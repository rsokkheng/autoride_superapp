import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/delivery_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// Receipt shown to the sender once a delivery / moving job is finished.
///
/// Reached from the "Delivered!" banner and the "View Summary" action on
/// [DeliveryTrackingScreen], and pushed as a replacement after the rating
/// dialog is submitted.
///
/// The [delivery] passed in is only the seed used to paint the first frame —
/// the screen re-reads the record from the API on open so the receipt shows
/// what the server actually settled (final fee, package amount, driver,
/// rating), not whatever the tracking screen happened to be holding.
class PassengerDeliverySummaryScreen extends StatefulWidget {
  final DeliveryModel delivery;

  /// Fare string the tracking screen already had on hand. Used when the
  /// completion response comes back with `fee == 0`, which the backend has
  /// been observed doing for a scheduled job.
  final String? fareDisplay;

  const PassengerDeliverySummaryScreen({
    super.key,
    required this.delivery,
    this.fareDisplay,
  });

  static const _kMonths = {
    'en': ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
           'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'],
    'km': ['មករា', 'កុម្ភៈ', 'មីនា', 'មេសា', 'ឧសភា', 'មិថុនា',
           'កក្កដា', 'សីហា', 'កញ្ញា', 'តុលា', 'វិច្ឆិកា', 'ធ្នូ'],
    'zh': ['1月', '2月', '3月', '4月', '5月', '6月',
           '7月', '8月', '9月', '10月', '11月', '12月'],
  };

  /// Formats an ISO-8601 timestamp from the API as e.g. `30 Aug 2026, 17:45`,
  /// with the month name in [locale]'s language (English when omitted).
  /// Returns `--` for a missing or unparseable value — several delivery
  /// endpoints omit `updated_at` entirely on a freshly created record.
  static String formatDateTimeStr(String? iso, {Locale? locale}) {
    if (iso == null || iso.isEmpty) return '--';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '--';
    final months = _kMonths[locale?.languageCode] ?? _kMonths['en']!;
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hh:$mm';
  }

  @override
  State<PassengerDeliverySummaryScreen> createState() =>
      _PassengerDeliverySummaryScreenState();
}

