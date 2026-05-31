import 'package:flutter/material.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:autoride_superapp/widgets/common_widgets.dart';
import 'payment_screen.dart';

// ─── Data Models ────────────────────────────────────────────────
class Vehicle {
  final String id, name, brand, type, fuelType, year, color;
  final String buyPrice, rentPriceDay, rentPriceWeek;
  final String range, seats, power, mileage;
  final double rating;
  final int reviews;
  final List<String> features;
  final bool isAvailable, isFeatured;
  final Color accentColor;

  const Vehicle({
    required this.id, required this.name, required this.brand,
    required this.type, required this.fuelType, required this.year,
    required this.color, required this.buyPrice, required this.rentPriceDay,
    required this.rentPriceWeek, required this.range, required this.seats,
    required this.power, required this.mileage, required this.rating,
    required this.reviews, required this.features, required this.isAvailable,
    required this.isFeatured, required this.accentColor,
  });
}

const _vehicles = [
  Vehicle(
    id: '1', name: 'Model 3 Long Range', brand: 'Tesla', type: 'Sedan',
    fuelType: 'Electric', year: '2024', color: 'Pearl White',
    buyPrice: '\$42,000', rentPriceDay: '\$75/day', rentPriceWeek: '\$420/week',
    range: '576 km', seats: '5', power: '498 hp', mileage: '12,000 km',
    rating: 4.9, reviews: 248, isAvailable: true, isFeatured: true,
    accentColor: Color(0xFF00D4AA),
    features: ['Autopilot', 'Supercharger', 'OTA Updates', 'Premium Audio'],
  ),
  Vehicle(
    id: '2', name: 'Atto 3 Extended', brand: 'BYD', type: 'SUV',
    fuelType: 'Electric', year: '2024', color: 'Surf Blue',
    buyPrice: '\$32,500', rentPriceDay: '\$52/day', rentPriceWeek: '\$295/week',
    range: '420 km', seats: '5', power: '204 hp', mileage: '8,500 km',
    rating: 4.7, reviews: 183, isAvailable: true, isFeatured: false,
    accentColor: Color(0xFF2196F3),
    features: ['Blade Battery', 'DiLink System', '360° Camera', 'Heat Pump'],
  ),
  Vehicle(
    id: '3', name: 'Ioniq 6 Standard', brand: 'Hyundai', type: 'Sedan',
    fuelType: 'Electric', year: '2023', color: 'Gravity Gold',
    buyPrice: '\$38,000', rentPriceDay: '\$60/day', rentPriceWeek: '\$340/week',
    range: '491 km', seats: '5', power: '225 hp', mileage: '5,200 km',
    rating: 4.8, reviews: 97, isAvailable: true, isFeatured: true,
    accentColor: Color(0xFFFFB300),
    features: ['800V Fast Charge', 'V2L Tech', 'ADAS Suite', 'Digital Mirrors'],
  ),
  Vehicle(
    id: '4', name: 'Camry Hybrid XSE', brand: 'Toyota', type: 'Sedan',
    fuelType: 'Hybrid', year: '2023', color: 'Midnight Black',
    buyPrice: '\$28,900', rentPriceDay: '\$45/day', rentPriceWeek: '\$255/week',
    range: '950 km', seats: '5', power: '219 hp', mileage: '22,000 km',
    rating: 4.6, reviews: 312, isAvailable: true, isFeatured: false,
    accentColor: Color(0xFF9C27B0),
    features: ['Toyota Safety Sense', 'JBL Audio', 'HUD Display', 'Wireless Charge'],
  ),
  Vehicle(
    id: '5', name: 'EQS 580 4MATIC', brand: 'Mercedes', type: 'Luxury Sedan',
    fuelType: 'Electric', year: '2024', color: 'High-tech Silver',
    buyPrice: '\$119,000', rentPriceDay: '\$180/day', rentPriceWeek: '\$980/week',
    range: '660 km', seats: '5', power: '516 hp', mileage: '3,100 km',
    rating: 5.0, reviews: 41, isAvailable: false, isFeatured: true,
    accentColor: Color(0xFFFF6B35),
    features: ['Hyperscreen', 'MBUX AI', 'Air Suspension', 'Burmester 3D Audio'],
  ),
  Vehicle(
    id: '6', name: 'Polestar 2 Performance', brand: 'Polestar', type: 'Fastback',
    fuelType: 'Electric', year: '2024', color: 'Snow White',
    buyPrice: '\$52,000', rentPriceDay: '\$85/day', rentPriceWeek: '\$480/week',
    range: '482 km', seats: '5', power: '476 hp', mileage: '6,800 km',
    rating: 4.8, reviews: 66, isAvailable: true, isFeatured: false,
    accentColor: Color(0xFF00BCD4),
    features: ['Brembo Brakes', 'Öhlins Suspension', 'Google Built-in', 'Vegan Interior'],
  ),
];

