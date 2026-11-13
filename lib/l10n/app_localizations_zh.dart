// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class LZh extends L {
  LZh([String locale = 'zh']) : super(locale);

  @override
  String get appName => '追光';

  @override
  String get tabVideo => '追剧';

  @override
  String get tabNovel => '看书';

  @override
  String get searchVideoHint => '搜剧名';

  @override
  String get searchNovelHint => '搜书名或作者';

  @override
  String get setupSource => '先导入一个内容源';

  @override
  String get watching => '在追';

  @override
  String get shelf => '书架';

  @override
  String get emptyVideoTitle => '还没有在追的剧';

  @override
  String get emptyVideoBody => '搜一个试试，看过会自动记在这里';

  @override
  String get emptyNovelTitle => '书架还空着';

  @override
  String get emptyNovelBody => '搜一本书，读过的会留在这里';

  @override
  String get searchTitle => '搜索';

  @override
  String get searchAction => '搜索';

  @override
  String get searchEmptyHint => '输入关键词，或粘贴详情页地址';

  @override
  String get browseSource => '看看这个源有什么';

  @override
  String get recentSearches => '最近搜过';

  @override
  String get clearAll => '清空';

  @override
  String get settingsTitle => '设置';

  @override
  String get sectionAppearance => '外观';

  @override
  String get themeColor => '主题色';

  @override
  String get wallpaper => '壁纸';

  @override
  String get darkMode => '深色模式';

  @override
  String get language => '语言';

  @override
  String get sectionNotify => '提醒';

  @override
  String get sectionData => '数据';

  @override
  String get sectionAbout => '关于';

  @override
  String get version => '版本';

  @override
  String get account => '账号';

  @override
  String get localAccount => '本机账号';

  @override
  String accountCount(Object count) {
    return '$count 个账号';
  }

  @override
  String get addAccount => '添加账号';

  @override
  String get profileTitle => '交友卡片';

  @override
  String get statFavorites => '收藏';

  @override
  String get statWatching => '在追';

  @override
  String get statDays => '天';

  @override
  String get infoGender => '性别';

  @override
  String get infoBirthday => '生日';

  @override
  String get infoEmail => '邮箱';

  @override
  String get infoJoined => '加入';

  @override
  String get genderUnset => '未设置';

  @override
  String get genderMale => '男';

  @override
  String get genderFemale => '女';

  @override
  String get genderSecret => '保密';

  @override
  String get editProfile => '编辑资料';

  @override
  String get fieldNickname => '昵称';

  @override
  String get fieldSignature => '签名';

  @override
  String get signatureHint => '一句话介绍自己';

  @override
  String get noSignature => '还没写签名';

  @override
  String get empty => '未填';

  @override
  String get save => '保存';

  @override
  String get cancel => '取消';

  @override
  String get confirm => '确定';

  @override
  String get delete => '删除';

  @override
  String get done => '完成';

  @override
  String get copy => '复制';

  @override
  String get copied => '已复制';

  @override
  String get retry => '重试';

  @override
  String get loading => '加载中';

  @override
  String get loginWelcome => '欢迎回来';

  @override
  String get loginCreate => '创建账号';

  @override
  String get loginSub => '登录后自动同步你的追剧与阅读进度';

  @override
  String get signupSub => '只需邮箱和密码，昵称之后随时能改';

  @override
  String get login => '登录';

  @override
  String get signup => '注册';

  @override
  String get hintEmail => '邮箱地址';

  @override
  String get hintPassword => '登录密码';

  @override
  String get hintConfirm => '确认密码';

  @override
  String get haveAccount => '已经有账号了？';

  @override
  String get noAccount => '还没有账号？';

  @override
  String get toLogin => '去登录';

  @override
  String get toSignup => '注册一个';

  @override
  String get errEmail => '邮箱格式不对';

  @override
  String get errPasswordShort => '密码至少 6 位';

  @override
  String get errPasswordMismatch => '两次密码不一致';

  @override
  String get errNeedVerify => '账号已创建，去邮箱点确认链接后再登录';

  @override
  String get cloudSync => '登录以同步';

  @override
  String get cloudOn => '已连接云端';

  @override
  String get cloudOffHint => '收藏和进度跟着账号走，换设备也能拿回来';

  @override
  String get signOut => '退出';

  @override
  String get langZh => '简体中文';

  @override
  String get langEn => 'English';

  @override
  String get wallpaperTitle => '壁纸';

  @override
  String get fromGallery => '从相册选';

  @override
  String get builtin => '内置';

  @override
  String get sourceTitle => '内容源';

  @override
  String get sourceAdd => '添加源';

  @override
  String get sourceEmpty => '还没有内容源';

  @override
  String get detailContinue => '继续';

  @override
  String get detailStart => '从第一集开始';

  @override
  String get inShelf => '已加入书架';

  @override
  String get removed => '已移出';

  @override
  String get appearance => '外观';

  @override
  String get darkNow => '当前是深色';

  @override
  String get lightNow => '当前是浅色';

  @override
  String get galleryImage => '相册图片';

  @override
  String get builtinWallpaper => '内置壁纸';

  @override
  String get defaultGlow => '默认光晕';

  @override
  String get sourceManage => '源管理';

  @override
  String get noSourceImported => '还没有导入';

  @override
  String get reading => '阅读';

  @override
  String get others => '其他';

  @override
  String get clearHistory => '清除搜索历史';

  @override
  String get noRecord => '没有记录';

  @override
  String get historyCleared => '搜索历史已清空';

  @override
  String get about => '关于';

  @override
  String get sourceRules => '源规则';

  @override
  String get sourceRulesHint => '纯 JSON 配置，可导出分享';

  @override
  String get counting => '统计中…';

  @override
  String get noCache => '还没有缓存';

  @override
  String get clearNovelCache => '清除小说缓存？';

  @override
  String get clearNovelCacheBody => '缓存的章节全部删掉，阅读进度保留。之后需要重新联网抓。';

  @override
  String get clear => '清除';

  @override
  String get cacheCleared => '缓存已清除';

  @override
  String get novelCache => '小说缓存';

  @override
  String get clearing => '清理中…';

  @override
  String get edit => '编辑';

  @override
  String get cover => '背景';

  @override
  String get copiedId => '已复制 ID';

  @override
  String get deviceAccounts => '这台设备上的账号';

  @override
  String get deviceAccountsNote =>
      '账号只存在这台设备上，没有密码也不同步。\\n真要做跨设备同步，得接后端——那时候这个界面不用改。';

  @override
  String get rename => '改名';

  @override
  String get deleteAccount => '删除这个账号';

  @override
  String get newAccount => '新建账号';

  @override
  String get deleteAccountTitle => '删除账号';

  @override
  String get accountRemovedNote => '会被移出这台设备。收藏和进度不受影响。';

  @override
  String get joinedOn => '加入于';

  @override
  String get kindVideo => '影视';

  @override
  String get kindNovel => '小说';

  @override
  String get searchBookHint => '搜书名';

  @override
  String get browseHint2 => '看看这个源有什么';

  @override
  String get searchNoResult => '这个源没有结果';

  @override
  String get failed => '失败';

  @override
  String get pressEnterToSearch => '回车开始搜索';

  @override
  String get searchingAll => '正在各个源里搜…';

  @override
  String get openWeb => '打开网页';

  @override
  String get continueRead => '继续读';

  @override
  String get continueWatch => '继续看';

  @override
  String get catalog => '目录';

  @override
  String get episodes => '选集';

  @override
  String get ascending => '正序';

  @override
  String get descending => '倒序';

  @override
  String get openWebDirect => '直接开网页';

  @override
  String get episodeUnit => '集';

  @override
  String get chapterUnit => '章';

  @override
  String get exportAll => '导出全部源';

  @override
  String get copiedToClipboard => '已复制到剪贴板';

  @override
  String get onlySearch => '仅搜索';

  @override
  String get supportCatalog => '支持目录';

  @override
  String get supportEpisodes => '支持选集';

  @override
  String get directPlay => '直链播放';

  @override
  String get webSniff => '网页嗅探';

  @override
  String get deleteSourceQ => '删除这个源？';

  @override
  String get deleteSourceBody => '的配置会被移除，观看记录不受影响。';

  @override
  String get noNovelSource => '还没有小说源';

  @override
  String get noVideoSource => '还没有影视源';

  @override
  String get importSource => '导入源';

  @override
  String get ruleSyntax => '规则写法';

  @override
  String get syntaxHint =>
      '取值规则统一写成  选择器@属性\nh1                 取文本\na.title@href       取链接\nimg@data-src       取封面\n@text  /  @href    取条目自身的文本或链接\n\nplay.type 为 web 时，播放页交给内置浏览器嗅探真实视频地址；为 direct 时用 play.url 从页面里直接抽 m3u8。';

  @override
  String get addSource => '添加内容源';

  @override
  String get importHint => '支持单个对象、数组，或带 sources 字段的对象';

  @override
  String get example => '示例';

  @override
  String get genReadRule => '生成阅读规则';

  @override
  String get genPlayRule => '生成播放规则';

  @override
  String get genHint =>
      '会按最常见的苹果CMS结构生成搜索、详情和正文规则，加上就能用；哪条抓不到，再用「粘 JSON」把导出的配置改掉。';

  @override
  String get processing => '处理中…';

  @override
  String get genAndAdd => '生成并添加';

  @override
  String get domainHint => '填个域名';

  @override
  String get preparePlaying => '准备播放…';

  @override
  String get somethingWrong => '出错了';

  @override
  String get capturing => '正在捕捉播放地址 · 没反应就点网页里的播放键';

  @override
  String get lastChapter => '已经是最后一章了';

  @override
  String get chapterNoContent => '这一章没抓到正文';

  @override
  String get chapterRuleHint => '源里的 chapter.content 选择器可能对不上这个站';

  @override
  String get nextChapter => '下一章';

  @override
  String get offline => '离线';

  @override
  String get prevChapter => '上一章';

  @override
  String get bookEnd => '全书完';

  @override
  String get typography => '排版';

  @override
  String get stop => '停止';

  @override
  String get fontSize => '字号';

  @override
  String get pageTurn => '翻页';

  @override
  String get pageLeftRight => '左右翻页';

  @override
  String get pageScroll => '上下滚动';

  @override
  String get cache => '缓存';

  @override
  String get alreadyOffline => '已离线';

  @override
  String get cacheWholeBook => '缓存全书';

  @override
  String get bgColor => '底色';

  @override
  String get searchChapter => '搜章节名';

  @override
  String get noMatchingChapter => '没有匹配的章节';

  @override
  String get noEpisodeList => '这个源没有解析出章节列表，检查一下 detail.episodes';

  @override
  String get noBrowseRule => '这个源没有配置浏览规则';

  @override
  String get noCategoryContent => '这个分类下没有内容';

  @override
  String get reachEnd => '到底了';

  @override
  String get accountTitle => '账号';

  @override
  String get noSyncNote => '账号只存在这台设备上，没有密码也不同步。\n真要做跨设备同步，得接后端——那时候这个界面不用改。';

  @override
  String get accountRemovedNote2 => '会被移出这台设备。收藏和进度不受影响。';

  @override
  String get signOutShort => '退出';

  @override
  String get currentLocation => '当前位置';

  @override
  String get fetchingWeather => '正在取天气…';

  @override
  String get changeCity => '换城市';

  @override
  String get todayHighLow => '今日最高 / 最低';

  @override
  String get precipChance => '降水概率';

  @override
  String get humidity => '湿度';

  @override
  String get windSpeed => '风速';

  @override
  String get uvIndex => '紫外线指数';

  @override
  String get weatherSource => '数据来自 Open-Meteo，每 30 分钟更新一次';

  @override
  String get pickCity => '选城市';

  @override
  String get useCurrentLocation => '使用当前位置';

  @override
  String get sourceDeletedBook => '这本书的源已经被删掉了';

  @override
  String get sourceDeletedVideo => '这个剧的源已经被删掉了';

  @override
  String get emptyShelfHint => '读过的书会记在这里';

  @override
  String get emptyWatchingHint => '看过的剧会记在这里';

  @override
  String get noSourceConfigured => '未配置源';

  @override
  String get restoreDefault => '恢复默认';

  @override
  String get currentGalleryImage => '当前：相册图片';

  @override
  String get pickFromGallery => '从相册选一张';

  @override
  String get useOwnPhoto => '用自己的照片当背景';

  @override
  String get wallpaperNote => '内置壁纸都是代码画的，不占包体。卡片会透出壁纸的颜色，阅读器和播放器不受影响。';
}
