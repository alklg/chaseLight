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
}
