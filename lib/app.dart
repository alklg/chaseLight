import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'pages/reset_password_page.dart';
import 'services/supabase_service.dart';
import 'services/sync_service.dart';
import 'wallpapers/wallpapers.dart';
import 'l10n/app_localizations.dart';
import 'services/store.dart';
import 'theme/accents.dart';
import 'theme/app_palette.dart';
import 'theme/app_theme.dart';

class DramaApp extends StatelessWidget {
  const DramaApp({super.key, this.navigatorKey});

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final dark = store.darkMode;
    final accentPreset = kAccents[store.accent.clamp(0, kAccents.length - 1)];
    final wall0 = wallpaperById(store.wallpaperId);
    // 主题色跟着壁纸走：壁纸给了 accent 就用它，商店图没有就用取色，最后才退回品牌色
    final baseAccent =
        wall0?.accent ?? (store.wallpaperTint ?? accentPreset.color(dark));
    final primary = _tuneAccent(baseAccent, dark);
    // 顶栏跟着壁纸的主调走：壁纸是米黄，顶栏就不能是冷白
    // 顶栏底色：内置壁纸用预设 tint，图片壁纸用提取出的顶部色
    final wall = wallpaperById(store.wallpaperId);
    final barTint = dark ? null : (wall?.tint ?? store.wallpaperTint);

    final basePalette = dark ? AppPalette.dark : AppPalette.light;
    // 卡片底色跟着壁纸轻轻染一点，别是刺眼的纯白
    final wallTint = wall0?.tint ?? store.wallpaperTint;
    final tintedSurface = wallTint == null
        ? basePalette.surface
        : Color.lerp(basePalette.surface, wallTint, dark ? 0.30 : 0.55)!;
    final tintedSurfaceHigh = wallTint == null
        ? basePalette.surfaceHigh
        : Color.lerp(basePalette.surfaceHigh, wallTint, dark ? 0.22 : 0.35)!;
    final palette = basePalette.copyWith(
      name: wall0?.name ?? accentPreset.name,
      primary: primary,
      primaryDim: _dimAccent(primary, dark),
      appBarBg: barTint,
      surface: tintedSurface,
      surfaceHigh: tintedSurfaceHigh,
    );

    final locale = store.lang == null ? null : Locale(store.lang!);

    // 系统导航条也跟主题走；constrastEnforced 关掉，否则透明会被系统加一层灰
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        // 透明在 3 键导航上会被系统忽略，直接用和背景一致的实色
        systemNavigationBarColor: dark
            ? const Color(0xFF151519)
            : const Color(0xFFF7F7FA),
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarContrastEnforced: false,
        systemNavigationBarIconBrightness: dark
            ? Brightness.light
            : Brightness.dark,
      ),
    );

    return MaterialApp(
      navigatorKey: navigatorKey,
      onGenerateTitle: (ctx) => L.of(ctx)!.appName,
      debugShowCheckedModeBanner: false,
      locale: locale,
      localizationsDelegates: const [
        L.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: L.supportedLocales,
      theme: buildAppTheme(palette),
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
            // 底部导航条也要跟着主题：否则深色壁纸下面拖一条白带
            systemNavigationBarColor: Colors.transparent,
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: dark
                ? Brightness.light
                : Brightness.dark,
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const AuthGate(),
    );
  }
}

