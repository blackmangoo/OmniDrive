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

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  List<Order> _orders = [];
  List<AppUser> _riders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final orders = await MarketplaceService.fetchAllOrders();
    final riders = await MarketplaceService.fetchRiders();
    if (mounted) {
      setState(() {
        _orders = orders;
        _riders = riders;
        _loading = false;
      });
    }
  }

  /// Show a dialog to assign a rider to the order
  Future<void> _assignRider(Order order) async {
    if (_riders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('No riders available. Add rider accounts first.'),
        backgroundColor: kWarning, behavior: SnackBarBehavior.floating));
      return;
    }
    final selected = await showDialog<AppUser>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Assign Rider', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _riders.map((r) => TappableScale(
            onTap: () => Navigator.pop(context, r),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: kCardDeco(radius: 12),
              child: ListTile(
                leading: const Icon(Icons.delivery_dining_rounded, color: kRider),
                title: Text(r.fullName, style: GoogleFonts.inter(color: Colors.white)),
                subtitle: Text(r.phone ?? r.email, style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
              ),
            ),
          )).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white38))),
        ],
      ),
    );

    if (selected != null) {
      await MarketplaceService.assignRider(order.id, selected.id);
      _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Rider ${selected.fullName} assigned!', style: GoogleFonts.inter()),
        backgroundColor: kSuccess, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg, automaticallyImplyLeading: false,
        title: Row(
          children: [
            Text('All Orders', style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: kAdmin.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
              child: MotionCounter(
                value: _orders.length,
                style: GoogleFonts.inter(color: kAdmin, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        actions: [
          TappableScale(
            onTap: _load,
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.refresh_rounded, color: kAdmin),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAdmin))
          : _orders.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: _load, color: kAdmin, backgroundColor: kSurface,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    separatorBuilder: (context, i) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => StaggeredEntrance(
                      index: i,
                      child: _AdminOrderTile(
                        order: _orders[i],
                        onAssignRider: _orders[i].status == 'ready' && _orders[i].riderId == null
                            ? () => _assignRider(_orders[i])
                            : null,
                      ),
                    ),
                  ),
                ),
    );
  }

  Widget _empty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/nano_banana_empty.png',
          width: 120,
          height: 120,
        )
        .animate()
        .scaleXY(begin: 0.8, end: 1.0, duration: 600.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 500.ms),
        const SizedBox(height: 16),
        Text('No orders yet', style: GoogleFonts.inter(color: Colors.white38, fontSize: 16)),
      ],
    ),
  );
}

class _AdminOrderTile extends StatelessWidget {
  final Order order;
  final VoidCallback? onAssignRider;
  const _AdminOrderTile({required this.order, this.onAssignRider});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(order.status);
    final date  = DateFormat('d MMM, hh:mm a').format(order.createdAt.toLocal());

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: kGlowCard(color),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Order #${order.id.substring(0, 8).toUpperCase()}',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            Text('${order.vendorShopName ?? "Vendor"}  →  ${order.customerName ?? "Customer"}',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Text('${statusIcon(order.status)} ${statusLabel(order.status)}',
                style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          MotionCounter(
            value: order.totalAmount,
            prefix: 'Rs ',
            style: GoogleFonts.inter(color: kCyan, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Text(date, style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
        ]),
        if (order.riderId != null) Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('🏍️ Rider: ${order.riderName ?? "Assigned"}',
              style: GoogleFonts.inter(color: kRider, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
        if (onAssignRider != null) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity, height: 38,
            child: TappableScale(
              onTap: onAssignRider,
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kRider,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.delivery_dining_rounded, size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text('Assign Rider', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                ]),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}
