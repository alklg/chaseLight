import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/drama.dart';
import '../models/media_source.dart';
import '../services/store.dart';
import '../theme/app_theme.dart';
import '../utils/watch_text.dart';
import '../widgets/app_background.dart';
import '../widgets/kind_pill.dart';
import '../widgets/pressable.dart';
import 'detail_page.dart';
import 'search_page.dart';
import 'settings_page.dart';
import 'sources_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _page = PageController();
  SourceKind _kind = SourceKind.video;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _select(SourceKind kind) {
    if (_kind == kind) return;
    setState(() => _kind = kind);
    _page.animateToPage(
      kind == SourceKind.video ? 0 : 1,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _gotoEpisode(WatchRecord record) {
    final store = context.read<AppStore>();
    MediaSource? source;
    for (final s in store.sources) {
      if (s.id == record.sourceId) {
        source = s;
        break;
      }
    }
    if (source == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            record.kind == SourceKind.novel ? '这本书的源已经被删掉了' : '这个剧的源已经被删掉了',
          ),
        ),
      );
      return;
    }
    final target = source;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailPage(
          source: target,
          pageUrl: record.detailUrl,
          fallbackTitle: record.title,
          fallbackCover: record.cover,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final sources = store.sources.where((s) => s.kind == _kind).toList();

    return AppBackground(
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _Header(sourceCount: sources.where((s) => s.enabled).length),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 12),
                child: Row(
                  children: [
                    KindPill(
                      label: '追剧',
                      icon: Icons.play_circle_outline_rounded,
                      active: _kind == SourceKind.video,
                      onTap: () => _select(SourceKind.video),
                    ),
                    const SizedBox(width: 8),
                    KindPill(
                      label: '看书',
                      icon: Icons.menu_book_outlined,
                      active: _kind == SourceKind.novel,
                      onTap: () => _select(SourceKind.novel),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _SearchBox(
                  hint: _kind == SourceKind.novel ? '搜书名或作者' : '搜剧名',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SearchPage(keyword: '', kind: _kind),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _page,
                  onPageChanged: (i) => setState(
                    () => _kind = i == 0 ? SourceKind.video : SourceKind.novel,
                  ),
                  children: [
                    _Feed(kind: SourceKind.video, onOpen: _gotoEpisode),
                    _Feed(kind: SourceKind.novel, onOpen: _gotoEpisode),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 单个频道的内容区。PageView 左右各挂一个，互不干扰滚动。
class _Feed extends StatelessWidget {
  const _Feed({required this.kind, required this.onOpen});

  final SourceKind kind;
  final ValueChanged<WatchRecord> onOpen;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final list = store.watchList.where((w) => w.kind == kind).toList();
    final hasSource = store.sources.any((s) => s.kind == kind && s.enabled);

    return CustomScrollView(
      slivers: [
        if (!hasSource)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: _SetupCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SourcesPage()),
                ),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 15,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  kind == SourceKind.novel ? '书架' : '在追',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 8),
                if (list.isNotEmpty)
                  Text(
                    '${list.length}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (list.isEmpty)
          SliverToBoxAdapter(child: _EmptyWatch(kind: kind))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) => _WatchTile(
                record: list[i],
                onTap: () => onOpen(list[i]),
                onRemove: () => store.removeWatch(list[i].key),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.sourceCount});

  final int sourceCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 8, 12),
      child: Row(
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '追光',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 9),
                Flexible(
                  child: Text(
                    sourceCount == 0 ? '未配置源' : '$sourceCount 个源在线',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 40, height: 40),
            icon: Icon(
              Icons.settings_outlined,
              size: 21,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.onTap, this.hint = '搜剧名'});

  final VoidCallback onTap;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          gradient: kCardGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: kSoftShadow,
          border: kSoftBorder,
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 19, color: AppColors.textTertiary),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                hint,
                style: TextStyle(fontSize: 14.5, color: AppColors.textTertiary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SetupCard extends StatelessWidget {
  const _SetupCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: kCardGradient,
          borderRadius: kCardRadius,
          boxShadow: kSoftShadow,
          border: kSoftBorder,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.add_link_rounded,
                size: 19,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '先导入一个内容源',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '粘一份 JSON 配置进来就能搜',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

class _WatchTile extends StatelessWidget {
  const _WatchTile({
    required this.record,
    required this.onTap,
    required this.onRemove,
  });

  final WatchRecord record;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey(record.key),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onRemove(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.danger.withValues(alpha: 0.18),
          borderRadius: kCardRadius,
        ),
        child: Icon(
          Icons.delete_outline_rounded,
          color: AppColors.danger,
          size: 20,
        ),
      ),
      child: Pressable(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            gradient: kCardGradient,
            borderRadius: kCardRadius,
            boxShadow: kSoftShadow,
            border: kSoftBorder,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: SizedBox(
                  width: 58,
                  height: 78,
                  child: _Thumb(
                    url: record.cover,
                    isNovel: record.kind == SourceKind.novel,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 78,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        progressLine(record),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 7),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: record.progress == 0 ? 0.02 : record.progress,
                          minHeight: 3,
                          backgroundColor: AppColors.surfaceHigh,
                          valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.url, this.isNovel = false});

  final String? url;
  final bool isNovel;

  @override
  Widget build(BuildContext context) {
    final placeholder = Container(
      color: AppColors.surfaceHigh,
      alignment: Alignment.center,
      child: Icon(
        isNovel ? Icons.auto_stories_outlined : Icons.movie_outlined,
        size: 18,
        color: AppColors.textTertiary,
      ),
    );
    if (url == null || url!.isEmpty) return placeholder;
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      placeholder: (_, _) => placeholder,
      errorWidget: (_, _, _) => placeholder,
    );
  }
}

class _EmptyWatch extends StatelessWidget {
  const _EmptyWatch({required this.kind});

  final SourceKind kind;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          borderRadius: kCardRadius,
          border: Border.all(color: AppColors.divider, width: 1),
        ),
        child: Column(
          children: [
            Icon(
              kind == SourceKind.novel
                  ? Icons.auto_stories_outlined
                  : Icons.subscriptions_outlined,
              size: 26,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 10),
            Text(
              kind == SourceKind.novel ? '读过的书会记在这里' : '看过的剧会记在这里',
              style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
