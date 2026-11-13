import 'dart:async';

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
import '../widgets/app_background.dart';
import '../widgets/glass.dart';
import '../widgets/pressable.dart';
import 'browse_page.dart';
import 'detail_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    required this.keyword,
    this.kind = SourceKind.video,
  });

  final String keyword;

  /// 只搜这个类型的源：追剧搜视频源，看书搜小说源
  final SourceKind kind;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _engine = SourceRuleEngine();
  final _input = TextEditingController();

  late String _keyword;
  bool _loading = false;
  List<SourceSearchResult> _results = const [];

  @override
  void initState() {
    super.initState();
    _keyword = widget.keyword;
    _input.text = _keyword;
    if (_keyword.trim().isNotEmpty) {
      _loading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _run(_keyword));
    }
  }

  @override
  void dispose() {
    _engine.dispose();
    _input.dispose();
    super.dispose();
  }

  Future<void> _run(String kw) async {
    final k = kw.trim();
    if (k.isEmpty) return;
    final store = context.read<AppStore>();
    final sources = store.enabledSources
        .where((s) => s.kind == widget.kind)
        .toList(growable: false);
    setState(() {
      _keyword = k;
      _loading = true;
      _results = const [];
    });
    unawaited(store.addHistory(widget.kind, k));
    final results = await _engine.searchAll(sources, k);
    if (!mounted) return;
    setState(() {
      _results = results;
      _loading = false;
    });
  }

  List<MediaSource> get _activeSources => context
      .read<AppStore>()
      .enabledSources
      .where((s) => s.kind == widget.kind)
      .toList(growable: false);

  /// 当前类型里第一个配了浏览规则的启用源
  MediaSource? get _browsable {
    for (final s in _activeSources) {
      if (s.browse != null) return s;
    }
    return null;
  }

  int get _totalHits => _results.fold(0, (sum, r) => sum + r.items.length);
  int get _failedCount => _results.where((r) => r.failed).length;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    final isNovel = widget.kind == SourceKind.novel;
    final topPad = MediaQuery.paddingOf(context).top + kToolbarHeight;

    return AppBackground(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          titleSpacing: 0,
          title: _SearchField(
            controller: _input,
            onSubmit: _run,
            hint: isNovel ? t.searchBookHint : t.searchVideoHint,
          ),
          actions: [
            if (_browsable != null)
              IconButton(
                tooltip: t.browseHint2,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BrowsePage(source: _browsable!),
                  ),
                ),
                icon: const Icon(Icons.grid_view_rounded, size: 20),
              ),
            IconButton(
              onPressed: () => _run(_keyword),
              icon: const Icon(Icons.refresh_rounded, size: 21),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: _loading
            ? Padding(
                padding: EdgeInsets.only(top: topPad),
                child: _LoadingView(),
              )
            : _keyword.trim().isEmpty
            ? _HistoryView(
                history: context.watch<AppStore>().historyFor(widget.kind),
                onTap: (kw) {
                  _input.text = kw;
                  _run(kw);
                },
                onClear: () =>
                    context.read<AppStore>().clearHistory(widget.kind),
                emptyText: isNovel ? t.searchNovelHint : t.searchVideoHint,
              )
            : _results.isEmpty
            ? Padding(
                padding: EdgeInsets.only(top: topPad),
                child: _EmptyView(
                  text: _activeSources.isEmpty
                      ? (isNovel
                            ? t.noUsableNovelSource
                            : t.noUsableVideoSource)
                      : t.noResultFor(_keyword),
                  hint: _activeSources.isEmpty
                      ? (isNovel ? t.addNovelSourceHint : t.addVideoSourceHint)
                      : t.tryAnotherKeyword,
                ),
              )
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: SizedBox(height: topPad)),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                      child: Text(
                        _failedCount == 0
                            ? t.resultsSummary(_totalHits, _results.length)
                            : t.resultsSummaryFailed(_failedCount, _totalHits),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ),
                  ),
                  for (final r in _results) ...[
                    SliverToBoxAdapter(child: _SectionHeader(result: r)),
                    if (r.failed)
                      SliverToBoxAdapter(child: _ErrorRow(text: r.error!))
                    else if (r.items.isEmpty)
                      SliverToBoxAdapter(
                        child: _ErrorRow(text: t.searchNoResult),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 11,
                                childAspectRatio: 0.5,
                              ),
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _ResultCard(item: r.items[i]),
                            childCount: r.items.length,
                          ),
                        ),
                      ),
                  ],
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onSubmit,
    required this.hint,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: SizedBox(
        height: 38,
        child: TextField(
          controller: controller,
          textInputAction: TextInputAction.search,
          onSubmitted: onSubmit,
          style: TextStyle(fontSize: 14.5, color: AppColors.textPrimary),
          cursorColor: AppColors.primary,
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surfaceHigh,
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(fontSize: 14.5, color: AppColors.textTertiary),
            prefixIcon: Icon(
              Icons.search_rounded,
              size: 19,
              color: AppColors.textTertiary,
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 38),
            contentPadding: const EdgeInsets.symmetric(vertical: 9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(11),
              borderSide: BorderSide(color: AppColors.primary, width: 1.2),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.result});

  final SourceSearchResult result;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 13,
            decoration: BoxDecoration(
              color: result.failed ? AppColors.textTertiary : AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            result.source.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          Text(
            result.failed ? t.failed : t.resultItemCount(result.items.length),
            style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          gradient: kCardGradient,
          borderRadius: BorderRadius.circular(12),
          border: kSoftBorder,
        ),
        child: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textTertiary,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.item});

  final SearchResult item;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () {
        HapticFeedback.selectionClick();
        final store = context.read<AppStore>();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailPage(
              source: store.sources.firstWhere(
                (s) => s.id == item.sourceId,
                orElse: () => store.sources.first,
              ),
              pageUrl: item.url,
              fallbackTitle: item.title,
              fallbackCover: item.cover,
            ),
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: _Cover(
                url: item.cover,
                isNovel: item.kind == SourceKind.novel,
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            item.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.35,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (item.remark != null) ...[
            const SizedBox(height: 3),
            Text(
              item.remark!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
            ),
          ],
        ],
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.url, this.isNovel = false});

  final String? url;
  final bool isNovel;

  @override
  Widget build(BuildContext context) {
    final fallback = _CoverPlaceholder(isNovel: isNovel);
    if (url == null || url!.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      width: double.infinity,
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({this.isNovel = false});

  final bool isNovel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      child: Icon(
        isNovel ? Icons.auto_stories_outlined : Icons.movie_outlined,
        size: 22,
        color: AppColors.textTertiary,
      ),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView({
    required this.history,
    required this.onTap,
    required this.onClear,
    required this.emptyText,
  });

  final List<String> history;
  final ValueChanged<String> onTap;
  final VoidCallback onClear;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    if (history.isEmpty) {
      return _EmptyView(text: emptyText, hint: t.pressEnterToSearch);
    }
    return ListView(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.paddingOf(context).top + kToolbarHeight + 12,
        20,
        40,
      ),
      children: [
        Row(
          children: [
            Text(
              t.recentSearches,
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onClear,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  t.clearAll,
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 9,
          runSpacing: 9,
          children: [
            for (final kw in history)
              GestureDetector(
                onTap: () => onTap(kw),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: kCardGradient,
                    borderRadius: BorderRadius.circular(14),
                    border: kSoftBorder,
                  ),
                  child: Text(
                    kw,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            t.searchingAll,
            style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.text, required this.hint});

  final String text;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 34,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 14),
          Text(
            text,
            style: TextStyle(fontSize: 14.5, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            hint,
            style: TextStyle(fontSize: 12.5, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
