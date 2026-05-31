import 'package:flutter/material.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:autoride_superapp/widgets/common_widgets.dart';

class SafetyScreen extends StatefulWidget {
  const SafetyScreen({super.key});

  @override
  State<SafetyScreen> createState() => _SafetyScreenState();
}

class _SafetyScreenState extends State<SafetyScreen> {
  bool _shareLocation = true;
  bool _trustedContacts = true;
  bool _tripRecording = false;
  bool _sosEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Safety Center')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // SOS Button
            GestureDetector(
              onLongPress: () => _showSOSDialog(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.danger.withValues(alpha: 0.5), width: 2),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: AppTheme.danger, shape: BoxShape.circle),
                      child: const Icon(Icons.sos, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 12),
                    const Text('Emergency SOS', style: TextStyle(color: AppTheme.danger, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    const Text('Hold for 3 seconds to activate', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Safety Features'),
            const SizedBox(height: 14),
            _SafetyToggle(
              icon: Icons.location_on_outlined,
              title: 'Share Trip Location',
              subtitle: 'Trusted contacts can track your trip',
              value: _shareLocation,
              color: AppTheme.accent,
              onChanged: (v) => setState(() => _shareLocation = v),
            ),
            _SafetyToggle(
              icon: Icons.people_outline,
              title: 'Trusted Contacts',
              subtitle: 'Receive real-time trip updates',
              value: _trustedContacts,
              color: AppTheme.warning,
              onChanged: (v) => setState(() => _trustedContacts = v),
            ),
            _SafetyToggle(
              icon: Icons.mic_outlined,
              title: 'Trip Audio Recording',
              subtitle: 'Record trip for safety (auto-deleted in 24h)',
              value: _tripRecording,
              color: const Color(0xFF9C27B0),
              onChanged: (v) => setState(() => _tripRecording = v),
            ),
            _SafetyToggle(
              icon: Icons.shield_outlined,
              title: 'SOS Auto-Alert',
              subtitle: 'Auto-contact emergency services',
              value: _sosEnabled,
              color: AppTheme.danger,
              onChanged: (v) => setState(() => _sosEnabled = v),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Trusted Contacts'),
            const SizedBox(height: 14),
            _ContactCard(name: 'Mom', phone: '+855 12 111 222', relation: 'Family'),
            _ContactCard(name: 'John Doe', phone: '+855 12 333 444', relation: 'Friend'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {},
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add_outlined, color: AppTheme.accent),
                    SizedBox(width: 8),
                    Text('Add Trusted Contact', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Safety Resources'),
            const SizedBox(height: 14),
            ...[
              ('Emergency: 117 / 119', Icons.phone_in_talk_outlined, AppTheme.danger),
              ('Report Incident', Icons.report_outlined, AppTheme.warning),
              ('Safety Guidelines', Icons.menu_book_outlined, AppTheme.accent),
            ].map((item) => Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
              child: Row(children: [
                Icon(item.$2, color: item.$3, size: 20),
                const SizedBox(width: 12),
                Text(item.$1, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                const Spacer(),
                const Icon(Icons.chevron_right, color: AppTheme.textSecondary, size: 18),
              ]),
            )),
          ],
        ),
      ),
    );
  }

  void _showSOSDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('🆘 Emergency Alert', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Sending SOS to emergency contacts and services...', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary))),
          ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger), child: const Text('Confirm SOS')),
        ],
      ),
    );
  }
}

class _SafetyToggle extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool value;
  final Color color;
  final Function(bool) onChanged;

  const _SafetyToggle({required this.icon, required this.title, required this.subtitle, required this.value, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ]),
          ),
          Switch(value: value, onChanged: onChanged, activeColor: color),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  final String name, phone, relation;

  const _ContactCard({required this.name, required this.phone, required this.relation});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: AppTheme.accent.withValues(alpha: 0.2), radius: 20,
            child: Text(name[0], style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700))),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
              Text(phone, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
            ]),
          ),
          StatusBadge(label: relation, color: AppTheme.accent),
          const SizedBox(width: 8),
          const Icon(Icons.more_vert, color: AppTheme.textSecondary, size: 20),
        ],
      ),
    );
  }
}
