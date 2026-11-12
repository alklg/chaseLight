import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/drama.dart';
import '../models/user_account.dart';
import 'sync_service.dart';
import '../models/media_source.dart';
import 'source_presets.dart';

/// 本地持久化：源配置、观看记录、搜索历史、主题。
class AppStore extends ChangeNotifier {
  static const _kSources = 'sources.v1';
  static const _kWatch = 'watch.v1';
  static const _kUsers = 'users.v1';
  static const _kCurrentUser = 'currentUser.v1';
  static const _kFav = 'favorites.v1';
  static const _kHistory = 'history.v1';
  static const _kDark = 'dark.v1';
  static const _kAccent = 'accent.v1';
  static const _kSeeded = 'seeded.v1';
  static const _kCity = 'weatherCity.v1';
  static const _kWall = 'wallpaper.v1';
  static const _kWallId = 'wallpaperId.v1';
  static const _kWallDim = 'wallpaperDim.v1';
  static const _kWallTint = 'wallpaperTint.v1';

  List<MediaSource> _sources = [];
  List<WatchRecord> _watch = [];
  List<FavoriteItem> _favorites = [];
  List<UserAccount> _users = [];
  String? _currentUserId;
  List<String> _history = [];
  bool _darkMode = false;
  int _accent = 0;
  bool _ready = false;
  String _weatherCity = '';
  String? _wallpaper;
  String? _wallpaperId;
  double _wallpaperDim = 0.30;
  int? _wallpaperTint;

  List<MediaSource> get sources => List.unmodifiable(_sources);
  List<MediaSource> get enabledSources =>
      _sources.where((s) => s.enabled).toList(growable: false);
  List<WatchRecord> get watchList => List.unmodifiable(_watch);

  List<FavoriteItem> get favorites => List.unmodifiable(_favorites);

  // ---------- 账号 ----------

  List<UserAccount> get users => List.unmodifiable(_users);

  UserAccount? get currentUser {
    if (_currentUserId == null) return _users.isEmpty ? null : _users.first;
    for (final u in _users) {
      if (u.id == _currentUserId) return u;
    }
    return _users.isEmpty ? null : _users.first;
  }

  Future<UserAccount> createUser(String nickname, int colorValue) async {
    final now = DateTime.now();
    final user = UserAccount(
      id: 'u${now.microsecondsSinceEpoch}',
      nickname: nickname.trim().isEmpty ? '我' : nickname.trim(),
      colorValue: colorValue,
      createdAt: now,
    );
    _users.add(user);
    _currentUserId = user.id;
    notifyListeners();
    await _persistUsers();
    return user;
  }

