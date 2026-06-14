import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';
import '../../core/motion/motion_stagger.dart';
import '../../core/motion/motion_tappable.dart';
import '../../core/motion/motion_counter.dart';

class RiderOrdersScreen extends StatefulWidget {
  const RiderOrdersScreen({super.key});
  @override
  State<RiderOrdersScreen> createState() => _RiderOrdersScreenState();
}

class _RiderOrdersScreenState extends State<RiderOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  List<Order> _myDeliveries = [];
  List<Order> _availableOrders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final results = await Future.wait([
      MarketplaceService.fetchRiderOrders(),
      MarketplaceService.fetchAvailableOrders(),
    ]);
    if (mounted) {
      setState(() {
        _myDeliveries = results[0];
        _availableOrders = results[1];
        _loading = false;
      });
    }
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

  Future<void> _claimOrder(Order order) async {
    await MarketplaceService.claimOrder(order.id);
    _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('🎉 Delivery accepted!', style: GoogleFonts.inter()),
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
        title: Text('Rider Dashboard', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        actions: [
          TappableScale(
            onTap: _load,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.refresh_rounded, color: kRider),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: kRider,
          labelColor: kRider,
          unselectedLabelColor: Colors.white38,
          dividerColor: Colors.transparent,
          tabs: [
            Tab(text: _myDeliveries.isNotEmpty ? 'My Deliveries (${_myDeliveries.length})' : 'My Deliveries'),
            Tab(text: _availableOrders.isNotEmpty ? 'Available (${_availableOrders.length})' : 'Available'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kRider))
          : TabBarView(
              controller: _tab,
              children: [
                _buildList(_myDeliveries, isClaimed: true),
                _buildList(_availableOrders, isClaimed: false),
              ],
            ),
    );
  }

  Widget _buildList(List<Order> list, {required bool isClaimed}) {
    if (list.isEmpty) {
      return _empty(isClaimed: isClaimed);
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: kRider, backgroundColor: kSurface,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        separatorBuilder: (context, i) => const SizedBox(height: 12),
        itemBuilder: (context, i) => StaggeredEntrance(
          index: i,
          child: _RiderOrderCard(
            order: list[i],
            onMarkDelivered: isClaimed && list[i].status == 'dispatched'
                ? () => _markDelivered(list[i])
                : null,
            onAcceptDelivery: !isClaimed
                ? () => _claimOrder(list[i])
                : null,
          ),
        ),
      ),
    );
  }

  Widget _empty({required bool isClaimed}) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kSurface,
            border: Border.all(color: kBorder),
          ),
          child: Icon(
            isClaimed ? Icons.local_shipping_rounded : Icons.explore_rounded,
            color: kRider,
            size: 64,
          ),
        )
        .animate()
        .scaleXY(begin: 0.8, end: 1.0, duration: 600.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 500.ms),
        const SizedBox(height: 16),
        Text(
          isClaimed ? 'No deliveries assigned yet' : 'No available deliveries',
          style: GoogleFonts.inter(color: Colors.white38, fontSize: 16),
        ),
        const SizedBox(height: 8),
        Text(
          isClaimed ? 'Check the available tab to claim' : 'Check back later',
          style: GoogleFonts.inter(color: Colors.white24, fontSize: 13),
        ),
      ],
    ),
  );
}

// ── Rider Order Card ──────────────────────────────────────────────────────────
class _RiderOrderCard extends StatefulWidget {
  final Order order;
  final VoidCallback? onMarkDelivered;
  final VoidCallback? onAcceptDelivery;
  const _RiderOrderCard({
    required this.order,
    this.onMarkDelivered,
    this.onAcceptDelivery,
  });
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
          TappableScale(
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
                      MotionCounter(
                        value: item.total,
                        prefix: 'Rs ',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ]),
                  )),
                  const SizedBox(height: 4),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Total', style: GoogleFonts.inter(color: Colors.white38, fontSize: 13)),
                    MotionCounter(
                      value: o.totalAmount,
                      prefix: 'Rs ',
                      style: GoogleFonts.inter(color: kRider, fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ]),
                ]),

                // ── Mark Delivered Button ───────────────────────────────
                if (widget.onMarkDelivered != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: TappableScale(
                      onTap: widget.onMarkDelivered,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: kSuccess,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 20, color: Colors.white),
                            const SizedBox(width: 8),
                            Text('Mark as Delivered', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // ── Accept Delivery Button ───────────────────────────────
                if (widget.onAcceptDelivery != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity, height: 48,
                    child: TappableScale(
                      onTap: widget.onAcceptDelivery,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: kRider,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 20, color: Colors.black),
                            const SizedBox(width: 8),
                            Text('Accept Delivery', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.black)),
                          ],
                        ),
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
