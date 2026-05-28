import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import 'performance_models.dart';
import 'performance_run_service.dart';
import 'sensor_fusion_service.dart';
import 'obd_wifi_service.dart';
import 'results_screen.dart';

const _kBg      = Color(0xFF0A0A0F);
const _kAccent  = Color(0xFF4FC3F7);
const _kRed     = Color(0xFFEF4444);
const _kGreen   = Color(0xFF34D399);
const _kAmber   = Colors.amber;

/// Live dashboard during a performance run.
/// - Large digital speedometer
/// - Real-time scrolling speed-time graph  
/// - Live elapsed timer
/// - Status pill (Armed / Recording / Finished)
/// - Dynamic BRAKE NOW button for braking tests
class LiveTestScreen extends StatefulWidget {
  final String carId;
  final PerformanceRunService runService;

  // References to dispose when run finishes / is cancelled
  final SensorFusionService? gpsService;
  final ObdWifiService? obdService;

  const LiveTestScreen({
    super.key,
    required this.carId,
    required this.runService,
    this.gpsService,
    this.obdService,
  });

  @override
  State<LiveTestScreen> createState() => _LiveTestScreenState();
}

class _LiveTestScreenState extends State<LiveTestScreen> {
  // Chart data
  final List<FlSpot> _chartData = [];
  double _maxX = 15.0; // dynamic x-axis window

  // Real-time state
  double   _currentSpeed = 0.0;
  double   _elapsedS     = 0.0;
  RunState _state        = RunState.idle;

  // FIX A3: Track braking arm via its own stream, not _completedMetrics
  bool _brakingArmed     = false;
  bool _brakingStarted   = false;

  // FIX B1: dynamic maxY for chart
  double _chartMaxY = 60.0;

  final Set<MetricType> _completedMetrics = {};
  final Map<MetricType, double> _milestoneTimes = {};

  // FIX A1: All 4 subscriptions are now properly tracked and cancelled
  StreamSubscription? _speedSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _milestoneSub;
  StreamSubscription? _elapsedSub;     // Was never cancelled before — fixed
  StreamSubscription? _brakingArmSub;  // New: listens to braking arm event

  @override
  void initState() {
    super.initState();
    _state = widget.runService.state;

    // Listen to smoothed speed
    _speedSub = widget.runService.speedOutStream.listen((speed) {
      if (!mounted) return;
      setState(() {
        _currentSpeed = speed;
        // FIX B1: Grow the Y ceiling dynamically
        if (speed > _chartMaxY * 0.85) {
          _chartMaxY = (speed * 1.25).ceilToDouble().clamp(60, 350);
        }
      });
    });

    // FIX A1: Store elapsed subscription so we can cancel it
    _elapsedSub = widget.runService.elapsedStream.listen((timeS) {
      if (!mounted) return;
      setState(() {
        _elapsedS = timeS;
        _chartData.add(FlSpot(timeS, _currentSpeed));
        // Extend x-axis window as time progresses
        if (timeS > _maxX * 0.85) {
          _maxX += 10.0;
        }
      });
    });

    // Listen to run state changes
    _stateSub = widget.runService.stateStream.listen((state) {
      if (!mounted) return;
      setState(() => _state = state);
      if (state == RunState.done) {
        _finishRun();
      }
    });

    // Listen to milestones
    _milestoneSub = widget.runService.milestoneStream.listen((m) {
      if (!mounted) return;
      setState(() {
        _completedMetrics.add(m.type);
        _milestoneTimes[m.type] = m.timeS;
      });
    });

    // FIX A3: Listen to braking ARM (separate from completion)
    _brakingArmSub = widget.runService.brakingArmStream.listen((armed) {
      if (!mounted) return;
      setState(() => _brakingArmed = armed);
    });
  }

  @override
  void dispose() {
    // FIX A1: Cancel all subscriptions properly
    _speedSub?.cancel();
    _stateSub?.cancel();
    _milestoneSub?.cancel();
    _elapsedSub?.cancel();       // Was missing before
    _brakingArmSub?.cancel();    // New
    super.dispose();
  }

  void _cancelTest() {
    widget.runService.dispose();
    widget.gpsService?.dispose();
    widget.obdService?.dispose();
    if (mounted) Navigator.pop(context);
  }

