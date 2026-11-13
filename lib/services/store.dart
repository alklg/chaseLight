import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/drama.dart';
import '../models/source_error.dart';
import '../models/user_account.dart';
import '../wallpapers/wallpapers.dart';
import 'supabase_service.dart';
import 'sync_service.dart';
import '../models/media_source.dart';
import 'source_presets.dart';

/// 本地持久化：源配置、观看记录、搜索历史、主题。
class AppStore extends ChangeNotifier {
  static const _kSources = 'sources.v1';
  static const _kWatch = 'watch.v1';
  static const _kUsers = 'users.v1';
  static const _kSig = 'signature.v1';
  static const _kLang = 'language.v1';
  static const _kReader = 'reader.v1';
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
  static const _kMyWalls = 'wallpapers.v1';

  List<MediaSource> _sources = [];
  List<WatchRecord> _watch = [];
  List<FavoriteItem> _favorites = [];
  UserAccount? _me;
  String? _signature;
  String? _lang;
  Map<String, dynamic> _readerPrefs = {};

  /// 搜索历史按类型分开：搜剧名不该出现在书籍搜索里
  final Map<String, List<String>> _history = {'video': [], 'novel': []};
  bool _darkMode = false;
  int _accent = 0;
  bool _ready = false;
  String _weatherCity = '';
  String? _wallpaper;
  String? _wallpaperId;
  double _wallpaperDim = 0.30;
  int? _wallpaperTint;
  List<MyWallpaper> _myWalls = [];

  List<MediaSource> get sources => List.unmodifiable(_sources);
  List<MediaSource> get enabledSources =>
      _sources.where((s) => s.enabled).toList(growable: false);
  List<WatchRecord> get watchList => List.unmodifiable(_watch);

  List<FavoriteItem> get favorites => List.unmodifiable(_favorites);

  // ---------- 账号 ----------
  //
  // 只有一份身份：Supabase 账号。`_me` 是云端 profiles 在本机的缓存，
  // 换设备登录同一个邮箱就重建，不再有「本机多账号」。

  UserAccount? get currentUser => _me;