// ─── Main Marketplace Screen ─────────────────────────────────────
class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _fuelFilter = 'All';
  String _sortBy = 'Featured';
  String _searchQuery = '';
  bool _showSearch = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  List<Vehicle> get _filtered {
    var list = _vehicles.where((v) {
      final matchFuel = _fuelFilter == 'All' || v.fuelType == _fuelFilter;
      final matchSearch = _searchQuery.isEmpty ||
          v.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.brand.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchFuel && matchSearch;
    }).toList();

    if (_sortBy == 'Price: Low') {
      list.sort((a, b) => a.buyPrice.compareTo(b.buyPrice));
    } else if (_sortBy == 'Rating') {
      list.sort((a, b) => b.rating.compareTo(a.rating));
    } else {
      list.sort((a, b) => (b.isFeatured ? 1 : 0).compareTo(a.isFeatured ? 1 : 0));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        title: _showSearch
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Search vehicles, brands...',
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              )
            : const Text('Marketplace',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: Icon(_showSearch ? Icons.close : Icons.search,
                color: AppTheme.textPrimary),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchQuery = '';
                _searchController.clear();
              }
            }),
          ),
          IconButton(
            icon: const Icon(Icons.tune_outlined, color: AppTheme.textPrimary),
            onPressed: () => _showFilterSheet(context),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accent,
          indicatorWeight: 3,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [
            Tab(text: '🛒  Buy'),
            Tab(text: '🔑  Rent'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter + Sort Row
          _FilterSortBar(
            fuelFilter: _fuelFilter,
            sortBy: _sortBy,
            onFuelChange: (v) => setState(() => _fuelFilter = v),
            onSortChange: (v) => setState(() => _sortBy = v),
          ),
          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(children: [
              Text('${_filtered.length} vehicles found',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
              const Spacer(),
              if (_fuelFilter != 'All')
                GestureDetector(
                  onTap: () => setState(() => _fuelFilter = 'All'),
                  child: const Text('Clear filters',
                      style: TextStyle(color: AppTheme.accent, fontSize: 12)),
                ),
            ]),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _VehicleListView(vehicles: _filtered, mode: 'buy'),
                _VehicleListView(vehicles: _filtered, mode: 'rent'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _FilterSheet(
        currentFuel: _fuelFilter,
        currentSort: _sortBy,
        onApply: (fuel, sort) => setState(() {
          _fuelFilter = fuel;
          _sortBy = sort;
        }),
      ),
    );
  }
}

// ─── Filter Sort Bar ─────────────────────────────────────────────
class _FilterSortBar extends StatelessWidget {
  final String fuelFilter, sortBy;
  final Function(String) onFuelChange, onSortChange;

  const _FilterSortBar({
    required this.fuelFilter, required this.sortBy,
    required this.onFuelChange, required this.onSortChange,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...['All', 'Electric', 'Hybrid', 'Petrol'].map((f) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => onFuelChange(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: fuelFilter == f ? AppTheme.accent : AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: fuelFilter == f ? AppTheme.accent : AppTheme.surface,
                    ),
                  ),
                  child: Row(children: [
                    Text(
                      f == 'Electric' ? '⚡ ' : f == 'Hybrid' ? '🔋 ' : f == 'Petrol' ? '⛽ ' : '',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(f,
                        style: TextStyle(
                          color: fuelFilter == f ? AppTheme.primary : AppTheme.textSecondary,
                          fontWeight: FontWeight.w600, fontSize: 13,
                        )),
                  ]),
                ),
              ),
            )),
            const SizedBox(width: 8),
            // Sort button
            GestureDetector(
              onTap: () {
                const sorts = ['Featured', 'Price: Low', 'Rating'];
                final idx = sorts.indexOf(sortBy);
                onSortChange(sorts[(idx + 1) % sorts.length]);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  const Icon(Icons.sort, color: AppTheme.textSecondary, size: 16),
                  const SizedBox(width: 6),
                  Text(sortBy,
                      style: const TextStyle(color: AppTheme.textSecondary,
                          fontWeight: FontWeight.w500, fontSize: 13)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Vehicle List ────────────────────────────────────────────────
class _VehicleListView extends StatelessWidget {
  final List<Vehicle> vehicles;
  final String mode;

  const _VehicleListView({required this.vehicles, required this.mode});

  @override
  Widget build(BuildContext context) {
    if (vehicles.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🚗', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          const Text('No vehicles found',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Try changing your filters',
              style: TextStyle(color: AppTheme.textSecondary)),
        ]),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: vehicles.length,
      itemBuilder: (context, i) => _VehicleCard(vehicle: vehicles[i], mode: mode),
    );
  }
}

// ─── Vehicle Card ────────────────────────────────────────────────
class _VehicleCard extends StatelessWidget {
  final Vehicle vehicle;
  final String mode;

  const _VehicleCard({required this.vehicle, required this.mode});

  @override
  Widget build(BuildContext context) {
    final color = vehicle.accentColor;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: vehicle, mode: mode)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: vehicle.isFeatured
              ? Border.all(color: color.withValues(alpha: 0.35), width: 1.5)
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Stack(
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.08), color.withValues(alpha: 0.18)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Stack(
                    children: [
                      // Grid lines for depth
                      Positioned.fill(
                        child: CustomPaint(painter: _GridPainter(color: color)),
                      ),
                      // Car icon
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              vehicle.type == 'SUV' ? Icons.directions_car :
                              vehicle.type == 'Luxury Sedan' ? Icons.local_taxi :
                              Icons.directions_car_filled,
                              color: color.withValues(alpha: 0.7),
                              size: 90,
                            ),
                            const SizedBox(height: 4),
                            Text(vehicle.color,
                                style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Featured badge
                if (vehicle.isFeatured)
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(children: [
                        Icon(Icons.star, color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text('Featured', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ),
                // Availability
                Positioned(
                  top: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: vehicle.isAvailable
                          ? AppTheme.success.withValues(alpha: 0.15)
                          : AppTheme.danger.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: vehicle.isAvailable
                            ? AppTheme.success.withValues(alpha: 0.4)
                            : AppTheme.danger.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(children: [
                      Container(
                        width: 6, height: 6,
                        decoration: BoxDecoration(
                          color: vehicle.isAvailable ? AppTheme.success : AppTheme.danger,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        vehicle.isAvailable ? 'Available' : 'Unavailable',
                        style: TextStyle(
                          color: vehicle.isAvailable ? AppTheme.success : AppTheme.danger,
                          fontSize: 11, fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                  ),
                ),
                // Favorite
                Positioned(
                  bottom: 12, right: 12,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border, color: AppTheme.textSecondary, size: 18),
                  ),
                ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(vehicle.brand,
                                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                            const SizedBox(height: 2),
                            Text(vehicle.name,
                                style: const TextStyle(
                                    color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                            Text('${vehicle.year} · ${vehicle.type}',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            mode == 'buy' ? vehicle.buyPrice : vehicle.rentPriceDay,
                            style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                          if (mode == 'rent')
                            Text(vehicle.rentPriceWeek,
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Specs row
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.cardBg,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _SpecItem(icon: Icons.bolt_outlined, label: vehicle.range, sublabel: 'Range', color: color),
                        _Divider(),
                        _SpecItem(icon: Icons.event_seat_outlined, label: vehicle.seats, sublabel: 'Seats', color: color),
                        _Divider(),
                        _SpecItem(icon: Icons.speed_outlined, label: vehicle.power, sublabel: 'Power', color: color),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Rating + Reviews
                  Row(children: [
                    ...List.generate(5, (i) => Icon(
                      i < vehicle.rating.floor() ? Icons.star : Icons.star_border,
                      color: AppTheme.gold, size: 14,
                    )),
                    const SizedBox(width: 6),
                    Text(vehicle.rating.toStringAsFixed(1),
                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(width: 4),
                    Text('(${vehicle.reviews} reviews)',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const Spacer(),
                    // Fuel type badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(vehicle.fuelType,
                          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                  const SizedBox(height: 14),
                  // Action buttons
                  Row(children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => VehicleDetailScreen(vehicle: vehicle, mode: mode)),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: color.withValues(alpha: 0.4)),
                          foregroundColor: color,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text('Details', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: vehicle.isAvailable
                            ? () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) =>
                                    mode == 'rent'
                                        ? RentBookingScreen(vehicle: vehicle)
                                        : const PaymentScreen()))
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: AppTheme.primary,
                          disabledBackgroundColor: AppTheme.cardBg,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: Text(
                          vehicle.isAvailable
                              ? (mode == 'buy' ? 'Buy Now' : 'Rent Now')
                              : 'Unavailable',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecItem extends StatelessWidget {
  final IconData icon;
  final String label, sublabel;
  final Color color;

  const _SpecItem({required this.icon, required this.label, required this.sublabel, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
      Text(sublabel, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
    ]);
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 36, color: AppTheme.primary.withValues(alpha: 0.5));
}

// ─── Filter Sheet ─────────────────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final String currentFuel, currentSort;
  final Function(String, String) onApply;

  const _FilterSheet({required this.currentFuel, required this.currentSort, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _fuel, _sort;

  @override
  void initState() {
    super.initState();
    _fuel = widget.currentFuel;
    _sort = widget.currentSort;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Filters', style: TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
            const Spacer(),
            TextButton(onPressed: () => setState(() { _fuel = 'All'; _sort = 'Featured'; }),
                child: const Text('Reset', style: TextStyle(color: AppTheme.accent))),
          ]),
          const SizedBox(height: 16),
          const Text('Fuel Type', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: ['All', 'Electric', 'Hybrid', 'Petrol'].map((f) =>
            GestureDetector(
              onTap: () => setState(() => _fuel = f),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _fuel == f ? AppTheme.accent : AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(f, style: TextStyle(color: _fuel == f ? AppTheme.primary : AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              ),
            )
          ).toList()),
          const SizedBox(height: 16),
          const Text('Sort By', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: ['Featured', 'Price: Low', 'Rating'].map((s) =>
            GestureDetector(
              onTap: () => setState(() => _sort = s),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _sort == s ? AppTheme.accent : AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(s, style: TextStyle(color: _sort == s ? AppTheme.primary : AppTheme.textSecondary, fontWeight: FontWeight.w600)),
              ),
            )
          ).toList()),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () { widget.onApply(_fuel, _sort); Navigator.pop(context); },
              child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Vehicle Detail Screen ───────────────────────────────────────
class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;
  final String mode;

  const VehicleDetailScreen({super.key, required this.vehicle, required this.mode});

  @override
  State<VehicleDetailScreen> createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  bool _isFav = false;
  int _imgIndex = 0;
  late final PageController _pageController;

  static const _views = [
    {'icon': Icons.directions_car_filled, 'label': 'Front View'},
    {'icon': Icons.directions_car,        'label': 'Side View'},
    {'icon': Icons.airport_shuttle,       'label': 'Interior'},
  ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vehicle;
    final color = v.accentColor;

    return Scaffold(
      backgroundColor: AppTheme.primary,
      // Standard AppBar — Flutter adds the back button automatically
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
        title: Text(
          v.name,
          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFav ? Icons.favorite : Icons.favorite_border,
              color: _isFav ? AppTheme.danger : AppTheme.textPrimary,
            ),
            onPressed: () => setState(() => _isFav = !_isFav),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image carousel ──────────────────────────────────────
            SizedBox(
              height: 260,
              child: Stack(children: [
                PageView.builder(
                  controller: _pageController,
                  itemCount: _views.length,
                  onPageChanged: (i) => setState(() => _imgIndex = i),
                  itemBuilder: (_, i) {
                    final view = _views[i];
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.08 + i * 0.04),
                            color.withValues(alpha: 0.20 + i * 0.04),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(children: [
                        Positioned.fill(child: CustomPaint(painter: _GridPainter(color: color))),
                        Center(
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(view['icon'] as IconData, color: color.withValues(alpha: 0.8), size: 130),
                            const SizedBox(height: 8),
                            Text(
                              view['label'] as String,
                              style: TextStyle(color: color.withValues(alpha: 0.6), fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                          ]),
                        ),
                      ]),
                    );
                  },
                ),
                // Pagination dots
                Positioned(
                  bottom: 14, left: 0, right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_views.length, (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _imgIndex == i ? 20 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: _imgIndex == i ? color : color.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    )),
                  ),
                ),
                // Photo counter
                Positioned(
                  top: 10, right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_imgIndex + 1} / ${_views.length}',
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ]),
            ),

            // ── Detail content ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(v.brand, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
                      Text(v.name,
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 22, fontWeight: FontWeight.w800)),
                      Text('${v.year} · ${v.type} · ${v.color}',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    ])),
                    const SizedBox(width: 8),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(
                        widget.mode == 'buy' ? v.buyPrice : v.rentPriceDay,
                        style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800),
                      ),
                      if (widget.mode == 'rent')
                        Text(v.rentPriceWeek,
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                    ]),
                  ]),
                  const SizedBox(height: 14),

                  // Rating + badges
                  Row(children: [
                    ...List.generate(5, (i) => Icon(
                      i < v.rating.floor() ? Icons.star : Icons.star_border,
                      color: AppTheme.gold, size: 15)),
                    const SizedBox(width: 6),
                    Text(v.rating.toStringAsFixed(1),
                        style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
                    Text('  ·  ${v.reviews} reviews',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const Spacer(),
                    StatusBadge(label: v.fuelType, color: color),
                    const SizedBox(width: 6),
                    StatusBadge(
                      label: v.isAvailable ? 'Available' : 'Unavailable',
                      color: v.isAvailable ? AppTheme.success : AppTheme.danger,
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // Spec cards (2×2 grid)
                  const SectionHeader(title: 'Specifications'),
                  const SizedBox(height: 12),
                  Row(children: [
                    Expanded(child: _SpecCard(icon: Icons.bolt,       label: 'Range',   value: v.range,   color: color)),
                    const SizedBox(width: 10),
                    Expanded(child: _SpecCard(icon: Icons.event_seat, label: 'Seats',   value: v.seats,   color: color)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _SpecCard(icon: Icons.speed,      label: 'Power',   value: v.power,   color: color)),
                    const SizedBox(width: 10),
                    Expanded(child: _SpecCard(icon: Icons.drive_eta,  label: 'Mileage', value: v.mileage, color: color)),
                  ]),
                  const SizedBox(height: 20),

                  // Features
                  const SectionHeader(title: 'Features'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: v.features.map((f) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.3)),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.check_circle_outline, color: color, size: 14),
                        const SizedBox(width: 5),
                        Text(f, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500)),
                      ]),
                    )).toList(),
                  ),
                  const SizedBox(height: 20),

                  // About
                  const SectionHeader(title: 'About this vehicle'),
                  const SizedBox(height: 10),
                  Text(
                    'The ${v.brand} ${v.name} (${v.year}) is a cutting-edge ${v.fuelType.toLowerCase()} vehicle '
                    'with an impressive range of ${v.range} and ${v.power} of power. '
                    'Perfect for both daily commutes and long trips, it combines '
                    'luxury with performance. Currently showing ${v.mileage} on the odometer.',
                    style: const TextStyle(color: AppTheme.textSecondary, height: 1.6, fontSize: 13),
                  ),
                  const SizedBox(height: 20),

                  // Seller info
                  const SectionHeader(title: 'Seller Info'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.2), radius: 24,
                        child: Text(v.brand[0],
                            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('${v.brand} Official Dealer',
                            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
                        const Text('Phnom Penh · Verified Seller',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        Row(children: [
                          const Icon(Icons.star, color: AppTheme.gold, size: 14),
                          const SizedBox(width: 4),
                          const Text('4.9 · 500+ sales',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                        ]),
                      ])),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(Icons.chat_outlined, color: color, size: 20),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 24),

                  // Primary CTA button (inline — no floating bar needed)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: v.isAvailable
                          ? () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => widget.mode == 'rent'
                                      ? RentBookingScreen(vehicle: v)
                                      : const PaymentScreen()))
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: AppTheme.primary,
                        disabledBackgroundColor: AppTheme.cardBg,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        v.isAvailable
                            ? (widget.mode == 'buy' ? '🛒  Proceed to Buy  ·  ${v.buyPrice}' : '🔑  Book Rental  ·  ${v.rentPriceDay}')
                            : 'Currently Unavailable',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;

  const _SpecCard({required this.icon, required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 13)),
          Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 10)),
        ]),
      ]),
    );
  }
}

