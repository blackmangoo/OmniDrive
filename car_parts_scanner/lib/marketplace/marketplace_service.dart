import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'marketplace_models.dart';

/// Single source of truth for all Supabase calls in the Marketplace module.
class MarketplaceService {
  static final _sb = Supabase.instance.client;
  static final String _bucket = 'product-images';
  static RealtimeChannel? _notifChannel;

  // ── Current user helpers ───────────────────────────────────────────────────
  static String get currentUserId => _sb.auth.currentUser!.id;

  static Future<AppUser?> fetchCurrentUser() async {
    try {
      final data = await _sb
          .from('user_profiles')
          .select()
          .eq('id', currentUserId)
          .single();
      return AppUser.fromMap(data);
    } catch (e) {
      debugPrint('fetchCurrentUser error: $e');
      return null;
    }
  }

  static Future<String> getUserRole() async {
    try {
      final user = _sb.auth.currentUser;
      if (user == null) return 'customer';

      final meta = user.userMetadata ?? {};
      final metadataRole = meta['role'] as String?;

      // Primary source: DB (populated by trigger on signup)
      String? dbRole;
      try {
        final data = await _sb
            .from('user_profiles')
            .select('role')
            .eq('id', currentUserId)
            .maybeSingle();
        dbRole = data?['role'] as String?;
      } catch (_) {}

      // If DB has the role, trust it
      if (dbRole != null) return dbRole;

      // Fallback: use metadata role and create the missing profile
      final finalRole = metadataRole ?? 'customer';
      try {
        await _sb.from('user_profiles').upsert({
          'id': currentUserId,
          'role': finalRole,
          'full_name': meta['full_name'] ?? 'User',
          'phone': meta['phone'],
        });
      } catch (e) {
        debugPrint('getUserRole upsert fallback error: $e');
      }

      // Also create vendor_profiles if vendor
      if (finalRole == 'vendor') {
        try {
          await _sb.from('vendor_profiles').upsert({
            'id': currentUserId,
            'shop_name': meta['shop_name'] ?? 'My Shop',
            'location': meta['location'] ?? '',
            'phone': meta['phone'] ?? '',
          });
        } catch (e) {
          debugPrint('vendor_profiles upsert fallback error: $e');
        }
      }

      return finalRole;
    } catch (e) {
      debugPrint('getUserRole error: $e');
      return 'customer';
    }
  }

  // ── FCM Token ───────────────────────────────────────────────────────────────
  static Future<void> saveFcmToken(String token) async {
    try {
      // Save on user_profiles for all roles
      await _sb
          .from('user_profiles')
          .update({'fcm_token': token}).eq('id', currentUserId);

      final role = await getUserRole();
      if (role == 'vendor') {
        await _sb
            .from('vendor_profiles')
            .update({'fcm_token': token}).eq('id', currentUserId);
      }
    } catch (e) {
      debugPrint('saveFcmToken error: $e');
    }
  }

