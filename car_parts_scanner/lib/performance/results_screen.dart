import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'performance_models.dart';

const _kBg      = Color(0xFF0A0A0F);
const _kSurface = Color(0xFF1C1C2E);
const _kAccent  = Color(0xFF4FC3F7);
const _kGreen   = Color(0xFF34D399);
const _kAmber   = Color(0xFFFBBF24);

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
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Test Results',
          style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        actions: [
          TextButton.icon(
            onPressed: () {
              // FIX B7: Pop all the way back to the Garage (root of performance stack)
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.home_rounded, color: _kAccent, size: 18),
            label: const Text('Garage', style: TextStyle(color: _kAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Summary header ────────────────────────────────────────
              Row(
                children: [
                  Icon(
                    result.sensorMode == 'obd2'
                        ? Icons.settings_input_component_rounded
                        : Icons.satellite_alt_rounded,
                    color: _kAccent, size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    result.sensorMode == 'obd2' ? 'OBD-II (WiFi)' : 'GPS + Phone IMU',
                    style: const TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _kAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kAmber.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.speed_rounded, color: _kAmber, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Top: ${result.topSpeedKmh.toStringAsFixed(1)} km/h',
                          style: const TextStyle(
                              color: _kAmber, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ── Result Cards ──────────────────────────────────────────
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.15,
                ),
                itemCount: result.metrics.length,
                itemBuilder: (ctx, i) {
                  final metric = result.metrics[i];
                  final time   = result.resultTimesS[metric];

                  return _ResultCard(
                    metric: metric,
                    timeS: time,
                    trapSpeed: metric == MetricType.quarterMile ? result.resultSpeeds[metric] : null,
                  );
                },
              ),

              const SizedBox(height: 36),

              // ── Telemetry header ──────────────────────────────────────
              Row(
                children: [
                  const Text('Telemetry',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(width: 8),
                  Text('(${result.dataPoints.length} pts)',
                    style: const TextStyle(color: Colors.white38, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 16),

              // ── Speed/Time Graph ──────────────────────────────────────
              if (result.dataPoints.isEmpty)
                Container(
                  height: 150,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('No telemetry data recorded.',
                    style: TextStyle(color: Colors.white38)),
                )
              else
                Container(
                  height: 240,
                  decoration: BoxDecoration(
                    color: _kSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  padding: const EdgeInsets.only(right: 20, left: 8, top: 24, bottom: 8),
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: result.dataPoints.last.timeS,
                      minY: 0,
                      maxY: chartMaxY,
                      clipData: const FlClipData.all(),
                      lineBarsData: [
                        LineChartBarData(
                          spots: result.dataPoints
                              .map((p) => FlSpot(p.timeS, p.speedKmh))
                              .toList(),
                          isCurved: true,
                          color: _kAccent,
                          barWidth: 2.5,
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
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          axisNameWidget: const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('Time (s)',
                              style: TextStyle(color: Colors.white38, fontSize: 10)),
                          ),
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 26,
                            getTitlesWidget: (v, m) => Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text('${v.toInt()}s',
                                style: const TextStyle(color: Colors.white38, fontSize: 10)),
                            ),
                          ),
                        ),
                        leftTitles: AxisTitles(
                          axisNameWidget: const Padding(
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
                              style: const TextStyle(color: Colors.white54, fontSize: 10)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: timeS != null
              ? _kGreen.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(metric.shortName,
            style: const TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
          const Spacer(),
          if (timeS != null)
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: timeS!.toStringAsFixed(2),
                    style: const TextStyle(
                      color: _kGreen,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const TextSpan(
                    text: ' s',
                    style: TextStyle(color: Colors.white38, fontSize: 14),
                  ),
                ],
              ),
            )
          else
            const Text('--', style: TextStyle(color: Colors.white24, fontSize: 30)),

          if (trapSpeed != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '@ ${trapSpeed!.toStringAsFixed(1)} km/h',
                style: const TextStyle(color: _kAccent, fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }
}
