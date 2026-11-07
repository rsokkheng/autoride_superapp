import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../models/partner_package.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'partner_create_package_screen.dart';
import 'partner_packages_screen.dart';
import 'partner_register_screen.dart';
import 'partner_report_screen.dart';

/// Labels, colours and icons for Partner package statuses / sizes / types.
class PackageUi {
  PackageUi._();

  static const statuses = ['pending', 'confirmed', 'driver_assigned', 'picked_up', 'in_transit', 'completed'];

  static String status(AppLocalizations l, String s) => switch (s) {
        'pending'         => l.pkStatusPending,
        'confirmed'       => l.pkStatusConfirmed,
        'driver_assigned' => l.pkStatusDriverAssigned,
        'picked_up'       => l.pkStatusPickedUp,
        'in_transit'      => l.pkStatusInTransit,
        'completed'       => l.pkStatusCompleted,
        'failed'          => l.pkStatusFailed,
        'returned'        => l.pkStatusReturned,
        'cancelled'       => l.pkStatusCancelled,
        _                 => s,
      };

  /// Chip text: a not-delivered package shows why (e.g. "Cannot contact receiver").
  static String statusOf(AppLocalizations l, String s, String? reason) =>
      s == 'failed' && reason != null ? reason_(l, reason) : status(l, s);

  static String reason_(AppLocalizations l, String? r) => switch (r) {
        'cannot_contact'     => l.pkReasonCannotContact,
        'receiver_refused'   => l.pkReasonRefused,
        'wrong_address'      => l.pkReasonWrongAddress,
        'receiver_postponed' => l.pkReasonPostponed,
        _                    => l.pkReasonOther,
      };

  static Color color(String s) => switch (s) {
        'pending'                                     => AppTheme.warning,
        'confirmed'                                   => AppTheme.confirmBlue,
        'driver_assigned' || 'picked_up' || 'in_transit' => AppTheme.accentOrange,
        'completed'                                   => AppTheme.success,
        'failed'                                      => AppTheme.danger,
        'returned'                                    => const Color(0xFF6D4C41),
        'cancelled'                                   => AppTheme.textSecondary,
        _                                             => AppTheme.textSecondary,
      };

  static IconData icon(String s) => switch (s) {
        'pending'         => Icons.hourglass_top_rounded,
        'confirmed'       => Icons.verified_outlined,
        'driver_assigned' => Icons.two_wheeler_rounded,
        'picked_up'       => Icons.inventory_2_rounded,
        'in_transit'      => Icons.local_shipping_rounded,
        'completed'       => Icons.check_circle_rounded,
        'failed'          => Icons.phone_disabled_rounded,
        'returned'        => Icons.assignment_return_rounded,
        'cancelled'       => Icons.cancel_rounded,
        _                 => Icons.circle_outlined,
      };

  static String size(AppLocalizations l, String s) => switch (s) {
        'medium'      => l.pkSizeMedium,
        'large'       => l.pkSizeLarge,
        'extra_large' => l.pkSizeXL,
        _             => l.pkSizeSmall,
      };

  static const types = ['parcel', 'document', 'clothing', 'food', 'electronics', 'fragile', 'other'];

  static String type(AppLocalizations l, String? t) => switch (t) {
        'document'    => l.pkTypeDocument,
        'food'        => l.pkTypeFood,
        'clothing'    => l.pkTypeClothing,
        'electronics' => l.pkTypeElectronics,
        'fragile'     => l.pkTypeFragile,
        'other'       => l.pkTypeOther,
        _             => l.pkTypeParcel,
      };

  static IconData typeIcon(String? t) => switch (t) {
        'document'    => Icons.description_outlined,
        'food'        => Icons.lunch_dining_outlined,
        'clothing'    => Icons.checkroom_outlined,
        'electronics' => Icons.devices_other_outlined,
        'fragile'     => Icons.wine_bar_outlined,
        'other'       => Icons.category_outlined,
        _             => Icons.inventory_2_outlined,
      };

  static String date(DateTime? d) {
    if (d == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';
  }
}

class PackageStatusChip extends StatelessWidget {
  final String status;
  final String? reason;
  const PackageStatusChip(this.status, {super.key, this.reason});

