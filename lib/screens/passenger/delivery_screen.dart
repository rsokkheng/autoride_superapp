import 'dart:async';
import 'package:flutter/material.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:autoride_superapp/widgets/common_widgets.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';
import '../../models/delivery_model.dart' show MovingEstimateModel;
import '../../services/maps_service.dart';
import 'delivery_tracking_screen.dart';

const _kPickerSW     = LatLng(10.4, 102.3);
const _kPickerNE     = LatLng(14.7, 107.6);
final  _kPickerBounds = LatLngBounds(southwest: _kPickerSW, northeast: _kPickerNE);

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  // ── Mode ─────────────────────────────────────────────────────────────────
  String _mode = 'delivery'; // 'delivery' | 'moving'

  // ── Delivery fields ──────────────────────────────────────────────────────
  final _senderNameCtrl      = TextEditingController();
  final _senderPhoneCtrl     = TextEditingController();
  final _pickupCtrl          = TextEditingController();
  final _recipientNameCtrl   = TextEditingController();
  final _recipientPhoneCtrl  = TextEditingController();
  final _dropoffCtrl         = TextEditingController();
  final _packageDetailsCtrl  = TextEditingController();
  final _feeCtrl             = TextEditingController();
  final _notesCtrl           = TextEditingController();
  final _delivPartnerCodeCtrl = TextEditingController();

  bool     _isScheduled          = false;
  String   _packageSize          = 'small';
  String   _deliveryServiceOption = 'normal'; // 'normal' | 'express'
  String   _deliveryVehicleType  = 'car'; // 'car'|'tuk_tuk'
  String   _paymentBy            = 'sender';
  String   _paymentMethod        = 'cash';
  DateTime _scheduledTime        = DateTime.now().add(const Duration(hours: 2));

  // ── Moving fields ────────────────────────────────────────────────────────
  final _moveFromCtrl  = TextEditingController();
  final _moveToCtrl    = TextEditingController();
  final _moveNotesCtrl = TextEditingController();

  String   _moveType            = 'home';   // 'home' | 'office'
  String   _movingServiceOption  = 'normal'; // 'normal' | 'express'
  String   _propertySize        = 'studio';
  int      _floorPickup         = 1;
  int      _floorDropoff      = 1;
  bool     _hasElevator       = true;
  bool     _needsStairsCarry  = false;
  bool     _heavyItems        = false;
  bool     _packingService    = false;
  int      _requiresHelpers   = 1;        // 1–4
  String   _movePaymentMethod = 'cash';
  bool     _isMoveScheduled   = false;
  DateTime _moveDate          = DateTime.now().add(const Duration(days: 1));

  // ── Location lat/lng (from map picker) ──────────────────────────────────
  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;
  LatLng? _moveFromLatLng;
  LatLng? _moveToLatLng;

  // ── Moving fare estimate (from API) ─────────────────────────────────────
  MovingEstimateModel? _movingEstimate;
  bool    _estimateLoading = false;

  // ── Shared ───────────────────────────────────────────────────────────────
  bool    _submitting = false;
  String? _error;

  @override
  void dispose() {
    _senderNameCtrl.dispose();
    _senderPhoneCtrl.dispose();
    _pickupCtrl.dispose();
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _dropoffCtrl.dispose();
    _packageDetailsCtrl.dispose();
    _feeCtrl.dispose();
    _notesCtrl.dispose();
    _delivPartnerCodeCtrl.dispose();
    _moveFromCtrl.dispose();
    _moveToCtrl.dispose();
    _moveNotesCtrl.dispose();
    super.dispose();
  }

  // ── Submit delivery ──────────────────────────────────────────────────────

  Future<void> _submitDelivery() async {
    final pickup  = _pickupCtrl.text.trim();
    final dropoff = _dropoffCtrl.text.trim();
    if (pickup.isEmpty || dropoff.isEmpty) {
      setState(() => _error = 'Pickup and delivery address are required.');
      return;
    }

    // ── Confirmation dialog ──────────────────────────────────────────────
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DeliveryConfirmDialog(
        pickupAddress:  pickup,
        dropoffAddress: dropoff,
        senderName:     _senderNameCtrl.text.trim().isEmpty    ? null : _senderNameCtrl.text.trim(),
        senderPhone:    _senderPhoneCtrl.text.trim().isEmpty   ? null : _senderPhoneCtrl.text.trim(),
        recipientName:  _recipientNameCtrl.text.trim().isEmpty ? null : _recipientNameCtrl.text.trim(),
        recipientPhone: _recipientPhoneCtrl.text.trim().isEmpty? null : _recipientPhoneCtrl.text.trim(),
        packageDetails: _packageDetailsCtrl.text.trim().isEmpty
            ? 'No description'
            : _packageDetailsCtrl.text.trim(),
        packageSize:    _packageSize,
        serviceOption:  _deliveryServiceOption,
        paymentBy:      _paymentBy,
        paymentMethod:  _paymentMethod,
        fee:            int.tryParse(_feeCtrl.text.trim()),
        scheduledAt:    _isScheduled ? _scheduledTime : null,
        notes:          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() { _submitting = true; _error = null; });
    try {
      final created = await ApiService.createDelivery(
        pickupAddress:  pickup,
        dropoffAddress: dropoff,
        packageDetails: _packageDetailsCtrl.text.trim().isEmpty
            ? 'No description'
            : _packageDetailsCtrl.text.trim(),
        senderName:     _senderNameCtrl.text.trim().isEmpty     ? null : _senderNameCtrl.text.trim(),
        senderPhone:    _senderPhoneCtrl.text.trim().isEmpty    ? null : _senderPhoneCtrl.text.trim(),
        recipientName:  _recipientNameCtrl.text.trim().isEmpty  ? null : _recipientNameCtrl.text.trim(),
        recipientPhone: _recipientPhoneCtrl.text.trim().isEmpty ? null : _recipientPhoneCtrl.text.trim(),
        packageSize:    _packageSize,
        fee:            int.tryParse(_feeCtrl.text.trim()),
        paymentBy:      _paymentBy,
        paymentMethod:  _paymentMethod,
        serviceOption:  _deliveryServiceOption,
        notes:          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        scheduledAt:    _isScheduled ? _formatDateTime(_scheduledTime) : null,
      );
      if (!mounted) return;
      final recipientName = _recipientNameCtrl.text.trim();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DeliveryTrackingScreen(
            deliveryId:    created.id,
            from:          pickup,
            to:            dropoff,
            fareDisplay:   AppTheme.khr(created.fee),
            serviceType:   'delivery',
            recipientName: recipientName.isEmpty ? 'Recipient' : recipientName,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Submit moving ────────────────────────────────────────────────────────

  Future<void> _submitMoving() async {
    final from = _moveFromCtrl.text.trim();
    final to   = _moveToCtrl.text.trim();
    if (from.isEmpty || to.isEmpty) {
      setState(() => _error = 'From and To addresses are required.');
      return;
    }

    // ── Confirmation dialog ──────────────────────────────────────────────
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _MovingConfirmDialog(
        from:           from,
        to:             to,
        floorPickup:    _floorPickup,
        floorDropoff:   _floorDropoff,
        hasElevator:    _hasElevator,
        requiresHelpers: _requiresHelpers,
        heavyItems:     _heavyItems,
        serviceOption:  _movingServiceOption,
        paymentMethod:  _movePaymentMethod,
        estimate:       _movingEstimate,
        scheduledAt:    _isMoveScheduled ? _moveDate : null,
        notes:          _moveNotesCtrl.text.trim().isEmpty
                            ? null
                            : _moveNotesCtrl.text.trim(),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() { _submitting = true; _error = null; });
    try {
      final createdMoving = await ApiService.createMoving(
        pickupAddress:    from,
        dropoffAddress:   to,
        pickupLat:        _moveFromLatLng?.latitude,
        pickupLng:        _moveFromLatLng?.longitude,
        dropoffLat:       _moveToLatLng?.latitude,
        dropoffLng:       _moveToLatLng?.longitude,
        floorPickup:      _floorPickup,
        floorDropoff:     _floorDropoff,
        hasElevator:      _hasElevator,
        needsStairsCarry: _needsStairsCarry,
        heavyItems:       _heavyItems,
        requiresHelpers:  _requiresHelpers,
        helperType:       _heavyItems ? 'heavy_carry' : 'normal_carry',
        serviceOption:    _movingServiceOption,
        paymentMethod:    _movePaymentMethod,
        fee:              _movingEstimate?.total,
        notes:            _moveNotesCtrl.text.trim().isEmpty
                              ? null
                              : _moveNotesCtrl.text.trim(),
        scheduledAt:      _isMoveScheduled ? _formatDateTime(_moveDate) : null,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => DeliveryTrackingScreen(
            deliveryId:    createdMoving.id,
            from:          from,
            to:            to,
            fareDisplay:   _movingEstimate != null
                ? AppTheme.khr(_movingEstimate!.total)
                : AppTheme.khr(createdMoving.fee),
            serviceType:   'moving',
            recipientName: 'Moving crew',
          ),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Moving fare estimate (real API) ──────────────────────────────────────

  Future<void> _fetchMovingEstimate() async {
    final from = _moveFromLatLng;
    final to   = _moveToLatLng;
    if (from == null || to == null) return;

    setState(() { _estimateLoading = true; });
    try {
      final est = await ApiService.estimateMoving(
        pickupLat:      from.latitude,
        pickupLng:      from.longitude,
        dropoffLat:     to.latitude,
        dropoffLng:     to.longitude,
        floorPickup:    _floorPickup,
        floorDropoff:   _floorDropoff,
        hasElevator:    _hasElevator,
        requiresHelpers: _requiresHelpers,
        helperType:     _heavyItems ? 'heavy_carry' : 'normal_carry',
        serviceOption:  _movingServiceOption,
      );
      if (!mounted) return;
      setState(() { _movingEstimate = est; _estimateLoading = false; });
    } catch (e) {
      if (mounted) {
        setState(() { _estimateLoading = false; });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not fetch estimate: ${e is ApiException ? e.message : e.toString()}'),
          backgroundColor: AppTheme.danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _formatDateTime(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')} '
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}:00';

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Future<void> _pickDeliverySchedule() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledTime,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_scheduledTime),
    );
    if (time == null) return;
    setState(() {
      _scheduledTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _pickMoveDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _moveDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_moveDate),
    );
    if (time == null) return;
    setState(() {
      _moveDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  // ── Map picker ───────────────────────────────────────────────────────────

  static const _kDefaultPos = LatLng(11.5680, 104.9195);

  Future<void> _openLocationPicker(
      TextEditingController ctrl,
      LatLng? current,
      ValueChanged<LatLng> onLatLng) async {
    LatLng initial = current ?? _kDefaultPos;
    if (current == null) {
      try {
        final pos = await Geolocator.getLastKnownPosition();
        if (pos != null) {
          final ll = LatLng(pos.latitude, pos.longitude);
          // Only use GPS position if it is actually inside Cambodia
          if (_kPickerBounds.contains(ll)) initial = ll;
        }
      } catch (_) {}
    }
    if (!mounted) return;
    final result = await Navigator.push<_LocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => _LocationPickerScreen(initial: initial),
        fullscreenDialog: true,
      ),
    );
    if (result != null && mounted) {
      ctrl.text = result.address;
      setState(() => onLatLng(result.latLng));
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isDelivery = _mode == 'delivery';
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery & Moving')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Mode toggle ──────────────────────────────────────
                  _ModeToggle(
                    selected: _mode,
                    onChanged: (m) => setState(() { _mode = m; _error = null; }),
                  ),
                  const SizedBox(height: 20),

                  // ── Error banner ─────────────────────────────────────
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.danger.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.danger.withValues(alpha: 0.4)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: AppTheme.danger, size: 18),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13))),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Form ─────────────────────────────────────────────
                  if (isDelivery) _buildDeliveryForm()
                  else            _buildMovingForm(),
                ],
              ),
            ),
          ),

          // ── Sticky bottom button ──────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomPadding),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.15))),
            ),
            child: _SubmitButton(
              label: isDelivery
                  ? (_isScheduled ? 'Schedule Delivery' : 'Send Now')
                  : (_isMoveScheduled ? 'Schedule Moving' : 'Book Moving'),
              icon: isDelivery ? Icons.delivery_dining : Icons.local_shipping,
              loading: _submitting,
              onPressed: isDelivery ? _submitDelivery : _submitMoving,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Delivery form
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildDeliveryForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GradientCard(
        colors: const [Color(0xFF00C48C), Color(0xFF00A37A)],
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Send anything,\nanywhere fast!',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Average delivery: 25 min',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
          ])),
          const Icon(Icons.delivery_dining, color: Colors.white, size: 56),
        ]),
      ),
      const SizedBox(height: 20),

      // Sender
      const SectionHeader(title: 'Sender'),
      const SizedBox(height: 14),
      _Field(hint: "Sender's name",  icon: Icons.person_outline,      controller: _senderNameCtrl),
      const SizedBox(height: 10),
      _Field(hint: "Sender's phone", icon: Icons.phone_outlined,       controller: _senderPhoneCtrl,
          keyboardType: TextInputType.phone),
      const SizedBox(height: 10),
      _AddressWithMap(
        hint: 'Pickup address', icon: Icons.location_on_outlined, controller: _pickupCtrl,
        onMapTap: () => _openLocationPicker(_pickupCtrl, _pickupLatLng, (ll) => _pickupLatLng = ll),
      ),
      const SizedBox(height: 20),

      // Recipient
      const SectionHeader(title: 'Recipient'),
      const SizedBox(height: 14),
      _Field(hint: "Recipient's name",  icon: Icons.person_outline, controller: _recipientNameCtrl),
      const SizedBox(height: 10),
      _Field(hint: "Recipient's phone", icon: Icons.phone_outlined,  controller: _recipientPhoneCtrl,
          keyboardType: TextInputType.phone),
      const SizedBox(height: 10),
      _AddressWithMap(
        hint: 'Delivery address', icon: Icons.location_on, controller: _dropoffCtrl,
        onMapTap: () => _openLocationPicker(_dropoffCtrl, _dropoffLatLng, (ll) => _dropoffLatLng = ll),
      ),
      const SizedBox(height: 20),

      // Package
      const SectionHeader(title: 'Package'),
      const SizedBox(height: 14),
      _Field(hint: 'Package description (optional)', icon: Icons.inventory_2_outlined,
          controller: _packageDetailsCtrl),
      const SizedBox(height: 10),
      _Field(hint: 'Fee in KHR (e.g. 18000)', icon: Icons.attach_money, controller: _feeCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true)),
      const SizedBox(height: 10),
      _Field(hint: 'Notes (optional)', icon: Icons.notes_outlined, controller: _notesCtrl),
      const SizedBox(height: 16),

      // Package size
      _AppDropdown<String>(
        label: 'Package Size',
        icon: Icons.inventory_2_outlined,
        value: _packageSize,
        items: const [
          _DropItem(value: 'small',  label: 'Small',  subtitle: 'Up to 2 kg',   icon: Icons.circle_outlined),
          _DropItem(value: 'medium', label: 'Medium', subtitle: '2 – 10 kg',    icon: Icons.circle_outlined),
          _DropItem(value: 'large',  label: 'Large',  subtitle: '10 kg and above', icon: Icons.circle_outlined),
        ],
        onChanged: (v) => setState(() => _packageSize = v),
      ),
      const SizedBox(height: 12),

      // Service option
      _AppDropdown<String>(
        label: 'Service Option',
        icon: Icons.speed,
        value: _deliveryServiceOption,
        items: const [
          _DropItem(value: 'normal',  label: 'Normal',  subtitle: 'Standard delivery speed', icon: Icons.check_circle_outline),
          _DropItem(value: 'express', label: 'Express', subtitle: 'Faster delivery at higher fee', icon: Icons.flash_on_outlined),
        ],
        onChanged: (v) => setState(() => _deliveryServiceOption = v),
      ),
      const SizedBox(height: 12),

      // Delivery vehicle
      _AppDropdown<String>(
        label: 'Delivery Vehicle',
        icon: Icons.directions_car_outlined,
        value: _deliveryVehicleType,
        items: const [
          _DropItem(value: 'car',     label: 'Car — ឡាន',       subtitle: 'Up to 200 kg  •  Comfortable', icon: Icons.directions_car_outlined),
          _DropItem(value: 'tuk_tuk', label: 'Tuk Tuk — តុកតុក', subtitle: 'Up to 100 kg  •  Affordable',  icon: Icons.electric_rickshaw_outlined),
        ],
        onChanged: (v) => setState(() => _deliveryVehicleType = v),
      ),
      const SizedBox(height: 12),

      // Payment by
      _AppDropdown<String>(
        label: 'Payment By',
        icon: Icons.person_outline,
        value: _paymentBy,
        items: const [
          _DropItem(value: 'sender',    label: 'Sender',    subtitle: 'Pays upfront', icon: Icons.upload_outlined),
          _DropItem(value: 'recipient', label: 'Recipient', subtitle: 'Cash on delivery (COD)', icon: Icons.download_outlined),
        ],
        onChanged: (v) => setState(() => _paymentBy = v),
      ),
      const SizedBox(height: 12),

      // Payment method (always visible, no payment model needed)
      _AppDropdown<String>(
        label: 'Payment Method',
        icon: Icons.wallet_outlined,
        value: _paymentMethod,
        items: const [
          _DropItem(value: 'cash',        label: 'Cash',         subtitle: 'Pay with cash',           icon: Icons.money),
          _DropItem(value: 'wallet',       label: 'ROTEH Wallet', subtitle: 'Pay from wallet balance',  icon: Icons.account_balance_wallet_outlined),
          _DropItem(value: 'aba',          label: 'ABA Pay',      subtitle: 'ABA mobile banking',      icon: Icons.credit_card),
          _DropItem(value: 'wing',         label: 'Wing Money',   subtitle: 'Wing mobile payment',     icon: Icons.send_to_mobile),
          _DropItem(value: 'other_online', label: 'Other Online', subtitle: 'Other online payment',    icon: Icons.language),
        ],
        onChanged: (v) => setState(() => _paymentMethod = v),
      ),
      const SizedBox(height: 20),

      // Schedule toggle
      Row(children: [
        const Text('Schedule delivery',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
        const Spacer(),
        Switch(
          value: _isScheduled,
          onChanged: (v) => setState(() => _isScheduled = v),
          activeThumbColor: AppTheme.accent,
          activeTrackColor: AppTheme.accent.withValues(alpha: 0.4),
        ),
      ]),
      if (_isScheduled) ...[
        const SizedBox(height: 10),
        _DateTimeTile(
          dateTime: _scheduledTime,
          color: AppTheme.accent,
          onTap: _pickDeliverySchedule,
        ),
      ],
      const SizedBox(height: 8),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Moving form
  // ═══════════════════════════════════════════════════════════════════════

  Widget _buildMovingForm() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      GradientCard(
        colors: const [Color(0xFF00C48C), Color(0xFF00A37A)],
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Move with ease,\nwe handle the rest!',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Professional moving service',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
          ])),
          const Icon(Icons.local_shipping, color: Colors.white, size: 56),
        ]),
      ),
      const SizedBox(height: 20),

      // ── Addresses ────────────────────────────────────────────────────────
      const SectionHeader(title: 'Addresses'),
      const SizedBox(height: 14),
      _AddressWithMap(
        hint: 'Moving from (full address)', icon: Icons.location_on_outlined, controller: _moveFromCtrl,
        onMapTap: () => _openLocationPicker(_moveFromCtrl, _moveFromLatLng, (ll) {
          _moveFromLatLng = ll;
          _fetchMovingEstimate();
        }),
      ),
      const SizedBox(height: 10),
      _AddressWithMap(
        hint: 'Moving to (full address)', icon: Icons.location_on, controller: _moveToCtrl,
        onMapTap: () => _openLocationPicker(_moveToCtrl, _moveToLatLng, (ll) {
          _moveToLatLng = ll;
          _fetchMovingEstimate();
        }),
      ),
      const SizedBox(height: 20),

      // ── Move type ─────────────────────────────────────────────────────────
      _AppDropdown<String>(
        label: 'Move Type',
        icon: Icons.local_shipping_outlined,
        value: _moveType,
        items: const [
          _DropItem(value: 'home',   label: 'Home Move',   subtitle: 'Residential moving',          icon: Icons.home_outlined),
          _DropItem(value: 'office', label: 'Office Move', subtitle: 'Commercial / office moving',  icon: Icons.business_outlined),
        ],
        onChanged: (v) => setState(() => _moveType = v),
      ),
      const SizedBox(height: 12),

      _AppDropdown<String>(
        label: 'Service Option',
        icon: Icons.speed,
        value: _movingServiceOption,
        items: const [
          _DropItem(value: 'normal',  label: 'Normal',  subtitle: 'Standard moving service', icon: Icons.check_circle_outline),
          _DropItem(value: 'express', label: 'Express', subtitle: 'Priority moving service', icon: Icons.flash_on_outlined),
        ],
        onChanged: (v) {
          setState(() => _movingServiceOption = v);
          _fetchMovingEstimate();
        },
      ),
      const SizedBox(height: 12),

      // ── Property size ─────────────────────────────────────────────────────
      _AppDropdown<String>(
        label: 'Property Size',
        icon: Icons.home_work_outlined,
        value: _propertySize,
        items: const [
          _DropItem(value: 'studio', label: 'Studio / 1 Room', subtitle: 'Small space',        icon: Icons.meeting_room_outlined),
          _DropItem(value: '1br',    label: '1 Bedroom',        subtitle: 'Medium apartment',   icon: Icons.bed_outlined),
          _DropItem(value: '2br',    label: '2 Bedrooms',       subtitle: 'Larger apartment',   icon: Icons.bedroom_parent_outlined),
          _DropItem(value: '3br+',   label: '3+ Bedrooms',      subtitle: 'Large home or villa', icon: Icons.villa_outlined),
        ],
        onChanged: (v) => setState(() => _propertySize = v),
      ),
      const SizedBox(height: 20),

      // ── 🏢 Building Info ──────────────────────────────────────────────────
      const SectionHeader(title: '🏢 Building Info'),
      const SizedBox(height: 14),

      // Pickup floor
      _FloorPicker(
        label: 'Pickup floor',
        value: _floorPickup,
        onChanged: (v) {
          setState(() {
            _floorPickup = v;
            _needsStairsCarry = !_hasElevator && (_floorPickup > 1 || _floorDropoff > 1);
          });
          _fetchMovingEstimate();
        },
      ),
      const SizedBox(height: 10),

      // Dropoff floor
      _FloorPicker(
        label: 'Dropoff floor',
        value: _floorDropoff,
        onChanged: (v) {
          setState(() {
            _floorDropoff = v;
            _needsStairsCarry = !_hasElevator && (_floorPickup > 1 || _floorDropoff > 1);
          });
          _fetchMovingEstimate();
        },
      ),
      const SizedBox(height: 14),

      // Elevator toggle
      _BoolToggleRow(
        label: 'Has elevator',
        subtitle: 'Building has a working elevator',
        icon: Icons.elevator_outlined,
        value: _hasElevator,
        onChanged: (v) {
          setState(() {
            _hasElevator = v;
            _needsStairsCarry = !v && (_floorPickup > 1 || _floorDropoff > 1);
          });
          _fetchMovingEstimate();
        },
      ),
      const SizedBox(height: 10),

      // Stairs carry (auto-set but still editable)
      _BoolToggleRow(
        label: 'Needs stairs carry',
        subtitle: 'Manual carry up/down stairs required',
        icon: Icons.stairs_outlined,
        value: _needsStairsCarry,
        onChanged: (v) => setState(() => _needsStairsCarry = v),
      ),
      const SizedBox(height: 20),

      // ── 🧍 Service Options ────────────────────────────────────────────────
      const SectionHeader(title: '🧍 Service Options'),
      const SizedBox(height: 14),

      // Helpers count
      _HelperCountRow(
        value: _requiresHelpers,
        onChanged: (v) {
          setState(() => _requiresHelpers = v);
          _fetchMovingEstimate();
        },
      ),
      const SizedBox(height: 14),

      // Heavy items
      _CheckOption(
        label: 'Has heavy items',
        subtitle: 'Fridge, sofa, bed, wardrobe',
        icon: Icons.chair_outlined,
        value: _heavyItems,
        onChanged: (v) {
          setState(() => _heavyItems = v);
          _fetchMovingEstimate();
        },
      ),
      const SizedBox(height: 10),

      // Packing service
      _CheckOption(
        label: 'Packing service',
        subtitle: 'We box and wrap your belongings',
        icon: Icons.inventory_2_outlined,
        value: _packingService,
        onChanged: (v) => setState(() => _packingService = v),
      ),
      const SizedBox(height: 20),

      // ── Notes ─────────────────────────────────────────────────────────────
      _Field(hint: 'Notes (optional)', icon: Icons.notes_outlined, controller: _moveNotesCtrl),
      const SizedBox(height: 20),

      // ── 💳 Payment Method ─────────────────────────────────────────────────
      _AppDropdown<String>(
        label: 'Payment Method',
        icon: Icons.wallet_outlined,
        value: _movePaymentMethod,
        items: const [
          _DropItem(value: 'cash',        label: 'Cash',         subtitle: 'Pay with cash',           icon: Icons.money),
          _DropItem(value: 'wallet',       label: 'ROTEH Wallet', subtitle: 'Pay from wallet balance',  icon: Icons.account_balance_wallet_outlined),
          _DropItem(value: 'aba',          label: 'ABA Pay',      subtitle: 'ABA mobile banking',      icon: Icons.credit_card),
          _DropItem(value: 'wing',         label: 'Wing Money',   subtitle: 'Wing mobile payment',     icon: Icons.send_to_mobile),
          _DropItem(value: 'other_online', label: 'Other Online', subtitle: 'Other online payment',    icon: Icons.language),
        ],
        onChanged: (v) => setState(() => _movePaymentMethod = v),
      ),
      const SizedBox(height: 20),

      // ── Moving date ───────────────────────────────────────────────────────
      const SizedBox(height: 14),
      Row(children: [
        const Text('Schedule moving date',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
        const Spacer(),
        Switch(
          value: _isMoveScheduled,
          onChanged: (v) => setState(() => _isMoveScheduled = v),
          activeThumbColor: AppTheme.accent,
          activeTrackColor: AppTheme.accent.withValues(alpha: 0.4),
        ),
      ]),
      if (_isMoveScheduled) ...[
        const SizedBox(height: 10),
        _DateTimeTile(dateTime: _moveDate, color: AppTheme.accent, onTap: _pickMoveDate),
      ],
      const SizedBox(height: 20),

      // ── 💰 Price Estimate (real API) ──────────────────────────────────────
      if (_moveFromLatLng == null || _moveToLatLng == null)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
          ),
          child: const Row(children: [
            Icon(Icons.receipt_long_outlined, color: AppTheme.textSecondary, size: 18),
            SizedBox(width: 10),
            Expanded(
              child: Text('Select pickup and dropoff locations to see fare estimate',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            ),
          ]),
        )
      else if (_estimateLoading)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardBg,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.accent)),
            SizedBox(width: 12),
            Text('Calculating fare…',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          ]),
        )
      else if (_movingEstimate != null)
        _MovingFareBreakdown(estimate: _movingEstimate!),
      const SizedBox(height: 8),
    ]);
  }
}

