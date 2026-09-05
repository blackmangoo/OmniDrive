import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'performance_models.dart';
import 'sensor_fusion_service.dart';

const _kPendingRunsKey = 'omnidrive_pending_runs';

/// Orchestrates a performance test run.
///
/// Listens to a speed stream (from [SensorFusionService] or [ObdWifiService])
/// and a GPS position stream, then:
///  1. Waits for the car to exceed 3 km/h (armed → running transition)
///  2. Records every speed sample into [_dataPoints]
///  3. Fires [milestoneStream] when each threshold is crossed
///  4. Declares the run done when all selected metrics are complete
///  5. Saves results to Supabase — or queues locally if offline (OBD mode)
class PerformanceRunService {
  final List<MetricType> selectedMetrics;
  final String sensorMode; // 'gps_imu' | 'obd2'
  SensorFusionService? sensorFusionRef;

  PerformanceRunService({
    required this.selectedMetrics,
    required this.sensorMode,
    this.sensorFusionRef,
  });

  // ── State ─────────────────────────────────────────────────────────────────

  RunState _state = RunState.idle;
  RunState get state => _state;

  // ── Timing ────────────────────────────────────────────────────────────────

  DateTime? _startTime;
  double    _elapsed = 0.0; // seconds since start

  // ── Data recording ────────────────────────────────────────────────────────

  final List<SpeedDataPoint> _dataPoints = [];
  double _topSpeed = 0.0;

  // ── Milestone tracking ────────────────────────────────────────────────────

  final Set<MetricType>         _achieved = {};
  final Map<MetricType, double> _resultTimesS  = {};
  final Map<MetricType, double> _resultSpeeds  = {};

  // Braking-specific
  // FIX A3: Separate "armed" (speed ≥ 100 reached) from "completed" so the
  //         BRAKE NOW button is NOT dismissed prematurely.
  bool      _brakingArmed    = false;  // speed ≥ 100 → show BRAKE NOW button
  bool      _brakingStarted  = false;  // user tapped BRAKE button
  DateTime? _stopDetectStart;          // when speed first dropped to ≈ 0

  // Quarter-mile
  Position? _startPos;

  // ── Output streams ────────────────────────────────────────────────────────

  final _stateCtrl      = StreamController<RunState>.broadcast();
  final _elapsedCtrl    = StreamController<double>.broadcast();
  final _milestoneCtrl  = StreamController<MilestoneAchieved>.broadcast();
  final _speedOutCtrl   = StreamController<double>.broadcast();
  final _brakingArmCtrl = StreamController<bool>.broadcast(); // FIX A3

  /// Ticks every ~50 ms with elapsed seconds since the run started.
  Stream<double>            get elapsedStream    => _elapsedCtrl.stream;
  Stream<RunState>          get stateStream      => _stateCtrl.stream;
  Stream<MilestoneAchieved> get milestoneStream  => _milestoneCtrl.stream;
  /// Smoothed speed passthrough — subscribe here for the live display.
  Stream<double>            get speedOutStream   => _speedOutCtrl.stream;
  /// Fires true when speed ≥ 100 km/h (braking test ready). FIX A3.
  Stream<bool>              get brakingArmStream => _brakingArmCtrl.stream;
  bool get isBrakingArmed => _brakingArmed;

  StreamSubscription? _speedSub;
  StreamSubscription? _posSub;
  Timer?              _ticker;

  // ── Public API ────────────────────────────────────────────────────────────

  /// Attach to the speed + position streams from the chosen sensor service.
  void attachStreams({
    required Stream<double>   speedStream,
    required Stream<Position> positionStream,
  }) {
    _speedSub = speedStream.listen(_onSpeedUpdate);
    _posSub   = positionStream.listen(_onPositionUpdate);
    _setState(RunState.armed); // waiting for first motion
    _tickElapsed();
  }

  /// Call when the BRAKE NOW button is tapped (braking test only).
  void triggerBrakeStart() {
    if (_state != RunState.running) return;
    if (selectedMetrics.contains(MetricType.hundredToZero) && _brakingArmed) {
      _brakingStarted = true;
      _startTime      = DateTime.now(); // reset timer for braking
      _dataPoints.clear();
      // Tell the sensor fusion to flip acceleration sign
      sensorFusionRef?.brakingMode = true;
    }
  }

  void stop() {
    _speedSub?.cancel();
    _posSub?.cancel();
    _ticker?.cancel();
    _setState(RunState.done);
  }

  void dispose() {
    stop();
    _stateCtrl.close();
    _elapsedCtrl.close();
    _milestoneCtrl.close();
    _speedOutCtrl.close();
    _brakingArmCtrl.close();
  }

  // ── Speed processing ──────────────────────────────────────────────────────

  void _onSpeedUpdate(double speedKmh) {
    if (!_speedOutCtrl.isClosed) _speedOutCtrl.add(speedKmh);
    if (_state == RunState.done) return;

    // ── Armed: wait for initial motion ────────────────────────────────────
    if (_state == RunState.armed && speedKmh >= 3.0) {
      _startTime = DateTime.now();
      _setState(RunState.running);
    }

    if (_state != RunState.running) return;

    // ── Record data ───────────────────────────────────────────────────────
    _elapsed = DateTime.now().difference(_startTime!).inMicroseconds / 1e6;
    _dataPoints.add(SpeedDataPoint(_elapsed, speedKmh));
    if (speedKmh > _topSpeed) _topSpeed = speedKmh;

    // ── Braking arm: wait for 100 km/h threshold first ────────────────────
    // FIX A3: Only update the _brakingArmCtrl stream, NOT a milestone event.
    if (selectedMetrics.contains(MetricType.hundredToZero) &&
        !_brakingArmed && speedKmh >= 100.0) {
      _brakingArmed = true;
      if (!_brakingArmCtrl.isClosed) _brakingArmCtrl.add(true);
    }

    // ── Acceleration milestones ────────────────────────────────────────────
    _checkAccelMilestone(MetricType.zeroTo60,  60.0,  speedKmh);
    _checkAccelMilestone(MetricType.zeroTo100, 100.0, speedKmh);

    // ── Braking: detect stop ───────────────────────────────────────────────
    if (_brakingStarted &&
        !_achieved.contains(MetricType.hundredToZero)) {
      if (speedKmh <= 0.5) {
        _stopDetectStart ??= DateTime.now();
        if (DateTime.now().difference(_stopDetectStart!).inMilliseconds >= 400) {
          _recordMilestone(MetricType.hundredToZero, _elapsed, null);
        }
      } else {
        _stopDetectStart = null; // speed crept up, reset
      }
    }

    // ── Check if all metrics are done ─────────────────────────────────────
    if (selectedMetrics.every((m) => _achieved.contains(m))) {
      _finalise();
    }
  }

