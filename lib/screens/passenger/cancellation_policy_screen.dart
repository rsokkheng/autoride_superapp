import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'support_screen.dart';

class CancellationPolicyScreen extends StatelessWidget {
  const CancellationPolicyScreen({super.key});

  List<_PolicyItem> _policies(BuildContext context) {
    final l = AppLocalizations.of(context);
    return [
      _PolicyItem(
        title: l.beforeDriverAccepts,
        description: l.freeCancellation,
        detail: l.freeCancelBeforeAcceptDetail,
        color: AppTheme.success,
        icon: Icons.check_circle_outline,
        free: true,
      ),
      _PolicyItem(
        title: l.afterDriverAccepts0to2,
        description: l.freeCancellation,
        detail: l.gracePeriodDetail,
        color: AppTheme.success,
        icon: Icons.timer_outlined,
        free: true,
      ),
      _PolicyItem(
        title: l.afterDriverAccepts2to5,
        description: l.fee2000Riel,
        detail: l.smallCancelFeeDetail,
        color: AppTheme.warning,
        icon: Icons.warning_amber_outlined,
        free: false,
      ),
      _PolicyItem(
        title: l.afterDriverAccepts5plus,
        description: l.fee5000Riel,
        detail: l.higherFeeDetail,
        color: AppTheme.accentOrange,
        icon: Icons.timer_off_outlined,
        free: false,
      ),
      _PolicyItem(
        title: l.afterDriverArrives,
        description: l.fee10000Riel,
        detail: l.highestFeeDetail,
        color: AppTheme.danger,
        icon: Icons.location_on_outlined,
        free: false,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(title: Text(AppLocalizations.of(context).cancellationPolicyTitle)),
      body: Column(children: [
        Expanded(
          child: ListView(
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
              for (final p in _policies(context)) _PolicyTile(item: p),
              const SizedBox(height: 16),
            ],
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
  final bool free;
  const _PolicyItem({
    required this.title,
    required this.description,
    required this.detail,
    required this.color,
    required this.icon,
    required this.free,
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
