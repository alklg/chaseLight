import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 「追剧 / 看书」这类内容类型的胶囊切换按钮。
class KindPill extends StatelessWidget {
  const KindPill({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
    this.dense = false,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    // 两端都用渐变：BoxDecoration 只在同类之间插值，color ↔ gradient 会瞬间跳变
    final gradient = active
        ? LinearGradient(
            colors: [AppColors.primary, AppColors.primary],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : kCardGradient;
    final fg = active ? Colors.white : AppColors.textSecondary;
    final iconColor = active ? Colors.white : AppColors.textTertiary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 12 : 14,
          vertical: dense ? 6 : 7,
        ),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          border: active ? null : kSoftBorder,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: iconColor),
              duration: const Duration(milliseconds: 240),
              builder: (_, c, __) =>
                  Icon(icon, size: dense ? 14 : 15, color: c),
            ),
            const SizedBox(width: 6),
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: fg),
              duration: const Duration(milliseconds: 240),
              builder: (_, c, __) => Text(
                label,
                style: TextStyle(
                  fontSize: dense ? 12.5 : 13,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: c,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
