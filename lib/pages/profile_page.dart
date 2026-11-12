import 'package:flutter/material.dart';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/user_account.dart';
import '../services/store.dart';
import '../services/supabase_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card.dart';

/// 交友卡片。
///
/// 结构参照参考图：顶部大头像压在白卡上沿、居中名字、一排统计、下面信息列表。
/// 追光没有等级和粉丝，统计换成收藏数 / 在追数 / 加入天数。
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    final store = context.watch<AppStore>();
    final me = store.currentUser;

    return AppBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(t.profileTitle),
          actions: [
            IconButton(
              tooltip: t.edit,
              onPressed: () => _edit(context, store, me),
              icon: Icon(
                Icons.edit_outlined,
                size: 19,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            _HeadCard(user: me, store: store),
            const SizedBox(height: 14),
            _StatsRow(store: store, user: me),
            const SizedBox(height: 14),
            _InfoCard(user: me),
            const SizedBox(height: 20),
            SizedBox(
              height: 46,
              child: OutlinedButton.icon(
                onPressed: () => _edit(context, store, me),
                icon: Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                label: Text(
                  t.editProfile,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.35),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _edit(BuildContext context, AppStore store, UserAccount? me) {
    if (me == null) return;
    showDialog<void>(
      context: context,
      builder: (_) => _EditDialog(store: store, user: me),
    );
  }
}

/// 顶部：背景图 + 压边头像 + 名字 + ID + 签名
class _HeadCard extends StatelessWidget {
  const _HeadCard({required this.user, required this.store});

  final UserAccount? user;
  final AppStore store;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    final u = user;

    return Column(
      children: [
        // 背景图（可上传），没有就用主色渐变
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 178,
            width: double.infinity,
            child: FutureBuilder<String?>(
              future: store.imagePath(u?.coverName),
              builder: (context, snap) {
                final path = snap.data;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (path != null)
                      Image.file(
                        File(path),
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                        errorBuilder: (_, _, _) =>
                            _coverFallback(u?.color ?? AppColors.primary),
                      )
                    else
                      _coverFallback(u?.color ?? AppColors.primary),
                    // 底部渐隐到卡片色，让头像和名字有个落脚处
                    DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.surface.withValues(alpha: 0.70),
                          ],
                          stops: const [0.58, 1.0],
                        ),
                      ),
                    ),
                    // 换背景
                    Positioned(
                      top: 10,
                      right: 10,
                      child: _EditChip(
                        icon: Icons.wallpaper_rounded,
                        label: t.cover,
                        onTap: () => _pickCover(context, store),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),

        // 头像压在上沿
        Transform.translate(
          offset: const Offset(0, -44),
          child: Column(
            children: [
              FutureBuilder<String?>(
                future: store.imagePath(u?.avatarName),
                builder: (context, snap) => GestureDetector(
                  onTap: () => _pickAvatar(context, store),
                  child: _BigAvatar(user: u, imagePath: snap.data),
                ),
              ),
              const SizedBox(height: 12),
              // 名字长了自动缩，别把两边顶满
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    u?.nickname ?? t.loading,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 26,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'ID  ${_shortId(u?.id)}',
                    style: TextStyle(
                      fontSize: 12,
                      letterSpacing: 0.3,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: u == null
                        ? null
                        : () {
                            Clipboard.setData(ClipboardData(text: u.id));
                            HapticFeedback.selectionClick();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(t.copiedId),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                    behavior: HitTestBehavior.opaque,
                    child: Icon(
                      Icons.copy_rounded,
                      size: 13,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  (store.signature?.trim().isNotEmpty ?? false)
                      ? store.signature!.trim()
                      : t.noSignature,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.6,
                    color: (store.signature?.trim().isNotEmpty ?? false)
                        ? AppColors.textSecondary
                        : AppColors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _coverFallback(Color color) {
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(color, Colors.white, 0.45)!,
                color,
                Color.lerp(color, Colors.black, 0.25)!,
              ],
              stops: const [0.0, 0.55, 1.0],
            ),
          ),
        ),
        // 两团光斑，让封面不是一块死色
        Positioned(
          top: -34,
          right: -26,
          child: _blob(120, Colors.white.withValues(alpha: 0.20)),
        ),
        Positioned(
          bottom: 10,
          left: -30,
          child: _blob(96, Colors.white.withValues(alpha: 0.12)),
        ),
      ],
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }

  Future<void> _pickCover(BuildContext context, AppStore store) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 88,
    );
    if (picked == null) return;
    await store.setProfileImage(isCover: true, source: File(picked.path));
  }

  Future<void> _pickAvatar(BuildContext context, AppStore store) async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 88,
    );
    if (picked == null) return;
    await store.setProfileImage(isCover: false, source: File(picked.path));
  }

  String _shortId(String? id) {
    if (id == null || id.isEmpty) return '------';
    final t = id.replaceAll('u', '');
    return t.length >= 6 ? t.substring(t.length - 6) : t;
  }
}

/// 背景图上的小按钮
class _EditChip extends StatelessWidget {
  const _EditChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.34),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(fontSize: 11.5, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

/// 大号头像：纯色圆底 + 首字，等有真头像了换成图片
class _BigAvatar extends StatelessWidget {
  const _BigAvatar({required this.user, this.imagePath});

  final UserAccount? user;
  final String? imagePath;

  @override
  Widget build(BuildContext context) {
    final color = user?.color ?? AppColors.primary;
    if (imagePath != null) {
      return Container(
        width: 92,
        height: 92,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.surface, width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipOval(
          child: Image.file(
            File(imagePath!),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => ColoredBox(color: color),
          ),
        ),
      );
    }
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, Color.lerp(color, Colors.black, 0.22)!],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.32),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        user?.initial ?? '?',
        style: const TextStyle(
          fontSize: 38,
          height: 1,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// 三格统计：收藏 / 在追 / 加入天数
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.store, required this.user});

  final AppStore store;
  final UserAccount? user;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    final days = user == null
        ? 0
        : DateTime.now().difference(user!.createdAt).inDays;

    return AppCard(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          _cell(t, '${store.favorites.length}', t.statFavorites),
          _divider(),
          _cell(t, '${store.watchList.length}', t.statWatching),
          _divider(),
          _cell(t, '${days < 1 ? 1 : days}', t.statDays),
        ],
      ),
    );
  }

  Widget _cell(L t, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 23,
              height: 1.1,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11.5, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 28, color: AppColors.divider);
}

