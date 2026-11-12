import 'package:flutter/material.dart';

import 'app.dart';
import 'services/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 绝不 await：初始化要联网，首帧不能等它
  SupabaseService.init();
  runApp(const AppBootstrap());
}
