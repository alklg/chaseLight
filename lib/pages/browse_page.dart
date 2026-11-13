import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/drama.dart';
import '../models/media_source.dart';
import '../services/rule_engine.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../utils/error_text.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card.dart';
import '../widgets/kind_pill.dart';
import 'detail_page.dart';

/// 单源浏览：挑个分类，一直往下翻。
class BrowsePage extends StatefulWidget {
  const BrowsePage({super.key, required this.source});

  final MediaSource source;

  @override
  State<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends State<BrowsePage> {
  final _engine = SourceRuleEngine();
  final _items = <SearchResult>[];

  late BrowseCategory? _category;
  String? _next;
  bool _loading = false;
  bool _end = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final cats = widget.source.browse?.categories ?? const [];
    _category = cats.isEmpty ? null : cats.first;
    if (_category == null) {
      _error = null; // initState 里没有 L，先留空，build 时统一处理
    } else {
      _load(reset: true);
    }
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  Future<void> _load({bool reset = false}) async {
    final t = L.of(context)!;
    if (_loading) return;
    final url = reset ? _category?.url : _next;
    if (url == null) return;

    setState(() {
      _loading = true;
      if (reset) {
        _items.clear();
        _end = false;
        _error = null;
      }
    });

    try {
      final r = await _engine.browse(widget.source, url);
      if (!mounted) return;
      setState(() {
        _items.addAll(r.items);
        _next = r.next;
        _end = r.next == null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = srcErrText(e, L.of(context)!);
        _loading = false;
        _end = true;
      });
    }
  }

  void _pickCategory(BrowseCategory c) {
    final t = L.of(context)!;
    if (_category?.url == c.url) return;
    setState(() => _category = c);
    _load(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    final cats = widget.source.browse?.categories ?? const [];

    return AppBackground(
      child: Scaffold(
        appBar: AppBar(title: Text(widget.source.name)),
        body: Column(
          children: [
            if (cats.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: SizedBox(
                  height: 30,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: cats.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 7),
                    itemBuilder: (_, i) => KindPill(
                      label: cats[i].name,
                      icon: Icons.folder_outlined,
                      active: _category?.url == cats[i].url,
                      dense: true,
                      onTap: () => _pickCategory(cats[i]),
                    ),
                  ),
                ),
              ),
            Expanded(child: _list()),
          ],
        ),
      ),
    );
  }

  Widget _list() {
    final t = L.of(context)!;
    if (_items.isEmpty && _loading) {
      return Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.primary,
          ),
        ),
      );
    }
    if (_items.isEmpty && _error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => _load(reset: true),
                child: Text(
                  t.retry,
                  style: TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Text(
          t.noCategoryContent,
          style: TextStyle(fontSize: 13, color: AppColors.textTertiary),
        ),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n.metrics.pixels > n.metrics.maxScrollExtent - 420 &&
            !_loading &&
            !_end) {
          _load();
        }
        return false;
      },
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 2, 20, 40),
        itemCount: _items.length + 1,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          if (i == _items.length) return _footer();
          return _tile(_items[i]);
        },
      ),
    );
  }

  Widget _footer() {
    final t = L.of(context)!;
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text(
            _error!,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ),
      );
    }
    if (_end) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Center(
          child: Text(
            t.reachEnd,
            style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 1.8,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _tile(SearchResult item) {
    final t = L.of(context)!;
    return AppCard(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DetailPage(
              source: widget.source,
              pageUrl: item.url,
              fallbackTitle: item.title,
              fallbackCover: item.cover,
            ),
          ),
        );
      },
      padding: const EdgeInsets.fromLTRB(14, 13, 12, 13),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (item.remark != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.remark!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
