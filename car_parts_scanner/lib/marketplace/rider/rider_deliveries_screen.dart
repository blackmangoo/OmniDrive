import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';

// ── Rider Deliveries Screen (Stitch Design) ───────────────────────────────────
class RiderDeliveriesScreen extends StatefulWidget {
  const RiderDeliveriesScreen({super.key});
  @override
  State<RiderDeliveriesScreen> createState() => _RiderDeliveriesScreenState();
}

class _RiderDeliveriesScreenState extends State<RiderDeliveriesScreen> {
  List<Order> _orders = [];
  bool _loading = true;
  double _earnings = 0;
  double _km = 0;
  int _expandedIndex = 0;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await MarketplaceService.fetchRiderOrders();
    double km = 0;
    double earnings = 0;
    for (final o in orders) {
      if (o.status == 'delivered') {
        km += 5.4;
        earnings += o.deliveryFee ?? 150.0;
      }
    }
    if (mounted) setState(() {
      _orders = orders;
      _earnings = earnings;
      _km = km;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: kRider))
        : RefreshIndicator(
            color: kRider, backgroundColor: kCard,
            onRefresh: _load,
            child: CustomScrollView(
              slivers: [
                // ── Header ────────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.fromLTRB(
                        20, MediaQuery.of(context).padding.top + 16, 20, 20),
                    decoration: BoxDecoration(
                      color: kSurface,
                      border: Border(bottom: BorderSide(color: kBorder))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            width: 40, height: 40,
                            decoration: BoxDecoration(
                              gradient: kRiderGradient,
                              borderRadius: BorderRadius.circular(12)),
                            child: const Icon(Icons.delivery_dining_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('OmniDrive AI', style: kLabel(11,
                                  color: kTextMuted)),
                                Text('My Deliveries', style: kHeadline(20)),
                              ],
                            ),
                          ),
                          kStatusPill(
                            '${_orders.length} in queue', kRider),
                        ]),
                        const SizedBox(height: 16),

                        // ── Stats row ─────────────────────────────────────
                        Row(children: [
                          Expanded(child: _RiderStat(
                            icon: Icons.currency_rupee_rounded,
                            label: "Today's Earnings",
                            value: 'Rs ${_earnings.toStringAsFixed(0)}',
                            accent: kVendor,
                          )),
                          const SizedBox(width: 12),
                          Expanded(child: _RiderStat(
                            icon: Icons.route_rounded,
                            label: 'Trip Meter',
                            value: '${_km.toStringAsFixed(1)} km',
                            accent: kRider,
                          )),
                        ]),
                      ],
                    ),
                  ),
                ),

                // ── Order cards ───────────────────────────────────────────
                _orders.isEmpty
                    ? SliverFillRemaining(
                        child: Center(child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.delivery_dining_rounded,
                                size: 64, color: kBorder),
                            const SizedBox(height: 16),
                            Text('No deliveries assigned',
                              style: kHeadline(16, color: kTextSecondary)),
                            const SizedBox(height: 8),
                            Text('New deliveries will appear here',
                              style: kBody(13)),
                          ],
                        )))
                    : SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (_, i) => _DeliveryCard(
                              order: _orders[i],
                              index: i,
                              isExpanded: _expandedIndex == i,
                              onToggle: () => setState(() =>
                                _expandedIndex = _expandedIndex == i ? -1 : i),
                              onAction: _load,
                            ),
                            childCount: _orders.length,
                          ),
                        ),
                      ),
              ],
            ),
          ),
  );
}

class _RiderStat extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color accent;
  const _RiderStat({required this.icon, required this.label,
    required this.value, required this.accent});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: kGlowDeco(accent, radius: 14),
    child: Row(children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: accent, size: 18),
      ),
      const SizedBox(width: 10),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: kLabel(9, color: kTextMuted)),
        Text(value, style: GoogleFonts.inter(
          fontSize: 14, fontWeight: FontWeight.w800, color: kTextPrimary)),
      ]),
    ]),
  );
}

class _DeliveryCard extends StatefulWidget {
  final Order order;
  final int index;
  final bool isExpanded;
  final VoidCallback onToggle, onAction;
  const _DeliveryCard({required this.order, required this.index,
    required this.isExpanded, required this.onToggle, required this.onAction});
  @override
  State<_DeliveryCard> createState() => _DeliveryCardState();
}

