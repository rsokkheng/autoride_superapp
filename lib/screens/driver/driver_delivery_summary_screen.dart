import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../models/delivery_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../passenger/passenger_delivery_summary_screen.dart'
    show PassengerDeliverySummaryScreen;

/// Full-screen job summary shown to the driver right after a delivery /
/// moving job is completed. Replaces the old bottom sheet so the cash the
/// driver still has to collect is legible at a glance.
///
/// The [delivery] passed in is only the seed for the first frame — the record
/// is re-read from the API on open, because the amount the driver has to
/// collect must come from the server rather than from the completion response
/// the active-trip screen happened to receive.
class DriverDeliverySummaryScreen extends StatefulWidget {
  final DeliveryModel delivery;

  const DriverDeliverySummaryScreen({
    super.key,
    required this.delivery,
  });

  @override
  State<DriverDeliverySummaryScreen> createState() =>
      _DriverDeliverySummaryScreenState();
}

class _DriverDeliverySummaryScreenState
    extends State<DriverDeliverySummaryScreen> {
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
  /// and deliveries behind `/deliveries/{id}`.
  Future<void> _reload() async {
    setState(() {
      _refreshing   = true;
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
      // Keep the seed record on screen — the driver has just finished the job
      // and needs the collect amount, not an error page.
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

  bool get _isCash => delivery.paymentMethod.toLowerCase() == 'cash';

  bool get _isRecipientPay => delivery.paymentBy.toLowerCase() == 'recipient';

  /// Platform's cut and the driver's net take, both null when the API returned
  /// no payout information for this job — in that case the card falls back to
  /// showing the gross fee, labelled as such, rather than guessing a rate.
  int? get _commission => delivery.platformCommission;
  int? get _netFee     => delivery.netDriverFee;

  /// Cash the driver has to hand over / collect on the spot. The delivery fee
  /// only counts when the recipient is the payer — a sender-paid fee was
  /// already settled at booking time.
  int get _totalCollect {
    if (!_isCash) return 0;
    final package = _hasPackageAmount ? delivery.packageAmount! : 0;
    return _isRecipientPay ? delivery.fee + package : package;
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
              color: AppTheme.accentOrange,
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
                      color: AppTheme.success.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(children: [
                      Container(
                        width: 68, height: 68,
                        decoration: BoxDecoration(
                          color: AppTheme.success.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_circle_rounded,
                            color: AppTheme.success, size: 44),
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
                      const SizedBox(height: 6),
                      Text(
                        isMoving
                            ? l.movingJobDone
                            : l.packageDeliveredSuccessfully,
                        style: TextStyle(
                            color: context.appTextSecondary, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
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

                  // ── Recipient / completion info ───────────────────────────
                  _Card(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.jobInfo,
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
                    ],
                  )),
                  const SizedBox(height: 12),

                  // ── Earnings & cash to collect ────────────────────────────
                  _Card(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l.earnings,
                          style: TextStyle(
                              color: context.appTextSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 14),
                      // Gross job fee, then the platform's cut, then what the
                      // driver actually keeps.
                      _AmountRow(
                        label: isMoving ? l.movingFee : l.deliveryFee,
                        value: AppTheme.khr(delivery.fee),
                      ),
                      if (_commission != null) ...[
                        const SizedBox(height: 8),
                        _AmountRow(
                          label: l.platformFee,
                          value: '-${AppTheme.khr(_commission!)}',
                          valueColor: AppTheme.danger,
                        ),
                      ],
                      Divider(
                          color: Theme.of(context).dividerColor, height: 24),
                      Row(children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _netFee != null
                                    ? l.netDriverFee
                                    : l.driverFee,
                                style: TextStyle(
                                    color: context.appTextPrimary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700),
                              ),
                              if (_netFee == null)
                                Text(l.beforePlatformFee,
                                    style: TextStyle(
                                        color: context.appTextSecondary,
                                        fontSize: 11)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(AppTheme.khr(_netFee ?? delivery.fee),
                                style: TextStyle(
                                    color: AppTheme.accentOrange,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800)),
                            Text(AppTheme.usd((_netFee ?? delivery.fee) / 4000),
                                style: TextStyle(
                                    color: context.appTextSecondary,
                                    fontSize: 11)),
                          ],
                        ),
                      ]),
                      if (_hasPackageAmount) ...[
                        Divider(
                            color: Theme.of(context).dividerColor, height: 24),
                        _AmountRow(
                          label: l.packageAmount,
                          value: AppTheme.khr(delivery.packageAmount!),
                        ),
                        const SizedBox(height: 8),
                      ] else
                        const SizedBox(height: 8),
                      _AmountRow(
                        label: l.payment,
                        value: delivery.paymentMethod.toUpperCase(),
                      ),
                      const SizedBox(height: 8),
                      _AmountRow(
                        label: l.paidBy,
                        value: _isRecipientPay ? l.recipient : l.sender,
                      ),
                      if (_totalCollect > 0) ...[
                        Divider(
                            color: Theme.of(context).dividerColor, height: 24),
                        Row(children: [
                          Expanded(
                            child: Text(
                              _isRecipientPay
                                  ? l.collectFromRecipient
                                  : l.collectPackageAmount,
                              style: TextStyle(
                                  color: AppTheme.success,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(AppTheme.khr(_totalCollect),
                              style: TextStyle(
                                  color: AppTheme.success,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800)),
                        ]),
                      ],
                    ],
                  )),
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
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(l.backToDashboard,
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

/// Thin progress strip shown while the record is being re-read from the API.
class _RefreshBar extends StatelessWidget {
  const _RefreshBar();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
    child: Row(children: [
      SizedBox(
        width: 14, height: 14,
        child: CircularProgressIndicator(
            strokeWidth: 2, color: AppTheme.accentOrange),
      ),
      const SizedBox(width: 10),
      Text(AppLocalizations.of(context).updatingSummary,
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
  final Color? valueColor;
  const _AmountRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(
      child: Text(label,
          style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
    ),
    const SizedBox(width: 8),
    Text(value,
        style: TextStyle(
            color: valueColor ?? context.appTextPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600)),
  ]);
}
