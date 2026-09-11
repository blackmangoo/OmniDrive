import 'dart:async';
import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Production-grade 2-State Discrete-Time Kalman Filter for vehicle speed estimation.
///
/// State vector:
///   x = [ v ]   (longitudinal speed in m/s)
///       [ b ]   (longitudinal accelerometer bias in m/s²)
///
/// Continuous physical model:
///   v_dot = a_measured - b + w_v    (Newtonian kinematics)
///   b_dot = w_b                    (bias modeled as slow random-walk)
///
/// Discrete state transition over interval dt:
///   F = [ 1  -dt ]
///       [ 0    1 ]
///
/// Control input matrix B:
///   B = [ dt ]
///       [  0 ]
///
/// Measurements:
///   GPS Doppler speed (m/s) with dynamic observation noise R derived from
///   reported GPS accuracy, innovation gating to reject multipath glitches,
///   and latency lead-compensation.
class VehicleSpeedKalmanFilter {
  // State: speed (m/s) and accel bias (m/s²)
  double _v = 0.0;
  double _b = 0.0;
  bool _hasInitialFix = false;

  // Covariance matrix P = [ P00  P01 ]
  //                       [ P10  P11 ]
  double _p00 = 0.01;
  double _p01 = 0.0;
  double _p10 = 0.0;
  double _p11 = 0.04;

  // Process noise spectral densities:
  // - qAccel: acceleration uncertainty from road slope, wind, throttle dynamics (m/s²)²
  // - qBias:  accelerometer bias random walk (m/s² / √s)²
  // - gpsLatencyS: internal GNSS Doppler pipeline delay (seconds)
  final double qAccel;
  final double qBias;
  final double gpsLatencyS;

  VehicleSpeedKalmanFilter({
    this.qAccel = 0.5,
    this.qBias = 0.005,
    this.gpsLatencyS = 0.0,
  });

  /// Current estimated speed in km/h.
  double get speedKmh => (_v * 3.6).clamp(0.0, 360.0);

  /// Current estimated speed in m/s.
  double get speedMs => _v;

  /// Estimated accelerometer bias along vehicle longitudinal axis in m/s².
  double get accelBiasMs2 => _b;

  /// Speed estimation variance (P00).
  double get speedVariance => _p00;

  /// Prediction step — called at ~50 Hz on each accelerometer tick.
  /// [accelMs2] is measured forward acceleration along vehicle axis (m/s²).
  /// [dtS] is elapsed seconds since previous prediction.
  double predict(double accelMs2, double dtS) {
    if (dtS <= 0.0) return speedKmh;
    // Bound dtS against sensor stalls or OS suspension (max 0.5s)
    final dt = dtS.clamp(0.001, 0.5);

    // Unbiased longitudinal acceleration
    final effectiveAccel = (accelMs2 - _b).clamp(-20.0, 20.0);

    // State propagation: v = v + (a - b) * dt
    _v += effectiveAccel * dt;
    if (_v < 0.0) _v = 0.0; // Vehicles in performance runs do not move backward
    if (_v > 100.0) _v = 100.0; // 360 km/h upper ceiling

    // Discrete process noise Q(dt)
    final q00 = (qAccel * qAccel) * dt;
    final q11 = (qBias * qBias) * dt;

    // Covariance propagation: P = F * P * F^T + Q
    // F = [ 1  -dt ]
    //     [ 0    1 ]
    final newP00 = _p00 - 2.0 * dt * _p01 + dt * dt * _p11 + q00;
    final newP01 = _p01 - dt * _p11;
    final newP11 = _p11 + q11;

    _p00 = math.max(1e-6, newP00);
    _p01 = newP01;
    _p10 = newP01;
    _p11 = math.max(1e-6, newP11);

    return speedKmh;
  }

