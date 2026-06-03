import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';
import '../../core/motion/motion_stagger.dart';
import '../../core/motion/motion_tappable.dart';
import '../../core/motion/motion_counter.dart';

// ── Vendor Orders Screen (Stitch Design) ─────────────────────────────────────
class VendorOrdersScreen extends StatefulWidget {
  const VendorOrdersScreen({super.key});
  @override
  State<VendorOrdersScreen> createState() => _VendorOrdersScreenState();
}

class _VendorOrdersScreenState extends State<VendorOrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _tabs = const [
    _TabCfg('All', null),
    _TabCfg('Pending', 'pending'),
    _TabCfg('Confirmed', 'confirmed'),
    _TabCfg('Preparing', 'preparing'),
    _TabCfg('Ready', 'ready'),
    _TabCfg('Done', 'delivered'),
  ];

  Map<String, List<Order>> _ordersByStatus = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _tabs.length, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final all = await MarketplaceService.fetchVendorOrders();
    final map = <String, List<Order>>{'all': all};
    for (final status in ['pending', 'confirmed', 'preparing', 'ready', 'delivered']) {
      map[status] = all.where((o) => o.status == status).toList();
    }
    if (mounted) {
      setState(() {
        _ordersByStatus = map;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    body: Column(
      children: [
        // ── Header ─────────────────────────────────────────────────────────
        Container(
          padding: EdgeInsets.fromLTRB(
              20, MediaQuery.of(context).padding.top + 16, 20, 0),
          decoration: const BoxDecoration(
            color: kBg,
            border: Border(bottom: BorderSide(color: kBorder)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Vendor Dashboard', style: kLabel(12, color: kTextMuted)),
                    const SizedBox(height: 2),
                    Text('Active Orders', style: kHeadline(22)),
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: kVendor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: kVendor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MotionCounter(
                        value: _ordersByStatus['all']?.length ?? 0,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: kVendor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text('orders', style: GoogleFonts.inter(
                        fontSize: 11,
                        color: kVendor,
                        fontWeight: FontWeight.w600,
                      )),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              TabBar(
                controller: _tab,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelStyle: GoogleFonts.inter(fontSize: 12,
                  fontWeight: FontWeight.w700),
                unselectedLabelStyle: GoogleFonts.inter(fontSize: 12,
                  fontWeight: FontWeight.w500),
                labelColor: kVendor,
                unselectedLabelColor: kTextMuted,
                indicatorColor: kVendor,
                indicatorWeight: 2.5,
                padding: EdgeInsets.zero,
                dividerColor: Colors.transparent,
                tabs: _tabs.map((t) {
                  final count = t.status == null
                      ? _ordersByStatus['all']?.length ?? 0
                      : _ordersByStatus[t.status]?.length ?? 0;
                  return Tab(text: count > 0 ? '${t.label} ($count)' : t.label);
                }).toList(),
              ),
            ],
          ),
        ),

        // ── Tab content ────────────────────────────────────────────────────
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: kVendor))
              : TabBarView(
                  controller: _tab,
                  children: _tabs.map((t) {
                    final orders = t.status == null
                        ? _ordersByStatus['all'] ?? []
                        : _ordersByStatus[t.status] ?? [];
                    return _OrderList(orders: orders, onStatusChange: _load);
                  }).toList(),
                ),
        ),
      ],
    ),
  );
}

class _TabCfg {
  final String label;
  final String? status;
  const _TabCfg(this.label, this.status);
}

class _OrderList extends StatelessWidget {
  final List<Order> orders;
  final VoidCallback onStatusChange;
  const _OrderList({required this.orders, required this.onStatusChange});

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.receipt_long_outlined, size: 56, color: kBorder),
          const SizedBox(height: 12),
          Text('No orders in this status', style: kBody(13, color: kTextMuted)),
        ]),
      );
    }
    return RefreshIndicator(
      color: kVendor, backgroundColor: kCard,
      onRefresh: () async => onStatusChange(),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: orders.length,
        itemBuilder: (context, i) => StaggeredEntrance(
          index: i,
          child: _VendorOrderCard(
            order: orders[i],
            onAction: onStatusChange,
          ),
        ),
      ),
    );
  }
}

class _VendorOrderCard extends StatefulWidget {
  final Order order;
  final VoidCallback onAction;
  const _VendorOrderCard({required this.order, required this.onAction});
  @override
  State<_VendorOrderCard> createState() => _VendorOrderCardState();
}

