double _toDouble(dynamic val) {
  if (val == null) return 0.0;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? 0.0;
  return 0.0;
}

double? _toOptionalDouble(dynamic val) {
  if (val == null) return null;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val);
  return null;
}

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String role; // 'customer' | 'vendor' | 'rider' | 'admin'
  final String? phone;
  final String? avatarUrl;
  final String? address;

  AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phone,
    this.avatarUrl,
    this.address,
  });

  factory AppUser.fromMap(Map<String, dynamic> m) => AppUser(
        id: m['id'] as String,
        fullName: m['full_name'] as String? ?? '',
        email: m['email'] as String? ?? '',
        role: m['role'] as String? ?? 'customer',
        phone: m['phone'] as String?,
        avatarUrl: m['avatar_url'] as String?,
        address: m['address'] as String?,
      );
}

// ── VendorProfile ─────────────────────────────────────────────────────────────
class VendorProfile {
  final String id;
  final String shopName;
  final String? shopDescription;
  final String? shopLogoUrl;
  final String? shopBannerUrl;
  final String? location;
  final double rating;
  final int totalOrders;
  final bool isVerified;
  final bool isActive;
  final String? fcmToken;

  VendorProfile({
    required this.id,
    required this.shopName,
    this.shopDescription,
    this.shopLogoUrl,
    this.shopBannerUrl,
    this.location,
    this.rating = 0,
    this.totalOrders = 0,
    this.isVerified = false,
    this.isActive = true,
    this.fcmToken,
  });

  factory VendorProfile.fromMap(Map<String, dynamic> m) => VendorProfile(
        id: m['id'] as String,
        shopName: m['shop_name'] as String? ?? '',
        shopDescription: m['shop_description'] as String?,
        shopLogoUrl: m['shop_logo_url'] as String?,
        shopBannerUrl: m['shop_banner_url'] as String?,
        location: m['location'] as String?,
        rating: _toDouble(m['rating']),
        totalOrders: m['total_orders'] as int? ?? 0,
        isVerified: m['is_verified'] as bool? ?? false,
        isActive: m['is_active'] as bool? ?? true,
        fcmToken: m['fcm_token'] as String?,
      );
}

// ── Category ─────────────────────────────────────────────────────────────────
class Category {
  final String id;
  final String name;
  final String? iconName;
  final String? color;

  Category({
    required this.id,
    required this.name,
    this.iconName,
    this.color,
  });

  factory Category.fromMap(Map<String, dynamic> m) => Category(
        id: m['id'] as String,
        name: m['name'] as String,
        iconName: m['icon_name'] as String?,
        color: m['color'] as String?,
      );
}

// ── Product ───────────────────────────────────────────────────────────────────
class Product {
  final String id;
  final String vendorId;
  final String? categoryId;
  final String name;
  final String? description;
  final double price;
  final double? comparePrice;
  int stockQuantity;
  final String unit;
  final List<String> images;
  final String? sku;
  final bool isActive;
  // Joined vendor info (optional)
  final String? vendorShopName;
  final String? vendorLogoUrl;

  Product({
    required this.id,
    required this.vendorId,
    this.categoryId,
    required this.name,
    this.description,
    required this.price,
    this.comparePrice,
    required this.stockQuantity,
    this.unit = 'piece',
    this.images = [],
    this.sku,
    this.isActive = true,
    this.vendorShopName,
    this.vendorLogoUrl,
  });

  factory Product.fromMap(Map<String, dynamic> m) {
    final p = Product(
      id: m['id'] as String,
      vendorId: m['vendor_id'] as String,
      categoryId: m['category_id'] as String?,
      name: m['name'] as String,
      description: m['description'] as String?,
      price: _toDouble(m['price']),
      comparePrice: _toOptionalDouble(m['compare_price']),
      stockQuantity: m['stock_quantity'] as int? ?? 0,
      unit: m['unit'] as String? ?? 'piece',
      images: List<String>.from(m['images'] as List? ?? []),
      sku: m['sku'] as String?,
      isActive: m['is_active'] as bool? ?? true,
      vendorShopName: m['vendor_profiles']?['shop_name'] as String?,
      vendorLogoUrl: m['vendor_profiles']?['shop_logo_url'] as String?,
    );
    if (m['categories'] != null) {
      p.setCategoryName(m['categories']['name'] as String?);
    }
    return p;
  }

  bool get hasDiscount => comparePrice != null && comparePrice! > price;
  double get discountPercent =>
      hasDiscount ? ((comparePrice! - price) / comparePrice! * 100) : 0;
  String get primaryImage => images.isNotEmpty ? images.first : '';

  // Joined from categories table (populated by service when needed)
  String? get categoryName => _categoryName;
  String? _categoryName;
  void setCategoryName(String? name) => _categoryName = name;
}

