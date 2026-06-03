import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'category_products_screen.dart';

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

  static const _heroBanners = [
    _HeroBanner('Precision Parts for Peak Performance',
        'Get up to 30% off German-engineered suspension kits this week.',
        kCyanGradient, Icons.car_repair_rounded),
    _HeroBanner('New Arrivals: Engine Components',
        'OEM-quality engine parts from verified vendors.',
        LinearGradient(colors: [Color(0xFF059669), Color(0xFF047857)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        Icons.build_circle_rounded),
    _HeroBanner('Free Delivery on Orders over Rs 2,000',
        'More savings, faster to your doorstep.',
        LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        Icons.local_shipping_rounded),
  ];

  static const _categoryList = [
    _CatData('Brakes',      Icons.disc_full_rounded,          Color(0xFFEF4444)),
    _CatData('Engine',      Icons.engineering_rounded,        Color(0xFFF59E0B)),
    _CatData('Filters',     Icons.filter_alt_rounded,          Color(0xFF4FC3F7)),
    _CatData('Lights',      Icons.light_mode_rounded,          Color(0xFFFBBF24)),
    _CatData('Suspension',  Icons.directions_car_rounded,     Color(0xFF10B981)),
    _CatData('Tyres',       Icons.radio_button_unchecked,     Color(0xFF6B7280)),
    _CatData('Body Parts',  Icons.car_crash_rounded,          Color(0xFFA78BFA)),
    _CatData('Electrical',  Icons.electrical_services_rounded, Color(0xFF60A5FA)),
  ];

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
    setState(() => _loading = true);
    final cats = await MarketplaceService.fetchCategories();
    final prods = await MarketplaceService.fetchProducts(searchQuery: _searchQuery);
    final cart = await MarketplaceService.fetchCart();
    if (mounted) setState(() {
      _categories = cats;
      _products = prods;
      _cartCount = cart.length;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: kBg,
        body: RefreshIndicator(
          color: kCyan,
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
                      child: const Icon(Icons.directions_car_rounded,
                          color: Colors.black, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Text('OmniDrive', style: GoogleFonts.inter(
                      fontSize: 18, fontWeight: FontWeight.w800,
                      color: kTextPrimary, letterSpacing: -0.5)),
                  ],
                ),
                actions: [
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.shopping_cart_checkout_rounded,
                            color: kTextSecondary),
                        onPressed: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const CartScreen()))
                            .then((_) => _loadData()),
                      ),
                      if (_cartCount > 0) Positioned(
                        top: 8, right: 8,
                        child: Container(
                          width: 16, height: 16,
                          decoration: const BoxDecoration(
                              color: kCyan, shape: BoxShape.circle),
                          child: Center(child: Text('$_cartCount',
                            style: TextStyle(fontSize: 9, color: Colors.black,
                                fontWeight: FontWeight.w800))),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_none_rounded,
                        color: kTextSecondary),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 4),
                ],
              ),

              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Search bar ────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Container(
                        height: 48,
                        decoration: kGlassDeco(radius: 14),
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
                            prefixIcon: const Icon(Icons.search_rounded,
                                color: kTextMuted, size: 20),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.close_rounded,
                                        color: kTextMuted, size: 18),
                                    onPressed: () {
                                      _searchCtrl.clear();
                                      setState(() => _searchQuery = null);
                                      _loadData();
                                    })
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
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
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: b.gradient,
                                borderRadius: BorderRadius.circular(20),
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
                                          fontSize: 15, fontWeight: FontWeight.w800,
                                          color: Colors.white, height: 1.25)),
                                        const SizedBox(height: 6),
                                        Text(b.subtitle, style: GoogleFonts.inter(
                                          fontSize: 11, color: Colors.white70)),
                                        const SizedBox(height: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text('Shop Now',
                                            style: GoogleFonts.inter(fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(b.icon, size: 64,
                                      color: Colors.white.withValues(alpha: 0.25)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    // Page dots
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_heroBanners.length, (i) =>
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == _heroBannerIndex ? 20 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i == _heroBannerIndex
                                  ? kCyan : kBorder,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          )),
                      ),
                    ),

                    // ── Categories ────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: kSectionHeader('Browse by Category',
                          trailing: TextButton(
                            onPressed: () {},
                            child: Text('See all',
                              style: kBody(12, color: kCyan, fw: FontWeight.w600)),
                          )),
                    ),
                    SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _categoryList.length,
                        itemBuilder: (_, i) {
                          final cat = _categoryList[i];
                          return GestureDetector(
                            onTap: () {
                              final dbCat = _categories.firstWhere(
                                (c) => c.name.toLowerCase() == cat.label.toLowerCase(),
                                orElse: () => Category(id: '', name: cat.label),
                              );
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CategoryProductsScreen(category: dbCat),
                                ),
                              ).then((_) => _loadData());
                            },
                            child: Container(
                              width: 72,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                children: [
                                  Container(
                                    width: 52, height: 52,
                                    decoration: BoxDecoration(
                                      color: cat.color.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                          color: cat.color.withValues(alpha: 0.3)),
                                    ),
                                    child: Icon(cat.icon, color: cat.color, size: 24),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(cat.label, style: kBody(10, color: kTextSecondary),
                                    textAlign: TextAlign.center, maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: kSectionHeader('Featured Products'),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),

              // ── Products Grid ───────────────────────────────────────────────
              _loading
                  ? const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator(color: kCyan)))
                  : _products.isEmpty
                      ? SliverFillRemaining(child: _EmptyState())
                      : SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          sliver: SliverGrid(
                            delegate: SliverChildBuilderDelegate(
                              (_, i) => _ProductCard(
                                product: _products[i],
                                onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) =>
                                    ProductDetailScreen(product: _products[i])))
                                  .then((_) => _loadData()),
                              ),
                              childCount: _products.length,
                            ),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.72,
                            ),
                          ),
                        ),

              // ── Vendor & AI Promo ───────────────────────────────────────────
              SliverToBoxAdapter(
                child: _loading ? const SizedBox() : Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                  child: Column(
                    children: [
                      const SizedBox(height: 16),
                      _PromoCard(
                        icon: Icons.storefront_rounded,
                        accent: kVendor,
                        title: 'Vendor Portal',
                        subtitle: 'Start selling your auto parts to thousands of customers.',
                        label: 'Start Selling',
                        onTap: () {},
                      ),
                      const SizedBox(height: 12),
                      _PromoCard(
                        icon: Icons.document_scanner_rounded,
                        accent: kCyan,
                        title: 'AI Diagnostics',
                        subtitle: 'Scan your dashboard lights to identify the right part.',
                        label: 'Scan Now',
                        onTap: () {},
                      ),
                    ],
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: kCardDeco(radius: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
              child: AspectRatio(
                aspectRatio: 1.2,
                child: product.primaryImage.isNotEmpty
                    ? Image.network(product.primaryImage, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _PlaceholderImg())
                    : _PlaceholderImg(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(product.name, style: GoogleFonts.inter(
                      fontSize: 12, fontWeight: FontWeight.w600,
                      color: kTextPrimary, height: 1.3),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    if (product.vendorShopName != null)
                      Text(product.vendorShopName!, style: kLabel(10),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rs ${product.price.toStringAsFixed(0)}',
                                style: GoogleFonts.inter(fontSize: 13,
                                  fontWeight: FontWeight.w800, color: kCyan)),
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
                          child: const Icon(Icons.add_rounded,
                              color: Colors.black, size: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            color: product.stockQuantity > 0 ? kSuccess : kError,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
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
    child: const Center(child: Icon(Icons.car_repair_rounded,
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
        const SizedBox(height: 16),
        Text('No products found', style: kHeadline(16, color: kTextSecondary)),
        const SizedBox(height: 8),
        Text('Try a different search or category', style: kBody(13)),
      ],
    ),
  );
}

class _PromoCard extends StatelessWidget {
  final IconData icon;
  final Color accent;
  final String title, subtitle, label;
  final VoidCallback onTap;
  const _PromoCard({required this.icon, required this.accent,
    required this.title, required this.subtitle,
    required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: kGlowDeco(accent, radius: 16),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(
                  fontSize: 14, fontWeight: FontWeight.w700, color: kTextPrimary)),
                const SizedBox(height: 3),
                Text(subtitle, style: kBody(11), maxLines: 2,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: accent.withValues(alpha: 0.3)),
            ),
            child: Text(label, style: kBody(11, color: accent, fw: FontWeight.w600)),
          ),
        ],
      ),
    ),
  );
}

class _HeroBanner {
  final String title, subtitle;
  final LinearGradient gradient;
  final IconData icon;
  const _HeroBanner(this.title, this.subtitle, this.gradient, this.icon);
}

class _CatData {
  final String label;
  final IconData icon;
  final Color color;
  const _CatData(this.label, this.icon, this.color);
}
