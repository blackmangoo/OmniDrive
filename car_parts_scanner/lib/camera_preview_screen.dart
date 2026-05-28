import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'part_detection_service.dart';

// Shares the same color palette as the home screen
const _kAccent = Color(0xFF4FC3F7);
const _kBg = Color(0xFF0A0A0F);

class CameraPreviewScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraPreviewScreen({super.key, required this.cameras});

  @override
  State<CameraPreviewScreen> createState() => _CameraPreviewScreenState();
}

class _CameraPreviewScreenState extends State<CameraPreviewScreen>
    with TickerProviderStateMixin {
  late CameraController _controller;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  final PartDetectionService _service = PartDetectionService();

  // Capture-ring animation
  late final AnimationController _captureAnim;
  late final Animation<double> _captureScale;

  @override
  void initState() {
    super.initState();
    _captureAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _captureScale = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _captureAnim, curve: Curves.easeIn));
    _initCamera();
  }

  Future<void> _initCamera() async {
    if (widget.cameras.isEmpty) return;
    _controller = CameraController(
      widget.cameras[0],
      ResolutionPreset.medium, // medium = ~1280×720, faster upload than high
      enableAudio: false,
    );
    try {
      await _controller.initialize();
      if (mounted) setState(() => _isCameraInitialized = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Camera init error: $e')));
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    if (_isCameraInitialized) _controller.dispose();
    _captureAnim.dispose();
    super.dispose();
  }

  // ── Capture + analyse ─────────────────────────────────────────────────────

  Future<void> _capture() async {
    if (!_isCameraInitialized || _isCapturing) return;

    HapticFeedback.heavyImpact();
    await _captureAnim.forward();
    await _captureAnim.reverse();

    setState(() => _isCapturing = true);

    try {
      final XFile image = await _controller.takePicture();
      final result =
          await _service.analyzeAndFetchPart(File(image.path));

      // Pop back to home screen, passing the result
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) Navigator.pop(context, null);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            CircularProgressIndicator(color: _kAccent, strokeWidth: 2),
            SizedBox(height: 16),
            Text('Starting camera…',
                style: TextStyle(color: _kAccent, fontSize: 13)),
          ]),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Live camera preview
          CameraPreview(_controller),

          // Dark vignette edges
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.55)],
                radius: 1.0,
              ),
            ),
          ),

          // SafeArea overlay controls
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  child: Row(children: [
                    // Back button
                    Material(
                      color: Colors.black38,
                      borderRadius: BorderRadius.circular(50),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(50),
                        onTap: () => Navigator.pop(context),
                        child: const Padding(
                          padding: EdgeInsets.all(10),
                          child: Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // HUD label
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: _kAccent.withOpacity(0.5)),
                      ),
                      child: const Text(
                        'SCAN MODE',
                        style: TextStyle(
                            color: _kAccent,
                            letterSpacing: 2,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 42), // balance back button
                  ]),
                ),

                // Scanning reticle area (middle)
                const Spacer(),
                _ScanReticle(scanning: _isCapturing),
                const SizedBox(height: 20),

                // Framing tips — shown while not capturing
                if (!_isCapturing)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: _kAccent.withOpacity(0.25)),
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _TipRow(
                          icon: Icons.crop_free_rounded,
                          text: 'Fill the frame — part should cover 70%+ of view',
                        ),
                        SizedBox(height: 8),
                        _TipRow(
                          icon: Icons.wb_sunny_outlined,
                          text: 'Use good lighting — avoid shadows on the part',
                        ),
                        SizedBox(height: 8),
                        _TipRow(
                          icon: Icons.motion_photos_off_outlined,
                          text: 'Hold steady — avoid motion blur for best accuracy',
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 16),

                // Capture button row
                Padding(
                  padding: const EdgeInsets.only(bottom: 36),
                  child: _isCapturing
                      ? const Column(mainAxisSize: MainAxisSize.min, children: [
                          CircularProgressIndicator(
                              color: _kAccent, strokeWidth: 2.5),
                          SizedBox(height: 12),
                          Text('ANALYSING…',
                              style: TextStyle(
                                  color: _kAccent,
                                  letterSpacing: 2,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600)),
                        ])
                      : ScaleTransition(
                          scale: _captureScale,
                          child: GestureDetector(
                            onTap: _capture,
                            child: Container(
                              width: 78,
                              height: 78,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _kAccent, width: 3.5),
                                color: Colors.black26,
                                boxShadow: [
                                  BoxShadow(
                                    color: _kAccent.withOpacity(0.35),
                                    blurRadius: 20,
                                    spreadRadius: 4,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Container(
                                  width: 58,
                                  height: 58,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _kAccent,
                                  ),
                                  child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: Colors.white,
                                      size: 28),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Framing tip row ──────────────────────────────────────────────────────────

class _TipRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TipRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _kAccent, size: 16),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text,
              style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
      ],
    );
  }
}

// ─── Scanning reticle widget ───────────────────────────────────────────────────

class _ScanReticle extends StatefulWidget {
  final bool scanning;
  const _ScanReticle({required this.scanning});

  @override
  State<_ScanReticle> createState() => _ScanReticleState();
}

class _ScanReticleState extends State<_ScanReticle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
    _fade = Tween<double>(begin: 0.4, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fade,
      builder: (_, _) => Opacity(
        opacity: widget.scanning ? 1.0 : _fade.value,
        child: SizedBox(
          width: 240,
          height: 240,
          child: CustomPaint(
            painter: _ReticlePainter(
              color: widget.scanning ? Colors.white : _kAccent,
            ),
          ),
        ),
      ),
    );
  }
}

class _ReticlePainter extends CustomPainter {
  final Color color;
  _ReticlePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const r = 24.0; // corner radius
    const l = 40.0; // corner length

    final corners = [
      // top-left
      [Offset(0, l), Offset(0, r), Offset(r, 0), Offset(l, 0)],
      // top-right
      [Offset(size.width - l, 0), Offset(size.width - r, 0), Offset(size.width, r), Offset(size.width, l)],
      // bottom-right
      [Offset(size.width, size.height - l), Offset(size.width, size.height - r), Offset(size.width - r, size.height), Offset(size.width - l, size.height)],
      // bottom-left
      [Offset(l, size.height), Offset(r, size.height), Offset(0, size.height - r), Offset(0, size.height - l)],
    ];

    for (final pts in corners) {
      canvas.drawLine(pts[0], pts[1], paint);
      canvas.drawLine(pts[2], pts[3], paint);
    }
  }

  @override
  bool shouldRepaint(_ReticlePainter old) => old.color != color;
}
