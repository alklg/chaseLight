import 'package:flutter/cupertino.dart';

import '../theme/app_theme.dart';

/// iOS 风格的确认弹窗。返回 true 表示用户点了确认。
Future<bool> showIosConfirm(
  BuildContext context, {
  required String title,
  String? message,
  String cancel = '取消',
  required String confirm,
  bool destructive = false,
}) async {
  final ok = await showCupertinoDialog<bool>(
    context: context,
    builder: (ctx) => CupertinoTheme(
      data: CupertinoThemeData(
        brightness: AppColors.isDark ? Brightness.dark : Brightness.light,
        primaryColor: AppColors.primary,
      ),
      child: CupertinoAlertDialog(
        title: Text(title),
        content: message == null ? null : Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancel),
          ),
          CupertinoDialogAction(
            isDestructiveAction: destructive,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirm),
          ),
        ],
      ),
    ),
  );
  return ok ?? false;
}
