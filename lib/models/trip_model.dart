class TripOtherParty {
  final String name;
  final String? avatar;

  const TripOtherParty({required this.name, this.avatar});

  factory TripOtherParty.fromJson(Map<String, dynamic> j) =>
      TripOtherParty(name: j['name'] as String? ?? '', avatar: j['avatar'] as String?);
}

class TripVehicle {
  final String? type;
  final String? plate;

  const TripVehicle({this.type, this.plate});

  factory TripVehicle.fromJson(Map<String, dynamic> j) =>
      TripVehicle(type: j['type'] as String?, plate: j['plate'] as String?);
}

class TripModel {
  final int    id;
  final String ref;
  final String type;       // ride | delivery | moving
  final String typeLabel;
  final String status;
  final String statusLabel;
  final String pickup;
  final String dropoff;
  final double? pickupLat;
  final double? pickupLng;
  final double? dropoffLat;
  final double? dropoffLng;
  final int    amount;
  final int    discount;
  final int    tip;
  final String currency;
  final String paymentMethod;
  final double? rating;
  final String date;
  final String dateLabel;
  final TripOtherParty? otherParty;
  final TripVehicle?    vehicle;
  final bool canRebook;
  final bool canRate;

  const TripModel({
    required this.id,
    required this.ref,
    required this.type,
    required this.typeLabel,
    required this.status,
    required this.statusLabel,
    required this.pickup,
    required this.dropoff,
    this.pickupLat,
    this.pickupLng,
    this.dropoffLat,
    this.dropoffLng,
    required this.amount,
    required this.discount,
    required this.tip,
    required this.currency,
    required this.paymentMethod,
    this.rating,
    required this.date,
    required this.dateLabel,
    this.otherParty,
    this.vehicle,
    required this.canRebook,
    required this.canRate,
  });

  factory TripModel.fromJson(Map<String, dynamic> j) => TripModel(
    id:            j['id']            as int,
    ref:           j['ref']           as String? ?? '',
    type:          j['type']          as String? ?? 'ride',
    typeLabel:     j['type_label']    as String? ?? '',
    status:        j['status']        as String? ?? '',
    statusLabel:   j['status_label']  as String? ?? '',
    pickup:        j['pickup']        as String? ?? '',
    dropoff:       j['dropoff']       as String? ?? '',
    pickupLat:     (j['pickup_lat']   as num?)?.toDouble(),
    pickupLng:     (j['pickup_lng']   as num?)?.toDouble(),
    dropoffLat:    (j['dropoff_lat']  as num?)?.toDouble(),
    dropoffLng:    (j['dropoff_lng']  as num?)?.toDouble(),
    amount:        j['amount']        as int? ?? 0,
    discount:      j['discount']      as int? ?? 0,
    tip:           j['tip']           as int? ?? 0,
    currency:      j['currency']      as String? ?? 'KHR',
    paymentMethod: j['payment_method'] as String? ?? 'cash',
    rating:        (j['rating']       as num?)?.toDouble(),
    date:          j['date']          as String? ?? '',
    dateLabel:     j['date_label']    as String? ?? '',
    otherParty:    j['other_party'] is Map<String, dynamic>
                       ? TripOtherParty.fromJson(j['other_party'] as Map<String, dynamic>)
                       : null,
    vehicle:       j['vehicle'] is Map<String, dynamic>
                       ? TripVehicle.fromJson(j['vehicle'] as Map<String, dynamic>)
                       : null,
    canRebook:     j['can_rebook'] as bool? ?? false,
    canRate:       j['can_rate']   as bool? ?? false,
  );
}

class TripGroup {
  final String month;
  final int    count;
  final List<TripModel> trips;

  const TripGroup({required this.month, required this.count, required this.trips});

  factory TripGroup.fromJson(Map<String, dynamic> j) => TripGroup(
    month: j['month'] as String? ?? '',
    count: j['count'] as int? ?? 0,
    trips: (j['trips'] as List<dynamic>? ?? [])
        .map((e) => TripModel.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class TripStats {
  final int totalTrips;
  final int completed;
  final int cancelled;
  final int totalSpentKhr;
  final int rides;
  final int deliveries;
  final int movings;

  const TripStats({
    required this.totalTrips,
    required this.completed,
    required this.cancelled,
    required this.totalSpentKhr,
    required this.rides,
    required this.deliveries,
    required this.movings,
  });

  factory TripStats.fromJson(Map<String, dynamic> j) => TripStats(
    totalTrips:    j['total_trips']     as int? ?? 0,
    completed:     j['completed']       as int? ?? 0,
    cancelled:     j['cancelled']       as int? ?? 0,
    totalSpentKhr: j['total_spent_khr'] as int? ?? 0,
    rides:         j['rides']           as int? ?? 0,
    deliveries:    j['deliveries']      as int? ?? 0,
    movings:       j['movings']         as int? ?? 0,
  );
}

class TripListResult {
  final List<TripModel>  trips;
  final List<TripGroup>  grouped;
  final TripStats?       stats;
  final String           filter;
  final String           type;
  final int              currentPage;
  final int              lastPage;
  final int              total;
  final bool             hasMore;

  const TripListResult({
    required this.trips,
    required this.grouped,
    this.stats,
    required this.filter,
    required this.type,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.hasMore,
  });

  factory TripListResult.fromJson(Map<String, dynamic> body) {
    final data       = (body['data'] as Map<String, dynamic>?) ?? body;
    final pagination = data['pagination'] as Map<String, dynamic>? ?? {};
    return TripListResult(
      trips:       (data['trips'] as List<dynamic>? ?? [])
                       .map((e) => TripModel.fromJson(e as Map<String, dynamic>))
                       .toList(),
      grouped:     (data['grouped'] as List<dynamic>? ?? [])
                       .map((e) => TripGroup.fromJson(e as Map<String, dynamic>))
                       .toList(),
      stats:       data['stats'] is Map<String, dynamic>
                       ? TripStats.fromJson(data['stats'] as Map<String, dynamic>)
                       : null,
      filter:      data['filter'] as String? ?? 'recent',
      type:        data['type']   as String? ?? 'all',
      currentPage: pagination['current_page'] as int? ?? 1,
      lastPage:    pagination['last_page']    as int? ?? 1,
      total:       pagination['total']        as int? ?? 0,
      hasMore:     pagination['has_more']     as bool? ?? false,
    );
  }
}

class TripMonthOption {
  final String value; // 2026-06
  final String label; // June 2026

  const TripMonthOption({required this.value, required this.label});

  factory TripMonthOption.fromJson(Map<String, dynamic> j) =>
      TripMonthOption(value: j['value'] as String, label: j['label'] as String);
}
