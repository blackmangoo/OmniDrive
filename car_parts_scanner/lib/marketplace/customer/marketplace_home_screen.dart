import '../../../chatbot/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'category_products_screen.dart';
import '../../core/theme/app_typography.dart';
import '../../core/motion/motion_stagger.dart';
import '../../core/motion/motion_tappable.dart';
import '../../core/motion/motion_counter.dart';
import 'package:car_parts_scanner/core/theme/app_colors.dart';


class MarketplaceHomeScreen extends StatefulWidget {
  const MarketplaceHomeScreen({super.key});
  @override
  State<MarketplaceHomeScreen> createState() => _MarketplaceHomeScreenState();
}

class _MarketplaceHomeScreenState extends State<MarketplaceHomeScreen> {
  final _searchCtrl = TextEditingController();
  List<Category> _categories = [];
  List<Product> _products = [];
  bool _loading = true;
  String? _searchQuery;
  int _cartCount = 0;

  static final _heroBanners = [
    _HeroBanner(
      'German-Engineered Suspension & Handling',
      'Precision coilovers, sway bars, and bush kits tested for peak stability.',
      const LinearGradient(
        colors: [Color(0xFF1A1D24), Color(0xFF101217)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      Icons.tune_rounded,
      const Color(0xFF7C6EF6),
    ),
    _HeroBanner(
      'OEM Powertrain & Engine Components',
      'Certified fuel injectors, turbochargers, and timing systems from verified vendors.',
      const LinearGradient(
        colors: [Color(0xFF141F1A), Color(0xFF0D1411)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      Icons.engineering_rounded,
      const Color(0xFF10B981),
    ),
    _HeroBanner(
      'Express Delivery on Track & Street Spares',
      'Live GPS rider dispatch straight to your workshop or pit lane.',
      const LinearGradient(
        colors: [Color(0xFF221A28), Color(0xFF140F19)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      Icons.local_shipping_outlined,
      const Color(0xFFA78BFA),
    ),
  ];

  static IconData _iconForCategory(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('brake')) return Icons.disc_full_rounded;
    if (lower.contains('engine') || lower.contains('motor')) return Icons.engineering_rounded;
    if (lower.contains('filter')) return Icons.filter_alt_rounded;
    if (lower.contains('light')) return Icons.light_mode_rounded;
    if (lower.contains('suspension')) return Icons.directions_car_rounded;
    if (lower.contains('tyre') || lower.contains('tire') || lower.contains('wheel')) return Icons.radio_button_unchecked;
    if (lower.contains('body')) return Icons.car_crash_rounded;
    if (lower.contains('electr')) return Icons.electrical_services_rounded;
    return Icons.build_circle_outlined;
  }

  static Color _colorForCategory(String name, String? colorHex) {
    if (colorHex != null && colorHex.isNotEmpty) {
      try {
        final hex = colorHex.replaceAll('#', '');
        return Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }
    final lower = name.toLowerCase();
    if (lower.contains('brake')) return const Color(0xFFEF4444);
    if (lower.contains('engine')) return const Color(0xFFF59E0B);
    if (lower.contains('filter')) return const Color(0xFF38BDF8);
    if (lower.contains('light')) return const Color(0xFFFBBF24);
    if (lower.contains('suspension')) return const Color(0xFF10B981);
    if (lower.contains('tyre') || lower.contains('wheel')) return const Color(0xFF94A3B8);
    if (lower.contains('body')) return const Color(0xFFA78BFA);
    if (lower.contains('electr')) return const Color(0xFF60A5FA);
    return AppColors.accent;
  }

  int _heroBannerIndex = 0;
  PageController? _pageCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _pageCtrl?.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (mounted) setState(() => _loading = true);
    final cats = await MarketplaceService.fetchCategories();
    final prods = await MarketplaceService.fetchProducts(searchQuery: _searchQuery);
    final cart = await MarketplaceService.fetchCart();
    if (mounted) {
      setState(() {
        _categories = cats;
        _products = prods;
        _cartCount = cart.length;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: kBg,
        body: RefreshIndicator(
          color: kAccent,
          backgroundColor: kCard,
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // ── App Bar ──────────────────────────────────────────────────────
              SliverAppBar(
                backgroundColor: kBg,
                expandedHeight: 0,
                pinned: true,
                surfaceTintColor: Colors.transparent,
                title: Row(
                  children: [
                    Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        gradient: kCyanGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.directions_car_rounded,
                          color: Colors.black, size: 18),
                    ),
                    SizedBox(width: 10),
                    Text('OmniDrive', style: AppTypography.title.copyWith(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: kTextPrimary, letterSpacing: -0.5)),
                  ],
                ),
                actions: [
                  Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.shopping_cart_checkout_rounded,
                            color: kTextSecondary),
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => CartScreen()))
                            .then((_) => _loadData()),
                      ),
                      if (_cartCount > 0) Positioned(
                        top: 8, right: 8,
                        child: Container(
                          width: 16, height: 16,
                          decoration: BoxDecoration(
                              color: kAccent, shape: BoxShape.circle),
                          child: Center(child: Text('$_cartCount',
                            style: TextStyle(fontSize: 9, color: Colors.black,
                                fontWeight: FontWeight.w800))),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.support_agent_rounded, color: kAccent),
                    onPressed: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => ChatScreen())),
                  ),
                  IconButton(
                    icon: Icon(Icons.notifications_none_rounded,
                        color: kTextSecondary),
                    onPressed: () {},
                  ),
                  SizedBox(width: 4),
                ],
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Search bar ────────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Container(
                        height: 48,
                        decoration: kFieldDeco(radius: 14),
                        child: TextField(
                          controller: _searchCtrl,
                          style: kBody(14, color: kTextPrimary),
                          onSubmitted: (v) {
                            setState(() => _searchQuery = v.isEmpty ? null : v);
                            _loadData();
                          },
                          decoration: InputDecoration(
                            hintText: 'Search auto parts, brands…',
                            hintStyle: kBody(13, color: kTextMuted),
                            prefixIcon: Icon(Icons.search_rounded,
                                color: kTextMuted, size: 20),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.close_rounded,
                                        color: kTextMuted, size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _searchQuery = null);
                                      _loadData();
                                    })
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),

                    // ── Hero Banner ───────────────────────────────────────
                    SizedBox(
                      height: 160,
                      child: PageView.builder(
                        controller: _pageCtrl,
                        onPageChanged: (i) => setState(() => _heroBannerIndex = i),
                        itemCount: _heroBanners.length,
                        itemBuilder: (_, i) {
                          final b = _heroBanners[i];
                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: b.gradient,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: b.accent.withValues(alpha: 0.3), width: 1),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(b.title, style: GoogleFonts.inter(
                                          fontSize: 14, fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary, height: 1.25, letterSpacing: -0.3)),
                                        const SizedBox(height: 6),
                                        Text(b.subtitle, style: GoogleFonts.inter(
                                          fontSize: 11, color: AppColors.textSecondary, height: 1.3)),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: b.accent.withValues(alpha: 0.18),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: b.accent.withValues(alpha: 0.4), width: 1),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text('Explore Spares',
                                                style: GoogleFonts.inter(fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.textPrimary, letterSpacing: -0.2)),
                                              const SizedBox(width: 4),
                                              Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.textPrimary),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(b.icon, size: 64,
                                      color: AppColors.textPrimary.withValues(alpha: 0.25)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Page dots
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_heroBanners.length, (i) =>
                          AnimatedContainer(
                            duration: Duration(milliseconds: 250),
                            margin: EdgeInsets.symmetric(horizontal: 3),
                            width: i == _heroBannerIndex ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _heroBannerIndex
                                  ? kAccent : kBorder,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          )),
                      ),
                    ),

