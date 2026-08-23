class MarketplaceProductsPage {
  final List<MarketplaceProductModel> products;
  final int currentPage;
  final int lastPage;
  final int total;
  bool get hasMore => currentPage < lastPage;

  const MarketplaceProductsPage({
    required this.products,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}

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

// ─── Vehicle type / color (marketplace filters) ───────────────────────────────
// GET /marketplace/vehicle-types and /marketplace/vehicle-colors.

class MarketplaceVehicleTypeModel {
  final int    id;
  final String nameEn;
  final String nameKm;
  final String slug;
  // Only populated when fetched via GET /marketplace/vehicle-types (which
  // eager-loads them) — the sizes valid for this specific vehicle type, per
  // the marketplace_vehicle_type_size pivot. Used to scope the size picker
  // once a type is chosen, since the backend 422s on a mismatched pairing.
  final List<MarketplaceVehicleSizeModel> sizes;

  const MarketplaceVehicleTypeModel({
    required this.id,
    required this.nameEn,
    required this.nameKm,
    required this.slug,
    this.sizes = const [],
  });

  String name(String languageCode) => languageCode == 'km' ? nameKm : nameEn;

  factory MarketplaceVehicleTypeModel.fromJson(Map<String, dynamic> json) => MarketplaceVehicleTypeModel(
    id:     (json['id'] as num?)?.toInt() ?? 0,
    nameEn: json['name_en'] as String? ?? '',
    nameKm: json['name_km'] as String? ?? '',
    slug:   json['slug'] as String? ?? '',
    sizes: (json['sizes'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(MarketplaceVehicleSizeModel.fromJson)
        .toList(),
  );
}

class MarketplaceVehicleColorModel {
  final int    id;
  final String nameEn;
  final String nameKm;
  final String code; // e.g. 'black' | 'red' | 'blue' | 'gray' — maps to a swatch color client-side

  const MarketplaceVehicleColorModel({
    required this.id,
    required this.nameEn,
    required this.nameKm,
    required this.code,
  });

  String name(String languageCode) => languageCode == 'km' ? nameKm : nameEn;

  factory MarketplaceVehicleColorModel.fromJson(Map<String, dynamic> json) => MarketplaceVehicleColorModel(
    id:     (json['id'] as num?)?.toInt() ?? 0,
    nameEn: json['name_en'] as String? ?? '',
    nameKm: json['name_km'] as String? ?? '',
    code:   json['code'] as String? ?? '',
  );
}

class MarketplaceVehicleSizeModel {
  final int    id;
  final String label;   // e.g. "1.4M"
  final double valueMeters;

  const MarketplaceVehicleSizeModel({
    required this.id,
    required this.label,
    required this.valueMeters,
  });

  factory MarketplaceVehicleSizeModel.fromJson(Map<String, dynamic> json) => MarketplaceVehicleSizeModel(
    id:          (json['id'] as num?)?.toInt() ?? 0,
    label:       json['label'] as String? ?? '',
    // Laravel's `decimal:2` cast serializes to a JSON string (e.g. "1.40"),
    // not a number — parse defensively regardless of which it sends.
    valueMeters: num.tryParse(json['value_meters']?.toString() ?? '')?.toDouble() ?? 0,
  );
}

class MarketplaceProductModel {
  final int id;
  final String title;
  final String? description;
  final int? categoryId;
  final String? categoryName;
  final String? condition;      // new | used | refurbished
  final String listingType;     // sale | rent | both
  final double price;
  final double? rentPricePerDay;
  final int quantity;
  final String status;          // draft | active | paused
  final String? locationText;
  final double? locationLat;
  final double? locationLng;
  final String? expiresAt;
  final int? vehicleId;
  final int? vehicleTypeId;
  final int? vehicleColorId;
  final int? vehicleSizeId;
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
    this.vehicleTypeId,
    this.vehicleColorId,
    this.vehicleSizeId,
    this.sellerId,
    this.sellerName,
    required this.images,
    required this.viewsCount,
    required this.createdAt,
  });

  static double _toDouble(dynamic v) =>
      v == null ? 0 : v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;

  static double? _toDoubleOpt(dynamic v) =>
      v == null ? null : v is num ? v.toDouble() : double.tryParse(v.toString());

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
      price:          _toDouble(json['price']),
      rentPricePerDay: _toDoubleOpt(json['rent_price_per_day']),
      quantity:       (json['quantity']    as num?)?.toInt() ?? 1,
      status:         json['status']       as String? ?? 'active',
      locationText:   json['location_text'] as String?,
      locationLat:    (json['location_lat'] as num?)?.toDouble(),
      locationLng:    (json['location_lng'] as num?)?.toDouble(),
      expiresAt:      json['expires_at']   as String?,
      vehicleId:      (json['vehicle_id']  as num?)?.toInt(),
      vehicleTypeId:  (json['marketplace_vehicle_type_id']  as num?)?.toInt(),
      vehicleColorId: (json['marketplace_vehicle_color_id'] as num?)?.toInt(),
      vehicleSizeId:  (json['marketplace_vehicle_size_id']  as num?)?.toInt(),
      sellerId:       (seller?['id']       as num?)?.toInt(),
      sellerName:     seller?['name']      as String?,
      images:         images,
      viewsCount:     (json['views_count'] as num?)?.toInt() ?? 0,
      createdAt:      json['created_at']   as String? ?? '',
    );
  }
}