  Future<void> _finishRun() async {
    widget.runService.stop();
    widget.gpsService?.stop();
    widget.obdService?.disconnect();

    if (!mounted) return;

    try {
      await widget.runService.saveRun(carId: widget.carId);
    } catch (e) {
      debugPrint('Save error (fallback handled inside saveRun): $e');
    }

    if (!mounted) return;
    // FIX B7: Navigate back to the garage root, not just pop to pre-test
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(
          result: widget.runService.buildResult(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // FIX A3: Show BRAKE NOW button based on arm stream, not completedMetrics
    final bool isBrakingTest = widget.runService.selectedMetrics.contains(MetricType.hundredToZero);
    final bool showBrakeButton = isBrakingTest
        && _brakingArmed
        && !_brakingStarted
        && !_completedMetrics.contains(MetricType.hundredToZero)
        && _state == RunState.running;

    return PopScope(
      canPop: false, // Prevent accidental back
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header row ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusPill(),
                    // Live elapsed timer
                    if (_state == RunState.running)
                      Text(
                        _formatElapsed(_elapsedS),
                        style: const TextStyle(
                          color: Colors.white38,
                          fontSize: 16,
                          fontFeatures: [FontFeature.tabularFigures()],
                          fontFamily: 'monospace',
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white38),
                      onPressed: _cancelTest,
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // ── Speedometer ───────────────────────────────────────────
              Text(
                _currentSpeed.toStringAsFixed(0),
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 110,
                  fontWeight: FontWeight.bold,
                  height: 1.0,
                  letterSpacing: -4,
                ),
              ),
              const Text('km/h',
                style: TextStyle(color: _kAccent, fontSize: 22, fontWeight: FontWeight.w600)),

              const Spacer(flex: 1),

              // ── BRAKE NOW button ──────────────────────────────────────
              if (showBrakeButton) ...[
                GestureDetector(
                  onTap: () {
                    if (_currentSpeed >= 98) {
                      widget.runService.triggerBrakeStart();
                      setState(() => _brakingStarted = true);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 190,
                    height: 190,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentSpeed >= 98
                          ? _kRed.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.04),
                      border: Border.all(
                        color: _currentSpeed >= 98 ? _kRed : Colors.white24,
                        width: 3,
                      ),
                      boxShadow: [
                        if (_currentSpeed >= 98)
                          BoxShadow(
                            color: _kRed.withValues(alpha: 0.35),
                            blurRadius: 50,
                            spreadRadius: 8,
                          ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.block_rounded,
                          color: _currentSpeed >= 98 ? _kRed : Colors.white38,
                          size: 36),
                        const SizedBox(height: 8),
                        Text(
                          _currentSpeed >= 98 ? 'BRAKE NOW' : 'Reach 100',
                          style: TextStyle(
                            color: _currentSpeed >= 98 ? Colors.white : Colors.white38,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // ── Live chart ────────────────────────────────────────────
              if (!showBrakeButton)
                Container(
                  height: 180,
                  padding: const EdgeInsets.only(left: 8, right: 16, bottom: 4),
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: _maxX,
                      minY: 0,
                      maxY: _chartMaxY,  // FIX B1: dynamic Y ceiling
                      clipData: const FlClipData.all(),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _chartMaxY / 3,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: Colors.white.withValues(alpha: 0.07), strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            interval: 5,
                            getTitlesWidget: (v, _) => Text(
                              '${v.toInt()}s',
                              style: const TextStyle(color: Colors.white24, fontSize: 10),
                            ),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            interval: _chartMaxY / 3,
                            getTitlesWidget: (v, _) => Text(
                              '${v.toInt()}',
                              style: const TextStyle(color: Colors.white24, fontSize: 10),
                            ),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _chartData.isEmpty
                              ? [const FlSpot(0, 0)]
                              : _chartData,
                          isCurved: true,
                          color: _kAccent,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                _kAccent.withValues(alpha: 0.25),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 0), // No chart animation for live
                  ),
                ),

              const Spacer(flex: 1),

              // ── Metric status list ────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Column(
                  children: widget.runService.selectedMetrics.map((m) {
                    final done = _completedMetrics.contains(m);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Icon(
                            done ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                            color: done ? _kGreen : Colors.white24,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            m.displayName,
                            style: TextStyle(
                              color: done ? Colors.white54 : Colors.white70,
                              fontSize: 15,
                              decoration: done ? TextDecoration.lineThrough : null,
                              decorationColor: Colors.white38,
                            ),
                          ),
                          if (done && _resultTime(m) != null) ...[
                            const Spacer(),
                            Text(
                              '${_resultTime(m)!.toStringAsFixed(2)}s',
                              style: const TextStyle(
                                color: _kGreen,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double? _resultTime(MetricType m) {
    return _milestoneTimes[m];
  }

  String _formatElapsed(double s) {
    final m = (s / 60).floor();
    final sec = (s % 60).toStringAsFixed(1).padLeft(4, '0');
    return m > 0 ? '${m}m ${sec}s' : '${sec}s';
  }

  Widget _buildStatusPill() {
    String text;
    Color color;

    switch (_state) {
      case RunState.idle:
      case RunState.armed:
        text = 'ARMED';
        color = _kAmber;
        break;
      case RunState.running:
        text = 'RECORDING';
        color = _kRed;
        break;
      case RunState.done:
        text = 'FINISHED';
        color = _kGreen;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Text(text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1.2,
            )),
        ],
      ),
    );
  }
}
