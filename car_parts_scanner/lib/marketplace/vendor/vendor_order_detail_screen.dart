import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';

class VendorOrderDetailScreen extends StatefulWidget {
  final Order order;
  final VoidCallback onStatusChanged;
  const VendorOrderDetailScreen({super.key, required this.order, required this.onStatusChanged});
  @override
  State<VendorOrderDetailScreen> createState() => _VendorOrderDetailScreenState();
}

class _VendorOrderDetailScreenState extends State<VendorOrderDetailScreen> {
  late Order _order;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  Future<void> _updateStatus(String newStatus) async {
    setState(() => _updating = true);
    await MarketplaceService.updateOrderStatus(_order.id, newStatus);
    setState(() { _order.status = newStatus; _updating = false; });
    widget.onStatusChanged();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Status → ${statusLabel(newStatus)}', style: GoogleFonts.inter()),
      backgroundColor: statusColor(newStatus), behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  @override
  Widget build(BuildContext context) {
    final color = statusColor(_order.status);
    final date  = DateFormat('EEEE, d MMM yyyy  •  hh:mm a').format(_order.createdAt.toLocal());

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Order Details', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Status ────────────────────────────────────────────────────
          Container(
            width: double.infinity, padding: const EdgeInsets.all(20),
            decoration: kGlowCard(color),
            child: Column(children: [
              Text(statusIcon(_order.status), style: const TextStyle(fontSize: 40)),
              const SizedBox(height: 8),
              Text(statusLabel(_order.status),
                  style: GoogleFonts.inter(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(date, style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
            ]),
          ),

          const SizedBox(height: 20),

          // ── Customer ───────────────────────────────────────────────────
          _sectionHeader('Customer'),
          _infoCard(children: [
            _row('Name', _order.customerName ?? '—'),
            _row('Phone', _order.customerPhone ?? '—'),
          ]),

          // ── Items ──────────────────────────────────────────────────────
          _sectionHeader('Order Items'),
          ..._order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: kCardDeco(),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.productName, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text('${item.quantity} × Rs ${item.unitPrice.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
                ])),
                Text('Rs ${item.total.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
              ]),
            ),
          )),

          const SizedBox(height: 4),

          // ── Summary ────────────────────────────────────────────────────
          _infoCard(children: [
            _row('Subtotal', 'Rs ${(_order.totalAmount - _order.deliveryFee).toStringAsFixed(0)}'),
            _row('Delivery', 'Rs ${_order.deliveryFee.toStringAsFixed(0)}'),
            _row('Total', 'Rs ${_order.totalAmount.toStringAsFixed(0)}', accent: true),
          ]),

          // ── Delivery Address ───────────────────────────────────────────
          _sectionHeader('Delivery Address'),
          Container(
            width: double.infinity, padding: const EdgeInsets.all(14),
            decoration: kCardDeco(), margin: const EdgeInsets.only(bottom: 20),
            child: Row(children: [
              const Icon(Icons.location_on_rounded, color: kAccent, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(_order.deliveryAddress, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13))),
            ]),
          ),

          if (_order.customerNotes != null) ...[
            _sectionHeader('Customer Notes'),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(14),
              decoration: kCardDeco(), margin: const EdgeInsets.only(bottom: 20),
              child: Text(_order.customerNotes!, style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, fontStyle: FontStyle.italic)),
            ),
          ],

          // ── Action Buttons ─────────────────────────────────────────────
          _sectionHeader('Update Status'),
          const SizedBox(height: 10),
          _statusActions(),

          const SizedBox(height: 40),
        ]),
      ),
    );
  }

  Widget _statusActions() {
    if (_updating) return const Center(child: CircularProgressIndicator(color: kVendor));

    final actionMap = {
      'pending':   [('✅ Confirm Order', 'confirmed', kVendor), ('❌ Cancel', 'cancelled', kError)],
      'confirmed': [('🔧 Start Preparing', 'preparing', kVendor)],
      'preparing': [('📦 Mark as Ready', 'ready', kSuccess)],
    };

    final actions = actionMap[_order.status];
    if (actions == null) return Text('No actions available for this status.',
        style: GoogleFonts.inter(color: Colors.white38, fontSize: 13));

    return Column(
      children: actions.map((a) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SizedBox(
          width: double.infinity, height: 48,
          child: ElevatedButton(
            onPressed: () => _updateStatus(a.$2),
            style: ElevatedButton.styleFrom(
              backgroundColor: a.$3, foregroundColor: a.$3 == kError ? Colors.white : Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
            ),
            child: Text(a.$1, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ),
      )).toList(),
    );
  }

  Widget _sectionHeader(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 3, height: 16, decoration: BoxDecoration(color: kVendor, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(t, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _infoCard({required List<Widget> children}) => Container(
    width: double.infinity, padding: const EdgeInsets.all(14),
    margin: const EdgeInsets.only(bottom: 16), decoration: kCardDeco(),
    child: Column(children: [
      for (int i = 0; i < children.length; i++) ...[
        children[i],
        if (i < children.length - 1) Divider(color: kBorder, height: 14),
      ],
    ]),
  );

  Widget _row(String label, String value, {bool accent = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
      Text(value, style: GoogleFonts.inter(color: accent ? kVendor : Colors.white, fontSize: 13, fontWeight: accent ? FontWeight.bold : FontWeight.w500)),
    ],
  );
}
