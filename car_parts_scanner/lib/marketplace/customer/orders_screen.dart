import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  List<Order> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final orders = await MarketplaceService.fetchCustomerOrders();
    if (mounted) setState(() { _orders = orders; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        automaticallyImplyLeading: false,
        title: Text('My Orders', style: GoogleFonts.inter(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: kAccent))
          : _orders.isEmpty
              ? _empty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: kAccent, backgroundColor: kSurface,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _OrderTile(order: _orders[i]),
                  ),
                ),
    );
  }

  Widget _empty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.receipt_long_outlined, size: 72, color: Colors.white12),
      const SizedBox(height: 16),
      Text("No orders yet", style: GoogleFonts.inter(color: Colors.white38, fontSize: 16)),
    ]),
  );
}

class _OrderTile extends StatelessWidget {
  final Order order;
  const _OrderTile({required this.order});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(order.status);
    final date  = DateFormat('d MMM, hh:mm a').format(order.createdAt.toLocal());
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: kGlowCard(color),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('Order #${order.id.substring(0, 8).toUpperCase()}',
                style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            const Spacer(),
            _StatusPill(status: order.status),
          ]),
          const SizedBox(height: 8),
          Text(order.vendorShopName ?? 'Vendor', style: GoogleFonts.inter(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 6),
          Row(children: [
            Text('${order.items.length} item(s)', style: GoogleFonts.inter(color: Colors.white38, fontSize: 12)),
            const Spacer(),
            Text('Rs ${order.totalAmount.toStringAsFixed(0)}',
                style: GoogleFonts.inter(color: kAccent, fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 6),
          Text(date, style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),
        ]),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String status;
  const _StatusPill({required this.status});
  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text('${statusIcon(status)} ${statusLabel(status)}',
          style: GoogleFonts.inter(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }
}
