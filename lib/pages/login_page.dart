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

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  /// 0 = 登录，1 = 注册。装饰图形跟着这个值插值。
  late final _deco = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );

  final _email = TextEditingController();
  final _password = TextEditingController();
  final _pwdFocus = FocusNode();

  bool _signUp = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _deco.dispose();
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
                child: CustomPaint(painter: _DecoPainter(_deco)),
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
                      : () {
                          setState(() {
                            _signUp = !_signUp;
                            _error = null;
                          });
                          _signUp ? _deco.forward() : _deco.reverse();
                        },
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

/// 顶部装饰。
///
/// 登录态是「聚拢」：一个大圆压在右上，一个小圆在左下，点少而散。
/// 注册态是「张开」：两个圆各自移开、变大，点变多，弧线也翻过来。
/// 切换时所有参数一起插值，所以看起来是一个东西在变形，不是两张图在换。
class _DecoPainter extends CustomPainter {
  _DecoPainter(this.t) : super(repaint: t);

  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    final v = Curves.easeInOutCubic.transform(t.value);
    final c = AppColors.primary;
    final w = size.width;
    final h = size.height;

    double lerp(double a, double b) => a + (b - a) * v;

    // 大圆：从右上往中间靠，同时放大一点
    canvas.drawCircle(
      Offset(w * lerp(0.78, 0.62), h * lerp(0.30, 0.22)),
      h * lerp(0.46, 0.54),
      Paint()..color = c.withValues(alpha: lerp(0.07, 0.09)),
    );

    // 小圆：从左下移到右下，变大
    canvas.drawCircle(
      Offset(w * lerp(0.18, 0.74), h * lerp(0.72, 0.66)),
      h * lerp(0.26, 0.34),
      Paint()..color = c.withValues(alpha: lerp(0.12, 0.10)),
    );

    // 弧线：角度扫过去，像被拨了一下
    final arc = Paint()
      ..color = c.withValues(alpha: lerp(0.30, 0.42))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(w * lerp(0.42, 0.30), h * lerp(1.05, 0.95)),
        radius: h * lerp(0.95, 1.08),
      ),
      lerp(math.pi * 1.08, math.pi * 0.92),
      math.pi * lerp(0.42, 0.30),
      false,
      arc,
    );

    // 实心小圆：从左上游到右上
    canvas.drawCircle(
      Offset(w * lerp(0.62, 0.30), h * lerp(0.18, 0.30)),
      h * lerp(0.045, 0.038),
      Paint()..color = c.withValues(alpha: lerp(0.50, 0.62)),
    );

    // 散点：登录 5 颗，注册 8 颗，新的三颗淡入
    const base = [
      Offset(0.08, 0.16),
      Offset(0.30, 0.08),
      Offset(0.88, 0.62),
      Offset(0.52, 0.86),
      Offset(0.72, 0.78),
    ];
    const extra = [Offset(0.18, 0.44), Offset(0.90, 0.20), Offset(0.40, 0.62)];
    final dot = Paint();
    for (final p in base) {
      dot.color = c.withValues(alpha: 0.22);
      canvas.drawCircle(Offset(w * p.dx, h * p.dy), 2.4, dot);
    }
    if (v > 0) {
      for (final p in extra) {
        dot.color = c.withValues(alpha: 0.22 * v);
        canvas.drawCircle(Offset(w * p.dx, h * p.dy), 2.4, dot);
      }
    }
  }

  @override
  bool shouldRepaint(_DecoPainter old) => old.t != t;
}
