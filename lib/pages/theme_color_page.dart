import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/store.dart';
import '../theme/accents.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/glass.dart';

/// 主题色选择。选完立即生效，不用退出去看。
class ThemeColorPage extends StatelessWidget {
  const ThemeColorPage({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final dark = store.darkMode;
    final current = store.accent.clamp(0, kAccents.length - 1);

    return AppBackground(
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('主题色'),
          backgroundColor: Colors.transparent,
          flexibleSpace: GlassBackdrop(),
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            MediaQuery.paddingOf(context).top + kToolbarHeight + 8,
            20,
            40,
          ),
          children: [
            _Preview(accent: kAccents[current], dark: dark),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                gradient: kCardGradient,
                borderRadius: kCardRadius,
                boxShadow: kSoftShadow,
                border: kSoftBorder,
              ),
              child: Column(
                children: [
                  for (var i = 0; i < kAccents.length; i++) ...[
                    if (i > 0)
                      Divider(height: 1, indent: 66, color: AppColors.divider),
                    _AccentRow(
                      accent: kAccents[i],
                      dark: dark,
                      selected: i == current,
                      onTap: () => store.setAccent(i),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '深色和浅色各配了一套色值，同一个名字在两种底色下都是同一支颜色，'
                '亮度会自动调过，不会亮到刺眼，也不会暗到看不清。',
                style: TextStyle(
                  fontSize: 11.5,
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

class _Preview extends StatelessWidget {
  const _Preview({required this.accent, required this.dark});

  final AppAccent accent;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final color = accent.color(dark);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        gradient: kCardGradient,
        borderRadius: kCardRadius,
        boxShadow: kSoftShadow,
        border: kSoftBorder,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '追光',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Text(
                  accent.name,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Text(
                  '按钮',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: color, width: 1.2),
                ),
                child: Text(
                  '描边',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.play_circle_outline_rounded,
                  size: 18,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AccentRow extends StatelessWidget {
  const _AccentRow({
    required this.accent,
    required this.dark,
    required this.selected,
    required this.onTap,
  });

  final AppAccent accent;
  final bool dark;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = accent.color(dark);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(11),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                accent.name,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_rounded, size: 19, color: color)
            else
              const SizedBox(width: 19),
          ],
        ),
      ),
    );
  }
}
