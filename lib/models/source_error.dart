/// 源相关的失败类别。数据层只给类别，文案交给界面翻译。
enum SrcErr {
  timeout,
  network,
  noBrowseRule,
  missingSearchList,
  missingSearchName,
  missingEpisodes,
  missingBrowseList,
  missingBrowseName,
  missingName,
  missingBaseUrl,
  missingSearch,
  missingKw,
}

class SourceException implements Exception {
  const SourceException(this.message, {this.code});

  /// 兜底文案（中文）。有 code 时界面优先翻译。
  final String message;
  final SrcErr? code;

  @override
  String toString() => message;
}