  // ── Realtime Notification Listener ─────────────────────────────────────────
  static void startNotificationListener(void Function(AppNotification) onNotificationReceived) {
    stopNotificationListener();
    try {
      _notifChannel = _sb
          .channel('public:notifications:user:$currentUserId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: currentUserId,
            ),
            callback: (payload) {
              try {
                final notif = AppNotification.fromMap(payload.newRecord);
                onNotificationReceived(notif);
              } catch (e) {
                debugPrint('Error parsing realtime notification: $e');
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint('Error starting notification listener: $e');
    }
  }

  static void stopNotificationListener() {
    if (_notifChannel != null) {
      try {
        _sb.removeChannel(_notifChannel!);
      } catch (_) {}
      _notifChannel = null;
    }
  }

  // ── Vendor Profile ─────────────────────────────────────────────────────────
  static Future<VendorProfile?> fetchVendorProfile([String? vendorId]) async {
    try {
      final id = vendorId ?? currentUserId;
      final data = await _sb
          .from('vendor_profiles')
          .select()
          .eq('id', id)
          .single();
      return VendorProfile.fromMap(data);
    } catch (e) {
      debugPrint('fetchVendorProfile error: $e');
      return null;
    }
  }

  static Future<void> createVendorProfile({
    required String shopName,
    String? shopDescription,
    String? location,
    String? phone,
  }) async {
    await _sb.from('vendor_profiles').upsert({
      'id': currentUserId,
      'shop_name': shopName,
      'shop_description': shopDescription,
      'location': location,
    });
    if (phone != null) {
      await _sb
          .from('user_profiles')
          .update({'phone': phone, 'role': 'vendor'}).eq('id', currentUserId);
    }
  }

  static Future<void> updateVendorProfile(Map<String, dynamic> data) async {
    await _sb.from('vendor_profiles').update(data).eq('id', currentUserId);
  }

  // ── Categories ─────────────────────────────────────────────────────────────
  static Future<List<Category>> fetchCategories() async {
    try {
      final data = await _sb.from('categories').select().order('name');
      return (data as List).map((m) => Category.fromMap(m)).toList();
    } catch (e) {
      debugPrint('fetchCategories error: $e');
      return [];
    }
  }

  // ── Products (Public) ──────────────────────────────────────────────────────
  static Future<List<Product>> fetchProducts({
    String? categoryId,
    String? vendorId,
    String? searchQuery,
    bool activeOnly = true,
  }) async {
    try {
      var query = _sb.from('products').select(
            '*, vendor_profiles(shop_name, shop_logo_url), categories(name)',
          );
      if (activeOnly) query = query.eq('is_active', true);
      if (categoryId != null) query = query.eq('category_id', categoryId);
      if (vendorId != null) query = query.eq('vendor_id', vendorId);
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('name', '%$searchQuery%');
      }
      final data = await query.order('created_at', ascending: false);
      return (data as List).map((m) => Product.fromMap(m)).toList();
    } catch (e) {
      debugPrint('fetchProducts error: $e');
      return [];
    }
  }

  static Future<Product?> fetchProduct(String productId) async {
    try {
      final data = await _sb
          .from('products')
          .select('*, vendor_profiles(shop_name, shop_logo_url), categories(name)')
          .eq('id', productId)
          .single();
      return Product.fromMap(data);
    } catch (e) {
      return null;
    }
  }

  // ── Products (Vendor CRUD) ─────────────────────────────────────────────────
  static Future<String?> uploadProductImage(File file) async {
    try {
      final ext = file.path.split('.').last;
      final path = '$currentUserId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      
      Uint8List? compressedBytes;
      try {
        // Compress the image before uploading to save bandwidth & storage
        compressedBytes = await FlutterImageCompress.compressWithFile(
          file.absolute.path,
          quality: 70,
          minWidth: 1024,
          minHeight: 1024,
        );
      } catch (compressError) {
        debugPrint('[Resilient Upload] FlutterImageCompress error, falling back to original: $compressError');
      }

      if (compressedBytes != null) {
        await _sb.storage.from(_bucket).uploadBinary(path, compressedBytes);
      } else {
        await _sb.storage.from(_bucket).upload(path, file);
      }

      final url = _sb.storage.from(_bucket).getPublicUrl(path);
      return url;
    } catch (e) {
      debugPrint('uploadProductImage error: $e');
      return null;
    }
  }

  static Future<void> createProduct(Map<String, dynamic> data) async {
    await _sb.from('products').insert({...data, 'vendor_id': currentUserId});
  }

  static Future<void> updateProduct(String productId, Map<String, dynamic> data) async {
    await _sb.from('products').update(data).eq('id', productId);
  }

  static Future<void> updateStock(String productId, int newStock) async {
    await _sb
        .from('products')
        .update({'stock_quantity': newStock}).eq('id', productId);
  }

  /// Alias used by new Stitch-based vendor screens.
  static Future<void> updateProductStock(String productId, int newStock) =>
      updateStock(productId, newStock);

  /// Fetch products belonging to the currently logged-in vendor.
  static Future<List<Product>> fetchVendorProducts({String? search}) async {
    try {
      var query = _sb
          .from('products')
          .select('*, vendor_profiles(shop_name, shop_logo_url), categories(name)')
          .eq('vendor_id', currentUserId);
      if (search != null && search.isNotEmpty) {
        query = query.ilike('name', '%$search%');
      }
      final data = await query.order('created_at', ascending: false);
      return (data as List).map((m) => Product.fromMap(m)).toList();
    } catch (e) {
      debugPrint('fetchVendorProducts error: $e');
      return [];
    }
  }

  /// Fetch aggregated stats for the vendor dashboard.
  static Future<Map<String, dynamic>> fetchVendorStats() async {
    try {
      final results = await Future.wait([
        fetchVendorProfile(),
        fetchVendorOrders(),
      ]);
      final profile = results[0] as VendorProfile?;
      final orders = results[1] as List<Order>;

      final double revenue = orders
          .where((o) => o.status == 'delivered')
          .fold(0.0, (s, o) => s + o.totalAmount);
      return {
        'shop_name': profile?.shopName ?? '',
        'total_revenue': revenue,
        'total_orders': orders.length,
        'is_verified': profile?.isVerified ?? false,
      };
    } catch (e) {
      debugPrint('fetchVendorStats error: $e');
      return {'shop_name': '', 'total_revenue': 0.0, 'total_orders': 0};
    }
  }

  static Future<void> deleteProduct(String productId) async {
    await _sb.from('products').delete().eq('id', productId);
  }

  // ── Cart ───────────────────────────────────────────────────────────────────
  static Future<List<CartItem>> fetchCart() async {
    try {
      final data = await _sb
          .from('cart_items')
          .select('*, products(*, vendor_profiles(shop_name), categories(name))')
          .eq('user_id', currentUserId);
      return (data as List).map((m) => CartItem.fromMap(m)).toList();
    } catch (e) {
      debugPrint('fetchCart error: $e');
      return [];
    }
  }

  static Future<int> getCartCount() async {
    try {
      final data = await _sb
          .from('cart_items')
          .select('id')
          .eq('user_id', currentUserId);
      return (data as List).length;
    } catch (e) {
      return 0;
    }
  }

  static Future<void> addToCart(String productId, {int quantity = 1}) async {
    await _sb.from('cart_items').upsert({
      'user_id': currentUserId,
      'product_id': productId,
      'quantity': quantity,
    }, onConflict: 'user_id,product_id');
  }

  static Future<void> updateCartQuantity(String cartItemId, int quantity) async {
    if (quantity <= 0) {
      await _sb.from('cart_items').delete().eq('id', cartItemId);
    } else {
      await _sb
          .from('cart_items')
          .update({'quantity': quantity}).eq('id', cartItemId);
    }
  }

  static Future<void> removeFromCart(String cartItemId) async {
    await _sb.from('cart_items').delete().eq('id', cartItemId);
  }

  static Future<void> clearCart() async {
    await _sb.from('cart_items').delete().eq('user_id', currentUserId);
  }

  // ── Orders ─────────────────────────────────────────────────────────────────
  static Future<Order?> placeOrder({
    required String vendorId,
    required List<CartItem> items,
    required String deliveryAddress,
    double deliveryFee = 50,
    String? notes,
    String paymentMethod = 'COD',
  }) async {
    try {
      final double totalAmount = items.fold(0.0, (s, i) => s + i.subtotal) + deliveryFee;

      // 1. Create the order
      final orderData = await _sb.from('orders').insert({
        'customer_id': currentUserId,
        'vendor_id': vendorId,
        'total_amount': totalAmount,
        'delivery_address': deliveryAddress,
        'delivery_fee': deliveryFee,
        'customer_notes': notes,
        'payment_method': paymentMethod,
        'status': 'pending',
      }).select().single();

      final orderId = orderData['id'] as String;

      final orderItemsData = items.map((ci) => {
            'order_id': orderId,
            'product_id': ci.productId,
            'quantity': ci.quantity,
            'unit_price': ci.product?.price ?? 0,
            'product_name': ci.product?.name ?? '',
            'product_image': ci.product?.primaryImage,
          }).toList();
      final insertedItems = await _sb.from('order_items').insert(orderItemsData).select();

      // 3. Decrement stock for each product using atomic RPC
      for (final ci in items) {
        final success = await _sb.rpc('decrement_stock', params: {
          'p_product_id': ci.productId,
          'p_quantity': ci.quantity,
        });
        if (success != true) {
          throw Exception('Insufficient stock for item: ${ci.product?.name}');
        }
      }

      // 4 & 5. Clear cart and notify vendor concurrently
      await Future.wait([
        clearCart(),
        _sb.from('notifications').insert({
          'user_id': vendorId,
          'title': '🛒 New Order!',
          'body': 'You have a new order of ${items.length} item(s).',
          'type': 'new_order',
          'data': {'order_id': orderId},
        }),
      ]);

      return Order.fromMap({...orderData, 'order_items': insertedItems});
    } catch (e, st) {
      debugPrint('placeOrder error: $e\n$st');
      throw Exception('$e\n$st');
    }
  }

  /// Simplified checkout: fetches cart, picks first vendor, places order.
  /// Used by the new CartScreen which delegates address & payment selection here.
  static Future<void> placeOrderFromCart({
    required String paymentMethod,
    required String deliveryAddress,
    double deliveryFee = 199,
    String? notes,
  }) async {
    final cartItems = await fetchCart();
    if (cartItems.isEmpty) return;
    // Group by vendor and place one order per vendor
    final vendorIds = cartItems.map((i) => i.product?.vendorId ?? '').toSet();
    for (final vid in vendorIds) {
      if (vid.isEmpty) continue;
      final vendorItems = cartItems
          .where((i) => (i.product?.vendorId ?? '') == vid)
          .toList();
      await placeOrder(
        vendorId: vid,
        items: vendorItems,
        deliveryAddress: deliveryAddress,
        deliveryFee: deliveryFee,
        notes: notes,
        paymentMethod: paymentMethod,
      );
    }
  }


  /// Fetch orders for the logged-in CUSTOMER
  static Future<List<Order>> fetchCustomerOrders() async {
    try {
      final data = await _sb.from('orders').select(
            'id, customer_id, vendor_id, status, total_amount, delivery_address, delivery_fee, customer_notes, rider_id, created_at, payment_method, order_items(*), customer:user_profiles!orders_customer_id_fkey(full_name, phone), vendor:vendor_profiles!orders_vendor_id_fkey(shop_name, location, phone), rider:user_profiles!orders_rider_id_fkey(full_name, phone)',
          ).eq('customer_id', currentUserId).order('created_at', ascending: false);
      return (data as List).map((m) => Order.fromMap(Map<String, dynamic>.from(m))).toList();
    } catch (e) {
      debugPrint('fetchCustomerOrders error: $e');
      return [];
    }
  }

  /// Fetch orders for the logged-in VENDOR
  static Future<List<Order>> fetchVendorOrders({String? status}) async {
    try {
      var query = _sb.from('orders').select(
            'id, customer_id, vendor_id, status, total_amount, delivery_address, delivery_fee, customer_notes, rider_id, created_at, payment_method, order_items(*), customer:user_profiles!orders_customer_id_fkey(full_name, phone), vendor:vendor_profiles!orders_vendor_id_fkey(shop_name, location, phone), rider:user_profiles!orders_rider_id_fkey(full_name, phone)',
          ).eq('vendor_id', currentUserId);
      if (status != null) query = query.eq('status', status);
      final data = await query.order('created_at', ascending: false);
      return (data as List).map((m) => Order.fromMap(Map<String, dynamic>.from(m))).toList();
    } catch (e) {
      debugPrint('fetchVendorOrders error: $e');
      return [];
    }
  }

  /// Fetch orders assigned to logged-in RIDER
  static Future<List<Order>> fetchRiderOrders() async {
    try {
      final data = await _sb.from('orders').select(
            'id, customer_id, vendor_id, status, total_amount, delivery_address, delivery_fee, customer_notes, rider_id, created_at, payment_method, order_items(*), customer:user_profiles!orders_customer_id_fkey(full_name, phone, address), vendor:vendor_profiles!orders_vendor_id_fkey(shop_name, location, phone), rider:user_profiles!orders_rider_id_fkey(full_name, phone)',
          ).eq('rider_id', currentUserId).order('created_at', ascending: false);
      return (data as List).map((m) => Order.fromMap(Map<String, dynamic>.from(m))).toList();
    } catch (e) {
      debugPrint('fetchRiderOrders error: $e');
      return [];
    }
  }

  static Future<void> updateOrderStatus(String orderId, String status) async {
    await _sb.from('orders').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);

    // If order is marked as ready, automatically notify all registered riders
    if (status == 'ready') {
      try {
        final riders = await fetchRiders();
        final notifs = riders.map((r) => {
          'user_id': r.id,
          'title': '📦 New Delivery Available!',
          'body': 'An order is ready for pickup. Accept it now!',
          'type': 'delivery_available',
          'data': {'order_id': orderId},
        }).toList();
        if (notifs.isNotEmpty) {
          await _sb.from('notifications').insert(notifs);
        }
      } catch (e) {
        debugPrint('[Notification] Error notifying riders of ready order: $e');
      }
    }
  }

