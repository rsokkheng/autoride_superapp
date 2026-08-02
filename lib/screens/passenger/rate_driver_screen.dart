import 'package:flutter/material.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:autoride_superapp/services/api_service.dart';
import 'trip_receipt_screen.dart';

class RateDriverScreen extends StatefulWidget {
  final int?    rideId;
  final String  driverName;
  final String  fare;
  final String  paymentMethod;
  final double? distanceKm;
  final int?    durationMin;
  final String  from;
  final String  to;
  final int?    baseFareKhr;
  final int?    distanceFeeKhr;
  /// Intermediate stop addresses, in order — carried through to the receipt.
  final List<String> stops;

  const RateDriverScreen({
    super.key,
    this.rideId,
    required this.driverName,
    required this.fare,
    this.paymentMethod = 'cash',
    this.distanceKm,
    this.durationMin,
    this.from = '',
    this.to   = '',
    this.baseFareKhr,
    this.distanceFeeKhr,
    this.stops = const [],
  });

  @override
  State<RateDriverScreen> createState() => _RateDriverScreenState();
}

class _RateDriverScreenState extends State<RateDriverScreen> {
  int _stars = 0;
  final Set<String> _tags = {};
  final _commentController = TextEditingController();
  bool _submitted = false;
  bool _submitting = false;
  int? _selectedTip;   // KHR amount, null = no tip, 0 = explicitly "0 ৳"
  bool _tipping = false;

  static const _tipOptions = [0, 2000, 5000, 10000];

  static const _positiveTags = ['Great driving', 'Very friendly', 'Clean car', 'On time', 'Safe ride'];
  static const _negativeTags = ['Late pickup', 'Rude', 'Unsafe driving', 'Dirty car', 'Wrong route'];

  List<String> get _activeTags => _stars >= 4 ? _positiveTags : _negativeTags;

