import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/drama.dart';
import '../models/media_source.dart';
import '../services/novel_cache.dart';
import '../services/rule_engine.dart';
import '../services/store.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/glass.dart';

class _ReaderTheme {
  const _ReaderTheme(this.bg, this.text, this.dim, this.accent);

  final Color bg;
  final Color text;
  final Color dim;
  final Color accent;
}

const _readerThemes = <_ReaderTheme>[
  _ReaderTheme(
    Color(0xFF121216),
    Color(0xFFCCCCD4),
    Color(0xFF6A6A76),
    Color(0xFF6FA6FF),
  ),
  _ReaderTheme(
    Color(0xFFEDE3CE),
    Color(0xFF3B3226),
    Color(0xFF8B7E68),
    Color(0xFF2A5599),
  ),
  _ReaderTheme(
    Color(0xFFF7F5F0),
    Color(0xFF26262B),
    Color(0xFF94949C),
    Color(0xFF1D5AD9),
  ),
  _ReaderTheme(
    Color(0xFF000000),
    Color(0xFFA9A9B2),
    Color(0xFF5A5A64),
    Color(0xFF6FA6FF),
  ),
];

/// 小说阅读器：抓一章正文 → 分段排版 → 记住读到哪。
class ReaderPage extends StatefulWidget {
  const ReaderPage({
    super.key,
    required this.source,
    required this.book,
    required this.startIndex,
  });

  final MediaSource source;
  final DramaDetail book;
  final int startIndex;

  @override
  State<ReaderPage> createState() => _ReaderPageState();
}

class _ReaderPageState extends State<ReaderPage> {
  final _engine = SourceRuleEngine();
  final _scroll = ScrollController();
  final _pageController = PageController();

  late final AppStore _store;
  late int _index;

  ChapterContent? _content;
  bool _loading = true;
  bool _fromCache = false;
  bool _showControls = false;
  bool _restored = false;
  int _cachedCount = 0;
  bool _caching = false;
  int _cacheDone = 0;

  bool _pagedMode = false;
  List<String> _pages = const [];
  int _pageIndex = 0;
  Size? _pagedSize;
  double? _pagedFont;
  double? _pagedLine;

  late double _fontSize;
  late double _lineHeight;
  late int _themeIndex;
  DateTime _lastSaved = DateTime.fromMillisecondsSinceEpoch(0);

  List<Episode> get _chapters => widget.book.episodes;

  @override
  void initState() {
    super.initState();
    _store = context.read<AppStore>();
    final rp = _store.readerPrefs;
    _fontSize = (rp['font'] as num?)?.toDouble() ?? 18;
    _lineHeight = (rp['line'] as num?)?.toDouble() ?? 1.95;
    _pagedMode = rp['paged'] as bool? ?? false;
    _themeIndex = (rp['theme'] as num?)?.toInt() ?? (AppColors.isDark ? 0 : 2);
    _index = widget.startIndex.clamp(0, (_chapters.length - 1).clamp(0, 9999));
    _scroll.addListener(_onScroll);
    _refreshCacheCount();
    _load();
  }

  @override
  void dispose() {
    _saveProgress();
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _pageController.dispose();
    _engine.dispose();
    super.dispose();
  }

  void _onScroll() {
    final now = DateTime.now();
    if (now.difference(_lastSaved) < const Duration(seconds: 4)) return;
    _lastSaved = now;
    _saveProgress();
  }

