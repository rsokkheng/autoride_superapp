import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class VehicleTypeSelector extends StatelessWidget {
  final String selected;
  final void Function(String type) onChanged;
  final Map<String, int>? estimatedFaresKhr;

  const VehicleTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.estimatedFaresKhr,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? AppTheme.darkSurface : context.appSurface;
    final border = isDark ? AppTheme.darkCardBg  : context.appCardBg;

    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: AppTheme.vehicleTypes.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final v      = AppTheme.vehicleTypes[i];
          final active = selected == v.type;
          final fare   = estimatedFaresKhr?[v.type];

          return GestureDetector(
            onTap: () => onChanged(v.type),
            child: AnimatedContainer(
              duration: Duration(milliseconds: 180),
              width: 80,
              padding: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: active ? AppTheme.accent : bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: active ? AppTheme.accent : border,
                  width: active ? 2 : 1,
                ),
                boxShadow: active
                    ? [BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.25),
                        blurRadius: 8, offset: Offset(0, 3))]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(v.icon,
                      color: active ? Colors.white : context.appTextSecondary,
                      size: 26),
                  SizedBox(height: 4),
                  Text(v.label,
                      style: TextStyle(
                        color: active ? Colors.white : context.appTextPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      )),
                  if (fare != null) ...[
                    const SizedBox(height: 2),
                    Text(AppTheme.khr(fare),
                        style: TextStyle(
                          color: active
                              ? Colors.white.withValues(alpha: 0.85)
                              : AppTheme.accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                        )),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
