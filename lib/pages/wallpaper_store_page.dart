import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/store.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';

/// 壁纸商店：只读。用户只能挑一张下载使用，不能上传。
class WallpaperStorePage extends StatefulWidget {
  const WallpaperStorePage({super.key});

  @override
  State<WallpaperStorePage> createState() => _WallpaperStorePageState();
}

class _WallpaperStorePageState extends State<WallpaperStorePage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await context.read<AppStore>().loadStoreWallpapers();
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    final store = context.watch<AppStore>();
    final list = store.storeWallpapers;

    return AppBackground(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(title: Text(t.wallpaperStore)),
        body: _loading
            ? GridView.builder(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.paddingOf(context).top + kToolbarHeight + 12,
                  20,
                  24,
                ),
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.56,
                ),
                itemCount: 6,
                itemBuilder: (_, _) => DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              )
            : list.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 38,
                        color: AppColors.textTertiary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        t.storeEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.7,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : GridView.builder(
                padding: EdgeInsets.fromLTRB(
                  20,
                  MediaQuery.paddingOf(context).top + kToolbarHeight + 12,
                  20,
                  24 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.62,
                ),
                itemCount: list.length,
                itemBuilder: (context, i) {
                  final row = list[i];
                  final path = row['storage_path'] as String? ?? '';
                  if (path.isEmpty) return const SizedBox.shrink();
                  return GestureDetector(
                    onTap: () async {
                      await store.applyStoreWallpaper(row);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(L.of(context)!.wallpaperApplied),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.network(
                              SupabaseService.wallpaperUrl(path),
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                color: AppColors.surface,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 22,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (row['title'] as String?)?.isNotEmpty ?? false
                              ? row['title'] as String
                              : '',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
