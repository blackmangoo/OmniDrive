import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';
import 'orders_screen.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;
  final double deliveryFee;
  const CheckoutScreen({super.key, required this.items, required this.deliveryFee});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _addrCtrl  = TextEditingController();
  final _notesCtrl = TextEditingController();
  bool _loading = false;

  double get _subtotal => widget.items.fold(0, (s, i) => s + i.subtotal);
  double get _total => _subtotal + widget.deliveryFee;

  @override
  void dispose() {
    _addrCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_addrCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a delivery address'), backgroundColor: kError, behavior: SnackBarBehavior.floating));
      return;
    }

    // Group items by vendor. For simplicity, we assume one vendor per cart checkout.
    final vendorId = widget.items.first.product?.vendorId;
    if (vendorId == null) return;

    setState(() => _loading = true);
    try {
      final order = await MarketplaceService.placeOrder(
        vendorId: vendorId,
        items: widget.items,
        deliveryAddress: _addrCtrl.text.trim(),
        deliveryFee: widget.deliveryFee,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      if (!mounted) return;
      if (order != null) {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => const OrdersScreen()),
            (route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('🎉 Order placed successfully!'), backgroundColor: kSuccess, behavior: SnackBarBehavior.floating));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to place order. Try again.'), backgroundColor: kError, behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
        title: Text('Checkout', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Order Items summary ─────────────────────────────────
                  _sectionHeader('Order Summary'),
                  const SizedBox(height: 12),
                  ...widget.items.map((ci) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Expanded(child: Text('${ci.product?.name ?? 'Item'} × ${ci.quantity}',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 13), overflow: TextOverflow.ellipsis)),
                      Text('Rs ${ci.subtotal.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  )),
                  Divider(color: kBorder, height: 24),

                  // ── Delivery Address ────────────────────────────────────
                  _sectionHeader('Delivery Address'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addrCtrl,
                    maxLines: 3,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Full Address',
                      hintText: 'House #, Street, Area, City',
                      labelStyle: GoogleFonts.inter(color: Colors.white38),
                      hintStyle: GoogleFonts.inter(color: Colors.white24),
                      filled: true,
                      fillColor: kCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kAccent, width: 1.5)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ── Notes ──────────────────────────────────────────────
                  _sectionHeader('Notes for Vendor (Optional)'),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _notesCtrl,
                    style: GoogleFonts.inter(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Any special instructions?',
                      labelStyle: GoogleFonts.inter(color: Colors.white38),
                      hintStyle: GoogleFonts.inter(color: Colors.white24),
                      filled: true,
                      fillColor: kCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kAccent, width: 1.5)),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Price Breakdown ────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: kCardDeco(),
                    child: Column(children: [
                      _priceRow('Subtotal', _subtotal),
                      const SizedBox(height: 8),
                      _priceRow('Delivery', widget.deliveryFee),
                      Divider(color: kBorder, height: 20),
                      _priceRow('Total', _total, accent: true),
                    ]),
                  ),
                ],
              ),
            ),
          ),

          // ── Place Order CTA ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: BoxDecoration(color: kSurface, border: Border(top: BorderSide(color: kBorder))),
            child: SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _placeOrder,
                icon: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : const Icon(Icons.check_circle_rounded, size: 22),
                label: Text('Place Order  •  Rs ${_total.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kAccent, foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String t) => Row(children: [
    Container(width: 3, height: 18, decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 10),
    Text(t, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
  ]);

  Widget _priceRow(String label, double amount, {bool accent = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.inter(color: Colors.white54, fontSize: 14)),
      Text('Rs ${amount.toStringAsFixed(0)}',
          style: GoogleFonts.inter(color: accent ? kAccent : Colors.white, fontSize: accent ? 16 : 14, fontWeight: accent ? FontWeight.bold : FontWeight.w500)),
    ],
  );
}
