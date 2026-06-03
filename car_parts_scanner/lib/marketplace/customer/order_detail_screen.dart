import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/motion/motion_tappable.dart';
import '../../core/motion/motion_stagger.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(order.status);
    final date  = DateFormat('EEEE, d MMM yyyy  •  hh:mm a').format(order.createdAt.toLocal());

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        leading: TappableScale(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
        ),
        title: Text('Order Details', style: AppTypography.h2.copyWith(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Status Card ───────────────────────────────────────────────
            StaggeredEntrance(
              index: 0,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: kGlowCard(color),
                child: Column(children: [
                  Text(statusIcon(order.status), style: const TextStyle(fontSize: 42)),
                  const SizedBox(height: 10),
                  Text(statusLabel(order.status),
                      style: GoogleFonts.inter(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(date, style: AppTypography.body.copyWith(color: AppColors.textMuted, fontSize: 12)),
                ]),
              ),
            ),

            const SizedBox(height: 20),

            // ── Order ID ────────────────────────────────────────────────
            StaggeredEntrance(
              index: 1,
              child: _infoCard(children: [
                _infoRow('Order ID', '#${order.id.substring(0, 8).toUpperCase()}'),
                _infoRow('Total', 'Rs ${order.totalAmount.toStringAsFixed(0)}', valueColor: kAccent),
                _infoRow('Delivery Fee', 'Rs ${order.deliveryFee.toStringAsFixed(0)}'),
                if (order.customerNotes != null)
                  _infoRow('Notes', order.customerNotes!),
              ]),
            ),

            const SizedBox(height: 16),

            // ── Items ────────────────────────────────────────────────────
            _sectionHeader('Items Ordered'),
            ...order.items.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              return StaggeredEntrance(
                index: idx + 2,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: kCardDeco(),
                    child: Row(children: [
                      if (item.productImage != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(item.productImage!, width: 44, height: 44, fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => const Icon(Icons.car_repair, color: Colors.white24)),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item.productName, style: AppTypography.title.copyWith(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${item.quantity} × Rs ${item.unitPrice.toStringAsFixed(0)}',
                              style: AppTypography.body.copyWith(color: AppColors.textMuted, fontSize: 12)),
                        ]),
                      ),
                      Text('Rs ${item.total.toStringAsFixed(0)}',
                          style: AppTypography.title.copyWith(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // ── Vendor Info ──────────────────────────────────────────────
            _sectionHeader('Vendor'),
            _infoCard(children: [
              _infoRow('Shop', order.vendorShopName ?? '—'),
              _infoRow('Location', order.vendorLocation ?? '—'),
              if (order.vendorPhone != null) _infoRow('Phone', order.vendorPhone!),
            ]),

            const SizedBox(height: 16),

            // ── Delivery Address ─────────────────────────────────────────
            _sectionHeader('Delivery Address'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: kCardDeco(),
              child: Row(children: [
                const Icon(Icons.location_on_rounded, color: kAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(order.deliveryAddress, style: AppTypography.body.copyWith(color: Colors.white70, fontSize: 13))),
              ]),
            ),

            // ── Rider Info (when dispatched) ──────────────────────────────
            if (order.status == 'dispatched' || order.status == 'delivered') ...[
              const SizedBox(height: 16),
              _sectionHeader('Rider'),
              _infoCard(children: [
                _infoRow('Name', order.riderName ?? 'Assigned'),
                if (order.riderPhone != null) _infoRow('Phone', order.riderPhone!),
              ]),
            ],

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 3, height: 16, decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(2))),
      const SizedBox(width: 10),
      Text(t, style: AppTypography.title.copyWith(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _infoCard({required List<Widget> children}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: kCardDeco(),
    child: Column(children: [
      for (int i = 0; i < children.length; i++) ...[
        children[i],
        if (i < children.length - 1) Divider(color: kBorder, height: 16),
      ],
    ]),
  );

  Widget _infoRow(String label, String value, {Color? valueColor}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: AppTypography.body.copyWith(color: AppColors.textMuted, fontSize: 13)),
      Flexible(
        child: Text(value, textAlign: TextAlign.end,
            style: AppTypography.body.copyWith(color: valueColor ?? Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    ],
  );
}