// ── Floor picker ─────────────────────────────────────────────────────────────

class _FloorPicker extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  const _FloorPicker({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBg),
      ),
      child: Row(children: [
        const Icon(Icons.apartment_outlined, color: AppTheme.textSecondary, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(label,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14))),
        GestureDetector(
          onTap: value > 1 ? () => onChanged(value - 1) : null,
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: value > 1 ? AppTheme.accent.withValues(alpha: 0.12) : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.remove, size: 16,
                color: value > 1 ? AppTheme.accent : AppTheme.textSecondary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text('$value',
              style: const TextStyle(color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        GestureDetector(
          onTap: value < 20 ? () => onChanged(value + 1) : null,
          child: Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              color: value < 20 ? AppTheme.accent.withValues(alpha: 0.12) : AppTheme.cardBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.add, size: 16,
                color: value < 20 ? AppTheme.accent : AppTheme.textSecondary),
          ),
        ),
      ]),
    );
  }
}

// ── Bool toggle row ───────────────────────────────────────────────────────────

class _BoolToggleRow extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _BoolToggleRow({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: value ? AppTheme.accent.withValues(alpha: 0.4) : AppTheme.cardBg),
      ),
      child: Row(children: [
        Icon(icon, color: value ? AppTheme.accent : AppTheme.textSecondary, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(
              color: value ? AppTheme.accent : AppTheme.textPrimary,
              fontWeight: FontWeight.w600, fontSize: 14)),
          Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ])),
        Row(children: [
          GestureDetector(
            onTap: value ? null : () => onChanged(true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: value ? AppTheme.accent : AppTheme.cardBg,
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
              ),
              child: Text('Yes', style: TextStyle(
                  color: value ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
          GestureDetector(
            onTap: value ? () => onChanged(false) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: !value ? AppTheme.danger.withValues(alpha: 0.15) : AppTheme.cardBg,
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
              ),
              child: Text('No', style: TextStyle(
                  color: !value ? AppTheme.danger : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600, fontSize: 13)),
            ),
          ),
        ]),
      ]),
    );
  }
}

