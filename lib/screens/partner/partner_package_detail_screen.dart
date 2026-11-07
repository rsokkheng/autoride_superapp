import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../models/partner_package.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../passenger/delivery_tracking_screen.dart';
import 'partner_ui.dart';

/// One Partner package: status steps, driver, live map, QR, share & cancel.
class PartnerPackageDetailScreen extends StatefulWidget {
  final int packageId;
  const PartnerPackageDetailScreen({super.key, required this.packageId});

  @override
  State<PartnerPackageDetailScreen> createState() => _PartnerPackageDetailScreenState();
}

class _PartnerPackageDetailScreenState extends State<PartnerPackageDetailScreen> with WidgetsBindingObserver {
  PartnerPackage? _pkg;
  String? _error;
  bool _busy = false;
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
    // Keep the status fresh while the package is moving.
    _poll = Timer.periodic(const Duration(seconds: 15), (_) {
      if (_pkg != null && !_pkg!.isFinished) _load();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _poll?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final p = await ApiService.getPartnerPackage(widget.packageId);
      if (mounted) setState(() { _pkg = p; _error = null; });
    } on ApiException catch (e) {
      if (mounted && _pkg == null) setState(() => _error = e.message);
    } catch (_) {
      if (mounted && _pkg == null) setState(() => _error = AppLocalizations.of(context).connectionErrorRetry);
    }
  }

