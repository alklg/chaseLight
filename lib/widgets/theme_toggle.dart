import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 深/浅色切换开关。
///
/// 轨道里并排放太阳和月亮，一块玻璃滑块在上面滑。颜色不写死，
/// 深浅两态各配一套，切换时同步补间。
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key, required this.dark, required this.onChanged});

  final bool dark;
  final ValueChanged<bool> onChanged;

  static const _duration = Duration(milliseconds: 340);
  static const _curve = Curves.easeOutCubic;

  @override
  Widget build(BuildContext context) {
    final track = dark ? const Color(0xFF272D41) : const Color(0xFFBBD0F1);
    final rim = dark
        ? Colors.white.withValues(alpha: 0.14)
        : Colors.white.withValues(alpha: 0.72);
    final knob = dark
        ? Colors.white.withValues(alpha: 0.07)
        : Colors.white.withValues(alpha: 0.40);
    final sun = dark
        ? const Color(0xFFE9E9EF).withValues(alpha: 0.72)
        : const Color(0xFFF5C13A);
    final moon = dark
        ? const Color(0xFF74ABFF)
        : Colors.white.withValues(alpha: 0.94);

    return GestureDetector(
      onTap: () => onChanged(!dark),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: _duration,
        curve: _curve,
        width: 108,
        height: 46,
        decoration: BoxDecoration(
          color: track,
          borderRadius: BorderRadius.circular(23),
          border: Border.all(color: rim, width: 1.4),
        ),
        child: Stack(
          children: [
            const SizedBox.expand(),
            // 太阳
            Align(
              alignment: const Alignment(-0.52, 0),
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: sun),
                duration: _duration,
                curve: _curve,
                builder: (_, c, __) => SizedBox(
                  width: 23,
                  height: 23,
                  child: CustomPaint(painter: _SunPainter(c ?? sun)),
                ),
              ),
            ),
            // 月亮
            Align(
              alignment: const Alignment(0.52, 0),
              child: TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: moon),
                duration: _duration,
                curve: _curve,
                builder: (_, c, __) =>
                    Icon(Icons.dark_mode_rounded, size: 22, color: c),
              ),
            ),
            // 玻璃滑块
            AnimatedAlign(
              alignment: dark
                  ? const Alignment(0.92, 0)
                  : const Alignment(-0.92, 0),
              duration: _duration,
              curve: _curve,
              child: Container(
                width: 52,
                height: 42,
                decoration: BoxDecoration(
                  color: knob,
                  borderRadius: BorderRadius.circular(21),
                  border: Border.all(color: rim, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: dark ? 0.18 : 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
