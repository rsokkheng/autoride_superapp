import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

/// A driver's "missed calls": ride / delivery / rental requests they declined
/// or didn't answer before the request timer ran out.
class DriverMissedRequestsScreen extends StatelessWidget {
  const DriverMissedRequestsScreen({super.key});

  static const _seenKey = 'driver_missed_seen_at';

  /// How many entries arrived since the driver last opened this screen
  /// (badge on the dashboard). Never throws.
  static Future<int> unseenCount() async {
    try {
      final seen = (await SharedPreferences.getInstance()).getString(_seenKey);
      final since = seen == null ? null : DateTime.tryParse(seen);
      final list = await ApiService.getMissedRequests();
      return list.where((r) {
        final at = DateTime.tryParse(r['at'] as String? ?? '');
        return at != null && (since == null || at.isAfter(since));
      }).length;
    } catch (_) {
      return 0;
    }
  }

  /// Clears the dashboard / Missions tab badge.
  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_seenKey, DateTime.now().toUtc().toIso8601String());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: context.appBackground,
    appBar: AppBar(
      backgroundColor: context.appSurface,
      elevation: 0,
      title: Text(AppLocalizations.of(context).missedRequestsTitle,
          style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
      iconTheme: IconThemeData(color: context.appTextPrimary),
    ),
    body: const DriverMissedRequestsView(),
  );
}

/// The missed-requests list (filter chips + entries) — used by the full
/// screen and by the "Missed" tab on the Missions page.
class DriverMissedRequestsView extends StatefulWidget {
  /// Mark the list as seen as soon as it's shown. The Missions page turns
  /// this off and marks it when its tab is actually selected instead.
  final bool markSeenOnOpen;
  const DriverMissedRequestsView({super.key, this.markSeenOnOpen = true});

  @override
  State<DriverMissedRequestsView> createState() => _DriverMissedRequestsViewState();
}

class _DriverMissedRequestsViewState extends State<DriverMissedRequestsView>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  List<Map<String, dynamic>> _items = [];
  bool    _loading = true;
  String? _error;
  String? _reason; // null = all, 'missed', 'declined'

  @override
  void initState() {
    super.initState();
    _load();
    if (widget.markSeenOnOpen) DriverMissedRequestsScreen.markSeen();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getMissedRequests();
      if (mounted) setState(() { _items = list; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context).connectionErrorRetry;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l = AppLocalizations.of(context);
    final visible = _reason == null
        ? _items
        : _items.where((r) => r['reason'] == _reason).toList();

    return Column(children: [
        // Filter: All / Missed / Declined
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(children: [
            for (final f in [(null, l.all), ('missed', l.missedTab), ('declined', l.declinedTab)]) ...[
              ChoiceChip(
                label: Text(f.$2),
                selected: _reason == f.$1,
                onSelected: (_) => setState(() => _reason = f.$1),
                selectedColor: AppTheme.accent.withValues(alpha: 0.15),
                labelStyle: TextStyle(
                  color: _reason == f.$1 ? AppTheme.accent : context.appTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(color: _reason == f.$1 ? AppTheme.accent : context.appCardBg),
                backgroundColor: context.appSurface,
                showCheckmark: false,
              ),
              const SizedBox(width: 8),
            ],
          ]),
        ),
        Expanded(child: _body(context, visible)),
      ]);
  }

  Widget _body(BuildContext context, List<Map<String, dynamic>> visible) {
    final l = AppLocalizations.of(context);
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    }
    if (_error != null) {
      return Center(child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(_error!, textAlign: TextAlign.center,
              style: TextStyle(color: context.appTextSecondary)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: _load, style: AppTheme.confirmButtonStyle(),
              child: Text(l.retry)),
        ]),
      ));
    }
    if (visible.isEmpty) {
      return RefreshIndicator(
        color: AppTheme.accent,
        onRefresh: _load,
        child: ListView(children: [
          const SizedBox(height: 120),
          Icon(Icons.phone_missed_outlined, size: 56,
              color: context.appTextSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 14),
          Center(child: Text(l.noMissedRequests, style: TextStyle(
              color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 16))),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(l.missedRequestsHint, textAlign: TextAlign.center,
                style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: visible.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) => _MissedTile(item: visible[i]),
      ),
    );
  }
}

class _MissedTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _MissedTile({required this.item});

  IconData get _typeIcon => switch (item['request_type']) {
    'delivery' => Icons.delivery_dining_outlined,
    'rental'   => Icons.car_rental_outlined,
    _          => Icons.electric_rickshaw,
  };

  String _typeLabel(AppLocalizations l) => switch (item['request_type']) {
    'delivery' => l.delivery,
    'rental'   => l.rental,
    _          => l.ride,
  };

  String _when(AppLocalizations l, DateTime? at) {
    if (at == null) return '';
    final local = at.toLocal();
    final now   = DateTime.now();
    final day   = DateTime(local.year, local.month, local.day);
    final today = DateTime(now.year, now.month, now.day);
    final time  = DateFormat('HH:mm').format(local);
    if (day == today) return time;
    if (day == today.subtract(const Duration(days: 1))) return '${l.yesterday} $time';
    return DateFormat('dd/MM/yyyy HH:mm').format(local);
  }

  @override
  Widget build(BuildContext context) {
    final l       = AppLocalizations.of(context);
    final summary = (item['summary'] as Map?)?.cast<String, dynamic>() ?? const {};
    final missed  = item['reason'] == 'missed';
    final pickup  = summary['pickup_address'] as String?;
    final dropoff = summary['dropoff_address'] as String?;
    final customer = summary['customer_name'] as String?;
    final fare    = (summary['fare_khr'] as num?)?.toInt() ?? 0;
    final at      = DateTime.tryParse(item['at'] as String? ?? '');

    final (outcomeText, outcomeColor) = switch (item['outcome']) {
      'open'  => (l.outcomeOpen, AppTheme.success),
      'taken' => (l.outcomeTaken, context.appTextSecondary),
      _       => (l.outcomeCancelled, AppTheme.danger),
    };
    final reasonColor = missed ? AppTheme.danger : context.appTextSecondary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Type icon with a missed/declined call badge
        SizedBox(
          width: 46, height: 46,
          child: Stack(clipBehavior: Clip.none, children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                  color: reasonColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(_typeIcon, color: reasonColor, size: 22),
            ),
            Positioned(right: -2, bottom: -2,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(color: context.appSurface, shape: BoxShape.circle),
                child: Icon(missed ? Icons.call_missed : Icons.call_end_rounded,
                    color: reasonColor, size: 15),
              ),
            ),
          ]),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(
              pickup?.isNotEmpty == true ? pickup! : '${_typeLabel(l)} #${item['request_id']}',
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: missed ? AppTheme.danger : context.appTextPrimary,
                  fontWeight: FontWeight.w700, fontSize: 14),
            )),
            const SizedBox(width: 8),
            Text(_when(l, at), style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
          ]),
          if (dropoff?.isNotEmpty == true) ...[
            const SizedBox(height: 2),
            Text('→ $dropoff', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
          ],
          const SizedBox(height: 4),
          Text(
            [
              _typeLabel(l),
              if (customer?.isNotEmpty == true) customer!,
              missed ? l.reasonMissed : l.reasonDeclined,
            ].join(' · '),
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: reasonColor, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: outcomeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(outcomeText, style: TextStyle(
                  color: outcomeColor, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
            const Spacer(),
            if (fare > 0)
              Text(AppTheme.khr(fare), style: TextStyle(
                  color: context.appTextPrimary, fontWeight: FontWeight.w800, fontSize: 14)),
          ]),
        ])),
      ]),
    );
  }
}
