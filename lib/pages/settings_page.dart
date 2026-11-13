import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/novel_cache.dart';
import '../services/store.dart';
import '../services/supabase_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card.dart';
import '../widgets/ios_dialog.dart';
import 'account_page.dart';
import 'sources_page.dart';
import 'wallpaper_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _pickLang(BuildContext context, AppStore store) {
    final t = L.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 14),
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _langTile(ctx, store, null, t.langSystem),
              _langTile(ctx, store, 'zh', t.langZh),
              _langTile(ctx, store, 'en', t.langEn),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _langTile(
    BuildContext ctx,
    AppStore store,
    String? code,
    String label,
  ) {
    final active = store.lang == code;
    return GestureDetector(
      onTap: () {
        store.setLang(code);
        Navigator.pop(ctx);
      },
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            const SizedBox(width: 18),
            Text(
              label,
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? AppColors.primary : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            if (active)
              Icon(Icons.check_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 18),
          ],
        ),
      ),
    );
  }

  String _langName(L t, String? code) {
    if (code == 'zh') return t.langZh;
    if (code == 'en') return t.langEn;
    return t.langSystem;
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    final store = context.watch<AppStore>();
    final videoCount = store.sources.where((s) => !s.isNovel).length;
    final novelCount = store.sources.where((s) => s.isNovel).length;

    return AppBackground(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(title: Text(t.settingsTitle)),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top + kToolbarHeight + 4,
            20,
            24 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AccountPage()),
              ),
              behavior: HitTestBehavior.opaque,
              child: AppCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: store.currentUser?.color ?? AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        store.currentUser?.initial ?? '+',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            store.currentUser?.nickname ??
                                SupabaseService.email ??
                                t.account,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            SupabaseService.email ?? t.cloudOffHint,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
            _SectionLabel(t.language),
            _Card(
              children: [
                GestureDetector(
                  onTap: () => _pickLang(context, store),
                  behavior: HitTestBehavior.opaque,
                  child: _Row(
                    title: _langName(t, store.lang),
                    trailing: Icon(
                      Icons.chevron_right_rounded,
                      size: 19,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
            _SectionLabel(t.appearance),
            _Card(
              children: [
                _Row(
                  title: t.wallpaper,
                  subtitle: store.wallpaper != null
                      ? t.galleryImage
                      : (store.wallpaperId != null
                            ? t.builtinWallpaper
                            : t.defaultGlow),
                  trailing: store.wallpaper == null
                      ? null
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(store.wallpaper!),
                            width: 26,
                            height: 26,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const SizedBox(),
                          ),
                        ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const WallpaperPage()),
                  ),
                ),
              ],
            ),
            _SectionLabel(t.sourceTitle),
            _Card(
              children: [
                _Row(
                  title: t.sourceManage,
                  subtitle: store.sources.isEmpty
                      ? t.noSourceImported
                      : '${t.kindVideo} $videoCount · ${t.kindNovel} $novelCount',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SourcesPage()),
                  ),
                ),
              ],
            ),
            _SectionLabel(t.reading),
            _Card(children: [_CacheRow()]),
            _SectionLabel(t.others),
            _Card(
              children: [
                _Row(
                  title: t.clearHistory,
                  subtitle: store.historyCount == 0
                      ? t.noRecord
                      : t.historyCount(store.historyCount),
                  onTap: () async {
                    if (store.historyCount == 0) return;
                    await store.clearHistory();
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(t.historyCleared)));
                    }
                  },
                ),
              ],
            ),
            _SectionLabel(t.about),
            _Card(
              children: [
                _Row(title: t.version, trailing: const Text('1.0.0')),
                _Row(title: t.sourceRules, subtitle: t.sourceRulesHint),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 小说缓存占用与清理
class _CacheRow extends StatefulWidget {
  const _CacheRow();

  @override
  State<_CacheRow> createState() => _CacheRowState();
}

class _CacheRowState extends State<_CacheRow> {
  int? _bytes;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final b = await NovelCache.totalBytes();
    if (mounted) setState(() => _bytes = b);
  }

  String _label(L t) {
    final b = _bytes;
    if (b == null) return t.counting;
    if (b <= 0) return t.noCache;
    if (b < 1024 * 1024) return t.cacheUsedKb('${(b / 1024).ceil()}');
    return t.cacheUsedMb((b / 1024 / 1024).toStringAsFixed(1));
  }

  Future<void> _clear() async {
    final t = L.of(context)!;
    final b = _bytes ?? 0;
    if (b <= 0 || _busy) return;
    final ok = await showIosConfirm(
      context,
      title: t.clearNovelCache,
      message: t.clearNovelCacheBody,
      confirm: t.clear,
      destructive: true,
    );
    if (!ok) return;
    setState(() => _busy = true);
    await NovelCache.clearAll();
    await _load();
    if (!mounted) return;
    setState(() => _busy = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.cacheCleared)));
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return _Row(
      title: t.novelCache,
      subtitle: _busy ? t.clearing : _label(t),
      onTap: _clear,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 26, 0, 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.textTertiary,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: kCardGradient,
        borderRadius: kCardRadius,
        boxShadow: kSoftShadow,
        border: kSoftBorder,
      ),
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              Divider(
                height: 1,
                indent: 16,
                endIndent: 16,
                color: AppColors.divider,
              ),
            children[i],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.title, this.subtitle, this.trailing, this.onTap});

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = SizedBox(
      height: 62,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 12, 0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            ?trailing,
            if (onTap != null)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );

    if (onTap == null) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}
