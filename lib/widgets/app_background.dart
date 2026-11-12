import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/store.dart';
import '../theme/app_theme.dart';
import '../wallpapers/wallpapers.dart';

/// 页面底色。
///
/// 默认是几团极淡的光晕叠出来的——玻璃卡片必须有东西可以「透」。
/// 设了壁纸就用壁纸，再按 wallpaperDim 压暗保证文字可读。
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 用 select 而不是 watch：收藏、进度这些变化不该把壁纸跟着重绘一遍
    final path = context.select<AppStore, String?>((s) => s.wallpaper);
    final dim = context.select<AppStore, double>((s) => s.wallpaperDim);
    final wallId = context.select<AppStore, String?>((s) => s.wallpaperId);
    final dark = AppColors.isDark;
    final accent = AppColors.primary;

    // 内置壁纸：直接画
    final builtin = wallpaperById(wallId);
    if (builtin != null) {
      return Stack(
        children: [
          // RepaintBoundary + isComplex/willChange 让引擎把壁纸光栅化成一层纹理，
          // 页面转场、列表滚动时不再逐帧重画那几百条线
          Positioned.fill(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: builtin.painter,
                isComplex: true,
                willChange: false,
              ),
            ),
          ),
          Positioned.fill(
            child: ColoredBox(
              color: (builtin.dark || dark ? Colors.black : Colors.white)
                  .withValues(alpha: dim),
            ),
          ),
          Positioned.fill(child: child),
        ],
      );
    }

    if (path != null) {
      final file = File(path);
      if (file.existsSync()) {
        return Stack(
          children: [
            Positioned.fill(
              child: Image.file(
                file,
                fit: BoxFit.cover,
                gaplessPlayback: true,
                errorBuilder: (_, _, _) => ColoredBox(color: AppColors.bg),
              ),
            ),
            // 压暗：浅色模式用白色蒙层，深色模式用黑色，都不把图弄脏
            Positioned.fill(
              child: ColoredBox(
                color: (dark ? Colors.black : Colors.white).withValues(
                  alpha: dim,
                ),
              ),
            ),
            Positioned.fill(child: child),
          ],
        );
      }
    }

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
                    Color.lerp(
                      accent,
                      const Color(0xFF7BD3FF),
                      0.6,
                    )!.withValues(alpha: bottomRight),
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
