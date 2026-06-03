import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';
import 'add_edit_product_screen.dart';
import '../../core/theme/app_colors.dart';
import '../../core/motion/motion_stagger.dart';
import '../../core/motion/motion_tappable.dart';
import '../../core/motion/motion_counter.dart';

// ── Vendor Dashboard Screen (Stitch Design) ───────────────────────────────────
class VendorDashboardScreen extends StatefulWidget {
  const VendorDashboardScreen({super.key});
  @override
  State<VendorDashboardScreen> createState() => _VendorDashboardScreenState();
}

class _VendorDashboardScreenState extends State<VendorDashboardScreen> {
  Map<String, dynamic>? _stats;
  List<Order> _pendingOrders = [];
  List<Product> _lowStockProducts = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    if (mounted) {
      setState(() => _loading = true);
    }
    final stats = await MarketplaceService.fetchVendorStats();
    final pending = await MarketplaceService.fetchVendorOrders(status: 'pending');
    final products = await MarketplaceService.fetchVendorProducts();
    final lowStock = products.where((p) => p.stockQuantity <= 5).toList();

    if (mounted) {
      setState(() {
        _stats = stats;
        _pendingOrders = pending;
        _lowStockProducts = lowStock;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopName = _stats?['shop_name'] ?? 'Your Shop';
    final revenue = (_stats?['total_revenue'] ?? 0.0) as double;
    final orders = (_stats?['total_orders'] ?? 0) as int;

    return Scaffold(
      backgroundColor: kBg,
      body: RefreshIndicator(
        color: kVendor, backgroundColor: kCard,
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            // ── Vendor App Bar ──────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: EdgeInsets.fromLTRB(
                    20, MediaQuery.of(context).padding.top + 16, 20, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back 👋', style: kBody(13, color: kTextMuted)),
                          const SizedBox(height: 4),
                          Text(shopName, style: kHeadline(20)),
                        ],
                      ),
                    ),
                    Row(children: [
                      TappableScale(
                        onTap: () {},
                        child: const Icon(Icons.notifications_none_rounded,
                            color: kTextSecondary),
                      ),
                      const SizedBox(width: 8),
                      TappableScale(
                        onTap: () {},
                        child: Container(
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            gradient: kVendorGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(child: Text(
                            (shopName.isNotEmpty ? shopName[0] : 'V').toUpperCase(),
                            style: GoogleFonts.inter(fontSize: 16,
                                fontWeight: FontWeight.w800, color: Colors.black))),
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(child: _loading
              ? _buildShimmerLoading()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),

                    // ── Revenue stats row ─────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(children: [
                        Expanded(child: StaggeredEntrance(
                          index: 0,
                          child: _StatCard(
                            label: 'Total Revenue',
                            value: '',
                            numericValue: revenue,
                            prefix: 'Rs ',
                            icon: Icons.trending_up_rounded,
                            accent: kVendor,
                            gradient: kVendorGradient,
                          ),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: StaggeredEntrance(
                          index: 1,
                          child: _StatCard(
                            label: 'Total Orders',
                            value: '',
                            numericValue: orders,
                            icon: Icons.receipt_long_rounded,
                            accent: kCyan,
                          ),
                        )),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(children: [
                        Expanded(child: StaggeredEntrance(
                          index: 2,
                          child: _StatCard(
                            label: 'Pending',
                            value: '',
                            numericValue: _pendingOrders.length,
                            icon: Icons.pending_actions_rounded,
                            accent: kWarning,
                          ),
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: StaggeredEntrance(
                          index: 3,
                          child: _StatCard(
                            label: 'Low Stock',
                            value: '',
                            numericValue: _lowStockProducts.length,
                            icon: Icons.inventory_rounded,
                            accent: kError,
                          ),
                        )),
                      ]),
                    ),

                    const SizedBox(height: 24),

                    // ── Quick actions ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(children: [
                        _QuickAction(
                          icon: Icons.add_box_rounded,
                          label: 'Add Product',
                          accent: kVendor,
                          onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) =>
                              const AddEditProductScreen()))
                            .then((_) => _load()),
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          icon: Icons.inventory_2_rounded,
                          label: 'Stock Manager',
                          accent: kCyan,
                          onTap: () {},
                        ),
                        const SizedBox(width: 12),
                        _QuickAction(
                          icon: Icons.bar_chart_rounded,
                          label: 'Analytics',
                          accent: kRider,
                          onTap: () {},
                        ),
                      ]),
                    ),

                    const SizedBox(height: 24),

                    // ── Low Stock Alert ───────────────────────────────────────
                    if (_lowStockProducts.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: kSectionHeader(
                          '⚠️  Low Stock Alert',
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: kError.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('${_lowStockProducts.length} items',
                              style: kBody(10, color: kError, fw: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 88,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _lowStockProducts.length,
                          itemBuilder: (_, i) {
                            final p = _lowStockProducts[i];
                            return Container(
                              width: 180,
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(12),
                              decoration: kGlowDeco(kError, radius: 14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(p.name, style: kBody(11, color: kTextPrimary,
                                    fw: FontWeight.w600),
                                    maxLines: 1, overflow: TextOverflow.ellipsis),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.inventory_2_rounded,
                                        color: kError, size: 12),
                                    const SizedBox(width: 4),
                                    Text('${p.stockQuantity} left',
                                      style: kBody(11, color: kError,
                                        fw: FontWeight.w600)),
                                  ]),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ── Pending Orders Preview ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: kSectionHeader('Pending Orders Preview',
                        trailing: TextButton(
                          onPressed: () {},
                          child: Text('See all', style: kBody(12, color: kVendor,
                            fw: FontWeight.w600)),
                        )),
                    ),
                    const SizedBox(height: 10),
                    if (_pendingOrders.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Center(child: Text('No pending orders',
                          style: kBody(13, color: kTextMuted))),
                      )
                    else
                      ..._pendingOrders.asMap().entries.map((e) {
                        final idx = e.key;
                        final order = e.value;
                        return StaggeredEntrance(
                          index: idx + 4,
                          child: _PendingOrderRow(order: order, onAction: _load),
                        );
                      }),

                    const SizedBox(height: 100),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.card,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: Container(height: 110, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)))),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 110, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Container(height: 110, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)))),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 110, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16)))),
            ]),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: Container(height: 70, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)))),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 70, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)))),
              const SizedBox(width: 12),
              Expanded(child: Container(height: 70, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14)))),
            ]),
            const SizedBox(height: 32),
            Container(width: 150, height: 18, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 16),
            Container(height: 80, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14))),
            const SizedBox(height: 12),
            Container(height: 80, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(14))),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label, value;
  final num? numericValue;
  final String prefix;
  final IconData icon;
  final Color accent;
  final LinearGradient? gradient;
  const _StatCard({required this.label, required this.value, this.numericValue, this.prefix = '',
    required this.icon, required this.accent, this.gradient});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.inter(
      fontSize: 22, fontWeight: FontWeight.w800,
      color: gradient != null ? Colors.black : kTextPrimary,
      letterSpacing: -0.5);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? kCard : null,
        borderRadius: BorderRadius.circular(16),
        border: gradient == null ? Border.all(color: accent.withValues(alpha: 0.3)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: gradient != null
                    ? Colors.black.withValues(alpha: 0.2)
                    : accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon,
                color: gradient != null ? Colors.white : accent, size: 18),
            ),
          ]),
          const SizedBox(height: 12),
          if (numericValue != null)
            MotionCounter(
              value: numericValue!,
              prefix: prefix,
              style: style,
            )
          else
            Text(value, style: style),
          const SizedBox(height: 2),
          Text(label, style: kBody(11,
            color: gradient != null ? Colors.black54 : kTextMuted)),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accent;
  final VoidCallback onTap;
  const _QuickAction({required this.icon, required this.label,
    required this.accent, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: TappableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, color: accent, size: 24),
            const SizedBox(height: 6),
            Text(label, style: kBody(10, color: accent, fw: FontWeight.w600),
              textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}

class _PendingOrderRow extends StatelessWidget {
  final Order order;
  final VoidCallback onAction;
  const _PendingOrderRow({required this.order, required this.onAction});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
    padding: const EdgeInsets.all(14),
    decoration: kGlowDeco(kWarning, radius: 14),
    child: Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: kWarning.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(child: Text(
            (order.customerName?.isNotEmpty == true
                ? order.customerName![0] : '?').toUpperCase(),
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800,
              color: kWarning))),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.customerName ?? 'Customer', style: kBody(13,
                color: kTextPrimary, fw: FontWeight.w600)),
              Text('Order #OD-${order.id.substring(0, 6).toUpperCase()} · '
                '${order.items.length} items', style: kLabel(10)),
              const SizedBox(height: 2),
              Text('Rs ${order.totalAmount.toStringAsFixed(0)}',
                style: kBody(12, color: kVendor, fw: FontWeight.w700)),
            ],
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          kStatusPill(order.paymentMethod ?? 'COD', kCyan, fontSize: 10),
          const SizedBox(height: 6),
          TappableScale(
            onTap: () async {
              await MarketplaceService.updateOrderStatus(order.id, 'confirmed');
              onAction();
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: kSuccess.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: kSuccess.withValues(alpha: 0.4)),
              ),
              child: Text('Confirm', style: kBody(10, color: kSuccess,
                fw: FontWeight.w600)),
            ),
          ),
        ]),
      ],
    ),
  );
}
