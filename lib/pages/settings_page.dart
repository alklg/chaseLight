import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
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
        appBar: AppBar(
          title: const Text('设置'),
          backgroundColor: Colors.transparent,
          flexibleSpace: GlassBackdrop(),
        ),
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

/// 壁纸设置
void _showWallpaper(BuildContext context, AppStore store) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.22),
    builder: (_) => GlassSheet(child: _WallpaperSheet(store: store)),
  );
}

class _WallpaperSheet extends StatefulWidget {
  const _WallpaperSheet({required this.store});

  final AppStore store;

  @override
  State<_WallpaperSheet> createState() => _WallpaperSheetState();
}

class _WallpaperSheetState extends State<_WallpaperSheet> {
  bool _busy = false;

  Future<void> _pick() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 2400,
        imageQuality: 90,
      );
      if (picked == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      // 拷到自己的目录，相册权限变了也不影响
      final dir = await getApplicationDocumentsDirectory();
      final target = File('${dir.path}/wallpaper.jpg');
      await File(picked.path).copy(target.path);
      await widget.store.setWallpaper(target.path);
      if (!mounted) return;
      setState(() => _busy = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('选图失败：$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final has = store.wallpaper != null;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  '壁纸',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (has)
                  GestureDetector(
                    onTap: () async {
                      await store.setWallpaper(null);
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: Text(
                      '恢复默认',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (has) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(store.wallpaper!),
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox(),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    '压暗',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: store.wallpaperDim,
                      max: 0.8,
                      activeColor: AppColors.primary,
                      onChanged: (v) => store.setWallpaperDim(v),
                    ),
                  ),
                  Text(
                    '${(store.wallpaperDim * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '压暗保证文字看得清。浅色模式盖白、深色模式盖黑，都不会把图弄脏。',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.6,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 18),
            ] else
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: Text(
                  '选一张图当 App 背景。卡片会透出一点壁纸的颜色，阅读器和播放器不受影响。',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.7,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            FilledButton(
              onPressed: _busy ? null : _pick,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _busy ? '处理中…' : (has ? '换一张' : '从相册选择'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
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