  Future<void> _cancel() async {
    final l = AppLocalizations.of(context);
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(l.pkCancelPackage),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(l.pkCancelConfirm),
          const SizedBox(height: 12),
          TextField(controller: reason, maxLength: 200, decoration: InputDecoration(labelText: l.pkCancelReason)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l.pkKeep)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.pkCancelPackage, style: const TextStyle(color: AppTheme.danger)),
          ),
        ],
      ),
    );
    final text = reason.text.trim();
    reason.dispose();
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final p = await ApiService.cancelPartnerPackage(widget.packageId, reason: text);
      if (mounted) setState(() { _pkg = p; _busy = false; });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.message), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating));
      _load();
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showQr(PartnerPackage p) {
    final l = AppLocalizations.of(context);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('${l.pkQrTitle} · ${p.code}', textAlign: TextAlign.center),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: QrImageView(data: p.qrPayload!, size: 220),
          ),
          const SizedBox(height: 10),
          Text(l.pkQrHint, textAlign: TextAlign.center, style: TextStyle(color: ctx.appTextSecondary, fontSize: 12.5)),
        ]),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l.ok))],
      ),
    );
  }

  void _openLiveMap(PartnerPackage p) {
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => DeliveryTrackingScreen(
        deliveryId: p.id,
        from: p.pickupAddress,
        to: p.dropoffAddress,
        fareDisplay: AppTheme.khr(p.fee),
        serviceType: 'delivery',
        recipientName: p.recipientName,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final p = _pkg;
    return Scaffold(
      appBar: AppBar(
        title: Text(p?.code ?? l.pkDetailTitle),
        actions: [
          if (p?.qrPayload != null)
            IconButton(onPressed: () => _showQr(p!), tooltip: l.pkQrTitle, icon: const Icon(Icons.qr_code_2_rounded)),
          if (p?.trackingUrl != null && !(p?.isFinished ?? true))
            IconButton(
              tooltip: l.pkShareLink,
              icon: const Icon(Icons.share_rounded),
              onPressed: () => Share.share(l.pkShareText(p!.code, p.trackingUrl!)),
            ),
        ],
      ),
      body: p == null
          ? Center(
              child: _error != null
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton(onPressed: _load, child: Text(l.tryAgain)),
                      ]),
                    )
                  : const CircularProgressIndicator(color: AppTheme.accent),
            )
          : RefreshIndicator(
              color: AppTheme.accent,
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  _header(p, l),
                  const SizedBox(height: 12),
                  _card(l.pkTimeline, Icons.timeline_rounded, _Steps(pkg: p)),
                  if (p.driver != null) ...[
                    const SizedBox(height: 12),
                    _driverCard(p, l),
                  ],
                  const SizedBox(height: 12),
                  _card(l.pkPackage, Icons.inventory_2_outlined, Column(children: [
                    _row(l.pkSender, '${p.senderName} · ${p.senderPhone}\n${p.pickupAddress}', Icons.trip_origin_rounded, AppTheme.accent),
                    _row(l.pkReceiver, '${p.recipientName} · ${p.recipientPhone}\n${p.dropoffAddress}', Icons.location_on_rounded, AppTheme.danger),
                    _row(l.pkPackageType, [
                      PackageUi.type(l, p.packageType),
                      PackageUi.size(l, p.size),
                      if (p.weight != null) '${p.weight!.toStringAsFixed(p.weight! % 1 == 0 ? 0 : 1)} kg',
                      if (p.serviceOption == 'express') l.pkExpress,
                    ].join(' · '), PackageUi.typeIcon(p.packageType), context.appTextSecondary),
                    if ((p.details ?? '').isNotEmpty) _row(l.pkDescription, p.details!, Icons.notes_rounded, context.appTextSecondary),
                    if ((p.reference ?? '').isNotEmpty) _row(l.pkReference, p.reference!, Icons.tag_rounded, context.appTextSecondary),
                    if ((p.notes ?? '').isNotEmpty) _row(l.pkNotes, p.notes!, Icons.sticky_note_2_outlined, context.appTextSecondary),
                    _row(l.pkCreated, PackageUi.date(p.createdAt), Icons.schedule_rounded, context.appTextSecondary),
                  ])),
                  const SizedBox(height: 12),
                  _card(l.pkPayment, Icons.payments_outlined, Column(children: [
                    _money(l.pkDeliveryFee, p.fee, l.pkPaymentByPartner),
                    if (p.codAmount > 0) _money(l.pkCod, p.codAmount, l.pkReceiver),
                  ])),
                  if (p.photoUrl != null || p.proofPhotoUrl != null) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      if (p.photoUrl != null) Expanded(child: _photo(l.pkPackage, p.photoUrl!)),
                      if (p.photoUrl != null && p.proofPhotoUrl != null) const SizedBox(width: 10),
                      if (p.proofPhotoUrl != null) Expanded(child: _photo(l.pkProofPhoto, p.proofPhotoUrl!)),
                    ]),
                  ],
                  if (p.canCancel) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _busy ? null : _cancel,
                        icon: const Icon(Icons.close_rounded, color: AppTheme.danger),
                        label: Text(l.pkCancelPackage, style: const TextStyle(color: AppTheme.danger)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.danger),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _header(PartnerPackage p, AppLocalizations l) {
    final c = PackageUi.color(p.status);
    final sub = switch (p.status) {
      'pending'   => l.pkWaitingConfirm,
      'confirmed' => l.pkFindingDriver,
      'failed'    => '${PackageUi.reason_(l, p.failureReason)} — ${l.pkReturningToShop}',
      'returned'  => PackageUi.reason_(l, p.failureReason),
      'cancelled' => p.cancellationReason ?? '',
      _           => '',
    };
    final note = (p.status == 'failed' || p.status == 'returned') ? p.failureNote : null;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: c.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(color: c, shape: BoxShape.circle),
          child: Icon(PackageUi.icon(p.status), color: Colors.white),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(PackageUi.status(l, p.status),
                style: TextStyle(color: context.appTextPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
            if (sub.isNotEmpty)
              Text(sub, style: TextStyle(color: context.appTextSecondary, fontSize: 12.5)),
            if (note != null && note.isNotEmpty)
              Text('“$note”', style: TextStyle(color: context.appTextSecondary, fontSize: 12, fontStyle: FontStyle.italic)),
          ]),
        ),
        if (p.isLive)
          ElevatedButton.icon(
            onPressed: () => _openLiveMap(p),
            style: AppTheme.confirmButtonStyle(),
            icon: const Icon(Icons.map_rounded, size: 18),
            label: Text(l.pkLiveMap),
          ),
      ]),
    );
  }

  Widget _driverCard(PartnerPackage p, AppLocalizations l) {
    final d = p.driver!;
    final phone = d['phone']?.toString() ?? '';
    final avatar = d['avatar_url']?.toString();
    final rating = double.tryParse(d['rating']?.toString() ?? '');
    return _card(l.pkDriver, Icons.two_wheeler_rounded, Row(children: [
      CircleAvatar(
        radius: 22,
        backgroundColor: AppTheme.accent.withValues(alpha: 0.12),
        backgroundImage: (avatar != null && avatar.isNotEmpty) ? NetworkImage(avatar) : null,
        child: (avatar == null || avatar.isEmpty) ? const Icon(Icons.person, color: AppTheme.accent) : null,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(d['name']?.toString() ?? '', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600)),
          Row(children: [
            const Icon(Icons.star_rounded, size: 15, color: AppTheme.gold),
            Text(' ${rating?.toStringAsFixed(1) ?? '--'}  ·  $phone',
                style: TextStyle(color: context.appTextSecondary, fontSize: 12.5)),
          ]),
        ]),
      ),
      if (phone.isNotEmpty && !p.isFinished)
        IconButton.filledTonal(
          onPressed: () => launchUrl(Uri.parse('tel:$phone')),
          tooltip: l.pkCall,
          icon: const Icon(Icons.call_rounded, color: AppTheme.accent),
        ),
    ]));
  }

  Widget _card(String title, IconData icon, Widget child) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18, color: AppTheme.accent),
            const SizedBox(width: 6),
            Text(title, style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 14.5)),
          ]),
          const SizedBox(height: 12),
          child,
        ]),
      );

  Widget _row(String label, String value, IconData icon, Color iconColor) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(color: context.appTextSecondary, fontSize: 11.5)),
              const SizedBox(height: 2),
              Text(value, style: TextStyle(color: context.appTextPrimary, fontSize: 13.5, height: 1.35)),
            ]),
          ),
        ]),
      );

  Widget _money(String label, int amount, String note) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: TextStyle(color: context.appTextPrimary, fontSize: 13.5)),
              Text(note, style: TextStyle(color: context.appTextSecondary, fontSize: 11.5)),
            ]),
          ),
          Text(AppTheme.khr(amount), style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
      );

  Widget _photo(String label, String url) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: 1,
            child: Image.network(url, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: context.appCardBg, child: const Icon(Icons.broken_image_outlined))),
          ),
        ),
      ]);
}

