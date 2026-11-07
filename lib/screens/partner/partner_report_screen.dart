import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/app_localizations.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'partner_ui.dart';

/// Partner report — packages by day / week / month, with outcomes,
/// money and why packages were not delivered.
class PartnerReportScreen extends StatefulWidget {
  final String initialPeriod;
  const PartnerReportScreen({super.key, this.initialPeriod = 'day'});

  @override
  State<PartnerReportScreen> createState() => _PartnerReportScreenState();
}

class _PartnerReportScreenState extends State<PartnerReportScreen> {
  late String _period = widget.initialPeriod;
  DateTime _date = DateTime.now();
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  String? _exporting; // pdf | xlsx while downloading

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = _data == null; _error = null; });
    try {
      final d = await ApiService.getPartnerReport(period: _period, date: _date);
      if (mounted) setState(() { _data = d; _loading = false; });
    } on ApiException catch (e) {
      if (mounted) setState(() { _error = e.message; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = AppLocalizations.of(context).connectionErrorRetry; _loading = false; });
    }
  }

  void _shift(int dir) {
    setState(() {
      _date = switch (_period) {
        'week'  => _date.add(Duration(days: 7 * dir)),
        'month' => DateTime(_date.year, _date.month + dir, 1),
        _       => _date.add(Duration(days: dir)),
      };
    });
    _load();
  }

  Future<void> _export(String format) async {
    if (_exporting != null) return;
    final l = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final box = context.findRenderObject() as RenderBox?;
    setState(() => _exporting = format);
    try {
      final file = await ApiService.downloadPartnerReport(period: _period, date: _date, format: format);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: format == 'pdf'
            ? 'application/pdf'
            : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        subject: '${l.pkReports} · ${_rangeLabel(l)}',
        // iPad needs an anchor for the share popover.
        sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      );
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l.connectionErrorRetry), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _exporting = null);
    }
  }

  Future<void> _chooseExport() async {
    final l = AppLocalizations.of(context);
    final format = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: context.appSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(22))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${l.pkExportReport} · ${_rangeLabel(l)}',
                style: TextStyle(color: ctx.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 15)),
            const SizedBox(height: 8),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0x1AE53935), child: Icon(Icons.picture_as_pdf_rounded, color: Color(0xFFE53935))),
              title: Text(l.pkExportPdf),
              subtitle: Text(l.pkExportPdfSub, style: const TextStyle(fontSize: 12)),
              onTap: () => Navigator.pop(ctx, 'pdf'),
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0x1A1D6F42), child: Icon(Icons.grid_on_rounded, color: Color(0xFF1D6F42))),
              title: Text(l.pkExportExcel),
              subtitle: Text(l.pkExportExcelSub, style: const TextStyle(fontSize: 12)),
              onTap: () => Navigator.pop(ctx, 'xlsx'),
            ),
          ]),
        ),
      ),
    );
    if (format != null) _export(format);
  }

  bool get _isCurrent {
    final now = DateTime.now();
    final to = DateTime.tryParse(_data?['to']?.toString() ?? '');
    return to != null && !to.isBefore(DateTime(now.year, now.month, now.day));
  }

  String _rangeLabel(AppLocalizations l) {
    final from = DateTime.tryParse(_data?['from']?.toString() ?? '');
    final to = DateTime.tryParse(_data?['to']?.toString() ?? '');
    if (from == null || to == null) return '';
    String two(int v) => v.toString().padLeft(2, '0');
    String dmy(DateTime d) => '${two(d.day)}/${two(d.month)}/${d.year}';
    if (_isCurrent) {
      final cur = switch (_period) { 'week' => l.pkThisWeek, 'month' => l.pkThisMonth, _ => l.pkToday };
      return _period == 'day' ? '$cur · ${dmy(from)}' : '$cur · ${dmy(from)} – ${dmy(to)}';
    }
    return _period == 'day' ? dmy(from) : '${dmy(from)} – ${dmy(to)}';
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l.pkReports),
        actions: [
          _exporting != null
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                )
              : IconButton(
                  tooltip: l.pkExportReport,
                  onPressed: _data == null ? null : _chooseExport,
                  icon: const Icon(Icons.file_download_outlined),
                ),
        ],
      ),
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'day', label: Text(l.pkDay)),
                ButtonSegment(value: 'week', label: Text(l.pkWeek)),
                ButtonSegment(value: 'month', label: Text(l.pkMonth)),
              ],
              selected: {_period},
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                selectedBackgroundColor: AppTheme.accent,
                selectedForegroundColor: Colors.white,
              ),
              onSelectionChanged: (v) {
                setState(() { _period = v.first; _date = DateTime.now(); });
                _load();
              },
            ),
          ),
          Row(children: [
            IconButton(onPressed: () => _shift(-1), icon: const Icon(Icons.chevron_left_rounded)),
            Expanded(
              child: Text(_rangeLabel(l), textAlign: TextAlign.center,
                  style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600, fontSize: 13.5)),
            ),
            IconButton(
              onPressed: _isCurrent ? null : () => _shift(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ]),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
                : RefreshIndicator(
                    color: AppTheme.accent,
                    onRefresh: _load,
                    child: _error != null && _data == null
                        ? ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                            const SizedBox(height: 120),
                            Text(_error!, textAlign: TextAlign.center, style: TextStyle(color: context.appTextSecondary)),
                          ])
                        : _body(l, _data!),
                  ),
          ),
        ]),
      ),
    );
  }

  Widget _body(AppLocalizations l, Map<String, dynamic> d) {
    int n(Map? m, String k) => (m?[k] as num?)?.toInt() ?? 0;
    final t = d['totals'] as Map?;
    final m = d['money'] as Map?;
    final total = n(t, 'total');
    final rate = (d['success_rate'] as num?)?.toDouble();
    final avg = (d['avg_delivery_minutes'] as num?)?.toInt();
    final reasons = (d['failure_reasons'] as Map?) ?? const {};
    final series = (d['series'] as List? ?? const []).whereType<Map>().toList();
    final notDelivered = n(t, 'failed') + n(t, 'returned');

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        // Headline
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.accent, AppTheme.accent.withValues(alpha: 0.75)]),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(l.pkTotalPackages, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
                Text('$total', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
              ]),
            ),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(l.pkSuccessRate, style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
              Text(rate == null ? '—' : '${rate.toStringAsFixed(rate % 1 == 0 ? 0 : 1)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
            ]),
          ]),
        ),
        const SizedBox(height: 12),

        // Outcomes
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 2.3,
          children: [
            _stat(l.pkStatusCompleted, n(t, 'completed'), 'completed'),
            _stat(l.pkStatusReturned, notDelivered, 'returned'),
            _stat(l.pkInProgress, n(t, 'in_progress'), 'in_transit'),
            _stat(l.pkStatusCancelled, n(t, 'cancelled'), 'cancelled'),
          ],
        ),
        const SizedBox(height: 12),

        // Money
        _card(Column(children: [
          _money(l.pkDeliveryFees, n(m, 'delivery_fees'), Icons.local_shipping_outlined),
          _money(l.pkCodCollected, n(m, 'cod_collected'), Icons.payments_outlined),
          if (n(m, 'cod_pending') > 0) _money(l.pkCodPending, n(m, 'cod_pending'), Icons.hourglass_bottom_rounded),
          Row(children: [
            Icon(Icons.timer_outlined, size: 18, color: context.appTextSecondary),
            const SizedBox(width: 10),
            Expanded(child: Text(l.pkAvgTime, style: TextStyle(color: context.appTextPrimary, fontSize: 13.5))),
            Text(avg == null ? '—' : l.pkMinutes(avg),
                style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
          ]),
        ])),
        const SizedBox(height: 12),

        // Chart
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_period == 'day' ? l.pkByHour : l.pkByDay,
              style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 4),
          Row(children: [
            _legend(PackageUi.color('completed'), l.pkStatusCompleted),
            const SizedBox(width: 12),
            _legend(PackageUi.color('returned'), l.pkStatusReturned),
            const SizedBox(width: 12),
            _legend(AppTheme.confirmBlue.withValues(alpha: 0.35), l.pkInProgress),
          ]),
          const SizedBox(height: 12),
          total == 0
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text(l.pkNoData, style: TextStyle(color: context.appTextSecondary))),
                )
              : _Bars(series: series, period: _period),
        ])),

        // Why not delivered
        if (notDelivered > 0) ...[
          const SizedBox(height: 12),
          _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l.pkFailureReasons,
                style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 10),
            for (final e in reasons.entries.where((e) => (e.value as num? ?? 0) > 0))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(PackageUi.reason_(l, e.key.toString()),
                        style: TextStyle(color: context.appTextPrimary, fontSize: 13))),
                    Text('${e.value}', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (e.value as num).toDouble() / notDelivered,
                      minHeight: 6,
                      color: AppTheme.danger,
                      backgroundColor: context.appCardBg,
                    ),
                  ),
                ]),
              ),
          ])),
        ],
      ],
    );
  }

  Widget _card(Widget child) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(16)),
        child: child,
      );

  Widget _stat(String label, int value, String status) {
    final c = PackageUi.color(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(14)),
      child: Row(children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(color: c.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(PackageUi.icon(status), color: c, size: 19),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('$value', style: TextStyle(color: context.appTextPrimary, fontSize: 18, fontWeight: FontWeight.w800)),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: context.appTextSecondary, fontSize: 11.5)),
          ]),
        ),
      ]),
    );
  }

  Widget _money(String label, int amount, IconData icon) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Icon(icon, size: 18, color: context.appTextSecondary),
          const SizedBox(width: 10),
          Expanded(child: Text(label, style: TextStyle(color: context.appTextPrimary, fontSize: 13.5))),
          Text(AppTheme.khr(amount), style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w700)),
        ]),
      );

  Widget _legend(Color c, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
      ]);
}

