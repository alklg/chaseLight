// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class LEn extends L {
  LEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Chase Light';

  @override
  String get tabVideo => 'Shows';

  @override
  String get tabNovel => 'Books';

  @override
  String get searchVideoHint => 'Search shows';

  @override
  String get searchNovelHint => 'Search title or author';

  @override
  String get setupSource => 'Add a content source';

  @override
  String get watching => 'Watching';

  @override
  String get shelf => 'Shelf';

  @override
  String get emptyVideoTitle => 'Nothing in progress';

  @override
  String get emptyVideoBody =>
      'Search for something — what you watch gets saved here';

  @override
  String get emptyNovelTitle => 'Shelf is empty';

  @override
  String get emptyNovelBody => 'Search for a book — what you read stays here';

  @override
  String get searchTitle => 'Search';

  @override
  String get searchAction => 'Search';

  @override
  String get searchEmptyHint => 'Type a keyword, or paste a detail page URL';

  @override
  String get browseSource => 'Browse this source';

  @override
  String get recentSearches => 'Recent';

  @override
  String get clearAll => 'Clear';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get sectionAppearance => 'Appearance';

  @override
  String get themeColor => 'Accent';

  @override
  String get wallpaper => 'Wallpaper';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get language => 'Language';

  @override
  String get sectionNotify => 'Notifications';

  @override
  String get sectionData => 'Data';

  @override
  String get sectionAbout => 'About';

  @override
  String get version => 'Version';

  @override
  String get account => 'Account';

  @override
  String get localAccount => 'Local account';

  @override
  String accountCount(Object count) {
    return '$count accounts';
  }

  @override
  String get addAccount => 'Add account';

  @override
  String get profileTitle => 'Profile card';

  @override
  String get statFavorites => 'Saved';

  @override
  String get statWatching => 'Watching';

  @override
  String get statDays => 'Days';

  @override
  String get infoGender => 'Gender';

  @override
  String get infoBirthday => 'Birthday';

  @override
  String get infoEmail => 'Email';

  @override
  String get infoJoined => 'Joined';

  @override
  String get genderUnset => 'Not set';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get genderSecret => 'Private';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get fieldNickname => 'Nickname';

  @override
  String get fieldSignature => 'Bio';

  @override
  String get signatureHint => 'One line about you';

  @override
  String get noSignature => 'No bio yet';

  @override
  String get empty => 'Not set';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get confirm => 'OK';

  @override
  String get delete => 'Delete';

  @override
  String get done => 'Done';

  @override
  String get copy => 'Copy';

  @override
  String get copied => 'Copied';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading';

  @override
  String get loginWelcome => 'Welcome back';

  @override
  String get loginCreate => 'Create account';

  @override
  String get loginSub => 'Sign in to sync your shows and reading progress';

  @override
  String get signupSub =>
      'Email and password is all — nickname can change anytime';

  @override
  String get login => 'Sign in';

  @override
  String get signup => 'Sign up';

  @override
  String get hintEmail => 'Email address';

  @override
  String get hintPassword => 'Password';

  @override
  String get hintConfirm => 'Confirm password';

  @override
  String get haveAccount => 'Already have an account?';

  @override
  String get noAccount => 'No account yet?';

  @override
  String get toLogin => 'Sign in';

  @override
  String get toSignup => 'Sign up';

  @override
  String get errEmail => 'That email doesn\'t look right';

  @override
  String get errPasswordShort => 'Password needs at least 6 characters';

  @override
  String get errPasswordMismatch => 'Passwords don\'t match';

  @override
  String get errNeedVerify =>
      'Account created — confirm your email, then sign in';

  @override
  String get cloudSync => 'Sign in to sync';

  @override
  String get cloudOn => 'Cloud connected';

  @override
  String get cloudOffHint => 'Favorites and progress follow your account';

  @override
  String get signOut => 'Sign out';

  @override
  String get langZh => '简体中文';

  @override
  String get langEn => 'English';

  @override
  String get wallpaperTitle => 'Wallpaper';

  @override
  String get fromGallery => 'From library';

  @override
  String get builtin => 'Built-in';

  @override
  String get sourceTitle => 'Sources';

  @override
  String get sourceAdd => 'Add source';

  @override
  String get sourceEmpty => 'No sources yet';

  @override
  String get detailContinue => 'Continue';

  @override
  String get detailStart => 'Start from episode one';

  @override
  String get inShelf => 'Added to shelf';

  @override
  String get removed => 'Removed';

  @override
  String get appearance => 'Appearance';

  @override
  String get darkNow => 'Dark right now';

  @override
  String get lightNow => 'Light right now';

  @override
  String get galleryImage => 'From library';

  @override
  String get builtinWallpaper => 'Built-in';

  @override
  String get defaultGlow => 'Default glow';

  @override
  String get sourceManage => 'Manage sources';

  @override
  String get noSourceImported => 'None imported';

  @override
  String get reading => 'Reading';

  @override
  String get others => 'Others';

  @override
  String get clearHistory => 'Clear search history';

  @override
  String get noRecord => 'No records';

  @override
  String get historyCleared => 'Search history cleared';

  @override
  String get about => 'About';

  @override
  String get sourceRules => 'Source rules';

  @override
  String get sourceRulesHint => 'Plain JSON config, exportable';

  @override
  String get counting => 'Counting…';

  @override
  String get noCache => 'No cache yet';

  @override
  String get clearNovelCache => 'Clear novel cache?';

  @override
  String get clearNovelCacheBody =>
      'Cached chapters will be deleted. Reading progress is kept. You\'ll need network to fetch again.';

  @override
  String get clear => 'Clear';

  @override
  String get cacheCleared => 'Cache cleared';

  @override
  String get novelCache => 'Novel cache';

  @override
  String get clearing => 'Clearing…';

  @override
  String get edit => 'Edit';

  @override
  String get cover => 'Cover';

  @override
  String get copiedId => 'ID copied';

  @override
  String get deviceAccounts => 'Accounts on this device';

  @override
  String get deviceAccountsNote =>
      'Accounts live on this device only — no password, no sync.\\nReal cross-device sync needs a backend; this screen won\'t change when it comes.';

  @override
  String get rename => 'Rename';

  @override
  String get deleteAccount => 'Delete this account';

  @override
  String get newAccount => 'New account';

  @override
  String get deleteAccountTitle => 'Delete account';

  @override
  String get accountRemovedNote =>
      'will be removed from this device. Favorites and progress are kept.';

  @override
  String get joinedOn => 'Joined';

  @override
  String get kindVideo => 'Shows';

  @override
  String get kindNovel => 'Books';

  @override
  String get searchBookHint => 'Search books';

  @override
  String get browseHint2 => 'See what\'s in this source';

  @override
  String get searchNoResult => 'Nothing in this source';

  @override
  String get failed => 'Failed';

  @override
  String get pressEnterToSearch => 'Press enter to search';

  @override
  String get searchingAll => 'Searching all sources…';

  @override
  String get openWeb => 'Open in browser';

  @override
  String get continueRead => 'Keep reading';

  @override
  String get continueWatch => 'Keep watching';

  @override
  String get catalog => 'Contents';

  @override
  String get episodes => 'Episodes';

  @override
  String get ascending => 'Oldest first';

  @override
  String get descending => 'Newest first';

  @override
  String get openWebDirect => 'Open in browser';

  @override
  String get episodeUnit => 'ep';

  @override
  String get chapterUnit => 'ch';

  @override
  String get exportAll => 'Export all sources';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String get onlySearch => 'Search only';

  @override
  String get supportCatalog => 'Catalog';

  @override
  String get supportEpisodes => 'Episodes';

  @override
  String get directPlay => 'Direct stream';

  @override
  String get webSniff => 'Web sniff';

  @override
  String get deleteSourceQ => 'Delete this source?';

  @override
  String get deleteSourceBody =>
      'config will be removed. Watch history is kept.';

  @override
  String get noNovelSource => 'No book sources yet';

  @override
  String get noVideoSource => 'No show sources yet';

  @override
  String get importSource => 'Import source';

  @override
  String get ruleSyntax => 'Rule syntax';

  @override
  String get syntaxHint =>
      'Rules are written as  selector@attr\nh1                 text\na.title@href       link\nimg@data-src       cover\n@text  /  @href    the item\'s own text or link\n\nWhen play.type is web, the player page is handed to the in-app browser to sniff the real video URL; when direct, play.url is used to extract m3u8 from the page.';

  @override
  String get addSource => 'Add source';

  @override
  String get importHint =>
      'Accepts a single object, an array, or an object with a sources field';

  @override
  String get example => 'Example';

  @override
  String get genReadRule => 'Generate reading rules';

  @override
  String get genPlayRule => 'Generate playback rules';

  @override
  String get genHint =>
      'Generates search, detail and content rules for the common MacCMS layout — add it and it works. If a rule misses, paste the exported JSON and fix it.';

  @override
  String get processing => 'Working…';

  @override
  String get genAndAdd => 'Generate and add';

  @override
  String get domainHint => 'Enter a domain';

  @override
  String get preparePlaying => 'Preparing…';

  @override
  String get somethingWrong => 'Something went wrong';

  @override
  String get capturing =>
      'Capturing stream URL · if nothing happens, tap play in the page';

  @override
  String get lastChapter => 'This is the last chapter';

  @override
  String get chapterNoContent => 'No text captured for this chapter';

  @override
  String get chapterRuleHint =>
      'The source\'s chapter.content selector may not match this site';

  @override
  String get nextChapter => 'Next';

  @override
  String get offline => 'Offline';

  @override
  String get prevChapter => 'Previous';

  @override
  String get bookEnd => 'The End';

  @override
  String get typography => 'Typography';

  @override
  String get stop => 'Stop';

  @override
  String get fontSize => 'Text size';

  @override
  String get pageTurn => 'Paging';

  @override
  String get pageLeftRight => 'Swipe left/right';

  @override
  String get pageScroll => 'Scroll';

  @override
  String get cache => 'Cache';

  @override
  String get alreadyOffline => 'Saved offline';

  @override
  String get cacheWholeBook => 'Cache whole book';

  @override
  String get bgColor => 'Background';

  @override
  String get searchChapter => 'Search chapters';

  @override
  String get noMatchingChapter => 'No matching chapters';

  @override
  String get noEpisodeList =>
      'This source didn\'t return a chapter list — check detail.episodes';
}
