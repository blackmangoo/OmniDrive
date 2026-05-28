import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';
import 'add_edit_product_screen.dart';

// ── Vendor Catalogue Screen (Stitch: Product Catalogue) ─────────────────────
class VendorCatalogueScreen extends StatefulWidget {
  const VendorCatalogueScreen({super.key});
  @override
  State<VendorCatalogueScreen> createState() => _VendorCatalogueScreenState();
}

class _VendorCatalogueScreenState extends State<VendorCatalogueScreen> {
  List<Product> _products = [];
  bool _loading = true;
  String? _search;
  final _searchCtrl = TextEditingController();

  @override
  void initState() { super.initState(); _load(); }

  @override
  void dispose() { _searchCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prods = await MarketplaceService.fetchVendorProducts(search: _search);
    if (mounted) setState(() { _products = prods; _loading = false; });
  }

  Future<void> _deleteProduct(Product p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Delete Product?', style: kHeadline(16)),
        content: Text('Are you sure you want to delete "${p.name}"?',
          style: kBody(13)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: kBody(13, color: kTextMuted))),
          TextButton(onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: kBody(13, color: kError,
              fw: FontWeight.w700))),
        ],
      ),
    );
    if (confirm == true) {
      await MarketplaceService.deleteProduct(p.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    floatingActionButton: FloatingActionButton.extended(
      backgroundColor: kVendor,
      foregroundColor: Colors.black,
      onPressed: () => Navigator.push(context,
        MaterialPageRoute(builder: (_) => const AddEditProductScreen()))
        .then((_) => _load()),
      icon: const Icon(Icons.add_rounded),
      label: Text('Add Product', style: GoogleFonts.inter(
        fontWeight: FontWeight.w700)),
    ),
    body: Column(
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 16, 20, 16),
          decoration: BoxDecoration(
            color: kBg,
            border: Border(bottom: BorderSide(color: kBorder)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('Inventory Management', style: kLabel(11, color: kTextMuted)),
                const Spacer(),
                kStatusPill('${_products.length} products', kVendor),
              ]),
              const SizedBox(height: 4),
              Text('Catalogue', style: kHeadline(22)),
              const SizedBox(height: 14),
              Container(
                height: 44,
                decoration: kGlassDeco(radius: 12),
                child: TextField(
                  controller: _searchCtrl,
                  style: kBody(13, color: kTextPrimary),
                  onSubmitted: (v) {
                    setState(() => _search = v.isEmpty ? null : v);
                    _load();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search products…',
                    hintStyle: kBody(12, color: kTextMuted),
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: kTextMuted, size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    suffixIcon: _search != null ? IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: kTextMuted, size: 16),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _search = null);
                        _load();
                      }) : null,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Product list ──────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kVendor))
              : _products.isEmpty
                  ? _empty()
                  : RefreshIndicator(
                      color: kVendor, backgroundColor: kCard,
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                        itemCount: _products.length,
                        itemBuilder: (_, i) => _ProductRow(
                          product: _products[i],
                          onEdit: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) =>
                              AddEditProductScreen(product: _products[i])))
                            .then((_) => _load()),
                          onDelete: () => _deleteProduct(_products[i]),
                          onStockUpdate: _load,
                        ),
                      ),
                    ),
        ),
      ],
    ),
  );

  Widget _empty() => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.inventory_2_outlined, size: 64, color: kBorder),
      const SizedBox(height: 16),
      Text('No products yet', style: kHeadline(16, color: kTextSecondary)),
      const SizedBox(height: 8),
      Text('Tap + Add Product to get started', style: kBody(13)),
    ],
  ));
}

