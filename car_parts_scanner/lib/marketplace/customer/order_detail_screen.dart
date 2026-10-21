import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../../core/theme/app_typography.dart';
import '../../core/motion/motion_tappable.dart';
import '../../core/motion/motion_stagger.dart';
import 'package:car_parts_scanner/core/theme/app_colors.dart';


class OrderDetailScreen extends StatelessWidget {
  final Order order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg,
        elevation: 0,
        leading: TappableScale(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textSecondary, size: 20),
        ),
        title: Text('Order Details', style: AppTypography.h2.copyWith(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Interactive Status Stepper Card ───────────────────────────
            StaggeredEntrance(
              index: 0,
              child: _OrderTrackingStepper(order: order),
            ),

            SizedBox(height: 20),

            // ── Order ID ────────────────────────────────────────────────
            StaggeredEntrance(
              index: 1,
              child: _infoCard(children: [
                _infoRow('Order ID', '#${order.id.substring(0, 8).toUpperCase()}'),
                _infoRow('Total', 'Rs ${order.totalAmount.toStringAsFixed(0)}', valueColor: kAccent),
                _infoRow('Payment Method', order.paymentMethod ?? 'COD', valueColor: kSuccess),
                _infoRow('Delivery Fee', 'Rs ${order.deliveryFee.toStringAsFixed(0)}'),
                if (order.customerNotes != null)
                  _infoRow('Notes', order.customerNotes!),
              ]),
            ),

            SizedBox(height: 16),

            // ── Items ────────────────────────────────────────────────────
            _sectionHeader('Items Ordered'),
            ...order.items.asMap().entries.map((e) {
              final idx = e.key;
              final item = e.value;
              return StaggeredEntrance(
                index: idx + 2,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: kCardDeco(),
                    child: Row(children: [
                      if (item.productImage != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(item.productImage!, width: 44, height: 44, fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => Icon(Icons.car_repair, color: (AppColors.textMuted.withValues(alpha: 0.5)))),
                        ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(item.productName, style: AppTypography.title.copyWith(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                          Text('${item.quantity} × Rs ${item.unitPrice.toStringAsFixed(0)}',
                              style: AppTypography.body.copyWith(color: AppColors.textMuted, fontSize: 12)),
                        ]),
                      ),
                      Text('Rs ${item.total.toStringAsFixed(0)}',
                          style: AppTypography.title.copyWith(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
              );
            }),

            SizedBox(height: 16),

            // ── Vendor Info ──────────────────────────────────────────────
            _sectionHeader('Vendor'),
            _infoCard(children: [
              _infoRow('Shop', order.vendorShopName ?? '—'),
              _infoRow('Location', order.vendorLocation ?? '—'),
              if (order.vendorPhone != null) _infoRow('Phone', order.vendorPhone!),
            ]),

            SizedBox(height: 16),

            // ── Delivery Address ─────────────────────────────────────────
            _sectionHeader('Delivery Address'),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: kCardDeco(),
              child: Row(children: [
                Icon(Icons.location_on_rounded, color: kAccent, size: 20),
                SizedBox(width: 10),
                Expanded(child: Text(order.deliveryAddress, style: AppTypography.body.copyWith(color: AppColors.textSecondary, fontSize: 13))),
              ]),
            ),

            // ── Rider Info (when dispatched) ──────────────────────────────
            if (order.status == 'dispatched' || order.status == 'delivered') ...[
              SizedBox(height: 16),
              _sectionHeader('Rider'),
              _infoCard(children: [
                _infoRow('Name', order.riderName ?? 'Assigned'),
                if (order.riderPhone != null) _infoRow('Phone', order.riderPhone!),
              ]),
            ],

            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String t) => Padding(
    padding: EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 3, height: 16, decoration: BoxDecoration(color: kAccent, borderRadius: BorderRadius.circular(2))),
      SizedBox(width: 10),
      Text(t, style: AppTypography.title.copyWith(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
    ]),
  );

  Widget _infoCard({required List<Widget> children}) => Container(
    width: double.infinity,
    padding: EdgeInsets.all(16),
    margin: EdgeInsets.only(bottom: 16),
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
            style: AppTypography.body.copyWith(color: valueColor ?? AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    ],
  );
}

// ── Multi-Stage Delivery Stepper ─────────────────────────────────────────────

class _OrderTrackingStepper extends StatelessWidget {
  final Order order;
  const _OrderTrackingStepper({required this.order});

  int get _currentStepIndex {
    switch (order.status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'confirmed':
      case 'preparing':
        return 1;
      case 'ready':
      case 'dispatched':
        return 2;
      case 'delivered':
        return 3;
      default:
        return -1; // Cancelled
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCancelled = order.status.toLowerCase() == 'cancelled';
    final date = DateFormat('EEEE, d MMM yyyy  •  hh:mm a').format(order.createdAt.toLocal());
    final statusBadgeColor = statusColor(order.status);

    if (isCancelled) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kError.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kError.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: kError.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.cancel_rounded, color: kError, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order Cancelled',
                      style: GoogleFonts.inter(color: kError, fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    'This order was cancelled. Please browse the marketplace to place a new order.',
                    style: AppTypography.caption.copyWith(color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final currentIdx = _currentStepIndex;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: kCardDeco(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Status title + live badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusHeadline(order.status),
                      style: AppTypography.title.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      date,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              kStatusPill(statusLabel(order.status), statusBadgeColor),
            ],
          ),

          const SizedBox(height: 24),

          // Stepper: 4 horizontal nodes with animated/tinted connector bars
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepNode(
                stepIndex: 0,
                currentStep: currentIdx,
                label: 'Placed',
                icon: Icons.receipt_long_rounded,
              ),
              _buildConnector(stepIndex: 0, currentStep: currentIdx),
              _buildStepNode(
                stepIndex: 1,
                currentStep: currentIdx,
                label: 'Preparing',
                icon: Icons.handyman_rounded,
              ),
              _buildConnector(stepIndex: 1, currentStep: currentIdx),
              _buildStepNode(
                stepIndex: 2,
                currentStep: currentIdx,
                label: 'Dispatched',
                icon: Icons.delivery_dining_rounded,
              ),
              _buildConnector(stepIndex: 2, currentStep: currentIdx),
              _buildStepNode(
                stepIndex: 3,
                currentStep: currentIdx,
                label: 'Delivered',
                icon: Icons.check_circle_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _statusHeadline(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return 'Order Received';
      case 'confirmed':
        return 'Order Confirmed by Vendor';
      case 'preparing':
        return 'Packing Auto Spares';
      case 'ready':
        return 'Ready for Rider Pickup';
      case 'dispatched':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered Successfully';
      default:
        return 'Order In Progress';
    }
  }

  Widget _buildStepNode({
    required int stepIndex,
    required int currentStep,
    required String label,
    required IconData icon,
  }) {
    final isDone = stepIndex < currentStep;
    final isCurrent = stepIndex == currentStep;

    Color nodeColor;
    Color iconColor;
    if (isDone) {
      nodeColor = kSuccess;
      iconColor = Colors.white;
    } else if (isCurrent) {
      nodeColor = kAccent;
      iconColor = Colors.white;
    } else {
      nodeColor = AppColors.field;
      iconColor = AppColors.textMuted.withValues(alpha: 0.5);
    }

    return SizedBox(
      width: 58,
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: nodeColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrent
                    ? kAccent.withValues(alpha: 0.4)
                    : (isDone ? kSuccess : kBorder),
                width: isCurrent ? 3 : 1,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: kAccent.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Icon(
                isDone ? Icons.check_rounded : icon,
                color: iconColor,
                size: 16,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: (isCurrent || isDone) ? FontWeight.w700 : FontWeight.w500,
              color: isCurrent
                  ? AppColors.textPrimary
                  : (isDone ? AppColors.textSecondary : AppColors.textMuted),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildConnector({required int stepIndex, required int currentStep}) {
    final isPassed = stepIndex < currentStep;
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(top: 15),
        height: 2.5,
        decoration: BoxDecoration(
          color: isPassed ? kSuccess : kBorder,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