  Future<void> switchUser(String id) async {
    if (_currentUserId == id) return;
    _currentUserId = id;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrentUser, id);
  }

  Future<void> removeUser(String id) async {
    _users.removeWhere((u) => u.id == id);
    if (_currentUserId == id) {
      _currentUserId = _users.isEmpty ? null : _users.first.id;
    }
    notifyListeners();
    await _persistUsers();
  }

  Future<void> renameUser(String id, String nickname) async {
    final i = _users.indexWhere((u) => u.id == id);
    if (i < 0) return;
    _users[i] = UserAccount(
      id: _users[i].id,
      nickname: nickname.trim().isEmpty ? _users[i].nickname : nickname.trim(),
      colorValue: _users[i].colorValue,
      createdAt: _users[i].createdAt,
    );
    notifyListeners();
    await _persistUsers();
  }

  Future<void> _persistUsers() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kUsers,
      jsonEncode(_users.map((e) => e.toJson()).toList()),
    );
    if (_currentUserId == null) {
      await prefs.remove(_kCurrentUser);
    } else {
      await prefs.setString(_kCurrentUser, _currentUserId!);
    }
  }

  List<String> get history => List.unmodifiable(_history);
  bool get ready => _ready;
  bool get darkMode => _darkMode;

  /// 手动选的天气城市。空字符串表示跟随定位。
  String get weatherCity => _weatherCity;

  /// 自定义壁纸的文件路径（从相册选的）
  String? get wallpaper => _wallpaper;

  /// 内置壁纸的 id；和 wallpaper 二选一
  String? get wallpaperId => _wallpaperId;

  /// 壁纸压暗强度 0~1，越高压得越暗，保证文字可读
  double get wallpaperDim => _wallpaperDim;

  /// 图片壁纸顶部提取的颜色，给顶栏用；内置壁纸用 preset 里的 tint
  Color? get wallpaperTint =>
      _wallpaperTint == null ? null : Color(_wallpaperTint!);

  /// 主题色下标，对应 kAccents
  int get accent => _accent;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool(_kDark) ?? false;
    _accent = prefs.getInt(_kAccent) ?? 0;
    _weatherCity = prefs.getString(_kCity) ?? '';
    // 只存文件名：iOS 每次更新 App，沙盒目录的 UUID 都会变，
    // 存绝对路径的话更新一次壁纸就丢了
    final wallName = prefs.getString(_kWall);
    if (wallName != null && wallName.isNotEmpty) {
      try {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/$wallName');
        _wallpaper = file.existsSync() ? file.path : null;
      } catch (_) {
        _wallpaper = null;
      }
    }
    _wallpaperId = prefs.getString(_kWallId);
    _wallpaperDim = prefs.getDouble(_kWallDim) ?? 0.30;
    _wallpaperTint = prefs.getInt(_kWallTint);
    _sources = _decodeList(prefs.getString(_kSources), MediaSource.fromJson);
    _users = _decodeList(prefs.getString(_kUsers), UserAccount.fromJson);
    _currentUserId = prefs.getString(_kCurrentUser);
    _favorites = _decodeList(prefs.getString(_kFav), FavoriteItem.fromJson);
    _watch = _decodeList(prefs.getString(_kWatch), WatchRecord.fromJson)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final h = prefs.getString(_kHistory);
    if (h != null) {
      try {
        _history = (jsonDecode(h) as List).cast<String>();
      } catch (_) {
        _history = [];
      }
    }

    // 首次启动给一个能直接跑的示例源；删掉之后不会再自动加回来
    if (!(prefs.getBool(_kSeeded) ?? false) && _sources.isEmpty) {
      _sources = [bookSourcePreset];
      await prefs.setString(
        _kSources,
        jsonEncode(_sources.map((e) => e.toJson()).toList()),
      );
      await prefs.setBool(_kSeeded, true);
    }

    // 内置源升级：老数据里没有浏览规则的，补上（不然要用清数据才生效）
    final zdicIndex = _sources.indexWhere((s) => s.id == 'zdic');
    if (zdicIndex >= 0 &&
        _sources[zdicIndex].browse == null &&
        bookSourcePreset.browse != null) {
      _sources[zdicIndex] = _sources[zdicIndex].copyWith(
        browse: bookSourcePreset.browse,
      );
      await prefs.setString(
        _kSources,
        jsonEncode(_sources.map((e) => e.toJson()).toList()),
      );
    }

    _ready = true;
    notifyListeners();
  }

  Future<void> setDarkMode(bool v) async {
    if (_darkMode == v) return;
    _darkMode = v;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDark, v);
  }

  Future<void> setWallpaper(String? path, {Color? tint}) async {
    _wallpaper = path;
    _wallpaperTint = tint?.toARGB32();
    if (path != null) _wallpaperId = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (path == null) {
      await prefs.remove(_kWall);
    } else {
      // 同时兼容老的绝对路径：统一抽成文件名再存
      final name = path.split('/').last;
      await prefs.setString(_kWall, name);
      await prefs.remove(_kWallId);
      if (_wallpaperTint != null) {
        await prefs.setInt(_kWallTint, _wallpaperTint!);
      }
    }
  }

  Future<void> setBuiltinWallpaper(String? id) async {
    _wallpaperId = id;
    if (id != null) _wallpaper = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_kWallId);
    } else {
      await prefs.setString(_kWallId, id);
      await prefs.remove(_kWall);
    }
  }

  Future<void> setWallpaperDim(double v) async {
    _wallpaperDim = v.clamp(0.0, 0.8);
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_kWallDim, _wallpaperDim);
  }

  Future<void> setWeatherCity(String name) async {
    if (_weatherCity == name) return;
    _weatherCity = name;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCity, name);
  }

  Future<void> setAccent(int i) async {
    if (_accent == i) return;
    _accent = i;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kAccent, i);
  }

  static List<T> _decodeList<T>(
    String? raw,
    T Function(Map<String, dynamic>) from,
  ) {
    if (raw == null || raw.isEmpty) return <T>[];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .whereType<Map>()
          .map((e) => from(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('读取本地数据失败: $e');
      return <T>[];
    }
  }

  Future<void> _saveSources() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kSources,
      jsonEncode(_sources.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }

  Future<void> _saveWatch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kWatch,
      jsonEncode(_watch.map((e) => e.toJson()).toList()),
    );
    notifyListeners();
  }

  // ---------- 源 ----------

  /// 支持三种输入形态：单个源对象、源数组、`{ "sources": [...] }`
  Future<int> importSources(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) throw const FormatException('内容为空');
    dynamic decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException catch (e) {
      throw FormatException('JSON 格式错误：${e.message}');
    }
    final rawList = <Map<String, dynamic>>[];
    if (decoded is List) {
      for (final item in decoded) {
        if (item is Map) rawList.add(Map<String, dynamic>.from(item));
      }
    } else if (decoded is Map) {
      final inner = decoded['sources'];
      if (inner is List) {
        for (final item in inner) {
          if (item is Map) rawList.add(Map<String, dynamic>.from(item));
        }
      } else {
        rawList.add(Map<String, dynamic>.from(decoded));
      }
    }
    if (rawList.isEmpty) throw const FormatException('没有找到任何源配置');

    final parsed = <MediaSource>[];
    for (var i = 0; i < rawList.length; i++) {
      try {
        final src = MediaSource.fromJson(rawList[i]);
        parsed.add(
          src.id.isEmpty || _sources.any((s) => s.id == src.id)
              ? _withFreshId(src)
              : src,
        );
      } on FormatException catch (e) {
        throw FormatException('第 ${i + 1} 个源有问题：${e.message}');
      }
    }

    for (final src in parsed) {
      final idx = _sources.indexWhere((s) => s.name == src.name);
      if (idx >= 0) {
        _sources[idx] = src;
      } else {
        _sources.add(src);
      }
    }
    await _saveSources();
    return parsed.length;
  }

  MediaSource _withFreshId(MediaSource src) {
    return MediaSource(
      id: 's_${DateTime.now().microsecondsSinceEpoch}_${_sources.length}',
      name: src.name,
      baseUrl: src.baseUrl,
      searchUrl: src.searchUrl,
      search: src.search,
      kind: src.kind,
      detail: src.detail,
      chapter: src.chapter,
      play: src.play,
      headers: src.headers,
      enabled: src.enabled,
    );
  }

  Future<void> addSource(MediaSource src) async {
    _sources.removeWhere((s) => s.name == src.name);
    _sources.add(src);
    await _saveSources();
  }

  Future<void> removeSource(String id) async {
    _sources.removeWhere((s) => s.id == id);
    await _saveSources();
  }

  Future<void> toggleSource(String id, bool enabled) async {
    final i = _sources.indexWhere((s) => s.id == id);
    if (i < 0) return;
    _sources[i] = _sources[i].copyWith(enabled: enabled);
    await _saveSources();
  }

  String exportSources() => const JsonEncoder.withIndent(
    '  ',
  ).convert(_sources.map((e) => e.toJson()).toList());

  // ---------- 收藏 ----------

  bool isFavorite(String sourceId, String detailUrl) {
    final key = '$sourceId|$detailUrl';
    return _favorites.any((f) => f.key == key);
  }

  Future<bool> toggleFavorite(FavoriteItem item) async {
    final i = _favorites.indexWhere((f) => f.key == item.key);
    final added = i < 0;
    if (added) {
      _favorites.insert(0, item);
    } else {
      _favorites.removeAt(i);
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kFav,
      jsonEncode(_favorites.map((e) => e.toJson()).toList()),
    );
    // 不 await：本地先落盘，云端慢或失败都不影响用
    unawaited(
      added ? SyncService.pushFavorite(item) : SyncService.removeFavorite(item),
    );
    return added;
  }

  /// 登录后调用：把云端的收藏并到本地（同一条只留一份，本地优先）
  Future<void> mergeCloudFavorites() async {
    final cloud = await SyncService.pullFavorites();
    if (cloud.isEmpty) return;
    final keys = _favorites.map((e) => e.key).toSet();
    var changed = false;
    for (final f in cloud) {
      if (keys.add(f.key)) {
        _favorites.add(f);
        changed = true;
      }
    }
    if (!changed) return;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kFav,
      jsonEncode(_favorites.map((e) => e.toJson()).toList()),
    );
  }

  // ---------- 观看记录 ----------

  Future<void> upsertWatch(WatchRecord record) async {
    // 进度是高频写入，先本地，云端异步补
    unawaited(SyncService.pushProgress(record));
    final i = _watch.indexWhere((w) => w.key == record.key);
    if (i >= 0) {
      _watch[i] = record;
    } else {
      _watch.add(record);
    }
    _watch.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    await _saveWatch();
  }

  Future<void> removeWatch(String key) async {
    _watch.removeWhere((w) => w.key == key);
    await _saveWatch();
  }

  WatchRecord? findWatch(String sourceId, String detailUrl) {
    final key = '$sourceId|$detailUrl';
    for (final w in _watch) {
      if (w.key == key) return w;
    }
    return null;
  }

  // ---------- 历史 ----------

  Future<void> addHistory(String keyword) async {
    final k = keyword.trim();
    if (k.isEmpty) return;
    _history.remove(k);
    _history.insert(0, k);
    if (_history.length > 20) _history = _history.sublist(0, 20);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHistory, jsonEncode(_history));
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _history = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kHistory);
    notifyListeners();
  }
}