                    // ── Categories ────────────────────────────────────────
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: kSectionHeader('Browse by Category',
                          trailing: TextButton(
                            onPressed: () {},
                            child: Text('See all',
                                style: AppTypography.label.copyWith(color: kAccent, fontWeight: FontWeight.w600)),
                          )),
                    ),
                    SizedBox(
                      height: 94,
                      child: _loading && _categories.isEmpty
                          ? ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: 6,
                              itemBuilder: (_, i) => Container(
                                width: 72,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 52,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: kCard,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: kBorder),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Container(
                                      width: 44,
                                      height: 10,
                                      decoration: BoxDecoration(
                                        color: kCard,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              itemCount: _categories.length,
                              itemBuilder: (_, i) {
                                final cat = _categories[i];
                                final icon = _iconForCategory(cat.name);
                                final color = _colorForCategory(cat.name, cat.color);
                                return StaggeredEntrance(
                                  index: i,
                                  child: TappableScale(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => CategoryProductsScreen(category: cat),
                                        ),
                                      ).then((_) => _loadData());
                                    },
                                    child: Container(
                                      width: 72,
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              color: color.withValues(alpha: 0.12),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(
                                                color: color.withValues(alpha: 0.25),
                                                width: 1,
                                              ),
                                            ),
                                            child: Icon(icon, color: color, size: 24),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            cat.name,
                                            style: GoogleFonts.inter(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: kTextSecondary,
                                            ),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: kSectionHeader('Featured Products'),
                    ),
                    SizedBox(height: 12),
                  ],
                ),
              ),

              // ── Products Grid ───────────────────────────────────────────────
              _loading
                  ? SliverPadding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 100),
                      sliver: SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (_, index) => Shimmer.fromColors(
                            baseColor: AppColors.surface,
                            highlightColor: AppColors.card,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                          childCount: 4,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.72,
                        ),
                      ),
                    )
                  : _products.isEmpty
                      ? SliverFillRemaining(child: _EmptyState())
                      : SliverPadding(
                          padding: EdgeInsets.fromLTRB(16, 0, 16, 100),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => StaggeredEntrance(
                                index: i,
                                child: _ProductCard(
                                  product: _products[i],
                                  onTap: () => Navigator.push(context,
                                    MaterialPageRoute(builder: (_) =>
                                      ProductDetailScreen(product: _products[i])))
                                    .then((_) => _loadData()),
                                ),
                              ),
                              childCount: _products.length,
                            ),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.72,
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

