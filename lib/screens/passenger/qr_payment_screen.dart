import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';

class QrPaymentScreen extends StatefulWidget {
  const QrPaymentScreen({super.key});

  @override
  State<QrPaymentScreen> createState() => _QrPaymentScreenState();
}

class _QrPaymentScreenState extends State<QrPaymentScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primary,
      appBar: AppBar(
        title: const Text('QR Payment'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: AppTheme.accent,
          labelColor: AppTheme.accent,
          unselectedLabelColor: AppTheme.textSecondary,
          tabs: const [
            Tab(icon: Icon(Icons.qr_code), text: 'My QR'),
            Tab(icon: Icon(Icons.history_rounded), text: 'History'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          _MyQrTab(),
          _HistoryTab(),
        ],
      ),
    );
  }
}

// ── My QR Code tab ────────────────────────────────────────────────────────────

class _MyQrTab extends StatefulWidget {
  const _MyQrTab();

  @override
  State<_MyQrTab> createState() => _MyQrTabState();
}

class _MyQrTabState extends State<_MyQrTab> {
  final _amtCtrl = TextEditingController();
  Map<String, dynamic>? _qrData;
  bool _generating = false;
  bool _polling    = false;
  String? _error;
  String? _status;
  Timer? _pollTimer;

  @override
  void dispose() {
    _amtCtrl.dispose();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _generate() async {
    final raw = _amtCtrl.text.trim();
    final amount = int.tryParse(raw);
    if (amount == null || amount <= 0) {
      setState(() => _error = 'Enter a valid amount in KHR.');
      return;
    }
    setState(() { _generating = true; _error = null; _qrData = null; _status = null; });
    _pollTimer?.cancel();
    try {
      final data = await ApiService.generateQrPayment(amountKhr: amount);
      if (!mounted) return;
      setState(() { _qrData = data; _generating = false; _status = data['status'] as String? ?? 'pending'; });
      _startPolling(data['reference'] as String? ?? '');
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _generating = false; });
    }
  }

  void _startPolling(String reference) {
    if (reference.isEmpty) return;
    _pollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted) return;
      try {
        final s = await ApiService.getQrPaymentStatus(reference);
        if (!mounted) return;
        final newStatus = s['status'] as String? ?? 'pending';
        setState(() { _status = newStatus; _polling = false; });
        if (newStatus == 'paid' || newStatus == 'expired' || newStatus == 'cancelled') {
          _pollTimer?.cancel();
        }
      } catch (_) {}
    });
  }

  void _reset() {
    _pollTimer?.cancel();
    setState(() { _qrData = null; _status = null; _error = null; _amtCtrl.clear(); });
  }

  String get _qrString {
    if (_qrData == null) return '';
    return _qrData!['qr_data']   as String? ??
           _qrData!['qr_string'] as String? ??
           _qrData!['reference'] as String? ??
           '';
  }

  Color get _statusColor {
    switch (_status) {
      case 'paid':      return AppTheme.success;
      case 'expired':
      case 'cancelled': return AppTheme.danger;
      default:          return AppTheme.warning;
    }
  }

  IconData get _statusIcon {
    switch (_status) {
      case 'paid':      return Icons.check_circle_rounded;
      case 'expired':   return Icons.timer_off_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      default:          return Icons.hourglass_empty_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: _qrData == null ? _buildForm() : _buildQr(),
    );
  }

  Widget _buildForm() {
    return Column(children: [
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Generate QR to Receive',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text('Enter an amount and share the QR with the payer.',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.5)),
          const SizedBox(height: 20),
          const Text('Amount (KHR)', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _amtCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: const TextStyle(color: AppTheme.textSecondary),
              suffixText: '៛',
              suffixStyle: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700),
              filled: true,
              fillColor: AppTheme.cardBg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.accent, width: 1.5),
              ),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTheme.danger, fontSize: 13)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _generating ? null : _generate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                disabledBackgroundColor: AppTheme.accent.withValues(alpha: 0.4),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: _generating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.qr_code_rounded, color: Colors.white),
              label: Text(_generating ? 'Generating…' : 'Generate QR',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildQr() {
    final amtKhr = _qrData!['amount_khr'] ?? _qrData!['amount'] ?? '';
    final ref    = _qrData!['reference'] as String? ?? '';

    return Column(children: [
      // Status badge
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _statusColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _statusColor.withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          _status == 'pending'
              ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: _statusColor, strokeWidth: 2))
              : Icon(_statusIcon, color: _statusColor, size: 16),
          const SizedBox(width: 8),
          Text(
            _status == 'paid' ? 'Payment received!' :
            _status == 'expired' ? 'QR expired' :
            _status == 'cancelled' ? 'Cancelled' : 'Waiting for payment…',
            style: TextStyle(color: _statusColor, fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ]),
      ),

      const SizedBox(height: 24),

      // QR card
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: AppTheme.accent.withValues(alpha: 0.15), blurRadius: 24, offset: const Offset(0, 8))],
        ),
        child: Column(children: [
          if (_qrString.isNotEmpty)
            QrImageView(
              data: _qrString,
              version: QrVersions.auto,
              size: 220,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF00B14F)),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black87),
            )
          else
            const SizedBox(height: 220, child: Center(child: Icon(Icons.qr_code_2, size: 80, color: Colors.grey))),
          const SizedBox(height: 12),
          Text('$amtKhr ៛',
              style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w900, fontSize: 22)),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 22, height: 22,
              decoration: BoxDecoration(color: AppTheme.accent, borderRadius: BorderRadius.circular(5)),
              child: const Icon(Icons.bolt, color: Colors.white, size: 14),
            ),
            const SizedBox(width: 6),
            const Text('ROTEH Pay', style: TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w800, fontSize: 13)),
          ]),
        ]),
      ),

      const SizedBox(height: 20),

      if (ref.isNotEmpty)
        Text('Ref: $ref', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),

      const SizedBox(height: 16),

      Row(children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _qrString.isEmpty ? null : () {
              Clipboard.setData(ClipboardData(text: _qrString));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('QR reference copied'),
                backgroundColor: AppTheme.success,
                behavior: SnackBarBehavior.floating,
              ));
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accent,
              side: const BorderSide(color: AppTheme.accent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            icon: const Icon(Icons.copy_outlined, size: 18),
            label: const Text('Copy', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _reset,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.surface,
              foregroundColor: AppTheme.textPrimary,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 13),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('New QR', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    ]);
  }
}

