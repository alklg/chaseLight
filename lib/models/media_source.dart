/// 一条取值规则，字符串写法为 `css选择器@属性名`。
///
/// - `h1`             取 h1 的文本（属性省略时默认 text）
/// - `a.title@href`   取 a.title 的 href
/// - `img@data-src`   取 img 的 data-src
/// - `@href`          取条目自身（list 命中的那个元素）的 href
class ExtractRule {
  const ExtractRule(this.selector, [this.attr = 'text']);

  final String selector;
  final String attr;

  bool get takesSelf => selector.isEmpty;
  bool get isText => attr == 'text' || attr == 'textContent';

  static ExtractRule? tryParse(Object? raw) {
    if (raw is! String) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    final at = s.lastIndexOf('@');
    if (at < 0) return ExtractRule(s);
    final selector = s.substring(0, at).trim();
    final attr = s.substring(at + 1).trim();
    return ExtractRule(selector, attr.isEmpty ? 'text' : attr);
  }

  String get raw => takesSelf ? '@$attr' : '$selector@$attr';
}

/// 搜索结果列表的解析规则。
class SearchRule {
  const SearchRule({
    required this.list,
    required this.name,
    this.link,
    this.cover,
    this.remark,
  });

  /// 匹配每一条结果的 CSS 选择器
  final String list;
  final ExtractRule name;
  final ExtractRule? link;
  final ExtractRule? cover;
  final ExtractRule? remark;

  factory SearchRule.fromJson(Map<String, dynamic> j) {
    final list = j['list'];
    if (list is! String || list.trim().isEmpty) {
      throw const FormatException('search.list 缺失：需要匹配每条结果的 CSS 选择器');
    }
    final name = ExtractRule.tryParse(j['name']);
    if (name == null) {
      throw const FormatException('search.name 缺失：例如 ".title@text"');
    }
    return SearchRule(
      list: list.trim(),
      name: name,
      link: ExtractRule.tryParse(j['link']),
      cover: ExtractRule.tryParse(j['cover']),
      remark: ExtractRule.tryParse(j['remark']),
    );
  }

  Map<String, dynamic> toJson() => {
    'list': list,
    'name': name.raw,
    if (link != null) 'link': link!.raw,
    if (cover != null) 'cover': cover!.raw,
    if (remark != null) 'remark': remark!.raw,
  };
}

/// 详情页规则：标题、封面、简介，以及剧集 / 章节列表。
class DetailRule {
  const DetailRule({
    this.title,
    this.cover,
    this.desc,
    required this.episodes,
    required this.episodeName,
    required this.episodeLink,
  });

  final ExtractRule? title;
  final ExtractRule? cover;
  final ExtractRule? desc;

  /// 匹配每一个剧集 / 章节条目
  final String episodes;
  final ExtractRule episodeName;
  final ExtractRule episodeLink;

  factory DetailRule.fromJson(Map<String, dynamic> j) {
    final episodes = j['episodes'];
    if (episodes is! String || episodes.trim().isEmpty) {
      throw const FormatException('detail.episodes 缺失：例如 ".play-list a"');
    }
    final name =
        ExtractRule.tryParse(j['episodeName']) ?? const ExtractRule('', 'text');
    final link =
        ExtractRule.tryParse(j['episodeLink']) ?? const ExtractRule('', 'href');
    return DetailRule(
      title: ExtractRule.tryParse(j['title']),
      cover: ExtractRule.tryParse(j['cover']),
      desc: ExtractRule.tryParse(j['desc']),
      episodes: episodes.trim(),
      episodeName: name,
      episodeLink: link,
    );
  }

  Map<String, dynamic> toJson() => {
    if (title != null) 'title': title!.raw,
    if (cover != null) 'cover': cover!.raw,
    if (desc != null) 'desc': desc!.raw,
    'episodes': episodes,
    'episodeName': episodeName.raw,
    'episodeLink': episodeLink.raw,
  };
}

/// 这个源提供的是什么内容
enum SourceKind {
  /// 影视，走播放器
  video,

  /// 小说，走阅读器
  novel,
}

/// 小说正文的解析规则。找不到就按常见容器依次试。
class ChapterRule {
  const ChapterRule({
    this.title,
    this.content = '#content, #chaptercontent, .read-content, .content, #booktext',
    this.next,
    this.prev,
  });

  final ExtractRule? title;

  /// 正文容器选择器，可以用英文逗号写多个候选，按顺序试
  final String content;

  /// 下一页 / 上一页（可选，用于连续阅读）
  final ExtractRule? next;
  final ExtractRule? prev;

  factory ChapterRule.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const ChapterRule();
    final c = (j['content'] ?? '').toString().trim();
    return ChapterRule(
      title: ExtractRule.tryParse(j['title']),
      content: c.isEmpty ? const ChapterRule().content : c,
      next: ExtractRule.tryParse(j['next']),
      prev: ExtractRule.tryParse(j['prev']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (title != null) 'title': title!.raw,
    'content': content,
    if (next != null) 'next': next!.raw,
    if (prev != null) 'prev': prev!.raw,
  };
}

enum PlayMode {
  /// 播放页里是网页播放器，需要开 WebView 嗅探真实地址
  web,

