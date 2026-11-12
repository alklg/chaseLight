import '../models/drama.dart';
import '../models/media_source.dart';
import 'supabase_service.dart';

/// 收藏与进度的云同步。
///
/// 设计原则：**静默失败**。没登录、没网、表没建，一律吞掉异常——
/// 本地数据永远是主数据，云端只是副本。同步坏了不能让 App 用不了。
class SyncService {
  static bool get _ready =>
      SupabaseService.available && SupabaseService.signedIn;

  static String? get _uid => SupabaseService.user?.id;

  /// 更新资料。只推传进来的字段，没传的不动。
  static Future<void> pushProfile({
    String? nickname,
    String? signature,
    int? gender,
  }) async {
    if (!_ready) return;
    try {
      await SupabaseService.client.from('profiles').upsert({
        'id': _uid,
        if (nickname != null) 'nickname': nickname.trim(),
        if (signature != null) 'signature': signature.trim(),
        if (gender != null) 'gender': gender,
      });
    } catch (_) {}
  }

  // ---------------- 收藏 ----------------

  static Future<void> pushFavorite(FavoriteItem f) async {
    if (!_ready) return;
    try {
      await SupabaseService.client.from('favorites').upsert({
        'user_id': _uid,
        'source_id': f.sourceId,
        'source_name': f.sourceName,
        'title': f.title,
        'detail_url': f.detailUrl,
        'cover': f.cover,
        'kind': f.kind == SourceKind.novel ? 'novel' : 'video',
      }, onConflict: 'user_id,source_id,detail_url');
    } catch (_) {
      // 静默：表没建、没网、权限不足都走这里
    }
  }

  static Future<void> removeFavorite(FavoriteItem f) async {
    if (!_ready) return;
    try {
      await SupabaseService.client
          .from('favorites')
          .delete()
          .eq('user_id', _uid!)
          .eq('source_id', f.sourceId)
          .eq('detail_url', f.detailUrl);
    } catch (_) {}
  }

  static Future<List<FavoriteItem>> pullFavorites() async {
    if (!_ready) return const [];
    try {
      final rows = await SupabaseService.client
          .from('favorites')
          .select()
          .eq('user_id', _uid!)
          .order('created_at', ascending: false);
      return [
        for (final r in rows as List)
          FavoriteItem(
            sourceId: r['source_id'] as String? ?? '',
            sourceName: r['source_name'] as String? ?? '',
            title: r['title'] as String? ?? '',
            detailUrl: r['detail_url'] as String? ?? '',
            cover: r['cover'] as String?,
            kind: (r['kind'] as String?) == 'novel'
                ? SourceKind.novel
                : SourceKind.video,
            addedAt:
                DateTime.tryParse(r['created_at'] as String? ?? '') ??
                DateTime.now(),
          ),
      ];
    } catch (_) {
      return const [];
    }
  }

  // ---------------- 进度 ----------------

  static Future<void> pushProgress(WatchRecord r) async {
    if (!_ready) return;
    try {
      await SupabaseService.client.from('progress').upsert({
        'user_id': _uid,
        'source_id': r.sourceId,
        'detail_url': r.detailUrl,
        'title': r.title,
        'cover': r.cover,
        'kind': r.kind == SourceKind.novel ? 'novel' : 'video',
        'total_episodes': r.totalEpisodes,
        'chapter_index': r.chapterIndex,
        'episode_name': r.episodeName,
        'episode_url': r.episodeUrl,
        'updated_at': r.updatedAt.toIso8601String(),
      }, onConflict: 'user_id,source_id,detail_url');
    } catch (_) {}
  }

  static Future<List<WatchRecord>> pullProgress() async {
    if (!_ready) return const [];
    try {
      final rows = await SupabaseService.client
          .from('progress')
          .select()
          .eq('user_id', _uid!)
          .order('updated_at', ascending: false);
      return [
        for (final r in rows as List)
          WatchRecord(
            sourceId: r['source_id'] as String? ?? '',
            sourceName: '',
            title: r['title'] as String? ?? '',
            detailUrl: r['detail_url'] as String? ?? '',
            cover: r['cover'] as String?,
            kind: (r['kind'] as String?) == 'novel'
                ? SourceKind.novel
                : SourceKind.video,
            totalEpisodes: (r['total_episodes'] as num?)?.toInt() ?? 0,
            chapterIndex: (r['chapter_index'] as num?)?.toInt() ?? 0,
            episodeName: r['episode_name'] as String?,
            episodeUrl: r['episode_url'] as String?,
            updatedAt:
                DateTime.tryParse(r['updated_at'] as String? ?? '') ??
                DateTime.now(),
          ),
      ];
    } catch (_) {
      return const [];
    }
  }
}
