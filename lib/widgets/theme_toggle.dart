import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 深/浅色切换开关。
///
/// 轨道和滑块都是「半透明 + 双向渐变 + 亮边」堆出来的磨砂质感；
/// 滑块用 easeOutBack 走位，会轻微冲过头再弹回来，就是那个果冻感。
class ThemeToggle extends StatefulWidget {
  const ThemeToggle({super.key, required this.dark, required this.onChanged});

  final bool dark;
  final ValueChanged<bool> onChanged;

  @override
  State<ThemeToggle> createState() => _ThemeToggleState();
}

class _ThemeToggleState extends State<ThemeToggle> {
  static const _slide = Duration(milliseconds: 420);
  static const _jelly = Curves.easeOutBack;

  static const _trackW = 124.0;
  static const _trackH = 52.0;
  static const _knobW = 58.0;
  static const _knobH = 47.0;
  static const _radius = 26.0;

  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final dark = widget.dark;

    // 轨道：左上亮、右下暗的双色渐变，模拟光从左上打过来
    final trackGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: dark
          ? const [Color(0xFF39415A), Color(0xFF1E2436)]
          : const [Color(0xFFD8E5FA), Color(0xFFA6C0E9)],
    );
    // 滑块：比轨道更亮一档，像一块浮在上面的玻璃片
    final knobGradient = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: dark
          ? [
              Colors.white.withValues(alpha: 0.20),
              Colors.white.withValues(alpha: 0.06),
            ]
          : [
              Colors.white.withValues(alpha: 0.78),
              Colors.white.withValues(alpha: 0.34),
            ],
    );
    final rim = dark
        ? Colors.white.withValues(alpha: 0.22)
        : Colors.white.withValues(alpha: 0.85);

    final sunColor = dark
        ? const Color(0xFFE9E9EF).withValues(alpha: 0.7)
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
        scale: _pressed ? 0.965 : 1,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: Container(
          width: _trackW,
          height: _trackH,
          decoration: BoxDecoration(
            gradient: trackGradient,
            borderRadius: BorderRadius.circular(_radius),
            border: Border.all(color: rim, width: 1.4),
            boxShadow: [
              // 玻璃内部的一点体积感，不是投影
              BoxShadow(
                color: Colors.white.withValues(alpha: dark ? 0.05 : 0.55),
                blurRadius: 10,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_radius),
            child: Stack(
              children: [
                // 太阳
                Align(
                  alignment: const Alignment(-0.56, 0),
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: sunColor),
                    duration: _slide,
                    curve: Curves.easeOutCubic,
                    builder: (_, c, __) => SizedBox(
                      width: 25,
                      height: 25,
                      child: CustomPaint(painter: _SunPainter(c ?? sunColor)),
                    ),
                  ),
                ),
                // 月亮
                Align(
                  alignment: const Alignment(0.56, 0),
                  child: TweenAnimationBuilder<Color?>(
                    tween: ColorTween(end: moonColor),
                    duration: _slide,
                    curve: Curves.easeOutCubic,
                    builder: (_, c, __) =>
                        Icon(Icons.dark_mode_rounded, size: 24, color: c),
                  ),
                ),
                // 玻璃滑块
                AnimatedAlign(
                  alignment: dark
                      ? const Alignment(0.94, 0)
                      : const Alignment(-0.94, 0),
                  duration: _slide,
                  curve: _jelly,
                  child: Container(
                    width: _knobW,
                    height: _knobH,
                    decoration: BoxDecoration(
                      gradient: knobGradient,
                      borderRadius: BorderRadius.circular(_knobH / 2),
                      border: Border.all(color: rim, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: dark ? 0.22 : 0.06,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
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