// ── Helper count row ──────────────────────────────────────────────────────────

class _HelperCountRow extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _HelperCountRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBg),
      ),
      child: Row(children: [
        const Icon(Icons.people_outline, color: AppTheme.accent, size: 20),
        const SizedBox(width: 10),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Helpers needed', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          Text('1–4 persons for carrying', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ])),
        Row(children: List.generate(4, (i) {
          final n = i + 1;
          final selected = value == n;
          return GestureDetector(
            onTap: () => onChanged(n),
            child: Container(
              margin: const EdgeInsets.only(left: 6),
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: selected ? AppTheme.accent : AppTheme.cardBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Text('$n',
                  style: TextStyle(
                      color: selected ? Colors.white : AppTheme.textSecondary,
                      fontWeight: FontWeight.w700))),
            ),
          );
        })),
      ]),
    );
  }
}

// ── Helper type chip ──────────────────────────────────────────────────────────

// ── Price breakdown ───────────────────────────────────────────────────────────

// ── Moving fare breakdown (from API) ─────────────────────────────────────────

class _MovingFareBreakdown extends StatelessWidget {
  final MovingEstimateModel estimate;
  const _MovingFareBreakdown({required this.estimate});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.receipt_long_outlined, color: AppTheme.accent, size: 18),
          SizedBox(width: 6),
          Text('Fare Estimate', style: TextStyle(
              color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
        const SizedBox(height: 12),
        _PriceRow(label: 'Base fee',     value: AppTheme.khr(estimate.baseFee)),
        if (estimate.distanceFee > 0)
          _PriceRow(label: 'Distance fee', value: AppTheme.khr(estimate.distanceFee)),
        if (estimate.helperFee > 0)
          _PriceRow(label: 'Helper fee',   value: AppTheme.khr(estimate.helperFee)),
        if (estimate.floorFee > 0)
          _PriceRow(label: 'Floor fee',    value: AppTheme.khr(estimate.floorFee)),
        const Divider(height: 16, color: AppTheme.cardBg),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total estimate',
              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
          Text(AppTheme.khr(estimate.total),
              style: const TextStyle(
                  color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 18)),
        ]),
        const SizedBox(height: 4),
        const Text('Final price confirmed after booking',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ]),
    );
  }
}


