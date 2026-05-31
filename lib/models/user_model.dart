class UserModel {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final bool available;
  final String? statusNote;
  final String walletBalance;
  final String? tokenExpiresAt;
  final String? refreshTokenExpiresAt;

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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // id may arrive as int or String
    final rawId = json['id'];
    final id = rawId is int ? rawId : int.tryParse(rawId?.toString() ?? '') ?? 0;

    // available may arrive as int (0/1) or bool
    final rawAvail = json['available'];
    final available = rawAvail is bool ? rawAvail : (rawAvail as int? ?? 1) == 1;

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
    );
  }

  bool get isDriver    => role == 'driver';
  bool get isPassenger => role == 'passenger';
}
