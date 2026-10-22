class StoreCategory {
  const StoreCategory({
    required this.id,
    required this.name,
    required this.gender,
    this.description,
  });

  final String id;
  final String name;
  final String gender;
  final String? description;

  factory StoreCategory.fromJson(Map<String, dynamic> json) => StoreCategory(
    id: json['id'] as String,
    name: json['name'] as String,
    gender: json['gender'] as String? ?? 'Unisex',
    description: json['description'] as String?,
  );
}

class StoreVariant {
  const StoreVariant({
    required this.id,
    required this.sku,
    required this.size,
    required this.color,
    required this.stockQuantity,
  });

  final String id;
  final String sku;
  final String size;
  final String color;
  final int stockQuantity;

  factory StoreVariant.fromJson(Map<String, dynamic> json) => StoreVariant(
    id: json['id'] as String,
    sku: json['sku'] as String,
    size: json['size'] as String,
    color: json['color'] as String,
    stockQuantity: json['stockQuantity'] as int,
  );
}

class StoreProduct {
  const StoreProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.currentPrice,
    required this.isOnSale,
    required this.currencyCode,
    required this.imageUrl,
    required this.categoryId,
    required this.variants,
  });

  final String id;
  final String name;
  final String? description;
  final double price;
  final double currentPrice;
  final bool isOnSale;
  final String currencyCode;
  final String? imageUrl;
  final String categoryId;
  final List<StoreVariant> variants;

  int? get discountPercent =>
      isOnSale ? ((1 - currentPrice / price) * 100).round() : null;

  factory StoreProduct.fromJson(Map<String, dynamic> json) => StoreProduct(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    price: (json['price'] as num).toDouble(),
    currentPrice: (json['currentPrice'] as num).toDouble(),
    isOnSale:
        json['isOnSale'] as bool? ??
        (json['currentPrice'] as num) < (json['price'] as num),
    currencyCode: json['currencyCode'] as String? ?? 'EUR',
    imageUrl: json['imageUrl'] as String?,
    categoryId: json['categoryId'] as String,
    variants: (json['variants'] as List<dynamic>? ?? const [])
        .map(
          (variant) => StoreVariant.fromJson(variant as Map<String, dynamic>),
        )
        .toList(growable: false),
  );
}

class StoreProductPage {
  const StoreProductPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalCount,
  });

  final List<StoreProduct> items;
  final int page;
  final int totalPages;
  final int totalCount;

  factory StoreProductPage.fromJson(Map<String, dynamic> json) =>
      StoreProductPage(
        items: (json['items'] as List<dynamic>)
            .map((item) => StoreProduct.fromJson(item as Map<String, dynamic>))
            .toList(growable: false),
        page: json['page'] as int,
        totalPages: json['totalPages'] as int,
        totalCount: json['totalCount'] as int,
      );
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.email,
    required this.displayName,
    required this.roles,
  });

  final String accessToken;
  final String email;
  final String displayName;
  final List<String> roles;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['accessToken'] as String,
    email: json['email'] as String,
    displayName: json['displayName'] as String,
    roles: (json['roles'] as List<dynamic>).cast<String>(),
  );
}

class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.productVariantId,
    required this.sku,
    required this.size,
    required this.color,
    required this.quantity,
    required this.stockQuantity,
    required this.unitPrice,
    required this.lineTotal,
    required this.currencyCode,
    required this.imageUrl,
  });

  final String id;
  final String productId;
  final String productName;
  final String productVariantId;
  final String sku;
  final String size;
  final String color;
  final int quantity;
  final int stockQuantity;
  final double unitPrice;
  final double lineTotal;
  final String currencyCode;
  final String? imageUrl;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    id: json['id'] as String,
    productId: json['productId'] as String,
    productName: json['productName'] as String,
    productVariantId: json['productVariantId'] as String,
    sku: json['sku'] as String,
    size: json['size'] as String,
    color: json['color'] as String,
    quantity: json['quantity'] as int,
    stockQuantity: json['stockQuantity'] as int,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    lineTotal: (json['lineTotal'] as num).toDouble(),
    currencyCode: json['currencyCode'] as String,
    imageUrl: json['imageUrl'] as String?,
  );
}

class Cart {
  const Cart({required this.id, required this.items});

  final String? id;
  final List<CartItem> items;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => items.fold(0, (sum, item) => sum + item.lineTotal);
  String get currencyCode => items.firstOrNull?.currencyCode ?? 'EUR';

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
    id: json['id'] as String?,
    items: (json['items'] as List<dynamic>)
        .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );
}

