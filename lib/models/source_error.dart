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

/// 导入 / 校验源配置时的失败类别，文案同样由界面翻译。
enum ImportErr {
  empty,
  jsonSyntax,
  noSources,
  sourceAt,
  domainEmpty,
  notUrl,
  domainBad,
}

class ImportException implements Exception {
  const ImportException(this.code, {this.message, this.index});

  final ImportErr code;

  /// 具体原因（JSON 解析器或单条源校验给出的原文），附在译好的文案后面
  final String? message;

  /// 第几个源出错，从 1 开始
  final int? index;

  @override
  String toString() => message ?? code.name;
}
