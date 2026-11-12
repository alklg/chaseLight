import 'package:flutter/material.dart';

import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card.dart';

/// 云账号登录。没登录也能用，这里只是可选的同步入口。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.forced = false, this.onSuccess});

  /// 强制登录：去掉返回键，成功后不回退而是交给 onSuccess
  final bool forced;
  final VoidCallback? onSuccess;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _signUp = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final email = _email.text.trim();
    final pwd = _password.text;
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = '邮箱格式不对');
      return;
    }
    if (pwd.length < 6) {
      setState(() => _error = '密码至少 6 位');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      if (_signUp) {
        await SupabaseService.signUp(email, pwd);
      } else {
        await SupabaseService.signIn(email, pwd);
      }
      if (!mounted) return;
      if (widget.forced) {
        widget.onSuccess?.call();
      } else {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = SupabaseService.readable(e);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: Scaffold(
        appBar: AppBar(
          title: Text(_signUp ? '注册账号' : '登录'),
          automaticallyImplyLeading: !widget.forced,
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 20),
              child: Text(
                _signUp ? '邮箱和密码就够，验证邮件发到邮箱里点一下即可。' : '登录以后，收藏和阅读进度会同步到云端。',
                style: TextStyle(
                  fontSize: 12,
                  height: 1.7,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            AppCard(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
              child: Column(
                children: [
                  _field(
                    controller: _email,
                    hint: '邮箱',
                    keyboard: TextInputType.emailAddress,
                    icon: Icons.alternate_email_rounded,
                  ),
                  Divider(height: 1, color: AppColors.divider),
                  _field(
                    controller: _password,
                    hint: '密码',
                    icon: Icons.lock_outline_rounded,
                    obscure: _obscure,
                    trailing: IconButton(
                      onPressed: () => setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 12, 6, 0),
                child: Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.6,
                    color: AppColors.danger,
                  ),
                ),
              ),
            const SizedBox(height: 22),
            SizedBox(
              height: 48,
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _signUp ? '注册' : '登录',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _signUp = !_signUp;
                        _error = null;
                      }),
                child: Text(
                  _signUp ? '已经有账号了，去登录' : '没有账号？注册一个',
                  style: TextStyle(fontSize: 12.5, color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboard,
    bool obscure = false,
    Widget? trailing,
  }) {
    return SizedBox(
      height: 52,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboard,
              obscureText: obscure,
              style: TextStyle(fontSize: 14.5, color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  fontSize: 14.5,
                  color: AppColors.textTertiary,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }
}
