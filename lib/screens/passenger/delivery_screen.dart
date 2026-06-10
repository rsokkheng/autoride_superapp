import 'package:flutter/material.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:autoride_superapp/widgets/address_field.dart';
import 'package:autoride_superapp/widgets/common_widgets.dart';
import '../../services/api_service.dart';

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
  String   _deliveryVehicleType  = 'motorbike'; // 'motorbike'|'small_car'|'van'|'truck'
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
    setState(() { _submitting = true; _error = null; });
    try {
      await ApiService.createDelivery(
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
      _showSuccess('Delivery created successfully!');
      Navigator.pop(context);
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
    setState(() { _submitting = true; _error = null; });
    try {
      await ApiService.createMoving(
        pickupAddress:    from,
        dropoffAddress:   to,
        floorPickup:      _floorPickup,
        floorDropoff:     _floorDropoff,
        hasElevator:      _hasElevator,
        needsStairsCarry: _needsStairsCarry,
        heavyItems:       _heavyItems,
        requiresHelpers:  _requiresHelpers,
        serviceOption:    _movingServiceOption,
        paymentMethod:    _movePaymentMethod,
        notes:            _moveNotesCtrl.text.trim().isEmpty ? null : _moveNotesCtrl.text.trim(),
        scheduledAt:      _isMoveScheduled ? _formatDateTime(_moveDate) : null,
      );
      if (!mounted) return;
      _showSuccess('Moving scheduled successfully!');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  // ── Moving pricing preview (client-side estimate in USD) ──────────────────

  static const _kHelperFeeNormal = 5.0;
  static const _kBaseFeeMoving   = 15.0;

  double get _floorFee {
    final maxFloor = _floorPickup > _floorDropoff ? _floorPickup : _floorDropoff;
    double fee;
    if (maxFloor <= 1) {
      fee = 0;
    } else if (maxFloor <= 3) {
      fee = 2 + (maxFloor - 1) * 1.5;
    } else {
      fee = 5 + (maxFloor - 3) * 1.5;
    }
    return _hasElevator ? fee : fee * 1.5;
  }

  double get _helperFee => _requiresHelpers * _kHelperFeeNormal;

  double get _packingFee => _packingService ? 10.0 : 0.0;

  double get _totalEstimate => _kBaseFeeMoving + _floorFee + _helperFee + _packingFee;

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
        colors: const [Color(0xFF1A3FAA), Color(0xFF0D2F6E)],
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Send anything,\nanywhere fast!',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Average delivery: 25 min',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
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
      AddressField(hint: 'Pickup address', icon: Icons.location_on_outlined, controller: _pickupCtrl),
      const SizedBox(height: 20),

      // Recipient
      const SectionHeader(title: 'Recipient'),
      const SizedBox(height: 14),
      _Field(hint: "Recipient's name",  icon: Icons.person_outline, controller: _recipientNameCtrl),
      const SizedBox(height: 10),
      _Field(hint: "Recipient's phone", icon: Icons.phone_outlined,  controller: _recipientPhoneCtrl,
          keyboardType: TextInputType.phone),
      const SizedBox(height: 10),
      AddressField(hint: 'Delivery address', icon: Icons.location_on, controller: _dropoffCtrl),
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
        icon: Icons.two_wheeler,
        value: _deliveryVehicleType,
        items: const [
          _DropItem(value: 'motorbike', label: 'Motorbike — ម៉ូតូ',       subtitle: 'Up to 10 kg  •  Fastest', icon: Icons.two_wheeler),
          _DropItem(value: 'small_car', label: 'Small Car — ឡានតូច',      subtitle: 'Up to 50 kg  •  Fast',    icon: Icons.directions_car_outlined),
          _DropItem(value: 'van',       label: 'Van / Pickup — ឡានធំតូច', subtitle: 'Up to 300 kg  •  Standard', icon: Icons.airport_shuttle_outlined),
          _DropItem(value: 'truck',     label: 'Truck — ឡានធំ',           subtitle: '300 kg+  •  Scheduled',   icon: Icons.local_shipping_outlined),
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
        colors: const [Color(0xFF1A3FAA), Color(0xFF0D2F6E)],
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Move with ease,\nwe handle the rest!',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Professional moving service',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
          ])),
          const Icon(Icons.local_shipping, color: Colors.white, size: 56),
        ]),
      ),
      const SizedBox(height: 20),

      // ── Addresses ────────────────────────────────────────────────────────
      const SectionHeader(title: 'Addresses'),
      const SizedBox(height: 14),
      AddressField(hint: 'Moving from (full address)', icon: Icons.location_on_outlined, controller: _moveFromCtrl),
      const SizedBox(height: 10),
      AddressField(hint: 'Moving to (full address)', icon: Icons.location_on, controller: _moveToCtrl),
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
        onChanged: (v) => setState(() => _movingServiceOption = v),
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
        onChanged: (v) => setState(() {
          _floorPickup = v;
          _needsStairsCarry = !_hasElevator && (_floorPickup > 1 || _floorDropoff > 1);
        }),
      ),
      const SizedBox(height: 10),

      // Dropoff floor
      _FloorPicker(
        label: 'Dropoff floor',
        value: _floorDropoff,
        onChanged: (v) => setState(() {
          _floorDropoff = v;
          _needsStairsCarry = !_hasElevator && (_floorPickup > 1 || _floorDropoff > 1);
        }),
      ),
      const SizedBox(height: 14),

      // Elevator toggle
      _BoolToggleRow(
        label: 'Has elevator',
        subtitle: 'Building has a working elevator',
        icon: Icons.elevator_outlined,
        value: _hasElevator,
        onChanged: (v) => setState(() {
          _hasElevator = v;
          _needsStairsCarry = !v && (_floorPickup > 1 || _floorDropoff > 1);
        }),
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
        onChanged: (v) => setState(() => _requiresHelpers = v),
      ),
      const SizedBox(height: 14),

      // Heavy items
      _CheckOption(
        label: 'Has heavy items',
        subtitle: 'Fridge, sofa, bed, wardrobe',
        icon: Icons.chair_outlined,
        value: _heavyItems,
        onChanged: (v) => setState(() => _heavyItems = v),
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

      // ── 💰 Price Estimate ─────────────────────────────────────────────────
      _PriceBreakdown(
        baseFee:    _kBaseFeeMoving,
        floorFee:   _floorFee,
        helperFee:  _helperFee,
        packingFee: _packingFee,
        total:      _totalEstimate,
        hasElevator: _hasElevator,
        floorPickup: _floorPickup,
        floorDropoff: _floorDropoff,
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

class _PriceBreakdown extends StatelessWidget {
  final double baseFee, floorFee, helperFee, packingFee, total;
  final bool hasElevator;
  final int floorPickup, floorDropoff;
  const _PriceBreakdown({
    required this.baseFee,
    required this.floorFee,
    required this.helperFee,
    required this.packingFee,
    required this.total,
    required this.hasElevator,
    required this.floorPickup,
    required this.floorDropoff,
  });

  String _fmt(double v) => v == 0 ? 'Free' : '\$${v.toStringAsFixed(0)}';

  @override
  Widget build(BuildContext context) {
    final maxFloor = floorPickup > floorDropoff ? floorPickup : floorDropoff;
    String floorNote = '';
    if (maxFloor > 1) {
      floorNote = !hasElevator ? ' (×1.5 no elevator)' : '';
    }
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
          Text('Estimated Price', style: TextStyle(
              color: AppTheme.accent, fontWeight: FontWeight.w700, fontSize: 14)),
        ]),
        const SizedBox(height: 12),
        _PriceRow(label: 'Base fee',    value: _fmt(baseFee)),
        if (floorFee > 0)
          _PriceRow(label: 'Floor carry fee$floorNote', value: _fmt(floorFee)),
        if (helperFee > 0)
          _PriceRow(label: 'Helper fee', value: _fmt(helperFee)),
        if (packingFee > 0)
          _PriceRow(label: 'Packing service', value: _fmt(packingFee)),
        const Divider(height: 16, color: AppTheme.cardBg),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total estimate',
              style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
          Text('\$${total.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 18)),
        ]),
        const SizedBox(height: 4),
        const Text('Final price confirmed by driver',
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

