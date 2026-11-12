import 'package:flutter/material.dart';

/// 一套完整配色。深色和浅色各一份，运行时可切。
class AppPalette {
  const AppPalette({
    required this.name,
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.primary,
    required this.primaryDim,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.divider,
    this.appBarBg,
    required this.success,
    required this.danger,
    required this.isDark,
  });

  final String name;
  final Color bg;
  final Color surface;
  final Color surfaceHigh;
  final Color primary;
  final Color primaryDim;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color divider;

  /// 顶栏底色。null 时退回 bg。
  /// 设了壁纸就跟着壁纸的主调走，避免顶栏冷白、壁纸暖黄这种打架。
  final Color? appBarBg;
  final Color success;
  final Color danger;
  final bool isDark;

  AppPalette copyWith({
    String? name,
    Color? primary,
    Color? primaryDim,
    Color? appBarBg,
  }) {
    return AppPalette(
      name: name ?? this.name,
      bg: bg,
      appBarBg: appBarBg ?? this.appBarBg,
      surface: surface,
      surfaceHigh: surfaceHigh,
      primary: primary ?? this.primary,
      primaryDim: primaryDim ?? this.primaryDim,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textTertiary: textTertiary,
      divider: divider,
      success: success,
      danger: danger,
      isDark: isDark,
    );
  }

  static const dark = AppPalette(
    name: '深色',
    // 别用近黑：OLED 上纯黑会把卡片和背景的层次糊掉，整体压到深灰更耐看
    bg: Color(0xFF16161C),
    surface: Color(0xFF20202A),
    surfaceHigh: Color(0xFF2B2B36),
    primary: Color(0xFF5B9AFF),
    primaryDim: Color(0xFF2A5FB8),
    textPrimary: Color(0xFFF2F2F5),
    textSecondary: Color(0xFFA8A8B6),
    textTertiary: Color(0xFF7A7A88),
    divider: Color(0xFF32323E),
    success: Color(0xFF3ED598),
    danger: Color(0xFFFF5B50),
    isDark: true,
  );

  static const light = AppPalette(
    name: '浅色',
    bg: Color(0xFFF1F3F8),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFEAEDF4),
    primary: Color(0xFF1D5AD9),
    primaryDim: Color(0xFF16429E),
    textPrimary: Color(0xFF17171C),
    textSecondary: Color(0xFF5E5F68),
    textTertiary: Color(0xFF9B9CA5),
    divider: Color(0xFFE3E5EB),
    success: Color(0xFF1A9A68),
    danger: Color(0xFFD93A33),
    isDark: false,
  );
}
