import 'user_model.dart';
import 'ride_model.dart';

class DriverStatusModel {
  final UserModel driver;
  final List<RideModel> activeRides;
  final List<dynamic> activeDeliveries;
  // Wallet-balance gate — whether the driver currently has enough balance to
  // go online. min_balance_khr is admin-configurable, never hardcode it.
  final bool canGoOnline;
  final int  walletBalanceKhr;
  final int  minBalanceKhr;

  const DriverStatusModel({
    required this.driver,
    required this.activeRides,
    required this.activeDeliveries,
    this.canGoOnline     = true,
    this.walletBalanceKhr = 0,
    this.minBalanceKhr    = 0,
  });

  factory DriverStatusModel.fromJson(Map<String, dynamic> json) {
    return DriverStatusModel(
      driver: UserModel.fromJson(json['driver'] as Map<String, dynamic>),
      activeRides: (json['active_rides'] as List<dynamic>)
          .map((e) => RideModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      activeDeliveries: json['active_deliveries'] as List<dynamic>? ?? [],
      canGoOnline:      json['can_go_online'] as bool? ?? true,
      walletBalanceKhr: _toInt(json['wallet_balance']),
      minBalanceKhr:    _toInt(json['min_balance_khr']),
    );
  }

  static int _toInt(dynamic v) =>
      v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

  bool get isAvailable  => driver.available;
  bool get hasActiveWork => activeRides.isNotEmpty || activeDeliveries.isNotEmpty;
}
