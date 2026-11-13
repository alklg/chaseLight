import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_account.dart';

/// Supabase 接入。url 和 key 都是公开值，打包进客户端是设计如此的。
///
/// 现在的用途只有一件事：账号 + 收藏/进度同步。
/// 没登录时一切照旧走本地，登录以后本地数据会推上去。
class SupabaseService {
  static const url = 'https://gysrkowxrtuifghgobdw.supabase.co';
  static const anonKey = 'sb_publishable_s6i4MmTAofYIypj-No2q_w_rJoBYZaX';

  static bool _ready = false;

  /// 初始化失败不抛给上层：没网的时候 App 还得能用
  static Future<void> init() async {
    if (_ready) return;
    try {
      await Supabase.initialize(url: url, publishableKey: anonKey);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
  }

  static bool get available => _ready;

  static SupabaseClient get client => Supabase.instance.client;

  static User? get user => _ready ? client.auth.currentUser : null;

  static bool get signedIn => user != null;

  static String? get email => user?.email;

  /// 注册。返回 true 表示已直接登录（关掉了邮箱验证），
  /// false 表示要先去邮箱点确认链接。
  static Future<bool> signUp(String email, String password) async {
    final res = await client.auth.signUp(email: email, password: password);
    if (res.session == null) return false;
    await _ensureProfile(email);
    return true;
  }

  /// 往 profiles 补一条自己的资料。失败不抛，表没建也不影响登录。
  ///
  /// 不要覆盖已有行：登录多次不能把用户改过的昵称打回邮箱前缀。
  static Future<void> _ensureProfile(String email) async {
    final u = user;
    if (u == null) return;
    try {
      await client.from('profiles').upsert({
        'id': u.id,
        'nickname': email.split('@').first,
        'color': kAvatarColors.first,
      }, ignoreDuplicates: true);
    } catch (_) {}
  }

  static Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
    await _ensureProfile(email);
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// 找回密码邮件里的回跳地址，要和 Supabase 后台的 Redirect URLs 一致
  static const resetRedirect = 'com.chase.light://auth/reset';

  static Future<void> sendResetEmail(String email) async {
    await client.auth.resetPasswordForEmail(email, redirectTo: resetRedirect);
  }

  /// 邮件链接打开后：从 URL 片段里取 refresh_token 把恢复会话建立起来
  static Future<bool> acceptRecoveryLink(Uri uri) async {
    final raw = uri.fragment.isNotEmpty ? uri.fragment : uri.query;
    final params = Uri.splitQueryString(raw);
    if (params['type'] != 'recovery') return false;
    final refresh = params['refresh_token'];
    if (refresh == null || refresh.isEmpty) return false;
    await client.auth.setSession(refresh);
    return true;
  }

  static Future<void> updatePassword(String password) async {
    await client.auth.updateUser(UserAttributes(password: password));
  }

  // ---------------- 壁纸商店 ----------------

  static Future<List<Map<String, dynamic>>> fetchWallpapers() async {
    if (!_ready) return const [];
    try {
      final rows = await client
          .from('wallpapers')
          .select()
          .eq('status', 'published')
          .order('created_at', ascending: false)
          .limit(60);
      return (rows as List).cast<Map<String, dynamic>>();
    } catch (_) {
      return const [];
    }
  }

  static String wallpaperUrl(String path) =>
      client.storage.from('wallpapers').getPublicUrl(path);

  /// 注销账号：删 auth 用户需要 service role，客户端只能调 Edge Function
  static Future<void> deleteAccount() async {
    final res = await client.functions.invoke('delete-account');
    if (res.status != 200) {
      throw Exception('delete-account ${res.status}');
    }
  }

  /// 上传头像 / 背景图，返回可公开访问的 URL。
  ///
  /// 两个东西一套逻辑：同一个方法、同一个目录结构，只是桶和文件名不同。
  /// 路径带上时间戳做版本，避免 CDN 缓存到旧图。
  static Future<String?> uploadProfileImage({
    required bool isCover,
    required File file,
  }) async {
    if (!_ready) return null;
    final u = user;
    if (u == null) return null;
    final bucket = isCover ? 'backgrounds' : 'avatars';
    final name = isCover ? 'cover' : 'avatar';
    final path = '${u.id}/$name.jpg';
    try {
      await client.storage
          .from(bucket)
          .upload(
            path,
            file,
            fileOptions: const FileOptions(
              upsert: true,
              contentType: 'image/jpeg',
              cacheControl: '3600',
            ),
          );
      final url = client.storage.from(bucket).getPublicUrl(path);
      return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
    } catch (_) {
      return null;
    }
  }
}
