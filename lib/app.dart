import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'pages/home_page.dart';
import 'pages/login_page.dart';
import 'services/supabase_service.dart';
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
    final palette = (dark ? AppPalette.dark : AppPalette.light).copyWith(
      name: accent.name,
      primary: accent.color(dark),
      primaryDim: accent.dim(dark),
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
  late bool _signedIn = SupabaseService.signedIn;

  @override
  Widget build(BuildContext context) {
    if (_signedIn) return const HomePage();
    return LoginPage(
      forced: true,
      onSuccess: () {
        setState(() => _signedIn = true);
        // 登录成功后把云端收藏并回来，失败也不影响进首页
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
