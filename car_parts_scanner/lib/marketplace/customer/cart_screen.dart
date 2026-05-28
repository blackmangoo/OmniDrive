import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';

// ── Cart Screen (Stitch: My Cart) ─────────────────────────────────────────────
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _items = [];
  bool _loading = true;
  bool _checkingOut = false;
  String _paymentMethod = 'COD';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final items = await MarketplaceService.fetchCart();
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  double get _subtotal => _items.fold(0.0, (s, i) => s + i.totalPrice);
  double get _delivery => _subtotal > 2000 ? 0 : 199;
  double get _total => _subtotal + _delivery;

  Future<void> _checkout() async {
    if (_items.isEmpty) return;
    setState(() => _checkingOut = true);
    try {
      await MarketplaceService.placeOrderFromCart(
        paymentMethod: _paymentMethod,
        deliveryAddress: 'My saved address',
      );
      if (mounted) {
        setState(() => _items = []); // clear local list immediately
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Order placed successfully! 🎉',
            style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
          backgroundColor: kSuccess,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error placing order: $e'),
        backgroundColor: kError,
      ));
    } finally {
      if (mounted) setState(() => _checkingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(
      backgroundColor: kBg,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: kTextSecondary),
        onPressed: () => Navigator.pop(context)),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Selection', style: kLabel(11, color: kTextMuted)),
          Text('My Cart (${_items.length} items)', style: kHeadline(17)),
        ],
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: kCyan))
        : _items.isEmpty ? _emptyCart() : _buildCart(),
  );

  Widget _emptyCart() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 96, height: 96,
        decoration: BoxDecoration(
          color: kCard, shape: BoxShape.circle, border: Border.all(color: kBorder)),
        child: const Icon(Icons.shopping_cart_outlined, color: kBorder, size: 48),
      ),
      const SizedBox(height: 20),
      Text('Your cart is empty', style: kHeadline(18, color: kTextSecondary)),
      const SizedBox(height: 8),
      Text('Add some auto parts to get started', style: kBody(13)),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: kCyan,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text('Browse Market', style: GoogleFonts.inter(
          fontWeight: FontWeight.w700)),
      ),
    ]),
  );

  Widget _buildCart() => Stack(
    children: [
      RefreshIndicator(
        color: kCyan, backgroundColor: kCard,
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 200),
          children: [
            // ── Free delivery banner ─────────────────────────────────────
            if (_subtotal < 2000) Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: kSuccess.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kSuccess.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Icon(Icons.local_shipping_rounded, color: kSuccess, size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Add Rs ${(2000 - _subtotal).toStringAsFixed(0)} more for free delivery',
                  style: kBody(12, color: kSuccess, fw: FontWeight.w500))),
              ]),
            ),

            // ── Cart items ────────────────────────────────────────────────
            ..._items.map((item) => _CartItemCard(
              item: item,
              onRemove: () async {
                await MarketplaceService.removeFromCart(item.id);
                _load();
              },
              onQtyChange: (qty) async {
                await MarketplaceService.updateCartQuantity(item.id, qty);
                _load();
              },
            )),

            const SizedBox(height: 16),

            // ── Payment method ────────────────────────────────────────────
            kSectionHeader('Payment Method'),
            const SizedBox(height: 12),
            Row(children: [
              _PayChip('COD', 'Cash on Delivery', Icons.payments_rounded),
              const SizedBox(width: 8),
              _PayChip('Prepaid', 'JazzCash / Bank', Icons.credit_card_rounded),
            ]),

            const SizedBox(height: 20),

            // ── Order summary ─────────────────────────────────────────────
            kSectionHeader('Order Summary'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: kCardDeco(radius: 16),
              child: Column(children: [
                _SummaryRow('Subtotal', 'Rs ${_subtotal.toStringAsFixed(0)}'),
                const SizedBox(height: 8),
                _SummaryRow('Delivery',
                  _delivery == 0 ? 'FREE' : 'Rs ${_delivery.toStringAsFixed(0)}',
                  color: _delivery == 0 ? kSuccess : kTextSecondary),
                const SizedBox(height: 8),
                Divider(color: kBorder),
                const SizedBox(height: 8),
                _SummaryRow('Total', 'Rs ${_total.toStringAsFixed(0)}',
                  bold: true, color: kCyan),
              ]),
            ),
          ],
        ),
      ),

      // ── Sticky checkout bar ───────────────────────────────────────────────
      Positioned(
        bottom: 0, left: 0, right: 0,
        child: Container(
          padding: EdgeInsets.fromLTRB(
              16, 16, 16, MediaQuery.of(context).padding.bottom + 16),
          decoration: BoxDecoration(
            color: kSurface,
            border: Border(top: BorderSide(color: kBorder)),
          ),
          child: ElevatedButton(
            onPressed: _checkingOut ? null : _checkout,
            style: ElevatedButton.styleFrom(
              backgroundColor: kCyan,
              foregroundColor: Colors.black,
              minimumSize: const Size(double.infinity, 54),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            child: _checkingOut
                ? const SizedBox(width: 20, height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.black))
                : Text('Place Order · Rs ${_total.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(fontSize: 15,
                      fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    ],
  );

  Widget _PayChip(String id, String label, IconData icon) => Expanded(
    child: GestureDetector(
      onTap: () => setState(() => _paymentMethod = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: _paymentMethod == id ? kCyan.withValues(alpha: 0.12) : kCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _paymentMethod == id ? kCyan : kBorder,
            width: _paymentMethod == id ? 1.5 : 1,
          ),
        ),
        child: Row(children: [
          Icon(icon,
            color: _paymentMethod == id ? kCyan : kTextMuted, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: kBody(11,
            color: _paymentMethod == id ? kCyan : kTextSecondary,
            fw: FontWeight.w500), overflow: TextOverflow.ellipsis)),
        ]),
      ),
    ),
  );
}

