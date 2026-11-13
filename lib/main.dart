import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 边到边：让壁纸铺到系统导航条下面，导航条本身透明
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  // 不在这里初始化 Supabase：AuthGate 会 await 它，
  // 在它完成之前判断登录态一定判成「未登录」。
  runApp(const AppBootstrap());
}
