class UserModel {
  final int    id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool   available;
  final String? statusNote;
  final String  walletBalance;
  final String? tokenExpiresAt;
  final String? refreshTokenExpiresAt;
  // Driver-specific — populated when the user is returned as a driver on a ride
  final String? photoUrl;    // backend: photo_url
  final double? rating;      // backend: rating (driver's own avg rating)
  final int?    totalTrips;  // backend: total_trips / completed_rides

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.available,
    this.statusNote,
    this.walletBalance = '0.00',
    this.tokenExpiresAt,
    this.refreshTokenExpiresAt,
    this.photoUrl,
    this.rating,
    this.totalTrips,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // id may arrive as int or String
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

    // available may arrive as bool, int (0/1), or String ("true"/"1")
    final rawAvail  = json['available'];
    final available = rawAvail is bool
        ? rawAvail
        : rawAvail is int
            ? rawAvail != 0
            : (int.tryParse(rawAvail?.toString() ?? '') ?? 1) != 0;

    // wallet_balance may arrive as num or String
    final rawWallet = json['wallet_balance'];
    final walletBalance = rawWallet == null
        ? '0.00'
        : rawWallet is String
            ? rawWallet
            : rawWallet.toString();

    return UserModel(
      id:                    id,
      name:                  json['name']?.toString() ?? '',
      email:                 json['email']?.toString() ?? '',
      phone:                 json['phone']?.toString() ?? '',
      role:                  json['role']?.toString()  ?? '',
      available:             available,
      statusNote:            json['status_note']?.toString(),
      walletBalance:         walletBalance,
      tokenExpiresAt:        json['token_expires_at']?.toString(),
      refreshTokenExpiresAt: json['refresh_token_expires_at']?.toString(),
      photoUrl:   json['photo_url']?.toString(),
      rating:     json['rating']     == null ? null : num.tryParse(json['rating'].toString())?.toDouble(),
      totalTrips: json['total_trips'] != null
          ? int.tryParse(json['total_trips'].toString())
          : (json['completed_rides'] != null
              ? int.tryParse(json['completed_rides'].toString())
              : null),
    );
  }

  bool get isDriver    => role == 'driver';
  bool get isPassenger => role == 'passenger';
}