class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQtyChange;
  const _CartItemCard({required this.item, required this.onRemove,
    required this.onQtyChange});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 12),
    padding: const EdgeInsets.all(12),
    decoration: kCardDeco(radius: 14),
    child: Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 70, height: 70,
            color: kSurface,
            child: item.product?.primaryImage.isNotEmpty == true
                ? Image.network(item.product!.primaryImage, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.car_repair_rounded, color: kBorder, size: 28))
                : const Icon(Icons.car_repair_rounded, color: kBorder, size: 28),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.product?.name ?? 'Product', style: GoogleFonts.inter(
                fontSize: 13, fontWeight: FontWeight.w600, color: kTextPrimary),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              if (item.product?.vendorShopName != null)
                Text(item.product!.vendorShopName!, style: kLabel(10)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('Rs ${item.totalPrice.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(fontSize: 14,
                      fontWeight: FontWeight.w800, color: kCyan)),
                  const Spacer(),
                  // Qty controls
                  Container(
                    decoration: kGlassDeco(radius: 10),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      GestureDetector(
                        onTap: () => item.quantity > 1
                            ? onQtyChange(item.quantity - 1)
                            : onRemove(),
                        child: Container(
                          width: 28, height: 28,
                          child: Icon(
                            item.quantity > 1 ? Icons.remove_rounded
                                : Icons.delete_outline_rounded,
                            size: 14,
                            color: item.quantity > 1 ? kTextMuted : kError)),
                      ),
                      Text('${item.quantity}', style: kBody(12,
                        color: kTextPrimary, fw: FontWeight.w700)),
                      GestureDetector(
                        onTap: () => onQtyChange(item.quantity + 1),
                        child: Container(
                          width: 28, height: 28,
                          child: const Icon(Icons.add_rounded,
                            size: 14, color: kTextMuted)),
                      ),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _SummaryRow extends StatelessWidget {
  final String label, value;
  final bool bold;
  final Color? color;
  const _SummaryRow(this.label, this.value,
    {this.bold = false, this.color});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Text(label, style: bold
          ? kHeadline(14) : kBody(13, color: kTextMuted)),
      const Spacer(),
      Text(value, style: bold
          ? GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800,
              color: color ?? kTextPrimary)
          : kBody(13, color: color ?? kTextSecondary, fw: FontWeight.w600)),
    ],
  );
}
