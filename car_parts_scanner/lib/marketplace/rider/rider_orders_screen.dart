import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';

class RiderOrdersScreen extends StatefulWidget {
  const RiderOrdersScreen({super.key});
  @override
  State<RiderOrdersScreen> createState() => _RiderOrdersScreenState();
}

class _RiderOrdersScreenState extends State<RiderOrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await MarketplaceService.fetchRiderOrders();
    if (mounted) setState(() { _orders = orders; _loading = false; });
  }

  Future<void> _markDelivered(Order order) async {
    await MarketplaceService.updateOrderStatus(order.id, 'delivered');
    _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🎉 Order marked as delivered!', style: GoogleFonts.inter()),
      backgroundColor: kSuccess, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        automaticallyImplyLeading: false,
        title: Text('My Deliveries', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: kRider), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kRider))
          : _orders.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: kRider, backgroundColor: kSurface,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _RiderOrderCard(
                      order: _orders[i],
                      onMarkDelivered: _orders[i].status == 'dispatched'
                          ? () => _markDelivered(_orders[i])
                          : null,
                    ),
                  ),
                ),
    );
  }

  Widget _empty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.delivery_dining_outlined, size: 80, color: Colors.white12),
      const SizedBox(height: 16),
      Text('No deliveries assigned yet', style: GoogleFonts.inter(color: Colors.white38, fontSize: 16)),
      const SizedBox(height: 8),
      Text('Check back later', style: GoogleFonts.inter(color: Colors.white24, fontSize: 13)),
    ]),
  );
}

// ── Rider Order Card ──────────────────────────────────────────────────────────
class _RiderOrderCard extends StatefulWidget {
  final Order order;
  final VoidCallback? onMarkDelivered;
  const _RiderOrderCard({required this.order, this.onMarkDelivered});
  @override
  State<_RiderOrderCard> createState() => _RiderOrderCardState();
}

class _RiderOrderCardState extends State<_RiderOrderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final o = widget.order;
    final color = statusColor(o.status);
    final date  = DateFormat('d MMM, hh:mm a').format(o.createdAt.toLocal());

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: kGlowCard(color),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(statusIcon(o.status), style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Order #${o.id.substring(0, 8).toUpperCase()}',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                      Text(statusLabel(o.status),
                          style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                  Icon(_expanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                      color: Colors.white38),
                ]),
                const SizedBox(height: 10),
                // Delivery address prominent
                Row(children: [
                  const Icon(Icons.location_on_rounded, color: kRider, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(o.deliveryAddress,
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(color: Colors.white70, fontSize: 13)),
                  ),
                ]),
                const SizedBox(height: 6),
                Text(date, style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
              ]),
            ),
          ),

          // ── Expanded Details ─────────────────────────────────────────────
          if (_expanded) ...[
            Divider(color: kBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Vendor info ─────────────────────────────────────────
                _detailSection('📦 Vendor / Pickup', [
                  _detailRow('Shop', o.vendorShopName ?? '—'),
                  _detailRow('Location', o.vendorLocation ?? '—'),
                  if (o.vendorPhone != null) _detailRow('Phone', o.vendorPhone!),
                ]),

                const SizedBox(height: 14),

                // ── Customer info ───────────────────────────────────────
                _detailSection('👤 Customer / Deliver To', [
                  _detailRow('Name', o.customerName ?? '—'),
                  if (o.customerPhone != null) _detailRow('Phone', o.customerPhone!),
                  _detailRow('Address', o.deliveryAddress),
                ]),

                const SizedBox(height: 14),

                // ── Order items ─────────────────────────────────────────
                _detailSection('🛒 Items (${o.items.length})', [
                  ...o.items.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(children: [
                      Expanded(child: Text('${item.productName} × ${item.quantity}',
                          style: GoogleFonts.inter(color: Colors.white60, fontSize: 12))),
                      Text('Rs ${item.total.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  )),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Total', style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
                    Text('Rs ${o.totalAmount.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(color: kRider, fontSize: 14, fontWeight: FontWeight.bold)),
                  ]),
                ]),

                // ── Mark Delivered Button ───────────────────────────────
                if (widget.onMarkDelivered != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: ElevatedButton.icon(
                      onPressed: widget.onMarkDelivered,
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: Text('Mark as Delivered', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kSuccess, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
                      ),
                    ),
                  ),
                ],
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailSection(String title, List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: kCardDeco(radius: 12),
        child: Column(children: children),
      ),
    ],
  );

  Widget _detailRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(children: [
      SizedBox(width: 70, child: Text(label, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12))),
      Expanded(child: Text(value, style: GoogleFonts.inter(color: Colors.white70, fontSize: 12))),
    ]),
  );
}
