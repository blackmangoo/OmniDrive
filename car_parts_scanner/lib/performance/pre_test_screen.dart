import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'live_test_screen.dart';
import 'performance_models.dart';
import 'performance_run_service.dart';
import 'sensor_fusion_service.dart';
import 'obd_wifi_service.dart';
import '../core/theme/app_colors.dart';
import '../core/motion/motion_tappable.dart';

/// Pre-test check:
/// 1. Phone placement warning
/// 2. Wait for GPS/OBD connection
/// 3. Countdown → launch live test
class PreTestScreen extends StatefulWidget {
  final String carId;
  final List<MetricType> metrics;
  final bool obdMode; // false = GPS, true = OBD

  const PreTestScreen({
    super.key,
    required this.carId,
    required this.metrics,
    required this.obdMode,
  });

  @override
  State<PreTestScreen> createState() => _PreTestScreenState();
}

class _PreTestScreenState extends State<PreTestScreen> with SingleTickerProviderStateMixin {
  // Services
  SensorFusionService? _gpsService;
  ObdWifiService?      _obdService;
  late final PerformanceRunService _runService;

  Timer? _gpsPollingTimer;

  // State
  String _statusMsg    = 'Initializing...';
  bool   _sensorReady  = false;
  bool   _isCountingDown = false;
  int    _countdown    = 3;

  // Countdown animation
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _initServices();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  @override
  void dispose() {
    _gpsPollingTimer?.cancel();
    _pulseCtrl.dispose();
    if (!_isCountingDown) {
      _gpsService?.dispose();
      _obdService?.dispose();
    }
    super.dispose();
  }

  Future<void> _initServices() async {
    _runService = PerformanceRunService(
      selectedMetrics: widget.metrics,
      sensorMode: widget.obdMode ? 'obd2' : 'gps_imu',
      sensorFusionRef: null,
    );

    try {
      if (widget.obdMode) {
        setState(() => _statusMsg = 'Connecting to OBD-II WiFi...');
        _obdService = ObdWifiService();
        await _obdService!.connect();
        
        _runService.attachStreams(
          speedStream: _obdService!.speedStream,
          positionStream: const Stream.empty(),
        );

        if (mounted) {
          setState(() {
            _sensorReady = true;
            _statusMsg   = 'OBD Connected. Ready to test.';
          });
        }
      } else {
        setState(() => _statusMsg = 'Acquiring GPS lock...');
        _gpsService = SensorFusionService();
        _runService.sensorFusionRef = _gpsService;
        await _gpsService!.start();
        
        _gpsPollingTimer = Timer.periodic(const Duration(milliseconds: 500), (t) {
          if (!mounted) {
            t.cancel();
            return;
          }
          if (_gpsService!.isGpsReady) {
            t.cancel();
            _gpsPollingTimer = null;
            _runService.attachStreams(
              speedStream: _gpsService!.speedStream,
              positionStream: _gpsService!.positionStream,
            );
            if (mounted) {
              setState(() {
                _sensorReady = true;
                _statusMsg   = 'GPS Locked ✓  Ready to test.';
              });
            }
          } else if (mounted) {
            setState(() {
              final acc = _gpsService!.gpsAccuracyM.toStringAsFixed(0);
              _statusMsg = 'GPS accuracy: ${acc}m  (need < 15m)';
            });
          }
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _statusMsg = 'Sensor Error: $e');
    }
  }

  Future<void> _startCountdown() async {
    if (!_sensorReady) return;
    setState(() => _isCountingDown = true);

    if (!widget.obdMode && _gpsService != null) {
      setState(() => _statusMsg = 'Calibrating sensors (hold still)...');
      await _gpsService!.calibrate(durationMs: 1500);
    }

    for (int i = 3; i > 0; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      _pulseCtrl.forward(from: 0);
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted) return;
    HapticFeedback.vibrate();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => LiveTestScreen(
          carId: widget.carId,
          runService: _runService,
          gpsService: _gpsService,
          obdService: _obdService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: TappableScale(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.close_rounded, color: Colors.white70),
        ),
        title: const Text('Pre-Test Check', style: TextStyle(color: Colors.white70, fontSize: 15)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ── Phone placement icon ─────────────────────────────────
              Container(
                width: 110, height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.cyan.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.phone_android_rounded,
                  color: AppColors.cyan, size: 60),
              ),
              const SizedBox(height: 28),

              const Text(
                'Mount Your Phone Securely',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const Text(
                'Place the phone in a fixed mount or wedge it firmly where it will NOT move during the test. Movement = inaccurate results.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.6),
              ),

              const SizedBox(height: 40),

              // ── Sensor status box ────────────────────────────────────
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: _sensorReady 
                      ? AppColors.success.withValues(alpha: 0.08) 
                      : AppColors.surface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _sensorReady ? AppColors.success.withValues(alpha: 0.5) : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _sensorReady ? Icons.check_circle_rounded : Icons.sensors_rounded,
                      color: _sensorReady ? AppColors.success : AppColors.cyan,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _statusMsg,
                        style: TextStyle(
                          color: _sensorReady ? AppColors.success : Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (!_sensorReady && !_isCountingDown)
                      const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan),
                      )
                  ],
                ),
              ),

              const SizedBox(height: 56),

              // ── Action Button or Countdown ───────────────────────────
              if (_isCountingDown)
                ScaleTransition(
                  scale: Tween<double>(begin: 1.0, end: 1.3).animate(
                    CurvedAnimation(parent: _pulseCtrl, curve: Curves.elasticOut),
                  ),
                  child: Text(
                    _countdown.toString(),
                    style: const TextStyle(
                      color: AppColors.cyan,
                      fontSize: 100,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -2,
                    ),
                  ),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: TappableScale(
                    onTap: _sensorReady ? _startCountdown : null,
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _sensorReady ? AppColors.cyan : Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        'START TEST',
                        style: GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.4,
                          color: _sensorReady ? Colors.black : Colors.white38,
                        ),
                      ),
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
