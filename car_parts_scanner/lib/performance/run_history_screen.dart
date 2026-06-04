import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'performance_models.dart';
import 'results_screen.dart';
import '../core/theme/app_colors.dart';
import '../core/motion/motion_stagger.dart';
import '../core/motion/motion_tappable.dart';
import '../core/motion/motion_counter.dart';

class RunHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> car;

  const RunHistoryScreen({super.key, required this.car});

  @override
  State<RunHistoryScreen> createState() => _RunHistoryScreenState();
}

class _RunHistoryScreenState extends State<RunHistoryScreen> {
  List<Map<String, dynamic>> _runs = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRuns();
  }

  Future<void> _loadRuns() async {
    try {
      final data = await Supabase.instance.client
          .from('performance_runs')
          .select()
          .eq('car_id', widget.car['id'])
          .order('created_at', ascending: false);

      if (mounted) setState(() => _runs = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      debugPrint('Error loading runs: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  PerformanceRunData _parseRun(Map<String, dynamic> row) {
    return PerformanceRunData.fromJson(row);
  }

  void _openRun(Map<String, dynamic> row) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultsScreen(result: _parseRun(row)),
      ),
    );
  }

  String _formatDate(String isoStr) {
    final d = DateTime.parse(isoStr).toLocal();
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          '${widget.car['make']} ${widget.car['model']}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: TappableScale(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.cyan))
          : _runs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.white24, size: 56),
                      const SizedBox(height: 16),
                      const Text('No runs recorded yet.',
                        style: TextStyle(color: Colors.white38, fontSize: 16)),
                      const SizedBox(height: 6),
                      const Text('Head to the garage and start your first test!',
                        style: TextStyle(color: Colors.white24, fontSize: 13), textAlign: TextAlign.center),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _runs.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final run = _runs[index];
                    final dateStr = _formatDate(run['created_at'] as String);

                    // Pick the most prominent result to surface in the list
                    String topMetric = 'Run';
                    double topValue  = 0.0;
                    String topValueStr = '--';

                    if (run['result_0_to_100'] != null) {
                      topMetric = '0-100';
                      topValue  = (run['result_0_to_100'] as num).toDouble();
                      topValueStr = '${topValue.toStringAsFixed(2)}s';
                    } else if (run['result_0_to_60'] != null) {
                      topMetric = '0-60';
                      topValue  = (run['result_0_to_60'] as num).toDouble();
                      topValueStr = '${topValue.toStringAsFixed(2)}s';
                    } else if (run['result_quarter_mi'] != null) {
                      topMetric = '¼ Mile';
                      topValue  = (run['result_quarter_mi'] as num).toDouble();
                      topValueStr = '${topValue.toStringAsFixed(2)}s';
                    } else if (run['result_100_to_0'] != null) {
                      topMetric = '100-0';
                      topValue  = (run['result_100_to_0'] as num).toDouble();
                      topValueStr = '${topValue.toStringAsFixed(2)}s';
                    }

                    final isObd = run['sensor_mode'] == 'obd2';

                    return StaggeredEntrance(
                      index: index,
                      child: TappableScale(
                        onTap: () => _openRun(run),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.cyan.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.speed_rounded, color: AppColors.cyan, size: 22),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(topMetric,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      )),
                                    const SizedBox(height: 3),
                                    Text(
                                      '$dateStr  •  ${isObd ? 'OBD-II' : 'GPS'}',
                                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              if (topValueStr != '--')
                                MotionCounter(
                                  value: topValue,
                                  decimals: 2,
                                  suffix: 's',
                                  style: const TextStyle(
                                    color: AppColors.cyan,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                )
                              else
                                Text('--', style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.w900, fontSize: 18)),
                              const SizedBox(width: 6),
                              const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
