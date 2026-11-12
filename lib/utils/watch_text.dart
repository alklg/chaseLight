import '../models/drama.dart';
import '../models/media_source.dart';

/// "刚刚 / 3 小时前 / 昨天 / 11-05"
String relativeTime(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return '刚刚';
  if (d.inHours < 1) return '${d.inMinutes} 分钟前';
  if (d.inDays < 1) return '${d.inHours} 小时前';
  if (d.inDays == 1) return '昨天';
  if (d.inDays < 7) return '${d.inDays} 天前';
  return '${t.month}-${t.day.toString().padLeft(2, '0')}';
}

/// 列表里那一行进度文案。
///
/// 小说：`第 12 章 / 共 40 章 · 3 天前`
/// 影视：`第 03 集 / 40 · 3 天前`
String progressLine(WatchRecord r) {
  // 只是收藏、还没动过
  if (r.totalEpisodes == 0 && r.episodeName == null) {
    return '还没开始 · ${relativeTime(r.updatedAt)}';
  }
  if (r.kind == SourceKind.novel) {
    final current = r.chapterIndex + 1;
    final head = r.totalEpisodes > 0
        ? '第 $current 章 / 共 ${r.totalEpisodes} 章'
        : '第 $current 章';
    return '$head · ${relativeTime(r.updatedAt)}';
  }

  final name = r.episodeName ?? '未开始';
  final head = r.totalEpisodes > 0 ? '$name / ${r.totalEpisodes}' : name;
  return '$head · ${relativeTime(r.updatedAt)}';
}
