import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/drama.dart';

/// 小说章节的本地缓存。
///
/// 结构：`<app文档目录>/novel/<源id>/<书的哈希>/<章节序号>.json`
/// 一章几 KB，整本几十章也就几百 KB，不必上数据库。
class NovelCache {
  static Future<Directory> _dir(String sourceId, String bookUrl) async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${base.path}/novel/${_safe(sourceId)}/${_hash(bookUrl)}',
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  static String _safe(String s) => s.replaceAll(RegExp(r'[^\w\-]'), '_');

  /// FNV-1a，稳定且够短，同一本书的 URL 永远落到同一个目录
  static String _hash(String s) {
    var h = 0x811c9dc5;
    for (final c in s.codeUnits) {
      h ^= c;
      h = (h * 0x01000193) & 0xFFFFFFFF;
    }
    return h.toRadixString(16).padLeft(8, '0');
  }

  static Future<File> _file(String sourceId, String bookUrl, int index) async {
    final dir = await _dir(sourceId, bookUrl);
    return File('${dir.path}/$index.json');
  }

  static Future<ChapterContent?> read(
    String sourceId,
    String bookUrl,
    int index,
  ) async {
    try {
      final file = await _file(sourceId, bookUrl, index);
      if (!await file.exists()) return null;
      final map = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final paragraphs = (map['paragraphs'] as List).cast<String>();
      if (paragraphs.isEmpty) return null;
      return ChapterContent(
        title: map['title'] as String? ?? '',
        url: map['url'] as String? ?? '',
        paragraphs: paragraphs,
        charCount:
            (map['charCount'] as num?)?.toInt() ??
            paragraphs.fold<int>(0, (n, p) => n + p.length),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> write(
    String sourceId,
    String bookUrl,
    int index,
    ChapterContent chapter,
  ) async {
    try {
      final file = await _file(sourceId, bookUrl, index);
      await file.writeAsString(
        jsonEncode({
          'title': chapter.title,
          'url': chapter.url,
          'paragraphs': chapter.paragraphs,
          'charCount': chapter.charCount,
          'savedAt': DateTime.now().toIso8601String(),
        }),
      );
    } catch (_) {
      // 缓存失败不该影响阅读
    }
  }

  static Future<Set<int>> cachedIndexes(String sourceId, String bookUrl) async {
    try {
      final dir = await _dir(sourceId, bookUrl);
      final out = <int>{};
      await for (final entity in dir.list()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last;
        final idx = int.tryParse(name.replaceAll('.json', ''));
        if (idx != null) out.add(idx);
      }
      return out;
    } catch (_) {
      return {};
    }
  }

  /// 全部缓存占用的字节数
  static Future<int> totalBytes() async {
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/novel');
      if (!await dir.exists()) return 0;
      var total = 0;
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) total += await entity.length();
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// 清空全部小说缓存（阅读进度不受影响）
  static Future<void> clearAll() async {
    try {
      final base = await getApplicationDocumentsDirectory();
      final dir = Directory('${base.path}/novel');
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }

  static Future<void> clear(String sourceId, String bookUrl) async {
    try {
      final dir = await _dir(sourceId, bookUrl);
      if (await dir.exists()) await dir.delete(recursive: true);
    } catch (_) {}
  }
}