  /// 播放页 HTML 里能直接抽到 m3u8/mp4 地址
  direct,
}

class PlayRule {
  const PlayRule({this.mode = PlayMode.web, this.urlRule});

  final PlayMode mode;

  /// mode = direct 时，用这条规则从播放页抽取视频直链
  final ExtractRule? urlRule;

  bool get isDirect => mode == PlayMode.direct && urlRule != null;

  factory PlayRule.fromJson(Map<String, dynamic>? j) {
    if (j == null) return const PlayRule();
    final modeRaw = (j['type'] ?? 'web').toString().toLowerCase();
    final mode = modeRaw == 'direct' ? PlayMode.direct : PlayMode.web;
    return PlayRule(mode: mode, urlRule: ExtractRule.tryParse(j['url']));
  }

  Map<String, dynamic> toJson() => {
    'type': mode == PlayMode.direct ? 'direct' : 'web',
    if (urlRule != null) 'url': urlRule!.raw,
  };
}

/// 一个内容源。整份配置是纯 JSON，可以手动粘贴导入、也可以复制给别人。
class MediaSource {
  const MediaSource({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.searchUrl,
    required this.search,
    this.kind = SourceKind.video,
    this.detail,
    this.chapter,
    this.play = const PlayRule(),
    this.headers = const {},
    this.enabled = true,
  });

  final String id;
  final String name;
  final String baseUrl;

  /// 搜索地址模板，`{kw}` 会被替换成关键词
  final String searchUrl;
  final SearchRule search;
  final SourceKind kind;
  final DetailRule? detail;

  /// 仅小说源使用
  final ChapterRule? chapter;
  final PlayRule play;

  /// 部分站点需要特定 UA / Referer
  final Map<String, String> headers;
  final bool enabled;

  bool get isNovel => kind == SourceKind.novel;

  MediaSource copyWith({
    String? name,
    String? baseUrl,
    String? searchUrl,
    SearchRule? search,
    SourceKind? kind,
    DetailRule? detail,
    ChapterRule? chapter,
    PlayRule? play,
    Map<String, String>? headers,
    bool? enabled,
  }) {
    return MediaSource(
      id: id,
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      searchUrl: searchUrl ?? this.searchUrl,
      search: search ?? this.search,
      kind: kind ?? this.kind,
      detail: detail ?? this.detail,
      chapter: chapter ?? this.chapter,
      play: play ?? this.play,
      headers: headers ?? this.headers,
      enabled: enabled ?? this.enabled,
    );
  }

  factory MediaSource.fromJson(Map<String, dynamic> j) {
    final name = j['name'];
    if (name is! String || name.trim().isEmpty) {
      throw const FormatException('缺少 name 字段');
    }
    final baseUrl = (j['baseUrl'] ?? '').toString().trim();
    if (baseUrl.isEmpty) throw const FormatException('缺少 baseUrl 字段');
    final searchRaw = j['search'];
    if (searchRaw is! Map) throw const FormatException('缺少 search 字段');
    final searchUrl = (j['searchUrl'] ?? '').toString().trim();
    if (!searchUrl.contains('{kw}')) {
      throw const FormatException('searchUrl 里要用 {kw} 标记关键词位置');
    }
    final id = (j['id'] ?? '').toString().trim();
    return MediaSource(
      id: id.isEmpty ? name.trim() : id,
      name: name.trim(),
      baseUrl: baseUrl,
      searchUrl: searchUrl,
      search: SearchRule.fromJson(Map<String, dynamic>.from(searchRaw)),
      kind: (j['kind'] ?? '').toString().toLowerCase() == 'novel'
          ? SourceKind.novel
          : SourceKind.video,
      detail: j['detail'] is Map
          ? DetailRule.fromJson(Map<String, dynamic>.from(j['detail'] as Map))
          : null,
      chapter: j['chapter'] is Map
          ? ChapterRule.fromJson(Map<String, dynamic>.from(j['chapter'] as Map))
          : null,
      play: PlayRule.fromJson(
        j['play'] is Map ? Map<String, dynamic>.from(j['play'] as Map) : null,
      ),
      headers: j['headers'] is Map
          ? (j['headers'] as Map).map(
              (k, v) => MapEntry(k.toString(), v.toString()),
            )
          : const {},
      enabled: j['enabled'] is bool ? j['enabled'] as bool : true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'baseUrl': baseUrl,
    'searchUrl': searchUrl,
    'search': search.toJson(),
    if (kind == SourceKind.novel) 'kind': 'novel',
    if (detail != null) 'detail': detail!.toJson(),
    if (chapter != null) 'chapter': chapter!.toJson(),
    if (kind != SourceKind.novel) 'play': play.toJson(),
    if (headers.isNotEmpty) 'headers': headers,
    'enabled': enabled,
  };

  /// 把可能相对的地址补成绝对地址。
  /// 注意统一走 Uri.resolve：手写 replace(path:) 会把 `?query` 当成路径转义掉。
  Uri resolve(String path) {
    final p = path.trim();
    if (p.isEmpty) return Uri.parse(baseUrl);
    if (p.startsWith('http://') || p.startsWith('https://')) {
      return Uri.parse(p);
    }
    if (p.startsWith('//')) return Uri.parse('https:$p');
    final base = baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
    return Uri.parse(base).resolve(p);
  }
}
