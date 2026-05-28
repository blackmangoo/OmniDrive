import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// 1-D Kalman filter for speed estimation.
///
/// - Prediction step: integrates accelerometer data between GPS ticks
/// - Update step:     corrects estimate with GPS speed measurement
///
/// Tuning:
///   q = process noise  — lower = smoother, slower to respond to accel
///   r = measurement noise — lower = trusts GPS more
class _KalmanFilter {
  double _x = 0.0; // speed estimate (km/h)
  double _p = 1.0; // error covariance
  final double q;  // process noise
  final double r;  // measurement noise

  _KalmanFilter({this.q = 0.3, this.r = 1.2});

  /// Prediction step — call with accelerometer reading between GPS updates.
  /// [accelMs2] = forward acceleration in m/s²
  /// [dtS]      = elapsed time since last call in seconds
  double predict(double accelMs2, double dtS) {
    _x = (_x + accelMs2 * dtS * 3.6).clamp(0, 350); // m/s² → Δkm/h
    _p += q;
    return _x;
  }

  /// Update (correction) step — call when a new GPS speed arrives.
  double update(double gpsKmh) {
    final k = _p / (_p + r);  // Kalman gain
    _x = _x + k * (gpsKmh - _x);
    _p = (1 - k) * _p;
    return _x.clamp(0, 350);
  }

  void reset() {
    _x = 0;
    _p = 1;
  }
}

/// Fuses GPS velocity + accelerometer into a smooth, high-rate speed stream.
///
/// Algorithm:
///   1. GPS (1-10 Hz) provides accurate speed measurements → Kalman update
///   2. User accelerometer (~50 Hz, gravity-removed by device sensor fusion)
///      provides fast predictions between GPS ticks
///   3. During braking mode, acceleration sign is flipped so the Kalman
///      filter correctly predicts deceleration
///
/// No stationary calibration is required — the device's built-in sensor
/// fusion (gyro + accel) handles gravity removal automatically.
class SensorFusionService {
  final _kalman = _KalmanFilter(q: 0.3, r: 1.2);

  StreamSubscription<Position>?              _gpsSub;
  StreamSubscription<UserAccelerometerEvent>? _accelSub;

  final _speedCtrl = StreamController<double>.broadcast();
  final _posCtrl   = StreamController<Position>.broadcast();

  /// Smooth speed in km/h — high-rate (~50 Hz).
  Stream<double>   get speedStream    => _speedCtrl.stream;

  /// Raw GPS positions — used for quarter-mile distance tracking.
  Stream<Position> get positionStream => _posCtrl.stream;

  // ── Mode flags ─────────────────────────────────────────────────────────────

  bool _calibrated  = false;
  /// Set to true during braking tests so the Kalman filter knows
  /// acceleration should be negative (decelerating).
  bool brakingMode  = false;

  // ── Internal timing ───────────────────────────────────────────────────────

  DateTime? _lastAccelTime;

  // ── GPS accuracy tracking ─────────────────────────────────────────────────

  double _gpsAccuracyM = 99.0;
  double get gpsAccuracyM => _gpsAccuracyM;

  bool get isGpsReady => _gpsAccuracyM <= 15.0;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Start GPS + accelerometer streams.
  Future<void> start() async {
    await _ensurePermissions();

    // GPS: request highest accuracy, up to 10 Hz on Android
    final locationSettings = const LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
    );

    _gpsSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_onGps);

    // User accelerometer at ~50 Hz — gravity is removed by device sensor
    // fusion (gyro + accel), giving true linear acceleration.
    _accelSub = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen(_onAccel);
  }

  /// Calibrates by letting the user-accelerometer settle for [durationMs] ms.
  /// With userAccelerometerEventStream gravity is pre-removed, so no resting
  /// magnitude needs to be measured. We just reset the Kalman filter.
  Future<void> calibrate({int durationMs = 1000}) async {
    // Give sensors time to settle (gyro fusion warmup)
    await Future.delayed(Duration(milliseconds: durationMs));
    _calibrated = true;
    _kalman.reset();
    _lastAccelTime = null;
  }

  void stop() {
    _gpsSub?.cancel();
    _accelSub?.cancel();
    _gpsSub  = null;
    _accelSub = null;
  }

  void dispose() {
    stop();
    _speedCtrl.close();
    _posCtrl.close();
  }

  // ── GPS handler ───────────────────────────────────────────────────────────

  void _onGps(Position pos) {
    _gpsAccuracyM = pos.accuracy;

    if (!_posCtrl.isClosed) _posCtrl.add(pos);

    // GPS speed: m/s → km/h, clamp negative (Geolocator quirk at standstill)
    final gpsSpeedKmh = (pos.speed * 3.6).clamp(0.0, 350.0);

    // Kalman update step
    final filtered = _kalman.update(gpsSpeedKmh);

    // Reset accel timer reference so prediction doesn't over-extrapolate
    _lastAccelTime = DateTime.now();

    if (!_speedCtrl.isClosed) _speedCtrl.add(filtered);
  }

  // ── Accelerometer handler ─────────────────────────────────────────────────

  void _onAccel(UserAccelerometerEvent e) {
    if (!_calibrated || _lastAccelTime == null) return;

    final now = DateTime.now();
    final dtS  = now.difference(_lastAccelTime!).inMicroseconds / 1e6;

    // Only predict between GPS updates — skip if dt is too large (>500ms
    // means GPS is late; predicting further would drift too much)
    if (dtS < 0.01 || dtS > 0.5) return;

    // userAccelerometerEventStream already removes gravity via device
    // sensor fusion (gyro + accel). The magnitude is pure linear accel.
    final mag = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);

    // Clamp to ±8 m/s² to prevent overshoots before GPS corrects
    double vehicleAccelMs2 = mag.clamp(0.0, 8.0);

    // During braking, the magnitude is positive but the car is decelerating.
    // Flip the sign so the Kalman filter predicts decreasing speed.
    if (brakingMode) vehicleAccelMs2 = -vehicleAccelMs2;

    _lastAccelTime = now;

    // Kalman prediction step
    final predicted = _kalman.predict(vehicleAccelMs2, dtS);

    if (!_speedCtrl.isClosed) _speedCtrl.add(predicted);
  }

  // ── Permissions ───────────────────────────────────────────────────────────

  Future<void> _ensurePermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Enable GPS and try again.');
    }

    LocationPermission perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever || perm == LocationPermission.denied) {
      throw Exception('Location permission denied. Grant it in app settings.');
    }
  }
}
