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
  final String currencyCode;
  final String? imageUrl;
  final String categoryId;
  final List<StoreVariant> variants;

  bool get isOnSale => currentPrice < price;

  int? get discountPercent =>
      isOnSale ? ((1 - currentPrice / price) * 100).round() : null;

  factory StoreProduct.fromJson(Map<String, dynamic> json) => StoreProduct(
    id: json['id'] as String,
    name: json['name'] as String,
    description: json['description'] as String?,
    price: (json['price'] as num).toDouble(),
    currentPrice: (json['currentPrice'] as num).toDouble(),
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