  void _checkAccelMilestone(MetricType type, double thresholdKmh, double speed) {
    if (!selectedMetrics.contains(type)) return;
    if (_achieved.contains(type))        return;
    if (speed < thresholdKmh)            return;
    _recordMilestone(type, _elapsed, null);
  }

  void _recordMilestone(MetricType type, double timeS, double? trapSpeed) {
    if (_achieved.contains(type)) return;
    _achieved.add(type);
    _resultTimesS[type] = timeS;
    if (trapSpeed != null) _resultSpeeds[type] = trapSpeed;
    _milestoneCtrl.add(MilestoneAchieved(
      type: type, timeS: timeS, trapSpeedKmh: trapSpeed,
    ));
  }

  // ── GPS position (quarter mile) ───────────────────────────────────────────

  void _onPositionUpdate(Position pos) {
    if (_state == RunState.running) {
      _startPos ??= pos; // capture start position once running

      if (selectedMetrics.contains(MetricType.quarterMile) &&
          !_achieved.contains(MetricType.quarterMile) &&
          _startPos != null) {
        final distM = Geolocator.distanceBetween(
          _startPos!.latitude, _startPos!.longitude,
          pos.latitude,        pos.longitude,
        );
        if (distM >= 402.336) {
          final currentSpeed = _dataPoints.isNotEmpty
              ? _dataPoints.last.speedKmh : 0.0;
          _recordMilestone(MetricType.quarterMile, _elapsed, currentSpeed);
        }
      }
    }
  }

  // ── Elapsed ticker ────────────────────────────────────────────────────────

  void _tickElapsed() {
    _ticker = Timer.periodic(Duration(milliseconds: 50), (_) {
      if (_state == RunState.running && _startTime != null) {
        _elapsed = DateTime.now().difference(_startTime!).inMicroseconds / 1e6;
        if (!_elapsedCtrl.isClosed) _elapsedCtrl.add(_elapsed);
      }
    });
  }

  // ── Finalise ──────────────────────────────────────────────────────────────

  void _finalise() => _setState(RunState.done);

  // ── Build result ──────────────────────────────────────────────────────────

  PerformanceRunData buildResult() {
    return PerformanceRunData(
      metrics:        selectedMetrics,
      sensorMode:     sensorMode,
      dataPoints:     List.unmodifiable(_dataPoints),
      resultTimesS:   Map.unmodifiable(_resultTimesS),
      resultSpeeds:   Map.unmodifiable(_resultSpeeds),
      topSpeedKmh:    _topSpeed,
    );
  }

  // ── Save ─────────────────────────────────────────────────────────────────

  /// Saves the run to Supabase. If offline, queues to SharedPreferences.
  Future<void> saveRun({
    required String carId,
    String? conditions,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    // FIX A4: Pre-serialize speed_time_json to a proper list of plain maps
    //         before passing to toSupabaseRow() to avoid JSON encoding issues.
    final row = buildResult().toSupabaseRow(
      carId: carId, userId: user.id, conditions: conditions,
    );

    // Ensure speed_time_json is JSON-encodable (converts List<Map> properly)
    row['speed_time_json'] = jsonDecode(
      jsonEncode(row['speed_time_json']),
    );

    try {
      final connectivity = await Connectivity().checkConnectivity();
      final hasInternet  = !connectivity.contains(ConnectivityResult.none);

      if (hasInternet) {
        await Supabase.instance.client.from('performance_runs').insert(row);
      } else {
        // Queue locally for later sync
        await _queueLocally(row);
      }
    } catch (e) {
      debugPrint('Save error, queueing locally: $e');
      await _queueLocally(row);
    }
  }

  // ── Offline queue ─────────────────────────────────────────────────────────

  static Future<void> _queueLocally(Map<String, dynamic> row) async {
    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getStringList(_kPendingRunsKey) ?? [];
    raw.add(jsonEncode(row));
    await prefs.setStringList(_kPendingRunsKey, raw);
  }

  /// Call on app start / network reconnect to flush pending runs to Supabase.
  static Future<void> flushPendingRuns() async {
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.contains(ConnectivityResult.none)) return;

    final prefs = await SharedPreferences.getInstance();
    final raw   = prefs.getStringList(_kPendingRunsKey) ?? [];
    if (raw.isEmpty) return;

    final toUpload = raw.map((s) => jsonDecode(s) as Map<String, dynamic>).toList();

    try {
      await Supabase.instance.client
          .from('performance_runs')
          .insert(toUpload);
      await prefs.remove(_kPendingRunsKey);
    } catch (e) {
      debugPrint('Flush failed, will retry: $e');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _setState(RunState s) {
    _state = s;
    if (!_stateCtrl.isClosed) _stateCtrl.add(s);
  }
}
