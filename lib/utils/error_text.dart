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
