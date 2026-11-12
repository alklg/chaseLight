import 'package:supabase_flutter/supabase_flutter.dart';

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
  static Future<void> _ensureProfile(String email) async {
    final u = user;
    if (u == null) return;
    try {
      await client.from('profiles').upsert({
        'id': u.id,
        'email': email,
        'nickname': email.split('@').first,
        'color': 0,
        'gender': 0,
      });
    } catch (_) {}
  }

  static Future<void> signIn(String email, String password) async {
    await client.auth.signInWithPassword(email: email, password: password);
    await _ensureProfile(email);
  }

  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  /// 把错误翻译成人话，界面上直接显示
  static String readable(Object e) {
    if (e is AuthException) {
      final m = e.message.toLowerCase();
      if (m.contains('invalid login credentials')) return '邮箱或密码不对';
      if (m.contains('already registered')) return '这个邮箱已经注册过了';
      if (m.contains('password should be at least')) return '密码至少 6 位';
      if (m.contains('unable to validate email')) return '邮箱格式不对';
      if (m.contains('email not confirmed')) return '邮箱还没验证，去收件箱点一下';
      return e.message;
    }
    return e.toString();
  }
}
