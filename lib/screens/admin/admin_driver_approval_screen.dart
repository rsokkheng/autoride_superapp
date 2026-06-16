import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

const _green = Color(0xFF00C48C);

// ── Main list screen ──────────────────────────────────────────────────────────

class AdminDriverApprovalScreen extends StatefulWidget {
  const AdminDriverApprovalScreen({super.key});

  @override
  State<AdminDriverApprovalScreen> createState() => _AdminDriverApprovalScreenState();
}

class _AdminDriverApprovalScreenState extends State<AdminDriverApprovalScreen> {
  List<Map<String, dynamic>> _drivers = [];
  bool    _loading = true;
  String? _error;
  final Set<int> _processing = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getAdminPendingDrivers();
      if (mounted) setState(() { _drivers = list; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _quickAction(Map<String, dynamic> driver, String action) async {
    final id = driver['id'] as int;
    setState(() => _processing.add(id));
    try {
      await ApiService.adminApproveDriver(id, action: action);
      if (!mounted) return;
      setState(() {
        _drivers.removeWhere((d) => d['id'] == id);
        _processing.remove(id);
      });
      _snack(action == 'approve' ? 'Driver approved' : 'Driver rejected',
             action == 'approve' ? _green : AppTheme.danger);
    } on ApiException catch (e) {
      if (mounted) { setState(() => _processing.remove(id)); _snack(e.message, AppTheme.danger); }
    } catch (_) {
      if (mounted) setState(() => _processing.remove(id));
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: AppTheme.surface, elevation: 0,
        title: const Text('Driver Applications',
            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: const TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, child: const Text('Retry'),
                      style: ElevatedButton.styleFrom(backgroundColor: _green)),
                ]))
              : _drivers.isEmpty
                  ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.check_circle_outline_rounded, color: _green, size: 56),
                      SizedBox(height: 12),
                      Text('No pending applications',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: _green,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _drivers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) {
                          final d  = _drivers[i];
                          final id = d['id'] as int;
                          final processing = _processing.contains(id);
                          return _DriverCard(
                            driver:     d,
                            processing: processing,
                            onReview:   () => Navigator.push(ctx, MaterialPageRoute(
                              builder: (_) => AdminDriverDetailScreen(driverId: id,
                                  driverName: d['name'] as String? ?? 'Driver #$id'),
                            )).then((_) => _load()),
                            onApprove: () => _quickAction(d, 'approve'),
                            onReject:  () => _showRejectDialog(d),
                          );
                        },
                      ),
                    ),
    );
  }

  Future<void> _showRejectDialog(Map<String, dynamic> driver) async {
    final reasonCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Reject Driver', style: TextStyle(color: AppTheme.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Provide a reason (optional):',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: reasonCtrl,
            maxLines: 3,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'e.g. Documents unclear, ID expired…',
              hintStyle: TextStyle(color: AppTheme.textSecondary),
              filled: true, fillColor: AppTheme.primary,
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final id = driver['id'] as int;
      setState(() => _processing.add(id));
      try {
        await ApiService.adminApproveDriver(id, action: 'reject',
            reason: reasonCtrl.text.trim().isEmpty ? null : reasonCtrl.text.trim());
        if (!mounted) return;
        setState(() { _drivers.removeWhere((d) => d['id'] == id); _processing.remove(id); });
        _snack('Driver rejected', AppTheme.danger);
      } on ApiException catch (e) {
        if (mounted) { setState(() => _processing.remove(id)); _snack(e.message, AppTheme.danger); }
      } catch (_) {
        if (mounted) setState(() => _processing.remove(id));
      }
    }
    reasonCtrl.dispose();
  }
}

// ── Driver card ───────────────────────────────────────────────────────────────

class _DriverCard extends StatelessWidget {
  final Map<String, dynamic> driver;
  final bool processing;
  final VoidCallback onReview;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  const _DriverCard({
    required this.driver, required this.processing,
    required this.onReview, required this.onApprove, required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final name  = driver['name']  as String? ?? 'Unknown';
    final email = driver['email'] as String? ?? '';
    final type  = driver['driver_type'] as String? ?? '';
    final city  = driver['city']  as String? ?? '';
    final phone = driver['phone'] as String? ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            backgroundColor: _green.withValues(alpha: 0.15),
            radius: 22,
            child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(color: _green, fontWeight: FontWeight.w700, fontSize: 18)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700, fontSize: 15)),
            Text(email, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          ])),
          GestureDetector(
            onTap: onReview,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('Review Docs',
                  style: TextStyle(color: AppTheme.accent,
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
        if (type.isNotEmpty || city.isNotEmpty || phone.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 6, children: [
            if (type.isNotEmpty) _Chip(Icons.badge_outlined, type),
            if (city.isNotEmpty) _Chip(Icons.location_city_outlined, city),
            if (phone.isNotEmpty) _Chip(Icons.phone_outlined, phone),
          ]),
        ],
        const SizedBox(height: 14),
        if (processing)
          const Center(child: SizedBox(width: 24, height: 24,
              child: CircularProgressIndicator(color: _green, strokeWidth: 2.5)))
        else
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onReject,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.danger,
                  side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.6)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton(
                onPressed: onApprove,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green, foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
      ]),
    );
  }
}

