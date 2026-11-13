import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of L
/// returned by `L.of(context)`.
///
/// Applications need to include `L.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: L.localizationsDelegates,
///   supportedLocales: L.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the L.supportedLocales
/// property.
abstract class L {
  L(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static L? of(BuildContext context) {
    return Localizations.of<L>(context, L);
  }

  static const LocalizationsDelegate<L> delegate = _LDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// No description provided for @appName.
  ///
  /// In zh, this message translates to:
  /// **'追光'**
  String get appName;

  /// No description provided for @tabVideo.
  ///
  /// In zh, this message translates to:
  /// **'追剧'**
  String get tabVideo;

  /// No description provided for @tabNovel.
  ///
  /// In zh, this message translates to:
  /// **'看书'**
  String get tabNovel;

  /// No description provided for @searchVideoHint.
  ///
  /// In zh, this message translates to:
  /// **'搜剧名'**
  String get searchVideoHint;

  /// No description provided for @searchNovelHint.
  ///
  /// In zh, this message translates to:
  /// **'搜书名或作者'**
  String get searchNovelHint;

  /// No description provided for @setupSource.
  ///
  /// In zh, this message translates to:
  /// **'先导入一个内容源'**
  String get setupSource;

  /// No description provided for @watching.
  ///
  /// In zh, this message translates to:
  /// **'在追'**
  String get watching;

  /// No description provided for @shelf.
  ///
  /// In zh, this message translates to:
  /// **'书架'**
  String get shelf;

  /// No description provided for @emptyVideoTitle.
  ///
  /// In zh, this message translates to:
  /// **'还没有在追的剧'**
  String get emptyVideoTitle;

  /// No description provided for @emptyVideoBody.
  ///
  /// In zh, this message translates to:
  /// **'搜一个试试，看过会自动记在这里'**
  String get emptyVideoBody;

  /// No description provided for @emptyNovelTitle.
  ///
  /// In zh, this message translates to:
  /// **'书架还空着'**
  String get emptyNovelTitle;

  /// No description provided for @emptyNovelBody.
  ///
  /// In zh, this message translates to:
  /// **'搜一本书，读过的会留在这里'**
  String get emptyNovelBody;

  /// No description provided for @searchTitle.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get searchTitle;

  /// No description provided for @searchAction.
  ///
  /// In zh, this message translates to:
  /// **'搜索'**
  String get searchAction;

  /// No description provided for @searchEmptyHint.
  ///
  /// In zh, this message translates to:
  /// **'输入关键词，或粘贴详情页地址'**
  String get searchEmptyHint;

  /// No description provided for @browseSource.
  ///
  /// In zh, this message translates to:
  /// **'看看这个源有什么'**
  String get browseSource;

  /// No description provided for @recentSearches.
  ///
  /// In zh, this message translates to:
  /// **'最近搜过'**
  String get recentSearches;

  /// No description provided for @clearAll.
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get clearAll;

  /// No description provided for @settingsTitle.
  ///
  /// In zh, this message translates to:
  /// **'设置'**
  String get settingsTitle;

  /// No description provided for @sectionAppearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get sectionAppearance;

  /// No description provided for @themeColor.
  ///
  /// In zh, this message translates to:
  /// **'主题色'**
  String get themeColor;

  /// No description provided for @wallpaper.
  ///
  /// In zh, this message translates to:
  /// **'壁纸'**
  String get wallpaper;

  /// No description provided for @darkMode.
  ///
  /// In zh, this message translates to:
  /// **'深色模式'**
  String get darkMode;

  /// No description provided for @language.
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// No description provided for @sectionNotify.
  ///
  /// In zh, this message translates to:
  /// **'提醒'**
  String get sectionNotify;

  /// No description provided for @sectionData.
  ///
  /// In zh, this message translates to:
  /// **'数据'**
  String get sectionData;

  /// No description provided for @sectionAbout.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get sectionAbout;

  /// No description provided for @version.
  ///
  /// In zh, this message translates to:
  /// **'版本'**
  String get version;

  /// No description provided for @account.
  ///
  /// In zh, this message translates to:
  /// **'账号'**
  String get account;

  /// No description provided for @localAccount.
  ///
  /// In zh, this message translates to:
  /// **'本机账号'**
  String get localAccount;

  /// No description provided for @accountCount.
  ///
  /// In zh, this message translates to:
  /// **'{count} 个账号'**
  String accountCount(Object count);

  /// No description provided for @addAccount.
  ///
  /// In zh, this message translates to:
  /// **'添加账号'**
  String get addAccount;

  /// No description provided for @profileTitle.
  ///
  /// In zh, this message translates to:
  /// **'交友卡片'**
  String get profileTitle;

  /// No description provided for @statFavorites.
  ///
  /// In zh, this message translates to:
  /// **'收藏'**
  String get statFavorites;

  /// No description provided for @statWatching.
  ///
  /// In zh, this message translates to:
  /// **'在追'**
  String get statWatching;

  /// No description provided for @statDays.
  ///
  /// In zh, this message translates to:
  /// **'天'**
  String get statDays;

  /// No description provided for @infoGender.
  ///
  /// In zh, this message translates to:
  /// **'性别'**
  String get infoGender;

  /// No description provided for @infoBirthday.
  ///
  /// In zh, this message translates to:
  /// **'生日'**
  String get infoBirthday;

  /// No description provided for @infoEmail.
  ///
  /// In zh, this message translates to:
  /// **'邮箱'**
  String get infoEmail;

  /// No description provided for @infoJoined.
  ///
  /// In zh, this message translates to:
  /// **'加入'**
  String get infoJoined;

  /// No description provided for @genderUnset.
  ///
  /// In zh, this message translates to:
  /// **'未设置'**
  String get genderUnset;

  /// No description provided for @genderMale.
  ///
  /// In zh, this message translates to:
  /// **'男'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In zh, this message translates to:
  /// **'女'**
  String get genderFemale;

  /// No description provided for @genderSecret.
  ///
  /// In zh, this message translates to:
  /// **'保密'**
  String get genderSecret;

  /// No description provided for @editProfile.
  ///
  /// In zh, this message translates to:
  /// **'编辑资料'**
  String get editProfile;

  /// No description provided for @fieldNickname.
  ///
  /// In zh, this message translates to:
  /// **'昵称'**
  String get fieldNickname;

  /// No description provided for @fieldSignature.
  ///
  /// In zh, this message translates to:
  /// **'签名'**
  String get fieldSignature;

  /// No description provided for @signatureHint.
  ///
  /// In zh, this message translates to:
  /// **'一句话介绍自己'**
  String get signatureHint;

  /// No description provided for @noSignature.
  ///
  /// In zh, this message translates to:
  /// **'还没写签名'**
  String get noSignature;

  /// No description provided for @empty.
  ///
  /// In zh, this message translates to:
  /// **'未填'**
  String get empty;

  /// No description provided for @save.
  ///
  /// In zh, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In zh, this message translates to:
  /// **'确定'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// No description provided for @done.
  ///
  /// In zh, this message translates to:
  /// **'完成'**
  String get done;

  /// No description provided for @copy.
  ///
  /// In zh, this message translates to:
  /// **'复制'**
  String get copy;

  /// No description provided for @copied.
  ///
  /// In zh, this message translates to:
  /// **'已复制'**
  String get copied;

  /// No description provided for @retry.
  ///
  /// In zh, this message translates to:
  /// **'重试'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In zh, this message translates to:
  /// **'加载中'**
  String get loading;

  /// No description provided for @loginWelcome.
  ///
  /// In zh, this message translates to:
  /// **'欢迎回来'**
  String get loginWelcome;

  /// No description provided for @loginCreate.
  ///
  /// In zh, this message translates to:
  /// **'创建账号'**
  String get loginCreate;

  /// No description provided for @loginSub.
  ///
  /// In zh, this message translates to:
  /// **'登录后自动同步你的追剧与阅读进度'**
  String get loginSub;

  /// No description provided for @signupSub.
  ///
  /// In zh, this message translates to:
  /// **'只需邮箱和密码，昵称之后随时能改'**
  String get signupSub;

  /// No description provided for @login.
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get login;

  /// No description provided for @signup.
  ///
  /// In zh, this message translates to:
  /// **'注册'**
  String get signup;

  /// No description provided for @hintEmail.
  ///
  /// In zh, this message translates to:
  /// **'邮箱地址'**
  String get hintEmail;

  /// No description provided for @hintPassword.
  ///
  /// In zh, this message translates to:
  /// **'登录密码'**
  String get hintPassword;

  /// No description provided for @hintConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认密码'**
  String get hintConfirm;

  /// No description provided for @haveAccount.
  ///
  /// In zh, this message translates to:
  /// **'已经有账号了？'**
  String get haveAccount;

  /// No description provided for @noAccount.
  ///
  /// In zh, this message translates to:
  /// **'还没有账号？'**
  String get noAccount;

  /// No description provided for @toLogin.
  ///
  /// In zh, this message translates to:
  /// **'去登录'**
  String get toLogin;

  /// No description provided for @toSignup.
  ///
  /// In zh, this message translates to:
  /// **'注册一个'**
  String get toSignup;

  /// No description provided for @errEmail.
  ///
  /// In zh, this message translates to:
  /// **'邮箱格式不对'**
  String get errEmail;

  /// No description provided for @errPasswordShort.
  ///
  /// In zh, this message translates to:
  /// **'密码至少 6 位'**
  String get errPasswordShort;

  /// No description provided for @errPasswordMismatch.
  ///
  /// In zh, this message translates to:
  /// **'两次密码不一致'**
  String get errPasswordMismatch;

  /// No description provided for @errNeedVerify.
  ///
  /// In zh, this message translates to:
  /// **'账号已创建，去邮箱点确认链接后再登录'**
  String get errNeedVerify;

  /// No description provided for @cloudSync.
  ///
  /// In zh, this message translates to:
  /// **'登录以同步'**
  String get cloudSync;

  /// No description provided for @cloudOn.
  ///
  /// In zh, this message translates to:
  /// **'已连接云端'**
  String get cloudOn;

  /// No description provided for @cloudOffHint.
  ///
  /// In zh, this message translates to:
  /// **'收藏和进度跟着账号走，换设备也能拿回来'**
  String get cloudOffHint;

  /// No description provided for @signOut.
  ///
  /// In zh, this message translates to:
  /// **'退出'**
  String get signOut;

  /// No description provided for @langZh.
  ///
  /// In zh, this message translates to:
  /// **'简体中文'**
  String get langZh;

  /// No description provided for @langEn.
  ///
  /// In zh, this message translates to:
  /// **'English'**
  String get langEn;

  /// No description provided for @wallpaperTitle.
  ///
  /// In zh, this message translates to:
  /// **'壁纸'**
  String get wallpaperTitle;

  /// No description provided for @fromGallery.
  ///
  /// In zh, this message translates to:
  /// **'从相册选'**
  String get fromGallery;

  /// No description provided for @builtin.
  ///
  /// In zh, this message translates to:
  /// **'内置'**
  String get builtin;

  /// No description provided for @sourceTitle.
  ///
  /// In zh, this message translates to:
  /// **'内容源'**
  String get sourceTitle;

  /// No description provided for @sourceAdd.
  ///
  /// In zh, this message translates to:
  /// **'添加源'**
  String get sourceAdd;

  /// No description provided for @sourceEmpty.
  ///
  /// In zh, this message translates to:
  /// **'还没有内容源'**
  String get sourceEmpty;

  /// No description provided for @detailContinue.
  ///
  /// In zh, this message translates to:
  /// **'继续'**
  String get detailContinue;

  /// No description provided for @detailStart.
  ///
  /// In zh, this message translates to:
  /// **'从第一集开始'**
  String get detailStart;

  /// No description provided for @inShelf.
  ///
  /// In zh, this message translates to:
  /// **'已加入书架'**
  String get inShelf;

  /// No description provided for @removed.
  ///
  /// In zh, this message translates to:
  /// **'已移出'**
  String get removed;

  /// No description provided for @appearance.
  ///
  /// In zh, this message translates to:
  /// **'外观'**
  String get appearance;

  /// No description provided for @darkNow.
  ///
  /// In zh, this message translates to:
  /// **'当前是深色'**
  String get darkNow;

  /// No description provided for @lightNow.
  ///
  /// In zh, this message translates to:
  /// **'当前是浅色'**
  String get lightNow;

  /// No description provided for @galleryImage.
  ///
  /// In zh, this message translates to:
  /// **'相册图片'**
  String get galleryImage;

  /// No description provided for @builtinWallpaper.
  ///
  /// In zh, this message translates to:
  /// **'内置壁纸'**
  String get builtinWallpaper;

  /// No description provided for @defaultGlow.
  ///
  /// In zh, this message translates to:
  /// **'默认光晕'**
  String get defaultGlow;

  /// No description provided for @sourceManage.
  ///
  /// In zh, this message translates to:
  /// **'源管理'**
  String get sourceManage;

  /// No description provided for @noSourceImported.
  ///
  /// In zh, this message translates to:
  /// **'还没有导入'**
  String get noSourceImported;

  /// No description provided for @reading.
  ///
  /// In zh, this message translates to:
  /// **'阅读'**
  String get reading;

  /// No description provided for @others.
  ///
  /// In zh, this message translates to:
  /// **'其他'**
  String get others;

  /// No description provided for @clearHistory.
  ///
  /// In zh, this message translates to:
  /// **'清除搜索历史'**
  String get clearHistory;

  /// No description provided for @noRecord.
  ///
  /// In zh, this message translates to:
  /// **'没有记录'**
  String get noRecord;

  /// No description provided for @historyCleared.
  ///
  /// In zh, this message translates to:
  /// **'搜索历史已清空'**
  String get historyCleared;

  /// No description provided for @about.
  ///
  /// In zh, this message translates to:
  /// **'关于'**
  String get about;

  /// No description provided for @sourceRules.
  ///
  /// In zh, this message translates to:
  /// **'源规则'**
  String get sourceRules;

  /// No description provided for @sourceRulesHint.
  ///
  /// In zh, this message translates to:
  /// **'纯 JSON 配置，可导出分享'**
  String get sourceRulesHint;

  /// No description provided for @counting.
  ///
  /// In zh, this message translates to:
  /// **'统计中…'**
  String get counting;

  /// No description provided for @noCache.
  ///
  /// In zh, this message translates to:
  /// **'还没有缓存'**
  String get noCache;

  /// No description provided for @clearNovelCache.
  ///
  /// In zh, this message translates to:
  /// **'清除小说缓存？'**
  String get clearNovelCache;

  /// No description provided for @clearNovelCacheBody.
  ///
  /// In zh, this message translates to:
  /// **'缓存的章节全部删掉，阅读进度保留。之后需要重新联网抓。'**
  String get clearNovelCacheBody;

  /// No description provided for @clear.
  ///
  /// In zh, this message translates to:
  /// **'清除'**
  String get clear;

  /// No description provided for @cacheCleared.
  ///
  /// In zh, this message translates to:
  /// **'缓存已清除'**
  String get cacheCleared;

  /// No description provided for @novelCache.
  ///
  /// In zh, this message translates to:
  /// **'小说缓存'**
  String get novelCache;

  /// No description provided for @clearing.
  ///
  /// In zh, this message translates to:
  /// **'清理中…'**
  String get clearing;

  /// No description provided for @edit.
  ///
  /// In zh, this message translates to:
  /// **'编辑'**
  String get edit;

  /// No description provided for @cover.
  ///
  /// In zh, this message translates to:
  /// **'背景'**
  String get cover;

  /// No description provided for @copiedId.
  ///
  /// In zh, this message translates to:
  /// **'已复制 ID'**
  String get copiedId;

  /// No description provided for @deviceAccounts.
  ///
  /// In zh, this message translates to:
  /// **'这台设备上的账号'**
  String get deviceAccounts;

  /// No description provided for @deviceAccountsNote.
  ///
  /// In zh, this message translates to:
  /// **'账号只存在这台设备上，没有密码也不同步。\\n真要做跨设备同步，得接后端——那时候这个界面不用改。'**
  String get deviceAccountsNote;

  /// No description provided for @rename.
  ///
  /// In zh, this message translates to:
  /// **'改名'**
  String get rename;

  /// No description provided for @deleteAccount.
  ///
  /// In zh, this message translates to:
  /// **'删除这个账号'**
  String get deleteAccount;

  /// No description provided for @newAccount.
  ///
  /// In zh, this message translates to:
  /// **'新建账号'**
  String get newAccount;

  /// No description provided for @deleteAccountTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除账号'**
  String get deleteAccountTitle;

  /// No description provided for @accountRemovedNote.
  ///
  /// In zh, this message translates to:
  /// **'会被移出这台设备。收藏和进度不受影响。'**
  String get accountRemovedNote;

  /// No description provided for @joinedOn.
  ///
  /// In zh, this message translates to:
  /// **'加入于'**
  String get joinedOn;

  /// No description provided for @kindVideo.
  ///
  /// In zh, this message translates to:
  /// **'影视'**
  String get kindVideo;

  /// No description provided for @kindNovel.
  ///
  /// In zh, this message translates to:
  /// **'小说'**
  String get kindNovel;

  /// No description provided for @searchBookHint.
  ///
  /// In zh, this message translates to:
  /// **'搜书名'**
  String get searchBookHint;

  /// No description provided for @browseHint2.
  ///
  /// In zh, this message translates to:
  /// **'看看这个源有什么'**
  String get browseHint2;

  /// No description provided for @searchNoResult.
  ///
  /// In zh, this message translates to:
  /// **'这个源没有结果'**
  String get searchNoResult;

  /// No description provided for @failed.
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get failed;

  /// No description provided for @pressEnterToSearch.
  ///
  /// In zh, this message translates to:
  /// **'回车开始搜索'**
  String get pressEnterToSearch;

  /// No description provided for @searchingAll.
  ///
  /// In zh, this message translates to:
  /// **'正在各个源里搜…'**
  String get searchingAll;

  /// No description provided for @openWeb.
  ///
  /// In zh, this message translates to:
  /// **'打开网页'**
  String get openWeb;

  /// No description provided for @continueRead.
  ///
  /// In zh, this message translates to:
  /// **'继续读'**
  String get continueRead;

  /// No description provided for @continueWatch.
  ///
  /// In zh, this message translates to:
  /// **'继续看'**
  String get continueWatch;

  /// No description provided for @catalog.
  ///
  /// In zh, this message translates to:
  /// **'目录'**
  String get catalog;

  /// No description provided for @episodes.
  ///
  /// In zh, this message translates to:
  /// **'选集'**
  String get episodes;

  /// No description provided for @ascending.
  ///
  /// In zh, this message translates to:
  /// **'正序'**
  String get ascending;

  /// No description provided for @descending.
  ///
  /// In zh, this message translates to:
  /// **'倒序'**
  String get descending;

  /// No description provided for @openWebDirect.
  ///
  /// In zh, this message translates to:
  /// **'直接开网页'**
  String get openWebDirect;

  /// No description provided for @episodeUnit.
  ///
  /// In zh, this message translates to:
  /// **'集'**
  String get episodeUnit;

  /// No description provided for @chapterUnit.
  ///
  /// In zh, this message translates to:
  /// **'章'**
  String get chapterUnit;

  /// No description provided for @exportAll.
  ///
  /// In zh, this message translates to:
  /// **'导出全部源'**
  String get exportAll;

  /// No description provided for @copiedToClipboard.
  ///
  /// In zh, this message translates to:
  /// **'已复制到剪贴板'**
  String get copiedToClipboard;

  /// No description provided for @onlySearch.
  ///
  /// In zh, this message translates to:
  /// **'仅搜索'**
  String get onlySearch;

  /// No description provided for @supportCatalog.
  ///
  /// In zh, this message translates to:
  /// **'支持目录'**
  String get supportCatalog;

  /// No description provided for @supportEpisodes.
  ///
  /// In zh, this message translates to:
  /// **'支持选集'**
  String get supportEpisodes;

  /// No description provided for @directPlay.
  ///
  /// In zh, this message translates to:
  /// **'直链播放'**
  String get directPlay;

  /// No description provided for @webSniff.
  ///
  /// In zh, this message translates to:
  /// **'网页嗅探'**
  String get webSniff;

  /// No description provided for @deleteSourceQ.
  ///
  /// In zh, this message translates to:
  /// **'删除这个源？'**
  String get deleteSourceQ;

  /// No description provided for @deleteSourceBody.
  ///
  /// In zh, this message translates to:
  /// **'的配置会被移除，观看记录不受影响。'**
  String get deleteSourceBody;

  /// No description provided for @noNovelSource.
  ///
  /// In zh, this message translates to:
  /// **'还没有小说源'**
  String get noNovelSource;

  /// No description provided for @noVideoSource.
  ///
  /// In zh, this message translates to:
  /// **'还没有影视源'**
  String get noVideoSource;

  /// No description provided for @importSource.
  ///
  /// In zh, this message translates to:
  /// **'导入源'**
  String get importSource;

  /// No description provided for @ruleSyntax.
  ///
  /// In zh, this message translates to:
  /// **'规则写法'**
  String get ruleSyntax;

  /// No description provided for @syntaxHint.
  ///
  /// In zh, this message translates to:
  /// **'取值规则统一写成  选择器@属性\nh1                 取文本\na.title@href       取链接\nimg@data-src       取封面\n@text  /  @href    取条目自身的文本或链接\n\nplay.type 为 web 时，播放页交给内置浏览器嗅探真实视频地址；为 direct 时用 play.url 从页面里直接抽 m3u8。'**
  String get syntaxHint;

  /// No description provided for @addSource.
  ///
  /// In zh, this message translates to:
  /// **'添加内容源'**
  String get addSource;

  /// No description provided for @importHint.
  ///
  /// In zh, this message translates to:
  /// **'支持单个对象、数组，或带 sources 字段的对象'**
  String get importHint;

  /// No description provided for @example.
  ///
  /// In zh, this message translates to:
  /// **'示例'**
  String get example;

  /// No description provided for @genReadRule.
  ///
  /// In zh, this message translates to:
  /// **'生成阅读规则'**
  String get genReadRule;

  /// No description provided for @genPlayRule.
  ///
  /// In zh, this message translates to:
  /// **'生成播放规则'**
  String get genPlayRule;

  /// No description provided for @genHint.
  ///
  /// In zh, this message translates to:
  /// **'会按最常见的苹果CMS结构生成搜索、详情和正文规则，加上就能用；哪条抓不到，再用「粘 JSON」把导出的配置改掉。'**
  String get genHint;

  /// No description provided for @processing.
  ///
  /// In zh, this message translates to:
  /// **'处理中…'**
  String get processing;

  /// No description provided for @genAndAdd.
  ///
  /// In zh, this message translates to:
  /// **'生成并添加'**
  String get genAndAdd;

  /// No description provided for @domainHint.
  ///
  /// In zh, this message translates to:
  /// **'填个域名'**
  String get domainHint;

  /// No description provided for @preparePlaying.
  ///
  /// In zh, this message translates to:
  /// **'准备播放…'**
  String get preparePlaying;

  /// No description provided for @somethingWrong.
  ///
  /// In zh, this message translates to:
  /// **'出错了'**
  String get somethingWrong;

  /// No description provided for @capturing.
  ///
  /// In zh, this message translates to:
  /// **'正在捕捉播放地址 · 没反应就点网页里的播放键'**
  String get capturing;

  /// No description provided for @lastChapter.
  ///
  /// In zh, this message translates to:
  /// **'已经是最后一章了'**
  String get lastChapter;

  /// No description provided for @chapterNoContent.
  ///
  /// In zh, this message translates to:
  /// **'这一章没抓到正文'**
  String get chapterNoContent;

  /// No description provided for @chapterRuleHint.
  ///
  /// In zh, this message translates to:
  /// **'源里的 chapter.content 选择器可能对不上这个站'**
  String get chapterRuleHint;

  /// No description provided for @nextChapter.
  ///
  /// In zh, this message translates to:
  /// **'下一章'**
  String get nextChapter;

  /// No description provided for @offline.
  ///
  /// In zh, this message translates to:
  /// **'离线'**
  String get offline;

  /// No description provided for @prevChapter.
  ///
  /// In zh, this message translates to:
  /// **'上一章'**
  String get prevChapter;

  /// No description provided for @bookEnd.
  ///
  /// In zh, this message translates to:
  /// **'全书完'**
  String get bookEnd;

  /// No description provided for @typography.
  ///
  /// In zh, this message translates to:
  /// **'排版'**
  String get typography;

  /// No description provided for @stop.
  ///
  /// In zh, this message translates to:
  /// **'停止'**
  String get stop;

  /// No description provided for @fontSize.
  ///
  /// In zh, this message translates to:
  /// **'字号'**
  String get fontSize;

  /// No description provided for @pageTurn.
  ///
  /// In zh, this message translates to:
  /// **'翻页'**
  String get pageTurn;

  /// No description provided for @pageLeftRight.
  ///
  /// In zh, this message translates to:
  /// **'左右翻页'**
  String get pageLeftRight;

  /// No description provided for @pageScroll.
  ///
  /// In zh, this message translates to:
  /// **'上下滚动'**
  String get pageScroll;

  /// No description provided for @cache.
  ///
  /// In zh, this message translates to:
  /// **'缓存'**
  String get cache;

  /// No description provided for @alreadyOffline.
  ///
  /// In zh, this message translates to:
  /// **'已离线'**
  String get alreadyOffline;

  /// No description provided for @cacheWholeBook.
  ///
  /// In zh, this message translates to:
  /// **'缓存全书'**
  String get cacheWholeBook;

  /// No description provided for @bgColor.
  ///
  /// In zh, this message translates to:
  /// **'底色'**
  String get bgColor;

  /// No description provided for @searchChapter.
  ///
  /// In zh, this message translates to:
  /// **'搜章节名'**
  String get searchChapter;

  /// No description provided for @noMatchingChapter.
  ///
  /// In zh, this message translates to:
  /// **'没有匹配的章节'**
  String get noMatchingChapter;

  /// No description provided for @noEpisodeList.
  ///
  /// In zh, this message translates to:
  /// **'这个源没有解析出章节列表，检查一下 detail.episodes'**
  String get noEpisodeList;

  /// No description provided for @noBrowseRule.
  ///
  /// In zh, this message translates to:
  /// **'这个源没有配置浏览规则'**
  String get noBrowseRule;

  /// No description provided for @noCategoryContent.
  ///
  /// In zh, this message translates to:
  /// **'这个分类下没有内容'**
  String get noCategoryContent;

  /// No description provided for @reachEnd.
  ///
  /// In zh, this message translates to:
  /// **'到底了'**
  String get reachEnd;

  /// No description provided for @accountTitle.
  ///
  /// In zh, this message translates to:
  /// **'账号'**
  String get accountTitle;

  /// No description provided for @noSyncNote.
  ///
  /// In zh, this message translates to:
  /// **'账号只存在这台设备上，没有密码也不同步。\n真要做跨设备同步，得接后端——那时候这个界面不用改。'**
  String get noSyncNote;

  /// No description provided for @accountRemovedNote2.
  ///
  /// In zh, this message translates to:
  /// **'会被移出这台设备。收藏和进度不受影响。'**
  String get accountRemovedNote2;

  /// No description provided for @signOutShort.
  ///
  /// In zh, this message translates to:
  /// **'退出'**
  String get signOutShort;

  /// No description provided for @currentLocation.
  ///
  /// In zh, this message translates to:
  /// **'当前位置'**
  String get currentLocation;

  /// No description provided for @fetchingWeather.
  ///
  /// In zh, this message translates to:
  /// **'正在取天气…'**
  String get fetchingWeather;

  /// No description provided for @changeCity.
  ///
  /// In zh, this message translates to:
  /// **'换城市'**
  String get changeCity;

  /// No description provided for @todayHighLow.
  ///
  /// In zh, this message translates to:
  /// **'今日最高 / 最低'**
  String get todayHighLow;

  /// No description provided for @precipChance.
  ///
  /// In zh, this message translates to:
  /// **'降水概率'**
  String get precipChance;

  /// No description provided for @humidity.
  ///
  /// In zh, this message translates to:
  /// **'湿度'**
  String get humidity;

  /// No description provided for @windSpeed.
  ///
  /// In zh, this message translates to:
  /// **'风速'**
  String get windSpeed;

  /// No description provided for @uvIndex.
  ///
  /// In zh, this message translates to:
  /// **'紫外线指数'**
  String get uvIndex;

  /// No description provided for @weatherSource.
  ///
  /// In zh, this message translates to:
  /// **'数据来自 Open-Meteo，每 30 分钟更新一次'**
  String get weatherSource;

  /// No description provided for @pickCity.
  ///
  /// In zh, this message translates to:
  /// **'选城市'**
  String get pickCity;

  /// No description provided for @useCurrentLocation.
  ///
  /// In zh, this message translates to:
  /// **'使用当前位置'**
  String get useCurrentLocation;

  /// No description provided for @sourceDeletedBook.
  ///
  /// In zh, this message translates to:
  /// **'这本书的源已经被删掉了'**
  String get sourceDeletedBook;

  /// No description provided for @sourceDeletedVideo.
  ///
  /// In zh, this message translates to:
  /// **'这个剧的源已经被删掉了'**
  String get sourceDeletedVideo;

  /// No description provided for @emptyShelfHint.
  ///
  /// In zh, this message translates to:
  /// **'读过的书会记在这里'**
  String get emptyShelfHint;

  /// No description provided for @emptyWatchingHint.
  ///
  /// In zh, this message translates to:
  /// **'看过的剧会记在这里'**
  String get emptyWatchingHint;

  /// No description provided for @noSourceConfigured.
  ///
  /// In zh, this message translates to:
  /// **'未配置源'**
  String get noSourceConfigured;

  /// No description provided for @restoreDefault.
  ///
  /// In zh, this message translates to:
  /// **'恢复默认'**
  String get restoreDefault;

  /// No description provided for @currentGalleryImage.
  ///
  /// In zh, this message translates to:
  /// **'当前：相册图片'**
  String get currentGalleryImage;

  /// No description provided for @pickFromGallery.
  ///
  /// In zh, this message translates to:
  /// **'从相册选一张'**
  String get pickFromGallery;

  /// No description provided for @useOwnPhoto.
  ///
  /// In zh, this message translates to:
  /// **'用自己的照片当背景'**
  String get useOwnPhoto;

  /// No description provided for @wallpaperNote.
  ///
  /// In zh, this message translates to:
  /// **'内置壁纸都是代码画的，不占包体。卡片会透出壁纸的颜色，阅读器和播放器不受影响。'**
  String get wallpaperNote;

  /// No description provided for @srcTimeout.
  ///
  /// In zh, this message translates to:
  /// **'请求超时，检查网络或换个源'**
  String get srcTimeout;

  /// No description provided for @srcNetwork.
  ///
  /// In zh, this message translates to:
  /// **'网络错误，稍后再试'**
  String get srcNetwork;

  /// No description provided for @srcNoBrowseRule.
  ///
  /// In zh, this message translates to:
  /// **'这个源没有配置浏览规则'**
  String get srcNoBrowseRule;

  /// No description provided for @errSearchList.
  ///
  /// In zh, this message translates to:
  /// **'源缺少 search.list：需要一个能匹配每条结果的 CSS 选择器'**
  String get errSearchList;

  /// No description provided for @errSearchName.
  ///
  /// In zh, this message translates to:
  /// **'源缺少 search.name：例如 \".title@text\"'**
  String get errSearchName;

  /// No description provided for @errEpisodes.
  ///
  /// In zh, this message translates to:
  /// **'源缺少 detail.episodes：例如 \".play-list a\"'**
  String get errEpisodes;

  /// No description provided for @errBrowseList.
  ///
  /// In zh, this message translates to:
  /// **'源缺少 browse.list'**
  String get errBrowseList;

  /// No description provided for @errBrowseName.
  ///
  /// In zh, this message translates to:
  /// **'源缺少 browse.name'**
  String get errBrowseName;

  /// No description provided for @errName.
  ///
  /// In zh, this message translates to:
  /// **'源缺少 name 字段'**
  String get errName;

  /// No description provided for @errBaseUrl.
  ///
  /// In zh, this message translates to:
  /// **'源缺少 baseUrl 字段'**
  String get errBaseUrl;

  /// No description provided for @errSearch.
  ///
  /// In zh, this message translates to:
  /// **'源缺少 search 字段'**
  String get errSearch;

  /// No description provided for @errKw.
  ///
  /// In zh, this message translates to:
  /// **'searchUrl 里要用 kw 占位标记关键词位置'**
  String get errKw;
}

class _LDelegate extends LocalizationsDelegate<L> {
  const _LDelegate();

  @override
  Future<L> load(Locale locale) {
    return SynchronousFuture<L>(lookupL(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_LDelegate old) => false;
}

L lookupL(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return LEn();
    case 'zh':
      return LZh();
  }

  throw FlutterError(
    'L.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
