import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 深/浅色切换开关。
///
/// 轨道和滑块都是「半透明底 + 左上高光 + 右下暗边 + 亮描边」堆出来的磨砂片。
/// 滑块走 easeOutBack 会轻微冲过头再回来，图标被套住时弹一下。
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
  static const _icon = 24.0;

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

    // 滑块在轨道内的左右定位值（留出 gap）
    final travel = (_trackW - _knobW) / 2;
    final align = (travel - _gap) / travel;
    // 图标左边缘：让图标中心正好压在滑块中心上
    final leftX = _gap + _knobW / 2 - _icon / 2;
    final rightX = _trackW - _gap - _knobW / 2 - _icon / 2;

    final sunColor = dark
        ? const Color(0xFFE9E9EF).withValues(alpha: 0.68)
        : const Color(0xFFF5C13A);
    final moonColor = dark
        ? const Color(0xFF74ABFF)
        : Colors.white.withValues(alpha: 0.95);

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
          child: Stack(
            children: [
              // 轨道：半透明底，能透出下面的卡片
              Positioned.fill(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: dark ? 0.055 : 0.34),
                    borderRadius: BorderRadius.circular(_trackH / 2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: dark ? 0.16 : 0.62),
                      width: 1,
                    ),
                  ),
                  child: _GlassSheen(
                    radius: _trackH / 2,
                    highlight: dark ? 0.10 : 0.55,
                    shade: dark ? 0.22 : 0.06,
                  ),
                ),
              ),

              // 太阳
              Positioned(
                left: leftX,
                top: (_trackH - _icon) / 2,
                child: _popping(
                  selected: !dark,
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: sunColor),
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    builder: (_, c, __) => SizedBox(
                      width: _icon,
                      height: _icon,
                      child: CustomPaint(painter: _SunPainter(c ?? sunColor)),
                    ),
                  ),
                ),
              ),

              // 月亮
              Positioned(
                left: rightX,
                top: (_trackH - _icon) / 2,
                child: _popping(
                  selected: dark,
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: moonColor),
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeOutCubic,
                    builder: (_, c, __) =>
                        Icon(Icons.dark_mode_rounded, size: _icon, color: c),
                  ),
                ),
              ),

              // 滑块
              AnimatedAlign(
                alignment: Alignment(dark ? align : -align, 0),
                duration: const Duration(milliseconds: 460),
                curve: Curves.easeOutBack,
                child: Container(
                  width: _knobW,
                  height: _knobH,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: dark ? 0.10 : 0.52),
                    borderRadius: BorderRadius.circular(_knobH / 2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: dark ? 0.22 : 0.9),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: dark ? 0.2 : 0.05,
                        ),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _GlassSheen(
                    radius: _knobH / 2,
                    highlight: dark ? 0.16 : 0.85,
                    shade: dark ? 0.3 : 0.08,
                  ),
                ),
              ),
            ],
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

/// 玻璃切面的光：左上亮斑 + 右下暗边
class _GlassSheen extends StatelessWidget {
  const _GlassSheen({
    required this.radius,
    required this.highlight,
    required this.shade,
  });

  final double radius;
  final double highlight;
  final double shade;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(-0.85, -0.95),
                radius: 1.1,
                colors: [
                  Colors.white.withValues(alpha: highlight),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0.9, 1.0),
                radius: 0.95,
                colors: [
                  Colors.black.withValues(alpha: shade),
                  Colors.black.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ],
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
    final r = size.width * 0.235;
    final paint = Paint()..color = color;

    canvas.drawCircle(c, r, paint..style = PaintingStyle.fill);

    final ray = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.085
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + 0.2;
      final inner = r + size.width * 0.085;
      final outer = r + size.width * 0.20;
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
