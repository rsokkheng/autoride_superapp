import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class CarRentalScreen extends StatefulWidget {
  const CarRentalScreen({super.key});

  @override
  State<CarRentalScreen> createState() => _CarRentalScreenState();
}

class _CarRentalScreenState extends State<CarRentalScreen> {
  final _locationCtrl = TextEditingController();
  DateTime _pickupDate  = DateTime.now().add(const Duration(hours: 2));
  DateTime _returnDate  = DateTime.now().add(const Duration(days: 1, hours: 2));
  String _selectedCategory = 'economy';
  bool _withDriver = true;
  bool _booking = false;
  String? _bookError;

  static const _categories = [
    _VehicleCategory('economy',  'Economy',  Icons.directions_car_outlined,  60000),
    _VehicleCategory('standard', 'Standard', Icons.directions_car,            80000),
    _VehicleCategory('suv',      'SUV',      Icons.airport_shuttle,          120000),
    _VehicleCategory('luxury',   'Luxury',   Icons.star_outline,             200000),
  ];

  @override
  void dispose() {
    _locationCtrl.dispose();
    super.dispose();
  }

  int get _totalDays {
    final diff = _returnDate.difference(_pickupDate);
    return diff.inDays.clamp(1, 365);
  }

  int get _ratePerDay {
    final cat = _categories.firstWhere(
      (c) => c.id == _selectedCategory,
      orElse: () => _categories.first,
    );
    return cat.pricePerDay;
  }

  int get _totalPrice => _totalDays * _ratePerDay;

  Future<void> _pickDate(bool isPickup) async {
    final initial = isPickup ? _pickupDate : _returnDate;
    final firstDate = isPickup ? DateTime.now() : _pickupDate.add(const Duration(days: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(primary: AppTheme.accent),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (!mounted) return;
    final combined = DateTime(
      date.year, date.month, date.day,
      time?.hour ?? initial.hour, time?.minute ?? initial.minute,
    );
    setState(() {
      if (isPickup) {
        _pickupDate = combined;
        if (_returnDate.isBefore(_pickupDate.add(const Duration(hours: 1)))) {
          _returnDate = _pickupDate.add(const Duration(days: 1));
        }
      } else {
        _returnDate = combined;
      }
    });
  }

  String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final h   = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}  ${h.toString().padLeft(2, '0')}:$min $ampm';
  }

  Future<void> _bookNow() async {
    if (_locationCtrl.text.trim().isEmpty) {
      setState(() => _bookError = 'Please enter a pickup location.');
      return;
    }
    setState(() { _booking = true; _bookError = null; });
    try {
      await ApiService.createCarRental(
        pickupLocation: _locationCtrl.text.trim(),
        pickupDate: _pickupDate,
        returnDate: _returnDate,
        vehicleCategory: _selectedCategory,
        withDriver: _withDriver,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Rental booked successfully!'),
          backgroundColor: AppTheme.success,
        ),
      );
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() { _bookError = e.message; _booking = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _bookError = e.toString(); _booking = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(title: const Text('Car Rental')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionTitle('Pickup Location'),
          const SizedBox(height: 8),
          TextField(
            controller: _locationCtrl,
            decoration: const InputDecoration(
              hintText: 'Enter pickup address',
              prefixIcon: Icon(Icons.location_on_outlined, color: AppTheme.accent),
            ),
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Pickup Date & Time'),
          const SizedBox(height: 8),
          _DateTile(
            label: _formatDateTime(_pickupDate),
            icon: Icons.calendar_today_outlined,
            onTap: () => _pickDate(true),
          ),
          const SizedBox(height: 12),
          _sectionTitle('Return Date & Time'),
          const SizedBox(height: 8),
          _DateTile(
            label: _formatDateTime(_returnDate),
            icon: Icons.event_available_outlined,
            onTap: () => _pickDate(false),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Vehicle Category'),
          const SizedBox(height: 10),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: _categories.map((cat) {
              final selected = _selectedCategory == cat.id;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = cat.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.accent.withValues(alpha: 0.1) : AppTheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selected ? AppTheme.accent : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(cat.icon,
                          color: selected ? AppTheme.accent : AppTheme.textSecondary, size: 28),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(cat.label,
                            style: TextStyle(
                              color: selected ? AppTheme.accent : AppTheme.textPrimary,
                              fontWeight: FontWeight.w700, fontSize: 13,
                            )),
                        Text('${AppTheme.khr(cat.pricePerDay)}/day',
                            style: const TextStyle(
                                color: AppTheme.textSecondary, fontSize: 11)),
                      ]),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          _sectionTitle('Driver Option'),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Expanded(child: _DriverToggle(
                label: 'With Driver',
                icon: Icons.person_outline,
                selected: _withDriver,
                onTap: () => setState(() => _withDriver = true),
              )),
              Expanded(child: _DriverToggle(
                label: 'Self Drive',
                icon: Icons.drive_eta_outlined,
                selected: !_withDriver,
                onTap: () => setState(() => _withDriver = false),
              )),
            ]),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(children: [
              const Text('Booking Summary',
                  style: TextStyle(color: AppTheme.textPrimary,
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              _SummaryRow('Duration', '$_totalDays day${_totalDays > 1 ? 's' : ''}'),
              const SizedBox(height: 6),
              _SummaryRow('Rate', '${AppTheme.khr(_ratePerDay)}/day'),
              const Divider(color: AppTheme.cardBg, height: 20),
              Row(children: [
                const Text('Total',
                    style: TextStyle(color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                Text(AppTheme.khr(_totalPrice),
                    style: const TextStyle(color: AppTheme.accent,
                        fontWeight: FontWeight.w900, fontSize: 20)),
              ]),
            ]),
          ),
          if (_bookError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                const Icon(Icons.error_outline, color: AppTheme.danger, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(_bookError!,
                    style: const TextStyle(color: AppTheme.danger, fontSize: 12))),
              ]),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _booking ? null : _bookNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _booking
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                  : const Text('Book Now',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _sectionTitle(String title) => Text(title,
      style: const TextStyle(color: AppTheme.textPrimary,
          fontSize: 14, fontWeight: FontWeight.w600));
}

class _VehicleCategory {
  final String id;
  final String label;
  final IconData icon;
  final int pricePerDay;
  const _VehicleCategory(this.id, this.label, this.icon, this.pricePerDay);
}

class _DateTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _DateTile({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(children: [
          Icon(icon, color: AppTheme.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label,
              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500))),
          const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 18),
        ]),
      ),
    );
  }
}

class _DriverToggle extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _DriverToggle({required this.label, required this.icon,
      required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: selected ? Colors.white : AppTheme.textSecondary, size: 22),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                color: selected ? Colors.white : AppTheme.textSecondary,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13,
              )),
        ]),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
      const Spacer(),
      Text(value, style: const TextStyle(color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600, fontSize: 14)),
    ]);
  }
}
