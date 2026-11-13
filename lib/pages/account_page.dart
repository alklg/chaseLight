import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/user_account.dart';
import '../services/store.dart';
import '../services/supabase_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_card.dart';
import '../widgets/ios_dialog.dart';

/// 账号。全云之后本机只有一份身份，就是当前登录的 Supabase 账号。
class AccountPage extends StatelessWidget {
  const AccountPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    final me = context.watch<AppStore>().currentUser;

    return AppBackground(
      child: Scaffold(
        appBar: AppBar(title: Text(t.accountTitle)),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            8,
            20,
            24 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          children: [
            const _CloudCard(),
            if (me != null) ...[const SizedBox(height: 22), _MeCard(user: me)],
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                t.cloudAccountNote,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.7,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(height: 26),
            Center(
              child: TextButton(
                onPressed: me == null ? null : () => _deleteAccount(context),
                child: Text(
                  t.deleteAccount,
                  style: TextStyle(fontSize: 13, color: AppColors.danger),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final t = L.of(context)!;
    final ok = await showIosConfirm(
      context,
      title: t.deleteAccountQ,
      message: t.deleteAccountBody,
      confirm: t.deleteAccount,
      destructive: true,
    );
    if (!ok) return;
    try {
      await SupabaseService.deleteAccount();
      await SupabaseService.signOut();
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.deleteAccountFailed)));
    }
  }
}

/// 云账号：邮箱 + 退出
class _CloudCard extends StatelessWidget {
  const _CloudCard();

  @override
  Widget build(BuildContext context) {
    final t = L.of(context)!;
    final signedIn = SupabaseService.signedIn;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
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
          if (signedIn)
            GestureDetector(
              onTap: () => SupabaseService.signOut(),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  t.signOutShort,
                  style: TextStyle(fontSize: 12.5, color: AppColors.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 当前身份：头像 + 昵称 + 加入时间
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
                  t.joinedOnDate(
                    '${user.createdAt.year}-'
                    '${user.createdAt.month.toString().padLeft(2, '0')}-'
                    '${user.createdAt.day.toString().padLeft(2, '0')}',
                  ),
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.user, required this.size});

  final UserAccount user;
  final double size;

  @override
  Widget build(BuildContext context) {
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
