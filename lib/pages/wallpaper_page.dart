import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/store.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../wallpapers/wallpapers.dart';
import '../widgets/app_background.dart';
import 'wallpaper_store_page.dart';

/// 壁纸选择：默认光晕、内置几套、或者从相册选一张。
class WallpaperPage extends StatefulWidget {
  const WallpaperPage({super.key});

  @override
  State<WallpaperPage> createState() => _WallpaperPageState();
}

class _WallpaperPageState extends State<WallpaperPage> {
  @override
  Widget build(BuildContext context) {
    final isEn = Localizations.localeOf(context).languageCode == 'en';
    final t = L.of(context)!;
    final store = context.watch<AppStore>();
    final currentId = store.wallpaperId;
    final hasCustom = store.wallpaper != null;
    final isDefault = currentId == null && !hasCustom;

    return AppBackground(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(t.wallpaperTitle),
          actions: [
            if (!isDefault)
              TextButton(
                onPressed: () => store.setBuiltinWallpaper(null),
                child: Text(
                  t.restoreDefault,
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
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                t.builtin,
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
              itemCount: kWallpapers.length + 2,
              itemBuilder: (context, i) {
                if (i == kWallpapers.length + 1) {
                  return _Cell(
                    name: t.wallpaperStore,
                    selected: false,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const WallpaperStorePage(),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.14),
                            AppColors.primary.withValues(alpha: 0.04),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.20),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.add_rounded,
                        size: 30,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                }
                if (i == 0) {
                  return _Cell(
                    name: t.defaultGlow,
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
                  name: isEn ? w.nameEn : w.name,
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
                t.wallpaperNote,
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
