import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import 'support_screen.dart';

final _fmt = NumberFormat('#,###', 'en_US');

class CancellationPolicyScreen extends StatefulWidget {
  const CancellationPolicyScreen({super.key});

  @override
  State<CancellationPolicyScreen> createState() => _CancellationPolicyScreenState();
}

class _CancellationPolicyScreenState extends State<CancellationPolicyScreen> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = ApiService.getCancellationPolicy();
  }

  void _reload() => setState(() => _future = ApiService.getCancellationPolicy());

  List<_PolicyItem> _policies(BuildContext context, Map<String, dynamic> policy) {
    final l = AppLocalizations.of(context);
    final tiers = ((policy['tiers'] as List?) ?? const [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final tiersPerStage = <String, int>{};
    for (final t in tiers) {
      final stage = t['stage'] as String? ?? '';
      tiersPerStage[stage] = (tiersPerStage[stage] ?? 0) + 1;
    }
    var paidRank = 0;
    final items = <_PolicyItem>[];

    for (final t in tiers) {
      final stage = t['stage'] as String? ?? '';
      final from  = (t['from_minute'] as num?)?.toInt() ?? 0;
      final to    = (t['to_minute'] as num?)?.toInt();
      final fee   = (t['fee_khr'] as num?)?.toInt() ?? 0;
      final free  = fee <= 0;

      final stageLabel = switch (stage) {
        'before_accept' => l.beforeDriverAccepts,
        'after_arrival' => l.afterDriverArrives,
        _               => l.afterDriverAccepts,
      };
      final range = (tiersPerStage[stage] ?? 0) > 1
          ? (to != null ? l.cancelRangeMinutes(from, to) : l.cancelRangeFromMinutes(from))
          : null;

      final Color color;
      if (free) {
        color = AppTheme.success;
      } else {
        color = stage == 'after_arrival'
            ? AppTheme.danger
            : const [AppTheme.warning, AppTheme.accentOrange, AppTheme.danger]
                [(paidRank++).clamp(0, 2)];
      }

      items.add(_PolicyItem(
        title: range == null ? stageLabel : '$stageLabel ($range)',
        description: free ? l.freeCancellation : l.cancelFeeAmount(_fmt.format(fee)),
        detail: free
            ? (stage == 'before_accept'
                ? l.freeCancelBeforeAcceptDetail
                : l.cancelTierFreeDetail)
            : l.cancelTierFeeDetail(_fmt.format(fee)),
        color: color,
        icon: switch (stage) {
          'before_accept' => Icons.check_circle_outline,
          'after_arrival' => Icons.location_on_outlined,
          _               => free ? Icons.timer_outlined : Icons.warning_amber_outlined,
        },
      ));
    }
    return items;
  }

  Widget _buildPolicies(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
          );
        }
        if (snap.hasError || snap.data == null) {
          final l = AppLocalizations.of(context);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(children: [
              Icon(Icons.cloud_off_outlined, color: context.appTextSecondary, size: 36),
              const SizedBox(height: 10),
              Text(l.cancellationPolicyLoadFailed,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              TextButton(onPressed: _reload, child: Text(l.retry)),
            ]),
          );
        }
        return Column(children: [
          for (final p in _policies(context, snap.data!)) _PolicyTile(item: p),
        ]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(title: Text(AppLocalizations.of(context).cancellationPolicyTitle)),
      body: Column(children: [
        Expanded(
          child: RefreshIndicator(
        color: AppTheme.accent,
        onRefresh: () async => _reload(),
        child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                ),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: AppTheme.accent, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(context).feesGoToDriversNote,
                      style: const TextStyle(color: AppTheme.accent, fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ]),
              ),
              _buildPolicies(context),
              const SizedBox(height: 16),
            ],
          ),
      ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
              16, 8, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const SupportScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: const Icon(Icons.headset_mic_outlined),
              label: Text(AppLocalizations.of(context).contactSupport,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ),
      ]),
    );
  }
}

class _PolicyItem {
  final String title;
  final String description;
  final String detail;
  final Color color;
  final IconData icon;
  const _PolicyItem({
    required this.title,
    required this.description,
    required this.detail,
    required this.color,
    required this.icon,
  });
}

class _PolicyTile extends StatefulWidget {
  final _PolicyItem item;
  const _PolicyTile({required this.item});

  @override
  State<_PolicyTile> createState() => _PolicyTileState();
}

class _PolicyTileState extends State<_PolicyTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.item.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(widget.item.icon, color: widget.item.color, size: 20),
          ),
          title: Text(widget.item.title,
              style: TextStyle(color: context.appTextPrimary,
                  fontWeight: FontWeight.w600, fontSize: 14)),
          subtitle: Padding(
            padding: EdgeInsets.only(top: 2),
            child: Text(widget.item.description,
                style: TextStyle(color: widget.item.color,
                    fontWeight: FontWeight.w700, fontSize: 13)),
          ),
          trailing: Icon(
            _expanded ? Icons.expand_less : Icons.expand_more,
            color: context.appTextSecondary,
          ),
          onExpansionChanged: (v) => setState(() => _expanded = v),
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(widget.item.detail,
                  style: TextStyle(color: context.appTextSecondary,
                      fontSize: 13, height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}
