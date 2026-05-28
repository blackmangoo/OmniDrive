import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';

// ── Order Tracking Screen (Stitch Design) ─────────────────────────────────────
class CustomerOrdersScreen extends StatefulWidget {
  const CustomerOrdersScreen({super.key});
  @override
  State<CustomerOrdersScreen> createState() => _CustomerOrdersScreenState();
}

class _CustomerOrdersScreenState extends State<CustomerOrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await MarketplaceService.fetchCustomerOrders();
    if (mounted) setState(() { _orders = orders; _loading = false; });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: kBg,
    appBar: AppBar(
      backgroundColor: kBg,
      surfaceTintColor: Colors.transparent,
      title: Text('My Orders', style: kHeadline(18)),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: kTextSecondary),
          onPressed: _load,
        ),
      ],
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: kCyan))
        : _orders.isEmpty
            ? _emptyOrders()
            : RefreshIndicator(
                color: kCyan, backgroundColor: kCard,
                onRefresh: _load,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: _orders.length,
                  itemBuilder: (_, i) => _OrderTrackCard(order: _orders[i]),
                ),
              ),
  );

  Widget _emptyOrders() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.receipt_long_outlined, size: 64, color: kBorder),
      const SizedBox(height: 16),
      Text('No orders yet', style: kHeadline(16, color: kTextSecondary)),
      const SizedBox(height: 8),
      Text('Place your first order from the marketplace', style: kBody(13)),
    ]),
  );
}

// ── Individual order track card ───────────────────────────────────────────────
class _OrderTrackCard extends StatefulWidget {
  final Order order;
  const _OrderTrackCard({required this.order});
  @override
  State<_OrderTrackCard> createState() => _OrderTrackCardState();
}

class _OrderTrackCardState extends State<_OrderTrackCard> {
  bool _expanded = false;

  static const _steps = [
    _Step('pending',    'Pending',    Icons.schedule_rounded),
    _Step('confirmed',  'Confirmed',  Icons.check_circle_outline_rounded),
    _Step('preparing',  'Preparing',  Icons.restaurant_rounded),
    _Step('ready',      'Ready',      Icons.inventory_2_rounded),
    _Step('dispatched', 'Dispatched', Icons.delivery_dining_rounded),
    _Step('delivered',  'Delivered',  Icons.where_to_vote_rounded),
  ];