  Future<void> _load() async {
    if (_chapters.isEmpty) {
      setState(() {
        _loading = false;
        _noChapterList = true;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _noChapterList = false;
      _error = null;
      _content = null;
    });
    final chapter = _chapters[_index];

    // 先看本地缓存，命中就不发请求（断网也能读）
    final cached = await NovelCache.read(
      widget.source.id,
      widget.book.pageUrl,
      _index,
    );
    if (cached != null) {
      if (!mounted) return;
      setState(() {
        _content = cached;
        _loading = false;
        _fromCache = true;
      });
      _restorePosition();
      return;
    }

    try {
      final c = await _engine.chapter(
        widget.source,
        chapter.url,
        fallbackTitle: chapter.name,
      );
      await NovelCache.write(widget.source.id, widget.book.pageUrl, _index, c);
      if (!mounted) return;
      setState(() {
        _content = c;
        _loading = false;
        _fromCache = false;
      });
      _restorePosition();
      _saveProgress();
      _refreshCacheCount();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String? _error;

  /// 源里没解析出章节列表：文案要按当前语言在 build 里取，这里只记状态
  bool _noChapterList = false;

  Future<void> _refreshCacheCount() async {
    final set = await NovelCache.cachedIndexes(
      widget.source.id,
      widget.book.pageUrl,
    );
    if (!mounted) return;
    setState(() => _cachedCount = set.length);
  }

  /// 顺序抓整本，章与章之间留点间隔，别把源站打挂
  Future<void> _cacheAll() async {
    if (_caching) return;
    Navigator.maybePop(context);
    setState(() {
      _caching = true;
      _cacheDone = 0;
    });
    for (var i = 0; i < _chapters.length; i++) {
      if (!mounted || !_caching) return;
      final already = await NovelCache.read(
        widget.source.id,
        widget.book.pageUrl,
        i,
      );
      if (already == null) {
        try {
          final c = await _engine.chapter(
            widget.source,
            _chapters[i].url,
            fallbackTitle: _chapters[i].name,
          );
          await NovelCache.write(widget.source.id, widget.book.pageUrl, i, c);
          await Future.delayed(const Duration(milliseconds: 200));
        } catch (_) {
          // 单章失败跳过，不影响整体
        }
      }
      if (!mounted) return;
      setState(() => _cacheDone = i + 1);
    }
    if (!mounted) return;
    setState(() => _caching = false);
    _refreshCacheCount();
  }

  void _restorePosition() {
    final record = _store.findWatch(widget.source.id, widget.book.pageUrl);
    if (record == null || record.kind != SourceKind.novel) return;
    if (record.chapterIndex != _index) return;
    final offset = record.position.inMilliseconds.toDouble();
    if (offset < 50 || _restored) return;
    _restored = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      _scroll.jumpTo(offset.clamp(0, max));
    });
  }

  void _saveProgress() {
    if (_content == null || _chapters.isEmpty) return;
    final offset = _scroll.hasClients ? _scroll.offset : 0.0;
    final chapter = _chapters[_index];
    _store.upsertWatch(
      WatchRecord(
        sourceId: widget.source.id,
        sourceName: widget.source.name,
        title: widget.book.title,
        detailUrl: widget.book.pageUrl,
        cover: widget.book.cover,
        episodeName: chapter.name,
        episodeUrl: chapter.url,
        position: Duration(milliseconds: offset.round()),
        totalEpisodes: _chapters.length,
        kind: SourceKind.novel,
        chapterIndex: _index,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void _jumpTo(int index) {
    final tr = L.of(context)!;
    if (index < 0 || index >= _chapters.length || index == _index) return;
    _saveProgress();
    setState(() {
      _index = index;
      _restored = false;
      _pageIndex = 0;
      _pages = const [];
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
    if (_pageController.hasClients) _pageController.jumpToPage(0);
    _load();
  }

  void _next() {
    final tr = L.of(context)!;
    if (_index + 1 < _chapters.length) {
      _jumpTo(_index + 1);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(tr.lastChapter)));
    }
  }

  void _prev() => _jumpTo(_index - 1);

  @override
  Widget build(BuildContext context) {
    final tr = L.of(context)!;
    final t = _readerThemes[_themeIndex];
    final dark = t.bg.computeLuminance() < 0.4;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: dark ? Brightness.light : Brightness.dark,
        statusBarBrightness: dark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: t.bg,
        body: Stack(
          children: [
            Positioned.fill(child: _body(t)),
            if (_showControls) ...[_topBar(t), _bottomBar(t)],
            if (_caching) _cacheBanner(t),
          ],
        ),
      ),
    );
  }

  Widget _body(_ReaderTheme t) {
    final tr = L.of(context)!;
    if (_loading) {
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2, color: t.accent),
        ),
      );
    }
    if (_noChapterList || _error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _noChapterList ? tr.noEpisodeList : _error!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.6, color: t.dim),
              ),
              const SizedBox(height: 18),
              TextButton(
                onPressed: _load,
                child: Text(tr.retry, style: TextStyle(color: t.accent)),
              ),
            ],
          ),
        ),
      );
    }

    final c = _content;
    if (c == null || c.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr.chapterNoContent,
                style: TextStyle(fontSize: 14, color: t.dim),
              ),
              const SizedBox(height: 8),
              Text(
                tr.chapterRuleHint,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: t.dim.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: _load,
                    child: Text(tr.retry, style: TextStyle(color: t.accent)),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: _next,
                    child: Text(
                      tr.nextChapter,
                      style: TextStyle(color: t.accent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (_pagedMode) return _pagedBody(t);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => setState(() => _showControls = !_showControls),
      child: SafeArea(
        child: SingleChildScrollView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(22, 60, 22, 90),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                c.title.isEmpty ? _chapters[_index].name : c.title,
                style: TextStyle(
                  fontSize: _fontSize + 4,
                  height: 1.45,
                  fontWeight: FontWeight.w700,
                  color: t.text,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (_fromCache) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: t.dim.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tr.offline,
                        style: TextStyle(fontSize: 9.5, color: t.dim),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    tr.charCount(c.charCount),
                    style: TextStyle(fontSize: 11.5, color: t.dim),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '${_index + 1} / ${_chapters.length}',
                    style: TextStyle(fontSize: 11.5, color: t.dim),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              for (final p in c.paragraphs)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Text(
                    '　　$p',
                    style: TextStyle(
                      fontSize: _fontSize,
                      height: _lineHeight,
                      color: t.text,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              _chapterFooter(t),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _pageStyle(_ReaderTheme t) => TextStyle(
    fontSize: _fontSize,
    height: _lineHeight,
    color: t.text,
    letterSpacing: 0.2,
  );

  /// 按屏幕高度把整章切成页。用 TextPainter 量一遍，取每页右下角对应的字符位置。
  List<String> _paginate(String text, TextStyle style, Size size) {
    final pages = <String>[];
    final painter = TextPainter(textDirection: TextDirection.ltr);
    var start = 0;
    const bottomPad = 96.0;

    while (start < text.length) {
      final rest = text.substring(start);
      painter.text = TextSpan(text: rest, style: style);
      painter.layout(maxWidth: size.width);
      final usable = size.height - bottomPad;
      if (painter.height <= usable) {
        pages.add(rest);
        break;
      }
      final pos = painter.getPositionForOffset(
        Offset(size.width - 1, usable - 1),
      );
      var take = pos.offset;
      if (take <= 0) take = 1;
      final slice = rest.substring(0, take);
      final lastBreak = slice.lastIndexOf('\n');
      if (lastBreak > 0) take = lastBreak + 1;
      pages.add(rest.substring(0, take));
      start += take;
    }
    if (pages.isEmpty) pages.add(text);
    return pages;
  }

  Widget _pagedBody(_ReaderTheme t) {
    final tr = L.of(context)!;
    final c = _content;
    if (c == null || c.isEmpty) return const SizedBox.shrink();
    final text = c.paragraphs.map((p) => '　　$p').join('\n\n');
    final style = _pageStyle(t);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => setState(() => _showControls = !_showControls),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            if (_pagedSize != size ||
                _pagedFont != _fontSize ||
                _pagedLine != _lineHeight) {
              _pagedSize = size;
              _pagedFont = _fontSize;
              _pagedLine = _lineHeight;
              _pages = _paginate(text, style, size);
              _pageIndex = _pageIndex.clamp(0, _pages.length - 1);
            }
            return Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _pageIndex = i),
                    itemBuilder: (_, i) => Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                      child: Text(_pages[i], style: style),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
                  child: Row(
                    children: [
                      Text(
                        c.title.isEmpty ? _chapters[_index].name : c.title,
                        style: TextStyle(fontSize: 10.5, color: t.dim),
                      ),
                      const Spacer(),
                      Text(
                        '${_pageIndex + 1} / ${_pages.length}',
                        style: TextStyle(fontSize: 10.5, color: t.dim),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _chapterFooter(_ReaderTheme t) {
    final tr = L.of(context)!;
    final hasNext = _index + 1 < _chapters.length;
    final hasPrev = _index > 0;
    return Column(
      children: [
        Divider(color: t.dim.withValues(alpha: 0.18), height: 40),
        Row(
          children: [
            if (hasPrev)
              Expanded(
                child: TextButton(
                  onPressed: _prev,
                  child: Text(
                    tr.prevChapter,
                    style: TextStyle(fontSize: 13.5, color: t.accent),
                  ),
                ),
              )
            else
              const Spacer(),
            if (hasNext)
              Expanded(
                child: TextButton(
                  onPressed: _next,
                  child: Text(
                    tr.nextChapter,
                    style: TextStyle(fontSize: 13.5, color: t.accent),
                  ),
                ),
              )
            else
              Expanded(
                child: Text(
                  tr.bookEnd,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: t.dim),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _topBar(_ReaderTheme t) {
    final tr = L.of(context)!;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [t.bg, t.bg.withValues(alpha: 0.0)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: 52,
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: t.text,
                  ),
                ),
                Expanded(
                  child: Text(
                    widget.book.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: t.text,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bottomBar(_ReaderTheme t) {
    final tr = L.of(context)!;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [t.bg, t.bg.withValues(alpha: 0.0)],
          ),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.only(bottom: 14),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 18, 8, 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _barButton(
                  t,
                  Icons.skip_previous_rounded,
                  tr.prevChapter,
                  _index > 0 ? _prev : null,
                ),
                _barButton(t, Icons.list_rounded, tr.catalog, _showCatalog),
                _barButton(
                  t,
                  Icons.skip_next_rounded,
                  tr.nextChapter,
                  _index + 1 < _chapters.length ? _next : null,
                ),
                _barButton(
                  t,
                  Icons.text_fields_rounded,
                  tr.typography,
                  _showSettings,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _barButton(
    _ReaderTheme t,
    IconData icon,
    String label,
    VoidCallback? onTap,
  ) {
    final enabled = onTap != null;
    final color = enabled ? t.text : t.dim.withValues(alpha: 0.4);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 21, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 10.5, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(_ReaderTheme t, String label, VoidCallback? onTap) {
    final tr = L.of(context)!;
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: t.dim.withValues(alpha: enabled ? 0.14 : 0.06),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            color: enabled ? t.text : t.dim.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }

  Widget _cacheBanner(_ReaderTheme t) {
    final tr = L.of(context)!;
    final total = _chapters.isEmpty ? 1 : _chapters.length;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        color: t.bg.withValues(alpha: 0.97),
        padding: EdgeInsets.fromLTRB(
          22,
          MediaQuery.paddingOf(context).top + 12,
          22,
          12,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  tr.cachingProgress(_cacheDone, _chapters.length),
                  style: TextStyle(fontSize: 11.5, color: t.dim),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _caching = false),
                  child: Text(
                    tr.stop,
                    style: TextStyle(fontSize: 11.5, color: t.accent),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (_cacheDone / total).clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: t.dim.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(t.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCatalog() {
    final tr = L.of(context)!;
    final t = _readerThemes[_themeIndex];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (sheetContext) => GlassSheet(
        child: _CatalogSheet(
          chapters: _chapters,
          currentIndex: _index,
          theme: t,
          onPick: (i) {
            Navigator.pop(sheetContext);
            _jumpTo(i);
          },
        ),
      ),
    );
  }

  void _showSettings() {
    final tr = L.of(context)!;
    final t = _readerThemes[_themeIndex];
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.18),
      builder: (sheetContext) => GlassSheet(
        child: StatefulBuilder(
          builder: (context, setSheet) {
            final total = _chapters.length;
            final done = _cachedCount >= total && total > 0;
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          tr.fontSize,
                          style: TextStyle(fontSize: 13, color: t.dim),
                        ),
                        const Spacer(),
                        _stepButton(t, 'A-', () {
                          setSheet(() {});
                          setState(
                            () => _fontSize = (_fontSize - 1).clamp(14, 28),
                          );
                          _saveReader();
                        }),
                        SizedBox(
                          width: 46,
                          child: Text(
                            _fontSize.toStringAsFixed(0),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: t.text),
                          ),
                        ),
                        _stepButton(t, 'A+', () {
                          setSheet(() {});
                          setState(
                            () => _fontSize = (_fontSize + 1).clamp(14, 28),
                          );
                          _saveReader();
                        }),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Text(
                          L.of(context)!.lineHeight,
                          style: TextStyle(fontSize: 13, color: t.dim),
                        ),
                        const Spacer(),
                        _stepButton(t, '−', () {
                          setSheet(() {});
                          setState(
                            () => _lineHeight = (_lineHeight - 0.05).clamp(
                              1.30,
                              2.60,
                            ),
                          );
                          _saveReader();
                        }),
                        SizedBox(
                          width: 46,
                          child: Text(
                            _lineHeight.toStringAsFixed(2),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, color: t.text),
                          ),
                        ),
                        _stepButton(t, '+', () {
                          setSheet(() {});
                          setState(
                            () => _lineHeight = (_lineHeight + 0.05).clamp(
                              1.30,
                              2.60,
                            ),
                          );
                          _saveReader();
                        }),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Text(
                          tr.pageTurn,
                          style: TextStyle(fontSize: 13, color: t.dim),
                        ),
                        const Spacer(),
                        _actionButton(
                          t,
                          _pagedMode ? tr.pageLeftRight : tr.pageScroll,
                          () {
                            setState(() => _pagedMode = !_pagedMode);
                            _saveReader();
                            Navigator.pop(sheetContext);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Text(
                          tr.cache,
                          style: TextStyle(fontSize: 13, color: t.dim),
                        ),
                        const Spacer(),
                        Text(
                          done
                              ? tr.cachedAll(total)
                              : tr.cachedProgress(_cachedCount, total),
                          style: TextStyle(fontSize: 11.5, color: t.dim),
                        ),
                        const SizedBox(width: 10),
                        _actionButton(
                          t,
                          done ? tr.alreadyOffline : tr.cacheWholeBook,
                          done ? null : _cacheAll,
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Text(
                          tr.bgColor,
                          style: TextStyle(fontSize: 13, color: t.dim),
                        ),
                        const Spacer(),
                        for (var i = 0; i < _readerThemes.length; i++) ...[
                          GestureDetector(
                            onTap: () {
                              setSheet(() {});
                              setState(() => _themeIndex = i);
                              _saveReader();
                              Navigator.pop(sheetContext);
                            },
                            child: Container(
                              margin: const EdgeInsets.only(left: 12),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _readerThemes[i].bg,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: i == _themeIndex
                                      ? _readerThemes[i].accent
                                      : t.dim.withValues(alpha: 0.35),
                                  width: i == _themeIndex ? 2 : 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 阅读偏好落盘：字号 / 行距 / 翻页 / 底色，下次开书直接还原
  void _saveReader() {
    _store.saveReaderPrefs({
      'font': _fontSize,
      'line': double.parse(_lineHeight.toStringAsFixed(2)),
      'paged': _pagedMode,
      'theme': _themeIndex,
    });
  }

  Widget _stepButton(_ReaderTheme t, String label, VoidCallback onTap) {
    final tr = L.of(context)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 34,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.dim.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, color: t.text)),
      ),
    );
  }
}

/// 目录面板：带搜索，长书里能直接定位
class _CatalogSheet extends StatefulWidget {
  const _CatalogSheet({
    required this.chapters,
    required this.currentIndex,
    required this.theme,
    required this.onPick,
  });

  final List<Episode> chapters;
  final int currentIndex;
  final _ReaderTheme theme;
  final ValueChanged<int> onPick;

  @override
  State<_CatalogSheet> createState() => _CatalogSheetState();
}

class _CatalogSheetState extends State<_CatalogSheet> {
  final _query = TextEditingController();
  late List<int> _hits = List.generate(widget.chapters.length, (i) => i);

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  void _search(String raw) {
    final k = raw.trim();
    setState(() {
      _hits = k.isEmpty
          ? List.generate(widget.chapters.length, (i) => i)
          : [
              for (var i = 0; i < widget.chapters.length; i++)
                if (widget.chapters[i].name.contains(k)) i,
            ];
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = L.of(context)!;
    final t = widget.theme;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.72,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
            child: Row(
              children: [
                Text(
                  tr.catalog,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: t.text,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  tr.chapterCount(widget.chapters.length),
                  style: TextStyle(fontSize: 12, color: t.dim),
                ),
                const Spacer(),
                Text(
                  tr.currentChapter(widget.currentIndex + 1),
                  style: TextStyle(fontSize: 12, color: t.dim),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: t.dim.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_rounded, size: 17, color: t.dim),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _query,
                      onChanged: _search,
                      style: TextStyle(fontSize: 13.5, color: t.text),
                      cursorColor: t.accent,
                      decoration: InputDecoration(
                        isDense: true,
                        filled: false,
                        border: InputBorder.none,
                        hintText: tr.searchChapter,
                        hintStyle: TextStyle(fontSize: 13.5, color: t.dim),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  if (_query.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _query.clear();
                        _search('');
                      },
                      child: Icon(Icons.close_rounded, size: 16, color: t.dim),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _hits.isEmpty
                ? Center(
                    child: Text(
                      tr.noMatchingChapter,
                      style: TextStyle(fontSize: 13, color: t.dim),
                    ),
                  )
                : ListView.builder(
                    controller: ScrollController(
                      initialScrollOffset:
                          (_hits.indexOf(widget.currentIndex) * 46.0 - 120)
                              .clamp(0, double.infinity),
                    ),
                    itemCount: _hits.length,
                    itemBuilder: (_, n) {
                      final i = _hits[n];
                      final active = i == widget.currentIndex;
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => widget.onPick(i),
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          alignment: Alignment.centerLeft,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.chapters[i].name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    color: active ? t.accent : t.text,
                                    fontWeight: active
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                  ),
                                ),
                              ),
                              if (active)
                                Icon(
                                  Icons.play_arrow_rounded,
                                  size: 15,
                                  color: t.accent,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: MediaQuery.paddingOf(context).bottom),
        ],
      ),
    );
  }
}