class _PriceRow extends StatelessWidget {
  final String label, value;
  const _PriceRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600, fontSize: 13)),
      ]),
    );
  }
}

// ── Generic dropdown (bottom-sheet style) ────────────────────────────────────

class _DropItem<T> {
  final T value;
  final String label;
  final String subtitle;
  final IconData icon;
  const _DropItem({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.icon,
  });
}

class _AppDropdown<T> extends StatelessWidget {
  final String label;
  final IconData icon;
  final T value;
  final List<_DropItem<T>> items;
  final ValueChanged<T> onChanged;

  const _AppDropdown({
    required this.label,
    required this.icon,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  String get _selectedLabel =>
      items.firstWhere((i) => i.value == value,
          orElse: () => items.first).label;

  IconData get _selectedIcon =>
      items.firstWhere((i) => i.value == value,
          orElse: () => items.first).icon;

  void _open(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(2)),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(label,
                    style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700)),
              ),
            ),
            const Divider(height: 1, color: AppTheme.cardBg),
            // Options
            ...items.map((item) {
              final selected = item.value == value;
              return InkWell(
                onTap: () {
                  onChanged(item.value);
                  Navigator.pop(ctx);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppTheme.accent.withValues(alpha: 0.12)
                            : AppTheme.cardBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon,
                          color: selected
                              ? AppTheme.accent
                              : AppTheme.textSecondary,
                          size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.label,
                              style: TextStyle(
                                  color: selected
                                      ? AppTheme.accent
                                      : AppTheme.textPrimary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14)),
                          if (item.subtitle.isNotEmpty)
                            Text(item.subtitle,
                                style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12)),
                        ])),
                    if (selected)
                      const Icon(Icons.check_circle,
                          color: AppTheme.accent, size: 20)
                    else
                      const Icon(Icons.radio_button_off,
                          color: AppTheme.textSecondary, size: 20),
                  ]),
                ),
              );
            }),
            const SizedBox(height: 8),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.cardBg),
        ),
        child: Row(children: [
          Icon(_selectedIcon, color: AppTheme.accent, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w500)),
            const SizedBox(height: 2),
            Text(_selectedLabel,
                style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ])),
          const Icon(Icons.keyboard_arrow_down,
              color: AppTheme.textSecondary, size: 22),
        ]),
      ),
    );
  }
}

