import 'package:flutter/material.dart';

/// 本地账号。没有密码：一台手机上的几个身份，用来区分「谁在看」。
///
/// 真要跨设备同步才需要真正的认证，那是接后端以后的事，
/// 这里先把身份和界面立起来，数据模型到时候直接复用。
class UserAccount {
  const UserAccount({
    required this.id,
    required this.nickname,
    required this.colorValue,
    required this.createdAt,
    this.gender = 0,
    this.birthday,
    this.avatarName,
    this.coverName,
  });

  final String id;
  final String nickname;

  /// 头像就用一个纯色圆底 + 首字，省掉上传头像那一整套
  final int colorValue;
  final DateTime createdAt;

  /// 0 未设置 / 1 男 / 2 女 / 3 保密
  final int gender;
  final String? birthday;

  /// 头像图 / 背景图在文档目录里的文件名（不存绝对路径，iOS 更新会换容器）
  final String? avatarName;
  final String? coverName;

  Color get color => Color(colorValue);

  String get initial {
    final t = nickname.trim();
    return t.isEmpty ? '?' : t.characters.first;
  }

  factory UserAccount.fromJson(Map<String, dynamic> j) => UserAccount(
    id: j['id'] as String? ?? '',
    nickname: j['nickname'] as String? ?? '',
    colorValue: (j['color'] as num?)?.toInt() ?? 0xFF4C8DFF,
    gender: (j['gender'] as num?)?.toInt() ?? 0,
    birthday: j['birthday'] as String?,
    avatarName: j['avatar'] as String?,
    coverName: j['cover'] as String?,
    createdAt:
        DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nickname': nickname,
    'color': colorValue,
    if (gender != 0) 'gender': gender,
    if (birthday != null) 'birthday': birthday,
    if (avatarName != null) 'avatar': avatarName,
    if (coverName != null) 'cover': coverName,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// 可选的头像色，都是主题里出现过的那几支
const kAvatarColors = <int>[
  0xFF4C8DFF,
  0xFF35B98A,
  0xFFE8734A,
  0xFFB06CF0,
  0xFFE0A32E,
  0xFF3FA9D6,
  0xFFE05575,
  0xFF6F7BF7,
];
