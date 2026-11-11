import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 页面底色。
///
/// 不是纯色，而是几团极淡的光晕叠出来的。玻璃卡片必须有东西可以「透」，
/// 纯色背景上做玻璃等于什么都没发生。
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    final accent = AppColors.primary;
    final topLeft = dark ? 0.10 : 0.16;
    final bottomRight = dark ? 0.07 : 0.11;

    return Stack(
      children: [
        Positioned.fill(child: ColoredBox(color: AppColors.bg)),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(-0.9, -1.05),
                  radius: 1.15,
                  colors: [
                    accent.withValues(alpha: topLeft),
                    accent.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1.05, 0.95),
                  radius: 1.0,
                  colors: [
                    Color.lerp(accent, const Color(0xFF7BD3FF), 0.6)!
                        .withValues(alpha: bottomRight),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(child: child),
      ],
    );
  }
}