class _DeliveryCardState extends State<_DeliveryCard> {
  bool _delivering = false;

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final isFirst = widget.index == 0;
    final accent = isFirst ? kRider : kTextMuted;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: kGlowDeco(accent, radius: 18),
      child: Column(children: [
        // ── Card header ─────────────────────────────────────────────────
        GestureDetector(
          onTap: widget.onToggle,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: isFirst ? kRiderGradient : null,
                  color: isFirst ? null : kCard,
                  borderRadius: BorderRadius.circular(14),
                  border: isFirst ? null : Border.all(color: kBorder),
                ),
                child: Center(child: Text('#${widget.index + 1}',
                  style: GoogleFonts.inter(fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isFirst ? Colors.white : kTextMuted))),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('OD-AI-${order.id.substring(0, 8).toUpperCase()}',
                      style: kBody(13, color: kTextPrimary,
                        fw: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(order.deliveryAddress, style: kLabel(10),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                kStatusPill(statusLabel(order.status), accent, fontSize: 10),
                const SizedBox(height: 4),
                Text('Rs ${order.totalAmount.toStringAsFixed(0)}',
                  style: kBody(12, color: kVendor, fw: FontWeight.w600)),
              ]),
            ]),
          ),
        ),

        // ── Expanded details ─────────────────────────────────────────────
        if (widget.isExpanded) ...[
          Divider(color: kBorder, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Vendor pickup
                _LocationRow(
                  icon: Icons.storefront_rounded,
                  color: kVendor,
                  title: 'Vendor Pickup',
                  subtitle: order.vendorShopName ?? 'Vendor Location',
                ),
                _dottedLine(),

                // Customer dropoff
                _LocationRow(
                  icon: Icons.where_to_vote_rounded,
                  color: kRider,
                  title: 'Customer Drop-off',
                  subtitle: order.customerName ?? 'Customer',
                  detail: order.deliveryAddress,
                ),

                const SizedBox(height: 14),
                kSectionHeader('Order Details'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: kCardDeco(radius: 12),
                  child: Column(
                    children: order.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(children: [
                        Container(
                          width: 8, height: 8,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            color: kRider.withValues(alpha: 0.6),
                            shape: BoxShape.circle),
                        ),
                        Expanded(child: Text('${item.quantity}x ${item.productName}',
                          style: kBody(12, color: kTextSecondary))),
                        Text('Rs ${item.total.toStringAsFixed(0)}',
                          style: kBody(12, color: kTextPrimary,
                            fw: FontWeight.w600)),
                      ]),
                    )).toList(),
                  ),
                ),
                const SizedBox(height: 14),
              ],
            ),
          ),
        ],

        // ── Action button ────────────────────────────────────────────────
        if (order.status == 'dispatched') Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: ElevatedButton(
            onPressed: _delivering ? null : () async {
              setState(() => _delivering = true);
              await MarketplaceService.updateOrderStatus(order.id, 'delivered');
              setState(() => _delivering = false);
              widget.onAction();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kRider,
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: _delivering
                ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.where_to_vote_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text('Mark as Delivered', style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700, fontSize: 14)),
                  ]),
          ),
        )
        else if (order.status != 'delivered') Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: kCard, borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kBorder)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.schedule_rounded, color: kTextMuted, size: 16),
              const SizedBox(width: 8),
              Text('Waiting for dispatch',
                style: kBody(13, color: kTextMuted)),
            ]),
          ),
        )
        else Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: kSuccess.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: kSuccess.withValues(alpha: 0.3))),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.check_circle_rounded, color: kSuccess, size: 16),
              const SizedBox(width: 8),
              Text('Delivered Successfully',
                style: kBody(13, color: kSuccess, fw: FontWeight.w600)),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _dottedLine() => Padding(
    padding: const EdgeInsets.only(left: 18),
    child: Column(
      children: List.generate(4, (_) => Container(
        width: 2, height: 5,
        margin: const EdgeInsets.symmetric(vertical: 2),
        color: kBorder,
      )),
    ),
  );
}

class _LocationRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, subtitle;
  final String? detail;
  const _LocationRow({required this.icon, required this.color,
    required this.title, required this.subtitle, this.detail});

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: kLabel(10, color: kTextMuted, fw: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(subtitle, style: kBody(13, color: kTextPrimary,
              fw: FontWeight.w600)),
            if (detail != null) ...[
              const SizedBox(height: 2),
              Text(detail!, style: kLabel(10, color: kTextMuted),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    ],
  );
}