// ─── Rent Booking Screen ─────────────────────────────────────────
class RentBookingScreen extends StatefulWidget {
  final Vehicle vehicle;

  const RentBookingScreen({super.key, required this.vehicle});

  @override
  State<RentBookingScreen> createState() => _RentBookingScreenState();
}

class _RentBookingScreenState extends State<RentBookingScreen> {
  DateTime _pickupDate = DateTime.now().add(const Duration(days: 1));
  DateTime _returnDate = DateTime.now().add(const Duration(days: 4));
  String _pickupLocation = 'Phnom Penh City Center';
  bool _withDriver = false;
  bool _includeInsurance = true;

  int get _days => _returnDate.difference(_pickupDate).inDays;

  double get _subtotal {
    final rate = double.tryParse(
      widget.vehicle.rentPriceDay.replaceAll(RegExp(r'[^\d.]'), ''),
    ) ?? 0;
    return rate * _days;
  }

  double get _insurance => _includeInsurance ? _days * 8.0 : 0;
  double get _driverFee => _withDriver ? _days * 25.0 : 0;
  double get _total => _subtotal + _insurance + _driverFee;

  @override
  Widget build(BuildContext context) {
    final color = widget.vehicle.accentColor;
    return Scaffold(
      appBar: AppBar(title: Text('Rent ${widget.vehicle.brand} ${widget.vehicle.name.split(' ').first}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vehicle mini card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.directions_car_filled, color: color, size: 36),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.vehicle.brand, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(widget.vehicle.name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                  Text('${widget.vehicle.fuelType} · ${widget.vehicle.seats} seats',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                ])),
                Text(widget.vehicle.rentPriceDay,
                    style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16)),
              ]),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Rental Dates'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _DatePickerCard(
                label: 'Pickup',
                date: _pickupDate,
                icon: Icons.calendar_today_outlined,
                color: color,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _pickupDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    builder: (c, child) => Theme(data: ThemeData.dark().copyWith(
                        colorScheme: ColorScheme.dark(primary: color)), child: child!),
                  );
                  if (d != null) setState(() { _pickupDate = d; if (_returnDate.isBefore(d.add(const Duration(days: 1)))) _returnDate = d.add(const Duration(days: 1)); });
                },
              )),
              const SizedBox(width: 12),
              Expanded(child: _DatePickerCard(
                label: 'Return',
                date: _returnDate,
                icon: Icons.event_outlined,
                color: color,
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _returnDate,
                    firstDate: _pickupDate.add(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                    builder: (c, child) => Theme(data: ThemeData.dark().copyWith(
                        colorScheme: ColorScheme.dark(primary: color)), child: child!),
                  );
                  if (d != null) setState(() => _returnDate = d);
                },
              )),
            ]),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.access_time, color: color, size: 16),
                const SizedBox(width: 6),
                Text('$_days day${_days == 1 ? '' : 's'} rental',
                    style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Text('= ${widget.vehicle.rentPriceDay.replaceAll('/day', '')} × $_days',
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
              ]),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Pickup Location'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                ...[
                  'Phnom Penh City Center',
                  'Phnom Penh International Airport',
                  'AEON Mall Sen Sok',
                ].map((loc) => GestureDetector(
                  onTap: () => setState(() => _pickupLocation = loc),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(children: [
                      Icon(
                        _pickupLocation == loc ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: _pickupLocation == loc ? color : AppTheme.textSecondary, size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(loc,
                          style: TextStyle(
                            color: _pickupLocation == loc ? AppTheme.textPrimary : AppTheme.textSecondary,
                            fontSize: 13,
                          ))),
                    ]),
                  ),
                )),
              ]),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Add-ons'),
            const SizedBox(height: 12),
            _AddonToggle(
              icon: Icons.security_outlined,
              title: 'Full Insurance Coverage',
              subtitle: '\$8/day — Covers all damages',
              value: _includeInsurance,
              color: AppTheme.success,
              onChanged: (v) => setState(() => _includeInsurance = v),
            ),
            _AddonToggle(
              icon: Icons.person_outlined,
              title: 'With Professional Driver',
              subtitle: '\$25/day — Includes fuel',
              value: _withDriver,
              color: color,
              onChanged: (v) => setState(() => _withDriver = v),
            ),
            const SizedBox(height: 20),
            // Price breakdown
            const SectionHeader(title: 'Price Breakdown'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                _PriceRow('${widget.vehicle.rentPriceDay} × $_days days',
                    '\$${_subtotal.toStringAsFixed(0)}'),
                if (_includeInsurance) _PriceRow('Insurance (\$8 × $_days)', '\$${_insurance.toStringAsFixed(0)}'),
                if (_withDriver) _PriceRow('Driver fee (\$25 × $_days)', '\$${_driverFee.toStringAsFixed(0)}'),
                _PriceRow('Service fee (5%)', '\$${(_total * 0.05).toStringAsFixed(0)}'),
                const Divider(color: AppTheme.cardBg, height: 24),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Total', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w800)),
                  Text('\$${(_total * 1.05).toStringAsFixed(0)}',
                      style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
                ]),
              ]),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: '🔑  Confirm Rental — \$${(_total * 1.05).toStringAsFixed(0)}',
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentScreen())),
              color: color,
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text('Free cancellation up to 24h before pickup',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _DatePickerCard extends StatelessWidget {
  final String label;
  final DateTime date;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _DatePickerCard({required this.label, required this.date, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ]),
          const SizedBox(height: 6),
          Text('${date.day}/${date.month}/${date.year}',
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
      ),
    );
  }
}

class _AddonToggle extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final Color color;
  final Function(bool) onChanged;

  const _AddonToggle({required this.icon, required this.title, required this.subtitle, required this.value, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: value ? Border.all(color: color.withValues(alpha: 0.4)) : null,
      ),
      child: Row(children: [
        Container(padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
          Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ])),
        Switch(value: value, onChanged: onChanged, activeColor: color),
      ]),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label, amount;

  const _PriceRow(this.label, this.amount);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Text(amount, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500, fontSize: 13)),
      ]),
    );
  }
}

// ─── Grid Painter ────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final Color color;

  _GridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
