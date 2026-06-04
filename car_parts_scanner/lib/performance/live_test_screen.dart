import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';

import 'performance_models.dart';
import 'performance_run_service.dart';
import 'sensor_fusion_service.dart';
import 'obd_wifi_service.dart';
import 'results_screen.dart';
import '../core/theme/app_colors.dart';
import '../core/motion/motion_tappable.dart';

/// Live dashboard during a performance run.
/// - Redesigned speedometer with custom gauge CustomPainter
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

  bool _brakingArmed     = false;
  bool _brakingStarted   = false;

  double _chartMaxY = 60.0;

  final Set<MetricType> _completedMetrics = {};
  final Map<MetricType, double> _milestoneTimes = {};

  StreamSubscription? _speedSub;
  StreamSubscription? _stateSub;
  StreamSubscription? _milestoneSub;
  StreamSubscription? _elapsedSub;     
  StreamSubscription? _brakingArmSub;  

  @override
  void initState() {
    super.initState();
    _state = widget.runService.state;

    // Listen to smoothed speed
    _speedSub = widget.runService.speedOutStream.listen((speed) {
      if (!mounted) return;
      setState(() {
        _currentSpeed = speed;
        if (speed > _chartMaxY * 0.85) {
          _chartMaxY = (speed * 1.25).ceilToDouble().clamp(60, 350);
        }
      });
    });

    // Store elapsed subscription so we can cancel it
    _elapsedSub = widget.runService.elapsedStream.listen((timeS) {
      if (!mounted) return;
      setState(() {
        _elapsedS = timeS;
        _chartData.add(FlSpot(timeS, _currentSpeed));
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

    // Listen to braking ARM
    _brakingArmSub = widget.runService.brakingArmStream.listen((armed) {
      if (!mounted) return;
      setState(() => _brakingArmed = armed);
    });
  }

  @override
  void dispose() {
    _speedSub?.cancel();
    _stateSub?.cancel();
    _milestoneSub?.cancel();
    _elapsedSub?.cancel();       
    _brakingArmSub?.cancel();    
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
    final bool isBrakingTest = widget.runService.selectedMetrics.contains(MetricType.hundredToZero);
    final bool showBrakeButton = isBrakingTest
        && _brakingArmed
        && !_brakingStarted
        && !_completedMetrics.contains(MetricType.hundredToZero)
        && _state == RunState.running;

    return PopScope(
      canPop: false, // Prevent accidental back
      child: Scaffold(
        backgroundColor: AppColors.background,
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
                    TappableScale(
                      onTap: _cancelTest,
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.close_rounded, color: Colors.white38),
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 1),

              // ── Custom Speedometer Gauge ────────────────────────────────
              SpeedometerGauge(
                speed: _currentSpeed,
                maxSpeed: _chartMaxY,
                runState: _state,
              ),

              const Spacer(flex: 1),

              // ── BRAKE NOW button ──────────────────────────────────────
              if (showBrakeButton) ...[
                TappableScale(
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
                          ? AppColors.error.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.04),
                      border: Border.all(
                        color: _currentSpeed >= 98 ? AppColors.error : Colors.white24,
                        width: 3,
                      ),
                      boxShadow: [
                        if (_currentSpeed >= 98)
                          BoxShadow(
                            color: AppColors.error.withValues(alpha: 0.35),
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
                          color: _currentSpeed >= 98 ? AppColors.error : Colors.white38,
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
                      maxY: _chartMaxY,  
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
                          color: AppColors.cyan,
                          barWidth: 2.5,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              colors: [
                                AppColors.cyan.withValues(alpha: 0.25),
                                Colors.transparent,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 0), 
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
                            color: done ? AppColors.success : Colors.white24,
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
                                color: AppColors.success,
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
        color = AppColors.warning;
        break;
      case RunState.running:
        text = 'RECORDING';
        color = AppColors.error;
        break;
      case RunState.done:
        text = 'FINISHED';
        color = AppColors.success;
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

// ── Redesigned high-tech custom speedometer gauge ──────────────────────────
class SpeedometerGauge extends StatelessWidget {
  final double speed;
  final double maxSpeed;
  final RunState runState;

  const SpeedometerGauge({
    super.key,
    required this.speed,
    required this.maxSpeed,
    required this.runState,
  });

  @override
  Widget build(BuildContext context) {
    // Pulse and intensify glow near milestones (60 and 100)
    final isPulsing = (speed >= 50 && speed <= 65) || (speed >= 90 && speed <= 105);
    
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: speed, end: speed),
      duration: const Duration(milliseconds: 100),
      builder: (context, animSpeed, child) {
        return CustomPaint(
          size: const Size(220, 220),
          painter: _GaugePainter(
            speed: animSpeed,
            maxSpeed: maxSpeed,
            isPulsing: isPulsing && !MediaQuery.of(context).disableAnimations,
          ),
          child: child,
        );
      },
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              speed.toStringAsFixed(0),
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 64,
                fontWeight: FontWeight.w900,
                height: 1.0,
                letterSpacing: -2,
              ),
            ),
            Text(
              'km/h',
              style: GoogleFonts.inter(
                color: AppColors.cyan,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double speed;
  final double maxSpeed;
  final bool isPulsing;

  _GaugePainter({
    required this.speed,
    required this.maxSpeed,
    required this.isPulsing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    
    // Draw background track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
      
    const startAngle = 130 * math.pi / 180;
    const sweepAngle = 280 * math.pi / 180;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, trackPaint);
    
    // Draw Speed Arc
    final speedRatio = (speed / maxSpeed).clamp(0.0, 1.0);
    final activeSweep = speedRatio * sweepAngle;
    
    final speedPaint = Paint()
      ..shader = const LinearGradient(
        colors: [AppColors.cyan, AppColors.warning],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
      
    if (activeSweep > 0) {
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, activeSweep, false, speedPaint);
    }
    
    // Draw Tick Marks
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
      
    const totalTicks = 20;
    for (int i = 0; i <= totalTicks; i++) {
      final angle = startAngle + (i / totalTicks) * sweepAngle;
      final isMajor = i % 5 == 0;
      final tickLength = isMajor ? 12.0 : 6.0;
      
      final tickInnerRadius = radius - 12 - (isMajor ? 4 : 0);
      final tickOuterRadius = tickInnerRadius - tickLength;
      
      final startOffset = Offset(
        center.dx + tickInnerRadius * math.cos(angle),
        center.dy + tickInnerRadius * math.sin(angle),
      );
      final endOffset = Offset(
        center.dx + tickOuterRadius * math.cos(angle),
        center.dy + tickOuterRadius * math.sin(angle),
      );
      
      tickPaint.color = isMajor 
          ? Colors.white.withValues(alpha: 0.3) 
          : Colors.white.withValues(alpha: 0.12);
      canvas.drawLine(startOffset, endOffset, tickPaint);
    }

    // Outer glow pulse
    if (isPulsing) {
      final glowPaint = Paint()
        ..color = AppColors.cyan.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        
      canvas.drawCircle(center, radius + 8, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.speed != speed || oldDelegate.isPulsing != isPulsing;
  }
}