Widget _Chip(IconData icon, String label) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  decoration: BoxDecoration(
    color: AppTheme.cardBg, borderRadius: BorderRadius.circular(6)),
  child: Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, color: AppTheme.textSecondary, size: 12),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
  ]),
);

// ── Driver detail / document review screen ────────────────────────────────────

class AdminDriverDetailScreen extends StatefulWidget {
  final int    driverId;
  final String driverName;
  const AdminDriverDetailScreen({super.key, required this.driverId, required this.driverName});

  @override
  State<AdminDriverDetailScreen> createState() => _AdminDriverDetailScreenState();
}

class _AdminDriverDetailScreenState extends State<AdminDriverDetailScreen> {
  Map<String, dynamic>? _data;
  bool    _loading = true;
  String? _error;
  final Set<int> _processing = {};
  bool _finalizing = false;

  static const _docLabels = {
    'id_card':              'National ID / Passport',
    'driver_license':       'Driver License',
    'vehicle_registration': 'Vehicle Registration',
    'selfie_with_id':       'Selfie with ID',
    'vehicle_insurance':    'Vehicle Insurance',
    'other':                'Other Document',
  };

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await ApiService.adminGetDriverWithDocuments(widget.driverId);
      if (mounted) setState(() { _data = data; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _reviewDoc(Map<String, dynamic> doc, String action) async {
    final docId = doc['id'] as int;
    String? note;
    if (action == 'reject') {
      final ctrl = TextEditingController();
      note = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Reject Document', style: TextStyle(color: AppTheme.textPrimary)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            style: const TextStyle(color: AppTheme.textPrimary),
            decoration: const InputDecoration(
              hintText: 'Reason (e.g. Image too blurry)',
              hintStyle: TextStyle(color: AppTheme.textSecondary),
              filled: true, fillColor: AppTheme.primary,
              border: OutlineInputBorder(borderSide: BorderSide.none),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
              child: const Text('Reject', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      ctrl.dispose();
      if (note == null) return;
    }

    setState(() => _processing.add(docId));
    try {
      await ApiService.adminReviewDriverDocument(
        widget.driverId, docId, action: action, note: note,
      );
      if (mounted) await _load();
    } on ApiException catch (e) {
      if (mounted) _snack(e.message, AppTheme.danger);
    } catch (_) {}
    if (mounted) setState(() => _processing.remove(docId));
  }

  Future<void> _finalizeApproval(String action) async {
    String? serviceZone;
    if (action == 'approve') {
      final ctrl = TextEditingController();
      serviceZone = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: AppTheme.surface,
          title: const Text('Approve Driver', style: TextStyle(color: AppTheme.textPrimary)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Service zone (optional):',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: ctrl,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g. Phnom Penh Zone A',
                hintStyle: TextStyle(color: AppTheme.textSecondary),
                filled: true, fillColor: AppTheme.primary,
                border: OutlineInputBorder(borderSide: BorderSide.none),
              ),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim().isEmpty ? '' : ctrl.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: _green),
              child: const Text('Confirm Approve', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
      ctrl.dispose();
      if (serviceZone == null) return;
    }

    setState(() => _finalizing = true);
    try {
      await ApiService.adminApproveDriver(widget.driverId,
          action: action,
          serviceZone: serviceZone?.isEmpty == true ? null : serviceZone);
      if (!mounted) return;
      _snack(action == 'approve' ? 'Driver approved!' : 'Driver rejected',
             action == 'approve' ? _green : AppTheme.danger);
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) _snack(e.message, AppTheme.danger);
    } catch (_) {}
    if (mounted) setState(() => _finalizing = false);
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        backgroundColor: AppTheme.surface, elevation: 0,
        title: Text(widget.driverName,
            style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppTheme.textSecondary),
              onPressed: _loading ? null : _load),
        ],
      ),
      body: _loading && _data == null
          ? const Center(child: CircularProgressIndicator(color: _green))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, style: const TextStyle(color: AppTheme.textSecondary)),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _load, child: const Text('Retry'),
                      style: ElevatedButton.styleFrom(backgroundColor: _green)),
                ]))
              : Column(children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                        // Driver info card
                        _InfoSection(data: _data!),
                        const SizedBox(height: 20),

                        // Documents
                        const Text('Documents',
                            style: TextStyle(color: AppTheme.textPrimary,
                                fontSize: 15, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        ...(() {
                          final docs = (_data!['documents'] as List<dynamic>? ?? [])
                              .whereType<Map<String, dynamic>>()
                              .toList();
                          if (docs.isEmpty) {
                            return [const Center(child: Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('No documents uploaded yet.',
                                  style: TextStyle(color: AppTheme.textSecondary)),
                            ))];
                          }
                          return docs.map((doc) {
                            final docId  = doc['id'] as int? ?? 0;
                            final type   = doc['type']   as String? ?? '';
                            final status = doc['status'] as String? ?? 'pending';
                            final url    = doc['file_url'] as String?;
                            final note   = doc['note']    as String?;
                            final busy   = _processing.contains(docId);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.surface,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(child: Text(_docLabels[type] ?? type,
                                      style: const TextStyle(color: AppTheme.textPrimary,
                                          fontWeight: FontWeight.w600, fontSize: 13))),
                                  _StatusBadge(status),
                                ]),
                                if (note != null && note.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text('Note: $note',
                                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                                ],
                                if (url != null) ...[
                                  const SizedBox(height: 8),
                                  GestureDetector(
                                    onTap: () { /* open image viewer */ },
                                    child: Container(
                                      height: 110,
                                      width: double.infinity,
                                      decoration: BoxDecoration(
                                        color: AppTheme.cardBg,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Center(child: Column(
                                        mainAxisSize: MainAxisSize.min, children: [
                                          Icon(Icons.image_outlined, color: AppTheme.textSecondary, size: 32),
                                          SizedBox(height: 4),
                                          Text('View Document', style: TextStyle(
                                              color: AppTheme.textSecondary, fontSize: 12)),
                                        ],
                                      )),
                                    ),
                                  ),
                                ],
                                if (status == 'pending') ...[
                                  const SizedBox(height: 10),
                                  if (busy)
                                    const Center(child: SizedBox(width: 22, height: 22,
                                        child: CircularProgressIndicator(color: _green, strokeWidth: 2.5)))
                                  else
                                    Row(children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => _reviewDoc(doc, 'reject'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: AppTheme.danger,
                                            side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.5)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          child: const Text('Reject', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => _reviewDoc(doc, 'approve'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: _green, foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                          ),
                                          child: const Text('Approve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                                        ),
                                      ),
                                    ]),
                                ],
                              ]),
                            );
                          }).toList();
                        })(),
                        const SizedBox(height: 20),
                      ]),
                    ),
                  ),

                  // Final approve / reject bar
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12)],
                    ),
                    child: _finalizing
                        ? const Center(child: SizedBox(width: 28, height: 28,
                            child: CircularProgressIndicator(color: _green, strokeWidth: 2.5)))
                        : Row(children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _finalizeApproval('reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.danger,
                                  side: BorderSide(color: AppTheme.danger.withValues(alpha: 0.6)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('Reject Driver', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _finalizeApproval('approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _green, foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('Approve Driver', style: TextStyle(fontWeight: FontWeight.w700)),
                              ),
                            ),
                          ]),
                  ),
                ]),
    );
  }
}

// ── Info section ──────────────────────────────────────────────────────────────

class _InfoSection extends StatelessWidget {
  final Map<String, dynamic> data;
  const _InfoSection({required this.data});

  @override
  Widget build(BuildContext context) {
    final rows = <(IconData, String, String?)>[
      (Icons.email_outlined,        'Email',       data['email']       as String?),
      (Icons.phone_outlined,         'Phone',       data['phone']       as String?),
      (Icons.badge_outlined,         'Driver Type', data['driver_type'] as String?),
      (Icons.location_city_outlined, 'City',        data['city']        as String?),
    ].where((r) => r.$3 != null && r.$3!.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: Column(children: rows.map((r) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Icon(r.$1, color: AppTheme.textSecondary, size: 16),
          const SizedBox(width: 10),
          Text('${r.$2}: ', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
          Expanded(child: Text(r.$3!,
              style: const TextStyle(color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600, fontSize: 13))),
        ]),
      )).toList()),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge(this.status);

  @override
  Widget build(BuildContext context) {
    final (color, label) = status == 'approved'
        ? (_green,         'Approved')
        : status == 'rejected'
        ? (AppTheme.danger, 'Rejected')
        : (AppTheme.warning, 'Pending');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}
