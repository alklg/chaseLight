import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/user_account.dart';
import '../services/store.dart';
import '../services/supabase_service.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card.dart';
import 'login_page.dart';

/// 账号。本机上的几个身份，用来区分「谁在看」。
class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    final store = context.watch<AppStore>();
    final me = store.currentUser;

    return AppBackground(
      child: Scaffold(
        appBar: AppBar(title: Text(t.accountTitle)),
        body: ListView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            _CloudCard(onChanged: () => setState(() {})),
            const SizedBox(height: 22),
            if (me != null) _MeCard(user: me),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                t.deviceAccounts,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            for (final u in store.users) ...[
              _UserRow(
                user: u,
                active: u.id == me?.id,
                onTap: () {
                  HapticFeedback.selectionClick();
                  store.switchUser(u.id);
                },
                onLongPress: () => _showActions(context, store, u),
              ),
              const SizedBox(height: 10),
            ],
            _NewUserTile(onTap: () => _showCreate(context, store)),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                '账号只存在这台设备上，没有密码也不同步。\n'
                '真要做跨设备同步，得接后端——那时候这个界面不用改。',
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

  void _showActions(BuildContext context, AppStore store, UserAccount u) {
    final t = L.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        top: false,
        child: _SheetPad(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ActionRow(
                icon: Icons.edit_outlined,
                label: t.rename,
                onTap: () {
                  Navigator.pop(ctx);
                  _showRename(context, store, u);
                },
              ),
              _ActionRow(
                icon: Icons.delete_outline_rounded,
                label: t.deleteAccount,
                danger: true,
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDelete(context, store, u);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreate(BuildContext context, AppStore store) {
    final t = L.of(context)!;
    showDialog<void>(
      context: context,
      builder: (_) => _UserDialog(
        title: t.newAccount,
        onDone: (name, color) => store.createUser(name, color),
      ),
    );
  }

  void _showRename(BuildContext context, AppStore store, UserAccount u) {
    final t = L.of(context)!;
    showDialog<void>(
      context: context,
      builder: (_) => _UserDialog(
        title: t.rename,
        initialName: u.nickname,
        initialColor: u.colorValue,
        onDone: (name, _) => store.renameUser(u.id, name),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppStore store, UserAccount u) {
    final t = L.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.deleteAccountTitle),
        content: Text('「${u.nickname}」会被移出这台设备。收藏和进度不受影响。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(t.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              store.removeUser(u.id);
            },
            child: Text(t.delete, style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _SheetPad extends StatelessWidget {
  const _SheetPad({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

/// 云同步：没登录时可点去登录，登录后显示邮箱和退出
class _CloudCard extends StatelessWidget {
  const _CloudCard({required this.onChanged});

  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    final signedIn = SupabaseService.signedIn;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      onTap: () async {
        if (signedIn) {
          await SupabaseService.signOut();
          onChanged();
          return;
        }
        final ok = await Navigator.push<bool>(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
        if (ok == true) onChanged();
      },
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              signedIn ? Icons.cloud_done_outlined : Icons.cloud_outlined,
              size: 19,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  signedIn ? t.cloudOn : t.cloudSync,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  signedIn ? (SupabaseService.email ?? '') : t.cloudOffHint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            signedIn ? t.signOutShort : t.login,
            style: TextStyle(fontSize: 12.5, color: AppColors.primary),
          ),
        ],
      ),
    );
  }
}

class _MeCard extends StatelessWidget {
  const _MeCard({required this.user});

  final UserAccount user;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          _Avatar(user: user, size: 58),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.nickname,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '加入于 ${user.createdAt.year}-${user.createdAt.month.toString().padLeft(2, '0')}-${user.createdAt.day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.active,
    required this.onTap,
    required this.onLongPress,
  });

  final UserAccount user;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      behavior: HitTestBehavior.opaque,
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            _Avatar(user: user, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                user.nickname,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
            ),
            if (active)
              Icon(
                Icons.check_circle_rounded,
                size: 19,
                color: AppColors.primary,
              ),
          ],
        ),
      ),
    );
  }
}

class _NewUserTile extends StatelessWidget {
  const _NewUserTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider, width: 1.2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
            const SizedBox(width: 6),
            Text(
              t.newAccount,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.size});

  final UserAccount user;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: user.color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(
        user.initial,
        style: TextStyle(
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    final color = danger ? AppColors.danger : AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 52,
        child: Row(
          children: [
            const SizedBox(width: 18),
            Icon(icon, size: 19, color: color),
            const SizedBox(width: 12),
            Text(label, style: TextStyle(fontSize: 14.5, color: color)),
          ],
        ),
      ),
    );
  }
}

/// 新建 / 改名共用的对话框：一个昵称输入 + 一排头像色
class _UserDialog extends StatefulWidget {
  const _UserDialog({
    required this.title,
    required this.onDone,
    this.initialName,
    this.initialColor,
  });

  final String title;
  final String? initialName;
  final int? initialColor;
  final void Function(String name, int color) onDone;

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  late final _controller = TextEditingController(
    text: widget.initialName ?? '',
  );
  late int _color = widget.initialColor ?? kAvatarColors.first;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(hintText: t.fieldNickname),
            maxLength: 12,
            onSubmitted: (_) => _done(),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final c in kAvatarColors)
                GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Color(c),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _color == c
                            ? AppColors.textPrimary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        TextButton(onPressed: _done, child: Text(t.save)),
      ],
    );
  }

  void _done() {
    widget.onDone(_controller.text, _color);
    Navigator.pop(context);
  }
}
