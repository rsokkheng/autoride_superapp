import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'driver_document_upload_screen.dart';
import 'driver_home.dart';

const _green  = Color(0xFF00C48C);
const _orange = Color(0xFFFF9800);

class DriverApprovalPendingScreen extends StatefulWidget {
  const DriverApprovalPendingScreen({super.key});

  @override
  State<DriverApprovalPendingScreen> createState() => _DriverApprovalPendingScreenState();
}

class _DriverApprovalPendingScreenState extends State<DriverApprovalPendingScreen> {
  DriverApprovalStatus? _status;
  bool    _loading = true;
  String? _error;
  Timer?  _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    // Poll every 30 seconds so driver sees update without manual refresh
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    if (_status == null) setState(() { _loading = true; _error = null; });
    try {
      final s = await ApiService.getDriverApprovalStatus();
      if (!mounted) return;
      setState(() { _status = s; _loading = false; });

      if (s.isApproved) {
        _pollTimer?.cancel();
        // Small delay so the green tick is visible before navigating
        await Future.delayed(const Duration(milliseconds: 800));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DriverHomeScreen()),
        );
      }
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Application Status',
            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: context.appTextSecondary),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading && _status == null
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error != null && _status == null
              ? _ErrorBody(error: _error!, onRetry: _load)
              : _Body(status: _status!, onRefresh: _load, loading: _loading),
    );
  }
}

// ── Main body ────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final DriverApprovalStatus status;
  final VoidCallback onRefresh;
  final bool loading;
  const _Body({required this.status, required this.onRefresh, required this.loading});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(children: [
        SizedBox(height: 12),
        _StatusHero(status: status),
        SizedBox(height: 28),

        if (status.serviceZone != null || status.city != null) ...[
          _InfoCard(status: status),
          SizedBox(height: 20),
        ],

        if (status.documents.isNotEmpty) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              status.isRejected ? 'Document Review Results' : 'Document Status',
              style: TextStyle(color: context.appTextPrimary,
                  fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(height: 12),
          ...status.documents.map((d) => _DocumentStatusTile(doc: d)),
        ],

        SizedBox(height: 24),
        if (status.isRejected) ...[
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.danger.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.danger.withValues(alpha: 0.3)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.info_outline, color: AppTheme.danger, size: 18),
                SizedBox(width: 8),
                Text('What to do next',
                    style: TextStyle(color: AppTheme.danger,
                        fontWeight: FontWeight.w700, fontSize: 13)),
              ]),
              SizedBox(height: 8),
              Text(
                'Please review the feedback on your documents above, then re-submit with corrected photos. Contact support if you need help.',
                style: TextStyle(color: context.appTextSecondary, fontSize: 12, height: 1.5),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DriverDocumentUploadScreen(userId: 0)),
                  ),
                  icon: Icon(Icons.upload_rounded, size: 18),
                  label: Text('Re-upload Documents'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.danger,
                    side: BorderSide(color: AppTheme.danger),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ]),
          ),
        ],

        SizedBox(height: 20),
        if (status.isPending)
          Text(
            'We\'ll notify you once your documents have been reviewed.\nTypically 1–2 business days.',
            style: TextStyle(color: context.appTextSecondary, fontSize: 12, height: 1.6),
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: loading ? null : onRefresh,
          icon: loading
              ? const SizedBox(width: 14, height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: _green))
              : const Icon(Icons.refresh_rounded, size: 16, color: _green),
          label: const Text('Refresh Status', style: TextStyle(color: _green)),
        ),
        const SizedBox(height: 24),
      ]),
    );
  }
}

// ── Status hero ───────────────────────────────────────────────────────────────

class _StatusHero extends StatelessWidget {
  final DriverApprovalStatus status;
  const _StatusHero({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color, title, subtitle) = status.isApproved
        ? (Icons.check_circle_rounded, _green,  'Approved!',        'You can now go online and accept rides.')
        : status.isRejected
        ? (Icons.cancel_rounded,       AppTheme.danger,  'Application Rejected', 'Please review your documents and re-submit.')
        : (Icons.hourglass_top_rounded, _orange, 'Under Review',    'Our team is reviewing your application.');

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 64),
        SizedBox(height: 14),
        Text(title,
            style: TextStyle(color: color, fontSize: 22, fontWeight: FontWeight.w800)),
        SizedBox(height: 6),
        Text(subtitle,
            style: TextStyle(color: context.appTextSecondary, fontSize: 13, height: 1.4),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ── Info card (zone / city) ───────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final DriverApprovalStatus status;
  const _InfoCard({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: [
        if (status.city != null)
          _Row(context, Icons.location_city_outlined, 'City', status.city!),
        if (status.serviceZone != null)
          _Row(context, Icons.map_outlined, 'Service Zone', status.serviceZone!),
      ]),
    );
  }

  Widget _Row(BuildContext context, IconData icon, String label, String value) => Padding(
    padding: EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      Icon(icon, color: context.appTextSecondary, size: 18),
      SizedBox(width: 10),
      Text('$label: ', style: TextStyle(color: context.appTextSecondary, fontSize: 13)),
      Text(value, style: TextStyle(color: context.appTextPrimary,
          fontWeight: FontWeight.w600, fontSize: 13)),
    ]),
  );
}

// ── Document status tile ──────────────────────────────────────────────────────

class _DocumentStatusTile extends StatelessWidget {
  final DriverDocument doc;
  const _DocumentStatusTile({required this.doc});

  static const _labels = {
    'id_card':              'National ID / Passport',
    'driver_license':       'Driver License',
    'vehicle_registration': 'Vehicle Registration',
    'selfie_with_id':       'Selfie with ID',
    'vehicle_insurance':    'Vehicle Insurance',
    'other':                'Other Document',
  };

  @override
  Widget build(BuildContext context) {
    final color = doc.isApproved
        ? _green
        : doc.isRejected
            ? AppTheme.danger
            : _orange;

    final icon = doc.isApproved
        ? Icons.check_circle_rounded
        : doc.isRejected
            ? Icons.cancel_rounded
            : Icons.hourglass_top_rounded;

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_labels[doc.type] ?? doc.type,
              style: TextStyle(color: context.appTextPrimary,
                  fontWeight: FontWeight.w600, fontSize: 13)),
          if (doc.note != null && doc.note!.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(doc.note!, style: TextStyle(color: color, fontSize: 11)),
          ],
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            doc.isApproved ? 'Approved' : doc.isRejected ? 'Rejected' : 'Pending',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ]),
    );
  }
}

// ── Error body ────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorBody({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded, color: context.appTextSecondary, size: 48),
          SizedBox(height: 16),
          Text(error, style: TextStyle(color: context.appTextSecondary),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: _green, foregroundColor: Colors.white),
            child: const Text('Retry'),
          ),
        ]),
      ),
    );
  }
}