  @override
  Widget build(BuildContext context) {
    final c = PackageUi.color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(PackageUi.icon(status), size: 13, color: c),
        const SizedBox(width: 4),
        Flexible(
          child: Text(PackageUi.statusOf(AppLocalizations.of(context), status, reason),
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: c, fontSize: 11.5, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}

/// Passenger home section. Normal passengers see nothing here; a registered
/// Partner sees its review state, and an approved Partner gets Create
/// Package / My Packages / Track Package / Package History.
class PartnerServicesSection extends StatefulWidget {
  const PartnerServicesSection({super.key});

  @override
  State<PartnerServicesSection> createState() => PartnerServicesSectionState();
}

class PartnerServicesSectionState extends State<PartnerServicesSection> {
  PartnerStatus _status = PartnerStatus.none;
  Map<String, dynamic>? _summary;

  @override
  void initState() {
    super.initState();
    reload();
  }

  /// Called by the home screen's pull-to-refresh.
  Future<void> reload() async {
    try {
      final s = await ApiService.getPartnerStatus();
      Map<String, dynamic>? sum;
      if (s.isPartner) {
        try { sum = await ApiService.getPartnerSummary(); } catch (_) {}
      }
      if (!mounted) return;
      setState(() { _status = s; _summary = sum; });
    } catch (_) {
      // Offline / not logged in — keep whatever was shown.
    }
  }

  Future<void> _open(Widget screen) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
    reload();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (_status.status == 'none') return const SizedBox.shrink();

    if (!_status.isPartner) {
      final rejected  = _status.status == 'rejected';
      final suspended = _status.status == 'suspended';
      final c = rejected || suspended ? AppTheme.danger : AppTheme.warning;
      return Padding(
        padding: const EdgeInsets.only(top: 20),
        child: Material(
          color: c.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: suspended ? null : () => _open(PartnerRegisterScreen(status: _status)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Icon(rejected || suspended ? Icons.error_outline_rounded : Icons.hourglass_top_rounded, color: c),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(suspended ? l.pkSuspendedTitle : rejected ? l.pkRejectedTitle : l.pkPendingTitle,
                        style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      suspended ? l.pkSuspendedBody : rejected ? (_status.rejectionReason ?? l.pkResubmit) : l.pkPendingBody,
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.appTextSecondary, fontSize: 12, height: 1.3),
                    ),
                  ]),
                ),
                if (!suspended) Icon(Icons.chevron_right, color: context.appTextSecondary),
              ]),
            ),
          ),
        ),
      );
    }

    final active = (_summary?['active'] as num?)?.toInt() ?? 0;
    final today  = (_summary?['today'] as num?)?.toInt() ?? 0;
    final cod    = (_summary?['cod_pending'] as num?)?.toInt() ?? 0;
    final tiles = [
      (Icons.add_box_rounded, l.pkCreatePackage, l.pkCreatePackageSub, AppTheme.accent,
          () => _open(const PartnerCreatePackageScreen())),
      (Icons.inventory_2_rounded, l.pkMyPackages, l.pkMyPackagesSub, AppTheme.confirmBlue,
          () => _open(const PartnerPackagesScreen(initialTab: 2))),
      (Icons.local_shipping_rounded, l.pkTrackPackage, active > 0 ? l.pkActiveCount(active) : l.pkTrackPackageSub,
          AppTheme.accentOrange, () => _open(const PartnerPackagesScreen(initialTab: 0))),
      (Icons.history_rounded, l.pkHistory, l.pkHistorySub, const Color(0xFF7C4DFF),
          () => _open(const PartnerPackagesScreen(initialTab: 1))),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.handshake_rounded, color: AppTheme.accent, size: 20),
          const SizedBox(width: 6),
          Expanded(
            child: Text(l.pkPartnerServices,
                style: TextStyle(color: context.appTextPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          if (_summary != null)
            Text(cod > 0 ? '${l.pkCodPending}: ${AppTheme.khr(cod)}' : l.pkTodayCount(today),
                style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
        ]),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.15,
          children: [
            for (final t in tiles)
              Material(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: t.$5,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(children: [
                      Container(
                        width: 38, height: 38,
                        decoration: BoxDecoration(color: t.$4.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
                        child: Icon(t.$1, color: t.$4, size: 21),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t.$2, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: context.appTextPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 2),
                          Text(t.$3, maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
                        ]),
                      ),
                    ]),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        // Reports — day / week / month
        Material(
          color: context.appSurface,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _open(const PartnerReportScreen()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(children: [
                Container(
                  width: 38, height: 38,
                  decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(11)),
                  child: const Icon(Icons.bar_chart_rounded, color: AppTheme.accent, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(l.pkReports, style: TextStyle(color: context.appTextPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      _summary == null
                          ? l.pkReportsSub
                          : l.pkTodaySummary(
                              (_summary?['today_completed'] as num?)?.toInt() ?? 0,
                              (_summary?['today_returned'] as num?)?.toInt() ?? 0,
                              active),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: context.appTextSecondary, fontSize: 11),
                    ),
                  ]),
                ),
                Icon(Icons.chevron_right, color: context.appTextSecondary),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
