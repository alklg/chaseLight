import 'dart:math' as math;

import 'package:flutter/material.dart';

/// 内置壁纸。全部由代码绘制：不占包体、没有版权问题。
class Wallpaper {
  const Wallpaper({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.painter,
    this.darkPainter,
    this.dark = false,
    this.tint,
    this.accent,
  });

  final String id;
  final String name;
  final String nameEn;
  final CustomPainter painter;

  /// 深色模式的版本。设了就跟随主题自动切换，用户只需要选一次
  final CustomPainter? darkPainter;

  /// 深色底的壁纸，选中时压暗要用黑色
  final bool dark;

  /// 顶栏用的贴底色。取壁纸的主调、再往亮里提一档，
  /// 直接指定比从图上算平均色靠谱——算出来的经常发灰。
  final Color? tint;

  /// 这张壁纸搭配的主题色：App 主色直接跟着它走
  final Color? accent;
}

class _GradientPainter extends CustomPainter {
  const _GradientPainter(this.colors, {this.begin, this.end, this.radius});

  final List<Color> colors;
  final Alignment? begin;
  final Alignment? end;
  final double? radius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    if (radius != null) {
      final shader = RadialGradient(
        radius: radius!,
        colors: colors,
        center: const Alignment(-0.35, -0.45),
      ).createShader(rect);
      canvas.drawRect(rect, Paint()..shader = shader);
      return;
    }
    final shader = LinearGradient(
      begin: begin ?? Alignment.topLeft,
      end: end ?? Alignment.bottomRight,
      colors: colors,
    ).createShader(rect);
    canvas.drawRect(rect, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_GradientPainter old) => old.colors != colors;
}

/// 圆点阵：疏密渐变，像细沙
class _DotsPainter extends CustomPainter {
  const _DotsPainter({
    required this.background,
    required this.dot,
    this.step = 22,
  });