// One line of a POST /marketplace/checkout request. product_id must be
// unique across the items list (bump quantity instead of repeating a line —
// the backend rejects duplicates).
class MarketplaceCheckoutItem {
  final int    productId;
  final int    quantity;
  final String orderType; // purchase | rent
  final String? rentStartDate; // yyyy-MM-dd, required when orderType == rent
  final String? rentEndDate;

  const MarketplaceCheckoutItem({
    required this.productId,
    required this.quantity,
    this.orderType = 'purchase',
    this.rentStartDate,
    this.rentEndDate,
  });

  Map<String, dynamic> toJson() => {
    'product_id':  productId,
    'quantity':    quantity,
    'order_type':  orderType,
    if (rentStartDate != null) 'rent_start_date': rentStartDate,
    if (rentEndDate   != null) 'rent_end_date':   rentEndDate,
  };
}

class MarketplaceOrderModel {
  final int id;
  final int productId;
  final String? productTitle;
  final String? productImage;
  final String orderType;       // purchase | rent
  final int quantity;
  final int? days;
  final String? rentStartDate;
  final String? rentEndDate;
  final String paymentMethod;
  final String status;          // pending | confirmed | completed | cancelled
  final String paymentStatus;   // unpaid | paid | refunded
  final double unitPriceUsd;
  final double totalPriceUsd;
  final String? notes;
  final String createdAt;
  final String? renterName;
  final String? renterPhone;
  final String? sellerName;
  final String? sellerPhone;

  const MarketplaceOrderModel({
    required this.id,
    required this.productId,
    this.productTitle,
    this.productImage,
    required this.orderType,
    required this.quantity,
    this.days,
    this.rentStartDate,
    this.rentEndDate,
    required this.paymentMethod,
    required this.status,
    required this.paymentStatus,
    required this.unitPriceUsd,
    required this.totalPriceUsd,
    this.notes,
    required this.createdAt,
    this.renterName,
    this.renterPhone,
    this.sellerName,
    this.sellerPhone,
  });

  // total_price_usd = unit_price_usd × days × quantity
  double get computedTotal => unitPriceUsd * (days ?? 1) * quantity;

  factory MarketplaceOrderModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'] as Map<String, dynamic>?;
    final buyer   = json['buyer']   as Map<String, dynamic>?;
    final renter  = json['renter']  as Map<String, dynamic>?;
    final seller  = json['seller']  as Map<String, dynamic>?;

    // dates may come as ISO8601 ("2026-07-01T00:00:00.000000Z") — keep date part only
    String? _date(String? raw) {
      if (raw == null) return null;
      return raw.contains('T') ? raw.split('T').first : raw;
    }

    return MarketplaceOrderModel(
      id:            (json['id'] as num?)?.toInt() ?? 0,
      productId:     (json['product_id'] as num?)?.toInt()
                         ?? (product?['id'] as num?)?.toInt() ?? 0,
      productTitle:  product?['title'] as String? ?? json['title'] as String?,
      productImage:  product?['image'] as String?,
      orderType:     json['order_type'] as String? ?? 'purchase',
      quantity:      (json['quantity'] as num?)?.toInt() ?? 1,
      days:          (json['days'] as num?)?.toInt(),
      rentStartDate: _date(json['rent_start_date'] as String?),
      rentEndDate:   _date(json['rent_end_date']   as String?),
      paymentMethod: json['payment_method'] as String? ?? 'cash',
      status:        json['status']         as String? ?? 'pending',
      paymentStatus: json['payment_status'] as String? ?? 'unpaid',
      // API returns unit_price / total_price (also accepts unit_price_usd / total_price_usd)
      unitPriceUsd:  MarketplaceProductModel._toDouble(
                         json['unit_price_usd'] ?? json['unit_price']),
      totalPriceUsd: MarketplaceProductModel._toDouble(
                         json['total_price_usd'] ?? json['total_price']),
      notes:         json['notes'] as String?,
      createdAt:     json['created_at'] as String? ?? '',
      // buyer key used in buying orders; renter key used in rental confirmations
      renterName:    (buyer ?? renter)?['name']  as String?,
      renterPhone:   (buyer ?? renter)?['phone'] as String?,
      sellerName:    seller?['name']  as String?,
      sellerPhone:   seller?['phone'] as String?,
    );
  }
}
