import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';

/// Fast stock update bottom sheet — optimized for frequent vendor use.
/// Large +/- buttons for quick tapping, plus direct text input.
class StockManagerSheet extends StatefulWidget {
  final Product product;
  const StockManagerSheet({super.key, required this.product});
  @override
  State<StockManagerSheet> createState() => _StockManagerSheetState();
}

class _StockManagerSheetState extends State<StockManagerSheet> {
  late int _stock;
  late final TextEditingController _ctrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _stock = widget.product.stockQuantity;
    _ctrl = TextEditingController(text: '$_stock');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _adjust(int delta) {
    final newVal = (_stock + delta).clamp(0, 9999);
    setState(() {
      _stock = newVal;
      _ctrl.text = '$newVal';
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await MarketplaceService.updateStock(widget.product.id, _stock);
      widget.product.stockQuantity = _stock; // update local model
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to update stock'), backgroundColor: kError, behavior: SnackBarBehavior.floating));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    Color stockColor = kSuccess;
    if (_stock == 0) stockColor = kError;
    else if (_stock <= 5) stockColor = kWarning;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF12121A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),

          // Product name
          Text('Update Stock', style: GoogleFonts.inter(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(widget.product.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),

          const SizedBox(height: 28),

          // ── Big +/- buttons ────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Minus 10
              _BigBtn(label: '-10', color: kError, onTap: () => _adjust(-10)),
              const SizedBox(width: 8),
              // Minus 1
              _BigBtn(label: '-1', color: kError.withValues(alpha: 0.7), onTap: () => _adjust(-1)),
              const SizedBox(width: 16),

              // Stock display (editable)
              GestureDetector(
                onTap: () => _showDirectInput(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 80, height: 72,
                  decoration: BoxDecoration(
                    color: stockColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: stockColor.withValues(alpha: 0.5), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$_stock', style: GoogleFonts.inter(color: stockColor, fontSize: 28, fontWeight: FontWeight.bold)),
                      Text('units', style: GoogleFonts.inter(color: stockColor.withValues(alpha: 0.6), fontSize: 10)),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 16),
              // Plus 1
              _BigBtn(label: '+1', color: kSuccess.withValues(alpha: 0.7), onTap: () => _adjust(1)),
              const SizedBox(width: 8),
              // Plus 10
              _BigBtn(label: '+10', color: kSuccess, onTap: () => _adjust(10)),
            ],
          ),

          const SizedBox(height: 8),
          Text('Tap the number to type directly', style: GoogleFonts.inter(color: Colors.white24, fontSize: 11)),

          const SizedBox(height: 28),

          // ── Save Button ────────────────────────────────────────────────
          SizedBox(
            width: double.infinity, height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: kVendor, foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _saving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                  : Text('Save Stock  →  $_stock units', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showDirectInput() async {
    _ctrl.text = '$_stock';
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Enter Stock', style: GoogleFonts.inter(color: Colors.white)),
        content: TextField(
          controller: _ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          style: GoogleFonts.inter(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            filled: true, fillColor: kCard,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kBorder)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: kVendor, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white38))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: kVendor, foregroundColor: Colors.black),
            onPressed: () {
              final val = int.tryParse(_ctrl.text) ?? _stock;
              setState(() => _stock = val.clamp(0, 9999));
              Navigator.pop(context);
            },
            child: Text('OK', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// ── Big +/- button ─────────────────────────────────────────────────────────────
class _BigBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BigBtn({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 52, height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Center(child: Text(label, style: GoogleFonts.inter(color: color, fontSize: 15, fontWeight: FontWeight.bold))),
    ),
  );
}