  /// Update (correction) step — called whenever a GPS velocity fix arrives (1-10 Hz).
  /// [gpsSpeedMs] is raw GPS speed in m/s.
  /// [speedAccuracyMs] is GPS speed accuracy (m/s) if reported by GNSS chipset.
  /// [horizontalAccuracyM] is position horizontal dilution (m).
  /// [currentAccelMs2] is recent longitudinal acceleration for latency compensation.
  double update(
    double gpsSpeedMs, {
    double? speedAccuracyMs,
    double? horizontalAccuracyM,
    double currentAccelMs2 = 0.0,
  }) {
    // 1. GPS Latency Lead-Compensation:
    // Smartphone GNSS chipsets process Doppler fixes with ~150-220ms internal filter delay.
    // Under high launch acceleration, uncompensated GPS pulls down the instantaneous estimate.
    final leadCompensation = (currentAccelMs2 * gpsLatencyS).clamp(-2.0, 2.0);
    final zComp = math.max(0.0, gpsSpeedMs + leadCompensation);

    // 2. Dynamic Measurement Noise Covariance R:
    double r;
    if (speedAccuracyMs != null && speedAccuracyMs > 0.05) {
      // Direct speed accuracy reported by GNSS
      r = speedAccuracyMs * speedAccuracyMs;
      r = r.clamp(0.04, 16.0); // 0.2 m/s to 4.0 m/s stdev
    } else if (horizontalAccuracyM != null && horizontalAccuracyM > 0.0) {
      // Infer speed noise from horizontal dilution of precision
      r = 0.09 * (1.0 + math.pow(horizontalAccuracyM / 5.0, 2));
      r = r.clamp(0.04, 25.0);
    } else {
      // Default nominal GPS Doppler variance (~0.6 m/s stdev)
      r = 0.36;
    }

    // Initial fix: directly initialize state to avoid treating the first reading as an outlier
    if (!_hasInitialFix) {
      _v = zComp;
      _p00 = r;
      _hasInitialFix = true;
      return speedKmh;
    }

    // 3. Innovation (Measurement Residual)
    final y = zComp - _v;

    // Innovation covariance S = H * P * H^T + R = P00 + R
    final s = _p00 + r;

    // 4. Outlier Rejection / Innovation Gating:
    // Normalized Innovation Squared (NIS): d² = y² / S
    final d2 = (y * y) / s;
    double gatedY = y;
    if (d2 > 16.0 && y.abs() > 4.0) {
      // Deviation exceeds 4-sigma and > 14.4 km/h jump — soft clamp to 3-sigma
      final maxAllowedY = 3.0 * math.sqrt(s);
      gatedY = y.clamp(-maxAllowedY, maxAllowedY);
    }

    // 5. Kalman Gain K = P * H^T * S^(-1) = [ P00/S, P10/S ]^T
    final k0 = _p00 / s;
    final k1 = _p10 / s;

    // 6. State Correction: x = x + K * y
    _v = math.max(0.0, _v + k0 * gatedY);
    _b = (_b + k1 * gatedY).clamp(-2.5, 2.5); // Bound bias to physical MEMS sensor limits

    // 7. Covariance Update (Joseph-stabilized symmetric form):
    // P = (I - K * H) * P
    final newP00 = math.max(1e-6, (1.0 - k0) * _p00);
    final newP01 = (1.0 - k0) * _p01;
    final newP11 = math.max(1e-6, _p11 - k1 * _p01);

    _p00 = newP00;
    _p01 = newP01;
    _p10 = newP01;
    _p11 = newP11;

    return speedKmh;
  }

  /// Zero Velocity Update (ZUPT):
  /// Clamps speed to 0.0 when vehicle is known to be stationary,
  /// resets speed covariance, and absorbs residual static accel into bias.
  void applyZupt({double? measuredStationaryAccel}) {
    _v = 0.0;
    _p00 = math.min(_p00, 0.002);
    _p01 = 0.0;
    _p10 = 0.0;
    _hasInitialFix = true;
    if (measuredStationaryAccel != null) {
      // Exponential moving update of static bias
      _b = _b * 0.9 + measuredStationaryAccel * 0.1;
      _p11 = math.min(_p11, 0.01);
    }
  }

  void reset() {
    _v = 0.0;
    _b = 0.0;
    _p00 = 0.01;
    _p01 = 0.0;
    _p10 = 0.0;
    _p11 = 0.04;
    _hasInitialFix = false;
  }
}

/// Production Sensor Fusion Service for Automotive Telemetry.
///
/// Features:
/// 1. Gravity Vector Isolation: Automatically separates Earth's gravity (heave/bumps)
///    from horizontal vehicle plane motion.
/// 2. Longitudinal Dynamic Projection: Projects linear acceleration onto the vehicle's
///    direction of travel so that:
///    - Throttle acceleration is naturally positive (+)
///    - Braking / coasting deceleration is naturally negative (-)
///    - Lateral cornering forces (sway) are orthogonal and automatically rejected.
/// 3. Zero-Velocity Update (ZUPT): Prevents speedometer drift and false-launch triggers
///    when waiting at the starting line.
/// 4. 2-State Kalman Filter: Real-time speed and accelerometer bias tracking with dynamic
///    GPS noise adaptation and outlier rejection.
class SensorFusionService {
  final VehicleSpeedKalmanFilter _kalman = VehicleSpeedKalmanFilter(gpsLatencyS: 0.15);

  StreamSubscription<Position>? _gpsSub;
  StreamSubscription<UserAccelerometerEvent>? _accelSub;
  StreamSubscription<AccelerometerEvent>? _rawAccelSub;

  final _speedCtrl = StreamController<double>.broadcast();
  final _posCtrl = StreamController<Position>.broadcast();

  /// Smooth speed in km/h — high-rate (~50 Hz).
  Stream<double> get speedStream => _speedCtrl.stream;

