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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final orders = await MarketplaceService.fetchAllOrders();
    if (mounted) {
      setState(() {
        _orders = orders;
        _loading = false;
      });
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
            SizedBox(width: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
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
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Icon(Icons.refresh_rounded, color: kAdmin),
            ),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: kAdmin))
          : _orders.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: _load, color: kAdmin, backgroundColor: kSurface,
                  child: ListView.separated(
                    padding: EdgeInsets.all(16),
                    itemCount: _orders.length,
                    separatorBuilder: (context, i) => SizedBox(height: 10),
                    itemBuilder: (context, i) => StaggeredEntrance(
                      index: i,
                      child: _AdminOrderTile(
                        order: _orders[i],
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
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: kSurface,
            border: Border.all(color: kBorder),
          ),
          child: Icon(
            Icons.receipt_long_rounded,
            color: kAdmin,
            size: 64,
          ),
        )
        .animate()
        .scaleXY(begin: 0.8, end: 1.0, duration: 600.ms, curve: Curves.easeOutBack)
        .fadeIn(duration: 500.ms),
        SizedBox(height: 16),
        Text('No orders yet', style: GoogleFonts.inter(color: Colors.white38, fontSize: 16)),
      ],
    ),
  );
}

class _AdminOrderTile extends StatelessWidget {
  final Order order;
  const _AdminOrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(order.status);
    final date  = DateFormat('d MMM, hh:mm a').format(order.createdAt.toLocal());

    return Container(
      padding: EdgeInsets.all(14),
      decoration: kGlowCard(backgroundColor),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Order #${order.id.substring(0, 8).toUpperCase()}',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
            Text('${order.vendorShopName ?? "Vendor"}  →  ${order.customerName ?? "Customer"}',
                style: GoogleFonts.inter(color: Colors.white38, fontSize: 11)),
          ])),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
            child: Text('${statusIcon(order.status)} ${statusLabel(order.status)}',
                style: GoogleFonts.inter(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
          ),
        ]),
        SizedBox(height: 8),
        Row(children: [
          MotionCounter(
            value: order.totalAmount,
            prefix: 'Rs ',
            style: GoogleFonts.inter(color: kCyan, fontSize: 13, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 12),
          Text(date, style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
        ]),
        if (order.riderId != null) Padding(
          padding: EdgeInsets.only(top: 6),
          child: Text('🏍️ Rider: ${order.riderName ?? "Assigned"}',
              style: GoogleFonts.inter(color: kRider, fontSize: 11, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