/// 强制登录闸门：没登录就停在登录页，登录成功才放行进首页。
///
/// 没有「稍后再说」——这是刻意的，账号是唯一入口。
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  /// null = 还在检查登录态
  bool? _signedIn;
  StreamSubscription<AuthState>? _authSub;
  bool _loadingProfile = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  /// 必须等 Supabase 初始化完再判断：
  /// 它要从本地存储里把上次的 session 读回来，这个动作是异步的。
  /// 以前在 build 里同步读 signedIn，那时候 session 还没恢复，永远判成未登录。
  Future<void> _check() async {
    await SupabaseService.init();
    if (!mounted) return;
    // 初始化失败（没网/配置错）时不要碰 client，否则这里直接抛。
    if (!SupabaseService.available) {
      setState(() => _signedIn = false);
      return;
    }
    _watchAuth();
    if (SupabaseService.signedIn) {
      await _onSignedIn();
    } else if (mounted) {
      setState(() => _signedIn = false);
    }
  }

  /// 登录态一变就跟着切页面：退出后不能停在首页。
  void _watchAuth() {
    _authSub ??= SupabaseService.client.auth.onAuthStateChange.listen((state) {
      final signedIn = state.session != null;
      if (!mounted) return;
      if (signedIn != _signedIn) setState(() => _signedIn = signedIn);
      if (signedIn) {
        unawaited(_onSignedIn());
      }
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  /// 登录成功后：先把云端资料拉下来，再放行首页。
  ///
  /// 登录事件和 LoginPage 的回调都会走到这里，用 `_loadingProfile` 去重。
  Future<void> _onSignedIn() async {
    if (_loadingProfile) return;
    _loadingProfile = true;
    try {
      await _loadCloudProfile();
    } finally {
      _loadingProfile = false;
    }
    if (!mounted) return;
    setState(() => _signedIn = true);
    _syncFromCloud();
  }

  /// 云端 profile 落到本机。全云之后本机只有这一份身份。
  Future<void> _loadCloudProfile() async {
    final store = context.read<AppStore>();
    final email = SupabaseService.email ?? '';
    final fallback = email.contains('@') ? email.split('@').first : email;
    final row = await SyncService.pullProfile();
    if (!mounted) return;
    await store.applyCloudProfile(
      uid: SupabaseService.user?.id ?? '',
      fallbackName: fallback.isEmpty ? 'me' : fallback,
      nickname: row?['nickname'] as String?,
      color: (row?['color'] as num?)?.toInt(),
      gender: (row?['gender'] as num?)?.toInt(),
      birthday: row?['birthday'] as String?,
      signature: row?['signature'] as String?,
      avatarUrl: row?['avatar'] as String?,
      coverUrl: row?['cover'] as String?,
      createdAt: DateTime.tryParse(row?['created_at'] as String? ?? ''),
    );
    await store.cacheProfileImages();
  }

  @override
  Widget build(BuildContext context) {
    if (_signedIn == null) {
      final dark =
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
      return Scaffold(
        backgroundColor: dark
            ? const Color(0xFF16161C)
            : const Color(0xFFF1F3F8),
        body: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: dark ? const Color(0xFF5B9AFF) : const Color(0xFF2F6FE4),
            ),
          ),
        ),
      );
    }

    if (_signedIn!) return const HomePage();

    return LoginPage(forced: true, onSuccess: _onSignedIn);
  }

  /// 登录态就绪后把云端数据并回本地：收藏 + 进度。
  ///
  /// 不 await——云端慢或失败都不该挡住进首页，本地数据永远是主数据。
  void _syncFromCloud() {
    final store = context.read<AppStore>();
    unawaited(store.mergeCloudFavorites());
    unawaited(store.mergeCloudProgress());
    unawaited(store.mergeCloudProfile());
  }
}

/// 启动引导：先把本地数据读出来，再渲染首帧，避免闪一下空列表。
class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  final _store = AppStore();
  final _navKey = GlobalKey<NavigatorState>();
  late final Future<void> _ready = _store.load();
  StreamSubscription<Uri>? _links;

  @override
  void initState() {
    super.initState();
    _listenLinks();
  }

  @override
  void dispose() {
    _links?.cancel();
    super.dispose();
  }

  /// 找回密码邮件点回来会走这里：com.chase.light://auth/reset#...
  Future<void> _listenLinks() async {
    final appLinks = AppLinks();
    try {
      final initial = await appLinks.getInitialLink();
      if (initial != null) await _handleLink(initial);
    } catch (_) {}
    _links = appLinks.uriLinkStream.listen(
      (uri) => unawaited(_handleLink(uri)),
    );
  }

  Future<void> _handleLink(Uri uri) async {
    if (uri.scheme != 'com.chase.light' || uri.host != 'auth') return;
    final ok = await SupabaseService.acceptRecoveryLink(uri);
    if (!ok) return;
    await _ready;
    if (!mounted) return;
    await Future<void>.delayed(Duration.zero);
    _navKey.currentState?.push(
      MaterialPageRoute(builder: (_) => const ResetPasswordPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _ready,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return ColoredBox(
            color: AppColors.bg,
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            ),
          );
        }
        return ChangeNotifierProvider<AppStore>.value(
          value: _store,
          child: DramaApp(navigatorKey: _navKey),
        );
      },
    );
  }
}

/// 壁纸配套色的明度修正：深色模式提亮，浅色模式保持原色
Color _tuneAccent(Color base, bool dark) {
  final h = HSLColor.fromColor(base);
  if (!dark) {
    return h
        .withLightness(h.lightness.clamp(0.30, 0.52))
        .withSaturation(h.saturation.clamp(0.30, 0.80))
        .toColor();
  }
  return h
      .withLightness(h.lightness.clamp(0.62, 0.78))
      .withSaturation(h.saturation.clamp(0.22, 0.70))
      .toColor();
}

Color _dimAccent(Color primary, bool dark) {
  final h = HSLColor.fromColor(primary);
  return dark
      ? h.withLightness((h.lightness + 0.12).clamp(0.0, 0.9)).toColor()
      : h.withLightness((h.lightness - 0.10).clamp(0.0, 0.9)).toColor();
}
