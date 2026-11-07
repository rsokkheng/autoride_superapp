import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'partner_ui.dart';

/// Daily statement after ROTEH closes the books — the same Successful and
/// Unsuccessful reports ROTEH prints for the Partner, to reconcile.
class PartnerStatementScreen extends StatefulWidget {
  const PartnerStatementScreen({super.key});

  @override
  State<PartnerStatementScreen> createState() => _PartnerStatementScreenState();
}

class _PartnerStatementScreenState extends State<PartnerStatementScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  DateTime _date = DateTime.now();
  Map<String, dynamic>? _data;
  bool _loading = true;
  bool _opening = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = _data == null; _error = null; });
    try {
      final d = await ApiService.getPartnerStatement(_date);
      if (mounted) setState(() { _data = d; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = AppLocalizations.of(context).connectionErrorRetry; _loading = false; });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (d != null && mounted) {
      setState(() { _date = d; _data = null; });
      _load();
    }
  }

  void _shift(int days) {
    final next = _date.add(Duration(days: days));
    if (next.isAfter(DateTime.now())) return;
    setState(() { _date = next; _data = null; });
    _load();
  }

  /// Opens the printable statement (or the Excel) in the phone's browser —
  /// Khmer prints correctly there, and "Print → Save as PDF" makes the PDF.
  Future<void> _open({required bool excel}) async {
    if (_opening) return;
    final messenger = ScaffoldMessenger.of(context);
    final l = AppLocalizations.of(context);
    setState(() => _opening = true);
    try {
      final type = _tabs.index == 0 ? 'successful' : 'unsuccessful';
      final links = await ApiService.getPartnerStatementLink(_date, type: excel ? 'both' : type);
      final url = (excel ? links['excel_url'] : links['print_url'])?.toString();
      if (url != null) await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.connectionErrorRetry), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  String _dateLabel() {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(_date.day)}/${two(_date.month)}/${_date.year}';
  }

  bool get _isToday {
    final n = DateTime.now();
    return _date.year == n.year && _date.month == n.month && _date.day == n.day;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final sum = _data?['summary'] as Map?;
    int n(String k) => (sum?[k] as num?)?.toInt() ?? 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(l.pkStatement),
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppTheme.accent,
          indicatorColor: AppTheme.accent,
          unselectedLabelColor: context.appTextSecondary,
          tabs: [
            Tab(text: '${l.pkSuccessful}${sum == null ? '' : ' (${n('successful_count')})'}'),
            Tab(text: '${l.pkUnsuccessful}${sum == null ? '' : ' (${n('unsuccessful_count')})'}'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(children: [
          // Closing date
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
            child: Row(children: [
              IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left_rounded)),
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(children: [
                      Text(l.pkClosingDate, style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
                      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.event_rounded, size: 16, color: AppTheme.accent),
                        const SizedBox(width: 6),
                        Text('${_isToday ? '${l.pkToday} · ' : ''}${_dateLabel()}',
                            style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                      ]),
                    ]),
                  ),
                ),
              ),
              IconButton(onPressed: _isToday ? null : () => _shift(1), icon: const Icon(Icons.chevron_right_rounded)),
            ]),
          ),
          if (sum != null) _summary(l, n),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                : _error != null && _data == null
                    ? Center(child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: context.appTextSecondary)),
                          const SizedBox(height: 10),
                          OutlinedButton(onPressed: _load, child: Text(l.tryAgain)),
                        ]),
                      ))
                    : TabBarView(controller: _tabs, children: [
                        _list(l, (_data!['successful'] as List? ?? const []).whereType<Map>().toList(), true),
                        _list(l, (_data!['unsuccessful'] as List? ?? const []).whereType<Map>().toList(), false),
                      ]),
          ),
        ]),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 6, 16, 10),
        child: Row(children: [
          Expanded(
            child: SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: _data == null || _opening ? null : () => _open(excel: false),
                style: AppTheme.confirmButtonStyle(),
                icon: _opening
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.print_rounded, size: 18),
                label: Text(l.pkPrintPdf),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _data == null || _opening ? null : () => _open(excel: true),
              icon: const Icon(Icons.grid_on_rounded, size: 18, color: Color(0xFF1D6F42)),
              label: Text(l.pkExportExcel, style: const TextStyle(color: Color(0xFF1D6F42))),
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _summary(AppLocalizations l, int Function(String) n) {
    final net = n('net_to_partner');
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (net < 0 ? AppTheme.danger : AppTheme.accent).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: [
        Row(children: [
          Expanded(child: _kv(l.pkCodCollected, AppTheme.khr(n('cod_collected')))),
          Expanded(child: _kv(l.pkRotehFee, AppTheme.khr(n('service_fees')))),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _kv(l.pkNetToPartner, AppTheme.khr(n('roteh_pays_partner')), color: AppTheme.accent)),
          Expanded(child: _kv(l.pkPartnerOwes, AppTheme.khr(n('partner_pays_roteh')),
              color: n('partner_pays_roteh') > 0 ? AppTheme.danger : null)),
        ]),
        const Divider(height: 18),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${l.pkBalance} · ${net < 0 ? l.pkPartnerOwes : l.pkNetToPartner}',
                  style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
              Text(AppTheme.khr(net.abs()),
                  style: TextStyle(color: net < 0 ? AppTheme.danger : AppTheme.accent, fontSize: 22, fontWeight: FontWeight.w800)),
            ]),
          ),
          Flexible(
            child: Text(l.pkBalanceHint, textAlign: TextAlign.right,
                style: TextStyle(color: context.appTextSecondary, fontSize: 10, height: 1.3)),
          ),
        ]),
      ]),
    );
  }

  Widget _kv(String k, String v, {Color? color}) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(k, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: context.appTextSecondary, fontSize: 11.5)),
        Text(v, style: TextStyle(color: color ?? context.appTextPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
      ]);

  Widget _list(AppLocalizations l, List<Map> rows, bool ok) {
    if (rows.isEmpty) {
      return RefreshIndicator(
        color: AppTheme.accent,
        onRefresh: _load,
        child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
          const SizedBox(height: 80),
          Icon(ok ? Icons.inventory_2_outlined : Icons.assignment_return_outlined,
              size: 52, color: context.appTextSecondary.withValues(alpha: 0.5)),
          const SizedBox(height: 10),
          Text(ok ? l.pkStatementEmptyOk : l.pkStatementEmptyBad,
              textAlign: TextAlign.center, style: TextStyle(color: context.appTextSecondary)),
        ]),
      );
    }
    return RefreshIndicator(
      color: AppTheme.accent,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) => ok ? _okTile(l, rows[i]) : _badTile(l, rows[i]),
      ),
    );
  }

  int _i(Map r, String k) => (r[k] as num?)?.toInt() ?? 0;
  String _time(Map r, String k) => (r[k]?.toString() ?? '').split(' ').last;

  Widget _tile({required Widget top, required Widget middle, required List<Widget> money}) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          top,
          const SizedBox(height: 6),
          middle,
          const Divider(height: 18),
          Row(children: money),
        ]),
      );

  Widget _money(String label, int v, {Color? color, bool bold = false}) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: context.appTextSecondary, fontSize: 10.5)),
          Text(AppTheme.khr(v), style: TextStyle(
              color: color ?? context.appTextPrimary, fontSize: 13, fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ]),
      );

  Widget _okTile(AppLocalizations l, Map r) {
    final paidBy = switch (r['fee_paid_by']) {
      'partner_prepaid' => l.pkFeePrepaid,
      'partner_pays'    => l.pkPartnerOwes,
      _                 => l.pkFeeFromCod,
    };
    return _tile(
      top: Row(children: [
        Text(r['code']?.toString() ?? '', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        if ((r['reference'] ?? '').toString().isNotEmpty)
          Text('  #${r['reference']}', style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
        const Spacer(),
        const Icon(Icons.check_circle_rounded, size: 16, color: AppTheme.success),
        const SizedBox(width: 4),
        Text(_time(r, 'completed_at'), style: TextStyle(color: context.appTextSecondary, fontSize: 12)),
      ]),
      middle: Text('${r['receiver_name'] ?? ''} · ${r['receiver_phone'] ?? ''}',
          style: TextStyle(color: context.appTextPrimary, fontSize: 13)),
      money: [
        _i(r, 'cod_collected') > 0
            ? _money('COD', _i(r, 'cod_collected'))
            : Expanded(child: Text(l.pkNoCod, style: TextStyle(color: context.appTextSecondary, fontSize: 12))),
        _money('${l.pkRotehFee} · $paidBy', _i(r, 'fee')),
        _i(r, 'partner_pays_roteh') > 0
            ? _money(l.pkPartnerOwes, _i(r, 'partner_pays_roteh'), color: AppTheme.danger, bold: true)
            : _money(l.pkNetToPartner, _i(r, 'roteh_pays_partner'), color: AppTheme.accent, bold: true),
      ],
    );
  }

  Widget _badTile(AppLocalizations l, Map r) {
    final status = r['status']?.toString() ?? 'failed';
    final reason = r['reason']?.toString();
    final label = switch (status) {
      'returned'  => l.pkStatusReturned,
      'cancelled' => l.pkStatusCancelled,
      _           => l.pkReturning,
    };
    final note = r['note']?.toString();
    return _tile(
      top: Row(children: [
        Text(r['code']?.toString() ?? '', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        const Spacer(),
        Flexible(flex: 3, child: PackageStatusChip(status == 'cancelled' ? 'cancelled' : (status == 'returned' ? 'returned' : 'failed'))),
      ]),
      middle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('${r['receiver_name'] ?? ''} · ${r['receiver_phone'] ?? ''}',
            style: TextStyle(color: context.appTextPrimary, fontSize: 13)),
        if (reason != null)
          Text('$label · ${PackageUi.reason_(l, reason)}', style: const TextStyle(color: AppTheme.danger, fontSize: 12)),
        if (note != null && note.isNotEmpty)
          Text('“$note”', style: TextStyle(color: context.appTextSecondary, fontSize: 11.5, fontStyle: FontStyle.italic)),
      ]),
      money: [
        _money(l.pkCodNotCollected, _i(r, 'cod_amount')),
        _money(l.pkServiceFee, _i(r, 'fee')),
        _money(l.pkPartnerOwes, _i(r, 'fee_charged'), color: _i(r, 'fee_charged') > 0 ? AppTheme.danger : null, bold: true),
      ],
    );
  }
}
