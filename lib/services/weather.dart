import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WeatherCity {
  const WeatherCity(this.name, this.lat, this.lon);

  final String name;
  final double lat;
  final double lon;
}

/// 内置城市表。天气接口对精度要求不高，城市中心点足够。
const kCities = <WeatherCity>[
  WeatherCity('北京', 39.9042, 116.4074),
  WeatherCity('上海', 31.2304, 121.4737),
  WeatherCity('广州', 23.1291, 113.2644),
  WeatherCity('深圳', 22.5431, 114.0579),
  WeatherCity('杭州', 30.2741, 120.1551),
  WeatherCity('成都', 30.5728, 104.0668),
  WeatherCity('武汉', 30.5928, 114.3055),
  WeatherCity('西安', 34.3416, 108.9398),
  WeatherCity('南京', 32.0603, 118.7969),
  WeatherCity('重庆', 29.5630, 106.5516),
  WeatherCity('天津', 39.3434, 117.3616),
  WeatherCity('苏州', 31.2989, 120.5853),
  WeatherCity('长沙', 28.2282, 112.9388),
  WeatherCity('郑州', 34.7466, 113.6254),
  WeatherCity('青岛', 36.0671, 120.3826),
  WeatherCity('沈阳', 41.8057, 123.4315),
  WeatherCity('大连', 38.9140, 121.6147),
  WeatherCity('厦门', 24.4798, 118.0894),
  WeatherCity('福州', 26.0745, 119.2965),
  WeatherCity('昆明', 25.0389, 102.7183),
  WeatherCity('合肥', 31.8206, 117.2272),
  WeatherCity('济南', 36.6512, 117.1201),
  WeatherCity('哈尔滨', 45.8038, 126.5350),
  WeatherCity('长春', 43.8171, 125.3235),
  WeatherCity('石家庄', 38.0428, 114.5149),
  WeatherCity('太原', 37.8706, 112.5489),
  WeatherCity('南昌', 28.6820, 115.8579),
  WeatherCity('贵阳', 26.6470, 106.6302),
  WeatherCity('南宁', 22.8170, 108.3665),
  WeatherCity('兰州', 36.0611, 103.8343),
  WeatherCity('海口', 20.0440, 110.1999),
  WeatherCity('乌鲁木齐', 43.8256, 87.6168),
  WeatherCity('拉萨', 29.6520, 91.1721),
  WeatherCity('银川', 38.4872, 106.2309),
  WeatherCity('西宁', 36.6171, 101.7782),
  WeatherCity('呼和浩特', 40.8424, 111.7490),
];

WeatherCity cityByName(String? name) {
  if (name == null) return kCities.first;
  for (final c in kCities) {
    if (c.name == name) return c;
  }
  return kCities.first;
}

class WeatherNow {
  const WeatherNow({
    required this.city,
    required this.temp,
    required this.feelsLike,
    required this.code,
    required this.humidity,
    required this.wind,
    required this.precipProb,
    required this.uv,
    required this.max,
    required this.min,
    required this.updatedAt,
  });

  final String city;
  final double temp;
  final double feelsLike;
  final int code;
  final int humidity;
  final double wind;
  final int precipProb;
  final double uv;
  final double max;
  final double min;
  final DateTime updatedAt;

  /// WMO 天气代码 → 中文
  String get text {
    switch (code) {
      case 0:
        return '晴';
      case 1:
        return '大部晴朗';
      case 2:
        return '多云';
      case 3:
        return '阴';
      case 45:
      case 48:
        return '雾';
      case 51:
      case 53:
      case 55:
        return '毛毛雨';
      case 56:
      case 57:
        return '冻雨';
      case 61:
        return '小雨';
      case 63:
        return '中雨';
      case 65:
        return '大雨';
      case 66:
      case 67:
        return '冻雨';
      case 71:
        return '小雪';
      case 73:
        return '中雪';
      case 75:
        return '大雪';
      case 77:
        return '雪粒';
      case 80:
        return '阵雨';
      case 81:
        return '强阵雨';
      case 82:
        return '暴雨';
      case 85:
      case 86:
        return '阵雪';
      case 95:
        return '雷阵雨';
      case 96:
      case 99:
        return '雷暴伴冰雹';
      default:
        return '未知';
    }
  }