/// 信息列表：性别 / 生日 / 邮箱 / 加入
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.user});

  final UserAccount? user;

  static const _genderText = ['未设置', '男', '女', '保密'];

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    final u = user;
    final joined = u == null
        ? '—'
        : '${u.createdAt.year}-${u.createdAt.month.toString().padLeft(2, '0')}-${u.createdAt.day.toString().padLeft(2, '0')}';

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _row(
            t,
            Icons.wc_rounded,
            t.infoGender,
            _genderText[(u?.gender ?? 0).clamp(0, 3)],
          ),
          _line(),
          _row(t, Icons.cake_outlined, t.infoBirthday, u?.birthday ?? t.empty),
          _line(),
          _row(
            t,
            Icons.mail_outline_rounded,
            t.infoEmail,
            SupabaseService.email ?? t.loading,
          ),
          _line(),
          _row(t, Icons.event_available_outlined, t.infoJoined, joined),
        ],
      ),
    );
  }

  Widget _row(L t, IconData icon, String label, String value) {
    return SizedBox(
      height: 54,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line() => Divider(height: 1, color: AppColors.divider);
}

/// 编辑：昵称 + 签名 + 性别，一次改完
class _EditDialog extends StatefulWidget {
  const _EditDialog({required this.store, required this.user});

  final AppStore store;
  final UserAccount user;

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  late final _nick = TextEditingController(text: widget.user.nickname);
  late final _sig = TextEditingController(text: widget.store.signature ?? '');
  late int _gender = widget.user.gender.clamp(0, 3);

  @override
  void dispose() {
    _nick.dispose();
    _sig.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return AlertDialog(
      title: Text(t.editProfile),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nick,
              decoration: InputDecoration(labelText: t.fieldNickname),
              maxLength: 16,
            ),
            const SizedBox(height: 4),
            TextField(
              controller: _sig,
              decoration: InputDecoration(
                labelText: t.fieldSignature,
                hintText: t.signatureHint,
              ),
              maxLength: 40,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (var i = 0; i < 4; i++)
                  ChoiceChip(
                    label: Text(
                      ['未设置', '男', '女', '保密'][i],
                      style: const TextStyle(fontSize: 12.5),
                    ),
                    selected: _gender == i,
                    onSelected: (_) => setState(() => _gender = i),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        TextButton(
          onPressed: () async {
            await widget.store.updateProfile(
              nickname: _nick.text,
              signature: _sig.text,
              gender: _gender,
            );
            if (!context.mounted) return;
            Navigator.pop(context);
          },
          child: Text(t.save),
        ),
      ],
    );
  }
}