class _PassengerDeliverySummaryScreenState
    extends State<PassengerDeliverySummaryScreen> {
  static const _kGreen = Color(0xFF00B14F);

  late DeliveryModel delivery;
  bool    _refreshing = false;
  String? _refreshError;

  @override
  void initState() {
    super.initState();
    delivery = widget.delivery;
    _reload();
  }

  /// Re-reads the record from the API. Moving jobs live behind `/movings/{id}`
  /// and deliveries behind `/deliveries/{id}`, so pick the endpoint from the
  /// service type we already know.
  Future<void> _reload() async {
    setState(() {
      _refreshing  = true;
      _refreshError = null;
    });
    try {
      final fresh = delivery.isMoving
          ? await ApiService.getMoving(delivery.id)
          : await ApiService.getDelivery(delivery.id);
      if (!mounted) return;
      setState(() {
        delivery    = fresh;
        _refreshing = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      // Keep showing the seed record — a stale receipt is far better than an
      // error page for a job the sender has already completed.
      setState(() {
        _refreshing   = false;
        _refreshError = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _refreshing   = false;
        _refreshError = AppLocalizations.of(context).couldNotRefresh;
      });
    }
  }

  bool get _hasPackageAmount =>
      delivery.packageAmount != null && delivery.packageAmount! > 0;

  int get _fee => delivery.fee > 0
      ? delivery.fee
      : (_khrFromDisplay(widget.fareDisplay) ?? 0);

  int get _total => _fee + (_hasPackageAmount ? delivery.packageAmount! : 0);

  /// Recovers a plain integer from a formatted fare like `"12,000 ៛"`.
  static int? _khrFromDisplay(String? display) {
    if (display == null) return null;
    final digits = display.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? null : int.tryParse(digits);
  }

  /// Brand names (ABA, ACLEDA, Wing, ROTEH Pay) are proper nouns and stay
  /// untranslated; only the generic methods are localized.
  String _paymentLabel(AppLocalizations l) {
    switch (delivery.paymentMethod.toLowerCase()) {
      case 'aba':          return 'ABA Pay';
      case 'acleda':       return 'ACLEDA';
      case 'wing':         return 'Wing';
      case 'wallet':       return 'ROTEH Pay';
      case 'other_online': return l.onlinePay;
      default:             return l.cash;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l        = AppLocalizations.of(context);
    final isMoving = delivery.isMoving;

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        child: Column(children: [
          if (_refreshing) const _RefreshBar(),
          if (_refreshError != null)
            _RefreshErrorBar(message: _refreshError!, onRetry: _reload),
          Expanded(
            child: RefreshIndicator(
              color: _kGreen,
              onRefresh: _reload,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Success header ────────────────────────────────────────
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: BoxDecoration(
                      color: _kGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(children: [
                      Container(
                        width: 68, height: 68,
                        decoration: const BoxDecoration(
                            color: _kGreen, shape: BoxShape.circle),
                        child: const Icon(Icons.check,
                            color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        isMoving ? l.movingCompleted : l.deliveryCompleted,
                        style: TextStyle(
                            color: context.appTextPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text('${l.order} #${delivery.id}',
                          style: TextStyle(
                              color: context.appTextSecondary, fontSize: 13)),
                    ]),
                  ),
                  const SizedBox(height: 16),

                  // ── Route ─────────────────────────────────────────────────
                  _Card(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isMoving ? l.movingDetails : l.deliveryDetails,
                          style: TextStyle(
                              color: context.appTextPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(height: 14),
                      _AddressRow(
                        icon: Icons.radio_button_checked,
                        color: AppTheme.success,
                        label: l.pickup,
                        address: delivery.pickupAddress,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 9),
                        child: Container(
                            width: 2, height: 20, color: context.appCardBg),
                      ),
                      _AddressRow(
                        icon: Icons.location_on,
                        color: AppTheme.danger,
                        label: l.dropoff,
                        address: delivery.dropoffAddress,
                      ),
                    ],
                  )),
                  const SizedBox(height: 12),

                  // ── Completion info ───────────────────────────────────────
                  _Card(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.orderInfo,
                          style: TextStyle(
                              color: context.appTextSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 14),
                      _InfoRow(
                        icon: Icons.access_time_filled,
                        label: l.completedAt,
                        value: PassengerDeliverySummaryScreen
                            .formatDateTimeStr(delivery.updatedAt,
                                locale: Localizations.localeOf(context)),
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: l.recipient,
                        value: delivery.recipientName ?? '--',
                      ),
                      if ((delivery.recipientPhone ?? '').isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: l.phone,
                          value: delivery.recipientPhone!,
                        ),
                      ],
                      if (delivery.packageDetails.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.inventory_2_outlined,
                          label: l.package,
                          value: delivery.packageDetails,
                        ),
                      ],
                      if (delivery.driver != null) ...[
                        const SizedBox(height: 10),
                        _InfoRow(
                          icon: Icons.two_wheeler_outlined,
                          label: l.driver,
                          value: delivery.driver!.name,
                        ),
                      ],
                    ],
                  )),
                  const SizedBox(height: 12),

                  // ── Payment summary ───────────────────────────────────────
                  _Card(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.paymentSummary,
                          style: TextStyle(
                              color: context.appTextSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 14),
                      _AmountRow(
                        label: isMoving ? l.movingFee : l.deliveryFee,
                        value: AppTheme.khr(_fee),
                      ),
                      if (_hasPackageAmount) ...[
                        const SizedBox(height: 8),
                        _AmountRow(
                          label: l.packageAmount,
                          value: AppTheme.khr(delivery.packageAmount!),
                        ),
                      ],
                      const SizedBox(height: 8),
                      _AmountRow(
                        label: l.paidBy,
                        value: delivery.paymentBy.toLowerCase() == 'recipient'
                            ? l.recipient
                            : l.sender,
                      ),
                      const SizedBox(height: 8),
                      _AmountRow(
                        label: l.paymentMethod,
                        value: _paymentLabel(l),
                      ),
                      Divider(color: Theme.of(context).dividerColor, height: 24),
                      Row(children: [
                        Text(l.total,
                            style: TextStyle(
                                color: context.appTextPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        const Spacer(),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(AppTheme.khr(_total),
                                style: const TextStyle(
                                    color: _kGreen,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 18)),
                            Text(AppTheme.usd(_total / 4000),
                                style: TextStyle(
                                    color: context.appTextSecondary,
                                    fontSize: 11)),
                          ],
                        ),
                      ]),
                    ],
                  )),

                  if (delivery.rating != null) ...[
                    const SizedBox(height: 12),
                    _Card(child: Row(children: [
                      const Icon(Icons.star_rounded,
                          color: Color(0xFFFACC15), size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${l.youRated} ${delivery.rating!.toStringAsFixed(1)}',
                          style: TextStyle(
                              color: context.appTextPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ])),
                  ],
                  const SizedBox(height: 24),
                ],
                ),
              ),
            ),
          ),

          // ── Bottom button ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kGreen,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(l.backToHome,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Local widgets ────────────────────────────────────────────────────────────

/// Thin progress strip shown while the record is being re-read from the API,
/// so the seed data on screen is visibly provisional.
class _RefreshBar extends StatelessWidget {
  const _RefreshBar();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
    child: Row(children: [
      const SizedBox(
        width: 14, height: 14,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: Color(0xFF00B14F)),
      ),
      const SizedBox(width: 10),
      Text(AppLocalizations.of(context).updatingReceipt,
          style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
    ]),
  );
}

class _RefreshErrorBar extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;
  const _RefreshErrorBar({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppTheme.warning.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(children: [
      Icon(Icons.cloud_off_outlined, size: 16, color: AppTheme.warning),
      const SizedBox(width: 8),
      Expanded(
        child: Text(message,
            style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
      ),
      TextButton(
        onPressed: onRetry,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          minimumSize: const Size(0, 32),
          foregroundColor: AppTheme.warning,
        ),
        child: Text(AppLocalizations.of(context).retry,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ),
    ]),
  );
}

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: context.appSurface,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String address;

  const _AddressRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: color, size: 20),
    const SizedBox(width: 12),
    Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  color: context.appTextSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
          Text(address,
              style: TextStyle(
                  color: context.appTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    ),
  ]);
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 15, color: context.appTextSecondary),
    const SizedBox(width: 8),
    Expanded(
      child: Text(label,
          style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
    ),
    const SizedBox(width: 8),
    Flexible(
      child: Text(value,
          textAlign: TextAlign.end,
          style: TextStyle(
              color: context.appTextPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600),
          maxLines: 2,
          overflow: TextOverflow.ellipsis),
    ),
  ]);
}

class _AmountRow extends StatelessWidget {
  final String label;
  final String value;
  const _AmountRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(
      child: Text(label,
          style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
    ),
    const SizedBox(width: 8),
    Text(value,
        style: TextStyle(
            color: context.appTextPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600)),
  ]);
}