  /// 退出登录 / 换账号时清掉本机这份账号的缓存。
  ///
  /// 源、搜索历史、外观是设备级的，不动；收藏、进度、签名、身份属于账号。
  Future<void> clearLocalAccount() async {
    _me = null;
    _favorites = [];
    _watch = [];
    _signature = null;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUsers);
    await prefs.remove(_kFav);
    await prefs.remove(_kWatch);
    await prefs.remove(_kSig);
  }

  /// 登录后把云端资料落到本机。缺的字段按邮箱前缀/默认色补。
  Future<void> applyCloudProfile({
    required String uid,
    required String fallbackName,
    String? nickname,
    int? color,
    int? gender,
    String? birthday,
    String? signature,
    String? avatarUrl,
    String? coverUrl,
    DateTime? createdAt,
  }) async {
    // 换了账号：先把上一个账号留在本机的收藏/进度清掉，再落新身份
    if (_me != null && _me!.id != uid) await clearLocalAccount();
    final nick = (nickname ?? '').trim();
    _me = UserAccount(
      id: uid,
      nickname: nick.isEmpty ? fallbackName : nick,
      // 云端存的是色板下标（int4），不是 ARGB
      colorValue: (color != null && color >= 0 && color < kAvatarColors.length)
          ? kAvatarColors[color]
          : kAvatarColors.first,
      createdAt: createdAt ?? _me?.createdAt ?? DateTime.now(),
      gender: gender ?? 0,
      birthday: birthday,
      avatarName: _me?.avatarName,
      coverName: _me?.coverName,
      avatarUrl: avatarUrl,
      coverUrl: coverUrl,
    );
    final sig = (signature ?? '').trim();
    if (sig.isNotEmpty) _signature = sig;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUsers, jsonEncode(_me!.toJson()));
    if (_signature != null) await prefs.setString(_kSig, _signature!);
  }

  Future<void> _persistMe() async {
    final prefs = await SharedPreferences.getInstance();
    final me = _me;
    if (me == null) {
      await prefs.remove(_kUsers);
    } else {
      await prefs.setString(_kUsers, jsonEncode(me.toJson()));
    }
  }

  List<String> historyFor(SourceKind kind) =>
      List.unmodifiable(_history[_historyKey(kind)]!);

  int get historyCount =>
      _history.values.fold(0, (sum, list) => sum + list.length);

  static String _historyKey(SourceKind kind) =>
      kind == SourceKind.novel ? 'novel' : 'video';
  bool get ready => _ready;
  bool get darkMode => _darkMode;

  /// 手动选的天气城市。空字符串表示跟随定位。
  String get weatherCity => _weatherCity;

  /// 自定义壁纸的文件路径（从相册选的）
  String? get wallpaper => _wallpaper;

  /// 内置壁纸的 id；和 wallpaper 二选一
  String? get wallpaperId => _wallpaperId;

  /// 相册导入过的壁纸，最近的在前
  List<MyWallpaper> get myWallpapers => List.unmodifiable(_myWalls);

  List<Map<String, dynamic>> _storeWalls = [];
  List<Map<String, dynamic>> get storeWallpapers =>
      List.unmodifiable(_storeWalls);

  Future<void> loadStoreWallpapers() async {
    final rows = await SupabaseService.fetchWallpapers();
    if (rows.isEmpty && _storeWalls.isEmpty) return;
    _storeWalls = rows;
    notifyListeners();
  }

  /// 应用商店里的壁纸：先下到本地，再当普通自定义壁纸用
  Future<void> applyStoreWallpaper(Map<String, dynamic> row) async {
    final path = row['storage_path'] as String? ?? '';
    if (path.isEmpty) return;
    final url = SupabaseService.wallpaperUrl(path);
    final resp = await http.get(Uri.parse(url));
    if (resp.statusCode != 200) return;
    final dir = await getApplicationDocumentsDirectory();
    final name = 'store_${row['id']}.jpg';
    final f = File('${dir.path}/$name');
    await f.writeAsBytes(resp.bodyBytes);
    await addWallpaper(
      name,
      tint: row['tint'] == null ? null : Color((row['tint'] as num).toInt()),
    );
  }

  Future<void> addWallpaper(String fileName, {Color? tint}) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$fileName';
    _myWalls.removeWhere((w) => w.name == fileName);
    _myWalls.insert(
      0,
      MyWallpaper(name: fileName, path: path, tint: tint?.toARGB32()),
    );
    await _saveMyWalls();
    await setWallpaper(path, tint: tint);
  }

  Future<void> removeWallpaper(String name) async {
    _myWalls.removeWhere((w) => w.name == name);
    await _saveMyWalls();
    if (_wallpaper?.endsWith('/$name') ?? false) {
      await setWallpaper(null);
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/$name');
      if (f.existsSync()) await f.delete();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _saveMyWalls() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kMyWalls,
      jsonEncode([
        for (final w in _myWalls)
          {
            'name': w.name,
            'tint': w.tint,
            'at': DateTime.now().toIso8601String(),
          },
      ]),
    );
    notifyListeners();
  }

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
    // 启动时校正：选了内置壁纸就以壁纸的明暗为准，
    // 否则深色壁纸配浅色文字会看不清
    final wallPreset = wallpaperById(_wallpaperId);
    if (wallPreset != null) _darkMode = wallPreset.dark;
    final wallsRaw = prefs.getString(_kMyWalls);
    if (wallsRaw != null) {
      try {
        final list = jsonDecode(wallsRaw) as List;
        final dir = await getApplicationDocumentsDirectory();
        _myWalls = [
          for (final e in list.whereType<Map>())
            if (File('${dir.path}/${e['name']}').existsSync())
              MyWallpaper(
                name: e['name'] as String,
                path: '${dir.path}/${e['name']}',
                tint: (e['tint'] as num?)?.toInt(),
              ),
        ];
      } catch (_) {
        _myWalls = [];
      }
    }
    // 旧版本只存了一张 wallpaper.jpg：补进列表，不然它永远选不中
    final current = _wallpaper;
    if (current != null) {
      final name = current.split('/').last;
      if (!_myWalls.any((w) => w.name == name)) {
        _myWalls.insert(
          0,
          MyWallpaper(name: name, path: current, tint: _wallpaperTint),
        );
      }
    }
    _wallpaperDim = prefs.getDouble(_kWallDim) ?? 0.30;
    _wallpaperTint = prefs.getInt(_kWallTint);
    _sources = _decodeList(prefs.getString(_kSources), MediaSource.fromJson);
    _me = _decodeMe(prefs.getString(_kUsers), prefs.getString(_kCurrentUser));
    _signature = prefs.getString(_kSig);
    _lang = prefs.getString(_kLang);
    final readerRaw = prefs.getString(_kReader);
    if (readerRaw != null) {
      try {
        final d = jsonDecode(readerRaw);
        if (d is Map) _readerPrefs = Map<String, dynamic>.from(d);
      } catch (_) {}
    }
    _favorites = _decodeList(prefs.getString(_kFav), FavoriteItem.fromJson);
    _watch = _decodeList(prefs.getString(_kWatch), WatchRecord.fromJson)
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final h = prefs.getString(_kHistory);
    if (h != null) {
      try {
        final d = jsonDecode(h);
        if (d is List) {
          // 旧版本只有一份历史：两边都放一份，免得哪边突然空了
          final list = d.cast<String>();
          _history['video'] = List.of(list);
          _history['novel'] = List.of(list);
        } else if (d is Map) {
          for (final k in _history.keys) {
            final v = d[k];
            if (v is List) _history[k] = v.cast<String>();
          }
        }
      } catch (_) {}
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
    // 传 null 表示「恢复默认」：自定义图和取色都要一起清，
    // 否则只是把内置 id 清了，图片还盖在上面，看起来像没生效。
    if (id == null) {
      _wallpaper = null;
      _wallpaperTint = null;
    } else {
      _wallpaper = null;
      _wallpaperTint = null;
    }
    // 壁纸决定明暗：深色底壁纸自动切深色，浅色底/默认切回浅色
    if (id == null) {
      _darkMode = false;
    } else {
      final w = wallpaperById(id);
      if (w != null) _darkMode = w.dark;
    }
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDark, _darkMode);
    if (id == null) {
      await prefs.remove(_kWallId);
      await prefs.remove(_kWall);
      await prefs.remove(_kWallTint);
    } else {
      await prefs.setString(_kWallId, id);
      await prefs.remove(_kWall);
      await prefs.remove(_kWallTint);
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

  /// 读本机缓存的身份。兼容旧版本存的「用户数组」：
  /// 有 currentId 就取对应的那条，没有就取第一条。
  static UserAccount? _decodeMe(String? raw, String? currentId) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return UserAccount.fromJson(Map<String, dynamic>.from(decoded));
      }
      if (decoded is List) {
        final list = decoded
            .whereType<Map>()
            .map((e) => UserAccount.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        if (list.isEmpty) return null;
        return list.firstWhere(
          (u) => u.id == currentId,
          orElse: () => list.first,
        );
      }
    } catch (e) {
      debugPrint('读取账号失败: $e');
    }
    return null;
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
    if (trimmed.isEmpty) throw const ImportException(ImportErr.empty);
    dynamic decoded;
    try {
      decoded = jsonDecode(trimmed);
    } on FormatException catch (e) {
      throw ImportException(ImportErr.jsonSyntax, message: e.message);
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
    if (rawList.isEmpty) throw const ImportException(ImportErr.noSources);

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
        throw ImportException(
          ImportErr.sourceAt,
          index: i + 1,
          message: e.message,
        );
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

  /// 改已导入的源：保留原 id，其余字段以新配置为准
  Future<void> updateSource(String id, MediaSource src) async {
    final i = _sources.indexWhere((s) => s.id == id);
    if (i < 0) return;
    _sources[i] = MediaSource.fromJson({...src.toJson(), 'id': id});
    notifyListeners();
    await _saveSources();
  }

  String exportSources() => const JsonEncoder.withIndent(
    '  ',
  ).convert(_sources.map((e) => e.toJson()).toList());

  /// 阅读器偏好：字号 / 行距 / 翻页方式 / 底色
  Map<String, dynamic> get readerPrefs => Map.unmodifiable(_readerPrefs);

  Future<void> saveReaderPrefs(Map<String, dynamic> patch) async {
    _readerPrefs = {..._readerPrefs, ...patch};
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kReader, jsonEncode(_readerPrefs));
  }

  /// 语言代码：null 跟随系统，'zh' / 'en' 强制
  String? get lang => _lang;

  Future<void> setLang(String? code) async {
    _lang = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    if (code == null) {
      await prefs.remove(_kLang);
    } else {
      await prefs.setString(_kLang, code);
    }
  }

  /// 个性签名，跟账号走（暂存本地，登录后可同步）
  String? get signature => _signature;

  /// 改昵称 / 签名 / 性别 / 头像色。本地立刻生效，云端异步补。
  Future<void> updateProfile({
    String? nickname,
    String? signature,
    int? gender,
    int? color,
    String? birthday,
  }) async {
    final me = _me;
    if (me != null) {
      _me = me.copyWith(
        nickname: (nickname?.trim().isNotEmpty ?? false)
            ? nickname!.trim()
            : me.nickname,
        gender: gender,
        colorValue: color,
        birthday: birthday,
      );
    }
    if (signature != null) _signature = signature.trim();
    notifyListeners();

    await _persistMe();
    final prefs = await SharedPreferences.getInstance();
    if (_signature != null) await prefs.setString(_kSig, _signature!);

    final colorIndex = color == null ? null : kAvatarColors.indexOf(color);
    unawaited(
      SyncService.pushProfile(
        nickname: nickname,
        signature: signature,
        gender: gender,
        color: (colorIndex != null && colorIndex >= 0) ? colorIndex : null,
        birthday: birthday,
      ),
    );
  }

  /// 存头像或背景图：本地留一份缓存，同时传云端。
  ///
  /// 头像和背景一套逻辑：同一个桶、同一个目录，只有文件名不同。
  /// 上传失败不报错——本地这份仍然可用，下次改图会再传。
  Future<void> setProfileImage({
    required bool isCover,
    required File source,
  }) async {
    final me = _me;
    if (me == null) return;
    final dir = await getApplicationDocumentsDirectory();
    final name = '${isCover ? 'cover' : 'avatar'}_${me.id}.jpg';
    final target = File('${dir.path}/$name');
    await source.copy(target.path);

    _me = me.copyWith(
      avatarName: isCover ? me.avatarName : name,
      coverName: isCover ? name : me.coverName,
    );
    notifyListeners();
    await _persistMe();

    final url = await SupabaseService.uploadProfileImage(
      isCover: isCover,
      file: target,
    );
    if (url == null || _me == null) return;
    _me = _me!.copyWith(
      avatarUrl: isCover ? null : url,
      coverUrl: isCover ? url : null,
    );
    notifyListeners();
    await _persistMe();
    unawaited(
      SyncService.pushProfile(
        avatarUrl: isCover ? null : url,
        coverUrl: isCover ? url : null,
      ),
    );
  }

  /// 登录后把云端的头像/背景下到本地当缓存。
  ///
  /// 本地已有同名文件就不重复下——换设备时目录是空的，正好一次拉全。
  Future<void> cacheProfileImages() async {
    final me = _me;
    if (me == null) return;
    final avatar = await _cacheImage(me.avatarUrl, 'avatar_${me.id}.jpg');
    final cover = await _cacheImage(me.coverUrl, 'cover_${me.id}.jpg');
    if (avatar == null && cover == null) return;
    _me = _me!.copyWith(
      avatarName: avatar ?? me.avatarName,
      coverName: cover ?? me.coverName,
    );
    notifyListeners();
    await _persistMe();
  }

  Future<String?> _cacheImage(String? url, String fileName) async {
    if (url == null || url.isEmpty) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/$fileName');
      if (f.existsSync()) return fileName;
      final resp = await http.get(Uri.parse(url));
      if (resp.statusCode != 200) return null;
      await f.writeAsBytes(resp.bodyBytes);
      return fileName;
    } catch (_) {
      return null;
    }
  }

  /// 把文件名解析成完整路径（文件不在就返回 null）
  Future<String?> imagePath(String? name) async {
    if (name == null || name.isEmpty) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final f = File('${dir.path}/$name');
      return f.existsSync() ? f.path : null;
    } catch (_) {
      return null;
    }
  }

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

  /// 登录后调用：云端资料只补本地空着的字段（目前只有签名）。
  ///
  /// 昵称/性别不拉：本地多账号是独立身份，云端只有一个账号，
  /// 直接覆盖会把本地账号名改错。
  Future<void> mergeCloudProfile() async {
    final row = await SyncService.pullProfile();
    if (row == null) return;
    final sig = (row['signature'] as String?)?.trim();
    if (sig == null || sig.isEmpty) return;
    if (_signature?.trim().isNotEmpty ?? false) return;
    _signature = sig;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSig, sig);
  }

  /// 登录后调用：把云端的进度并到本地。同一条取 updated_at 较新的那份。
  ///
  /// 云端 progress 表没有 source_name，回来后按 source_id 在本地补。
  Future<void> mergeCloudProgress() async {
    final cloud = await SyncService.pullProgress();
    if (cloud.isEmpty) return;
    var changed = false;
    for (final r in cloud) {
      final remote = r.sourceName.isEmpty
          ? r.copyWith(sourceName: _sourceNameOf(r.sourceId))
          : r;
      final i = _watch.indexWhere((w) => w.key == remote.key);
      if (i < 0) {
        _watch.add(remote);
        changed = true;
      } else if (remote.updatedAt.isAfter(_watch[i].updatedAt)) {
        _watch[i] = remote;
        changed = true;
      }
    }
    if (!changed) return;
    _watch.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
    await _saveWatch();
  }

  String _sourceNameOf(String id) {
    for (final s in _sources) {
      if (s.id == id) return s.name;
    }
    return '';
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

  Future<void> addHistory(SourceKind kind, String keyword) async {
    final k = keyword.trim();
    if (k.isEmpty) return;
    final list = _history[_historyKey(kind)]!;
    list.remove(k);
    list.insert(0, k);
    if (list.length > 20) list.removeRange(20, list.length);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHistory, jsonEncode(_history));
    notifyListeners();
  }

  /// 传 kind 只清这个类型；不传清全部（设置页用）
  Future<void> clearHistory([SourceKind? kind]) async {
    if (kind == null) {
      for (final list in _history.values) {
        list.clear();
      }
    } else {
      _history[_historyKey(kind)]!.clear();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kHistory, jsonEncode(_history));
    notifyListeners();
  }
}

/// 相册导入的壁纸。文件在文档目录里，这里只记文件名和顶栏取色。
class MyWallpaper {
  const MyWallpaper({required this.name, required this.path, this.tint});

  final String name;
  final String path;
  final int? tint;
}