// ── Mode toggle ───────────────────────────────────────────────────────────────

class _ModeToggle extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;
  const _ModeToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: _ModeCard(
        value: 'delivery',
        label: 'Delivery',
        subtitle: 'Send packages',
        icon: Icons.delivery_dining,
        selected: selected == 'delivery',
        onTap: () => onChanged('delivery'),
      )),
      const SizedBox(width: 12),
      Expanded(child: _ModeCard(
        value: 'moving',
        label: 'Moving',
        subtitle: 'Relocate home/office',
        icon: Icons.local_shipping,
        selected: selected == 'moving',
        onTap: () => onChanged('moving'),
      )),
    ]);
  }
}

class _ModeCard extends StatelessWidget {
  final String value, label, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _ModeCard({
    required this.value,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent.withValues(alpha: 0.10) : AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.cardBg,
            width: 2,
          ),
          boxShadow: selected
              ? [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 3))]
              : [],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected ? AppTheme.accent : AppTheme.cardBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: selected ? Colors.white : AppTheme.textSecondary, size: 22),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle, color: AppTheme.accent, size: 18),
          ]),
          const SizedBox(height: 12),
          Text(label,
              style: TextStyle(
                color: selected ? AppTheme.accent : AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              )),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
        ]),
      ),
    );
  }
}