/// Stacked bars: completed / not delivered / still open, per hour or day.
class _Bars extends StatelessWidget {
  final List<Map> series;
  final String period;
  const _Bars({required this.series, required this.period});

  @override
  Widget build(BuildContext context) {
    int n(Map m, String k) => (m[k] as num?)?.toInt() ?? 0;
    final maxV = series.fold<int>(1, (a, m) => n(m, 'total') > a ? n(m, 'total') : a);
    const h = 140.0;

    String label(Map m, int i) {
      final k = m['key'].toString();
      if (period == 'day') return i % 3 == 0 ? k : '';
      final d = DateTime.tryParse(k);
      if (d == null) return '';
      if (period == 'week') return '${d.day}/${d.month}';
      return (d.day == 1 || d.day % 5 == 0) ? '${d.day}' : '';
    }

    return SizedBox(
      height: h + 22,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        for (var i = 0; i < series.length; i++)
          Expanded(
            child: Tooltip(
              message: '${series[i]['key']}: ${n(series[i], 'total')}',
              child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: series.length > 20 ? 1 : 3),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      _seg(h * (n(series[i], 'total') - n(series[i], 'completed') - n(series[i], 'not_delivered') - n(series[i], 'cancelled')).clamp(0, 1 << 30) / maxV,
                          AppTheme.confirmBlue.withValues(alpha: 0.35)),
                      _seg(h * n(series[i], 'not_delivered') / maxV, PackageUi.color('returned')),
                      _seg(h * n(series[i], 'completed') / maxV, PackageUi.color('completed')),
                      _seg(h * n(series[i], 'cancelled') / maxV, context.appTextSecondary.withValues(alpha: 0.4)),
                    ]),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 14,
                  child: Text(label(series[i], i), maxLines: 1, overflow: TextOverflow.visible, softWrap: false,
                      style: TextStyle(color: context.appTextSecondary, fontSize: 9)),
                ),
              ]),
            ),
          ),
      ]),
    );
  }

  Widget _seg(double height, Color c) => height <= 0 ? const SizedBox.shrink() : Container(height: height, color: c);
}
