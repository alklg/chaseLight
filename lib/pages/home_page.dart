import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/drama.dart';
import '../models/media_source.dart';
import '../services/store.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/watch_text.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card.dart';
import '../widgets/solar_icon.dart';
import '../widgets/kind_pill.dart';
import '../widgets/pressable.dart';
import '../widgets/weather_bar.dart';
import 'detail_page.dart';
import 'profile_page.dart';
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
    final t = L.of(context)!;
    if (_kind == kind) return;
    setState(() => _kind = kind);
    _page.animateToPage(
      kind == SourceKind.video ? 0 : 1,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  void _gotoEpisode(WatchRecord record) {
    final t = L.of(context)!;
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
            record.kind == SourceKind.novel
                ? t.sourceDeletedBook
                : t.sourceDeletedVideo,
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
    final t = L.of(context)!;
    final store = context.watch<AppStore>();
    final sources = store.sources.where((s) => s.kind == _kind).toList();
    final hasSource = sources.any((s) => s.enabled);

    return AppBackground(
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 20,
          title: _TitleBar(sourceCount: sources.where((s) => s.enabled).length),
          actions: [
            // 交友卡片：头像入口，在设置左边
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              ),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Container(
                  width: 29,
                  height: 29,
                  decoration: BoxDecoration(
                    color: store.currentUser?.color ?? AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    store.currentUser?.initial ?? '·',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            IconButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              ),
              icon: Icon(
                Icons.settings_outlined,
                size: 21,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              WeatherBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                child: Row(
                  children: [
                    KindPill(
                      label: t.tabVideo,
                      icon: Icons.play_circle_outline_rounded,
                      active: _kind == SourceKind.video,
                      dense: true,
                      onTap: () => _select(SourceKind.video),
                    ),
                    const SizedBox(width: 7),
                    KindPill(
                      label: t.tabNovel,
                      icon: Icons.menu_book_outlined,
                      active: _kind == SourceKind.novel,
                      dense: true,
                      onTap: () => _select(SourceKind.novel),
                    ),
                  ],
                ),
              ),
              // tab 下面这块二选一：没源就导入，有源就搜索
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: hasSource
                    ? _SearchBox(
                        hint: _kind == SourceKind.novel
                            ? t.searchNovelHint
                            : t.searchVideoHint,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                SearchPage(keyword: '', kind: _kind),
                          ),
                        ),
                      )
                    : _SetupCard(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SourcesPage(),
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
    final t = L.of(context)!;
    final store = context.watch<AppStore>();

    final favs = store.favorites.where((f) => f.kind == kind).toList();
    final favKeys = favs.map((f) => f.key).toSet();
    final watches = store.watchList.where((w) => w.kind == kind).toList();

    // 收藏的排前面；读过但没收的跟在后面，避免重复
    final list = <WatchRecord>[
      for (final f in favs)
        watches.firstWhere(
          (w) => w.key == f.key,
          orElse: () => _placeholder(f),
        ),
      for (final w in watches)
        if (!favKeys.contains(w.key)) w,
    ];

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 26, 20, 10),
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
                  kind == SourceKind.novel ? t.shelf : t.watching,
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

/// 收藏了但还没开始看的，造一条空记录好复用卡片
WatchRecord _placeholder(FavoriteItem f) => WatchRecord(
  sourceId: f.sourceId,
  sourceName: f.sourceName,
  title: f.title,
  detailUrl: f.detailUrl,
  cover: f.cover,
  kind: f.kind,
  totalEpisodes: 0,
  chapterIndex: 0,
  updatedAt: f.addedAt,
);

class _TitleBar extends StatelessWidget {
  const _TitleBar({required this.sourceCount});

  final int sourceCount;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          t.appName,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: Text(
            sourceCount == 0
                ? t.noSourceConfigured
                : t.sourcesOnline(sourceCount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
          ),
        ),
      ],
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.onTap, this.hint});

  final VoidCallback onTap;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    // 和导入卡共用 AppCard，宽度和阴影完全一致
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: 19, color: AppColors.textTertiary),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                hint ?? t.searchVideoHint,
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
    final t = L.of(context)!;
    // 和搜索框同高同宽，视觉上是一个层级
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: SizedBox(
        height: 50,
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(9),
              ),
              child: SolarIcon('import', size: 16, color: AppColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t.setupSource,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.textTertiary,
            ),
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
    final t = L.of(context)!;
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
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              record.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.5,
                                height: 1.35,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (context.watch<AppStore>().isFavorite(
                            record.sourceId,
                            record.detailUrl,
                          ))
                            Padding(
                              padding: const EdgeInsets.only(left: 4, top: 1),
                              child: Icon(
                                Icons.star_rounded,
                                size: 15,
                                color: const Color(0xFFFFC94D),
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        progressLine(record, t),
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
    final t = L.of(context)!;
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
    final t = L.of(context)!;
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
              kind == SourceKind.novel ? t.emptyShelfHint : t.emptyWatchingHint,
              style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
