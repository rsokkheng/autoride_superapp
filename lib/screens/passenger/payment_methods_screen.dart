import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

const _green = Color(0xFF00C48C);
const _kPrefsKey = 'saved_payment_methods';

enum PayMethodType { card, aba, acleda }

enum CardBrand { visa, mastercard, paypal }

class SavedPaymentMethod {
  final String id;
  final PayMethodType type;
  final CardBrand? brand;   // for type == card
  final String? last4;      // for type == card
  final String label;       // cardholder name, or linked account label
  bool isDefault;

  SavedPaymentMethod({
    required this.id,
    required this.type,
    this.brand,
    this.last4,
    required this.label,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'brand': brand?.name,
        'last4': last4,
        'label': label,
        'is_default': isDefault,
      };

  factory SavedPaymentMethod.fromJson(Map<String, dynamic> j) => SavedPaymentMethod(
        id: j['id'] as String,
        type: PayMethodType.values.byName(j['type'] as String),
        brand: j['brand'] == null ? null : CardBrand.values.byName(j['brand'] as String),
        last4: j['last4'] as String?,
        label: j['label'] as String? ?? '',
        isDefault: j['is_default'] as bool? ?? false,
      );
}

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<SavedPaymentMethod> _methods = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey);
    List<SavedPaymentMethod> list = [];
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        list = decoded
            .whereType<Map<String, dynamic>>()
            .map(SavedPaymentMethod.fromJson)
            .toList();
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() { _methods = list; _loading = false; });
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kPrefsKey, jsonEncode(_methods.map((m) => m.toJson()).toList()));
  }

  Future<void> _addMethod(SavedPaymentMethod method) async {
    setState(() {
      if (method.isDefault) {
        for (final m in _methods) {
          m.isDefault = false;
        }
      }
      _methods.add(method);
    });
    await _persist();
  }

  Future<void> _setDefault(SavedPaymentMethod method) async {
    setState(() {
      for (final m in _methods) {
        m.isDefault = m.id == method.id;
      }
    });
    await _persist();
  }

  Future<void> _remove(SavedPaymentMethod method) async {
    setState(() => _methods.removeWhere((m) => m.id == method.id));
    await _persist();
  }

  List<SavedPaymentMethod> get _cards =>
      _methods.where((m) => m.type == PayMethodType.card).toList();
  SavedPaymentMethod? get _aba =>
      _methods.where((m) => m.type == PayMethodType.aba).firstOrNull;
  SavedPaymentMethod? get _acleda =>
      _methods.where((m) => m.type == PayMethodType.acleda).firstOrNull;

  Future<void> _openAddSheet() async {
    final result = await showModalBottomSheet<SavedPaymentMethod>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddMethodSheet(
        abaLinked: _aba != null,
        acledaLinked: _acleda != null,
      ),
    );
    if (result != null) await _addMethod(result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        leading: BackButton(color: context.appTextPrimary),
        title: Text(AppLocalizations.of(context).paymentMethods,
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: _green))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _AddMethodTile(onTap: _openAddSheet),
                const SizedBox(height: 20),

                _SectionLabel(AppLocalizations.of(context).cardsSection),
                const SizedBox(height: 8),
                if (_cards.isEmpty)
                  _EmptyRow(text: AppLocalizations.of(context).noCardsAddedYet)
                else
                  ..._cards.map((c) => _MethodTile(
                        method: c,
                        onSetDefault: () => _setDefault(c),
                        onRemove: () => _remove(c),
                      )),
                const SizedBox(height: 20),

                _SectionLabel(AppLocalizations.of(context).linkedAccountsSection),
                const SizedBox(height: 8),
                _LinkedAccountTile(
                  label: 'ABA Pay',
                  color: const Color(0xFF004B87),
                  method: _aba,
                  onSetDefault: _aba == null ? null : () => _setDefault(_aba!),
                  onRemove: _aba == null ? null : () => _remove(_aba!),
                ),
                _LinkedAccountTile(
                  label: 'ACLEDA Pay',
                  color: const Color(0xFF006B3F),
                  method: _acleda,
                  onSetDefault: _acleda == null ? null : () => _setDefault(_acleda!),
                  onRemove: _acleda == null ? null : () => _remove(_acleda!),
                ),
              ],
            ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

