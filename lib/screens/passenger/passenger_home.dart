import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:autoride_superapp/widgets/common_widgets.dart';
import 'package:autoride_superapp/widgets/banner_carousel.dart';
import 'package:autoride_superapp/l10n/app_localizations.dart';
import 'package:autoride_superapp/screens/auth/login_screen.dart';
import 'package:autoride_superapp/screens/driver/driver_home.dart';
import 'package:autoride_superapp/services/api_service.dart';
import 'package:autoride_superapp/utils/app_log.dart';
import 'package:autoride_superapp/models/ride_model.dart';
import 'ride_booking.dart';
import 'delivery_screen.dart';
import 'marketplace_screen.dart';
import 'charging_stations.dart';
import 'chat_screen.dart';
import 'payment_methods_screen.dart';
import 'safety_screen.dart';
import 'trip_history_screen.dart';
import 'trip_tracking_screen.dart';
import 'wallet_screen.dart';
import 'promo_screen.dart';
import 'edit_profile_screen.dart';
import 'saved_places_screen.dart';
import 'support_screen.dart';
import 'scheduled_rides_screen.dart';
import 'loyalty_screen.dart';
import 'referral_screen.dart';
import 'qr_payment_screen.dart';
import 'settings_screen.dart';
import 'car_rental_screen.dart';
import 'family_screen.dart';
import 'subscription_screen.dart';
import 'my_rentals_screen.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen> {
  int _tab = 0;

  final List<Widget> _pages = [
    const _HomeTab(),
    const RideBookingScreen(skipDestination: true),
    const ChargingStationsScreen(),
    const ChatScreen(isDriver: false),
    const _ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _pages[_tab],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: context.appSurface,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20)],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                Expanded(child: _NavItem(icon: Icons.home_outlined, label: AppLocalizations.of(context).home, index: 0, current: _tab, onTap: (i) => setState(() => _tab = i))),
                Expanded(child: _NavItem(
                    icon: Icons.electric_rickshaw,
                    label: AppLocalizations.of(context).bookRide,
                    index: 1,
                    current: _tab,
                    onTap: (i) => setState(() => _tab = i),
                  )),
                Expanded(child: _NavItem(icon: Icons.ev_station_outlined, label: AppLocalizations.of(context).charging, index: 2, current: _tab, onTap: (i) => setState(() => _tab = i))),
                Expanded(child: _NavItem(icon: Icons.chat_bubble_outline, label: AppLocalizations.of(context).chat, index: 3, current: _tab, onTap: (i) => setState(() => _tab = i))),
                Expanded(child: _NavItem(icon: Icons.person_outline, label: AppLocalizations.of(context).profile, index: 4, current: _tab, onTap: (i) => setState(() => _tab = i))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final Function(int) onTap;

  const _NavItem({required this.icon, required this.label, required this.index, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: selected ? AppTheme.accent : context.appTextSecondary, size: 22),
            SizedBox(height: 4),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: selected ? AppTheme.accent : context.appTextSecondary,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  static const _gridColumnsPrefKey = 'home_services_grid_columns';

  String     _firstName  = '';
  List<RideModel> _recentRides = [];
  RideModel? _activeRide;
  SurgeInfo? _surgeInfo;
  int _gridColumns = 3;

  @override
  void initState() {
    super.initState();
    _load();
    _loadGridColumns();
  }

  Future<void> _loadGridColumns() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt(_gridColumnsPrefKey);
    if (saved == 2 || saved == 3) {
      if (mounted) setState(() => _gridColumns = saved!);
    }
  }

  Future<void> _setGridColumns(int columns) async {
    setState(() => _gridColumns = columns);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_gridColumnsPrefKey, columns);
  }

  Future<void> _load() async {
    final saved = await ApiService.getSavedUser();
    if (!mounted) return;
    final name = saved?.name ?? '';
    setState(() => _firstName = name.split(' ').first);

    // Run all three fetches in parallel
    await Future.wait([
      _loadRecentRides(),
      _loadActiveRide(),
      _loadSurge(),
    ]);
  }

  Future<void> _loadRecentRides() async {
    try {
      final rides = await ApiService.getRides(status: 'completed');
      if (!mounted) return;
      setState(() => _recentRides = rides.take(5).toList());
    } catch (e, s) {
      AppLog.e('Home', 'loadRecentRides failed', e, s);
    }
  }

  Future<void> _loadActiveRide() async {
    try {
      final ride = await ApiService.getActiveRide();
      if (!mounted) return;
      setState(() => _activeRide = ride);
    } catch (_) {}
  }

  Future<void> _loadSurge() async {
    try {
      double? lat, lng;
      try {
        final pos = await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.low,
            );
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {}
      final info = await ApiService.checkSurge(lat: lat, lng: lng);
      if (!mounted) return;
      if (info.surgeActive) setState(() => _surgeInfo = info);
    } catch (_) {}
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return '';
    if (h < 18) return '';
    return '';
  }

  void _resumeActiveRide() {
    final ride = _activeRide;
    if (ride == null) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => TripTrackingScreen(
        rideId:       ride.id,
        driverId:     ride.driverId?.toString() ?? '',
        driverName:   ride.driver?.name ?? 'Finding driver...',
        vehicle:      ride.vehicle != null
            ? '${ride.vehicle!.make} ${ride.vehicle!.model} ${ride.vehicle!.year}'
            : '--',
        vehicleType:  ride.vehicle?.type ?? 'motorbike',
        plate:        ride.vehicle?.licensePlate ?? '--',
        from:         ride.pickupAddress,
        to:           ride.dropoffAddress,
        fare:         AppTheme.khr(ride.fareKhr),
        pickupLatLng: ride.pickupLat != null && ride.pickupLng != null
            ? LatLng(ride.pickupLat!, ride.pickupLng!)
            : null,
        destLatLng:   ride.dropoffLat != null && ride.dropoffLng != null
            ? LatLng(ride.dropoffLat!, ride.dropoffLng!)
            : null,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_greeting(),
                        style: TextStyle(
                            color: context.appTextSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(_firstName.isEmpty ? AppLocalizations.of(context).welcome : '${AppLocalizations.of(context).hello} $_firstName 👋',
                        style: TextStyle(color: context.appTextPrimary, fontSize: 21, fontWeight: FontWeight.w800)),
                  ],
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.35)],
                        ),
                      ),
                      child: CircleAvatar(
                          backgroundColor: context.appSurface,
                          radius: 21,
                          child: Icon(Icons.person, color: AppTheme.accent)),
                    ),
                    Positioned(bottom: 0, right: 0,
                      child: Container(
                        width: 12, height: 12,
                        decoration: BoxDecoration(
                          color: AppTheme.success,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.appBackground, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Active ride restore banner
            if (_activeRide != null)
              GestureDetector(
                onTap: _resumeActiveRide,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: AppTheme.success.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.electric_rickshaw,
                        color: AppTheme.success, size: 22),
                    const SizedBox(width: 10),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      const Text('Active ride in progress',
                          style: TextStyle(color: AppTheme.success,
                              fontWeight: FontWeight.w700, fontSize: 13)),
                      Text(
                          '${_activeRide!.pickupAddress} → ${_activeRide!.dropoffAddress}',
                          style: TextStyle(
                              color: context.appTextSecondary, fontSize: 12),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ])),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: AppTheme.success, size: 14),
                  ]),
                ),
              ),

            // Surge zone banner
            if (_surgeInfo != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.danger.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.local_fire_department,
                      color: AppTheme.danger, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    _surgeInfo!.message ??
                        '${_surgeInfo!.multiplier.toStringAsFixed(1)}× surge pricing active in your area',
                    style: const TextStyle(
                        color: AppTheme.danger, fontSize: 12,
                        fontWeight: FontWeight.w600),
                  )),
                ]),
              ),

            const SizedBox(height: 8),
            // Hero banner
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen())),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E7D32), Color(0xFF00E676)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF2E7D32).withValues(alpha: 0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 6)),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(children: [
                  Positioned(right: -20, top: -30,
                    child: Container(width: 110, height: 110,
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08), shape: BoxShape.circle))),
                  Positioned(right: 40, bottom: -40,
                    child: Container(width: 70, height: 70,
                        decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06), shape: BoxShape.circle))),
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(AppLocalizations.of(context).evCarsSubtitle, style: const TextStyle(color: AppTheme.primary, fontSize: 15, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(8)),
                                child: Text(AppLocalizations.of(context).explore, style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: Image.asset(
                            'assets/library/icon_fa.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 16),
            const BannerCarousel(),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(AppLocalizations.of(context).services,
                    style: TextStyle(
                        color: context.appTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
                _GridColumnToggle(
                  columns: _gridColumns,
                  onChanged: _setGridColumns,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Builder(builder: (context) {
              final l = AppLocalizations.of(context);
              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: _gridColumns,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: _gridColumns == 2 ? 1.7 : 1.1,
                children: [
                  ServiceCard(
                    icon: Icons.electric_rickshaw,
                    title: l.bookRide,
                    color: AppTheme.accent,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RideBookingScreen(skipDestination: true))),
                  ),
                  ServiceCard(
                    icon: Icons.delivery_dining_outlined,
                    title: l.delivery,
                    color: AppTheme.accentOrange,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliveryScreen())),
                  ),
                  ServiceCard(
                    icon: Icons.store_outlined,
                    title: l.marketplace,
                    color: const Color(0xFF9C27B0),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen())),
                  ),
                  ServiceCard(
                    icon: Icons.ev_station_outlined,
                    title: l.evStations,
                    color: AppTheme.warning,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChargingStationsScreen())),
                  ),
                  ServiceCard(
                    icon: Icons.handshake,
                    title: 'Rental',
                    color: const Color(0xFF1565C0),
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CarRentalScreen())),
                  ),
                  ServiceCard(
                    icon: Icons.family_restroom_rounded,
                    title: 'Family',
                    color: AppTheme.accentOrange,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyScreen())),
                  ),
                ],
              );
            }),
            const SizedBox(height: 24),
            Builder(builder: (context) {
              final l = AppLocalizations.of(context);
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SectionHeader(title: l.quickActions),
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: _QuickAction(icon: Icons.account_balance_wallet_outlined, label: 'Wallet', color: AppTheme.accent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())))),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickAction(icon: Icons.star_outline, label: 'Rewards', color: AppTheme.gold,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoyaltyScreen())))),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickAction(icon: Icons.card_giftcard_outlined, label: 'Refer', color: AppTheme.success,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen())))),
                  const SizedBox(width: 12),
                  Expanded(child: _QuickAction(icon: Icons.shield_outlined, label: l.safety, color: AppTheme.danger,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SafetyScreen())))),
                ]),
              ]);
            }),
            const SizedBox(height: 24),
            Builder(builder: (context) {
              final l = AppLocalizations.of(context);
              return SectionHeader(title: l.recentTrips, action: l.seeAll,
                  onAction: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TripHistoryScreen())));
            }),
            SizedBox(height: 14),
            if (_recentRides.isEmpty)
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(14)),
                child: Center(child: Text('No recent trips', style: TextStyle(color: context.appTextSecondary))),
              )
            else
              ..._recentRides.map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _TripCard(
                  from: r.pickupAddress,
                  to: r.dropoffAddress,
                  price: AppTheme.khr(r.fareKhr),
                  status: r.status[0].toUpperCase() + r.status.substring(1),
                  date: r.createdAt.length >= 16 ? r.createdAt.substring(0, 16) : r.createdAt,
                ),
              )),
          ],
        ),
      ),
    );
  }
}

