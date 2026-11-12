import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

import '../services/store.dart';
import '../theme/app_theme.dart';
import '../wallpapers/wallpapers.dart';
import '../widgets/app_background.dart';
import '../widgets/solar_icon.dart';
import '../widgets/glass.dart';

/// 壁纸选择：默认光晕、内置几套、或者从相册选一张。
class WallpaperPage extends StatefulWidget {
  const WallpaperPage({super.key});

  @override
  State<WallpaperPage> createState() => _WallpaperPageState();
}

class _WallpaperPageState extends State<WallpaperPage> {
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
      final dir = await getApplicationDocumentsDirectory();
      final target = File('${dir.path}/wallpaper.jpg');
      await File(picked.path).copy(target.path);
      if (!mounted) return;
      await context.read<AppStore>().setWallpaper(target.path);
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
    final store = context.watch<AppStore>();
    final currentId = store.wallpaperId;
    final hasCustom = store.wallpaper != null;
    final isDefault = currentId == null && !hasCustom;

    return AppBackground(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('壁纸'),
          actions: [
            if (!isDefault)
              TextButton(
                onPressed: () => store.setBuiltinWallpaper(null),
                child: Text(
                  '恢复默认',
                  style: TextStyle(fontSize: 13, color: AppColors.primary),
                ),
              ),
            const SizedBox(width: 4),
          ],
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
            20,
            40,
          ),
          children: [
            // 相册
            GestureDetector(
              onTap: _busy ? null : _pick,
              child: Container(
                height: 74,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: kCardGradient,
                  borderRadius: kCardRadius,
                  boxShadow: kSoftShadow,
                  border: kSoftBorder,
                ),
                child: Row(
                  children: [
                    if (hasCustom)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.file(
                          File(store.wallpaper!),
                          width: 42,
                          height: 42,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const SizedBox(),
                        ),
                      )
                    else
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: SolarIcon(
                          'gallery',
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            hasCustom ? '当前：相册图片' : '从相册选一张',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _busy ? '处理中…' : '用自己的照片当背景',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasCustom)
                      Icon(
                        Icons.check_circle_rounded,
                        size: 19,
                        color: AppColors.primary,
                      )
                    else
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: AppColors.textTertiary,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                '内置',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 10,
                childAspectRatio: 0.62,
              ),
              itemCount: kWallpapers.length + 1,
              itemBuilder: (context, i) {
                if (i == 0) {
                  return _Cell(
                    name: '默认光晕',
                    selected: isDefault,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      store.setBuiltinWallpaper(null);
                    },
                    child: const _DefaultThumb(),
                  );
                }
                final w = kWallpapers[i - 1];
                return _Cell(
                  name: w.name,
                  selected: currentId == w.id,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    store.setBuiltinWallpaper(w.id);
                  },
                  child: CustomPaint(
                    painter: (AppColors.isDark && w.darkPainter != null)
                        ? w.darkPainter!
                        : w.painter,
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '内置壁纸都是代码画的，不占包体。卡片会透出壁纸的颜色，'
                '阅读器和播放器不受影响。',
                style: TextStyle(
                  fontSize: 11,
                  height: 1.7,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 默认光晕的缩略：和 AppBackground 同款两团光
class _DefaultThumb extends StatelessWidget {
  const _DefaultThumb();

  @override
  Widget build(BuildContext context) {
    final dark = AppColors.isDark;
    final accent = AppColors.primary;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: AppColors.bg),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(-0.9, -1.05),
              radius: 1.15,
              colors: [
                accent.withValues(alpha: dark ? 0.35 : 0.42),
                accent.withValues(alpha: 0),
              ],
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(1.05, 0.95),
              radius: 1.0,
              colors: [
                Color.lerp(
                  accent,
                  const Color(0xFF7BD3FF),
                  0.6,
                )!.withValues(alpha: dark ? 0.25 : 0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({
    required this.name,
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final String name;
  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: selected
                      ? AppColors.primary
                      : Colors.white.withValues(alpha: 0.4),
                  width: selected ? 2.4 : 1,
                ),
                boxShadow: kSoftShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11.5),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    child,
                    if (selected)
                      Align(
                        alignment: Alignment.topRight,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 7),
          Text(
            name,
            style: TextStyle(
              fontSize: 12,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