// ── Section label ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(text,
      style: TextStyle(
          color: context.appTextSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5));
}

class _EmptyRow extends StatelessWidget {
  final String text;
  const _EmptyRow({required this.text});

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(14)),
        child: Text(text, style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
      );
}

// ── Add method entry tile ────────────────────────────────────────────────────

class _AddMethodTile extends StatelessWidget {
  final VoidCallback onTap;
  const _AddMethodTile({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.appSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _green.withValues(alpha: 0.3)),
          ),
          child: Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _green.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.add, color: _green, size: 20),
            ),
            const SizedBox(width: 12),
            Text(AppLocalizations.of(context).addMethodLabel,
                style: const TextStyle(color: _green, fontWeight: FontWeight.w700, fontSize: 14)),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: _green, size: 20),
          ]),
        ),
      );
}

// ── Card brand helpers ───────────────────────────────────────────────────────

String _brandLabel(CardBrand b) => switch (b) {
      CardBrand.visa => 'VISA',
      CardBrand.mastercard => 'MASTERCARD',
      CardBrand.paypal => 'PAYPAL',
    };

Color _brandColor(CardBrand b) => switch (b) {
      CardBrand.visa => const Color(0xFF1A1F71),
      CardBrand.mastercard => const Color(0xFFEB001B),
      CardBrand.paypal => const Color(0xFF003087),
    };

// ── Saved card / linked account tile ─────────────────────────────────────────

class _MethodTile extends StatelessWidget {
  final SavedPaymentMethod method;
  final VoidCallback onSetDefault;
  final VoidCallback onRemove;

  const _MethodTile({required this.method, required this.onSetDefault, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final color = method.brand != null ? _brandColor(method.brand!) : _green;
    final title = method.brand != null
        ? '${_brandLabel(method.brand!)} •••• ${method.last4}'
        : method.label;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(Icons.credit_card, color: color, size: 22),
          ),
          title: Text(title, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: method.brand != null
              ? Text(method.label, style: TextStyle(color: context.appTextSecondary, fontSize: 12))
              : null,
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (method.isDefault)
              Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: _green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(AppLocalizations.of(context).defaultBadge, style: const TextStyle(color: _green, fontSize: 10, fontWeight: FontWeight.w600)),
              ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: context.appTextSecondary, size: 20),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (_) => [
                if (!method.isDefault)
                  PopupMenuItem(value: 'default', child: Text(AppLocalizations.of(context).setAsDefaultOption)),
                PopupMenuItem(value: 'remove', child: Text(AppLocalizations.of(context).removeOption, style: const TextStyle(color: AppTheme.danger))),
              ],
              onSelected: (v) {
                if (v == 'default') onSetDefault();
                if (v == 'remove') onRemove();
              },
            ),
          ]),
        ),
      ),
    );
  }
}

class _LinkedAccountTile extends StatelessWidget {
  final String label;
  final Color color;
  final SavedPaymentMethod? method;
  final VoidCallback? onSetDefault;
  final VoidCallback? onRemove;

  const _LinkedAccountTile({
    required this.label,
    required this.color,
    required this.method,
    required this.onSetDefault,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final linked = method != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(14)),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
            child: Icon(Icons.account_balance, color: color, size: 22),
          ),
          title: Text(label, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Text(
            linked ? (method!.label.isEmpty ? AppLocalizations.of(context).linkedLabel : method!.label) : AppLocalizations.of(context).notLinkedLabel,
            style: TextStyle(color: linked ? _green : context.appTextSecondary, fontSize: 12),
          ),
          trailing: linked
              ? Row(mainAxisSize: MainAxisSize.min, children: [
                  if (method!.isDefault)
                    Container(
                      margin: const EdgeInsets.only(right: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: _green.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                      child: Text(AppLocalizations.of(context).defaultBadge, style: const TextStyle(color: _green, fontSize: 10, fontWeight: FontWeight.w600)),
                    ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert, color: context.appTextSecondary, size: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (_) => [
                      if (!method!.isDefault)
                        PopupMenuItem(value: 'default', child: Text(AppLocalizations.of(context).setAsDefaultOption)),
                      PopupMenuItem(value: 'remove', child: Text(AppLocalizations.of(context).unlinkOption, style: const TextStyle(color: AppTheme.danger))),
                    ],
                    onSelected: (v) {
                      if (v == 'default') onSetDefault?.call();
                      if (v == 'remove') onRemove?.call();
                    },
                  ),
                ])
              : Icon(Icons.chevron_right_rounded, color: context.appTextSecondary, size: 20),
        ),
      ),
    );
  }
}