  /// Fetch all unassigned orders that are ready for delivery (status = 'ready' and rider_id is null)
  static Future<List<Order>> fetchAvailableOrders() async {
    try {
      final data = await _sb.from('orders').select(
            'id, customer_id, vendor_id, status, total_amount, delivery_address, delivery_fee, customer_notes, rider_id, created_at, payment_method, order_items(*), customer:user_profiles!orders_customer_id_fkey(full_name, phone, address), vendor:vendor_profiles!orders_vendor_id_fkey(shop_name, location, phone)',
          )
          .eq('status', 'ready')
          .isFilter('rider_id', null)
          .order('created_at', ascending: false);
      return (data as List).map((m) => Order.fromMap(Map<String, dynamic>.from(m))).toList();
    } catch (e) {
      debugPrint('fetchAvailableOrders error: $e');
      return [];
    }
  }

  /// Let a rider accept/claim an available ready order
  static Future<void> claimOrder(String orderId) async {
    await _sb.from('orders').update({
      'rider_id': currentUserId,
      'status': 'dispatched',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);

    try {
      final order = await _sb.from('orders').select('customer_id, vendor_id').eq('id', orderId).single();
      final customerId = order['customer_id'] as String;
      final vendorId = order['vendor_id'] as String;

      await Future.wait([
        _sb.from('notifications').insert({
          'user_id': customerId,
          'title': '🏍️ Order Dispatched!',
          'body': 'A rider has accepted your order and is on the way.',
          'type': 'order_dispatched',
          'data': {'order_id': orderId},
        }),
        _sb.from('notifications').insert({
          'user_id': vendorId,
          'title': '🏍️ Rider Assigned!',
          'body': 'A rider has accepted and is picking up the order.',
          'type': 'rider_accepted',
          'data': {'order_id': orderId},
        }),
      ]);
    } catch (e) {
      debugPrint('claimOrder notify error: $e');
    }
  }

  static Future<void> assignRider(String orderId, String riderId) async {
    await _sb.from('orders').update({
      'rider_id': riderId,
      'status': 'dispatched',
    }).eq('id', orderId);

    // Notify the rider
    await _sb.from('notifications').insert({
      'user_id': riderId,
      'title': '🏍️ New Delivery!',
      'body': 'You have been assigned a delivery.',
      'type': 'delivery_assigned',
      'data': {'order_id': orderId},
    });
  }

  // ── Notifications ──────────────────────────────────────────────────────────
  static Future<List<AppNotification>> fetchNotifications() async {
    try {
      final data = await _sb
          .from('notifications')
          .select()
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false)
          .limit(50);
      return (data as List).map((m) => AppNotification.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<void> markNotificationRead(String notifId) async {
    await _sb.from('notifications').update({'is_read': true}).eq('id', notifId);
  }

  // ── Admin helpers ──────────────────────────────────────────────────────────
  static Future<List<AppUser>> fetchRiders() async {
    try {
      final data = await _sb
          .from('user_profiles')
          .select()
          .eq('role', 'rider');
      return (data as List).map((m) => AppUser.fromMap(m)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Order>> fetchAllOrders() async {
    try {
      final data = await _sb.from('orders').select(
            'id, customer_id, vendor_id, status, total_amount, delivery_address, delivery_fee, customer_notes, rider_id, created_at, payment_method, order_items(*), customer:user_profiles!orders_customer_id_fkey(full_name, phone), vendor:vendor_profiles!orders_vendor_id_fkey(shop_name, location, phone), rider:user_profiles!orders_rider_id_fkey(full_name, phone)',
          ).order('created_at', ascending: false);
      return (data as List).map((m) => Order.fromMap(Map<String, dynamic>.from(m))).toList();
    } catch (e) {
      debugPrint('fetchAllOrders error: $e');
      return [];
    }
  }

  static Future<bool> isUserApproved() async {
    try {
      final user = _sb.auth.currentUser;
      if (user == null) return false;
      final data = await _sb
          .from('user_profiles')
          .select('is_approved')
          .eq('id', user.id)
          .maybeSingle();
      if (data == null) return false;
      return data['is_approved'] as bool? ?? false;
    } catch (e) {
      debugPrint('isUserApproved error: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchPendingApprovals() async {
    try {
      final data = await _sb.rpc('get_pending_approvals');
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint('fetchPendingApprovals error: $e');
      return [];
    }
  }

  static Future<void> approveUser(String id, String role) async {
    try {
      await _sb.rpc('approve_user', params: {
        'p_user_id': id,
        'p_role': role,
      });
    } catch (e) {
      debugPrint('approveUser error: $e');
      rethrow;
    }
  }

  static Future<void> rejectUser(String id) async {
    try {
      await _sb.rpc('reject_user', params: {
        'p_user_id': id,
      });
    } catch (e) {
      debugPrint('rejectUser error: $e');
      rethrow;
    }
  }

  // ── Realtime ───────────────────────────────────────────────────────────────
  /// Stream of vendor's live orders (for vendor bell icon)
  static RealtimeChannel vendorOrdersStream(void Function(dynamic) onInsert) {
    return _sb
        .channel('vendor_orders')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'vendor_id',
            value: currentUserId,
          ),
          callback: (payload) => onInsert(payload),
        )
        .subscribe();
  }
}
