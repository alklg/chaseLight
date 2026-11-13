import 'package:flutter/material.dart';

/// 一个主题色。深色底和浅色底各配一档：同一个色值在两种背景上的对比度差很多，
/// 所以不能直接复用。
class AppAccent {
  const AppAccent(this.name, this.nameEn, this.onDark, this.onLight);

  final String name;

  /// 英文名，列表里按语言选
  final String nameEn;
  final Color onDark;
  final Color onLight;

  Color color(bool dark) => dark ? onDark : onLight;

  Color dim(bool dark) => dark
      ? Color.lerp(onDark, Colors.black, 0.38)!
      : Color.lerp(onLight, Colors.black, 0.18)!;
}

const kAccents = <AppAccent>[
  AppAccent('深邃蓝', 'Deep Blue', Color(0xFF4C8DFF), Color(0xFF1D5AD9)),
  AppAccent('天空蓝', 'Sky Blue', Color(0xFF4FC3F7), Color(0xFF0277BD)),
  AppAccent('青瓷', 'Celadon', Color(0xFF6FD3CB), Color(0xFF00726A)),
  AppAccent('抹茶绿', 'Matcha', Color(0xFF9CCC65), Color(0xFF4E7A2A)),
  AppAccent('橄榄', 'Olive', Color(0xFFB7C77A), Color(0xFF6B7A2E)),
  AppAccent('优雅粉', 'Rose', Color(0xFFFF8FB1), Color(0xFFC2185B)),
  AppAccent('暮光紫', 'Twilight', Color(0xFFB39DDB), Color(0xFF6A4FA8)),
  AppAccent('落日橙', 'Sunset', Color(0xFFFF9F68), Color(0xFFC4531F)),
];