// ── Add method bottom sheet ──────────────────────────────────────────────────

class _AddMethodSheet extends StatefulWidget {
  final bool abaLinked;
  final bool acledaLinked;
  const _AddMethodSheet({required this.abaLinked, required this.acledaLinked});

  @override
  State<_AddMethodSheet> createState() => _AddMethodSheetState();
}

class _AddMethodSheetState extends State<_AddMethodSheet> {
  PayMethodType? _picked;

  // Card form
  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  bool _cardIsDefault = false;

  // Linked account form
  final _phoneCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  // Detects the network from the card number prefix. Never persisted beyond
  // this — only the brand + last 4 digits are ever saved (see _submitCard).
  static CardBrand? _detectBrand(String digits) {
    if (digits.startsWith('4')) return CardBrand.visa;
    final prefix2 = digits.length >= 2 ? int.tryParse(digits.substring(0, 2)) : null;
    if (prefix2 != null && prefix2 >= 51 && prefix2 <= 55) return CardBrand.mastercard;
    final prefix4 = digits.length >= 4 ? int.tryParse(digits.substring(0, 4)) : null;
    if (prefix4 != null && prefix4 >= 2221 && prefix4 <= 2720) return CardBrand.mastercard;
    return null;
  }

  void _submitCard() {
    final digits = _cardNumberCtrl.text.replaceAll(' ', '');
    final expiry = _expiryCtrl.text.trim();
    final cvv = _cvvCtrl.text.trim();

    if (digits.length < 13 || digits.length > 19 || int.tryParse(digits) == null) {
      setState(() => _error = AppLocalizations.of(context).enterValidCardNumber);
      return;
    }
    final expiryMatch = RegExp(r'^(0[1-9]|1[0-2])/(\d{2})$').firstMatch(expiry);
    if (expiryMatch == null) {
      setState(() => _error = AppLocalizations.of(context).enterExpiryMMYY);
      return;
    }
    final expMonth = int.parse(expiryMatch.group(1)!);
    final expYear = 2000 + int.parse(expiryMatch.group(2)!);
    final now = DateTime.now();
    final expiryEnd = DateTime(expYear, expMonth + 1);
    if (expiryEnd.isBefore(now)) {
      setState(() => _error = AppLocalizations.of(context).cardExpiredError);
      return;
    }
    if (cvv.length < 3 || cvv.length > 4 || int.tryParse(cvv) == null) {
      setState(() => _error = AppLocalizations.of(context).enterValidCvv);
      return;
    }

    // Only the brand and last 4 digits are kept — the full number and CVV
    // are discarded once we derive what we need to display the card.
    Navigator.pop(context, SavedPaymentMethod(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: PayMethodType.card,
      brand: _detectBrand(digits),
      last4: digits.substring(digits.length - 4),
      label: '${AppLocalizations.of(context).expiresPrefix} $expiry',
      isDefault: _cardIsDefault,
    ));
  }

