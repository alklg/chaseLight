import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../theme/app_theme.dart';

/// Solar 图标集（Bold Duotone）。
///
/// SVG 里有一层 opacity .5 的衬底，染色时只换色相、保留透明度，
/// 所以「淡色底 + 实色主体」的双色层次不会塌成单色。
class SolarIcon extends StatelessWidget {
  const SolarIcon(this.name, {super.key, this.size = 20, this.color});

  /// assets/icons 下的文件名，不含 .svg
  final String name;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(
        color ?? AppColors.textTertiary,
        BlendMode.srcIn,
      ),
    );
  }
}