  /// Raw GPS positions — used for quarter-mile distance tracking.
  Stream<Position> get positionStream => _posCtrl.stream;

  // ── Orientation & Projection Vectors ───────────────────────────────────────

  // Earth-downward unit gravity vector in device body coordinates.
  // Defaults to [0, 0, 1] (phone lying flat screen up) or portrait tilt.
  double _downX = 0.0;
  double _downY = 0.6;
  double _downZ = 0.8;

  // Forward unit vector in horizontal plane (vehicle longitudinal axis).
  double _fwdX = 0.0;
  double _fwdY = 0.8;
  double _fwdZ = -0.6;

  bool _calibrated = false;

  /// Set to true during braking tests as a directional assertion if desired.
  bool brakingMode = false;

  // ── Internal timing & state ───────────────────────────────────────────────

  DateTime? _lastAccelTime;
  double _lastFilteredSpeedKmh = 0.0;
  double _recentLongAccelMs2 = 0.0;

  // Standstill / ZUPT tracking ring-buffer
  final List<double> _recentAccelMags = [];
  static const int _kAccelHistorySize = 10;

  // ── GPS accuracy tracking ─────────────────────────────────────────────────

  double _gpsAccuracyM = 99.0;
  double get gpsAccuracyM => _gpsAccuracyM;
  bool get isGpsReady => _gpsAccuracyM <= 15.0;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Start GPS + accelerometer streams.
  Future<void> start() async {
    await _ensurePermissions();

    final locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 0,
    );

    _gpsSub = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen(_onGps);