  final Color background;
  final Color dot;
  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    final paint = Paint()..color = dot;
    for (double y = step / 2; y < size.height; y += step) {
      for (double x = step / 2; x < size.width; x += step) {
        // 越靠左上越密（通过半径变化模拟）
        final t = 1 - (x / size.width * 0.6 + y / size.height * 0.4);
        final r = 1.0 + t * 1.4;
        canvas.drawCircle(Offset(x, y), r, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotsPainter old) => old.dot != dot;
}

/// 斜纹：45° 极细线
class _StripePainter extends CustomPainter {
  const _StripePainter({
    required this.background,
    required this.line,
    this.step = 14,
  });

  final Color background;
  final Color line;
  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final paint = Paint()
      ..color = line
      ..strokeWidth = 1;
    final span = size.width + size.height;
    for (double d = -size.height; d < span; d += step) {
      canvas.drawLine(
        Offset(d, 0),
        Offset(d + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.line != line;
}

/// 波纹：等距同心弧
class _WavePainter extends CustomPainter {
  const _WavePainter({
    required this.background,
    required this.line,
    this.step = 46,
  });

  final Color background;
  final Color line;
  final double step;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final paint = Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final center = Offset(size.width * 0.15, size.height * 0.2);
    final maxR = size.width * 1.6;
    for (double r = step; r < maxR; r += step) {
      canvas.drawCircle(center, r, paint);
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.line != line;
}

/// 纸纹：底色 + 稀疏噪点，模仿粗纸
class _PaperPainter extends CustomPainter {
  const _PaperPainter({required this.background, required this.speck});

  final Color background;
  final Color speck;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    // 固定种子，每次绘制纹理位置一致，不会闪
    final rnd = math.Random(20261112);
    final paint = Paint();
    final count = (size.width * size.height / 90).round().clamp(600, 4200);
    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final a = 0.04 + rnd.nextDouble() * 0.10;
      paint.color = speck.withValues(alpha: a);
      canvas.drawCircle(Offset(x, y), 0.7 + rnd.nextDouble() * 1.1, paint);
    }
  }

  @override
  bool shouldRepaint(_PaperPainter old) => old.background != background;
}

/// 内置壁纸清单。浅色深色各挑了一张中性底，其余是有色底的。
const kWallpapers = <Wallpaper>[
  Wallpaper(
    id: 'doodle_paper',
    name: '涂鸦 · 米白',
    nameEn: 'Doodle · Paper',
    painter: _DoodlePainter(
      background: Color(0xFFF8F0DF),
      ink: Color(0xFF8A7357),
      count: 64,
    ),
    tint: const Color(0xFFF3EDE0),
    accent: const Color(0xFF8C6A46),
  ),
  Wallpaper(
    id: 'doodle_mist',
    name: '涂鸦 · 雾蓝',
    nameEn: 'Doodle · Mist',
    painter: _DoodlePainter(
      background: Color(0xFFEDF1F6),
      ink: Color(0xFF7D8CA0),
      count: 64,
    ),
    tint: const Color(0xFFE9EEF5),
    accent: const Color(0xFF52708F),
  ),
  Wallpaper(
    id: 'doodle_ink',
    name: '涂鸦 · 墨夜',
    nameEn: 'Doodle · Ink',
    dark: true,
    painter: _DoodlePainter(
      background: Color(0xFF1B1C21),
      ink: Color(0xFF6E707C),
      count: 56,
    ),
    tint: const Color(0xFF202128),
    accent: const Color(0xFF8E93A8),
  ),
];

/// 手绘风格涂鸦墙：米色底 + 散落的小图案，参照 WhatsApp 那张默认壁纸的路子。
/// 全部用 Canvas 画，不依赖图标字体，也没有素材版权问题。
class _DoodlePainter extends CustomPainter {
  const _DoodlePainter({
    required this.background,
    required this.ink,
    this.count = 78,
  });

  final Color background;
  final Color ink;
  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    final rnd = math.Random(20261112);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var i = 0; i < count; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = rnd.nextDouble() * size.height;
      final s = 8 + rnd.nextDouble() * 16;
      // 之前 5%~11% 太淡，压在米色底上几乎看不见，抬到 10%~24%
      final a = 0.10 + rnd.nextDouble() * 0.14;
      paint
        ..color = ink.withValues(alpha: a)
        ..strokeWidth = 1.35;

      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rnd.nextDouble() * math.pi * 2);
      switch (rnd.nextInt(6)) {
        case 0:
          _ring(canvas, s, paint);
        case 1:
          _heart(canvas, s, paint);
        case 2:
          _star(canvas, s, paint);
        case 3:
          _wave(canvas, s, paint);
        case 4:
          _cross(canvas, s, paint);
        default:
          _spiral(canvas, s, paint);
      }
      canvas.restore();
    }
  }

  void _ring(Canvas c, double s, Paint p) =>
      c.drawCircle(Offset.zero, s * 0.45, p);

  void _heart(Canvas c, double s, Paint p) {
    final path = Path()
      ..moveTo(0, s * 0.42)
      ..cubicTo(-s * 0.75, -s * 0.15, -s * 0.28, -s * 0.7, 0, -s * 0.28)
      ..cubicTo(s * 0.28, -s * 0.7, s * 0.75, -s * 0.15, 0, s * 0.42)
      ..close();
    c.drawPath(path, p);
  }

  void _star(Canvas c, double s, Paint p) {
    final path = Path();
    for (var i = 0; i < 5; i++) {
      final a = -math.pi / 2 + i * 2 * math.pi / 5;
      final o = Offset(math.cos(a) * s * 0.55, math.sin(a) * s * 0.55);
      final b = -math.pi / 2 + (i + 0.5) * 2 * math.pi / 5;
      final inn = Offset(math.cos(b) * s * 0.24, math.sin(b) * s * 0.24);
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
      path.lineTo(inn.dx, inn.dy);
    }
    path.close();
    c.drawPath(path, p);
  }

  void _wave(Canvas c, double s, Paint p) {
    final path = Path()..moveTo(-s * 0.6, 0);
    for (var i = 0; i < 3; i++) {
      final x0 = -s * 0.6 + i * s * 0.4;
      path.cubicTo(
        x0 + s * 0.1,
        -s * 0.32,
        x0 + s * 0.3,
        s * 0.32,
        x0 + s * 0.4,
        0,
      );
    }
    c.drawPath(path, p);
  }

  void _cross(Canvas c, double s, Paint p) {
    c.drawLine(Offset(-s * 0.42, 0), Offset(s * 0.42, 0), p);
    c.drawLine(Offset(0, -s * 0.42), Offset(0, s * 0.42), p);
  }

  void _spiral(Canvas c, double s, Paint p) {
    final path = Path();
    for (var i = 0; i <= 46; i++) {
      final t = i / 46;
      final a = t * math.pi * 3.2;
      final r = s * 0.5 * t;
      final pt = Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        path.moveTo(pt.dx, pt.dy);
      } else {
        path.lineTo(pt.dx, pt.dy);
      }
    }
    c.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_DoodlePainter old) => old.ink != ink;
}

Wallpaper? wallpaperById(String? raw) {
  if (raw == null) return null;
  // 老版本把涂鸦的夜间版做成了独立项，统一收回主项
  final id = raw == 'doodleNight' ? 'doodle' : raw;
  for (final w in kWallpapers) {
    if (w.id == id) return w;
  }
  return null;
}
