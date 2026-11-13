import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_localizations.dart';
import '../models/source_error.dart';

/// 把抓取异常翻译成当前语言。
///
/// 服务层只给错误类别（SrcErr），文案在这里决定，
/// 这样数据层不用知道用户说的是哪国话。
String srcErrText(Object e, L t) {
  if (e is SourceException) {
    switch (e.code) {
      case SrcErr.timeout:
        return t.srcTimeout;
      case SrcErr.network:
        return t.srcNetwork;
      case SrcErr.noBrowseRule:
        return t.srcNoBrowseRule;
      case SrcErr.missingSearchList:
        return t.errSearchList;
      case SrcErr.missingSearchName:
        return t.errSearchName;
      case SrcErr.missingEpisodes:
        return t.errEpisodes;
      case SrcErr.missingBrowseList:
        return t.errBrowseList;
      case SrcErr.missingBrowseName:
        return t.errBrowseName;
      case SrcErr.missingName:
        return t.errName;
      case SrcErr.missingBaseUrl:
        return t.errBaseUrl;
      case SrcErr.missingSearch:
        return t.errSearch;
      case SrcErr.missingKw:
        return t.errKw;
      default:
        return e.message;
    }
  }
  return e.toString();
}

/// 导入源配置时的失败文案。数据层只给类别，具体原因原样附在后面。
String importErrText(Object e, L t) {
  if (e is ImportException) {
    switch (e.code) {
      case ImportErr.empty:
        return t.errImportEmpty;
      case ImportErr.jsonSyntax:
        return t.errImportJson(e.message ?? '');
      case ImportErr.noSources:
        return t.errImportNoSources;
      case ImportErr.sourceAt:
        return t.errImportSourceAt(e.index ?? 0, e.message ?? '');
      case ImportErr.domainEmpty:
        return t.errDomainEmpty;
      case ImportErr.notUrl:
        return t.errNotUrl;
      case ImportErr.domainBad:
        return t.errDomainBad;
    }
  }
  if (e is FormatException) return e.message;
  return e.toString();
}

/// 登录 / 注册失败文案。Supabase 的报错是英文串，按关键字归类。
String authErrText(Object e, L t) {
  if (e is AuthException) {
    final m = e.message.toLowerCase();
    if (m.contains('invalid login credentials')) return t.errBadCredentials;
    if (m.contains('already registered')) return t.errAlreadyRegistered;
    if (m.contains('password should be at least')) return t.errPasswordShort;
    if (m.contains('unable to validate email')) return t.errEmail;
    if (m.contains('email not confirmed')) return t.errEmailUnconfirmed;
    return e.message;
  }
  return e.toString();
}
