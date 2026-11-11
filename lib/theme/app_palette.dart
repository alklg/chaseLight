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
  final Color success;
  final Color danger;
  final bool isDark;

  AppPalette copyWith({String? name, Color? primary, Color? primaryDim}) {
    return AppPalette(
      name: name ?? this.name,
      bg: bg,
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
    bg: Color(0xFF0A0A0D),
    surface: Color(0xFF15151A),
    surfaceHigh: Color(0xFF1E1E25),
    primary: Color(0xFF4C8DFF),
    primaryDim: Color(0xFF2456A8),
    textPrimary: Color(0xFFF5F5F7),
    textSecondary: Color(0xFF9B9BA6),
    textTertiary: Color(0xFF5F5F6B),
    divider: Color(0xFF24242C),
    success: Color(0xFF3ED598),
    danger: Color(0xFFFF453A),
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
