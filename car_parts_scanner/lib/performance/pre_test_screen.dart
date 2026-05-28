import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'live_test_screen.dart';
import 'performance_models.dart';
import 'performance_run_service.dart';
import 'sensor_fusion_service.dart';
import 'obd_wifi_service.dart';

const _kBg      = Color(0xFF0A0A0F);
const _kSurface = Color(0xFF1C1C2E);
const _kAccent  = Color(0xFF4FC3F7);
const _kGreen   = Color(0xFF34D399);

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

  // FIX A2: Hold a ref to the GPS polling timer so we can cancel it on dispose.
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
    // FIX A2: Cancel the GPS polling timer if user backs out mid-acquisition.
    _gpsPollingTimer?.cancel();
    _pulseCtrl.dispose();
    // Only dispose services if we never launched the live test
    // (if we did, LiveTestScreen owns them)
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
      sensorFusionRef: widget.obdMode ? null : null, // set after init
    );

    try {
      if (widget.obdMode) {
        setState(() => _statusMsg = 'Connecting to OBD-II WiFi...');
        _obdService = ObdWifiService();
        await _obdService!.connect();
        
        _runService.attachStreams(
          speedStream: _obdService!.speedStream,
          positionStream: const Stream.empty(), // OBD doesn't give GPS pos
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
        
        // FIX A2: Store the timer so it can be cancelled on dispose.
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

    // Calibrate accelerometer at rest before starting (if GPS mode)
    if (!widget.obdMode && _gpsService != null) {
      setState(() => _statusMsg = 'Calibrating sensors (hold still)...');
      await _gpsService!.calibrate(durationMs: 1500);
    }

    for (int i = 3; i > 0; i--) {
      if (!mounted) return;
      setState(() => _countdown = i);
      _pulseCtrl.forward(from: 0); // Trigger pulse animation
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(seconds: 1));
    }

    if (!mounted) return;
    HapticFeedback.vibrate();

    // Launch live test and pass the initialized services forward
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
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
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
                  color: _kSurface,
                  border: Border.all(color: _kAccent.withValues(alpha: 0.3), width: 2),
                ),
                child: const Icon(Icons.phone_android_rounded,
                  color: _kAccent, size: 60),
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
                      ? _kGreen.withValues(alpha: 0.08) 
                      : _kSurface.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _sensorReady ? _kGreen.withValues(alpha: 0.5) : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _sensorReady ? Icons.check_circle_rounded : Icons.sensors_rounded,
                      color: _sensorReady ? _kGreen : _kAccent,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _statusMsg,
                        style: TextStyle(
                          color: _sensorReady ? _kGreen : Colors.white70,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (!_sensorReady && !_isCountingDown)
                      const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _kAccent),
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
                      color: _kAccent,
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
                  child: ElevatedButton(
                    onPressed: _sensorReady ? _startCountdown : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kAccent,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.white.withValues(alpha: 0.08),
                      disabledForegroundColor: Colors.white38,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('START TEST',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: 1.4)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
