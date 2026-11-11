import 'media_source.dart';

class SearchResult {
  const SearchResult({
    required this.title,
    required this.url,
    required this.sourceId,
    required this.sourceName,
    this.kind = SourceKind.video,
    this.cover,
    this.remark,
  });

  final String title;
  final String url;
  final String sourceId;
  final String sourceName;
  final SourceKind kind;
  final String? cover;
  final String? remark;
}

/// 一个源的搜索结果（或者它失败的原因）
class SourceSearchResult {
  const SourceSearchResult({
    required this.source,
    this.items = const [],
    this.error,
    this.elapsed = Duration.zero,
  });

  final MediaSource source;
  final List<SearchResult> items;
  final String? error;
  final Duration elapsed;

  bool get failed => error != null;
}

class Episode {
  const Episode({required this.name, required this.url});

  final String name;
  final String url;
}

/// 一章的正文（已按段落切好）
class ChapterContent {
  const ChapterContent({
    required this.title,
    required this.url,
    required this.paragraphs,
    this.nextUrl,
    this.prevUrl,
    this.charCount = 0,
  });

  final String title;
  final String url;
  final List<String> paragraphs;
  final String? nextUrl;
  final String? prevUrl;
  final int charCount;

  bool get isEmpty => paragraphs.isEmpty;
}

class DramaDetail {
  const DramaDetail({
    required this.title,
    required this.pageUrl,
    required this.source,
    this.cover,
    this.desc,
    this.episodes = const [],
  });

  final String title;
  final String pageUrl;
  final MediaSource source;
  final String? cover;
  final String? desc;
  final List<Episode> episodes;
}

/// 追剧 / 阅读记录：记住看到哪一集、读到哪一章
class WatchRecord {
  const WatchRecord({
    required this.sourceId,
    required this.sourceName,
    required this.title,
    required this.detailUrl,
    required this.updatedAt,
    this.cover,
    this.episodeName,
    this.episodeUrl,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.totalEpisodes = 0,
    this.kind = SourceKind.video,
    this.chapterIndex = 0,
  });

  final String sourceId;
  final String sourceName;
  final String title;
  final String detailUrl;
  final String? cover;
  final String? episodeName;
  final String? episodeUrl;
  final Duration position;
  final Duration duration;
  final int totalEpisodes;
  final SourceKind kind;

  /// 小说读到第几章（0 起）
  final int chapterIndex;
  final DateTime updatedAt;

  String get key => '$sourceId|$detailUrl';

  double get progress {
    if (kind == SourceKind.novel && totalEpisodes > 0) {
      return ((chapterIndex + 1) / totalEpisodes).clamp(0.0, 1.0);
    }
    if (duration.inMilliseconds <= 0) return 0;
    return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
  }

  WatchRecord copyWith({
    String? episodeName,
    String? episodeUrl,
    Duration? position,
    Duration? duration,
    int? totalEpisodes,
    String? cover,
    int? chapterIndex,
    DateTime? updatedAt,
  }) {
    return WatchRecord(
      sourceId: sourceId,
      sourceName: sourceName,
      title: title,
      detailUrl: detailUrl,
      cover: cover ?? this.cover,
      episodeName: episodeName ?? this.episodeName,
      episodeUrl: episodeUrl ?? this.episodeUrl,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      totalEpisodes: totalEpisodes ?? this.totalEpisodes,
      kind: kind,
      chapterIndex: chapterIndex ?? this.chapterIndex,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory WatchRecord.fromJson(Map<String, dynamic> j) => WatchRecord(
    sourceId: j['sourceId'] as String? ?? '',
    sourceName: j['sourceName'] as String? ?? '',
    title: j['title'] as String? ?? '',
    detailUrl: j['detailUrl'] as String? ?? '',
    cover: j['cover'] as String?,
    episodeName: j['episodeName'] as String?,
    episodeUrl: j['episodeUrl'] as String?,
    position: Duration(milliseconds: (j['position'] as num?)?.toInt() ?? 0),
    duration: Duration(milliseconds: (j['duration'] as num?)?.toInt() ?? 0),
    totalEpisodes: (j['totalEpisodes'] as num?)?.toInt() ?? 0,
    kind: (j['kind'] as String?) == 'novel'
        ? SourceKind.novel
        : SourceKind.video,
    chapterIndex: (j['chapterIndex'] as num?)?.toInt() ?? 0,
    updatedAt: DateTime.tryParse(j['updatedAt'] as String? ?? '') ??
        DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'sourceId': sourceId,
    'sourceName': sourceName,
    'title': title,
    'detailUrl': detailUrl,
    if (cover != null) 'cover': cover,
    if (episodeName != null) 'episodeName': episodeName,
    if (episodeUrl != null) 'episodeUrl': episodeUrl,
    'position': position.inMilliseconds,
    'duration': duration.inMilliseconds,
    'totalEpisodes': totalEpisodes,
    if (kind == SourceKind.novel) 'kind': 'novel',
    'chapterIndex': chapterIndex,
    'updatedAt': updatedAt.toIso8601String(),
  };
}
