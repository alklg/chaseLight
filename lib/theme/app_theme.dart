import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'app_palette.dart';

/// 全局取色入口。配色是可切换的，所以这些都是运行时 getter——
/// 切换主题时在根部重建整棵树，所有引用自动跟着变。
class AppColors {
  static AppPalette _p = AppPalette.dark;

  static AppPalette get palette => _p;
  static bool get isDark => _p.isDark;
  static void apply(AppPalette p) => _p = p;

  static Color get bg => _p.bg;
  static Color get surface => _p.surface;
  static Color get surfaceHigh => _p.surfaceHigh;
  static Color get primary => _p.primary;
  static Color get primaryDim => _p.primaryDim;
  static Color get textPrimary => _p.textPrimary;
  static Color get textSecondary => _p.textSecondary;
  static Color get textTertiary => _p.textTertiary;
  static Color get divider => _p.divider;
  static Color get success => _p.success;
  static Color get danger => _p.danger;
}

ThemeData buildAppTheme([AppPalette palette = AppPalette.dark]) {
  AppColors.apply(palette);

  final scheme =
      ColorScheme.fromSeed(
        seedColor: palette.primary,
        brightness: palette.isDark ? Brightness.dark : Brightness.light,
      ).copyWith(
        primary: palette.primary,
        surface: palette.surface,
        surfaceContainerHighest: palette.surfaceHigh,
        onSurface: palette.textPrimary,
      );

  final base = ThemeData(
    useMaterial3: true,
    // 让 Material 组件按 iOS 的视觉惯例渲染：返回箭头用 chevron、转场横向滑入
    platform: TargetPlatform.iOS,
    colorScheme: scheme,
    scaffoldBackgroundColor: Colors.transparent,
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
    splashColor: Colors.transparent,
    fontFamilyFallback: const ['PingFang SC', 'Heiti SC'],
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: palette.bg,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: palette.textPrimary,
        fontSize: 17,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
      iconTheme: IconThemeData(color: palette.textPrimary, size: 22),
    ),
    textTheme: base.textTheme.apply(
      bodyColor: palette.textPrimary,
      displayColor: palette.textPrimary,
    ),
    dividerTheme: DividerThemeData(
      color: palette.divider,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.surfaceHigh,
      contentTextStyle: TextStyle(color: palette.textPrimary, fontSize: 14),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.surfaceHigh,
      hintStyle: TextStyle(color: palette.textTertiary, fontSize: 15),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: palette.primary, width: 1.4),
      ),
    ),
  );
}

/// 浮起卡片的统一阴影。深色底上阴影看不见，那边改用描边。
List<BoxShadow> get kSoftShadow => AppColors.isDark
    ? const []
    : const [
        BoxShadow(
          color: Color(0x12151C2E),
          blurRadius: 18,
          offset: Offset(0, 4),
        ),
      ];

/// 卡片填充。
///
/// **只能通过这一处改**：全 App 的卡片都取这个，不透明。
/// 之前用半透明渐变想做出「壁纸透上来」的通透感，结果是设了壁纸以后卡片
/// 底下花纹隐约可见，字发灰、边缘发脏，还不如老老实实一块实色。
LinearGradient get kCardGradient => LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.surface, AppColors.surface],
);

/// 卡片描边。深色靠一圈淡白提亮边缘，浅色靠一圈淡灰压出边界。
Border? get kSoftBorder => Border.all(
  color: AppColors.isDark
      ? Colors.white.withValues(alpha: 0.07)
      : AppColors.divider.withValues(alpha: 0.75),
  width: 0.8,
);

/// 常用的水平内边距，统一 20
const kPagePadding = EdgeInsets.symmetric(horizontal: 20);

BorderRadius get kCardRadius => BorderRadius.circular(14);
