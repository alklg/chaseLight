import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'pressable.dart';

/// 全 App 唯一的卡片。
///
/// 新代码一律用它，不要再手写 `Container(decoration: BoxDecoration(...))`。
/// 卡片是**不透明**的：设了壁纸以后，半透明会让底下的花纹隐约透上来，
/// 字发灰、边缘发脏，试过一版毛玻璃，效果不如一块实色。
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.radius,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsets? padding;
  final VoidCallback? onTap;
  final double? radius;

  /// 内容需要被圆角裁掉时打开（比如里面放了图片）
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? 14;
    Widget body = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(r),
        boxShadow: kSoftShadow,
        border: kSoftBorder,
      ),
      child: clip
          ? ClipRRect(borderRadius: BorderRadius.circular(r), child: child)
          : child,
    );

    if (onTap != null) {
      body = Pressable(onTap: onTap, child: body);
    }
    return body;
  }
}