// ── Supporting widgets ─────────────────────────────────────────────────────────

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TappableScale(
      onTap: onTap,
      child: Container(
        decoration: kCardDeco(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Hero Transition
            Hero(
              tag: 'product_image_${product.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                child: AspectRatio(
                  aspectRatio: 1.2,
                  child: product.primaryImage.isNotEmpty
                      ? Image.network(product.primaryImage, fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => _PlaceholderImg())
                      : _PlaceholderImg(),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: AppTypography.title.copyWith(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: kTextPrimary, height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 4),
                    if (product.vendorShopName != null)
                      Text(product.vendorShopName!, style: kLabel(10),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              MotionCounter(
                                value: product.price,
                                prefix: 'Rs ',
                                style: GoogleFonts.inter(fontSize: 13,
                                  fontWeight: FontWeight.w800, color: kAccent),
                              ),
                              if (product.hasDiscount)
                                Text('Rs ${product.comparePrice!.toStringAsFixed(0)}',
                                  style: kBody(10, color: kTextMuted).copyWith(
                                    decoration: TextDecoration.lineThrough)),
                            ],
                          ),
                        ),
                        Container(
                          width: 30, height: 30,
                          decoration: BoxDecoration(
                            gradient: kCyanGradient,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.add_rounded,
                              color: Colors.black, size: 18),
                        ),
                      ],
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            color: product.stockQuantity > 0 ? kSuccess : kError,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 5),
                        Text(product.stockQuantity > 0 ? 'In Stock' : 'Out of Stock',
                          style: kLabel(9,
                            color: product.stockQuantity > 0 ? kSuccess : kError)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderImg extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: kCard,
    child: Center(child: Icon(Icons.car_repair_rounded,
        color: kBorder, size: 36)),
  );
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inventory_2_outlined, size: 64, color: kBorder),
        SizedBox(height: 16),
        Text('No products found', style: kHeadline(16, color: kTextSecondary)),
        SizedBox(height: 8),
        Text('Try a different search or category', style: kBody(13)),
      ],
    ),
  );
}

class _HeroBanner {
  final String title, subtitle;
  final LinearGradient gradient;
  final IconData icon;
  final Color accent;
  _HeroBanner(this.title, this.subtitle, this.gradient, this.icon, [this.accent = const Color(0xFF7C6EF6)]);
}