    _accelSub = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen(_onAccel);
  }

  /// Calibrates sensors while the vehicle is stationary before a run.
  /// Measures the gravity vector to determine phone tilt in the mount,
  /// establishes the horizontal road plane, and locks zero-velocity baseline.
  Future<void> calibrate({int durationMs = 1500}) async {
    final rawSamples = <List<double>>[];
    final userSamples = <List<double>>[];

    // Listen to raw accelerometer to measure gravity vector
    final subRaw = accelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen((e) {
      rawSamples.add([e.x, e.y, e.z]);
    });

    final subUser = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 20),
    ).listen((e) {
      userSamples.add([e.x, e.y, e.z]);
    });

    await Future.delayed(Duration(milliseconds: durationMs));
    await subRaw.cancel();
    await subUser.cancel();

    if (rawSamples.isNotEmpty) {
      double sumX = 0.0, sumY = 0.0, sumZ = 0.0;
      for (final s in rawSamples) {
        sumX += s[0];
        sumY += s[1];
        sumZ += s[2];
      }
      final n = rawSamples.length.toDouble();
      final gx = sumX / n;
      final gy = sumY / n;
      final gz = sumZ / n;
      final gMag = math.sqrt(gx * gx + gy * gy + gz * gz);

      if (gMag > 5.0) {
        _downX = gx / gMag;
        _downY = gy / gMag;
        _downZ = gz / gMag;
      }
    }

    _computeInitialForwardVector();

    _kalman.reset();
    _kalman.applyZupt();
    _lastAccelTime = null;
    _lastFilteredSpeedKmh = 0.0;
    _recentAccelMags.clear();
    _calibrated = true;
  }

  void _computeInitialForwardVector() {
    // In portrait mount, vehicle forward direction points toward back of phone (-Z)
    // or up the phone body (+Y) depending on mount tilt.
    // Project -Z onto horizontal plane perpendicular to _down:
    // f = [0, 0, -1] - ([0, 0, -1] · down) * down
    final dotZ = -_downZ;
    double fx = -dotZ * _downX;
    double fy = -dotZ * _downY;
    double fz = -1.0 - dotZ * _downZ;
    double fMag = math.sqrt(fx * fx + fy * fy + fz * fz);

    if (fMag < 0.2) {
      // Phone is nearly flat, project +Y instead
      final dotY = _downY;
      fx = -dotY * _downX;
      fy = 1.0 - dotY * _downY;
      fz = -dotY * _downZ;
      fMag = math.sqrt(fx * fx + fy * fy + fz * fz);
    }

    if (fMag > 0.01) {
      _fwdX = fx / fMag;
      _fwdY = fy / fMag;
      _fwdZ = fz / fMag;
    }
  }

  void stop() {
    _gpsSub?.cancel();
    _accelSub?.cancel();
    _rawAccelSub?.cancel();
    _gpsSub = null;
    _accelSub = null;
    _rawAccelSub = null;
  }

  void dispose() {
    stop();
    _speedCtrl.close();
    _posCtrl.close();
  }

  // ── GPS Handler ───────────────────────────────────────────────────────────

  void _onGps(Position pos) {
    _gpsAccuracyM = pos.accuracy;
    if (!_posCtrl.isClosed) _posCtrl.add(pos);

    // GPS speed in m/s (Geolocator speed is non-negative m/s)
    final gpsSpeedMs = math.max(0.0, pos.speed);
    final now = DateTime.now();

    // Standstill check: if GPS reports < 0.8 km/h (< 0.22 m/s) and accel is quiet
    final isStationary = gpsSpeedMs < 0.22 && _isAccelerometerQuiet();
    if (isStationary) {
      _kalman.applyZupt(measuredStationaryAccel: _recentLongAccelMs2);
      _lastFilteredSpeedKmh = 0.0;
      _lastAccelTime = now;
      if (!_speedCtrl.isClosed) _speedCtrl.add(0.0);
      return;
    }

    // Dynamic forward alignment:
    // If car is moving with confident GPS velocity (> 10 km/h) and acceleration aligns with speed changes,
    // ensure forward vector polarity matches motion direction.
    if (_lastFilteredSpeedKmh > 10.0 && _recentLongAccelMs2.abs() > 0.6) {
      if (gpsSpeedMs * 3.6 > _lastFilteredSpeedKmh && _recentLongAccelMs2 < -0.4) {
        // Detected inverted mounting polarity — flip forward axis
        _fwdX = -_fwdX;
        _fwdY = -_fwdY;
        _fwdZ = -_fwdZ;
      }
    }

    // Kalman update step with latency lead compensation and dynamic noise R
    final filteredKmh = _kalman.update(
      gpsSpeedMs,
      speedAccuracyMs: pos.speedAccuracy > 0.05 ? pos.speedAccuracy : null,
      horizontalAccuracyM: pos.accuracy > 0 ? pos.accuracy : null,
      currentAccelMs2: _recentLongAccelMs2,
    );

    _lastFilteredSpeedKmh = filteredKmh;
    _lastAccelTime = now;

    if (!_speedCtrl.isClosed) _speedCtrl.add(filteredKmh);
  }

  // ── Accelerometer Handler ─────────────────────────────────────────────────

  void _onAccel(UserAccelerometerEvent e) {
    if (!_calibrated || _lastAccelTime == null) return;

    final now = DateTime.now();
    final dtS = now.difference(_lastAccelTime!).inMicroseconds / 1e6;

    // Reject erratic timer steps
    if (dtS < 0.005 || dtS > 0.5) {
      _lastAccelTime = now;
      return;
    }

    // 1. Decompose linear acceleration into vertical (gravity-aligned) and horizontal (road plane):
    // userAccelerometerEventStream provides linear acceleration (gravity subtracted by OS).
    final ax = e.x;
    final ay = e.y;
    final az = e.z;

    // Component along downward vertical axis: a_vert = a · down
    final aVert = ax * _downX + ay * _downY + az * _downZ;

    // Road plane horizontal acceleration: a_h = a - a_vert * down
    final ahX = ax - aVert * _downX;
    final ahY = ay - aVert * _downY;
    final ahZ = az - aVert * _downZ;

    // 2. Project horizontal acceleration onto vehicle forward axis:
    // a_long = a_h · forward
    double longAccel = ahX * _fwdX + ahY * _fwdY + ahZ * _fwdZ;

    // Manual brakingMode assertion if set
    if (brakingMode && longAccel > 0.0) {
      longAccel = -longAccel;
    }

    // 3. Noise deadband for MEMS resting jitter
    if (longAccel.abs() < 0.06) {
      longAccel = 0.0;
    }

    _recentLongAccelMs2 = longAccel;

    // Track rolling acceleration magnitude for ZUPT
    final horizMag = math.sqrt(ahX * ahX + ahY * ahY + ahZ * ahZ);
    _recentAccelMags.add(horizMag);
    if (_recentAccelMags.length > _kAccelHistorySize) {
      _recentAccelMags.removeAt(0);
    }

    _lastAccelTime = now;

    // If car is confirmed at standstill, enforce ZUPT
    if (_lastFilteredSpeedKmh < 0.5 && _isAccelerometerQuiet()) {
      _kalman.applyZupt(measuredStationaryAccel: longAccel);
      if (!_speedCtrl.isClosed) _speedCtrl.add(0.0);
      return;
    }

    // Kalman prediction step
    final predictedKmh = _kalman.predict(longAccel, dtS);
    _lastFilteredSpeedKmh = predictedKmh;

    if (!_speedCtrl.isClosed) _speedCtrl.add(predictedKmh);
  }

  bool _isAccelerometerQuiet() {
    if (_recentAccelMags.length < 5) return true;
    double sum = 0.0;
    for (final m in _recentAccelMags) {
      sum += m;
    }
    final mean = sum / _recentAccelMags.length;
    double varSum = 0.0;
    for (final m in _recentAccelMags) {
      final diff = m - mean;
      varSum += diff * diff;
    }
    final variance = varSum / _recentAccelMags.length;
    return variance < 0.08 && mean < 0.35;
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