// ── History tab ───────────────────────────────────────────────────────────────

class _HistoryTab extends StatefulWidget {
  const _HistoryTab();

  @override
  State<_HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<_HistoryTab> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await ApiService.getQrPaymentHistory();
      if (!mounted) return;
      setState(() { _items = list; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString().replaceFirst('Exception: ', ''); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
    if (_error != null) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline, color: AppTheme.danger, size: 40),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: AppTheme.textSecondary), textAlign: TextAlign.center),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent), child: const Text('Retry')),
      ]));
    }
    if (_items.isEmpty) {
      return const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.receipt_long_outlined, color: AppTheme.textSecondary, size: 48),
        SizedBox(height: 12),
        Text('No QR payment history', style: TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
      ]));
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppTheme.accent,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => _HistoryTile(item: _items[i]),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final Map<String, dynamic> item;
  const _HistoryTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final ref    = item['reference'] as String? ?? '—';
    final amount = item['amount_khr'] ?? item['amount'] ?? 0;
    final status = item['status'] as String? ?? 'pending';
    final date   = item['created_at'] as String? ?? '';
    final short  = date.length >= 10 ? date.substring(0, 10) : date;

    final Color statusColor = status == 'paid'
        ? AppTheme.success
        : status == 'pending' ? AppTheme.warning : AppTheme.danger;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.qr_code_rounded, color: statusColor, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ref, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
            if (short.isNotEmpty)
              Text(short, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('$amount ៛', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(status.toUpperCase(),
                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w700)),
          ),
        ]),
      ]),
    );
  }
}
