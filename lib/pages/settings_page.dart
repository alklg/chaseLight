import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/novel_cache.dart';
import '../services/store.dart';
import '../theme/accents.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/glass.dart';
import '../widgets/ios_dialog.dart';
import '../widgets/theme_toggle.dart';
import 'sources_page.dart';
import 'wallpaper_page.dart';
import 'theme_color_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final videoCount = store.sources.where((s) => !s.isNovel).length;
    final novelCount = store.sources.where((s) => s.isNovel).length;
    final accent = kAccents[store.accent.clamp(0, kAccents.length - 1)];

    return AppBackground(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(title: const Text('设置')),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top + kToolbarHeight + 4,
            20,
            40,
          ),
          children: [
            _SectionLabel('外观'),
            _Card(
              children: [
                _Row(
                  title: '深色模式',
                  subtitle: store.darkMode ? '当前是深色' : '当前是浅色',
                  trailing: ThemeToggle(
                    dark: store.darkMode,
                    onChanged: (v) => store.setDarkMode(v),
                  ),
                ),
                _Row(
                  title: '主题色',
                  subtitle: accent.name,
                  trailing: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: accent.color(store.darkMode),
                      shape: BoxShape.circle,
                    ),
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ThemeColorPage()),
                  ),
                ),
                _Row(
                  title: '壁纸',
                  subtitle: store.wallpaper != null
                      ? '相册图片'
                      : (store.wallpaperId != null ? '内置壁纸' : '默认光晕'),
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
            _SectionLabel('内容源'),
            _Card(
              children: [
                _Row(
                  title: '源管理',
                  subtitle: store.sources.isEmpty
                      ? '还没有导入'
                      : '影视 $videoCount · 小说 $novelCount',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SourcesPage()),
                  ),
                ),
              ],
            ),
            _SectionLabel('阅读'),
            _Card(children: [_CacheRow()]),
            _SectionLabel('其他'),
            _Card(
              children: [
                _Row(
                  title: '清除搜索历史',
                  subtitle: store.history.isEmpty
                      ? '没有记录'
                      : '${store.history.length} 条',
                  onTap: () async {
                    if (store.history.isEmpty) return;
                    await store.clearHistory();
                    if (context.mounted) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('搜索历史已清空')));
                    }
                  },
                ),
              ],
            ),
            _SectionLabel('关于'),
            _Card(
              children: [
                _Row(title: '版本', trailing: const Text('1.0.0')),
                _Row(title: '源规则', subtitle: '纯 JSON 配置，可导出分享'),
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

  String get _label {
    final b = _bytes;
    if (b == null) return '统计中…';
    if (b <= 0) return '还没有缓存';
    if (b < 1024 * 1024) return '已用 ${(b / 1024).ceil()} KB';
    return '已用 ${(b / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  Future<void> _clear() async {
    final b = _bytes ?? 0;
    if (b <= 0 || _busy) return;
    final ok = await showIosConfirm(
      context,
      title: '清除小说缓存？',
      message: '缓存的章节全部删掉，阅读进度保留。之后需要重新联网抓。',
      confirm: '清除',
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
    ).showSnackBar(const SnackBar(content: Text('缓存已清除')));
  }

  @override
  Widget build(BuildContext context) {
    return _Row(
      title: '小说缓存',
      subtitle: _busy ? '清理中…' : _label,
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
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 9),
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
    final content = Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
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
    );

    if (onTap == null) return content;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}
