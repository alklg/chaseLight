import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/supabase_service.dart';
import '../theme/app_theme.dart';

/// 登录 / 注册。
///
/// 结构参照设计稿：顶部一块装饰插画、左对齐大标题、下划线式输入框。
/// 装饰用几何图形而不是人物插画——手绘插画很难画到能看，几何至少不乱。
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.forced = false, this.onSuccess});

  final bool forced;
  final VoidCallback? onSuccess;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _pwdFocus = FocusNode();

  bool _signUp = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _pwdFocus.dispose();
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
    HapticFeedback.lightImpact();

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
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: widget.forced ? 28 : 8),

              // 顶部装饰
              SizedBox(
                height: 168,
                width: double.infinity,
                child: CustomPaint(painter: _DecoPainter()),
              ),

              const SizedBox(height: 18),

              // 标题
              Text(
                _signUp ? '注册' : '登录',
                style: TextStyle(
                  fontSize: 30,
                  height: 1.2,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _signUp ? '邮箱和密码就够，昵称之后能改' : '登录后收藏和阅读进度会同步',
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.6,
                  color: AppColors.textTertiary,
                ),
              ),

              const SizedBox(height: 34),

              // 表单：两行，下划线
              _UnderlineField(
                controller: _email,
                hint: '邮箱',
                icon: Icons.alternate_email_rounded,
                keyboard: TextInputType.emailAddress,
                onNext: () => _pwdFocus.requestFocus(),
              ),
              const SizedBox(height: 4),
              _UnderlineField(
                controller: _password,
                hint: '密码',
                icon: Icons.lock_outline_rounded,
                obscure: _obscure,
                focusNode: _pwdFocus,
                submit: true,
                onNext: _submit,
                trailing: GestureDetector(
                  onTap: () => setState(() => _obscure = !_obscure),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 10, top: 4, bottom: 4),
                    child: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 17,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ),

              // 错误
              AnimatedSize(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.topLeft,
                child: _error == null
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: Text(
                          _error!,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            color: AppColors.danger,
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: 30),

              // 主按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: FilledButton(
                  onPressed: _busy ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppColors.primary.withValues(
                      alpha: 0.5,
                    ),
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
                          _signUp ? '注册' : '登录',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 18),

              // 切换模式
              Center(
                child: GestureDetector(
                  onTap: _busy
                      ? null
                      : () => setState(() {
                          _signUp = !_signUp;
                          _error = null;
                        }),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Text(
                      _signUp ? '已经有账号了，去登录' : '没有账号？注册一个',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 下划线式输入行：图标 + 输入 + 底线
class _UnderlineField extends StatelessWidget {
  const _UnderlineField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.keyboard,
    this.obscure = false,
    this.submit = false,
    this.focusNode,
    this.onNext,
    this.trailing,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final TextInputType? keyboard;
  final bool obscure;
  final bool submit;
  final FocusNode? focusNode;
  final VoidCallback? onNext;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 1)),
      ),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Icon(icon, size: 18, color: AppColors.textTertiary),
          ),
          Expanded(
            child: SizedBox(
              height: 50,
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                keyboardType: keyboard,
                obscureText: obscure,
                textInputAction: submit
                    ? TextInputAction.done
                    : TextInputAction.next,
                onSubmitted: (_) => onNext?.call(),
                cursorColor: AppColors.primary,
                style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    fontSize: 15,
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 顶部装饰：几个圆 + 一道弧 + 几颗点，用主色的深浅变化撑出层次。
class _DecoPainter extends CustomPainter {
  const _DecoPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = AppColors.primary;
    final w = size.width;
    final h = size.height;

    // 大圆：右上角露出一部分
    canvas.drawCircle(
      Offset(w * 0.78, h * 0.30),
      h * 0.46,
      Paint()..color = c.withValues(alpha: 0.07),
    );

    // 中圆：左下
    canvas.drawCircle(
      Offset(w * 0.18, h * 0.72),
      h * 0.26,
      Paint()..color = c.withValues(alpha: 0.12),
    );

    // 弧线：从左上扫到右下
    final arc = Paint()
      ..color = c.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(w * 0.42, h * 1.05), radius: h * 0.95),
      math.pi * 1.08,
      math.pi * 0.42,
      false,
      arc,
    );

    // 小实心圆
    canvas.drawCircle(
      Offset(w * 0.62, h * 0.18),
      h * 0.045,
      Paint()..color = c.withValues(alpha: 0.55),
    );

    // 几颗散点
    final dot = Paint()..color = c.withValues(alpha: 0.22);
    for (final p in [
      const Offset(0.08, 0.16),
      const Offset(0.30, 0.08),
      const Offset(0.88, 0.62),
      const Offset(0.52, 0.86),
      const Offset(0.72, 0.78),
    ]) {
      canvas.drawCircle(Offset(w * p.dx, h * p.dy), 2.4, dot);
    }
  }

  @override
  bool shouldRepaint(_DecoPainter old) => false;
}
