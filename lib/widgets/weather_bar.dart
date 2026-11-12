import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/store.dart';
import '../services/weather.dart';
import '../theme/app_theme.dart';
import '../widgets/app_card.dart';
import '../widgets/glass.dart';

/// 首页顶部一条天气。加载失败就整条收起，不占地方也不弹错误。
class WeatherBar extends StatefulWidget {
  const WeatherBar({super.key});

  @override
  State<WeatherBar> createState() => _WeatherBarState();
}

class _WeatherBarState extends State<WeatherBar> {
  WeatherNow? _now;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // 缓存先顶上，避免闪空白；但定位必须每次重来，否则会一直显示上次的城市
    _now = WeatherService.cached;
    _load();
  }

  Future<void> _load({bool force = false}) async {
    if (_loading) return;
    final store = context.read<AppStore>();
    setState(() => _loading = true);
    try {
      WeatherNow? w;

      if (store.weatherCity.isNotEmpty) {
        // 手动选过城市就听手动选的
        w = await WeatherService.load(
          cityByName(store.weatherCity),
          force: force,
        );
      } else {
        // 没选过 → 先问定位
        final pos = await WeatherService.locate();
        if (pos != null) {
          w = await WeatherService.loadAt(
            pos.latitude,
            pos.longitude,
            '当前位置',
            force: force,
          );
        } else {
          // 没权限或定位失败 → 退回默认城市
          w = await WeatherService.load(kCities.first, force: force);
        }
      }

      if (!mounted) return;
      setState(() {
        _now = w;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = _now;
    // 没有数据且没在加载 → 整条不显示
    if (now == null && !_loading) return const SizedBox.shrink();

    return Padding(
      // 和 AppBar 拉开距离，别贴着
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        onTap: now == null ? null : _openDetail,
        child: now == null
            ? Row(
                children: [
                  SizedBox(
                    width: 13,
                    height: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    '正在取天气…',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const Spacer(),
                ],
              )
            : Row(
                children: [
                  Icon(now.icon, size: 20, color: AppColors.primary),
                  const SizedBox(width: 9),
                  Text(
                    '${now.temp.round()}°',
                    style: TextStyle(
                      fontSize: 20,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Text(
                    '${now.city} · ${now.text}',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 17,
                    color: AppColors.textTertiary,
                  ),
                ],
              ),
      ),
    );
  }

  void _openDetail() {
    final now = _now;
    if (now == null) return;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.22),
      builder: (sheetContext) => GlassSheet(
        child: _WeatherSheet(
          initial: now,
          onCityChanged: (_) => _load(force: true),
        ),
      ),
    );
  }
}

class _WeatherSheet extends StatefulWidget {
  const _WeatherSheet({required this.initial, required this.onCityChanged});

  final WeatherNow initial;

  /// 城市变了，通知首页也刷一遍
  final ValueChanged<String> onCityChanged;

  @override
  State<_WeatherSheet> createState() => _WeatherSheetState();
}

class _WeatherSheetState extends State<_WeatherSheet> {
  late WeatherNow _now = widget.initial;
  bool _busy = false;

  Future<void> _reload(String city) async {
    setState(() => _busy = true);
    try {
      WeatherNow? w;
      if (city == '当前位置') {
        final pos = await WeatherService.locate();
        if (pos != null) {
          w = await WeatherService.loadAt(
            pos.latitude,
            pos.longitude,
            '当前位置',
            force: true,
          );
        }
      }
      w ??= await WeatherService.load(cityByName(city), force: true);
      if (!mounted) return;
      setState(() {
        _now = w!;
        _busy = false;
      });
      widget.onCityChanged(city);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.62,
      child: Column(
        children: [
          const SizedBox(height: 14),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(_now.icon, size: 34, color: AppColors.primary),
                        const SizedBox(width: 12),
                        if (_busy)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: SizedBox(
                              width: 26,
                              height: 26,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary,
                              ),
                            ),
                          )
                        else
                          Text(
                            '${_now.temp.round()}°',
                            style: TextStyle(
                              fontSize: 44,
                              height: 1,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -1.5,
                              color: AppColors.textPrimary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${_now.city} · ${_now.text} · 体感 ${_now.feelsLike.round()}°',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                GestureDetector(
                  onTap: _busy ? null : () => _pickCity(context, store),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '换城市',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Icon(
                          Icons.expand_more_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 14),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Text(
                _now.advice,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.5,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                _row(
                  '今日最高 / 最低',
                  '${_now.max.round()}° / ${_now.min.round()}°',
                ),
                _row('降水概率', '${_now.precipProb}%'),
                _row('湿度', '${_now.humidity}%'),
                _row('风速', '${_now.wind.toStringAsFixed(0)} km/h'),
                _row('紫外线指数', _now.uv.toStringAsFixed(1)),
                const SizedBox(height: 8),
                Text(
                  '数据来自 Open-Meteo，每 30 分钟更新一次',
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 打开列表时直接停在当前城市，省得往下翻
  double _initialOffset(String city) {
    final i = kCities.indexWhere((c) => c.name == city);
    if (i <= 0) return 0;
    return (i * 46.0 - 100).clamp(0, double.infinity);
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _pickCity(BuildContext context, AppStore store) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.2),
      builder: (ctx) => GlassSheet(
        child: SizedBox(
          height: MediaQuery.sizeOf(ctx).height * 0.62,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
                child: Row(
                  children: [
                    Text(
                      '选城市',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${kCities.length} 个',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: ScrollController(
                    initialScrollOffset: _initialOffset(store.weatherCity),
                  ),
                  itemCount: kCities.length + 1,
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      final active = _now.city == '当前位置';
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          Navigator.pop(ctx);
                          await store.setWeatherCity('');
                          await _reload('当前位置');
                        },
                        child: Container(
                          height: 46,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            children: [
                              Icon(
                                Icons.my_location_rounded,
                                size: 16,
                                color: active
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '使用当前位置',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: active
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                  fontWeight: active
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                ),
                              ),
                              const Spacer(),
                              if (active)
                                Icon(
                                  Icons.check_rounded,
                                  size: 17,
                                  color: AppColors.primary,
                                ),
                            ],
                          ),
                        ),
                      );
                    }
                    final c = kCities[i - 1];
                    final active = c.name == store.weatherCity;
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () async {
                        Navigator.pop(ctx);
                        await store.setWeatherCity(c.name);
                        await _reload(c.name);
                      },
                      child: Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            Text(
                              c.name,
                              style: TextStyle(
                                fontSize: 14,
                                color: active
                                    ? AppColors.primary
                                    : AppColors.textPrimary,
                                fontWeight: active
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            ),
                            const Spacer(),
                            if (active)
                              Icon(
                                Icons.check_rounded,
                                size: 17,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: MediaQuery.paddingOf(ctx).bottom),
            ],
          ),
        ),
      ),
    );
  }
}
