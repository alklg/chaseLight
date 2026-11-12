import 'package:flutter/material.dart';

import 'app.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 失败也不阻塞启动：没网的时候 App 照常能用
  await SupabaseService.init();
  runApp(const AppBootstrap());
}
