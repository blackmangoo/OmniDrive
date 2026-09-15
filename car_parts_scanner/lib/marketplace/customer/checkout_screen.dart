import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';
import 'orders_screen.dart';
import 'package:car_parts_scanner/core/theme/app_colors.dart';



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
  String _paymentMethod = 'COD'; // 'COD' | 'CARD'

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
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
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
        paymentMethod: _paymentMethod,
      );

      if (!mounted) return;
      if (order != null) {
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => OrdersScreen()),
            (route) => route.isFirst);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('🎉 Order placed successfully!'), backgroundColor: kSuccess, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Failed to place order: $e'), backgroundColor: kError, behavior: SnackBarBehavior.floating));
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
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Checkout', style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Order Items summary ─────────────────────────────────
                  _sectionHeader('Order Summary'),
                  SizedBox(height: 12),
                  ...widget.items.map((ci) => Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Expanded(child: Text('${ci.product?.name ?? 'Item'} × ${ci.quantity}',
                          style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13), overflow: TextOverflow.ellipsis)),
                      Text('Rs ${ci.subtotal.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  )),
                  Divider(color: kBorder, height: 24),

                  // ── Delivery Address ────────────────────────────────────
                  _sectionHeader('Delivery Address'),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _addrCtrl,
                    maxLines: 3,
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Full Address',
                      hintText: 'House #, Street, Area, City',
                      labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                      hintStyle: GoogleFonts.inter(color: (AppColors.textMuted.withValues(alpha: 0.5))),
                      filled: true,
                      fillColor: kCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kAccent, width: 1.5)),
                    ),
                  ),

                  SizedBox(height: 20),

                  // ── Notes ──────────────────────────────────────────────
                  _sectionHeader('Notes for Vendor (Optional)'),
                  SizedBox(height: 12),
                  TextFormField(
                    controller: _notesCtrl,
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      labelText: 'Any special instructions?',
                      labelStyle: GoogleFonts.inter(color: AppColors.textMuted),
                      hintStyle: GoogleFonts.inter(color: (AppColors.textMuted.withValues(alpha: 0.5))),
                      filled: true,
                      fillColor: kCard,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: kAccent, width: 1.5)),
                    ),
                  ),

                  SizedBox(height: 24),

                  // ── Payment Method ─────────────────────────────────────
                  _sectionHeader('Payment Method'),
                  SizedBox(height: 12),
                  _paymentMethodTile(
                    id: 'COD',
                    title: 'Cash on Delivery (COD)',
                    subtitle: 'Pay cash to rider upon delivery of parts',
                    icon: Icons.payments_outlined,
                  ),
                  SizedBox(height: 10),
                  _paymentMethodTile(
                    id: 'CARD',
                    title: 'Credit / Debit Card (Online)',
                    subtitle: 'Visa, Mastercard & UnionPay accepted',
                    icon: Icons.credit_card_rounded,
                  ),

                  SizedBox(height: 28),

                  // ── Price Breakdown ────────────────────────────────────
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: kCardDeco(),
                    child: Column(children: [
                      _priceRow('Subtotal', _subtotal),
                      SizedBox(height: 8),
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
            padding: EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: BoxDecoration(color: kSurface, border: Border(top: BorderSide(color: kBorder))),
            child: SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _placeOrder,
                icon: _loading
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                    : Icon(Icons.check_circle_rounded, size: 22),
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

  Widget _paymentMethodTile({
    required String id,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final isSelected = _paymentMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = id),
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? kAccent : kBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: (isSelected ? kAccent : AppColors.textMuted).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isSelected ? kAccent : AppColors.textMuted, size: 22),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                  SizedBox(height: 2),
                  Text(subtitle, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 11)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? kAccent : AppColors.textMuted,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String t) => Row(children: [
    Container(width: 3, height: 18, decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(2))),
    SizedBox(width: 10),
    Text(t, style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
  ]);

  Widget _priceRow(String label, double amount, {bool accent = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 14)),
      Text('Rs ${amount.toStringAsFixed(0)}',
          style: GoogleFonts.inter(color: accent ? kAccent : AppColors.textPrimary, fontSize: accent ? 16 : 14, fontWeight: accent ? FontWeight.bold : FontWeight.w500)),
    ],
  );
}
