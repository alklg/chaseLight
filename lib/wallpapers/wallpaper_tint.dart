import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// 从壁纸图片里取「顶栏该用的颜色」。
///
/// 做法：把图缩到 4×16 再读像素，取**顶部三行**的平均。
/// 不取全图平均，是因为风景照算出来一片灰绿，而顶栏实际挨着的是图片最上面那块。
/// 缩图再采样，一张 4K 图也就几毫秒。
Future<Color?> extractTopColor(File file) async {
  try {
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 4,
      targetHeight: 16,
    );
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(
      format: ui.ImageByteFormat.rawRgba,
    );
    if (data == null) return null;

    var r = 0, g = 0, b = 0, n = 0;
    for (var y = 0; y < 3; y++) {
      for (var x = 0; x < 4; x++) {
        final i = (y * 4 + x) * 4;
        r += data.getUint8(i);
        g += data.getUint8(i + 1);
        b += data.getUint8(i + 2);
        n++;
      }
    }
    if (n == 0) return null;
    return Color.fromARGB(255, r ~/ n, g ~/ n, b ~/ n);
  } catch (_) {
    return null;
  }
}
