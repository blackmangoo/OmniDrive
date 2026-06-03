import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../marketplace_constants.dart';
import '../marketplace_models.dart';
import '../marketplace_service.dart';
import '../../core/motion/motion_tappable.dart';

class AddEditProductScreen extends StatefulWidget {
  final Product? product; // null = add new
  const AddEditProductScreen({super.key, this.product});
  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey    = GlobalKey<FormState>();
  final _nameCtrl   = TextEditingController();
  final _priceCtrl  = TextEditingController();
  final _cmpCtrl    = TextEditingController();
  final _stockCtrl  = TextEditingController();
  final _descCtrl   = TextEditingController();
  final _skuCtrl    = TextEditingController();
  bool _loading = false;
  bool _isActive = true;
  List<String> _existingImages = [];
  final List<File> _newImages = [];
  List<Category> _categories = [];
  String? _selectedCategoryId;

  bool get isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (isEditing) {
      final p = widget.product!;
      _nameCtrl.text  = p.name;
      _priceCtrl.text = p.price.toStringAsFixed(0);
      _cmpCtrl.text   = p.comparePrice?.toStringAsFixed(0) ?? '';
      _stockCtrl.text = '${p.stockQuantity}';
      _descCtrl.text  = p.description ?? '';
      _skuCtrl.text   = p.sku ?? '';
      _isActive       = p.isActive;
      _existingImages = List.from(p.images);
      _selectedCategoryId = p.categoryId;
    }
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _priceCtrl, _cmpCtrl, _stockCtrl, _descCtrl, _skuCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final cats = await MarketplaceService.fetchCategories();
    if (mounted) setState(() => _categories = List<Category>.from(cats));
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage();
    setState(() => _newImages.addAll(picked.map((f) => File(f.path))));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loading = true);

    try {
      final List<String> uploadedUrls = [];
      for (final file in _newImages) {
        final url = await MarketplaceService.uploadProductImage(file);
        if (url != null) uploadedUrls.add(url);
      }

      final allImages = [..._existingImages, ...uploadedUrls];

      final data = {
        'name':           _nameCtrl.text.trim(),
        'price':          double.tryParse(_priceCtrl.text) ?? 0,
        'compare_price':  _cmpCtrl.text.isEmpty ? null : double.tryParse(_cmpCtrl.text),
        'stock_quantity': int.tryParse(_stockCtrl.text) ?? 0,
        'description':    _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        'sku':            _skuCtrl.text.trim().isEmpty ? null : _skuCtrl.text.trim(),
        'is_active':      _isActive,
        'category_id':    _selectedCategoryId,
        'images':         allImages,
      };

      if (isEditing) {
        await MarketplaceService.updateProduct(widget.product!.id, data);
      } else {
        await MarketplaceService.createProduct(data);
      }

      nav.pop();
      messenger.showSnackBar(SnackBar(
        content: Text(isEditing ? 'Product updated!' : 'Product added!',
            style: GoogleFonts.inter()),
        backgroundColor: kSuccess, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    } catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text('Failed: $e'), backgroundColor: kError, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kBg, elevation: 0,
        leading: TappableScale(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70, size: 20),
        ),
        title: Text(isEditing ? 'Edit Product' : 'Add Product',
            style: GoogleFonts.inter(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          if (isEditing)
            TappableScale(
              onTap: () async {
                final nav = Navigator.of(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: kSurface,
                    title: Text('Delete Product?', style: GoogleFonts.inter(color: Colors.white)),
                    content: Text('This cannot be undone.', style: GoogleFonts.inter(color: Colors.white54)),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: GoogleFonts.inter(color: Colors.white38))),
                      ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: kError), child: const Text('Delete')),
                    ],
                  ),
                );
                if (confirm == true) {
                  await MarketplaceService.deleteProduct(widget.product!.id);
                  nav.pop();
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Icon(Icons.delete_outline_rounded, color: kError),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Images ─────────────────────────────────────────────
                    _sectionHeader('Product Images'),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 100,
                      child: ListView(scrollDirection: Axis.horizontal, children: [
                        // Existing images
                        ..._existingImages.map((url) => Stack(
                          children: [
                            Container(
                              width: 100, height: 100, margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: kBorder)),
                              child: ClipRRect(borderRadius: BorderRadius.circular(12),
                                  child: CachedNetworkImage(imageUrl: url, fit: BoxFit.cover, errorWidget: (_, _, _) => const Icon(Icons.broken_image, color: Colors.white24))),
                            ),
                            Positioned(top: 4, right: 12, child: TappableScale(
                              onTap: () => setState(() => _existingImages.remove(url)),
                              child: Container(width: 22, height: 22, decoration: const BoxDecoration(color: kError, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14)),
                            )),
                          ],
                        )),
                        // New images
                        ..._newImages.map((file) => Stack(
                          children: [
                            Container(
                              width: 100, height: 100, margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: kVendor.withValues(alpha: 0.5))),
                              child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(file, fit: BoxFit.cover)),
                            ),
                            Positioned(top: 4, right: 12, child: TappableScale(
                              onTap: () => setState(() => _newImages.remove(file)),
                              child: Container(width: 22, height: 22, decoration: const BoxDecoration(color: kError, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 14)),
                            )),
                          ],
                        )),
                        // Add button
                        TappableScale(
                          onTap: _pickImages,
                          child: Container(
                            width: 100, height: 100,
                            decoration: BoxDecoration(
                              color: kVendor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: kVendor.withValues(alpha: 0.4), style: BorderStyle.solid),
                            ),
                            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                              const Icon(Icons.add_photo_alternate_outlined, color: kVendor, size: 28),
                              const SizedBox(height: 4),
                              Text('Add', style: GoogleFonts.inter(color: kVendor, fontSize: 11)),
                            ]),
                          ),
                        ),
                      ]),
                    ),

                    const SizedBox(height: 24),

                    // ── Basic Info ─────────────────────────────────────────
                    _sectionHeader('Product Information'),
                    const SizedBox(height: 12),
                    _field(_nameCtrl, 'Product Name', hint: 'e.g. Front Brake Pad Set',
                        validator: (v) => v!.trim().isEmpty ? 'Required' : null),
                    const SizedBox(height: 14),
                    _field(_descCtrl, 'Description (Optional)', hint: 'Describe the product...', maxLines: 3),
                    const SizedBox(height: 14),
                    // Category dropdown
                    if (_categories.isNotEmpty) ...[
                      Text('Category', style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategoryId,
                        dropdownColor: kSurface,
                        style: GoogleFonts.inter(color: Colors.white),
                        decoration: InputDecoration(
                          filled: true, fillColor: kSurface,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kVendor, width: 1.5)),
                        ),
                        hint: Text('Select category', style: GoogleFonts.inter(color: Colors.white24)),
                        items: _categories.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList(),
                        onChanged: (v) => setState(() => _selectedCategoryId = v),
                      ),
                      const SizedBox(height: 14),
                    ],
                    _field(_skuCtrl, 'SKU / Part Number (Optional)', hint: 'e.g. BRK-001'),

                    const SizedBox(height: 24),

                    // ── Pricing & Stock ────────────────────────────────────
                    _sectionHeader('Pricing & Stock'),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: _field(_priceCtrl, 'Selling Price (Rs)', hint: '0', keyboardType: TextInputType.number,
                          validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null)),
                      const SizedBox(width: 12),
                      Expanded(child: _field(_cmpCtrl, 'Original Price (Opt)', hint: '0', keyboardType: TextInputType.number)),
                    ]),
                    const SizedBox(height: 14),
                    _field(_stockCtrl, 'Stock Quantity', hint: '0', keyboardType: TextInputType.number,
                        validator: (v) => int.tryParse(v ?? '') == null ? 'Invalid' : null),

                    const SizedBox(height: 20),

                    // ── Active toggle ──────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: kCardDeco(),
                      child: Row(children: [
                        const Icon(Icons.visibility_rounded, color: Colors.white54, size: 20),
                        const SizedBox(width: 12),
                        Expanded(child: Text('Product is Active', style: GoogleFonts.inter(color: Colors.white, fontSize: 14))),
                        Switch(value: _isActive, activeThumbColor: kVendor, activeTrackColor: kVendor.withValues(alpha: 0.3), onChanged: (v) => setState(() => _isActive = v)),
                      ]),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // ── Save Button ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(color: kSurface, border: Border(top: BorderSide(color: kBorder))),
              child: SizedBox(
                width: double.infinity, height: 52,
                child: TappableScale(
                  onTap: _loading ? null : _save,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: kVendorGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: _loading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2.5))
                        : Text(isEditing ? 'Save Changes' : 'Add to Catalogue',
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {
    String? hint, int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator,
  }) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
    const SizedBox(height: 8),
    TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint, hintStyle: GoogleFonts.inter(color: Colors.white24),
        filled: true, fillColor: kSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kBorder)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kVendor, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kError)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: kError)),
      ),
    ),
  ]);

  Widget _sectionHeader(String t) => Row(children: [
    Container(width: 3, height: 18, decoration: BoxDecoration(color: kVendor, borderRadius: BorderRadius.circular(2))),
    const SizedBox(width: 10),
    Text(t, style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
  ]);
}
