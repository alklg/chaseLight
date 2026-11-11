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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 12 : 14,
          vertical: dense ? 6 : 7,
        ),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : null,
          gradient: active ? null : kCardGradient,
          borderRadius: BorderRadius.circular(20),
          border: active ? null : kSoftBorder,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: dense ? 14 : 15,
              color: active ? Colors.white : AppColors.textTertiary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: dense ? 12.5 : 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