  void _submitLinked(PayMethodType type) {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).enterAccountPhoneNumber);
      return;
    }
    Navigator.pop(context, SavedPaymentMethod(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      label: phone,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(
          width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
        )),
        const SizedBox(height: 18),
        Text(_picked == null ? AppLocalizations.of(context).addPaymentMethodTitle : _titleFor(context, _picked!),
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
        const SizedBox(height: 18),

        if (_picked == null) ...[
          _MethodOption(
            icon: Icons.credit_card,
            color: const Color(0xFF1A1F71),
            label: AppLocalizations.of(context).cardOptionLabel,
            subtitle: AppLocalizations.of(context).cardOptionSubtitle,
            onTap: () => setState(() { _picked = PayMethodType.card; _error = null; }),
          ),
          const SizedBox(height: 10),
          _MethodOption(
            icon: Icons.account_balance,
            color: const Color(0xFF004B87),
            label: 'ABA Pay',
            subtitle: widget.abaLinked ? AppLocalizations.of(context).alreadyLinked : AppLocalizations.of(context).linkYourAbaAccount,
            enabled: !widget.abaLinked,
            onTap: () => setState(() { _picked = PayMethodType.aba; _error = null; }),
          ),
          const SizedBox(height: 10),
          _MethodOption(
            icon: Icons.account_balance,
            color: const Color(0xFF006B3F),
            label: 'ACLEDA Pay',
            subtitle: widget.acledaLinked ? AppLocalizations.of(context).alreadyLinked : AppLocalizations.of(context).linkYourAcledaAccount,
            enabled: !widget.acledaLinked,
            onTap: () => setState(() { _picked = PayMethodType.acleda; _error = null; }),
          ),
        ] else if (_picked == PayMethodType.card) ...[
          _SheetTextField(ctrl: _cardNumberCtrl, label: AppLocalizations.of(context).cardNumberLabel, hint: '1234 5678 9012 3456',
              keyboardType: TextInputType.number, maxLength: 19,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, _CardNumberFormatter()]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _SheetTextField(ctrl: _expiryCtrl, label: AppLocalizations.of(context).expiryDateLabel, hint: 'MM/YY',
                keyboardType: TextInputType.number, maxLength: 5,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, _ExpiryFormatter()])),
            const SizedBox(width: 12),
            Expanded(child: _SheetTextField(ctrl: _cvvCtrl, label: AppLocalizations.of(context).cvvLabel, hint: '123',
                keyboardType: TextInputType.number, maxLength: 4, obscureText: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly])),
          ]),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: Text(AppLocalizations.of(context).setAsDefaultSwitch, style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w600, fontSize: 14)),
            ),
            Switch(
              value: _cardIsDefault,
              activeColor: _green,
              onChanged: (v) => setState(() => _cardIsDefault = v),
            ),
          ]),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: _submitCard,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _green, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(AppLocalizations.of(context).addCardBtn, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ] else ...[
          _SheetTextField(ctrl: _phoneCtrl, label: AppLocalizations.of(context).phoneNumber, hint: AppLocalizations.of(context).phoneNumberHintExample,
              keyboardType: TextInputType.phone),
          if (_error != null) ...[
            const SizedBox(height: 4),
            Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity, height: 50,
            child: ElevatedButton(
              onPressed: () => _submitLinked(_picked!),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _green, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(AppLocalizations.of(context).linkAccountBtn, style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ]),
    );
  }

  String _titleFor(BuildContext context, PayMethodType t) => switch (t) {
        PayMethodType.card => AppLocalizations.of(context).addCardBtn,
        PayMethodType.aba => AppLocalizations.of(context).linkAbaPayTitle,
        PayMethodType.acleda => AppLocalizations.of(context).linkAcledaPayTitle,
      };
}

class _MethodOption extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  const _MethodOption({
    required this.icon,
    required this.color,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) => Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: enabled ? onTap : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F7F7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                Container(
                  width: 42, height: 30,
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: const TextStyle(color: Color(0xFF1A1A1A), fontWeight: FontWeight.w700, fontSize: 14)),
                  Text(subtitle, style: const TextStyle(color: Color(0xFF757575), fontSize: 12)),
                ])),
                const Icon(Icons.chevron_right, color: Color(0xFF757575)),
              ]),
            ),
          ),
        ),
      );
}

class _SheetTextField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;

  const _SheetTextField({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.maxLength,
    this.inputFormatters,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFF757575), fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            keyboardType: keyboardType,
            maxLength: maxLength,
            inputFormatters: inputFormatters,
            obscureText: obscureText,
            style: const TextStyle(color: Color(0xFF1A1A1A), fontSize: 14),
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              filled: true,
              fillColor: const Color(0xFFF7F7F7),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _green)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
          ),
        ],
      );
}

// ── Input formatters ─────────────────────────────────────────────────────────

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}

class _ExpiryFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('/', '');
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length && i < 4; i++) {
      if (i == 2) buffer.write('/');
      buffer.write(digits[i]);
    }
    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
