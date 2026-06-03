import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';
import 'product_detail_screen.dart';

class CategoryProductsScreen extends StatefulWidget {
  final Category category;
  const CategoryProductsScreen({super.key, required this.category});
  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  List<Product> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final products = await MarketplaceService.fetchProducts(categoryId: widget.category.id);
    if (mounted) setState(() { _products = products; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.category.name,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? _shimmer()
          : _products.isEmpty
              ? Center(child: Text('No products in this category yet.',
                    style: GoogleFonts.inter(color: Colors.white38)))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: kAccent,
                  backgroundColor: kSurface,
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _products.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 0.72,
                    ),
                    itemBuilder: (_, i) {
                      final p = _products[i];
                      return GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => ProductDetailScreen(product: p))),
                        child: Container(
                          decoration: kCardDeco(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                  child: p.primaryImage.isNotEmpty
                                      ? CachedNetworkImage(imageUrl: p.primaryImage, fit: BoxFit.cover, width: double.infinity,
                                          errorWidget: (ctx, url, err) => _imgPlaceholder())
                                      : _imgPlaceholder(),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10),
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  Text('Rs ${p.price.toStringAsFixed(0)}',
                                      style: GoogleFonts.inter(color: kAccent, fontSize: 14, fontWeight: FontWeight.bold)),
                                ]),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _imgPlaceholder() => Container(color: kCard, child: const Icon(Icons.car_repair, color: Colors.white24, size: 40));

  Widget _shimmer() => Shimmer.fromColors(
    baseColor: kSurface, highlightColor: kCard,
    child: GridView.builder(
      padding: const EdgeInsets.all(16), itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemBuilder: (_, index) => Container(decoration: BoxDecoration(color: kSurface, borderRadius: BorderRadius.circular(16))),
    ),
  );
}
