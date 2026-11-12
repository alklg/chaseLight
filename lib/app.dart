import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'models/user_account.dart';
import 'services/supabase_service.dart';
import 'wallpapers/wallpapers.dart';
import 'services/store.dart';
import 'theme/accents.dart';
import 'theme/app_palette.dart';
import 'theme/app_theme.dart';

class DramaApp extends StatelessWidget {
  const DramaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final dark = store.darkMode;
    final accent = kAccents[store.accent.clamp(0, kAccents.length - 1)];
    // 顶栏跟着壁纸的主调走：壁纸是米黄，顶栏就不能是冷白
    // 顶栏底色：内置壁纸用预设 tint，图片壁纸用提取出的顶部色
    final wall = wallpaperById(store.wallpaperId);
    final barTint = dark ? null : (wall?.tint ?? store.wallpaperTint);

    final palette = (dark ? AppPalette.dark : AppPalette.light).copyWith(
      name: accent.name,
      primary: accent.color(dark),
      primaryDim: accent.dim(dark),
      appBarBg: barTint,
    );

    return MaterialApp(
      title: '追光',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(palette),
      builder: (context, child) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
            statusBarBrightness: dark ? Brightness.dark : Brightness.light,
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
    final signedIn = SupabaseService.signedIn;
    if (signedIn) await _ensureLocalUser();
    if (!mounted) return;
    setState(() => _signedIn = signedIn);
  }

  /// 云账号有了但本地还没有身份时补一个：
  /// 昵称取邮箱前缀，头像色轮着来。不然页面上永远是「未登录」。
  Future<void> _ensureLocalUser() async {
    final store = context.read<AppStore>();
    if (store.currentUser != null) return;
    final email = SupabaseService.email ?? '';
    final name = email.contains('@') ? email.split('@').first : email;
    if (name.isEmpty) return;
    await store.createUser(name, kAvatarColors.first);
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

    return LoginPage(
      forced: true,
      onSuccess: () async {
        await _ensureLocalUser();
        if (!mounted) return;
        setState(() => _signedIn = true);
        context.read<AppStore>().mergeCloudFavorites();
      },
    );
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
  late final Future<void> _ready = _store.load();

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
          child: const DramaApp(),
        );
      },
    );
  }
}