// ── Checkbox option ───────────────────────────────────────────────────────────

class _CheckOption extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _CheckOption({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: value ? AppTheme.accent.withValues(alpha: 0.08) : AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: value ? AppTheme.accent : AppTheme.cardBg, width: 1.5),
        ),
        child: Row(children: [
          Icon(icon, color: value ? AppTheme.accent : AppTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(
              color: value ? AppTheme.accent : AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            )),
            Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ])),
          Checkbox(
            value: value,
            onChanged: (v) => onChanged(v ?? false),
            activeColor: AppTheme.accent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        ]),
      ),
    );
  }
}

// ── Date-time tile ────────────────────────────────────────────────────────────

class _DateTimeTile extends StatelessWidget {
  final DateTime dateTime;
  final Color    color;
  final VoidCallback onTap;
  const _DateTimeTile({required this.dateTime, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          Icon(Icons.schedule, color: color, size: 20),
          const SizedBox(width: 10),
          Text(
            '${dateTime.day}/${dateTime.month}/${dateTime.year}  '
            '${dateTime.hour.toString().padLeft(2,'0')}:${dateTime.minute.toString().padLeft(2,'0')}',
            style: const TextStyle(color: AppTheme.textPrimary),
          ),
          const Spacer(),
          Text('Change', style: TextStyle(color: color, fontSize: 13)),
        ]),
      ),
    );
  }
}

// ── Submit button ─────────────────────────────────────────────────────────────

class _SubmitButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool loading;
  final VoidCallback onPressed;
  const _SubmitButton({required this.label, required this.icon, required this.loading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.danger,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppTheme.danger.withValues(alpha: 0.5),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: loading
            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 20),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              ]),
      ),
    );
  }
}

// ── Tappable address field — opens map picker directly ────────────────────────

class _AddressWithMap extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final VoidCallback onMapTap;
  const _AddressWithMap({
    required this.controller,
    required this.hint,
    required this.icon,
    required this.onMapTap,
  });

  @override
  Widget build(BuildContext context) {
    final filled = controller.text.trim().isNotEmpty;
    return GestureDetector(
      onTap: onMapTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: filled
                ? const Color(0xFF00C853).withValues(alpha: 0.4)
                : AppTheme.cardBg,
          ),
        ),
        child: Row(children: [
          Icon(icon,
              color: filled ? const Color(0xFF00C853) : AppTheme.textSecondary,
              size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              filled ? controller.text.trim() : hint,
              style: TextStyle(
                color: filled ? AppTheme.textPrimary : AppTheme.textSecondary,
                fontSize: 14,
                fontWeight: filled ? FontWeight.w500 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            filled ? Icons.check_circle : Icons.map_outlined,
            color: filled ? const Color(0xFF00C853) : AppTheme.accent,
            size: 20,
          ),
        ]),
      ),
    );
  }
}

// ── Location picker result ────────────────────────────────────────────────────

class _LocationResult {
  final String address;
  final LatLng latLng;
  const _LocationResult(this.address, this.latLng);
}

// ── Full-screen map drag-drop location picker ─────────────────────────────────

class _LocationPickerScreen extends StatefulWidget {
  final LatLng initial;
  const _LocationPickerScreen({required this.initial});

