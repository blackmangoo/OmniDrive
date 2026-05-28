import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'camera_preview_screen.dart';
import 'part_detection_service.dart';

// ─── Colour palette ──────────────────────────────────────────────────────────
const _kBg = Color(0xFF0A0A0F);
const _kSurface = Color(0xFF1C1C2E);
const _kAccent = Color(0xFF4FC3F7);
const _kAccent2 = Color(0xFF818CF8);
const _kGreen = Color(0xFF34D399);
const _kAmber = Color(0xFFF59E0B);
const _kTextMuted = Color(0xFF6B7280);
const _kTextSub = Color(0xFF4B5563);
// ─────────────────────────────────────────────────────────────────────────────

class ImageSearchScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const ImageSearchScreen({super.key, required this.cameras});

  @override
  State<ImageSearchScreen> createState() => _ImageSearchScreenState();
}

class _ImageSearchScreenState extends State<ImageSearchScreen>
    with SingleTickerProviderStateMixin {
  bool _isAnalyzing = false;
  bool _apiLive = false;
  final ImagePicker _picker = ImagePicker();
  final PartDetectionService _service = PartDetectionService();
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _checkApi();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkApi() async {
    final alive = await _service.checkApiHealth();
    if (mounted) setState(() => _apiLive = alive);
  }

  // ── Camera ────────────────────────────────────────────────────────────────

  Future<void> _openCameraScanner() async {
    if (widget.cameras.isEmpty) {
      _showSnack('No camera detected on this device.');
      return;
    }
    HapticFeedback.lightImpact();

    final result = await Navigator.push<PartDetectionResult>(
      context,
      MaterialPageRoute(
        builder: (_) => CameraPreviewScreen(cameras: widget.cameras),
      ),
    );

    if (result != null && mounted) _showResultsModal(result);
  }

  // ── Gallery ───────────────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    if (_isAnalyzing) return;
    HapticFeedback.lightImpact();
    try {
      final XFile? image =
          await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isAnalyzing = true);
      final result =
          await _service.analyzeAndFetchPart(File(image.path));
      if (mounted) _showResultsModal(result);
    } catch (e) {
      _showSnack('Gallery Error: $e');
    } finally {
      if (mounted) setState(() => _isAnalyzing = false);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  void _showResultsModal(PartDetectionResult result) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ResultsSheet(result: result),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      body: Stack(
        children: [
          // Subtle radial background glow
          Positioned(
            top: -80,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  _kAccent.withOpacity(0.07),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 28),
                _buildSearchBar(),
                const SizedBox(height: 32),
                _buildSectionLabel('HOW IT WORKS'),
                const SizedBox(height: 14),
                Expanded(child: _buildFeatureList()),
              ],
            ),
          ),

          // Full-screen loading overlay (gallery analyse)
          if (_isAnalyzing) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // ── Sub-widgets ───────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Animated accent dot
              AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (_, _) => Container(
                  width: 9,
                  height: 9,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kAccent
                        .withOpacity(0.5 + _pulseCtrl.value * 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: _kAccent
                            .withOpacity(_pulseCtrl.value * 0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 9),
              const Text(
                'OmniDrive AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              const Spacer(),
              // API status badge
              GestureDetector(
                onTap: _checkApi,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 400),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (_apiLive ? _kGreen : Colors.redAccent)
                        .withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                            (_apiLive ? _kGreen : Colors.redAccent)
                                .withOpacity(0.45)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle,
                          color:
                              _apiLive ? _kGreen : Colors.redAccent,
                          size: 7),
                      const SizedBox(width: 5),
                      Text(
                        _apiLive ? 'API Live' : 'API Offline',
                        style: TextStyle(
                          color: _apiLive
                              ? _kGreen
                              : Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Automotive Vision System',
            style: TextStyle(
                color: _kAccent, fontSize: 12, letterSpacing: 1.8),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _kAccent.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: _kAccent.withOpacity(0.08),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            // Gallery button
            _SearchBarButton(
              icon: Icons.photo_library_rounded,
              tooltip: 'Pick from Gallery',
              radius: const BorderRadius.horizontal(
                  left: Radius.circular(18)),
              onTap: _isAnalyzing ? null : _pickFromGallery,
            ),

            // Divider
            Container(
                width: 1,
                height: 28,
                color: _kAccent.withOpacity(0.18)),

            // Hint text
            const Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Scan or upload a car part…',
                  style: TextStyle(color: _kTextMuted, fontSize: 14),
                ),
              ),
            ),

            // Divider
            Container(
                width: 1,
                height: 28,
                color: _kAccent.withOpacity(0.18)),

            // Camera scan button
            _SearchBarButton(
              icon: Icons.camera_alt_rounded,
              tooltip: 'Open Camera Scanner',
              radius: const BorderRadius.horizontal(
                  right: Radius.circular(18)),
              onTap: _isAnalyzing ? null : _openCameraScanner,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        label,
        style: const TextStyle(
          color: _kTextSub,
          fontSize: 11,
          letterSpacing: 2.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: const [
        _FeatureCard(
          icon: Icons.camera_alt_rounded,
          iconColor: _kAccent,
          title: 'Scan a Part',
          subtitle:
              'Point the camera at any car part — YOLO11 identifies it in ~110ms.',
        ),
        SizedBox(height: 12),
        _FeatureCard(
          icon: Icons.photo_library_rounded,
          iconColor: _kAccent2,
          title: 'Upload from Gallery',
          subtitle:
              'Select an existing photo of a part and get instant AI identification.',
        ),
        SizedBox(height: 12),
        _FeatureCard(
          icon: Icons.analytics_rounded,
          iconColor: _kGreen,
          title: '99.1% Top-1 Accuracy',
          subtitle:
              'Trained on 26,820 images across 50 car part classes (YOLO11 Large).',
        ),
        SizedBox(height: 12),
        _FeatureCard(
          icon: Icons.store_rounded,
          iconColor: _kAmber,
          title: 'Marketplace — Coming Soon',
          subtitle:
              'Vendor listings, real-time pricing and delivery — Phase 4.',
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.78),
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
                color: _kAccent, strokeWidth: 2.5),
            SizedBox(height: 18),
            Text(
              'ANALYSING IMAGE…',
              style: TextStyle(
                color: _kAccent,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Reusable search-bar icon button ─────────────────────────────────────────

class _SearchBarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final BorderRadius radius;
  final VoidCallback? onTap;

  const _SearchBarButton({
    required this.icon,
    required this.tooltip,
    required this.radius,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          splashColor: _kAccent.withOpacity(0.15),
          child: SizedBox(
            width: 58,
            height: double.infinity,
            child: Icon(
              icon,
              color: onTap == null ? Colors.grey[700] : _kAccent,
              size: 25,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Feature info card ────────────────────────────────────────────────────────

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;

  const _FeatureCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: _kTextMuted, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Results bottom sheet ─────────────────────────────────────────────────────

class _ResultsSheet extends StatelessWidget {
  final PartDetectionResult result;
  const _ResultsSheet({required this.result});

  @override
  Widget build(BuildContext context) {
    final bool hasError = result.error != null;
    final bool hasPart = result.part != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      minChildSize: 0.35,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: _kSurface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding:
              const EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: Colors.grey[700],
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),

            // ── Error state ──────────────────────────────────────────
            if (hasError) ...[
              Row(children: [
                const Icon(Icons.error_outline,
                    color: Colors.redAccent, size: 26),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Analysis Result',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ),
              ]),
              const SizedBox(height: 10),
              Text(result.error!,
                  style: const TextStyle(
                      color: Color(0xFF9CA3AF), fontSize: 14, height: 1.5)),
            ],

            // ── Success state ─────────────────────────────────────────
            if (hasPart) ...[
              // Part name + confidence badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      result.part!.className,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _ConfidenceBadge(
                      value: result.confidence),
                ],
              ),
              const SizedBox(height: 16),

              // Price card
              if (result.part!.averagePrice != null)
                _InfoCard(
                  icon: Icons.local_offer_rounded,
                  iconColor: _kAccent,
                  label: 'Estimated Price',
                  value:
                      '\$${result.part!.averagePrice!.toStringAsFixed(2)}',
                ),

              if (result.part!.description != null) ...[
                const SizedBox(height: 12),
                _SectionLabel('DESCRIPTION'),
                const SizedBox(height: 6),
                Text(result.part!.description!,
                    style: const TextStyle(
                        color: Color(0xFFD1D5DB),
                        fontSize: 14,
                        height: 1.5)),
              ],

              if (result.part!.compatibilityNotes != null) ...[
                const SizedBox(height: 14),
                _SectionLabel('COMPATIBILITY'),
                const SizedBox(height: 6),
                Text(result.part!.compatibilityNotes!,
                    style: const TextStyle(
                        color: Color(0xFFD1D5DB),
                        fontSize: 14,
                        height: 1.5)),
              ],
            ],

            // ── All predictions (always show if present) ──────────────
            if (result.allPredictions != null &&
                result.allPredictions!.isNotEmpty) ...[
              const SizedBox(height: 20),
              _SectionLabel('ALL PREDICTIONS'),
              const SizedBox(height: 10),
              ...result.allPredictions!.asMap().entries.map((e) {
                final idx = e.key;
                final p = e.value;
                final cls = p['class'] as String;
                final conf =
                    (p['confidence'] as num).toDouble();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: (idx == 0 ? _kAccent : Colors.grey)
                            .withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${idx + 1}',
                          style: TextStyle(
                            color: idx == 0 ? _kAccent : Colors.grey,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          )),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child:
                          Text(cls,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 13)),
                    ),
                    Text('${conf.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: idx == 0 ? _kAccent : _kTextMuted,
                          fontSize: 13,
                          fontWeight: idx == 0
                              ? FontWeight.w700
                              : FontWeight.normal,
                        )),
                  ]),
                );
              }),
            ],

            // ── Inference time footer ─────────────────────────────────
            if (result.inferenceTimeMs != null) ...[
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '⚡ ${result.inferenceTimeMs!.toStringAsFixed(0)} ms inference',
                  style: const TextStyle(
                      color: _kTextSub, fontSize: 11),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double value;
  const _ConfidenceBadge({required this.value});
  @override
  Widget build(BuildContext context) {
    final color = value >= 80
        ? _kGreen
        : value >= 50
            ? _kAmber
            : Colors.redAccent;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Text(
        '${value.toStringAsFixed(1)}%',
        style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 14),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  const _InfoCard(
      {required this.icon,
      required this.iconColor,
      required this.label,
      required this.value});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: iconColor.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  color: _kTextMuted, fontSize: 11, letterSpacing: 0.5)),
          Text(value,
              style: TextStyle(
                  color: iconColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
            color: _kTextSub,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w600),
      );
}
