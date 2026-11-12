import 'package:flutter/material.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 不在这里初始化 Supabase：AuthGate 会 await 它，
  // 在它完成之前判断登录态一定判成「未登录」。
  runApp(const AppBootstrap());
}
