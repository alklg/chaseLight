import 'package:flutter/cupertino.dart' show CupertinoSwitch;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/media_source.dart';
import '../services/source_presets.dart';
import '../services/store.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/glass.dart';
import '../widgets/ios_dialog.dart';
import '../widgets/kind_pill.dart';

const kSourceTemplate = r'''
{
  "name": "示例源",
  "baseUrl": "https://example.com",
  "searchUrl": "/index.php/vod/search.html?wd={kw}",
  "search": {
    "list": ".module-search-item",
    "name": "h3 a@text",
    "link": "h3 a@href",
    "cover": "img@data-original",
    "remark": ".module-item-text@text"
  },
  "detail": {
    "title": "h1@text",
    "cover": ".module-item-pic img@data-original",
    "desc": ".module-info-content@text",
    "episodes": ".module-play-list-link",
    "episodeName": "@text",
    "episodeLink": "@href"
  },
  "play": { "type": "web" }
}
''';

class SourcesPage extends StatefulWidget {
  const SourcesPage({super.key});

  @override
  State<SourcesPage> createState() => _SourcesPageState();
}

class _SourcesPageState extends State<SourcesPage> {
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

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    final store = context.watch<AppStore>();
    final all = store.sources;
    final videoCount = all.where((s) => !s.isNovel).length;
    final novelCount = all.where((s) => s.isNovel).length;

    return AppBackground(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(t.sourceTitle),
          actions: [
            if (all.isNotEmpty)
              IconButton(
                tooltip: t.exportAll,
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: store.exportSources()),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(t.copiedToClipboard)),
                    );
                  }
                },
                icon: const Icon(Icons.ios_share_rounded, size: 20),
              ),
            IconButton(
              tooltip: '导入',
              onPressed: () => _showImportSheet(context, _kind),
              icon: const Icon(Icons.add_rounded, size: 26),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            SizedBox(
              height: MediaQuery.paddingOf(context).top + kToolbarHeight,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
              child: Row(
                children: [
                  KindPill(
                    label: videoCount > 0 ? '追剧 $videoCount' : t.tabVideo,
                    icon: Icons.play_circle_outline_rounded,
                    active: _kind == SourceKind.video,
                    dense: true,
                    onTap: () => _select(SourceKind.video),
                  ),
                  const SizedBox(width: 8),
                  KindPill(
                    label: novelCount > 0 ? '看书 $novelCount' : t.tabNovel,
                    icon: Icons.menu_book_outlined,
                    active: _kind == SourceKind.novel,
                    dense: true,
                    onTap: () => _select(SourceKind.novel),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _page,
                onPageChanged: (i) => setState(
                  () => _kind = i == 0 ? SourceKind.video : SourceKind.novel,
                ),
                children: [
                  _SourceList(
                    kind: SourceKind.video,
                    onAdd: () => _showImportSheet(context, SourceKind.video),
                  ),
                  _SourceList(
                    kind: SourceKind.novel,
                    onAdd: () => _showImportSheet(context, SourceKind.novel),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showImportSheet(BuildContext context, SourceKind kind) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (_) => GlassSheet(child: ImportSourceSheet(initialKind: kind)),
    );
  }
}

/// 单个分类下的源列表
class _SourceList extends StatelessWidget {
  const _SourceList({required this.kind, required this.onAdd});

  final SourceKind kind;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    final store = context.watch<AppStore>();
    final list = store.sources.where((s) => s.kind == kind).toList();

    if (list.isEmpty) {
      return _EmptySources(kind: kind, onAdd: onAdd);
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
      itemCount: list.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        if (i == list.length) return _RulesHint();
        return _SourceTile(source: list[i]);
      },
    );
  }
}

class _SourceTile extends StatelessWidget {
  const _SourceTile({required this.source});

  final MediaSource source;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    final store = context.read<AppStore>();
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        gradient: kCardGradient,
        borderRadius: kCardRadius,
        boxShadow: kSoftShadow,
        border: kSoftBorder,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  source.name,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  Uri.tryParse(source.baseUrl)?.host ?? source.baseUrl,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: source.isNovel
                      ? [
                          _Chip(label: t.kindNovel),
                          _Chip(
                            label: source.detail == null
                                ? t.onlySearch
                                : t.supportCatalog,
                          ),
                        ]
                      : [
                          _Chip(
                            label: source.detail == null
                                ? t.onlySearch
                                : t.supportEpisodes,
                          ),
                          _Chip(
                            label: source.play.isDirect
                                ? t.directPlay
                                : t.webSniff,
                          ),
                        ],
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: source.enabled,
            activeTrackColor: AppColors.primary,
            onChanged: (v) => store.toggleSource(source.id, v),
          ),
          IconButton(
            onPressed: () => _confirmDelete(context, store),
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, AppStore store) async {
    final t = L.of(context)!;
    final ok = await showIosConfirm(
      context,
      title: t.deleteSourceQ,
      message: '「${source.name}」的配置会被移除，观看记录不受影响。',
      confirm: '删除',
      destructive: true,
    );
    if (ok) await store.removeSource(source.id);
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10.5, color: AppColors.textTertiary),
      ),
    );
  }
}