/// Workflow steps: Pending → Confirmed → Driver assigned → Picked up → In transit → Delivered.
class _Steps extends StatelessWidget {
  final PartnerPackage pkg;
  const _Steps({required this.pkg});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final times = <String, DateTime?>{for (final t in pkg.timeline) t.status: t.at};
    // Completed / in progress: the normal path. Cancelled, not delivered or
    // returned: the steps that actually happened, then the outcome.
    final offPath = const ['cancelled', 'failed', 'returned'].contains(pkg.status);
    final steps = offPath
        ? <String>[
            ...pkg.timeline.map((t) => t.status).where((s) => s != pkg.status && s != 'cancelled'),
            if (pkg.status == 'returned' && !pkg.timeline.any((t) => t.status == 'failed')) 'failed',
            pkg.status,
          ].toSet().toList()
        : PackageUi.statuses;
    final current = steps.indexOf(pkg.status);

    return Column(children: [
      for (var i = 0; i < steps.length; i++)
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Column(children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= current ? PackageUi.color(steps[i]) : context.appCardBg,
              ),
              child: Icon(i < current || (i == current && steps[i] == 'completed')
                      ? Icons.check_rounded
                      : PackageUi.icon(steps[i]),
                  size: 13, color: i <= current ? Colors.white : context.appTextSecondary),
            ),
            if (i < steps.length - 1)
              Container(width: 2, height: 26, color: i < current ? PackageUi.color(steps[i + 1]) : context.appCardBg),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(children: [
                Expanded(
                  child: Text(steps[i] == 'failed' ? PackageUi.statusOf(l, 'failed', pkg.failureReason) : PackageUi.status(l, steps[i]),
                      style: TextStyle(
                        color: i <= current ? context.appTextPrimary : context.appTextSecondary,
                        fontWeight: i == current ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 13.5,
                      )),
                ),
                if (times[steps[i]] != null)
                  Text(PackageUi.date(times[steps[i]]), style: TextStyle(color: context.appTextSecondary, fontSize: 11.5)),
              ]),
            ),
          ),
        ]),
    ]);
  }
}
