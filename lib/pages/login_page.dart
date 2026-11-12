import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/solar_icon.dart';

/// 登录 / 注册。
///
/// 结构参照设计稿：顶部一块装饰插画、左对齐大标题、下划线式输入框。
/// 装饰围绕「追光」主题用几何光影与书页/镜头元素构成，随登录/注册态平滑插值变形。
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
  final _confirm = TextEditingController();
  final _pwdFocus = FocusNode();
  final _confirmFocus = FocusNode();

  bool _signUp = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _deco.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _pwdFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    final email = _email.text.trim();
    final pwd = _password.text;

    // 比「包含 @」严得多：挡掉 a@b、@@@ 这类
    final emailRe = RegExp(r'^[\w.+\-]+@[\w\-]+\.[\w.]{2,}$');
    if (!emailRe.hasMatch(email)) {
      setState(() => _error = '邮箱格式不对');
      return;
    }
    if (pwd.length < 6) {
      setState(() => _error = '密码至少 6 位');
      return;
    }
    if (_signUp && pwd != _confirm.text) {
      setState(() => _error = '两次密码不一致');
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
    final screenHeight = MediaQuery.sizeOf(context).height;
    // 顶部装饰占屏高约 28%，限制在合理区间以兼容小屏与平板
    final decoHeight = (screenHeight * 0.28).clamp(185.0, 260.0);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        backgroundColor: AppColors.bg,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 非强制入口时保留极简返回按钮，强制登录时仅留顶部呼吸空间
                if (!widget.forced)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                    child: IconButton(
                      onPressed: () => Navigator.maybePop(context),
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 8),

                // 顶部全宽几何光影插画。
                // 图形会故意画出血，所以上下各压一层渐变把它淡出到背景色，
                // 不然 clipRect 会把圆裁成一条直线，看着像一条分隔线。
                SizedBox(
                  height: decoHeight,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(painter: _DecoPainter(_deco)),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Container(
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  AppColors.bg,
                                  AppColors.bg.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: IgnorePointer(
                          child: Container(
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  AppColors.bg,
                                  AppColors.bg.withValues(alpha: 0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 下方正文与表单区
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),

                      // 微型品牌印记
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '追光',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2.5,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // 左对齐极粗大标题 + 丝滑切换动画
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.14),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        layoutBuilder: (currentChild, previousChildren) =>
                            Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                ...previousChildren,
                                if (currentChild != null) currentChild,
                              ],
                            ),
                        child: Text(
                          _signUp ? '创建账号' : '欢迎回来',
                          key: ValueKey(_signUp),
                          style: TextStyle(
                            fontSize: 31,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      // 副标题
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        layoutBuilder: (currentChild, previousChildren) =>
                            Stack(
                              alignment: Alignment.centerLeft,
                              children: [
                                ...previousChildren,
                                if (currentChild != null) currentChild,
                              ],
                            ),
                        child: Text(
                          _signUp ? '只需邮箱和密码，昵称之后随时能改' : '登录后自动同步你的追剧与阅读进度',
                          key: ValueKey(_signUp),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.55,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),

                      // 表单：两行极简下划线输入框
                      _UnderlineField(
                        controller: _email,
                        hint: '邮箱地址',
                        iconName: 'mail',
                        keyboard: TextInputType.emailAddress,
                        onNext: () => _pwdFocus.requestFocus(),
                      ),
                      const SizedBox(height: 14),
                      _UnderlineField(
                        controller: _password,
                        hint: '登录密码',
                        iconName: 'lock',
                        obscure: _obscure,
                        focusNode: _pwdFocus,
                        submit: true,
                        onNext: _submit,
                        trailing: GestureDetector(
                          onTap: () => setState(() => _obscure = !_obscure),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              left: 12,
                              top: 8,
                              bottom: 8,
                            ),
                            child: SolarIcon(
                              _obscure ? 'eye_closed' : 'eye',
                              size: 18,
                              color: _obscure
                                  ? AppColors.textTertiary
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),

                      // 注册时才出现的确认框
                      AnimatedSize(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topCenter,
                        child: !_signUp
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(top: 14),
                                child: _UnderlineField(
                                  controller: _confirm,
                                  hint: '确认密码',
                                  iconName: 'lock',
                                  obscure: _obscure,
                                  focusNode: _confirmFocus,
                                  submit: true,
                                  onNext: _submit,
                                ),
                              ),
                      ),

                      // 错误提示：表单与按钮之间平滑展开
                      AnimatedSize(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        alignment: Alignment.topLeft,
                        child: _error == null
                            ? const SizedBox(width: double.infinity)
                            : Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
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
                                          height: 1.4,
                                          color: AppColors.danger,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                      ),

                      const SizedBox(height: 36),

                      // 全宽主按钮
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: _busy ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            disabledBackgroundColor: AppColors.primary
                                .withValues(alpha: 0.45),
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
                                  _signUp ? '注 册' : '登 录',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 3,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // 底部切换登录 / 注册
                      Center(
                        child: GestureDetector(
                          onTap: _busy
                              ? null
                              : () {
                                  HapticFeedback.selectionClick();
                                  setState(() {
                                    _signUp = !_signUp;
                                    _error = null;
                                    _confirm.clear();
                                  });
                                  _signUp ? _deco.forward() : _deco.reverse();
                                },
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            child: Text.rich(
                              TextSpan(
                                style: const TextStyle(fontSize: 13),
                                children: [
                                  TextSpan(
                                    text: _signUp ? '已经有账号了？' : '还没有账号？',
                                    style: TextStyle(
                                      color: AppColors.textTertiary,
                                    ),
                                  ),
                                  TextSpan(
                                    text: _signUp ? ' 去登录' : ' 注册一个',
                                    style: TextStyle(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 下划线式输入行：左侧小图标 + 无边框输入 + 聚焦动态底线
class _UnderlineField extends StatefulWidget {
  const _UnderlineField({
    required this.controller,
    required this.hint,
    required this.iconName,
    this.keyboard,
    this.obscure = false,
    this.submit = false,
    this.focusNode,
    this.onNext,
    this.trailing,
  });

  final TextEditingController controller;
  final String hint;
  final String iconName;
  final TextInputType? keyboard;
  final bool obscure;
  final bool submit;
  final FocusNode? focusNode;
  final VoidCallback? onNext;
  final Widget? trailing;

  @override
  State<_UnderlineField> createState() => _UnderlineFieldState();
}

class _UnderlineFieldState extends State<_UnderlineField> {
  FocusNode? _ownNode;
  bool _focused = false;

  FocusNode get _effectiveNode =>
      widget.focusNode ?? (_ownNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _effectiveNode.addListener(_handleFocus);
  }

  @override
  void didUpdateWidget(covariant _UnderlineField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _ownNode)?.removeListener(_handleFocus);
      _effectiveNode.addListener(_handleFocus);
      _focused = _effectiveNode.hasFocus;
    }
  }

  @override
  void dispose() {
    _effectiveNode.removeListener(_handleFocus);
    _ownNode?.dispose();
    super.dispose();
  }

  void _handleFocus() {
    if (mounted && _focused != _effectiveNode.hasFocus) {
      setState(() => _focused = _effectiveNode.hasFocus);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomLeft,
      children: [
        // 静态极细底线
        Container(
          height: 50,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: AppColors.divider, width: 1),
            ),
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 13),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: SolarIcon(
                    widget.iconName,
                    size: 19,
                    color: _focused
                        ? AppColors.primary
                        : AppColors.textTertiary,
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  focusNode: _effectiveNode,
                  keyboardType: widget.keyboard,
                  obscureText: widget.obscure,
                  textInputAction: widget.submit
                      ? TextInputAction.done
                      : TextInputAction.next,
                  onSubmitted: (_) => widget.onNext?.call(),
                  cursorColor: AppColors.primary,
                  cursorWidth: 1.6,
                  style: TextStyle(
                    fontSize: 15.5,
                    color: AppColors.textPrimary,
                    letterSpacing: widget.obscure ? 1.5 : 0.2,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    hintStyle: TextStyle(
                      fontSize: 15,
                      letterSpacing: 0.2,
                      color: AppColors.textTertiary.withValues(alpha: 0.8),
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              if (widget.trailing != null) widget.trailing!,
            ],
          ),
        ),

        // 聚焦时从左向右生长的高亮底线
        LayoutBuilder(
          builder: (context, constraints) => AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            width: _focused ? constraints.maxWidth : 0,
            height: 1.8,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

/// 顶部「追光」几何装饰画布。
///
/// 视觉元素：柔和径向主光晕 + 空心镜头光圈 + 旋转的圆角书页卡片 + 掠光轨道弧 + 四角星芒。
/// 登录态（t=0）元素内敛聚拢；注册态（t=1）光圈张开、书页翻转、新的星芒浮现。
class _DecoPainter extends CustomPainter {
  _DecoPainter(this.t) : super(repaint: t);

  final Animation<double> t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);

    final v = Curves.easeInOutCubic.transform(t.value);
    final c = AppColors.primary;
    final w = size.width;
    final h = size.height;

    double lerp(double a, double b) => a + (b - a) * v;

    // 1. 远景柔和径向大光晕（营造「追光」氛围感，不生硬）
    final glowCenter = Offset(w * lerp(0.76, 0.58), h * lerp(0.38, 0.32));
    final glowRadius = h * lerp(0.72, 0.84);
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          c.withValues(alpha: lerp(0.15, 0.19)),
          c.withValues(alpha: lerp(0.05, 0.07)),
          c.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius));
    canvas.drawCircle(glowCenter, glowRadius, glowPaint);

    // 2. 实体柔光大圆（偏右上 -> 偏中上）
    canvas.drawCircle(
      Offset(w * lerp(0.80, 0.66), h * lerp(0.34, 0.28)),
      h * lerp(0.40, 0.46),
      Paint()..color = c.withValues(alpha: lerp(0.065, 0.085)),
    );

    // 3. 次级交叠圆（左下 -> 右下漫游，形成景深层叠）
    canvas.drawCircle(
      Offset(w * lerp(0.22, 0.78), h * lerp(0.68, 0.68)),
      h * lerp(0.23, 0.30),
      Paint()..color = c.withValues(alpha: lerp(0.085, 0.07)),
    );

    // 4. 旋转的圆角矩形（隐喻「书页 / 银幕帧」）
    canvas.save();
    canvas.translate(w * lerp(0.60, 0.34), h * lerp(0.52, 0.46));
    canvas.rotate(lerp(-0.22, 0.26));
    final cardRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset.zero,
        width: h * lerp(0.36, 0.40),
        height: h * lerp(0.46, 0.50),
      ),
      const Radius.circular(14),
    );
    canvas.drawRRect(
      cardRect,
      Paint()..color = c.withValues(alpha: lerp(0.06, 0.08)),
    );
    canvas.drawRRect(
      cardRect,
      Paint()
        ..color = c.withValues(alpha: lerp(0.18, 0.24))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.restore();

    // 5. 空心镜头环（细线圆环，增加几何精致度）
    canvas.drawCircle(
      Offset(w * lerp(0.28, 0.56), h * lerp(0.40, 0.56)),
      h * lerp(0.17, 0.22),
      Paint()
        ..color = c.withValues(alpha: lerp(0.18, 0.24))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // 6. 主掠光弧线：横跨画布的优雅圆弧
    final arcPaint = Paint()
      ..color = c.withValues(alpha: lerp(0.32, 0.44))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(
        center: Offset(w * lerp(0.48, 0.38), h * lerp(1.18, 1.06)),
        radius: h * lerp(0.96, 1.08),
      ),
      lerp(math.pi * 1.12, math.pi * 0.96),
      math.pi * lerp(0.44, 0.36),
      false,
      arcPaint,
    );

    // 7. 焦点实心光珠（画面视觉锚点）
    final orbCenter = Offset(w * lerp(0.68, 0.26), h * lerp(0.24, 0.28));
    canvas.drawCircle(
      orbCenter,
      h * lerp(0.068, 0.082),
      Paint()..color = c.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      orbCenter,
      h * lerp(0.036, 0.042),
      Paint()..color = c.withValues(alpha: lerp(0.68, 0.80)),
    );

    // 8. 四角星芒（✦ 呼应「追光」之光）
    _drawSparkle(
      canvas,
      Offset(w * lerp(0.84, 0.82), h * lerp(0.22, 0.26)),
      lerp(7.5, 9.5),
      c.withValues(alpha: lerp(0.55, 0.72)),
    );
    _drawSparkle(
      canvas,
      Offset(w * lerp(0.15, 0.18), h * lerp(0.30, 0.56)),
      lerp(5.5, 6.5),
      c.withValues(alpha: lerp(0.35, 0.48)),
    );
    if (v > 0.01) {
      _drawSparkle(
        canvas,
        Offset(w * 0.48, h * lerp(0.24, 0.18)),
        7.0 * v,
        c.withValues(alpha: 0.52 * v),
      );
    }

    // 9. 微尘散点：登录 4 颗，注册浮现额外 3 颗
    const baseDots = [
      Offset(0.11, 0.54),
      Offset(0.38, 0.18),
      Offset(0.89, 0.58),
      Offset(0.54, 0.80),
    ];
    const extraDots = [
      Offset(0.24, 0.78),
      Offset(0.70, 0.44),
      Offset(0.91, 0.36),
    ];
    final dotPaint = Paint();
    for (final p in baseDots) {
      dotPaint.color = c.withValues(alpha: 0.24);
      canvas.drawCircle(Offset(w * p.dx, h * p.dy), 2.3, dotPaint);
    }
    if (v > 0.01) {
      for (final p in extraDots) {
        dotPaint.color = c.withValues(alpha: 0.26 * v);
        canvas.drawCircle(Offset(w * p.dx, h * p.dy), 2.3 * v, dotPaint);
      }
    }

    canvas.restore();
  }

  /// 绘制四角星芒（✦）
  void _drawSparkle(Canvas canvas, Offset center, double r, Color color) {
    if (r <= 0.5) return;
    final path = Path()
      ..moveTo(center.dx, center.dy - r)
      ..quadraticBezierTo(center.dx, center.dy, center.dx + r, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy + r)
      ..quadraticBezierTo(center.dx, center.dy, center.dx - r, center.dy)
      ..quadraticBezierTo(center.dx, center.dy, center.dx, center.dy - r)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_DecoPainter old) => old.t != t;
}
