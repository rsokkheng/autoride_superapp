import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'support_screen.dart';

class CancellationPolicyScreen extends StatelessWidget {
  const CancellationPolicyScreen({super.key});

  static const _policies = [
    _PolicyItem(
      title: 'Before driver accepts',
      description: 'Free cancellation',
      detail: 'You can cancel at any time before a driver accepts your ride with no charge.',
      color: AppTheme.success,
      icon: Icons.check_circle_outline,
      free: true,
    ),
    _PolicyItem(
      title: 'After driver accepts (0–2 min)',
      description: 'Free cancellation',
      detail: 'You have a 2-minute grace period after the driver accepts to cancel for free.',
      color: AppTheme.success,
      icon: Icons.timer_outlined,
      free: true,
    ),
    _PolicyItem(
      title: 'After driver accepts (2–5 min)',
      description: '2,000 ៛ fee',
      detail: 'A small cancellation fee applies if you cancel 2–5 minutes after the driver accepts.',
      color: AppTheme.warning,
      icon: Icons.warning_amber_outlined,
      free: false,
    ),
    _PolicyItem(
      title: 'After driver accepts (5+ min)',
      description: '5,000 ៛ fee',
      detail: 'If you cancel more than 5 minutes after acceptance, a higher fee applies.',
      color: AppTheme.accentOrange,
      icon: Icons.timer_off_outlined,
      free: false,
    ),
    _PolicyItem(
      title: 'After driver arrives',
      description: '10,000 ៛ fee',
      detail: 'Cancelling after the driver arrives at your pickup location incurs the highest fee.',
      color: AppTheme.danger,
      icon: Icons.location_on_outlined,
      free: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(title: const Text('Cancellation Policy')),
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
                child: const Row(children: [
                  Icon(Icons.info_outline, color: AppTheme.accent, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Fees go to drivers as compensation for their time.',
                      style: TextStyle(color: AppTheme.accent, fontSize: 13,
                          fontWeight: FontWeight.w500),
                    ),
                  ),
                ]),
              ),
              for (final p in _policies) _PolicyTile(item: p),
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
              label: const Text('Contact Support',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
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
