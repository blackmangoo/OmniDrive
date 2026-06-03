import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'metric_selection_screen.dart';
import 'pre_test_screen.dart';
import 'run_history_screen.dart';
import 'results_screen.dart';
import 'performance_models.dart';

const _kBg = Color(0xFF0A0A0F);
const _kSurface = Color(0xFF12121A);
const _kAccent = Color(0xFF4FC3F7);
const _kBorder = Color(0xFF1E1E2E);

/// Entry screen for the Performance Metrics module.
/// Shows the user's cars, lets them start a new test, and shows recent runs.
class PerformanceHomeScreen extends StatefulWidget {
  const PerformanceHomeScreen({super.key});

  @override
  State<PerformanceHomeScreen> createState() => _PerformanceHomeScreenState();
}

class _PerformanceHomeScreenState extends State<PerformanceHomeScreen> {
  List<Map<String, dynamic>> _cars = [];
  bool _loadingCars = true;
  int _selectedCarIndex = 0; // The currently active car
  List<Map<String, dynamic>> _recentRuns = [];
  bool _loadingRuns = false;

  @override
  void initState() {
    super.initState();
    _loadCars();
  }

  Future<void> _loadCars() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      final data = await Supabase.instance.client
          .from('user_cars')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _cars = List<Map<String, dynamic>>.from(data);
          if (_selectedCarIndex >= _cars.length && _cars.isNotEmpty) {
            _selectedCarIndex = 0;
          }
        });
        _loadRecentRuns();
      }
    } catch (e) {
      debugPrint('Error loading cars: $e');
    } finally {
      if (mounted) setState(() => _loadingCars = false);
    }
  }

  Future<void> _loadRecentRuns() async {
    if (_cars.isEmpty) {
      if (mounted) {
        setState(() {
          _recentRuns = [];
          _loadingRuns = false;
        });
      }
      return;
    }
    setState(() => _loadingRuns = true);
    try {
      final carId = _cars[_selectedCarIndex]['id'];
      final data = await Supabase.instance.client
          .from('performance_runs')
          .select()
          .eq('car_id', carId)
          .order('created_at', ascending: false)
          .limit(3);
      if (mounted) {
        setState(() {
          _recentRuns = List<Map<String, dynamic>>.from(data);
        });
      }
    } catch (e) {
      debugPrint('Error loading runs: $e');
    } finally {
      if (mounted) setState(() => _loadingRuns = false);
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    // AuthGate stream handles redirect
  }

  Future<void> _startNewTest() async {
    if (_cars.isEmpty) return;

    final carId = _cars[_selectedCarIndex]['id'] as String;

    // 1. Pick metrics
    final selection = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(builder: (_) => const MetricSelectionScreen()),
    );
    if (selection == null || !mounted) return;

    final metrics = selection['metrics'] as List<dynamic>; // Actually List<MetricType>
    final obdMode = selection['obdMode'] as bool;

    // 2. Launch Pre-Test (will automatically sequence to Live Test -> Results)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreTestScreen(
          carId: carId,
          metrics: metrics.cast(),
          obdMode: obdMode,
        ),
      ),
    ).then((_) => _loadRecentRuns());
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────────
            SliverAppBar(
              backgroundColor: _kBg,
              pinned: true,
              title: const Text('Performance',
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 22)),
              actions: [
                IconButton(
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout_rounded,
                      color: Colors.white54, size: 22),
                  tooltip: 'Sign Out',
                ),
              ],
            ),

            // ── User greeting ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Welcome, ${user?.userMetadata?['full_name'] ?? 'Driver'} 👋',
                  style: const TextStyle(color: Colors.white54, fontSize: 14),
                ),
              ),
            ),

            // ── My Cars section ───────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('My Cars',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    TextButton.icon(
                      onPressed: () => _showAddCarDialog(context),
                      icon: const Icon(Icons.add, color: _kAccent, size: 18),
                      label: const Text('Add Car',
                          style: TextStyle(color: _kAccent, fontSize: 13)),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    ),
                  ],
                ),
              ),
            ),

            // Car list
            _loadingCars
                ? const SliverToBoxAdapter(
                    child: Center(
                        child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(color: _kAccent),
                  )))
                : _cars.isEmpty
                    ? SliverToBoxAdapter(
                        child: _EmptyCarPrompt(
                            onAdd: () => _showAddCarDialog(context)))
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) => GestureDetector(
                            onTap: () {
                              setState(() => _selectedCarIndex = i);
                              _loadRecentRuns();
                            },
                            child: _CarCard(
                              car: _cars[i],
                              isSelected: i == _selectedCarIndex,
                            ),
                          ),
                          childCount: _cars.length,
                        ),
                      ),

            // ── Recent Runs section ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 32, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Recent Runs',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700)),
                    if (_cars.isNotEmpty && _recentRuns.isNotEmpty)
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RunHistoryScreen(car: _cars[_selectedCarIndex]),
                            ),
                          ).then((_) => _loadRecentRuns());
                        },
                        child: const Text('See All',
                            style: TextStyle(color: _kAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
            ),

            _loadingRuns
                ? const SliverToBoxAdapter(
                    child: Center(
                        child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(color: _kAccent),
                    )))
                : _recentRuns.isEmpty
                    ? SliverToBoxAdapter(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _kSurface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _kBorder),
                          ),
                          child: const Column(
                            children: [
                              Icon(Icons.speed_rounded, color: Colors.white24, size: 48),
                              SizedBox(height: 12),
                              Text('No runs yet',
                                  style: TextStyle(color: Colors.white38, fontSize: 15)),
                              SizedBox(height: 6),
                              Text('Choose a car, then start your first test!',
                                  style: TextStyle(color: Colors.white24, fontSize: 12)),
                            ],
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            final run = _recentRuns[i];
                            final d = DateTime.parse(run['created_at'] as String).toLocal();
                            final dateStr = '${d.day}/${d.month}/${d.year}';

                            String topMetric = 'Run';
                            String topValue  = '--';

                            if (run['result_0_to_100'] != null) {
                              topMetric = '0-100';
                              topValue  = '${(run['result_0_to_100'] as num).toStringAsFixed(2)}s';
                            } else if (run['result_0_to_60'] != null) {
                              topMetric = '0-60';
                              topValue  = '${(run['result_0_to_60'] as num).toStringAsFixed(2)}s';
                            } else if (run['result_quarter_mi'] != null) {
                              topMetric = '¼ Mile';
                              topValue  = '${(run['result_quarter_mi'] as num).toStringAsFixed(2)}s';
                            } else if (run['result_100_to_0'] != null) {
                              topMetric = '100-0';
                              topValue  = '${(run['result_100_to_0'] as num).toStringAsFixed(2)}s';
                            }

                            final isObd = run['sensor_mode'] == 'obd2';

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                              child: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ResultsScreen(result: PerformanceRunData.fromJson(run)),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  decoration: BoxDecoration(
                                    color: _kSurface,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: _kBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: _kAccent.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.speed_rounded, color: _kAccent, size: 22),
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
                                      Text(topValue,
                                          style: const TextStyle(
                                            color: _kAccent,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 18,
                                          )),
                                      const SizedBox(width: 6),
                                      const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: _recentRuns.length,
                        ),
                      ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
          ],
        ),
      ),

      // ── New Test FAB ──────────────────────────────────────────────────────
      floatingActionButton: _cars.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _startNewTest,
              backgroundColor: _kAccent,
              foregroundColor: Colors.black,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('New Test',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            )
          : null,
    );
  }

  Future<void> _showAddCarDialog(BuildContext context) async {
    final makeCtrl = TextEditingController();
    final modelCtrl = TextEditingController();
    final yearCtrl = TextEditingController();
    final ccCtrl = TextEditingController();
    final modsCtrl = TextEditingController();
    String fuel = 'petrol';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
        child: StatefulBuilder(
          builder: (ctx, setModalState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Car',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _DialogField(ctrl: makeCtrl, hint: 'Make (e.g. Honda)'),
              const SizedBox(height: 12),
              _DialogField(ctrl: modelCtrl, hint: 'Model (e.g. Civic EK)'),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: _DialogField(
                      ctrl: yearCtrl,
                      hint: 'Year',
                      keyboardType: TextInputType.number),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DialogField(
                      ctrl: ccCtrl,
                      hint: 'Engine CC',
                      keyboardType: TextInputType.number),
                ),
              ]),
              const SizedBox(height: 12),
              // Fuel type dropdown
              DropdownButtonFormField<String>(
                initialValue: fuel,
                dropdownColor: _kSurface,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Fuel Type',
                  labelStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF1A1A28),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _kBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: _kBorder)),
                ),
                items: ['petrol', 'diesel', 'hybrid', 'electric']
                    .map((f) => DropdownMenuItem(
                        value: f,
                        child: Text(f[0].toUpperCase() + f.substring(1))))
                    .toList(),
                onChanged: (v) => setModalState(() => fuel = v!),
              ),
              const SizedBox(height: 12),
              _DialogField(
                  ctrl: modsCtrl,
                  hint: 'Modifications (optional)',
                  maxLines: 2),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (makeCtrl.text.isEmpty || modelCtrl.text.isEmpty) return;
                    final userId =
                        Supabase.instance.client.auth.currentUser!.id;
                    await Supabase.instance.client.from('user_cars').insert({
                      'user_id': userId,
                      'make': makeCtrl.text.trim(),
                      'model': modelCtrl.text.trim(),
                      'year': int.tryParse(yearCtrl.text),
                      'engine_cc': int.tryParse(ccCtrl.text),
                      'fuel_type': fuel,
                      'mods': modsCtrl.text.trim().isEmpty
                          ? null
                          : modsCtrl.text.trim(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    _loadCars();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Car',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Supporting widgets ────────────────────────────────────────────────────────

class _CarCard extends StatelessWidget {
  final Map<String, dynamic> car;
  final bool isSelected;
  const _CarCard({required this.car, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isSelected ? _kAccent : _kBorder, width: isSelected ? 2 : 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _kAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.directions_car_rounded,
                color: _kAccent, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${car['make']} ${car['model']}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15)),
                const SizedBox(height: 3),
                Text(
                  [
                    if (car['year'] != null) '${car['year']}',
                    if (car['engine_cc'] != null) '${car['engine_cc']}cc',
                    if (car['fuel_type'] != null)
                      (car['fuel_type'] as String)[0].toUpperCase() +
                          (car['fuel_type'] as String).substring(1),
                  ].join(' · '),
                  style:
                      const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                if (car['mods'] != null && car['mods'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(car['mods'],
                        style: const TextStyle(
                            color: _kAccent, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: Colors.white24, size: 20),
        ],
      ),
    );
  }
}

class _EmptyCarPrompt extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyCarPrompt({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: GestureDetector(
        onTap: onAdd,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: _kAccent.withOpacity(0.25),
                style: BorderStyle.solid),
          ),
          child: const Column(
            children: [
              Icon(Icons.add_circle_outline_rounded,
                  color: _kAccent, size: 44),
              SizedBox(height: 12),
              Text('Add your first car',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              SizedBox(height: 6),
              Text('Tap here to add a car and start measuring performance',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final TextInputType? keyboardType;
  final int maxLines;

  const _DialogField({
    required this.ctrl,
    required this.hint,
    this.keyboardType,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
        filled: true,
        fillColor: const Color(0xFF1A1A28),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kAccent, width: 1.5)),
      ),
    );
  }
}