class _EmptySources extends StatelessWidget {
  const _EmptySources({required this.kind, required this.onAdd});

  final SourceKind kind;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 44),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.add_link_rounded,
                size: 36,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              kind == SourceKind.novel ? t.noNovelSource : t.noVideoSource,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '把源配置（JSON）粘进来就能开始搜索。\n影视和小说分开管理，各自独立生效。',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onAdd,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                t.importSource,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RulesHint extends StatelessWidget {
  const _RulesHint();

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.ruleSyntax,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: kCardGradient,
              borderRadius: kCardRadius,
              border: kSoftBorder,
            ),
            child: Text(
              '取值规则统一写成  选择器@属性\n'
              'h1                 取文本\n'
              'a.title@href       取链接\n'
              'img@data-src       取封面\n'
              '@text  /  @href    取条目自身的文本或链接\n\n'
              'play.type 为 web 时，播放页交给内置浏览器嗅探真实视频地址；'
              '为 direct 时用 play.url 从页面里直接抽 m3u8。',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.85,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ImportSourceSheet extends StatefulWidget {
  const ImportSourceSheet({super.key, this.initialKind = SourceKind.video});

  final SourceKind initialKind;

  @override
  State<ImportSourceSheet> createState() => _ImportSourceSheetState();
}

enum _ImportMode { domain, json }

class _ImportSourceSheetState extends State<ImportSourceSheet> {
  final _domain = TextEditingController();
  final _json = TextEditingController();
  _ImportMode _mode = _ImportMode.domain;
  late SourceKind _kind = widget.initialKind;
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _domain.dispose();
    _json.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final store = context.read<AppStore>();
    try {
      if (_mode == _ImportMode.domain) {
        final src = macCmsPreset(_domain.text, kind: _kind);
        await store.addSource(src);
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已添加 ${src.name}')));
      } else {
        final n = await store.importSources(_json.text);
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('已导入 $n 个源')));
      }
    } catch (e) {
      setState(() {
        _error = e is FormatException ? e.message : e.toString();
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final isJson = _mode == _ImportMode.json;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: SizedBox(
        height: isJson ? MediaQuery.sizeOf(context).height * 0.78 : null,
        child: Column(
          mainAxisSize: isJson ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Text(
                t.addSource,
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _Segmented(
                value: _mode,
                onChanged: (m) => setState(() {
                  _mode = m;
                  _error = null;
                }),
              ),
            ),
            if (isJson)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  child: TextField(
                    controller: _json,
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.55,
                      fontFamily: 'Menlo',
                      color: Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: '支持单个对象、数组，或 { "sources": [...] }',
                      contentPadding: const EdgeInsets.all(14),
                      suffixIcon: TextButton(
                        onPressed: () {
                          _json.text = kSourceTemplate;
                          setState(() => _error = null);
                        },
                        child: Text(t.example, style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ),
                ),
              )
            else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    KindPill(
                      label: t.tabVideo,
                      icon: Icons.play_circle_outline_rounded,
                      active: _kind == SourceKind.video,
                      dense: true,
                      onTap: () => setState(() => _kind = SourceKind.video),
                    ),
                    const SizedBox(width: 8),
                    KindPill(
                      label: t.tabNovel,
                      icon: Icons.menu_book_outlined,
                      active: _kind == SourceKind.novel,
                      dense: true,
                      onTap: () => setState(() => _kind = SourceKind.novel),
                    ),
                    const Spacer(),
                    Text(
                      _kind == SourceKind.novel ? t.genReadRule : t.genPlayRule,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: TextField(
                  controller: _domain,
                  autofocus: true,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'abc.com',
                    prefixIcon: Icon(
                      Icons.link_rounded,
                      size: 19,
                      color: Color(0xFF9B9CA5),
                    ),
                    prefixIconConstraints: BoxConstraints(minWidth: 44),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                child: Text(
                  '会按最常见的苹果CMS结构生成搜索、详情和正文规则，加上就能用；'
                  '哪条抓不到，再用「粘 JSON」把导出的配置改掉。',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.7,
                    color: AppColors.textTertiary,
                  ),
                ),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text(
                  _error!,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: AppColors.danger,
                    height: 1.5,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primaryDim,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _busy ? t.processing : (isJson ? '导入' : t.genAndAdd),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.value, required this.onChanged});

  final _ImportMode value;
  final ValueChanged<_ImportMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          _item(t.domainHint, _ImportMode.domain),
          _item('粘 JSON', _ImportMode.json),
        ],
      ),
    );
  }

  Widget _item(String label, _ImportMode mode) {
    final active = value == mode;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: active ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              color: active ? AppColors.textPrimary : AppColors.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}
