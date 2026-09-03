import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';
import 'checkout_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/motion/motion_stagger.dart';
import '../../core/motion/motion_tappable.dart';
import '../../core/motion/motion_counter.dart';

// ── Cart Screen (Stitch: My Cart) ─────────────────────────────────────────────
class CartScreen extends StatefulWidget {
  const CartScreen({super.key});
  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<CartItem> _items = [];
  bool _loading = true;
  final bool _checkingOut = false;
  String _paymentMethod = 'COD';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final items = await MarketplaceService.fetchCart();
    if (mounted) setState(() { _items = items; _loading = false; });
  }

  double get _subtotal => _items.fold(0.0, (s, i) => s + i.totalPrice);
  double get _delivery => _subtotal > 2000 ? 0 : 199;
  double get _total => _subtotal + _delivery;

  Future<void> _checkout() async {
    if (_items.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(
          items: _items,
          deliveryFee: _delivery,
        ),
      ),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(
      backgroundColor: kBg,
      surfaceTintColor: Colors.transparent,
      leading: TappableScale(
        onTap: () => Navigator.pop(context),
        child: const Icon(Icons.arrow_back_rounded, color: kTextSecondary),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Your Selection', style: kLabel(11, color: kTextMuted)),
          Text('My Cart (${_items.length} items)', style: kHeadline(17)),
        ],
      ),
    ),
    body: _loading
        ? Shimmer.fromColors(
            baseColor: AppColors.surface,
            highlightColor: AppColors.card,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 3,
              itemBuilder: (_, index) => Container(
                height: 94,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          )
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
      TappableScale(
        onTap: () => Navigator.pop(context),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          decoration: BoxDecoration(
            color: kCyan,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text('Browse Market', style: AppTypography.label.copyWith(
            fontWeight: FontWeight.w700, color: Colors.black)),
        ),
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
            ..._items.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              return StaggeredEntrance(
                index: idx,
                child: _CartItemCard(
                  item: item,
                  onRemove: () async {
                    await MarketplaceService.removeFromCart(item.id);
                    _load();
                  },
                  onQtyChange: (qty) async {
                    await MarketplaceService.updateCartQuantity(item.id, qty);
                    _load();
                  },
                ),
              );
            }),

            const SizedBox(height: 16),

            // ── Payment method ────────────────────────────────────────────
            kSectionHeader('Payment Method'),
            const SizedBox(height: 12),
            Row(children: [
              _payChip('COD', 'Cash on Delivery', Icons.payments_rounded),
              const SizedBox(width: 8),
              _payChip('Prepaid', 'JazzCash / Bank', Icons.credit_card_rounded),
            ]),

            const SizedBox(height: 20),

            // ── Order summary ─────────────────────────────────────────────
            kSectionHeader('Order Summary'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: kCardDeco(radius: 16),
              child: Column(children: [
                _SummaryRow('Subtotal', '', numericValue: _subtotal, prefix: 'Rs '),
                const SizedBox(height: 8),
                _SummaryRow(
                  'Delivery',
                  _delivery == 0 ? 'FREE' : '',
                  numericValue: _delivery == 0 ? null : _delivery,
                  prefix: _delivery == 0 ? '' : 'Rs ',
                  color: _delivery == 0 ? kSuccess : kTextSecondary,
                ),
                const SizedBox(height: 8),
                Divider(color: kBorder),
                const SizedBox(height: 8),
                _SummaryRow('Total', '', numericValue: _total, prefix: 'Rs ', bold: true, color: kCyan),
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
          child: TappableScale(
            onTap: _checkingOut ? null : _checkout,
            child: Container(
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: kCyan,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: kCyan.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: _checkingOut
                  ? const SizedBox(width: 20, height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.black))
                  : Text('Place Order · Rs ${_total.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(fontSize: 15,
                        fontWeight: FontWeight.w700, color: Colors.black)),
            ),
          ),
        ),
      ),
    ],
  );

  Widget _payChip(String id, String label, IconData icon) => Expanded(
    child: TappableScale(
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
                    errorBuilder: (ctx, err, stack) => const Icon(
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
                  MotionCounter(
                    value: item.totalPrice,
                    prefix: 'Rs ',
                    style: GoogleFonts.inter(fontSize: 14,
                      fontWeight: FontWeight.w800, color: kCyan),
                  ),
                  const Spacer(),
                  // Qty controls
                  Container(
                    decoration: kGlassDeco(radius: 10),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      TappableScale(
                        onTap: () => item.quantity > 1
                            ? onQtyChange(item.quantity - 1)
                            : onRemove(),
                        child: SizedBox(
                          width: 28, height: 28,
                          child: Icon(
                            item.quantity > 1 ? Icons.remove_rounded
                                : Icons.delete_outline_rounded,
                            size: 14,
                            color: item.quantity > 1 ? kTextMuted : kError)),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: Text('${item.quantity}', style: kBody(12,
                          color: kTextPrimary, fw: FontWeight.w700)),
                      ),
                      TappableScale(
                        onTap: () => onQtyChange(item.quantity + 1),
                        child: const SizedBox(
                          width: 28, height: 28,
                          child: Icon(Icons.add_rounded,
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
  final String label;
  final String value;
  final num? numericValue;
  final String prefix;
  final bool bold;
  final Color? color;
  const _SummaryRow(this.label, this.value,
    {this.numericValue, this.prefix = '', this.bold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final style = bold
        ? GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800,
            color: color ?? kTextPrimary)
        : kBody(13, color: color ?? kTextSecondary, fw: FontWeight.w600);
    return Row(
      children: [
        Text(label, style: bold
            ? kHeadline(14) : kBody(13, color: kTextMuted)),
        const Spacer(),
        if (numericValue != null)
          MotionCounter(
            value: numericValue!,
            prefix: prefix,
            style: style,
          )
        else
          Text(value, style: style),
      ],
    );
  }
}