// ── CartItem ──────────────────────────────────────────────────────────────────
class CartItem {
  final String id;
  final String userId;
  final String productId;
  int quantity;
  final Product? product; // joined

  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    this.product,
  });

  factory CartItem.fromMap(Map<String, dynamic> m) => CartItem(
        id: m['id'] as String,
        userId: m['user_id'] as String,
        productId: m['product_id'] as String,
        quantity: m['quantity'] as int,
        product: m['products'] != null
            ? Product.fromMap(m['products'] as Map<String, dynamic>)
            : null,
      );

  double get subtotal => (product?.price ?? 0) * quantity;
  double get totalPrice => subtotal; // alias for backwards-compat
}

// ── OrderItem ─────────────────────────────────────────────────────────────────
class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final int quantity;
  final double unitPrice;
  final String productName;
  final String? productImage;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.quantity,
    required this.unitPrice,
    required this.productName,
    this.productImage,
  });

  factory OrderItem.fromMap(Map<String, dynamic> m) {
    try {
      return OrderItem(
        id: m['id']?.toString() ?? '',
        orderId: m['order_id']?.toString() ?? '',
        productId: m['product_id']?.toString() ?? '',
        quantity: m['quantity'] as int? ?? 1,
        unitPrice: _toDouble(m['unit_price']),
        productName: m['product_name']?.toString() ?? 'Unknown',
        productImage: m['product_image']?.toString(),
      );
    } catch (e) {
      print('OrderItem.fromMap error: $e | Data: $m');
      rethrow;
    }
  }

  double get total => unitPrice * quantity;
}

// ── Order ──────────────────────────────────────────────────────────────────────
class Order {
  final String id;
  final String customerId;
  final String vendorId;
  String status;
  final double totalAmount;
  final String deliveryAddress;
  final double deliveryFee;
  final String? customerNotes;
  final String? riderId;
  final DateTime createdAt;
  final String? paymentMethod;  // 'COD' | 'Prepaid'
  // Joined data
  final List<OrderItem> items;
  final String? customerName;
  final String? customerPhone;
  final String? vendorShopName;
  final String? vendorLocation;
  final String? vendorPhone;
  final String? riderName;
  final String? riderPhone;

  Order({
    required this.id,
    required this.customerId,
    required this.vendorId,
    required this.status,
    required this.totalAmount,
    required this.deliveryAddress,
    this.deliveryFee = 0,
    this.customerNotes,
    this.riderId,
    required this.createdAt,
    this.paymentMethod,
    this.items = [],
    this.customerName,
    this.customerPhone,
    this.vendorShopName,
    this.vendorLocation,
    this.vendorPhone,
    this.riderName,
    this.riderPhone,
  });

  factory Order.fromMap(Map<String, dynamic> m) {
    final List<OrderItem> parsedItems = m['order_items'] != null
        ? (m['order_items'] as List)
            .map((i) => OrderItem.fromMap(i as Map<String, dynamic>))
            .toList()
        : [];

    final customer = m['customer'] as Map<String, dynamic>?;
    final vendor = m['vendor'] as Map<String, dynamic>?;
    final rider = m['rider'] as Map<String, dynamic>?;

    try {
      return Order(
        id: m['id']?.toString() ?? '',
        customerId: m['customer_id']?.toString() ?? '',
        vendorId: m['vendor_id']?.toString() ?? '',
        status: m['status']?.toString() ?? 'pending',
        totalAmount: _toDouble(m['total_amount']),
        deliveryAddress: m['delivery_address']?.toString() ?? '',
        deliveryFee: _toDouble(m['delivery_fee']),
        customerNotes: m['customer_notes']?.toString(),
        riderId: m['rider_id']?.toString(),
        createdAt: m['created_at'] != null ? DateTime.tryParse(m['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
        paymentMethod: m['payment_method']?.toString(),
        items: parsedItems,
        customerName: customer?['full_name']?.toString(),
        customerPhone: customer?['phone']?.toString(),
        vendorShopName: vendor?['shop_name']?.toString(),
        vendorLocation: vendor?['location']?.toString(),
        vendorPhone: vendor?['phone']?.toString(),
        riderName: rider?['full_name']?.toString(),
        riderPhone: rider?['phone']?.toString(),
      );
    } catch (e) {
      print('Order.fromMap error: $e | Data: $m');
      rethrow;
    }
  }
}

// ── AppNotification ────────────────────────────────────────────────────────────
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final Map<String, dynamic> data;
  bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.data = {},
    this.isRead = false,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: m['id'] as String,
        title: m['title'] as String,
        body: m['body'] as String,
        type: m['type'] as String,
        data: Map<String, dynamic>.from(m['data'] as Map? ?? {}),
        isRead: m['is_read'] as bool? ?? false,
        createdAt: DateTime.parse(m['created_at'] as String),
      );
}
