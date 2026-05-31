import 'package:flutter/material.dart';
import 'package:autoride_superapp/theme/app_theme.dart';
import 'package:autoride_superapp/services/api_service.dart';

class RateDriverScreen extends StatefulWidget {
  final int? rideId;
  final String driverName;
  final String fare;
  final String paymentMethod;

  const RateDriverScreen({
    super.key,
    this.rideId,
    required this.driverName,
    required this.fare,
    this.paymentMethod = 'cash',
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

  static const _positiveTags = ['Great driving', 'Very friendly', 'Clean car', 'On time', 'Safe ride'];
  static const _negativeTags = ['Late pickup', 'Rude', 'Unsafe driving', 'Dirty car', 'Wrong route'];

  List<String> get _activeTags => _stars >= 4 ? _positiveTags : _negativeTags;

  String _methodLabel(String method) {
    switch (method) {
      case 'aba':    return 'ABA Pay';
      case 'acleda': return 'ACLEDA';
      case 'wing':   return 'Wing Money';
      case 'wallet': return 'AutoRide Pay';
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
        title: const Text('Rate Your Trip'),
        automaticallyImplyLeading: false,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('Skip', style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          const SizedBox(height: 16),

          // Driver avatar
          CircleAvatar(
            radius: 48,
            backgroundColor: AppTheme.accentOrange.withValues(alpha: 0.2),
            child: Text(
              widget.driverName[0],
              style: const TextStyle(color: AppTheme.accentOrange, fontSize: 36, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: 12),
          Text(widget.driverName,
              style: const TextStyle(color: AppTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.w700)),
          Text('${widget.fare}  •  ${_methodLabel(widget.paymentMethod)}',
              style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          const SizedBox(height: 8),
          const Text('How was your trip?',
              style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 24),

          // Star rating
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => GestureDetector(
              onTap: () => setState(() { _stars = i + 1; _tags.clear(); }),
              child: AnimatedScale(
                scale: _stars == i + 1 ? 1.3 : 1.0,
                duration: const Duration(milliseconds: 150),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Icon(
                    i < _stars ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: i < _stars ? AppTheme.gold : AppTheme.textSecondary,
                    size: 44,
                  ),
                ),
              ),
            )),
          ),
          const SizedBox(height: 8),
          Text(
            _stars == 0 ? 'Tap to rate' :
            _stars == 1 ? 'Terrible' :
            _stars == 2 ? 'Bad' :
            _stars == 3 ? 'Okay' :
            _stars == 4 ? 'Good' : 'Excellent!',
            style: TextStyle(
              color: _stars >= 4 ? AppTheme.success : _stars > 0 ? AppTheme.danger : AppTheme.textSecondary,
              fontWeight: FontWeight.w700, fontSize: 15,
            ),
          ),

          if (_stars > 0) ...[
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                _stars >= 4 ? 'What did you love?' : 'What went wrong?',
                style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
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
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: _tags.contains(tag)
                        ? (_stars >= 4 ? AppTheme.accent : AppTheme.danger).withValues(alpha: 0.15)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _tags.contains(tag)
                          ? (_stars >= 4 ? AppTheme.accent : AppTheme.danger)
                          : AppTheme.surface,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: _tags.contains(tag)
                          ? (_stars >= 4 ? AppTheme.accent : AppTheme.danger)
                          : AppTheme.textSecondary,
                      fontWeight: FontWeight.w500, fontSize: 13,
                    ),
                  ),
                ),
              )).toList(),
            ),
            const SizedBox(height: 20),

            // Comment
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surface, borderRadius: BorderRadius.circular(14)),
              child: TextField(
                controller: _commentController,
                maxLines: 3,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: const InputDecoration(
                  hintText: 'Add a comment (optional)...',
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(14),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tip section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Add a tip?',
                  style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 10),
            Row(
              children: ['0 ៛', '2,000 ៛', '5,000 ៛', '10,000 ៛'].map((t) => Expanded(child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.accent),
                    foregroundColor: AppTheme.accent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ))).toList(),
            ),
            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : () async {
                  setState(() => _submitting = true);
                  try {
                    if (widget.rideId != null) {
                      await ApiService.rateRide(
                        widget.rideId!,
                        _stars,
                        comment: _commentController.text.trim().isEmpty
                            ? null
                            : _commentController.text.trim(),
                      );
                    }
                  } catch (_) {}
                  if (mounted) setState(() { _submitting = false; _submitted = true; });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: AppTheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _submitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('Submit Rating', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ),
          ],
        ]),
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
          padding: const EdgeInsets.all(40),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: AppTheme.accent.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: AppTheme.accent, size: 56),
            ),
            const SizedBox(height: 24),
            const Text('Thank you!', style: TextStyle(color: AppTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            const Text('Your feedback helps us improve the experience for everyone.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary, height: 1.5)),
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