class FavoriteProduct {
  const FavoriteProduct({
    required this.productId,
    required this.name,
    required this.price,
    required this.salePrice,
    required this.currentPrice,
    required this.isOnSale,
    required this.currencyCode,
    required this.imageUrl,
    required this.categoryId,
  });

  final String productId;
  final String name;
  final double price;
  final double? salePrice;
  final double currentPrice;
  final bool isOnSale;
  final String currencyCode;
  final String? imageUrl;
  final String categoryId;

  factory FavoriteProduct.fromJson(Map<String, dynamic> json) =>
      FavoriteProduct(
        productId: json['productId'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        salePrice: (json['salePrice'] as num?)?.toDouble(),
        currentPrice: (json['currentPrice'] as num).toDouble(),
        isOnSale: json['isOnSale'] as bool,
        currencyCode: json['currencyCode'] as String,
        imageUrl: json['imageUrl'] as String?,
        categoryId: json['categoryId'] as String,
      );
}

class CustomerAddress {
  const CustomerAddress({
    required this.id,
    required this.label,
    required this.recipientName,
    required this.phoneNumber,
    required this.addressLine,
    required this.city,
    required this.province,
    required this.postalCode,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    required this.isDefault,
    required this.createdAt,
  });

  final String id;
  final String label;
  final String recipientName;
  final String phoneNumber;
  final String addressLine;
  final String city;
  final String? province;
  final String? postalCode;
  final String countryCode;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime createdAt;

  String get fullAddress => [
    addressLine,
    city,
    province,
    postalCode,
    countryCode,
  ].whereType<String>().where((part) => part.isNotEmpty).join(', ');

  factory CustomerAddress.fromJson(Map<String, dynamic> json) =>
      CustomerAddress(
        id: json['id'] as String,
        label: json['label'] as String,
        recipientName: json['recipientName'] as String,
        phoneNumber: json['phoneNumber'] as String,
        addressLine: json['addressLine'] as String,
        city: json['city'] as String,
        province: json['province'] as String?,
        postalCode: json['postalCode'] as String?,
        countryCode: json['countryCode'] as String,
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
        isDefault: json['isDefault'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}

class OrderItem {
  const OrderItem({
    required this.id,
    required this.productName,
    required this.sku,
    required this.size,
    required this.color,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String id;
  final String productName;
  final String sku;
  final String size;
  final String color;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    id: json['id'] as String,
    productName: json['productName'] as String,
    sku: json['sku'] as String,
    size: json['size'] as String,
    color: json['color'] as String,
    quantity: json['quantity'] as int,
    unitPrice: (json['unitPrice'] as num).toDouble(),
    lineTotal: (json['lineTotal'] as num).toDouble(),
  );
}

class CustomerOrder {
  const CustomerOrder({
    required this.id,
    required this.orderNumber,
    required this.status,
    required this.subtotal,
    required this.shippingAmount,
    required this.totalAmount,
    required this.currencyCode,
    required this.createdAt,
    required this.items,
  });

  final String id;
  final String orderNumber;
  final String status;
  final double subtotal;
  final double shippingAmount;
  final double totalAmount;
  final String currencyCode;
  final DateTime createdAt;
  final List<OrderItem> items;

  factory CustomerOrder.fromJson(Map<String, dynamic> json) => CustomerOrder(
    id: json['id'] as String,
    orderNumber: json['orderNumber'] as String,
    status: json['status'] as String,
    subtotal: (json['subtotal'] as num).toDouble(),
    shippingAmount: (json['shippingAmount'] as num).toDouble(),
    totalAmount: (json['totalAmount'] as num).toDouble(),
    currencyCode: json['currencyCode'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    items: (json['items'] as List<dynamic>)
        .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
        .toList(growable: false),
  );
}

class StoreNotification {
  const StoreNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.dataJson,
    required this.createdAt,
    required this.readAt,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final String? dataJson;
  final DateTime createdAt;
  final DateTime? readAt;

  bool get isRead => readAt != null;

  factory StoreNotification.fromJson(Map<String, dynamic> json) =>
      StoreNotification(
        id: json['id'] as String,
        type: json['type'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        dataJson: json['dataJson'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        readAt: json['readAt'] == null
            ? null
            : DateTime.parse(json['readAt'] as String),
      );
}

class ChatReply {
  const ChatReply({required this.answer});

  final String answer;

  factory ChatReply.fromJson(Map<String, dynamic> json) =>
      ChatReply(answer: json['answer'] as String);
}