  int get _currentStep {
    final idx = _steps.indexWhere((s) => s.id == widget.order.status);
    return idx == -1 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final accent = statusColor(order.status);
    final fmt = DateFormat('MMM d, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: kGlowDeco(accent, radius: 18),
      child: Column(
        children: [
          // ── Header ───────────────────────────────────────────────────────
          GestureDetector(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('#OD-${order.id.substring(0, 8).toUpperCase()}',
                              style: GoogleFonts.inter(fontSize: 13,
                                fontWeight: FontWeight.w700, color: kTextPrimary,
                                letterSpacing: 0.5)),
                            const SizedBox(height: 2),
                            Text(fmt.format(order.createdAt),
                              style: kBody(11, color: kTextMuted)),
                          ],
                        ),
                      ),
                      kStatusPill(statusLabel(order.status), accent),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _InfoChip(Icons.storefront_rounded,
                          order.vendorShopName ?? 'Vendor'),
                      const SizedBox(width: 8),
                      _InfoChip(Icons.payments_rounded,
                          'Rs ${order.totalAmount.toStringAsFixed(0)}',
                          color: kCyan),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ── Progress timeline (mini) ──────────────────────────
                  _MiniTimeline(steps: _steps, currentStep: _currentStep),

                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(_expanded ? 'Hide details' : 'View details',
                        style: kBody(12, color: kCyan, fw: FontWeight.w600)),
                      Icon(_expanded ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                        color: kCyan, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Expanded details ──────────────────────────────────────────────
          if (_expanded) ...[
            Divider(color: kBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Full timeline
                  ..._steps.asMap().entries.map((e) {
                    final i = e.key;
                    final step = e.value;
                    final done = i <= _currentStep;
                    final active = i == _currentStep;
                    final color = active ? accent : (done ? kSuccess : kBorder);
                    return _TimelineRow(
                      step: step, done: done, active: active, color: color,
                      isLast: i == _steps.length - 1,
                    );
                  }),
                  const SizedBox(height: 16),

                  // Rider info
                  if (order.status == 'dispatched' && order.riderName != null) ...[
                    kSectionHeader('Your Rider'),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: kCardDeco(accent: kRider, radius: 12),
                      child: Row(children: [
                        Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kRider.withValues(alpha: 0.2),
                          ),
                          child: const Icon(Icons.person_rounded,
                              color: kRider, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(order.riderName!,
                                style: kHeadline(13, fw: FontWeight.w600)),
                              if (order.riderPhone != null)
                                Text(order.riderPhone!,
                                  style: kBody(11, color: kTextMuted)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: kSuccess.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.phone_rounded,
                              color: kSuccess, size: 18),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Order items
                  kSectionHeader('Shipment Contents'),
                  const SizedBox(height: 10),
                  if (order.items.isEmpty)
                    Text('No items', style: kBody(12))
                  else
                    ...order.items.map((item) => _ItemRow(item: item)),

                  const SizedBox(height: 12),
                  // Delivery address
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: kCardDeco(radius: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: kCyan, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(order.deliveryAddress,
                          style: kBody(12), maxLines: 2,
                          overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Step {
  final String id, label;
  final IconData icon;
  const _Step(this.id, this.label, this.icon);
}

class _MiniTimeline extends StatelessWidget {
  final List<_Step> steps;
  final int currentStep;
  const _MiniTimeline({required this.steps, required this.currentStep});

  @override
  Widget build(BuildContext context) => Row(
    children: steps.asMap().entries.map((e) {
      final i = e.key;
      final done = i <= currentStep;
      return Expanded(
        child: Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? kSuccess : kBorder,
              ),
            ),
            if (i < steps.length - 1) Expanded(
              child: Container(height: 2,
                color: done && i < currentStep ? kSuccess : kBorder),
            ),
          ],
        ),
      );
    }).toList(),
  );
}

class _TimelineRow extends StatelessWidget {
  final _Step step;
  final bool done, active, isLast;
  final Color color;
  const _TimelineRow({required this.step, required this.done,
    required this.active, required this.isLast, required this.color});

  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: active ? 0.25 : 0.1),
              border: Border.all(color: color, width: active ? 2 : 1),
            ),
            child: Icon(step.icon, size: 15, color: color),
          ),
          if (!isLast) Expanded(
            child: Container(width: 2,
              color: done ? kSuccess.withValues(alpha: 0.4) : kBorder)),
        ]),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(step.label, style: GoogleFonts.inter(
                fontSize: 13, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? color : (done ? kTextSecondary : kTextMuted))),
              if (active) Text('IN PROGRESS',
                style: kLabel(9, color: color, fw: FontWeight.w700)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ItemRow extends StatelessWidget {
  final OrderItem item;
  const _ItemRow({required this.item});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: kCard, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kBorder),
          ),
          child: item.productImage != null
              ? ClipRRect(borderRadius: BorderRadius.circular(9),
                  child: Image.network(item.productImage!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.inventory_2_rounded, color: kBorder, size: 18)))
              : const Icon(Icons.inventory_2_rounded, color: kBorder, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.productName, style: kBody(12, color: kTextPrimary,
                fw: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
              Text('Qty: ${item.quantity}', style: kLabel(10)),
            ],
          ),
        ),
        Text('Rs ${item.total.toStringAsFixed(0)}',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700,
            color: kCyan)),
      ],
    ),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip(this.icon, this.label, {this.color = kTextMuted});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Icon(icon, color: color, size: 13),
      const SizedBox(width: 4),
      Text(label, style: kBody(11, color: color)),
    ],
  );
}
