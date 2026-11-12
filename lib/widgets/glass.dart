import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// 磨砂玻璃背板。
///
/// 它只能模糊「下面真的有东西」的区域。盖在纯色背景上等于什么都没有，
/// 所以必须配合 `extendBodyBehindAppBar` 让内容滚到它下面。
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop({
    super.key,
    this.tint,
    this.blur = 24,
    this.opacity = 0.55,
  });

  final Color? tint;
  final double blur;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    // 顶栏一律不透明：设了壁纸时透花纹很脏，没设时纯色也不难看
    return ColoredBox(color: tint ?? AppColors.bg);
  }
}

/// 玻璃卡片：模糊 + 半透明 + 一圈上亮下暗的高光边，模拟玻璃切面。
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = 14,
    this.blur = 18,
    this.padding,
  });

  final Widget child;
  final double radius;
  final double blur;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: dark ? 0.07 : 0.55),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
              color: Colors.white.withValues(alpha: dark ? 0.10 : 0.7),
              width: 0.8,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// 底部弹出面板的玻璃底。配合 `showModalBottomSheet(backgroundColor: transparent)` 使用。
class GlassSheet extends StatelessWidget {
  const GlassSheet({super.key, required this.child, this.radius = 20});

  final Widget child;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: Container(
          color: AppColors.surface.withValues(alpha: 0.78),
          child: child,
        ),
      ),
    );
  }
}
