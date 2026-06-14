// ─── Performance Module — Shared Data Models ──────────────────────────────────

double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}



/// Identifies which metric a run is testing.
enum MetricType {
  zeroTo60,
  zeroTo100,
  quarterMile,
  hundredToZero;

  String get displayName {
    switch (this) {
      case MetricType.zeroTo60:    return '0 → 60 km/h';
      case MetricType.zeroTo100:   return '0 → 100 km/h';
      case MetricType.quarterMile: return 'Quarter Mile';
      case MetricType.hundredToZero: return '100 → 0 km/h';
    }
  }

  String get shortName {
    switch (this) {
      case MetricType.zeroTo60:    return '0-60';
      case MetricType.zeroTo100:   return '0-100';
      case MetricType.quarterMile: return '¼ Mile';
      case MetricType.hundredToZero: return '100-0';
    }
  }

  /// Acceleration metrics can all run in a single drive.
  bool get isAcceleration => this != MetricType.hundredToZero;

  /// Speed threshold in km/h to trigger milestone (null = use GPS distance).
  double? get speedThresholdKmh {
    switch (this) {
      case MetricType.zeroTo60:    return 60.0;
      case MetricType.zeroTo100:   return 100.0;
      case MetricType.quarterMile: return null; // distance-based
      case MetricType.hundredToZero: return 100.0; // arm threshold
    }
  }

  String get dbKey {
    switch (this) {
      case MetricType.zeroTo60:    return 'result_0_to_60';
      case MetricType.zeroTo100:   return 'result_0_to_100';
      case MetricType.quarterMile: return 'result_quarter_mi';
      case MetricType.hundredToZero: return 'result_100_to_0';
    }
  }
}

/// A single time-stamped speed sample for the speed/time graph.
class SpeedDataPoint {
  final double timeS;
  final double speedKmh;

  const SpeedDataPoint(this.timeS, this.speedKmh);

  Map<String, dynamic> toJson() => {'t': timeS, 'v': speedKmh};

  factory SpeedDataPoint.fromJson(Map<String, dynamic> j) =>
      SpeedDataPoint((j['t'] as num).toDouble(), (j['v'] as num).toDouble());
}

/// Fired when a metric threshold is crossed during a run.
class MilestoneAchieved {
  final MetricType type;
  final double timeS;
  final double? trapSpeedKmh; // filled for quarter mile

  const MilestoneAchieved({
    required this.type,
    required this.timeS,
    this.trapSpeedKmh,
  });
}

/// Complete data set for a finished performance run.
class PerformanceRunData {
  final List<MetricType> metrics;
  final String sensorMode;         // 'gps_imu' | 'obd2'
  final List<SpeedDataPoint> dataPoints;
  final Map<MetricType, double> resultTimesS;  // metric → seconds
  final Map<MetricType, double> resultSpeeds; // metric → trap speed km/h
  final double topSpeedKmh;

  const PerformanceRunData({
    required this.metrics,
    required this.sensorMode,
    required this.dataPoints,
    required this.resultTimesS,
    required this.resultSpeeds,
    required this.topSpeedKmh,
  });

  bool get isComplete =>
      metrics.every((m) => resultTimesS.containsKey(m));

  factory PerformanceRunData.fromJson(Map<String, dynamic> json) {
    return PerformanceRunData(
      metrics: (json['metrics_selected'] as List).map((k) {
        if (k == 'result_0_to_60') return MetricType.zeroTo60;
        if (k == 'result_0_to_100') return MetricType.zeroTo100;
        if (k == 'result_quarter_mi') return MetricType.quarterMile;
        return MetricType.hundredToZero;
      }).toList(),
      sensorMode: json['sensor_mode'] ?? 'gps_imu',
      dataPoints: (json['speed_time_json'] as List?)
              ?.map((p) => SpeedDataPoint.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      resultTimesS: {
        if (json['result_0_to_60'] != null)
          MetricType.zeroTo60: _toDouble(json['result_0_to_60']),
        if (json['result_0_to_100'] != null)
          MetricType.zeroTo100: _toDouble(json['result_0_to_100']),
        if (json['result_quarter_mi'] != null)
          MetricType.quarterMile: _toDouble(json['result_quarter_mi']),
        if (json['result_100_to_0'] != null)
          MetricType.hundredToZero: _toDouble(json['result_100_to_0']),
      },
      resultSpeeds: {
        if (json['trap_speed_kmh'] != null)
          MetricType.quarterMile: _toDouble(json['trap_speed_kmh']),
      },
      topSpeedKmh: _toDouble(json['top_speed_kmh']),
    );
  }

  Map<String, dynamic> toSupabaseRow({
    required String carId,
    required String userId,
    String? conditions,
  }) {
    return {
      'car_id': carId,
      'user_id': userId,
      'metrics_selected': metrics.map((m) => m.dbKey).toList(),
      'result_0_to_60':    resultTimesS[MetricType.zeroTo60],
      'result_0_to_100':   resultTimesS[MetricType.zeroTo100],
      'result_quarter_mi': resultTimesS[MetricType.quarterMile],
      'result_100_to_0':   resultTimesS[MetricType.hundredToZero],
      'top_speed_kmh':     topSpeedKmh,
      'trap_speed_kmh':    resultSpeeds[MetricType.quarterMile],
      'sensor_mode':       sensorMode,
      'speed_time_json':   dataPoints.map((p) => p.toJson()).toList(),
      'conditions':        conditions,
    };
  }
}

/// State machine states for a run session.
enum RunState {
  idle,    // before anything starts
  armed,   // waiting for initial motion (speed > 3 km/h)
  running, // test in progress
  done,    // all selected milestones reached
}