  String _methodLabel(String method) {
    switch (method) {
      case 'aba':    return 'ABA Pay';
      case 'acleda': return 'ACLEDA';
      case 'wing':   return 'Wing Money';
      case 'wallet': return 'ROTEH Pay';
      default:       return 'Cash';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_submitted) return _ThankYouScreen(
    onDone: () => Navigator.of(context).popUntil((route) => route.isFirst),
  );

    return Scaffold(
      appBar: AppBar(
        title: Text('Rate Your Trip'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: Text('Skip', style: TextStyle(color: context.appTextSecondary)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(children: [
                SizedBox(height: 8),

                // Driver avatar
                CircleAvatar(
                  radius: 48,
                  backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.2),
                  child: Text(
                    widget.driverName[0],
                    style: TextStyle(color: AppTheme.accentOrange, fontSize: 36, fontWeight: FontWeight.w800),
                  ),
                ),
                SizedBox(height: 12),
                Text(widget.driverName,
                    style: TextStyle(color: context.appTextPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
                Text('${widget.fare}  •  ${_methodLabel(widget.paymentMethod)}',
                    style: TextStyle(color: context.appTextSecondary, fontSize: 14)),
                SizedBox(height: 12),

                // Distance & Duration stats
                if (widget.distanceKm != null || widget.durationMin != null)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 8),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (widget.distanceKm != null) ...[
                          Column(children: [
                            const Icon(Icons.route_outlined, color: AppTheme.accent, size: 20),
                            const SizedBox(height: 4),
                            Text('${widget.distanceKm!.toStringAsFixed(1)} km',
                                style: TextStyle(color: context.appTextPrimary,
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                            Text('Distance',
                                style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
                          ]),
                        ],
                        if (widget.distanceKm != null && widget.durationMin != null)
                          Container(width: 1, height: 36, color: context.appCardBg),
                        if (widget.durationMin != null) ...[
                          Column(children: [
                            const Icon(Icons.timer_outlined, color: AppTheme.accent, size: 20),
                            const SizedBox(height: 4),
                            Text('${widget.durationMin} min',
                                style: TextStyle(color: context.appTextPrimary,
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                            Text('Duration',
                                style: TextStyle(color: context.appTextSecondary, fontSize: 11)),
                          ]),
                        ],
                      ],
                    ),
                  ),
                SizedBox(height: 12),
                Text('How was your trip?',
                    style: TextStyle(color: context.appTextPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 24),

                // Star rating
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => GestureDetector(
                    onTap: () => setState(() { _stars = i + 1; _tags.clear(); }),
                    child: AnimatedScale(
                      scale: _stars == i + 1 ? 1.3 : 1.0,
                      duration: Duration(milliseconds: 150),
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          i < _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: i < _stars ? AppTheme.gold : context.appTextSecondary,
                          size: 44,
                        ),
                      ),
                    ),
                  )),
                ),
                SizedBox(height: 8),
                Text(
                  _stars == 0 ? 'Tap to rate' :
                  _stars == 1 ? 'Terrible' :
                  _stars == 2 ? 'Bad' :
                  _stars == 3 ? 'Okay' :
                  _stars == 4 ? 'Good' : 'Excellent!',
                  style: TextStyle(
                    color: _stars >= 4 ? AppTheme.success : _stars > 0 ? AppTheme.danger : context.appTextSecondary,
                    fontWeight: FontWeight.w700, fontSize: 15,
                  ),
                ),

                if (_stars > 0) ...[
                  SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _stars >= 4 ? 'What did you love?' : 'What went wrong?',
                      style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _activeTags.map((tag) => GestureDetector(
                      onTap: () => setState(() {
                        _tags.contains(tag) ? _tags.remove(tag) : _tags.add(tag);
                      }),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 150),
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: _tags.contains(tag)
                              ? (_stars >= 4 ? AppTheme.accent : AppTheme.danger).withValues(alpha: 0.15)
                              : context.appSurface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _tags.contains(tag)
                                ? (_stars >= 4 ? AppTheme.accent : AppTheme.danger)
                                : context.appSurface,
                          ),
                        ),
                        child: Text(
                          tag,
                          style: TextStyle(
                            color: _tags.contains(tag)
                                ? (_stars >= 4 ? AppTheme.accent : AppTheme.danger)
                                : context.appTextSecondary,
                            fontWeight: FontWeight.w500, fontSize: 13,
                          ),
                        ),
                      ),
                    )).toList(),
                  ),
                  SizedBox(height: 20),

                  // Comment
                  Container(
                    decoration: BoxDecoration(
                        color: context.appSurface, borderRadius: BorderRadius.circular(14)),
                    child: TextField(
                      controller: _commentController,
                      maxLines: 3,
                      style: TextStyle(color: context.appTextPrimary),
                      decoration: InputDecoration(
                        hintText: 'Add a comment (optional)...',
                        hintStyle: TextStyle(color: context.appTextSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(14),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),

                  // Tip section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Add a tip?',
                        style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: _tipOptions.asMap().entries.map((entry) {
                      final amount   = entry.value;
                      final label    = amount == 0 ? 'No tip' : '${amount ~/ 1000}k ៛';
                      final selected = _selectedTip == amount;
                      return Expanded(child: Padding(
                        padding: EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTip = selected ? null : amount),
                          child: AnimatedContainer(
                            duration: Duration(milliseconds: 150),
                            padding: EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.accent : context.appSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: selected ? AppTheme.accent : context.appCardBg),
                            ),
                            child: Text(label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: selected ? AppTheme.primary : context.appTextSecondary,
                                fontWeight: FontWeight.w700, fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ));
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                ],
              ]),
            ),
          ),

          // ── Sticky submit button ─────────────────────────────────────────
          if (_stars > 0)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_submitting || _tipping) ? null : () async {
                      setState(() => _submitting = true);
                      try {
                        if (widget.rideId != null) {
                          await ApiService.rateRide(
                            widget.rideId!,
                            _stars.toDouble(),
                            comment: _commentController.text.trim().isEmpty
                                ? null
                                : _commentController.text.trim(),
                          );
                          if (_selectedTip != null && _selectedTip! > 0) {
                            setState(() => _tipping = true);
                            try {
                              await ApiService.tipDriver(widget.rideId!, amountKhr: _selectedTip!);
                            } on ApiException catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                  content: Text('Tip failed: ${e.message}'),
                                  backgroundColor: Colors.orange,
                                  behavior: SnackBarBehavior.floating,
                                ));
                              }
                            } catch (_) {}
                            if (mounted) setState(() => _tipping = false);
                          }
                        }
                      } catch (_) {}
                      if (!mounted) return;
                      setState(() => _submitting = false);
                      await Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TripReceiptScreen(
                            rideId:           widget.rideId,
                            from:             widget.from.isNotEmpty ? widget.from : '--',
                            to:               widget.to.isNotEmpty   ? widget.to   : '--',
                            stops:            widget.stops,
                            driverName:       widget.driverName,
                            starsGiven:       _stars.clamp(1, 5),
                            fareTotal:        widget.fare,
                            baseFareKhr:      widget.baseFareKhr ?? 0,
                            distanceFeeKhr:   widget.distanceFeeKhr ?? 0,
                            surgeKhr:         0,
                            promoDiscountKhr: 0,
                            distanceKm:       widget.distanceKm,
                            durationMin:      widget.durationMin,
                            paymentMethod:    widget.paymentMethod,
                            tripDate:         DateTime.now(),
                          ),
                        ),
                      );
                      if (mounted) setState(() => _submitted = true);
                    },
                    style: AppTheme.confirmButtonStyle(background: AppTheme.accent),
                    child: (_submitting || _tipping)
                        ? const SizedBox(width: 22, height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Text('Submit Rating'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ThankYouScreen extends StatelessWidget {
  final VoidCallback onDone;
  const _ThankYouScreen({required this.onDone});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(Icons.check_rounded, color: AppTheme.accent, size: 56),
            ),
            SizedBox(height: 24),
            Text('Thank you!', style: TextStyle(color: context.appTextPrimary, fontSize: 28, fontWeight: FontWeight.w800)),
            SizedBox(height: 8),
            Text('Your feedback helps us improve the experience for everyone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: context.appTextSecondary, height: 1.5)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: AppTheme.primary,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Back to Home', style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ]),
        ),
      ),
    );
  }
}
