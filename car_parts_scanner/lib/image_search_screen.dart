import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'camera_preview_screen.dart';
import 'part_detection_service.dart';
import 'core/theme/app_spacing.dart';
import 'core/theme/app_typography.dart';
import 'core/motion/motion_stagger.dart';
import 'core/motion/motion_tappable.dart';
import 'package:car_parts_scanner/core/theme/app_colors.dart';
import 'marketplace/customer/marketplace_home_screen.dart';
import 'marketplace/marketplace_constants.dart';


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
        vsync: this, duration: Duration(seconds: 2))
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
      setState(() => _isAnalyzing = true);
      final XFile? image =
          await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

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

  void _showResultsModal(PartDetectionResult result) async {
    final searchQuery = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _ResultsSheet(result: result),
    );

    if (searchQuery != null && searchQuery.trim().isNotEmpty && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => MarketplaceHomeScreen(
            initialSearchQuery: searchQuery.trim(),
          ),
        ),
      );
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
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
                  AppColors.accent.withValues(alpha: 0.07),
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
                SizedBox(height: 28),
                _buildSearchBar(),
                SizedBox(height: 32),
                _buildSectionLabel('HOW IT WORKS'),
                SizedBox(height: 14),
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
      padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
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
                    color: AppColors.accent
                        .withValues(alpha: 0.5 + _pulseCtrl.value * 0.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent
                            .withValues(alpha: _pulseCtrl.value * 0.6),
                        blurRadius: 8,
                        spreadRadius: 2,
                      )
                    ],
                  ),
                ),
              ),
              SizedBox(width: 9),
              Text(
                'OmniDrive AI',
                style: AppTypography.h2.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                ),
              ),
              Spacer(),
              // API status badge
              TappableScale(
                onTap: _checkApi,
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 400),
                  padding: EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (_apiLive ? AppColors.success : AppColors.error)
                        .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color:
                            (_apiLive ? AppColors.success : AppColors.error)
                                .withValues(alpha: 0.45)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle,
                          color:
                              _apiLive ? AppColors.success : AppColors.error,
                          size: 7),
                      SizedBox(width: 5),
                      Text(
                        _apiLive ? 'API Live' : 'API Offline',
                        style: TextStyle(
                          color: _apiLive
                              ? AppColors.success
                              : AppColors.error,
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
          SizedBox(height: 4),
          Text(
            'Automotive Vision System',
            style: AppTypography.caption.copyWith(
                color: AppColors.accent, fontSize: 12, letterSpacing: 1.8),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.08),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            // Gallery button
            TappableScale(
              onTap: _isAnalyzing ? null : _pickFromGallery,
              child: _SearchBarButton(
                icon: Icons.photo_library_rounded,
                tooltip: 'Pick from Gallery',
                radius: BorderRadius.horizontal(
                    left: Radius.circular(18)),
                onTap: _isAnalyzing ? null : _pickFromGallery,
              ),
            ),

            // Divider
            Container(
                width: 1,
                height: 28,
                color: AppColors.accent.withValues(alpha: 0.18)),

            // Hint text
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Scan or upload a car part…',
                  style: AppTypography.body.copyWith(color: AppColors.textMuted, fontSize: 14),
                ),
              ),
            ),

            // Divider
            Container(
                width: 1,
                height: 28,
                color: AppColors.accent.withValues(alpha: 0.18)),

            // Camera scan button
            Hero(
              tag: 'scan_results_hud',
              child: Material(
                color: Colors.transparent,
                child: TappableScale(
                  onTap: _isAnalyzing ? null : _openCameraScanner,
                  child: _SearchBarButton(
                    icon: Icons.camera_alt_rounded,
                    tooltip: 'Open Camera Scanner',
                    radius: BorderRadius.horizontal(
                        right: Radius.circular(18)),
                    onTap: _isAnalyzing ? null : _openCameraScanner,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: AppColors.textMuted,
          fontSize: 11,
          letterSpacing: 2.2,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFeatureList() {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20),
      children: [
        StaggeredEntrance(
          index: 0,
          child: _FeatureCard(
            icon: Icons.camera_alt_rounded,
            iconColor: AppColors.accent,
            title: 'Scan a Part',
            subtitle:
                'Point the camera at any car part — YOLO11 identifies it in ~110ms.',
          ),
        ),
        SizedBox(height: 12),
        StaggeredEntrance(
          index: 1,
          child: _FeatureCard(
            icon: Icons.photo_library_rounded,
            iconColor: AppColors.accent,
            title: 'Upload from Gallery',
            subtitle:
                'Select an existing photo of a part and get instant AI identification.',
          ),
        ),
        SizedBox(height: 12),
        StaggeredEntrance(
          index: 2,
          child: _FeatureCard(
            icon: Icons.analytics_rounded,
            iconColor: AppColors.success,
            title: '99.1% Top-1 Accuracy',
            subtitle:
                'Trained on 26,820 images across 50 car part classes (YOLO11 Large).',
          ),
        ),
        SizedBox(height: 12),
        StaggeredEntrance(
          index: 3,
          child: _FeatureCard(
            icon: Icons.store_rounded,
            iconColor: AppColors.accent,
            title: 'Marketplace — Coming Soon',
            subtitle:
                'Vendor listings, real-time pricing and delivery — Phase 4.',
          ),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.78),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
                color: AppColors.accent, strokeWidth: 2.5),
            SizedBox(height: 18),
            Text(
              'ANALYSING IMAGE…',
              style: AppTypography.label.copyWith(
                color: AppColors.accent,
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
          splashColor: AppColors.accent.withValues(alpha: 0.15),
          child: SizedBox(
            width: 58,
            height: double.infinity,
            child: Icon(
              icon,
              color: onTap == null ? Colors.grey[700] : AppColors.accent,
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.rMd),
        border:
            Border.all(color: AppColors.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.title.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text(subtitle,
                    style: AppTypography.body.copyWith(
                        color: AppColors.textMuted, fontSize: 12, height: 1.4)),
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

  Future<void> _openMarketplaceSearch(BuildContext context, String partName) async {
    final query = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CarModelPromptSheet(partName: partName),
    );

    if (query != null && query.trim().isNotEmpty && context.mounted) {
      Navigator.pop(context, query.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasError = result.error != null;
    final bool hasPart = result.part != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      minChildSize: 0.35,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(26)),
        ),
        child: ListView(
          controller: scrollCtrl,
          padding:
              EdgeInsets.fromLTRB(24, 12, 24, 32),
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                    color: AppColors.textMuted.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),

            // Top Hero Badge
            Center(
              child: Hero(
                tag: 'scan_results_hud',
                child: Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (hasError ? AppColors.error : AppColors.accent).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasError ? Icons.error_outline : Icons.analytics_rounded,
                    color: hasError ? AppColors.error : AppColors.accent,
                    size: 32,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),

            // ── Error state ──────────────────────────────────────────
            if (hasError) ...[
              Row(children: [
                Icon(Icons.error_outline,
                    color: AppColors.error, size: 26),
                SizedBox(width: 10),
                Expanded(
                  child: Text('Analysis Result',
                      style: AppTypography.h2.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ),
              ]),
              SizedBox(height: 10),
              Text(result.error!,
                  style: AppTypography.body.copyWith(
                      color: AppColors.textSecondary, fontSize: 14, height: 1.5)),
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
                      style: AppTypography.h1.copyWith(
                          color: AppColors.textPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          height: 1.2),
                    ),
                  ),
                  SizedBox(width: 10),
                  _ConfidenceBadge(
                      value: result.confidence),
                ],
              ),
              SizedBox(height: 12),

              // Animated Confidence Bar
              _ConfidenceProgressBar(
                confidence: result.confidence,
                color: result.confidence >= 80
                    ? AppColors.success
                    : result.confidence >= 50
                        ? AppColors.warning
                        : AppColors.error,
              ),
              SizedBox(height: 20),

              // Price card
              if (result.part!.averagePrice != null)
                _InfoCard(
                  icon: Icons.local_offer_rounded,
                  iconColor: AppColors.accent,
                  label: 'Estimated Price',
                  value:
                      'Rs. ${result.part!.averagePrice!.toStringAsFixed(0)}',
                ),

              // ── Search in Marketplace CTA Button ──────────────────
              const SizedBox(height: 16),
              TappableScale(
                onTap: () => _openMarketplaceSearch(context, result.part!.className),
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: kCyanGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: kAccent.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.storefront_rounded, color: Colors.black, size: 21),
                      const SizedBox(width: 10),
                      Text(
                        'Search in Marketplace',
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.black, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              if (result.part!.description != null) ...[
                SizedBox(height: 12),
                _SectionLabel('DESCRIPTION'),
                SizedBox(height: 6),
                Text(result.part!.description!,
                    style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5)),
              ],

              if (result.part!.compatibilityNotes != null) ...[
                SizedBox(height: 14),
                _SectionLabel('COMPATIBILITY'),
                SizedBox(height: 6),
                Text(result.part!.compatibilityNotes!,
                    style: AppTypography.body.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.5)),
              ],
            ],

            // ── Other possibilities (only show significant ones > 5%) ──────
            if (hasPart && result.allPredictions != null &&
                result.allPredictions!.length > 1) ...[
              // Filter to only show alternatives above 5% confidence
              Builder(builder: (_) {
                final alternatives = result.allPredictions!
                    .skip(1) // Skip the top prediction (already shown above)
                    .where((p) => (p['confidence'] as num).toDouble() > 5.0)
                    .toList();
                if (alternatives.isEmpty) return SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 20),
                    _SectionLabel('OTHER POSSIBILITIES'),
                    SizedBox(height: 12),
                    ...alternatives.asMap().entries.map((e) {
                      final idx = e.key;
                      final p = e.value;
                      final cls = p['class'] as String;
                      final conf = (p['confidence'] as num).toDouble();
                      return StaggeredEntrance(
                        index: idx,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () => _openMarketplaceSearch(context, cls),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Row(children: [
                                Expanded(
                                  child: Text(cls,
                                      style: AppTypography.body.copyWith(
                                          color: AppColors.textPrimary,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                                ),
                                Text('${conf.toStringAsFixed(1)}%',
                                    style: AppTypography.body.copyWith(
                                      color: AppColors.textMuted,
                                      fontSize: 13,
                                    )),
                                const SizedBox(width: 8),
                                Icon(Icons.search_rounded,
                                    size: 16, color: AppColors.accent),
                              ]),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],

            // ── Inference time footer ─────────────────────────────────
            if (result.inferenceTimeMs != null) ...[
              SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '⚡ ${result.inferenceTimeMs!.toStringAsFixed(0)} ms inference',
                  style: AppTypography.caption.copyWith(
                      color: AppColors.textMuted, fontSize: 11),
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
        ? AppColors.success
        : value >= 50
            ? AppColors.warning
            : AppColors.error;
    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
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
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: iconColor.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: iconColor, size: 20),
        SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted, fontSize: 11, letterSpacing: 0.5)),
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
        style: AppTypography.caption.copyWith(
            color: AppColors.textMuted,
            fontSize: 11,
            letterSpacing: 2,
            fontWeight: FontWeight.w600),
      );
}

// ─── Confidence animated progress bar ──────────────────────────────────────────

class _ConfidenceProgressBar extends StatefulWidget {
  final double confidence;
  final Color color;
  const _ConfidenceProgressBar({required this.confidence, required this.color});

  @override
  State<_ConfidenceProgressBar> createState() => _ConfidenceProgressBarState();
}

class _ConfidenceProgressBarState extends State<_ConfidenceProgressBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl;
  late final Animation<double> _progressAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _progressAnim = Tween<double>(begin: 0.0, end: widget.confidence / 100.0)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (MediaQuery.of(context).disableAnimations) {
          _animCtrl.value = 1.0;
        } else {
          _animCtrl.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _progressAnim,
      builder: (context, _) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progressAnim.value,
            backgroundColor: widget.color.withValues(alpha: 0.1),
            color: widget.color,
            minHeight: 6,
          ),
        );
      },
    );
  }
}

// ─── Car Model Prompt Modal Sheet ─────────────────────────────────────────────

class _CarModelPromptSheet extends StatefulWidget {
  final String partName;
  const _CarModelPromptSheet({required this.partName});

  @override
  State<_CarModelPromptSheet> createState() => _CarModelPromptSheetState();
}

class _CarModelPromptSheetState extends State<_CarModelPromptSheet> {
  final TextEditingController _carCtrl = TextEditingController();
  List<Map<String, dynamic>> _userCars = [];
  bool _loadingCars = true;
  String? _selectedCarChip;

  @override
  void initState() {
    super.initState();
    _loadUserCars();
    _carCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _carCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUserCars() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final data = await Supabase.instance.client
            .from('user_cars')
            .select('make, model, year')
            .eq('user_id', user.id)
            .order('created_at', ascending: false);
        if (mounted) {
          setState(() {
            _userCars = List<Map<String, dynamic>>.from(data);
            if (_userCars.isNotEmpty) {
              final first = _userCars.first;
              final label = '${first['make']} ${first['model']}'.trim();
              _selectedCarChip = label;
              _carCtrl.text = label;
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user cars for search prompt: $e');
    } finally {
      if (mounted) setState(() => _loadingCars = false);
    }
  }

  String get _currentQuery {
    final model = _carCtrl.text.trim();
    return model.isNotEmpty ? '$model ${widget.partName}' : widget.partName;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.textMuted.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.directions_car_rounded,
                    color: AppColors.accent,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Find Compatible Spares',
                        style: AppTypography.title.copyWith(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Part detected: ${widget.partName}',
                        style: AppTypography.caption.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Registered Cars (from user_cars table)
            if (_loadingCars)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Checking your garage…',
                      style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                    ),
                  ],
                ),
              )
            else if (_userCars.isNotEmpty) ...[
              Text(
                'YOUR REGISTERED VEHICLES',
                style: AppTypography.caption.copyWith(
                  color: AppColors.textMuted,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _userCars.map((car) {
                  final label = '${car['make']} ${car['model']}'.trim();
                  final isSelected = _selectedCarChip == label;
                  return ChoiceChip(
                    label: Text(
                      '🚗 $label${car['year'] != null ? ' (${car['year']})' : ''}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.black : AppColors.textPrimary,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: kAccent,
                    backgroundColor: AppColors.field,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? kAccent : AppColors.border,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCarChip = label;
                          _carCtrl.text = label;
                        } else {
                          _selectedCarChip = null;
                          _carCtrl.clear();
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Input field for car model
            Text(
              'CAR MODEL (OPTIONAL)',
              style: AppTypography.caption.copyWith(
                color: AppColors.textMuted,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: kFieldDeco(radius: 12),
              child: TextField(
                controller: _carCtrl,
                style: AppTypography.body.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'e.g. Honda Civic, Toyota Corolla 2018...',
                  hintStyle: AppTypography.body.copyWith(
                    color: AppColors.textMuted.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.directions_car_outlined,
                    color: AppColors.textMuted,
                    size: 20,
                  ),
                  suffixIcon: _carCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          color: AppColors.textMuted,
                          onPressed: () {
                            setState(() {
                              _selectedCarChip = null;
                              _carCtrl.clear();
                            });
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Live search preview box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, color: AppColors.accent, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Search query: ',
                    style: AppTypography.caption.copyWith(color: AppColors.textMuted),
                  ),
                  Expanded(
                    child: Text(
                      _currentQuery,
                      style: GoogleFonts.inter(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Search CTA
            SizedBox(
              width: double.infinity,
              height: 52,
              child: TappableScale(
                onTap: () => Navigator.pop(context, _currentQuery),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: kCyanGradient,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: kAccent.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.storefront_rounded, color: Colors.black, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _carCtrl.text.trim().isNotEmpty
                            ? 'Search ${_carCtrl.text.trim()} Spares'
                            : 'Search Spares in Marketplace',
                        style: GoogleFonts.inter(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            if (_carCtrl.text.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context, widget.partName),
                  child: Text(
                    'Search "${widget.partName}" Only (All Vehicles)',
                    style: AppTypography.body.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 12,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
