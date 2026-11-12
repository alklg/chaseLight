import '../models/media_source.dart';

/// 内置的示例源：汉典古籍（经史子集，公有领域）。
///
/// 只在首次启动、且没有任何源的时候自动加一次，删掉了不会再回来。
final MediaSource bookSourcePreset = MediaSource(
  id: 'zdic',
  name: '汉典古籍',
  baseUrl: 'https://gj.zdic.net',
  kind: SourceKind.novel,
  searchUrl: '/e/search/index.php?keyboard={kw}&show=book&tempid=1',
  search: const SearchRule(
    list: '.search-result-item',
    name: ExtractRule('.result-section a'),
    link: ExtractRule('.result-section a', 'href'),
    remark: ExtractRule('.result-author'),
  ),
  detail: const DetailRule(
    title: ExtractRule('h1'),
    episodes: '.article-bookdata li a',
    episodeName: ExtractRule(''),
    episodeLink: ExtractRule('', 'href'),
  ),
  chapter: const ChapterRule(
    title: ExtractRule('h1'),
    content: '.article-body',
  ),
  browse: const BrowseRule(
    categories: [
      BrowseCategory('经部', '/jingbu/'),
      BrowseCategory('史部', '/shibu/'),
      BrowseCategory('子部', '/zibu/'),
      BrowseCategory('集部', '/jibu/'),
    ],
    list: '.article',
    name: ExtractRule('.article-title a'),
    link: ExtractRule('.article-title a', 'href'),
    remark: ExtractRule('.publish-date a'),
    next: ExtractRule('.pager a[rel=next]', 'href'),
  ),
);

/// 按最常见的苹果CMS（MacCMS v10）页面结构生成一份源配置。
///
/// 大多数模板站开局都能直接跑；解析不到的地方，用户把导出的 JSON 改两条选择器就行。
MediaSource macCmsPreset(String input, {SourceKind kind = SourceKind.video}) {
  final raw = input.trim();
  if (raw.isEmpty) throw const FormatException('先填个站点地址');

  var normalized = raw;
  if (!normalized.startsWith('http://') && !normalized.startsWith('https://')) {
    normalized = 'https://$normalized';
  }

  late final Uri uri;
  try {
    uri = Uri.parse(normalized);
  } catch (_) {
    throw const FormatException('这不像一个网址');
  }
  if (uri.host.isEmpty || !uri.host.contains('.')) {
    throw const FormatException('域名看起来不对，例如 abc.com');
  }

  final origin = uri.hasPort
      ? '${uri.scheme}://${uri.host}:${uri.port}'
      : '${uri.scheme}://${uri.host}';

  final isNovel = kind == SourceKind.novel;

  return MediaSource(
    id: 'm_${DateTime.now().microsecondsSinceEpoch}',
    kind: kind,
    name: uri.host.replaceFirst(RegExp(r'^www\.'), ''),
    baseUrl: origin,
    searchUrl: '/index.php/vod/search.html?wd={kw}',
    search: const SearchRule(
      list: '.module-search-item',
      name: ExtractRule('.module-card-item-title a'),
      link: ExtractRule('.module-card-item-title a', 'href'),
      cover: ExtractRule('img', 'data-original'),
      remark: ExtractRule('.module-item-text'),
    ),
    detail: DetailRule(
      title: ExtractRule(isNovel ? 'h1' : '.page-title'),
      cover: const ExtractRule('.module-item-pic img', 'data-original'),
      desc: const ExtractRule('.module-info-introduction-content'),
      episodes: isNovel
          ? '.chapter-list a, .module-play-list-link'
          : '.module-play-list-link',
      episodeName: const ExtractRule('span'),
      episodeLink: const ExtractRule('', 'href'),
    ),
    browse: BrowseRule(
      categories: const [BrowseCategory('全部', '/index.php/vod/show/id/1.html')],
      list: '.module-items .module-item',
      name: ExtractRule('.module-card-item-title a'),
      link: ExtractRule('.module-card-item-title a', 'href'),
      cover: ExtractRule('img', 'data-original'),
      remark: ExtractRule('.module-item-text'),
      next: ExtractRule('.page a[rel=next]', 'href'),
    ),
    chapter: isNovel
        ? const ChapterRule(
            title: ExtractRule('h1'),
            content:
                '#content, #chaptercontent, .read-content, #booktext, .content',
          )
        : null,
  );
}
