import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../utils/error_text.dart';
import '../widgets/app_background.dart';

/// 从找回密码邮件跳回来之后设置新密码。
///
/// 打开时 Supabase 已经用邮件里的 refresh_token 建立了恢复会话，
/// 这里只负责让用户输两遍新密码。
class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _pwd = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  bool _obscure = true;
  bool _missing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    if (!SupabaseService.signedIn) {
      setState(() => _missing = true);
    }
  }

  @override
  void dispose() {
    _pwd.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final t = L.of(context)!;
    if (_pwd.text.length < 6) {
      setState(() => _error = t.errPasswordShort);
      return;
    }
    if (_pwd.text != _confirm.text) {
      setState(() => _error = t.errPasswordMismatch);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await SupabaseService.updatePassword(_pwd.text);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.resetDone)));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = authErrText(e, L.of(context)!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return AppBackground(
      child: Scaffold(
        appBar: AppBar(title: Text(t.resetTitle)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          children: [
            Text(
              _missing ? t.resetExpired : t.resetNewHint,
              style: TextStyle(
                fontSize: 13,
                height: 1.7,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 26),
            TextField(
              controller: _pwd,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: t.newPassword,
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _confirm,
              obscureText: _obscure,
              decoration: InputDecoration(labelText: t.hintConfirm),
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 15,
                      color: AppColors.danger,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 28),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: _busy || _missing ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
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
                        t.save,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