  @override
  State<_LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<_LocationPickerScreen> {
  late LatLng _center;
  String _address  = '';
  bool   _geocoding = false;
  GoogleMapController? _ctrl;

  // Search
  final _searchCtrl    = TextEditingController();
  List<PlaceResult> _searchResults = [];
  bool   _searching    = false;
  bool   _showResults  = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _center = widget.initial;
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    _searchCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _geocode() async {
    setState(() => _geocoding = true);
    final addr = await MapsService.reverseGeocode(_center);
    if (!mounted) return;
    setState(() {
      _address  = addr ??
          '${_center.latitude.toStringAsFixed(4)}, '
          '${_center.longitude.toStringAsFixed(4)}';
      _geocoding = false;
    });
  }

  void _onSearchChanged(String q) {
    _debounce?.cancel();
    if (q.trim().isEmpty) {
      setState(() { _searchResults = []; _searching = false; _showResults = false; });
      return;
    }
    setState(() => _searching = true);
    _debounce = Timer(const Duration(milliseconds: 450), () async {
      final results = await MapsService.searchAddress(q.trim());
      if (!mounted) return;
      setState(() {
        _searchResults = results;
        _searching     = false;
        _showResults   = true;
      });
    });
  }

  void _selectResult(PlaceResult r) {
    _ctrl?.animateCamera(CameraUpdate.newLatLngZoom(r.latLng, 16));
    _center  = r.latLng;
    _address = r.address;
    _searchCtrl.clear();
    FocusScope.of(context).unfocus();
    setState(() { _searchResults = []; _showResults = false; _address = r.address; });
  }

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).viewPadding.bottom;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Stack(children: [

        // ── Map ───────────────────────────────────────────────────────────
        GoogleMap(
          onMapCreated: (c) {
            _ctrl = c;
            c.animateCamera(CameraUpdate.newLatLng(_center));
            _geocode();
          },
          initialCameraPosition: CameraPosition(target: _center, zoom: 15),
          onCameraMove: (pos) {
            _center = pos.target;
            if (_showResults) setState(() => _showResults = false);
          },
          onCameraIdle:  _geocode,
          myLocationEnabled:       true,
          myLocationButtonEnabled: false,
          zoomControlsEnabled:     false,
          cameraTargetBounds:      CameraTargetBounds(_kPickerBounds),
          minMaxZoomPreference:    const MinMaxZoomPreference(10, 20),
        ),

        // ── Green crosshair pin ───────────────────────────────────────────
        const Center(child: _DeliveryCrosshair()),

        // ── Top bar: back + search ────────────────────────────────────────
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  // Back button
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8)],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new,
                          color: AppTheme.textPrimary, size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Search field
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 8)],
                      ),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _onSearchChanged,
                        style: const TextStyle(
                            color: AppTheme.textPrimary, fontSize: 14),
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          hintText: 'Search location…',
                          hintStyle: const TextStyle(
                              color: AppTheme.textSecondary, fontSize: 14),
                          prefixIcon: _searching
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16, height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFF00C853)),
                                  ),
                                )
                              : const Icon(Icons.search,
                                  color: AppTheme.textSecondary, size: 20),
                          suffixIcon: _searchCtrl.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchCtrl.clear();
                                    setState(() {
                                      _searchResults = [];
                                      _showResults   = false;
                                      _searching     = false;
                                    });
                                    FocusScope.of(context).unfocus();
                                  },
                                  child: const Icon(Icons.close,
                                      color: AppTheme.textSecondary, size: 18),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 0),
                          isDense: true,
                        ),
                      ),
                    ),
                  ),
                ]),

                // Search results dropdown
                if (_showResults && _searchResults.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          blurRadius: 12)],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: _searchResults.length > 6
                          ? 6
                          : _searchResults.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1,
                          indent: 50,
                          color: AppTheme.cardBg),
                      itemBuilder: (_, i) {
                        final r = _searchResults[i];
                        return InkWell(
                          onTap: () => _selectResult(r),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            child: Row(children: [
                              const Icon(Icons.location_on_outlined,
                                  color: Color(0xFF00C853), size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(r.address,
                                    style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 13),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ]),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // ── Bottom confirm bar ────────────────────────────────────────────
        Positioned(
          bottom: 0, left: 0, right: 0,
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 20)],
            ),
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + bottomPad),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                const Icon(Icons.location_on,
                    color: Color(0xFF00C853), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: _geocoding
                      ? const Row(children: [
                          SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppTheme.accent)),
                          SizedBox(width: 8),
                          Text('Finding address…',
                              style: TextStyle(
                                  color: AppTheme.textSecondary, fontSize: 13)),
                        ])
                      : Text(
                          _address.isEmpty
                              ? 'Drag map to select location'
                              : _address,
                          style: TextStyle(
                            color: _address.isEmpty
                                ? AppTheme.textSecondary
                                : AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: _address.isEmpty
                                ? FontWeight.normal
                                : FontWeight.w500,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                ),
              ]),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_geocoding || _address.isEmpty)
                      ? null
                      : () => Navigator.pop(
                            context,
                            _LocationResult(_address, _center),
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C853),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.cardBg,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: const Text('Confirm Location',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}

// ── Green crosshair drag pin ──────────────────────────────────────────────────

class _DeliveryCrosshair extends StatelessWidget {
  const _DeliveryCrosshair();
  static const _green = Color(0xFF00C853);

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: _green,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black38,
                    blurRadius: 8,
                    offset: Offset(0, 3)),
              ],
            ),
            child: const Icon(Icons.location_on,
                color: Colors.white, size: 20),
          ),
          Container(
            width: 3, height: 18,
            decoration: const BoxDecoration(
              color: _green,
              borderRadius:
                  BorderRadius.vertical(bottom: Radius.circular(2)),
            ),
          ),
          Container(
            width: 10, height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Delivery booking confirmation dialog ─────────────────────────────────────

class _DeliveryConfirmDialog extends StatelessWidget {
  final String  pickupAddress;
  final String  dropoffAddress;
  final String? senderName;
  final String? senderPhone;
  final String? recipientName;
  final String? recipientPhone;
  final String  packageDetails;
  final String  packageSize;
  final String  serviceOption;
  final String  paymentBy;
  final String  paymentMethod;
  final int?    fee;
  final DateTime? scheduledAt;
  final String? notes;

  const _DeliveryConfirmDialog({
    required this.pickupAddress,
    required this.dropoffAddress,
    required this.packageDetails,
    required this.packageSize,
    required this.serviceOption,
    required this.paymentBy,
    required this.paymentMethod,
    this.senderName,
    this.senderPhone,
    this.recipientName,
    this.recipientPhone,
    this.fee,
    this.scheduledAt,
    this.notes,
  });

  @override
  Widget build(BuildContext context) {
    final String payLabel = {
      'cash': 'Cash',
      'wallet': 'Wallet',
      'aba': 'ABA Pay',
      'wing': 'Wing Money',
      'other_online': 'Other Online',
    }[paymentMethod] ?? paymentMethod;

    final String sizeLabel = {
      'small':  'Small',
      'medium': 'Medium',
      'large':  'Large',
    }[packageSize] ?? packageSize;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: const BoxDecoration(
              color: Color(0xFF00C853),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Column(children: [
              Icon(Icons.delivery_dining_outlined, color: Colors.white, size: 32),
              SizedBox(height: 6),
              Text('Confirm Delivery Booking',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ]),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Addresses
                _ConfirmRow(
                  icon: Icons.location_on_outlined,
                  iconColor: const Color(0xFF00C853),
                  label: 'Pickup',
                  value: pickupAddress,
                ),
                const SizedBox(height: 8),
                _ConfirmRow(
                  icon: Icons.location_on,
                  iconColor: AppTheme.danger,
                  label: 'Dropoff',
                  value: dropoffAddress,
                ),

                const Divider(height: 20, color: AppTheme.cardBg),

                // Sender / recipient
                if (senderName != null)
                  _ConfirmRow(icon: Icons.person_outline, label: 'Sender', value: senderName!),
                if (senderPhone != null) ...[
                  const SizedBox(height: 6),
                  _ConfirmRow(icon: Icons.phone_outlined, label: 'Sender Ph.', value: senderPhone!),
                ],
                if (recipientName != null) ...[
                  const SizedBox(height: 6),
                  _ConfirmRow(icon: Icons.person_outline, iconColor: AppTheme.accentOrange, label: 'Recipient', value: recipientName!),
                ],
                if (recipientPhone != null) ...[
                  const SizedBox(height: 6),
                  _ConfirmRow(icon: Icons.phone_outlined, iconColor: AppTheme.accentOrange, label: 'Recip. Ph.', value: recipientPhone!),
                ],

                const Divider(height: 20, color: AppTheme.cardBg),

                // Package
                _ConfirmRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Package',
                  value: packageDetails,
                ),
                const SizedBox(height: 6),
                _ConfirmRow(
                  icon: Icons.straighten_outlined,
                  label: 'Size',
                  value: sizeLabel,
                ),
                const SizedBox(height: 6),
                _ConfirmRow(
                  icon: Icons.flash_on_outlined,
                  label: 'Service',
                  value: serviceOption == 'express' ? 'Express' : 'Normal',
                ),
                const SizedBox(height: 6),
                _ConfirmRow(
                  icon: Icons.payment_outlined,
                  label: 'Payment',
                  value: '$payLabel (paid by ${paymentBy == 'recipient' ? 'recipient' : 'sender'})',
                ),
                if (fee != null) ...[
                  const SizedBox(height: 6),
                  _ConfirmRow(
                    icon: Icons.receipt_long_outlined,
                    iconColor: AppTheme.accent,
                    label: 'Fee',
                    value: AppTheme.khr(fee!),
                  ),
                ],
                if (scheduledAt != null) ...[
                  const SizedBox(height: 6),
                  _ConfirmRow(
                    icon: Icons.schedule_outlined,
                    iconColor: AppTheme.warning,
                    label: 'Scheduled',
                    value: '${scheduledAt!.day}/${scheduledAt!.month}/${scheduledAt!.year}'
                        '  ${scheduledAt!.hour.toString().padLeft(2, '0')}:'
                        '${scheduledAt!.minute.toString().padLeft(2, '0')}',
                  ),
                ],
                if (notes != null && notes!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _ConfirmRow(
                    icon: Icons.notes_outlined,
                    label: 'Notes',
                    value: notes!,
                  ),
                ],
                const SizedBox(height: 20),
              ]),
            ),
          ),

          // ── Buttons ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('No, Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Yes, Send Now',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Moving booking confirmation dialog ───────────────────────────────────────

