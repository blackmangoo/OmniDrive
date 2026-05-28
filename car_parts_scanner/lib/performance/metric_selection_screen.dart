import 'package:flutter/material.dart';
import 'performance_models.dart';

const _kBg     = Color(0xFF0A0A0F);
const _kSurface = Color(0xFF12121A);
const _kAccent  = Color(0xFF4FC3F7);
const _kBorder  = Color(0xFF1E1E2E);
const _kGreen   = Color(0xFF34D399);
const _kAmber   = Color(0xFFF59E0B);

/// Screen where the user selects:
///  • Test type (ACCELERATION or BRAKING) — segmented toggle
///  • Which metrics to measure (checkboxes per type)
///  • Sensor mode (GPS + IMU or OBD-II WiFi)
class MetricSelectionScreen extends StatefulWidget {
  const MetricSelectionScreen({super.key});

  @override
  State<MetricSelectionScreen> createState() => _MetricSelectionScreenState();
}

class _MetricSelectionScreenState extends State<MetricSelectionScreen>
    with SingleTickerProviderStateMixin {
  // 0 = Acceleration, 1 = Braking
  int _testTypeIndex = 0;
  late final TabController _tabCtrl;

  final Set<MetricType> _selected = {MetricType.zeroTo100}; // sensible default

  bool _obdMode = false; // false = GPS+IMU, true = OBD-II WiFi

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (_tabCtrl.indexIsChanging) {
          setState(() {
            _testTypeIndex = _tabCtrl.index;
            // Clear selected metrics when switching type
            _selected.clear();
            if (_testTypeIndex == 0) {
              _selected.add(MetricType.zeroTo100); // default accel preset
            } else {
              _selected.add(MetricType.hundredToZero); // braking is the only option
            }
          });
        }
      });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  bool get _canProceed => _selected.isNotEmpty;

  List<MetricType> get _accelerationMetrics =>
      [MetricType.zeroTo60, MetricType.zeroTo100, MetricType.quarterMile];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kBg,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Configure Test',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Segmented toggle: Acceleration | Braking ───────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Container(
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _kBorder),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: _kAccent.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kAccent.withOpacity(0.6)),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.rocket_launch_rounded, size: 16),
                        SizedBox(width: 8),
                        Text('Acceleration',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.stop_circle_outlined, size: 16),
                        SizedBox(width: 8),
                        Text('Braking',
                            style: TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
                labelColor: _kAccent,
                unselectedLabelColor: Colors.white38,
              ),
            ),
          ),

          // ── Metric checkboxes ──────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                // ── Acceleration tab ──────────────────────────────────────
                _MetricList(
                  metrics: _accelerationMetrics,
                  selected: _selected,
                  onToggle: (m, v) => setState(() {
                    if (v) _selected.add(m); else _selected.remove(m);
                  }),
                  note: 'All selected metrics are measured in a single drive.',
                  noteIcon: Icons.info_outline_rounded,
                  noteColor: _kAccent,
                ),

                // ── Braking tab ───────────────────────────────────────────
                _MetricList(
                  metrics: const [MetricType.hundredToZero],
                  selected: _selected,
                  onToggle: (m, v) => setState(() {
                    if (v) _selected.add(m); else _selected.remove(m);
                  }),
                  note: 'Accelerate past 100 km/h, then brake hard on command.',
                  noteIcon: Icons.warning_amber_rounded,
                  noteColor: _kAmber,
                ),
              ],
            ),
          ),

          // ── Sensor mode toggle ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Sensor Mode',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _SensorModeToggle(
                  isObd: _obdMode,
                  onChanged: (v) => setState(() => _obdMode = v),
                ),
                if (_obdMode)
                  const Padding(
                    padding: EdgeInsets.only(top: 10),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_rounded, color: _kAmber, size: 14),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Make sure your phone is connected to the OBD-II WiFi network before proceeding.',
                            style: TextStyle(color: _kAmber, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // ── Proceed button ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _canProceed
                    ? () => Navigator.pop(context, {
                          'metrics': _selected.toList(),
                          'obdMode': _obdMode,
                        })
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kAccent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white12,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Configure & Continue',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Supporting widgets ──────────────────────────────────────────────────────

class _MetricList extends StatelessWidget {
  final List<MetricType> metrics;
  final Set<MetricType> selected;
  final void Function(MetricType, bool) onToggle;
  final String note;
  final IconData noteIcon;
  final Color noteColor;

  const _MetricList({
    required this.metrics,
    required this.selected,
    required this.onToggle,
    required this.note,
    required this.noteIcon,
    required this.noteColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Info note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: noteColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: noteColor.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                Icon(noteIcon, color: noteColor, size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(note,
                      style: TextStyle(color: noteColor, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Metric tiles
          ...metrics.map(
            (m) => _MetricTile(
              metric:   m,
              selected: selected.contains(m),
              onToggle: (v) => onToggle(m, v),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  final MetricType metric;
  final bool selected;
  final ValueChanged<bool> onToggle;

  const _MetricTile({
    required this.metric,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onToggle(!selected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? _kAccent.withOpacity(0.1) : _kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _kAccent.withOpacity(0.5) : _kBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _kAccent : Colors.transparent,
                border: Border.all(
                    color: selected ? _kAccent : Colors.white24, width: 1.5),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded,
                      color: Colors.black, size: 14)
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(metric.displayName,
                      style: TextStyle(
                          color: selected ? Colors.white : Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(_metricSubtitle(metric),
                      style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _metricSubtitle(MetricType m) {
    switch (m) {
      case MetricType.zeroTo60:    return 'Time from standstill to 60 km/h';
      case MetricType.zeroTo100:   return 'Time from standstill to 100 km/h';
      case MetricType.quarterMile: return '402 m elapsed time + trap speed';
      case MetricType.hundredToZero: return 'Distance & time from 100 to full stop';
    }
  }
}

class _SensorModeToggle extends StatelessWidget {
  final bool isObd;
  final ValueChanged<bool> onChanged;

  const _SensorModeToggle({required this.isObd, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _ModeChip(
          label: 'GPS + IMU',
          icon: Icons.gps_fixed_rounded,
          selected: !isObd,
          onTap: () => onChanged(false),
          description: 'Uses phone GPS & accelerometer',
        ),
        const SizedBox(width: 12),
        _ModeChip(
          label: 'OBD-II WiFi',
          icon: Icons.bluetooth_connected_rounded,
          selected: isObd,
          onTap: () => onChanged(true),
          description: 'Uses ECU wheel speed sensor',
        ),
      ],
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  final String description;

  const _ModeChip({
    required this.label, required this.icon, required this.selected,
    required this.onTap, required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? _kAccent.withOpacity(0.1) : _kSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: selected ? _kAccent.withOpacity(0.5) : _kBorder,
                width: selected ? 1.5 : 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: selected ? _kAccent : Colors.white38, size: 20),
              const SizedBox(height: 8),
              Text(label,
                  style: TextStyle(
                      color: selected ? Colors.white : Colors.white54,
                      fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 3),
              Text(description,
                  style: const TextStyle(color: Colors.white24, fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
}
