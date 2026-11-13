import '../l10n/app_localizations.dart';
import '../models/drama.dart';
import '../models/media_source.dart';

/// 「刚刚 / 3 小时前 / 昨天 / 11-05」
String relativeTime(DateTime t, L l) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return l.timeJustNow;
  if (d.inHours < 1) return l.minutesAgo(d.inMinutes);
  if (d.inDays < 1) return l.hoursAgo(d.inHours);
  if (d.inDays == 1) return l.timeYesterday;
  if (d.inDays < 7) return l.daysAgo(d.inDays);
  return '${t.month}-${t.day.toString().padLeft(2, '0')}';
}

/// 列表里那一行进度文案。
///
/// 小说：`第 12 章 / 共 40 章 · 3 天前`
/// 影视：`第 03 集 / 40 · 3 天前`
String progressLine(WatchRecord r, L l) {
  final rel = relativeTime(r.updatedAt, l);
  // 只是收藏、还没动过
  if (r.totalEpisodes == 0 && r.episodeName == null) {
    return l.progressNotStarted(rel);
  }
  if (r.kind == SourceKind.novel) {
    final current = r.chapterIndex + 1;
    final head = r.totalEpisodes > 0
        ? l.chapterProgress(current, r.totalEpisodes)
        : l.chapterAt(current);
    return '$head · $rel';
  }

  final name = r.episodeName ?? l.episodeNotStarted;
  final head = r.totalEpisodes > 0 ? '$name / ${r.totalEpisodes}' : name;
  return '$head · $rel';
}
