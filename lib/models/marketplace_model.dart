class MarketplaceCategoryModel {
  final int id;
  final String name;
  final List<MarketplaceCategoryModel> children;

  const MarketplaceCategoryModel({
    required this.id,
    required this.name,
    this.children = const [],
  });

  factory MarketplaceCategoryModel.fromJson(Map<String, dynamic> json) {
    return MarketplaceCategoryModel(
      id:   (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      children: (json['children'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MarketplaceCategoryModel.fromJson)
          .toList(),
    );
  }
}

class MarketplaceProductModel {
  final int id;
  final String title;
  final String? description;
  final int? categoryId;
  final String? categoryName;
  final String? condition;      // new | used | refurbished
  final String listingType;     // sale | rent | both
  final int price;
  final int? rentPricePerDay;
  final int quantity;
  final String status;          // draft | active | paused
  final String? locationText;
  final double? locationLat;
  final double? locationLng;
  final String? expiresAt;
  final int? vehicleId;
  final int? sellerId;
  final String? sellerName;
  final List<String> images;
  final int viewsCount;
  final String createdAt;

  const MarketplaceProductModel({
    required this.id,
    required this.title,
    this.description,
    this.categoryId,
    this.categoryName,
    this.condition,
    required this.listingType,
    required this.price,
    this.rentPricePerDay,
    required this.quantity,
    required this.status,
    this.locationText,
    this.locationLat,
    this.locationLng,
    this.expiresAt,
    this.vehicleId,
    this.sellerId,
    this.sellerName,
    required this.images,
    required this.viewsCount,
    required this.createdAt,
  });

  factory MarketplaceProductModel.fromJson(Map<String, dynamic> json) {
    final seller = json['seller'] as Map<String, dynamic>?;
    final images = <String>[];
    for (final e in (json['images'] as List<dynamic>? ?? [])) {
      if (e is Map<String, dynamic>) {
        final url = e['full_url'] as String? ?? e['url'] as String? ?? e['path'] as String?;
        if (url != null) images.add(url);
      } else if (e is String) {
        images.add(e);
      }
    }
    return MarketplaceProductModel(
      id:             (json['id']    as num?)?.toInt() ?? 0,
      title:          json['title']  as String? ?? '',
      description:    json['description'] as String?,
      categoryId:     (json['category_id'] as num?)?.toInt(),
      categoryName:   (json['category'] as Map<String, dynamic>?)?['name'] as String?,
      condition:      json['condition']    as String?,
      listingType:    json['listing_type'] as String? ?? 'sale',
      price:          (json['price'] as num?)?.toInt() ?? 0,
      rentPricePerDay: (json['rent_price_per_day'] as num?)?.toInt(),
      quantity:       (json['quantity']    as num?)?.toInt() ?? 1,
      status:         json['status']       as String? ?? 'active',
      locationText:   json['location_text'] as String?,
      locationLat:    (json['location_lat'] as num?)?.toDouble(),
      locationLng:    (json['location_lng'] as num?)?.toDouble(),
      expiresAt:      json['expires_at']   as String?,
      vehicleId:      (json['vehicle_id']  as num?)?.toInt(),
      sellerId:       (seller?['id']       as num?)?.toInt(),
      sellerName:     seller?['name']      as String?,
      images:         images,
      viewsCount:     (json['views_count'] as num?)?.toInt() ?? 0,
      createdAt:      json['created_at']   as String? ?? '',
    );
  }
}

class MarketplaceOrderModel {
  final int id;
  final int productId;
  final String? productTitle;
  final String orderType;     // purchase | rent
  final int quantity;
  final String? rentStartDate;
  final String? rentEndDate;
  final String paymentMethod;
  final String status;        // pending | confirmed | completed | cancelled
  final int total;
  final String? notes;
  final String createdAt;

  const MarketplaceOrderModel({
    required this.id,
    required this.productId,
    this.productTitle,
    required this.orderType,
    required this.quantity,
    this.rentStartDate,
    this.rentEndDate,
    required this.paymentMethod,
    required this.status,
    required this.total,
    this.notes,
    required this.createdAt,
  });

  factory MarketplaceOrderModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    return MarketplaceOrderModel(
      id:           (json['id'] as num?)?.toInt() ?? 0,
      productId:    (json['product_id'] as num?)?.toInt() ?? (product?['id'] as num?)?.toInt() ?? 0,
      productTitle: product?['title'] as String?,
      orderType: json['order_type'] as String? ?? 'purchase',
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      rentStartDate: json['rent_start_date'] as String?,
      rentEndDate: json['rent_end_date'] as String?,
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      status: json['status'] as String? ?? 'pending',
      total: (json['total'] as num?)?.toInt() ?? 0,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}
