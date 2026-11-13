import 'dart:async';
import 'dart:convert';

import 'package:fast_gbk/fast_gbk.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/drama.dart';
import '../models/media_source.dart';
import '../models/source_error.dart';

const kDefaultUserAgent =
    'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 '
    '(KHTML, like Gecko) Version/17.4 Safari/605.1.15';

typedef _Fetched = ({dom.Document doc, String body, Uri url});

/// 把一份源配置跑起来：抓页面 → 按 CSS 选择器提取 → 产出结构化数据。
class SourceRuleEngine {
  SourceRuleEngine({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<_Fetched> _load(Uri url, MediaSource source) async {
    late http.Response resp;
    try {
      resp = await _client
          .get(
            url,
            headers: {
              'User-Agent': kDefaultUserAgent,
              'Accept': 'text/html,application/xhtml+xml,*/*;q=0.8',
              'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
              ...source.headers,
            },
          )
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw SourceException('请求超时：${url.host}', code: SrcErr.timeout);
    } catch (e) {
      throw SourceException('网络错误：${_short(e)}', code: SrcErr.network);
    }
    if (resp.statusCode >= 400) {
      throw SourceException('HTTP ${resp.statusCode}（${url.host}）');
    }
    final body = _decodeBody(resp);
    return (doc: html_parser.parse(body), body: body, url: url);
  }

  String _decodeBody(http.Response resp) {
    final ct = resp.headers['content-type'] ?? '';
    final m = RegExp(
      r'''charset=["']?([\w-]+)''',
      caseSensitive: false,
    ).firstMatch(ct);
    final charset = (m?.group(1) ?? '').toLowerCase();
    final bytes = resp.bodyBytes;
    if (charset.contains('gb')) {
      try {
        return gbk.decode(bytes);
      } catch (_) {
        // 声明 GBK 实际是 UTF-8 的站不少，两种都试一遍
      }
    }
    try {
      return utf8.decode(bytes);
    } catch (_) {
      try {
        return gbk.decode(bytes);
      } catch (_) {
        return latin1.decode(bytes);
      }
    }
  }

  Future<List<SearchResult>> search(MediaSource source, String keyword) async {
    final rawUrl = source.searchUrl.replaceAll(
      '{kw}',
      Uri.encodeQueryComponent(keyword),
    );
    final fetched = await _load(source.resolve(rawUrl), source);
    final nodes = fetched.doc.querySelectorAll(source.search.list);
    final out = <SearchResult>[];
    final seen = <String>{};
    for (final node in nodes) {
      final title = _text(node, source.search.name);
      if (title == null) continue;
      final linkRule = source.search.link ?? const ExtractRule('', 'href');
      final href = _attr(node, linkRule);
      if (href == null) continue;
      final url = source.resolve(href).toString();
      if (!seen.add(url)) continue;
      out.add(
        SearchResult(
          title: _clean(title),
          url: url,
          cover: _absUrl(source, _attr(node, source.search.cover)),
          remark: _text(node, source.search.remark),
          sourceId: source.id,
          sourceName: source.name,
          kind: source.kind,
        ),
      );
    }
    return out;
  }

  Future<List<SourceSearchResult>> searchAll(
    List<MediaSource> sources,
    String keyword,
  ) async {
    final active = sources.where((s) => s.enabled).toList();
    if (active.isEmpty) return const [];
    return Future.wait(
      active.map((s) async {
        final sw = Stopwatch()..start();
        try {
          final items = await search(s, keyword);
          return SourceSearchResult(
            source: s,
            items: items,
            elapsed: sw.elapsed,
          );
        } catch (e) {
          return SourceSearchResult(
            source: s,
            error: _friendly(e),
            elapsed: sw.elapsed,
          );
        }
      }),
    );
  }

  /// 浏览一页列表。返回这一页的条目和「下一页」地址（没有就是到底了）。
  Future<({List<SearchResult> items, String? next})> browse(
    MediaSource source,
    String pageUrl,
  ) async {
    final rule = source.browse;
    if (rule == null) {
      throw SourceException('这个源没有配置浏览规则', code: SrcErr.noBrowseRule);
    }

    final fetched = await _load(source.resolve(pageUrl), source);
    final items = <SearchResult>[];
    final seen = <String>{};

    for (final node in fetched.doc.querySelectorAll(rule.list)) {
      final title = _text(node, rule.name);
      if (title == null) continue;
      final linkRule = rule.link ?? const ExtractRule('', 'href');
      final href = _attr(node, linkRule);
      if (href == null) continue;
      final url = source.resolve(href).toString();
      if (!seen.add(url)) continue;
      items.add(
        SearchResult(
          title: _clean(title),
          url: url,
          cover: _absUrl(source, _attr(node, rule.cover)),
          remark: _text(node, rule.remark),
          sourceId: source.id,
          sourceName: source.name,
          kind: source.kind,
        ),
      );
    }

    String? next;
    if (rule.next != null) {
      final root = fetched.doc.documentElement;
      if (root != null) next = _abs(source, _attr(root, rule.next!));
    }

    return (items: items, next: next);
  }

  Future<DramaDetail> detail(
    MediaSource source,
    String pageUrl, {
    String? fallbackTitle,
    String? fallbackCover,
  }) async {
    final fetched = await _load(Uri.parse(pageUrl), source);
    final root = fetched.doc.documentElement;
    final rule = source.detail;

    String? title;
    String? cover;
    String? desc;
    final episodes = <Episode>[];

    if (rule != null && root != null) {
      if (rule.title != null) title = _text(root, rule.title!);
      if (rule.cover != null) cover = _attr(root, rule.cover!);
      if (rule.desc != null) desc = _text(root, rule.desc!);

      final seen = <String>{};
      for (final node in fetched.doc.querySelectorAll(rule.episodes)) {
        final name = _text(node, rule.episodeName);
        final link = _attr(node, rule.episodeLink);
        if (name == null || link == null) continue;
        final url = source.resolve(link).toString();
        if (!seen.add('${_clean(name)}|$url')) continue;
        episodes.add(Episode(name: _clean(name), url: url));
      }
    }

    // 两列排版的书页会把奇偶回拆成两段，按名字里的序号重排回来
    if (episodes.length > 2) {
      final ordinals = episodes.map((e) => _ordinal(e.name)).toList();
      if (ordinals.every((o) => o > 0)) {
        final indexed = List.generate(
          episodes.length,
          (i) => (ord: ordinals[i], ep: episodes[i]),
        )..sort((a, b) => a.ord.compareTo(b.ord));
        episodes
          ..clear()
          ..addAll(indexed.map((e) => e.ep));
      }
    }

    return DramaDetail(
      title: (title == null || title.isEmpty)
          ? (fallbackTitle ?? source.name)
          : _clean(title),
      pageUrl: pageUrl,
      source: source,
      cover: _absUrl(source, cover) ?? fallbackCover,
      desc: desc == null ? null : _clean(desc),
      episodes: episodes,
    );
  }

  /// 抓一章正文。容器抓不到时返回空段落，由调用方决定怎么提示。
  Future<ChapterContent> chapter(
    MediaSource source,
    String chapterUrl, {
    String? fallbackTitle,
  }) async {
    final fetched = await _load(Uri.parse(chapterUrl), source);
    final rule = source.chapter ?? const ChapterRule();
    final root = fetched.doc.documentElement;

    String? title;
    String? next;
    String? prev;
    dom.Element? container;

    if (root != null) {
      if (rule.title != null) title = _text(root, rule.title!);
      if (rule.next != null) next = _attr(root, rule.next!);
      if (rule.prev != null) prev = _attr(root, rule.prev!);
      for (final selector in rule.content.split(',')) {
        final sel = selector.trim();
        if (sel.isEmpty) continue;
        final el = fetched.doc.querySelector(sel);
        if (el != null && _meaningfulLength(el) >= 40) {
          container = el;
          break;
        }
      }
    }

    final paragraphs = container == null
        ? const <String>[]
        : extractParagraphs(container);

    return ChapterContent(
      title: _clean(title ?? fallbackTitle ?? ''),
      url: chapterUrl,
      paragraphs: paragraphs,
      nextUrl: _abs(source, next),
      prevUrl: _abs(source, prev),
      charCount: paragraphs.fold<int>(0, (n, p) => n + p.length),
    );
  }

  /// direct 模式下从播放页里抠出真正的视频地址
  Future<String?> directPlayUrl(MediaSource source, String playPageUrl) async {
    final rule = source.play.urlRule;
    final fetched = await _load(Uri.parse(playPageUrl), source);
    if (rule != null) {
      final root = fetched.doc.documentElement;
      if (root != null) {
        final v = _attr(root, rule) ?? _text(root, rule);
        if (v != null && _looksLikeVideo(v)) {
          return source.resolve(v).toString();
        }
      }
    }
    // 兜底：整页扫一遍 m3u8 / mp4
    final m = RegExp(
      r'''https?://[^\s"'<>\\]+?\.(?:m3u8|mp4)[^\s"'<>\\]*''',
    ).firstMatch(fetched.body);
    if (m != null) return m.group(0);
    final escaped = RegExp(
      r'''https?:\\/\\/[^\s"'<>]+?\.(?:m3u8|mp4)[^\s"'<>]*''',
    ).firstMatch(fetched.body);
    if (escaped != null) return escaped.group(0)!.replaceAll(r'\/', '/');
    return null;
  }

  static const _blockTags = {
    'p',
    'div',
    'br',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'li',
    'tr',
    'section',
    'article',
    'blockquote',
    'dd',
    'dt',
  };

  /// 把一段 HTML 按块级元素和 <br> 切成段落，避免整章挤成一坨。
  ///
  /// 容器里有成规模的 <p> 时优先只取 <p>：这类站点会把导航、版权模板
  /// 塞在同一容器里，按 <p> 取能把它们挡在外面。
  static List<String> extractParagraphs(dom.Element root) {
    final ps = root.querySelectorAll('p');
    if (ps.length >= 3) {
      final picked = <String>[];
      for (final p in ps) {
        final t = _clean(p.text);
        if (t.isNotEmpty) picked.add(t);
      }
      if (picked.length >= 3) return picked;
    }

    final out = <String>[];
    final buf = StringBuffer();

    void flush() {
      final t = _clean(buf.toString());
      if (t.isNotEmpty) out.add(t);
      buf.clear();
    }

    void walk(dom.Node node) {
      for (final child in node.nodes) {
        if (child is dom.Text) {
          buf.write(child.text);
        } else if (child is dom.Element) {
          final tag = child.localName;
          if (tag == 'script' || tag == 'style') continue;
          if (tag == 'br') {
            flush();
            continue;
          }
          final block = _blockTags.contains(tag);
          if (block) flush();
          walk(child);
          if (block) flush();
        }
      }
    }

    walk(root);
    flush();
    return out;
  }

  /// 只算真正会被读到的文字长度，把 <style>/<script> 排除掉
  int _meaningfulLength(dom.Element el) {
    var n = 0;
    void walk(dom.Node node) {
      for (final child in node.nodes) {
        if (child is dom.Text) {
          n += child.text.trim().length;
        } else if (child is dom.Element) {
          final tag = child.localName;
          if (tag == 'style' || tag == 'script') continue;
          walk(child);
        }
      }
    }

    walk(el);
    return n;
  }

  static const _cnDigits = {
    '零': 0,
    '一': 1,
    '二': 2,
    '两': 2,
    '三': 3,
    '四': 4,
    '五': 5,
    '六': 6,
    '七': 7,
    '八': 8,
    '九': 9,
  };
  static const _cnUnits = {'十': 10, '百': 100, '千': 1000};

  /// 从「第十二回」「第 12 章」这类标题里取出序号，取不到返回 -1
  static int _ordinal(String name) {
    final m = RegExp(
      r'第\s*([0-9零一二三四五六七八九十百千两]+)\s*[回章节話话集篇卷]',
    ).firstMatch(name);
    if (m == null) return -1;
    final raw = m.group(1)!;
    final direct = int.tryParse(raw);
    if (direct != null) return direct;

    var section = 0;
    var number = 0;
    for (final ch in raw.split('')) {
      if (_cnDigits.containsKey(ch)) {
        number = _cnDigits[ch]!;
      } else if (_cnUnits.containsKey(ch)) {
        final unit = _cnUnits[ch]!;
        section += (number == 0 ? 1 : number) * unit;
        number = 0;
      }
    }
    final value = section + number;
    return value == 0 ? -1 : value;
  }

  String? _abs(MediaSource source, String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw == '#') return null;
    try {
      return source.resolve(raw).toString();
    } catch (_) {
      return null;
    }
  }

  // ---------- 提取工具 ----------

  dom.Element? _node(dom.Element scope, ExtractRule rule) {
    if (rule.takesSelf) return scope;
    return scope.querySelector(rule.selector);
  }

  String? _text(dom.Element scope, ExtractRule? rule) {
    if (rule == null) return null;
    final el = _node(scope, rule);
    if (el == null) return null;
    final v = rule.isText ? el.text : (el.attributes[rule.attr] ?? el.text);
    return _emptyToNull(_clean(v));
  }

  String? _attr(dom.Element scope, ExtractRule? rule) {
    if (rule == null) return null;
    final el = _node(scope, rule);
    if (el == null) return null;
    if (rule.isText) return _emptyToNull(_clean(el.text));
    var v = el.attributes[rule.attr];
    // 常见的懒加载写法
    if (v == null && (rule.attr == 'src' || rule.attr == 'href')) {
      v =
          el.attributes['data-src'] ??
          el.attributes['data-original'] ??
          el.attributes['data-url'] ??
          el.attributes[rule.attr];
    }
    return _emptyToNull(v?.trim());
  }

  String? _absUrl(MediaSource source, String? raw) {
    if (raw == null || raw.isEmpty) return null;
    if (raw.startsWith('data:')) return null;
    try {
      return source.resolve(raw).toString();
    } catch (_) {
      return null;
    }
  }

  static String _clean(String s) => s.replaceAll(RegExp(r'\s+'), ' ').trim();
  static String? _emptyToNull(String? s) => (s == null || s.isEmpty) ? null : s;

  static bool _looksLikeVideo(String s) =>
      s.contains('.m3u8') || s.contains('.mp4') || s.startsWith('http');

  static String _friendly(Object e) {
    if (e is SourceException) return e.message;
    return _short(e);
  }

  static String _short(Object e) {
    final s = e.toString();
    return s.length > 120 ? '${s.substring(0, 120)}…' : s;
  }

  void dispose() => _client.close();
}
