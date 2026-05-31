import 'package:flutter/material.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:autoride_superapp/widgets/common_widgets.dart';
import '../../services/api_service.dart';

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  State<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  final _senderNameCtrl     = TextEditingController();
  final _pickupCtrl         = TextEditingController();
  final _recipientNameCtrl  = TextEditingController();
  final _recipientPhoneCtrl = TextEditingController();
  final _dropoffCtrl        = TextEditingController();
  final _packageDetailsCtrl = TextEditingController();
  final _feeCtrl            = TextEditingController();
  final _notesCtrl          = TextEditingController();

  bool _isScheduled   = false;
  String _packageSize   = 'small';
  String _paymentBy     = 'sender';   // 'sender' | 'recipient'
  String _paymentMethod = 'cash';     // 'cash' | 'wallet' | 'aba' | 'wing' | 'other_online'
  DateTime _scheduledTime = DateTime.now().add(const Duration(hours: 2));
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _senderNameCtrl.dispose();
    _pickupCtrl.dispose();
    _recipientNameCtrl.dispose();
    _recipientPhoneCtrl.dispose();
    _dropoffCtrl.dispose();
    _packageDetailsCtrl.dispose();
    _feeCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
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
        recipientName:  _recipientNameCtrl.text.trim().isEmpty  ? null : _recipientNameCtrl.text.trim(),
        recipientPhone: _recipientPhoneCtrl.text.trim().isEmpty ? null : _recipientPhoneCtrl.text.trim(),
        packageSize:    _packageSize,
        fee:            int.tryParse(_feeCtrl.text.trim()),
        paymentBy:      _paymentBy,
        paymentMethod:  _paymentMethod,
        notes:          _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        scheduledAt:    _isScheduled
            ? '${_scheduledTime.year}-${_scheduledTime.month.toString().padLeft(2,'0')}-${_scheduledTime.day.toString().padLeft(2,'0')} '
              '${_scheduledTime.hour.toString().padLeft(2,'0')}:${_scheduledTime.minute.toString().padLeft(2,'0')}:00'
            : null,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Delivery created successfully!'),
        backgroundColor: AppTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _pickScheduleTime() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientCard(
              colors: [const Color(0xFF1A1A2E), const Color(0xFF2D1B00)],
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Send anything,\nanywhere fast!',
                      style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Text('Average delivery: 25 min', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                ])),
                const Icon(Icons.delivery_dining, color: AppTheme.accentOrange, size: 56),
              ]),
            ),
            const SizedBox(height: 20),

            // ── Error banner ────────────────────────────────────────────
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

            // ── Sender ──────────────────────────────────────────────────
            const SectionHeader(title: 'Sender'),
            const SizedBox(height: 14),
            _Field(hint: "Sender's name",    icon: Icons.person_outline,       controller: _senderNameCtrl),
            const SizedBox(height: 10),
            _Field(hint: 'Pickup address',   icon: Icons.location_on_outlined,  controller: _pickupCtrl),

            const SizedBox(height: 20),

            // ── Recipient ───────────────────────────────────────────────
            const SectionHeader(title: 'Recipient'),
            const SizedBox(height: 14),
            _Field(hint: "Recipient's name",  icon: Icons.person_outline,  controller: _recipientNameCtrl),
            const SizedBox(height: 10),
            _Field(hint: "Recipient's phone", icon: Icons.phone_outlined,  controller: _recipientPhoneCtrl,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 10),
            _Field(hint: 'Delivery address',  icon: Icons.location_on,     controller: _dropoffCtrl),

            const SizedBox(height: 20),

            // ── Package ─────────────────────────────────────────────────
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

            // ── Package size ────────────────────────────────────────────
            const SectionHeader(title: 'Package Size'),
            const SizedBox(height: 14),
            Row(children: [
              _SizeChip(label: 'Small',  subtitle: '< 2 kg',   selected: _packageSize == 'small',  onTap: () => setState(() => _packageSize = 'small')),
              const SizedBox(width: 10),
              _SizeChip(label: 'Medium', subtitle: '2–10 kg',  selected: _packageSize == 'medium', onTap: () => setState(() => _packageSize = 'medium')),
              const SizedBox(width: 10),
              _SizeChip(label: 'Large',  subtitle: '10+ kg',   selected: _packageSize == 'large',  onTap: () => setState(() => _packageSize = 'large')),
            ]),

            const SizedBox(height: 20),

            // ── Payment By ──────────────────────────────────────────────
            const SectionHeader(title: 'Payment By'),
            const SizedBox(height: 14),
            Row(children: [
              _PaymentByChip(
                label: 'Sender',
                subtitle: 'Pays upfront',
                icon: Icons.upload_outlined,
                selected: _paymentBy == 'sender',
                onTap: () => setState(() => _paymentBy = 'sender'),
              ),
              const SizedBox(width: 10),
              _PaymentByChip(
                label: 'Recipient',
                subtitle: 'COD',
                icon: Icons.download_outlined,
                selected: _paymentBy == 'recipient',
                onTap: () => setState(() => _paymentBy = 'recipient'),
              ),
            ]),

            const SizedBox(height: 20),

            // ── Payment Method ──────────────────────────────────────────
            const SectionHeader(title: 'Payment Method'),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _PaymentMethodChip(label: 'Cash',         value: 'cash',         icon: Icons.money,              selected: _paymentMethod == 'cash',         onTap: () => setState(() => _paymentMethod = 'cash')),
                _PaymentMethodChip(label: 'Wallet',       value: 'wallet',       icon: Icons.account_balance_wallet_outlined, selected: _paymentMethod == 'wallet',       onTap: () => setState(() => _paymentMethod = 'wallet')),
                _PaymentMethodChip(label: 'ABA',          value: 'aba',          icon: Icons.credit_card,        selected: _paymentMethod == 'aba',          onTap: () => setState(() => _paymentMethod = 'aba')),
                _PaymentMethodChip(label: 'Wing',         value: 'wing',         icon: Icons.send_to_mobile,     selected: _paymentMethod == 'wing',         onTap: () => setState(() => _paymentMethod = 'wing')),
                _PaymentMethodChip(label: 'Other Online', value: 'other_online', icon: Icons.language,           selected: _paymentMethod == 'other_online', onTap: () => setState(() => _paymentMethod = 'other_online')),
              ],
            ),

            const SizedBox(height: 20),

            // ── Schedule toggle ─────────────────────────────────────────
            Row(children: [
              const Text('Schedule delivery', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
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
              GestureDetector(
                onTap: _pickScheduleTime,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.4)),
                  ),
                  child: Row(children: [
                    const Icon(Icons.schedule, color: AppTheme.accentOrange, size: 20),
                    const SizedBox(width: 10),
                    Text(
                      '${_scheduledTime.day}/${_scheduledTime.month}/${_scheduledTime.year}  '
                      '${_scheduledTime.hour.toString().padLeft(2,'0')}:${_scheduledTime.minute.toString().padLeft(2,'0')}',
                      style: const TextStyle(color: AppTheme.textPrimary),
                    ),
                    const Spacer(),
                    const Text('Change', style: TextStyle(color: AppTheme.accentOrange, fontSize: 13)),
                  ]),
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ── Submit ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  disabledBackgroundColor: AppTheme.accentOrange.withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _submitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text(
                        _isScheduled ? 'Schedule Delivery' : 'Send Now',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                      ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
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
          borderSide: const BorderSide(color: AppTheme.accentOrange, width: 1.5),
        ),
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  final String label, subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _SizeChip({required this.label, required this.subtitle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.accentOrange.withValues(alpha: 0.15) : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppTheme.accentOrange : Colors.transparent, width: 1.5),
          ),
          child: Column(children: [
            Text(label,    style: TextStyle(color: selected ? AppTheme.accentOrange : AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
            Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}

class _PaymentByChip extends StatelessWidget {
  final String label, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentByChip({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.accentOrange.withValues(alpha: 0.15) : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppTheme.accentOrange : Colors.transparent, width: 1.5),
          ),
          child: Row(children: [
            Icon(icon, color: selected ? AppTheme.accentOrange : AppTheme.textSecondary, size: 18),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,    style: TextStyle(color: selected ? AppTheme.accentOrange : AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
              Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _PaymentMethodChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentMethodChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accentOrange.withValues(alpha: 0.15) : AppTheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? AppTheme.accentOrange : Colors.transparent, width: 1.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: selected ? AppTheme.accentOrange : AppTheme.textSecondary, size: 16),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: selected ? AppTheme.accentOrange : AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
  }
}
