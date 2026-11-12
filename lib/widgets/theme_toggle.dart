import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 深/浅色切换开关。
///
/// 两层都是「渐变描边 + 半透明磨砂填充」：描边从左上的白走到中间的淡、
/// 再到右下的白，磨砂本身不再加光斑。滑块走 easeOutBack，图标被套住时弹一下。
class ThemeToggle extends StatefulWidget {
  const ThemeToggle({super.key, required this.dark, required this.onChanged});

  final bool dark;
  final ValueChanged<bool> onChanged;

  @override
  State<ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends State<ThemeToggle>
    with SingleTickerProviderStateMixin {
  static const _trackW = 104.0;
  static const _trackH = 44.0;
  static const _knobW = 50.0;
  static const _knobH = 34.0;
  static const _gap = 5.0;
  static const _icon = 23.0;
  static const _sunSize = 21.5;
  static const _morph = Duration(milliseconds: 380);

  late final _pop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  bool _pressed = false;

  @override
  void didUpdateWidget(ThemeToggle old) {
    super.didUpdateWidget(old);
    if (old.dark != widget.dark) _pop.forward(from: 0);
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;

    final travel = (_trackW - _knobW) / 2;
    final align = (travel - _gap) / travel;
    final leftX = _gap + _knobW / 2 - _sunSize / 2;
    final rightX = _trackW - _gap - _knobW / 2 - _icon / 2;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: () => widget.onChanged(!dark),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: SizedBox(
          width: _trackW,
          height: _trackH,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(end: dark ? 1 : 0),
            duration: _morph,
            curve: Curves.easeOutCubic,
            builder: (context, t, _) {
              // 两态都带一点蓝，纯白叠在白色卡片上等于不存在
              Color mix(Color light, Color dark) => Color.lerp(light, dark, t)!;

              final sun = Color.lerp(
                const Color(0xFFFFB300),
                const Color(0xFFF4F4F8),
                t,
              )!;
              // 浅色是白月亮，靠一圈淡蓝阴影和淡底分开
              final moon = Color.lerp(
                Colors.white,
                const Color(0xFF86BAFF),
                t,
              )!;
              final moonHaze = Color.lerp(
                const Color(0xFF9CB8DE).withValues(alpha: 0.55),
                const Color(0xFF86BAFF).withValues(alpha: 0),
                t,
              )!;

              return Stack(
                children: [
                  // 轨道
                  Positioned.fill(
                    child: _GlassPlate(
                      radius: _trackH / 2,
                      fill: mix(
                        const Color(0xFFF1F6FE),
                        const Color(0xFF2C3448),
                      ),
                      rimTop: mix(
                        const Color(0xFFC4D6EF),
                        Colors.white.withValues(alpha: 0.58),
                      ),
                      rimMid: mix(
                        const Color(0xFFE2EBF9),
                        Colors.white.withValues(alpha: 0.18),
                      ),
                      rimBottom: mix(
                        const Color(0xFFB7CCE7),
                        Colors.white.withValues(alpha: 0.48),
                      ),
                    ),
                  ),

                  // 滑块
                  AnimatedAlign(
                    alignment: Alignment(dark ? align : -align, 0),
                    duration: const Duration(milliseconds: 460),
                    curve: Curves.easeOutBack,
                    child: SizedBox(
                      width: _knobW,
                      height: _knobH,
                      child: _GlassPlate(
                        radius: _knobH / 2,
                        fill: mix(
                          const Color(0xFFFBFDFF),
                          const Color(0xFF3C4660),
                        ),
                        rimTop: mix(
                          const Color(0xFFFFFFFF),
                          Colors.white.withValues(alpha: 0.72),
                        ),
                        rimMid: mix(
                          const Color(0xFFD9E5F6),
                          Colors.white.withValues(alpha: 0.26),
                        ),
                        rimBottom: mix(
                          const Color(0xFFCBD9EE),
                          Colors.white.withValues(alpha: 0.62),
                        ),
                        shadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: 0.05 + 0.15 * t,
                            ),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 太阳
                  Positioned(
                    left: leftX,
                    top: (_trackH - _sunSize) / 2,
                    child: _popping(
                      selected: !dark,
                      child: SizedBox(
                        width: _sunSize,
                        height: _sunSize,
                        child: CustomPaint(painter: _SunPainter(sun)),
                      ),
                    ),
                  ),

                  // 月亮
                  Positioned(
                    left: rightX,
                    top: (_trackH - _icon) / 2,
                    child: _popping(
                      selected: dark,
                      child: Icon(
                        Icons.dark_mode_rounded,
                        size: _icon,
                        color: moon,
                        shadows: [
                          Shadow(
                            color: moonHaze,
                            blurRadius: 3,
                            offset: const Offset(0, 0.5),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// 图标被滑块套住时弹一下：一个 sin 脉冲，起来再落回去
  Widget _popping({required bool selected, required Widget child}) {
    return AnimatedBuilder(
      animation: _pop,
      builder: (_, __) {
        final pulse = math.sin(_pop.value * math.pi);
        final amp = selected ? 0.18 : 0.08;
        return Transform.scale(scale: 1 + amp * pulse, child: child);
      },
    );
  }
}

/// 一块玻璃片：1px 的渐变描边（左上白 → 中间淡 → 右下白）+ 半透明磨砂内胆。
class _GlassPlate extends StatelessWidget {
  const _GlassPlate({
    required this.radius,
    required this.fill,
    required this.rimTop,
    required this.rimMid,
    required this.rimBottom,
    this.shadow,
  });

  final double radius;
  final Color fill;
  final Color rimTop;
  final Color rimMid;
  final Color rimBottom;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [rimTop, rimMid, rimBottom],
          stops: const [0, 0.52, 1],
        ),
        boxShadow: shadow,
      ),
      padding: const EdgeInsets.all(1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(radius - 1),
        ),
      ),
    );
  }
}

/// 中心圆 + 八道光芒。线宽和长度都按画布宽度等比，缩到 20px 也不糊。
class _SunPainter extends CustomPainter {
  const _SunPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.245;
    final paint = Paint()..color = color;

    canvas.drawCircle(c, r, paint..style = PaintingStyle.fill);

    final ray = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.125
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + 0.2;
      final inner = r + size.width * 0.10;
      final outer = r + size.width * 0.215;
      canvas.drawLine(
        c + Offset(math.cos(a), math.sin(a)) * inner,
        c + Offset(math.cos(a), math.sin(a)) * outer,
        ray,
      );
    }
  }

  @override
  bool shouldRepaint(_SunPainter old) => old.color != color;
}
