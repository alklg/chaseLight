import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/drama.dart';
import '../models/media_source.dart';
import '../services/rule_engine.dart';
import '../services/store.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/error_text.dart';
import '../widgets/app_background.dart';
import '../widgets/pressable.dart';
import 'player_page.dart';
import 'reader_page.dart';

class DetailPage extends StatefulWidget {
  const DetailPage({
    super.key,
    required this.source,
    required this.pageUrl,
    this.fallbackTitle,
    this.fallbackCover,
  });

  final MediaSource source;
  final String pageUrl;
  final String? fallbackTitle;
  final String? fallbackCover;

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final _engine = SourceRuleEngine();
  bool _loading = true;
  String? _error;
  DramaDetail? _detail;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final d = await _engine.detail(
        widget.source,
        widget.pageUrl,
        fallbackTitle: widget.fallbackTitle,
        fallbackCover: widget.fallbackCover,
      );
      if (!mounted) return;
      setState(() {
        _detail = d;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = srcErrText(e, L.of(context)!);
        _loading = false;
      });
    }
  }

  WatchRecord? get _record {
    if (_detail == null) return null;
    return context.read<AppStore>().findWatch(widget.source.id, widget.pageUrl);
  }

  void _open(Episode ep) {
    final d = _detail;
    if (d == null) return;
    HapticFeedback.selectionClick();

    if (widget.source.isNovel) {
      var index = d.episodes.indexWhere((e) => e.url == ep.url);
      if (index < 0) index = 0;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ReaderPage(source: widget.source, book: d, startIndex: index),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PlayerPage(source: widget.source, detail: d, episode: ep),
      ),
    );
  }

  Future<void> _toggleFavorite(
    AppStore store,
    String title,
    String? cover,
  ) async {
    final added = await store.toggleFavorite(
      FavoriteItem(
        sourceId: widget.source.id,
        sourceName: widget.source.name,
        title: title,
        detailUrl: widget.pageUrl,
        cover: cover,
        kind: widget.source.kind,
        addedAt: DateTime.now(),
      ),
    );
    if (!mounted) return;
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added ? L.of(context)!.favAdded : L.of(context)!.favRemoved,
        ),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    final store = context.watch<AppStore>();
    final d = _detail;
    final cover = d?.cover ?? widget.fallbackCover;
    final title = d?.title ?? widget.fallbackTitle ?? widget.source.name;
    final record = _record;
    final starred = store.isFavorite(widget.source.id, widget.pageUrl);

    return AppBackground(
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 300,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
              leading: _RoundBack(),
              actions: [
                _StarButton(
                  starred: starred,
                  onTap: () => _toggleFavorite(store, title, cover),
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: _Hero(cover: cover, title: title),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 21,
                        height: 1.3,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          widget.source.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.primary,
                          ),
                        ),
                        if (d != null && d.episodes.isNotEmpty) ...[
                          Text(
                            ' · ',
                            style: TextStyle(color: AppColors.textTertiary),
                          ),
                          Text(
                            widget.source.isNovel
                                ? t.chapterTotal(d.episodes.length)
                                : t.episodeTotal(d.episodes.length),
                            style: TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (d != null && (d.desc?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 14),
                      _ExpandableText(d.desc!),
                    ],
                    if (record != null && record.episodeName != null) ...[
                      const SizedBox(height: 20),
                      _ContinueCard(
                        record: record,
                        isNovel: widget.source.isNovel,
                        onTap: () {
                          final eps = d?.episodes ?? const <Episode>[];
                          var ep = eps.isEmpty
                              ? Episode(
                                  name: record.episodeName!,
                                  url: record.episodeUrl ?? widget.pageUrl,
                                )
                              : eps.firstWhere(
                                  (e) => e.name == record.episodeName,
                                  orElse: () => Episode(
                                    name: record.episodeName!,
                                    url: record.episodeUrl ?? widget.pageUrl,
                                  ),
                                );
                          _open(ep);
                        },
                      ),
                    ],
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            if (_loading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              )
            else if (_error != null)
              SliverToBoxAdapter(
                child: _ErrorBlock(message: _error!, onRetry: _load),
              )
            else if (d != null && d.episodes.isNotEmpty)
              SliverToBoxAdapter(
                child: _EpisodeSection(detail: d, onPlay: _open),
              )
            else if (d != null)
              SliverToBoxAdapter(
                child: _ErrorBlock(
                  message: widget.source.isNovel
                      ? t.noEpisodeList
                      : t.detailNoEpisodes,
                  onRetry: _load,
                  onOpenWeb: widget.source.isNovel
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlayerPage(
                              source: widget.source,
                              detail: d,
                              episode: Episode(
                                name: t.openWeb,
                                url: widget.pageUrl,
                              ),
                              webOnly: true,
                            ),
                          ),
                        ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }
}

class _RoundBack extends StatelessWidget {
  const _RoundBack();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: () => Navigator.maybePop(context),
        behavior: HitTestBehavior.opaque,
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// 收藏星标。只有图标本身，没有圆底
class _StarButton extends StatelessWidget {
  const _StarButton({required this.starred, required this.onTap});

  final bool starred;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Icon(
            starred ? Icons.star_rounded : Icons.star_border_rounded,
            key: ValueKey(starred),
            size: 21,
            color: starred ? const Color(0xFFFFC94D) : Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.cover, required this.title});

  final String? cover;
  final String title;

  @override
  Widget build(BuildContext context) {
    final hasCover = cover != null && cover!.isNotEmpty;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasCover)
          CachedNetworkImage(imageUrl: cover!, fit: BoxFit.cover)
        else
          // 源里没有封面图时不要留一块灰：用书名首字做个纸面底
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.22),
                  AppColors.bg,
                ],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              title.characters.first,
              style: TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w700,
                color: AppColors.primary.withValues(alpha: 0.28),
              ),
            ),
          ),
        if (hasCover) Container(color: Colors.black.withValues(alpha: 0.45)),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, AppColors.bg],
              stops: const [0.35, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class _ExpandableText extends StatefulWidget {
  const _ExpandableText(this.text);

  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Text(
        widget.text,
        maxLines: _expanded ? null : 2,
        overflow: _expanded ? null : TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13,
          height: 1.65,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({
    required this.record,
    required this.isNovel,
    required this.onTap,
  });

  final WatchRecord record;
  final bool isNovel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withValues(
                alpha: AppColors.isDark ? 0.16 : 0.09,
              ),
              AppColors.surface,
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: kCardRadius,
          border: kSoftBorder,
        ),
        child: Row(
          children: [
            Icon(
              Icons.play_circle_fill_rounded,
              color: AppColors.primary,
              size: 30,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${isNovel ? t.continueRead : t.continueWatch} ${record.episodeName}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (isNovel || record.position.inSeconds > 0) ...[
                    const SizedBox(height: 3),
                    Text(
                      isNovel
                          ? t.lastReadChapter(record.chapterIndex + 1)
                          : t.lastWatched(_fmt(record.position)),
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }
}

class _EpisodeSection extends StatefulWidget {
  const _EpisodeSection({required this.detail, required this.onPlay});

  final DramaDetail detail;
  final ValueChanged<Episode> onPlay;

  @override
  State<_EpisodeSection> createState() => _EpisodeSectionState();
}

class _EpisodeSectionState extends State<_EpisodeSection> {
  bool _ascending = true;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    final list = _ascending
        ? [...widget.detail.episodes]
        : widget.detail.episodes.reversed.toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                widget.detail.source.isNovel ? t.catalog : t.episodes,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${list.length}',
                style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => setState(() => _ascending = !_ascending),
                icon: Icon(
                  Icons.sort_rounded,
                  size: 16,
                  color: AppColors.textTertiary,
                ),
                label: Text(
                  _ascending ? t.ascending : t.descending,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textTertiary,
                  ),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 9,
            runSpacing: 9,
            children: [
              for (final ep in list)
                GestureDetector(
                  onTap: () => widget.onPlay(ep),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 58),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      gradient: kCardGradient,
                      borderRadius: BorderRadius.circular(12),
                      border: kSoftBorder,
                    ),
                    child: Text(
                      ep.name,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.message, this.onRetry, this.onOpenWeb});

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenWeb;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: kCardGradient,
          borderRadius: kCardRadius,
          border: kSoftBorder,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.6,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (onRetry != null)
                  TextButton(
                    onPressed: onRetry,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(t.retry, style: TextStyle(fontSize: 13)),
                  ),
                if (onOpenWeb != null) ...[
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: onOpenWeb,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      t.openWebDirect,
                      style: TextStyle(fontSize: 13, color: AppColors.primary),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