class _MovingConfirmDialog extends StatelessWidget {
  final String  from;
  final String  to;
  final int     floorPickup;
  final int     floorDropoff;
  final bool    hasElevator;
  final int     requiresHelpers;
  final bool    heavyItems;
  final String  serviceOption;
  final String  paymentMethod;
  final MovingEstimateModel? estimate;
  final DateTime? scheduledAt;
  final String? notes;

  const _MovingConfirmDialog({
    required this.from,
    required this.to,
    required this.floorPickup,
    required this.floorDropoff,
    required this.hasElevator,
    required this.requiresHelpers,
    required this.heavyItems,
    required this.serviceOption,
    required this.paymentMethod,
    required this.estimate,
    this.scheduledAt,
    this.notes,
  });

  @override
  Widget build(BuildContext context) {
    final String payLabel = {
      'cash': 'Cash',
      'wallet': 'Wallet',
      'aba': 'ABA Pay',
      'wing': 'Wing Money',
      'other_online': 'Other Online',
    }[paymentMethod] ?? paymentMethod;

    return Dialog(
      backgroundColor: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: const BoxDecoration(
              color: Color(0xFF00C853),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: const Column(children: [
              Icon(Icons.local_shipping_outlined, color: Colors.white, size: 32),
              SizedBox(height: 6),
              Text('Confirm Moving Booking',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
            ]),
          ),

          // ── Body ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              // Addresses
              _ConfirmRow(
                icon: Icons.location_on_outlined,
                iconColor: const Color(0xFF00C853),
                label: 'From',
                value: from,
              ),
              const SizedBox(height: 8),
              _ConfirmRow(
                icon: Icons.location_on,
                iconColor: AppTheme.danger,
                label: 'To',
                value: to,
              ),

              const Divider(height: 20, color: AppTheme.cardBg),

              // Building & helpers
              _ConfirmRow(
                icon: Icons.apartment_outlined,
                label: 'Floors',
                value: 'Pickup: $floorPickup  •  Dropoff: $floorDropoff',
              ),
              const SizedBox(height: 6),
              _ConfirmRow(
                icon: hasElevator
                    ? Icons.elevator_outlined
                    : Icons.stairs_outlined,
                label: 'Elevator',
                value: hasElevator ? 'Yes' : 'No (stairs carry)',
              ),
              const SizedBox(height: 6),
              _ConfirmRow(
                icon: Icons.people_outline,
                label: 'Helpers',
                value: '$requiresHelpers helper${requiresHelpers != 1 ? 's' : ''}'
                    ' (${heavyItems ? 'heavy carry' : 'normal carry'})',
              ),
              const SizedBox(height: 6),
              _ConfirmRow(
                icon: Icons.flash_on_outlined,
                label: 'Service',
                value: serviceOption == 'express' ? 'Express' : 'Normal',
              ),
              const SizedBox(height: 6),
              _ConfirmRow(
                icon: Icons.payment_outlined,
                label: 'Payment',
                value: payLabel,
              ),
              if (scheduledAt != null) ...[
                const SizedBox(height: 6),
                _ConfirmRow(
                  icon: Icons.schedule_outlined,
                  iconColor: AppTheme.warning,
                  label: 'Scheduled',
                  value: '${scheduledAt!.day}/${scheduledAt!.month}/${scheduledAt!.year}'
                      '  ${scheduledAt!.hour.toString().padLeft(2,'0')}:'
                      '${scheduledAt!.minute.toString().padLeft(2,'0')}',
                ),
              ],
              if (notes != null && notes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                _ConfirmRow(
                  icon: Icons.notes_outlined,
                  label: 'Notes',
                  value: notes!,
                ),
              ],

              // Fare
              if (estimate != null) ...[
                const Divider(height: 20, color: AppTheme.cardBg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Estimated Fare',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 13)),
                    Text(AppTheme.khr(estimate!.total),
                        style: const TextStyle(
                            color: AppTheme.accent,
                            fontSize: 20,
                            fontWeight: FontWeight.w800)),
                  ],
                ),
              ],

              const SizedBox(height: 20),
            ]),
          ),

          // ── Buttons ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('No, Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976D2),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('Yes, Book Now',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  final IconData icon;
  final Color    iconColor;
  final String   label;
  final String   value;

  const _ConfirmRow({
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = AppTheme.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: iconColor, size: 16),
      const SizedBox(width: 8),
      SizedBox(
        width: 68,
        child: Text('$label:',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12)),
      ),
      Expanded(
        child: Text(value,
            style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ),
    ]);
  }
}

// ── Reusable text field ───────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final String hint;
  final IconData icon;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _Field({
    required this.hint,
    required this.icon,
    required this.controller,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 20),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
        ),
      ),
    );
  }
}