  IconData get icon {
    if (code == 0 || code == 1) return Icons.wb_sunny_rounded;
    if (code == 2) return Icons.wb_cloudy_rounded;
    if (code == 3) return Icons.cloud_rounded;
    if (code == 45 || code == 48) return Icons.foggy;
    if (code >= 51 && code <= 67) return Icons.grain_rounded;
    if (code >= 71 && code <= 86) return Icons.ac_unit_rounded;
    if (code >= 95) return Icons.thunderstorm_rounded;
    return Icons.wb_cloudy_rounded;
  }

  /// 一句生活建议。按「会不会影响出门」的优先级挑一条，
  /// 雨雪 > 温差 > 紫外线 > 风 > 温度舒适度。
  String get advice {
    if (precipProb >= 60 || (code >= 61 && code <= 67)) {
      return '有雨，出门带把伞';
    }
    if (code >= 71 && code <= 86) {
      return '下雪，路面会滑，慢点走';
    }
    if (code >= 95) {
      return '有雷暴，尽量别在外面逗留';
    }
    if (max - min >= 10) {
      return '早晚温差 ${(max - min).round()}°，带件外套';
    }
    if (uv >= 8) {
      return '紫外线很强，注意防晒';
    }
    if (wind >= 30) {
      return '风不小，骑车注意';
    }
    if (temp >= 33) {
      return '很热，多喝水，别在正午暴晒';
    }
    if (temp <= 0) {
      return '零下了，裹严实点';
    }
    if (code == 45 || code == 48) {
      return '有雾，开车慢一点';
    }
    if (temp >= 18 && temp <= 27 && precipProb < 30) {
      return '天气不错，适合出门走走';
    }
    return '体感 ${feelsLike.round()}°，穿得舒服就行';
  }
}

class WeatherService {
  static WeatherNow? _cache;
  static String? _cacheCity;
  static DateTime? _cacheAt;

  /// 缓存 30 分钟：天气没必要每次进 App 都请求
  static bool get _fresh =>
      _cacheAt != null &&
      DateTime.now().difference(_cacheAt!) < const Duration(minutes: 30);

  static WeatherNow? get cached => _fresh ? _cache : null;

  static Future<WeatherNow> load(WeatherCity city, {bool force = false}) {
    return loadAt(city.lat, city.lon, city.name, force: force);
  }

  /// 按坐标取天气。GPS 拿到位置后直接走这里，不必先反查城市。
  static Future<WeatherNow> loadAt(
    double lat,
    double lon,
    String city, {
    bool force = false,
  }) async {
    if (!force && _fresh && _cacheCity == city && _cache != null) {
      return _cache!;
    }

    final uri = Uri.https('api.open-meteo.com', '/v1/forecast', {
      'latitude': lat.toStringAsFixed(4),
      'longitude': lon.toStringAsFixed(4),
      'current':
          'temperature_2m,relative_humidity_2m,apparent_temperature,'
          'precipitation,weather_code,wind_speed_10m',
      'daily':
          'temperature_2m_max,temperature_2m_min,'
          'precipitation_probability_max,uv_index_max',
      'timezone': 'Asia/Shanghai',
      'forecast_days': '1',
    });

    final resp = await http.get(uri).timeout(const Duration(seconds: 12));
    if (resp.statusCode >= 400) {
      throw Exception('天气服务返回 ${resp.statusCode}');
    }

    final j = jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    final cur = j['current'] as Map<String, dynamic>;
    final daily = j['daily'] as Map<String, dynamic>;

    double pick(Map<String, dynamic> m, String k, [double fallback = 0]) {
      final list = m[k];
      if (list is List && list.isNotEmpty && list.first is num) {
        return (list.first as num).toDouble();
      }
      final v = m[k];
      return v is num ? v.toDouble() : fallback;
    }

    final now = WeatherNow(
      city: city,
      temp: pick(cur, 'temperature_2m'),
      feelsLike: pick(cur, 'apparent_temperature'),
      code: pick(cur, 'weather_code').round(),
      humidity: pick(cur, 'relative_humidity_2m').round(),
      wind: pick(cur, 'wind_speed_10m'),
      precipProb: pick(daily, 'precipitation_probability_max').round(),
      uv: pick(daily, 'uv_index_max'),
      max: pick(daily, 'temperature_2m_max'),
      min: pick(daily, 'temperature_2m_min'),
      updatedAt: DateTime.now(),
    );

    _cache = now;
    _cacheCity = city;
    _cacheAt = now.updatedAt;
    return now;
  }
}
