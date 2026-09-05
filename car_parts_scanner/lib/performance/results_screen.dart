import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'performance_models.dart';
import '../core/theme/app_colors.dart';
import '../core/motion/motion_stagger.dart';
import '../core/motion/motion_tappable.dart';
import '../core/motion/motion_counter.dart';

class ResultsScreen extends StatelessWidget {
  final PerformanceRunData result;

  const ResultsScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    // Compute dynamic Y ceiling from data
    final double maxSpeed = result.dataPoints.isEmpty
        ? 100.0
        : result.dataPoints.map((p) => p.speedKmh).reduce((a, b) => a > b ? a : b);
    final double chartMaxY = (maxSpeed * 1.15).clamp(60.0, 350.0);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Test Results',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        actions: [
          TappableScale(
            onTap: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(Icons.home_rounded, color: AppColors.cyan, size: 18),
                  SizedBox(width: 6),
                  Text('Garage', style: GoogleFonts.inter(color: AppColors.cyan, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 0, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Summary header ────────────────────────────────────────
              Row(
                children: [
                  Icon(
                    Icons.satellite_alt_rounded,
                    color: AppColors.cyan, size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    result.sensorMode == 'obd2' ? 'OBD-II (WiFi)' : 'GPS + Phone IMU',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.speed_rounded, color: AppColors.warning, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Top: ${result.topSpeedKmh.toStringAsFixed(1)} km/h',
                          style: TextStyle(
                              color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 24),

              // ── Result Cards ──────────────────────────────────────────
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.15,
                ),
                itemCount: result.metrics.length,
                itemBuilder: (ctx, i) {
                  final metric = result.metrics[i];
                  final time   = result.resultTimesS[metric];

                  return StaggeredEntrance(
                    index: i,
                    child: _ResultCard(
                      metric: metric,
                      timeS: time,
                      trapSpeed: metric == MetricType.quarterMile ? result.resultSpeeds[metric] : null,
                    ),
                  );
                },
              ),

              SizedBox(height: 36),

              // ── Telemetry header ──────────────────────────────────────
              Row(
                children: [
                  Text('Telemetry',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(width: 8),
                  Text('(${result.dataPoints.length} pts)',
                    style: TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
              SizedBox(height: 16),

              // ── Speed/Time Graph ──────────────────────────────────────
              if (result.dataPoints.isEmpty)
                Container(
                  height: 150,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text('No telemetry data recorded.',
                    style: TextStyle(color: Colors.white38)),
                )
              else
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  padding: EdgeInsets.only(right: 20, left: 8, top: 24, bottom: 8),
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: result.dataPoints.last.timeS,
                      minY: 0,
                      maxY: chartMaxY,
                      clipData: FlClipData.all(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: result.dataPoints
                              .map((p) => FlSpot(p.timeS, p.speedKmh))
                              .toList(),
                          isCurved: true,
                          color: AppColors.cyan,
                          barWidth: 2.5,
                          dotData: FlDotData(show: false),
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
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: true,
                        horizontalInterval: chartMaxY / 4,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: Colors.white.withValues(alpha: 0.07), strokeWidth: 1, dashArray: [4, 4]),
                        getDrawingVerticalLine: (_) =>
                            FlLine(color: Colors.white.withValues(alpha: 0.04), strokeWidth: 1),
                      ),
                      titlesData: FlTitlesData(
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          axisNameWidget: Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('Time (s)',
                              style: TextStyle(color: Colors.white38, fontSize: 10)),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            getTitlesWidget: (v, m) => Padding(
                              padding: EdgeInsets.only(top: 6),
                              child: Text('${v.toInt()}s',
                                style: TextStyle(color: Colors.white38, fontSize: 10)),
                            ),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          axisNameWidget: Padding(
                            padding: EdgeInsets.only(right: 4),
                            child: Text('km/h',
                              style: TextStyle(color: Colors.white38, fontSize: 10)),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            interval: chartMaxY / 4,
                            getTitlesWidget: (v, m) => Text(
                              '${v.toInt()}',
                              style: TextStyle(color: Colors.white54, fontSize: 10)),
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final MetricType metric;
  final double? timeS;
  final double? trapSpeed;

  const _ResultCard({required this.metric, required this.timeS, this.trapSpeed});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: timeS != null
              ? AppColors.success.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric.shortName,
            style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
          Spacer(),
          if (timeS != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                MotionCounter(
                  value: timeS!,
                  decimals: 2,
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    height: 1,
                  ),
                ),
                Text(' s', style: TextStyle(color: Colors.white38, fontSize: 14)),
              ],
            )
          else
            Text('--', style: TextStyle(color: Colors.white24, fontSize: 30)),

          if (trapSpeed != null)
            Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                '@ ${trapSpeed!.toStringAsFixed(1)} km/h',
                style: TextStyle(color: AppColors.cyan, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}