class _VendorOrderCardState extends State<_VendorOrderCard> {
  bool _expanded = false;
  bool _updating = false;

  static const _nextStatus = {
    'pending':    'confirmed',
    'confirmed':  'preparing',
    'preparing':  'ready',
    'ready':      'dispatched',
  };

  static const _nextLabel = {
    'pending':    'Confirm Order',
    'confirmed':  'Start Preparing',
    'preparing':  'Mark Ready',
    'ready':      'Mark Dispatched',
  };

  Future<void> _advance() async {
    final next = _nextStatus[widget.order.status];
    if (next == null) return;
    setState(() => _updating = true);
    await MarketplaceService.updateOrderStatus(widget.order.id, next);
    if (mounted) {
      setState(() => _updating = false);
    }
    widget.onAction();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final accent = statusColor(order.status);
    final fmt = DateFormat('MMM d, HH:mm');
    final nextLabel = _nextLabel[order.status];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: kGlowDeco(accent, radius: 18),
      child: Column(children: [
        TappableScale(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              Row(children: [
                // Customer initials
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14)),
                  child: Center(child: Text(
                    (order.customerName?.isNotEmpty == true
                      ? order.customerName![0] : '?').toUpperCase(),
                    style: GoogleFonts.inter(fontSize: 18,
                      fontWeight: FontWeight.w800, color: accent))),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(order.customerName ?? 'Customer',
                        style: kBody(14, color: kTextPrimary, fw: FontWeight.w700)),
                      Text('Order #OD-${order.id.substring(0,8).toUpperCase()} · '
                        '${fmt.format(order.createdAt)}',
                        style: kLabel(10)),
                    ],
                  ),
                ),
                kStatusPill(statusLabel(order.status), accent, fontSize: 10),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _Chip(Icons.shopping_bag_rounded,
                  '${order.items.length} items', kTextMuted),
                const SizedBox(width: 8),
                Row(
                  children: [
                    const Icon(Icons.payments_rounded, color: kVendor, size: 12),
                    const SizedBox(width: 4),
                    MotionCounter(
                      value: order.totalAmount,
                      prefix: 'Rs ',
                      style: kBody(11, color: kVendor),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                _Chip(Icons.receipt_rounded,
                  order.paymentMethod ?? 'COD', kCyan),
              ]),
            ]),
          ),
        ),

        // order items (expanded)
        if (_expanded) ...[
          Divider(color: kBorder, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                kSectionHeader('Order Items'),
                const SizedBox(height: 10),
                ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        color: kCard, borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: kBorder)),
                      child: item.productImage != null
                          ? ClipRRect(borderRadius: BorderRadius.circular(7),
                              child: CachedNetworkImage(imageUrl: item.productImage!,
                                fit: BoxFit.cover,
                                errorWidget: (_, _, _) => const Icon(
                                  Icons.inventory_2_rounded, color: kBorder, size: 16)))
                          : const Icon(Icons.inventory_2_rounded,
                              color: kBorder, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(item.productName, style: kBody(12,
                      color: kTextPrimary, fw: FontWeight.w500),
                      overflow: TextOverflow.ellipsis)),
                    Text('×${item.quantity}', style: kLabel(11)),
                    const SizedBox(width: 8),
                    MotionCounter(
                      value: item.total,
                      prefix: 'Rs ',
                      style: kBody(12, color: kVendor, fw: FontWeight.w700),
                    ),
                  ]),
                )),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_rounded, color: kCyan, size: 14),
                  const SizedBox(width: 6),
                  Expanded(child: Text(order.deliveryAddress,
                    style: kBody(11, color: kTextMuted), maxLines: 2,
                    overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],

        // Action button
        if (nextLabel != null) Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
          child: TappableScale(
            onTap: _updating ? null : _advance,
            child: Container(
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: _updating
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.black))
                  : Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.black),
                      const SizedBox(width: 6),
                      Text(nextLabel, style: GoogleFonts.inter(
                        fontSize: 13, fontWeight: FontWeight.w700, color: Colors.black)),
                    ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _Chip(this.icon, this.label, this.color);

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: color, size: 12),
    const SizedBox(width: 4),
    Text(label, style: kBody(11, color: color)),
  ]);
}
