import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';
import '../../core/theme/app_typography.dart';
import '../../core/motion/motion_tappable.dart';

// ── Product Detail Screen (Stitch Design) ─────────────────────────────────────
class ProductDetailScreen extends StatefulWidget {
  final Product product;
  const ProductDetailScreen({super.key, required this.product});
  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _qty = 1;
  bool _addingToCart = false;
  bool _inWishlist = false;
  int _imageIdx = 0;
  PageController? _imgCtrl;

  @override
  void initState() {
    super.initState();
    _imgCtrl = PageController();
  }

  @override
  void dispose() { _imgCtrl?.dispose(); super.dispose(); }

  static const _specs = [
    ['Compatibility', 'OEM Verified'],
    ['Material', 'Premium Grade'],
    ['Warranty', '12 months'],
    ['Shipping', '1-3 business days'],
  ];

  Future<void> _addToCart() async {
    setState(() => _addingToCart = true);
    try {
      await MarketplaceService.addToCart(widget.product.id, quantity: _qty);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(children: [
            const Icon(Icons.shopping_cart_checkout_rounded,
                color: Colors.black, size: 18),
            const SizedBox(width: 8),
            Text('Added to cart', style: AppTypography.label.copyWith(
              fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black)),
          ]),
          backgroundColor: kCyan,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = product.images.isNotEmpty
        ? product.images : [product.primaryImage];

    return Scaffold(
      backgroundColor: kBg,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // ── Image gallery ─────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: kSurface,
                leading: TappableScale(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    margin: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: kTextPrimary),
                  ),
                ),
                actions: [
                  TappableScale(
                    onTap: () => setState(() => _inWishlist = !_inWishlist),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _inWishlist ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: _inWishlist ? kError : kTextPrimary, size: 22),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    children: [
                      Hero(
                        tag: 'product_image_${product.id}',
                        child: PageView.builder(
                          controller: _imgCtrl,
                          onPageChanged: (i) => setState(() => _imageIdx = i),
                          itemCount: images.length,
                          itemBuilder: (_, i) => images[i].isNotEmpty
                              ? Image.network(images[i], fit: BoxFit.cover,
                                  errorBuilder: (ctx, err, stack) => _ImgPlaceholder())
                              : _ImgPlaceholder(),
                        ),
                      ),
                      if (images.length > 1) Positioned(
                        bottom: 12, left: 0, right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(images.length, (i) =>
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              width: i == _imageIdx ? 20 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: i == _imageIdx ? kCyan : Colors.white38,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            )),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Product info ──────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    color: kBg,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price & Rating row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(children: [
                                  Text('Rs ${product.price.toStringAsFixed(0)}',
                                    style: GoogleFonts.inter(fontSize: 24,
                                      fontWeight: FontWeight.w800, color: kCyan,
                                      letterSpacing: -0.5)),
                                  if (product.hasDiscount) ...[
                                    const SizedBox(width: 8),
                                    Text('Rs ${product.comparePrice!.toStringAsFixed(0)}',
                                      style: kBody(14, color: kTextMuted).copyWith(
                                        decoration: TextDecoration.lineThrough)),
                                  ],
                                ]),
                                if (product.hasDiscount)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: kError.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${((1 - product.price / product.comparePrice!) * 100).round()}% OFF',
                                      style: kBody(11, color: kError,
                                          fw: FontWeight.w700)),
                                  ),
                              ],
                            ),
                          ),
                          // Stock badge
                          kStatusPill(
                            product.stockQuantity > 0
                                ? 'In Stock (${product.stockQuantity})'
                                : 'Out of Stock',
                            product.stockQuantity > 0 ? kSuccess : kError,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(product.name, style: kHeadline(20)),
                      const SizedBox(height: 6),
                      if (product.vendorShopName != null)
                        Row(children: [
                          const Icon(Icons.storefront_rounded, size: 14, color: kVendor),
                          const SizedBox(width: 6),
                          Text(product.vendorShopName!,
                            style: kBody(13, color: kVendor, fw: FontWeight.w600)),
                        ]),
                      const SizedBox(height: 16),

                      // ── Specs grid ────────────────────────────────────────
                      _SpecsGrid(specs: _specs),
                      const SizedBox(height: 20),

                      // ── Description ───────────────────────────────────────
                      kSectionHeader('Description'),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: kCardDeco(radius: 14),
                        child: Text(
                          product.description?.isNotEmpty == true
                              ? product.description!
                              : 'High-quality auto part from a verified vendor. '
                                'Designed for optimal performance and longevity.',
                          style: kBody(13, color: kTextSecondary).copyWith(height: 1.6)),
                      ),
                      const SizedBox(height: 20),

                      // ── Quantity selector ─────────────────────────────────
                      kSectionHeader('Quantity'),
                      const SizedBox(height: 12),
                      Row(children: [
                        Container(
                          decoration: kGlassDeco(radius: 14),
                          child: Row(children: [
                            _QtyBtn(Icons.remove_rounded, () {
                              if (_qty > 1) setState(() => _qty--);
                            }),
                            Container(
                              width: 48,
                              alignment: Alignment.center,
                              child: Text('$_qty', style: kHeadline(16)),
                            ),
                            _QtyBtn(Icons.add_rounded, () {
                              if (_qty < (product.stockQuantity > 0 
                                  ? product.stockQuantity : 99)) {
                                setState(() => _qty++);
                              }
                            }),
                          ]),
                        ),
                        const SizedBox(width: 12),
                        Text('Rs ${(product.price * _qty).toStringAsFixed(0)} total',
                          style: kBody(14, color: kTextMuted)),
                      ]),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Bottom add-to-cart bar ────────────────────────────────────────
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
              decoration: BoxDecoration(
                color: kSurface,
                border: Border(top: BorderSide(color: kBorder)),
                boxShadow: [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 20)],
              ),
              child: Row(children: [
                // Wishlist button
                TappableScale(
                  onTap: () => setState(() => _inWishlist = !_inWishlist),
                  child: Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: kCard, borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: kBorder),
                    ),
                    child: Icon(
                      _inWishlist ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: _inWishlist ? kError : kTextMuted),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TappableScale(
                    onTap: product.stockQuantity > 0 && !_addingToCart
                        ? _addToCart : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: product.stockQuantity > 0 ? kCyanGradient : null,
                        color: product.stockQuantity == 0 ? kCard : null,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: product.stockQuantity > 0
                            ? [BoxShadow(color: kCyan.withValues(alpha: 0.3),
                                blurRadius: 16, offset: const Offset(0, 6))]
                            : [],
                      ),
                      child: Center(
                        child: _addingToCart
                            ? const SizedBox(width: 20, height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.black))
                            : Text(
                                product.stockQuantity > 0
                                    ? 'Add to Cart' : 'Out of Stock',
                                style: GoogleFonts.inter(fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: product.stockQuantity > 0
                                      ? Colors.black : kTextMuted)),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImgPlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    color: kSurface,
    child: const Center(child: Icon(Icons.car_repair_rounded,
        color: kBorder, size: 64)),
  );
}

class _SpecsGrid extends StatelessWidget {
  final List<List<String>> specs;
  const _SpecsGrid({required this.specs});

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    childAspectRatio: 3.5, crossAxisSpacing: 8, mainAxisSpacing: 8,
    children: specs.map((s) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: kCardDeco(radius: 12),
      child: Row(children: [
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(s[0], style: kLabel(10, color: kTextMuted)),
            Text(s[1], style: kBody(12, color: kTextPrimary, fw: FontWeight.w600),
              overflow: TextOverflow.ellipsis),
          ],
        )),
      ]),
    )).toList(),
  );
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => TappableScale(
    onTap: onTap,
    child: SizedBox(
      width: 42, height: 42,
      child: Icon(icon, color: kTextSecondary, size: 20)),
  );
}