class _ProductRow extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit, onDelete, onStockUpdate;
  const _ProductRow({required this.product, required this.onEdit,
    required this.onDelete, required this.onStockUpdate});

  @override
  Widget build(BuildContext context) {
    final stockColor = product.stockQuantity == 0 ? kError
        : product.stockQuantity <= 5 ? kWarning : kSuccess;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: kCardDeco(radius: 16),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Product image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 72, height: 72, color: kSurface,
                    child: product.primaryImage.isNotEmpty
                        ? CachedNetworkImage(imageUrl: product.primaryImage, fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => const Icon(
                              Icons.car_repair_rounded, color: kBorder, size: 28))
                        : const Icon(Icons.car_repair_rounded,
                            color: kBorder, size: 28),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name, style: GoogleFonts.inter(fontSize: 13,
                        fontWeight: FontWeight.w700, color: kTextPrimary),
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(product.categoryName ?? 'Uncategorised',
                        style: kLabel(10)),
                      const SizedBox(height: 6),
                      Row(children: [
                        Text('Rs ${product.price.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(fontSize: 14,
                            fontWeight: FontWeight.w800, color: kVendor)),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: stockColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('${product.stockQuantity} in stock',
                            style: kBody(10, color: stockColor,
                              fw: FontWeight.w600)),
                        ),
                      ]),
                    ],
                  ),
                ),

                Column(children: [
                  IconButton(
                    icon: const Icon(Icons.edit_rounded,
                        color: kCyan, size: 20),
                    onPressed: onEdit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: kError, size: 20),
                    onPressed: onDelete,
                  ),
                ]),
              ],
            ),
          ),

          // Quick stock update
          GestureDetector(
            onTap: () => _showStockSheet(context),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: kSurface,
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.inventory_2_rounded,
                      color: kTextMuted, size: 14),
                  const SizedBox(width: 6),
                  Text('Update Stock', style: kBody(12, color: kTextMuted,
                    fw: FontWeight.w500)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStockSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: kSurface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _StockUpdateSheet(
          product: product, onUpdated: onStockUpdate),
    );
  }
}

class _StockUpdateSheet extends StatefulWidget {
  final Product product;
  final VoidCallback onUpdated;
  const _StockUpdateSheet({required this.product, required this.onUpdated});
  @override
  State<_StockUpdateSheet> createState() => _StockUpdateSheetState();
}

class _StockUpdateSheetState extends State<_StockUpdateSheet> {
  late int _qty;
  bool _saving = false;

  @override
  void initState() { super.initState(); _qty = widget.product.stockQuantity; }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
        20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(width: 36, height: 4,
            decoration: BoxDecoration(
              color: kBorder, borderRadius: BorderRadius.circular(2))),
        ),
        const SizedBox(height: 16),
        Text('Update Stock', style: kHeadline(18)),
        const SizedBox(height: 4),
        Text(widget.product.name, style: kBody(13, color: kTextMuted),
          maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _QtyBtn(Icons.remove_rounded, () {
              if (_qty > 0) setState(() => _qty--);
            }),
            const SizedBox(width: 24),
            Text('$_qty', style: GoogleFonts.inter(fontSize: 42,
              fontWeight: FontWeight.w800, color: kTextPrimary)),
            const SizedBox(width: 24),
            _QtyBtn(Icons.add_rounded, () => setState(() => _qty++)),
          ],
        ),
        const SizedBox(height: 8),
        Center(child: Text('units in stock', style: kBody(12, color: kTextMuted))),
        const SizedBox(height: 20),
        // Quick presets
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (final preset in [10, 25, 50, 100])
            GestureDetector(
              onTap: () => setState(() => _qty = preset),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _qty == preset ? kVendor.withValues(alpha: 0.2) : kCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _qty == preset ? kVendor : kBorder),
                ),
                child: Text('+$preset', style: kBody(12,
                  color: _qty == preset ? kVendor : kTextSecondary,
                  fw: FontWeight.w600)),
              ),
            ),
        ]),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _saving ? null : () async {
            setState(() => _saving = true);
            await MarketplaceService.updateProductStock(widget.product.id, _qty);
            setState(() => _saving = false);
            widget.onUpdated();
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: kVendor, foregroundColor: Colors.black,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _saving
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
              : Text('Save Stock', style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700, fontSize: 15)),
        ),
      ],
    ),
  );
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyBtn(this.icon, this.onTap);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 44, height: 44,
      decoration: BoxDecoration(
        color: kCard, shape: BoxShape.circle,
        border: Border.all(color: kBorder)),
      child: Icon(icon, color: kTextSecondary, size: 20)),
  );
}

extension on IconButton {
  // This is intentionally unused - using GestureDetector patterns instead
  @deprecated
  Widget withColor(Color c) => this;
}