class _GridColumnToggle extends StatelessWidget {
  final int columns;
  final ValueChanged<int> onChanged;
  const _GridColumnToggle({required this.columns, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: context.appCardBg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _ColumnOption(
            icon: Icons.grid_view_rounded,
            active: columns == 3,
            onTap: () => onChanged(3)),
        _ColumnOption(
            icon: Icons.view_module_outlined,
            active: columns == 2,
            onTap: () => onChanged(2)),
      ]),
    );
  }
}

class _ColumnOption extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _ColumnOption({required this.icon, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: active ? AppTheme.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 16,
          color: active ? AppTheme.primary : context.appTextSecondary),
    ),
  );
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 19),
            ),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(
                color: context.appTextSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  final String from, to, price, status, date;
  const _TripCard({required this.from, required this.to, required this.price, required this.status, required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(padding: EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.route, color: AppTheme.accent, size: 20)),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$from → $to', style: TextStyle(color: context.appTextPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text(date, style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(price, style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              StatusBadge(label: status, color: AppTheme.success),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab();

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  String _name  = '';
  String _phone = '';
  String? _photoUrl;
  bool _loadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await ApiService.getMe();
      if (!mounted) return;
      setState(() {
        _name  = user.name;
        _phone = user.phone;
        _photoUrl = user.photoUrl;
        _loadingProfile = false;
      });
    } catch (_) {
      // fall back to cached prefs
      final saved = await ApiService.getSavedUser();
      if (!mounted) return;
      setState(() {
        _name  = saved?.name  ?? '';
        _phone = saved?.phone ?? '';
        _loadingProfile = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            SizedBox(height: 20),
            CircleAvatar(
              radius: 48,
              backgroundColor: AppTheme.accent.withValues(alpha: 0.2),
              backgroundImage: _photoUrl != null && _photoUrl!.isNotEmpty
                  ? NetworkImage(_photoUrl!)
                  : null,
              child: _photoUrl == null || _photoUrl!.isEmpty
                  ? Icon(Icons.person, color: AppTheme.accent, size: 48)
                  : null,
            ),
            SizedBox(height: 12),
            _loadingProfile
                ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2))
                : Text(_name, style: TextStyle(color: context.appTextPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
            SizedBox(height: 4),
            Text(_phone, style: TextStyle(color: context.appTextSecondary)),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.star, color: AppTheme.gold, size: 18),
                SizedBox(width: 4),
                Text('4.9', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600)),
                SizedBox(width: 4),
                Text('(128 trips)', style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 24),
            Builder(builder: (context) {
              final l = AppLocalizations.of(context);
              return Column(children: [
                _ProfileMenuItem(icon: Icons.edit_outlined, label: 'Edit Profile',
                    onTap: () async {
                      await Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                      // Pushing doesn't unmount this tab, so its cached
                      // profile data would otherwise stay stale after a save.
                      _loadProfile();
                    }),
                _ProfileMenuItem(icon: Icons.account_balance_wallet_outlined, label: 'ROTEH Pay',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()))),
                _ProfileMenuItem(icon: Icons.qr_code_outlined, label: 'QR Payment',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const QrPaymentScreen()))),
                _ProfileMenuItem(icon: Icons.local_offer_outlined, label: 'Promos & Vouchers',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PromoScreen()))),
                _ProfileMenuItem(icon: Icons.calendar_month_outlined, label: 'Scheduled Rides',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduledRidesScreen()))),
                _ProfileMenuItem(icon: Icons.workspace_premium_rounded, label: 'Subscription Plans',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubscriptionScreen()))),
                _ProfileMenuItem(icon: Icons.star_outline, label: 'ROTEH Rewards',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LoyaltyScreen()))),
                _ProfileMenuItem(icon: Icons.card_giftcard_outlined, label: 'Refer & Earn',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReferralScreen()))),
                _ProfileMenuItem(icon: Icons.payment_outlined, label: l.paymentMethods,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()))),
                _ProfileMenuItem(icon: Icons.history_outlined, label: l.tripHistory,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TripHistoryScreen()))),
                _ProfileMenuItem(icon: Icons.directions_car_outlined, label: 'My Rentals',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyRentalsScreen()))),
                _ProfileMenuItem(icon: Icons.bookmark_outline, label: 'Saved Places',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SavedPlacesScreen()))),
                _ProfileMenuItem(icon: Icons.help_outline, label: l.helpSupport,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupportScreen()))),
                _ProfileMenuItem(icon: Icons.settings_outlined, label: 'Settings',
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))),
                _ProfileMenuItem(
                  icon: Icons.drive_eta_outlined,
                  label: 'Switch to Driver Mode',
                  color: AppTheme.accentOrange,
                  onTap: () => Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
                    (_) => false,
                  ),
                ),
                _ProfileMenuItem(
                  icon: Icons.logout,
                  label: l.signOut,
                  color: AppTheme.danger,
                  onTap: () async {
                    await ApiService.logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                ),
              ]);
            }),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _ProfileMenuItem({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 10),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(14)),
        child: Row(
          children: [
            Icon(icon, color: color ?? context.appTextSecondary, size: 20),
            SizedBox(width: 14),
            Text(label, style: TextStyle(color: color ?? context.appTextPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
            Spacer(),
            Icon(Icons.chevron_right, color: context.appTextSecondary, size: 18),
          ],
        ),
      ),
    );
  }
}
