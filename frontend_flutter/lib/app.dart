import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'models/app_models.dart';
import 'services/app_api_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/update_service.dart';
import 'services/voice/medicohub_voice_service.dart';
import 'theme/app_theme.dart';

const List<String> _accountRoles = <String>['patient', 'doctor', 'admin'];
const List<String> _questionCategories = <String>[
  'Related to my condition',
  'Related to my medications',
  'Related to my test results',
  'General',
];
const List<String> _specialties = <String>[
  'General Health',
  'Neurology',
  'Cardiology',
  'Endocrinology',
  'Pediatrics',
];
const Map<String, String> _languageLocales = <String, String>{
  'English': 'en-US',
  'Arabic': 'ar',
  'French': 'fr-FR',
  'Spanish': 'es-ES',
  'Mandarin': 'zh-CN',
  'Hindi': 'hi-IN',
  'Marathi': 'mr-IN',
  'Tamil': 'ta-IN',
  'Telugu': 'te-IN',
  'Kannada': 'kn-IN',
  'Malayalam': 'ml-IN',
  'Gujarati': 'gu-IN',
  'Bengali': 'bn-IN',
};
const List<String> _adPlacements = <String>['home', 'question', 'education', 'blog'];
const String _androidBannerAdUnitId = 'ca-app-pub-9639630926363418/8715517435';
const String _androidAppOpenAdUnitId = 'ca-app-pub-9639630926363418/3417519336';
const String _iosBannerAdUnitId = 'ca-app-pub-9639630926363418/4253455835';
const String _iosAppOpenAdUnitId = 'ca-app-pub-9639630926363418/8422205095';
const String _androidTestBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
const String _androidTestAppOpenAdUnitId = 'ca-app-pub-3940256099942544/9257395921';
const String _iosTestBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';
const String _iosTestAppOpenAdUnitId = 'ca-app-pub-3940256099942544/5575463023';
const String _brandLightAsset = 'assets/branding/medicohub_we_connect_light.png';
const String _brandDarkAsset = 'assets/branding/medicohub_we_connect_dark.png';
const String _brandIconLightAsset = 'assets/branding/medicohub_icon_light.png';
const String _brandIconDarkAsset = 'assets/branding/medicohub_icon_dark.png';
const Map<String, String> _signInChannelOptions = <String, String>{
  'Email': 'email',
  'United Arab Emirates (+971)': '+971',
  'United States (+1)': '+1',
  'India (+91)': '+91',
  'United Kingdom (+44)': '+44',
  'Saudi Arabia (+966)': '+966',
  'Qatar (+974)': '+974',
  'Oman (+968)': '+968',
};
const Map<String, String> _defaultDialCodeByCountry = <String, String>{
  'AE': 'United Arab Emirates (+971)',
  'US': 'United States (+1)',
  'IN': 'India (+91)',
  'GB': 'United Kingdom (+44)',
  'SA': 'Saudi Arabia (+966)',
  'QA': 'Qatar (+974)',
  'OM': 'Oman (+968)',
};

enum _QuestionFeedScope { mine, public }

enum _AuthMethod { password, otp }

enum _QuestionDateFilter {
  allTime,
  last7Days,
  last30Days,
  thisMonth,
  thisYear,
  customRange,
}

extension on _QuestionDateFilter {
  String get label {
    switch (this) {
      case _QuestionDateFilter.allTime:
        return 'All time';
      case _QuestionDateFilter.last7Days:
        return 'Last 7 days';
      case _QuestionDateFilter.last30Days:
        return 'Last 30 days';
      case _QuestionDateFilter.thisMonth:
        return 'This month';
      case _QuestionDateFilter.thisYear:
        return 'This year';
      case _QuestionDateFilter.customRange:
        return 'Custom range';
    }
  }
}

class MedicoHubApp extends StatefulWidget {
  const MedicoHubApp({super.key});

  @override
  State<MedicoHubApp> createState() => _MedicoHubAppState();
}

class _MedicoHubAppState extends State<MedicoHubApp> {
  MedicoHubThemeConfig _themeConfig = const MedicoHubThemeConfig(
    preset: MedicoHubThemePreset.dark,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedicoHub',
      debugShowCheckedModeBanner: false,
      theme: buildMedicoHubTheme(_themeConfig),
      home: MedicoHubHomePage(
        themeConfig: _themeConfig,
        onThemeChanged: (config) => setState(() => _themeConfig = config),
      ),
    );
  }
}

class MedicoHubHomePage extends StatefulWidget {
  const MedicoHubHomePage({
    super.key,
    required this.themeConfig,
    required this.onThemeChanged,
  });

  final MedicoHubThemeConfig themeConfig;
  final ValueChanged<MedicoHubThemeConfig> onThemeChanged;

  @override
  State<MedicoHubHomePage> createState() => _MedicoHubHomePageState();
}

class _MedicoHubHomePageState extends State<MedicoHubHomePage>
    with WidgetsBindingObserver {
  final AppApiService _api = AppApiService();
  final FirebaseAuthService _auth = FirebaseAuthService();
  final UpdateService _updateService = UpdateService();
  final MedicoHubVoiceService _voiceService = MedicoHubVoiceService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _signInIdentifierController =
      TextEditingController();
  final TextEditingController _otpCodeController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _adminTitleController = TextEditingController();
  final TextEditingController _doctorInviteNameController =
      TextEditingController();
  final TextEditingController _doctorInviteEmailController =
      TextEditingController();
  final TextEditingController _doctorInvitePhoneController =
      TextEditingController();
  final TextEditingController _articleTitleController = TextEditingController();
  final TextEditingController _articleSummaryController =
      TextEditingController();
  final TextEditingController _articleBodyController = TextEditingController();
  final TextEditingController _notificationPhraseController =
      TextEditingController();
  final TextEditingController _notificationTargetController =
      TextEditingController();
  final TextEditingController _emailStatusNoteController =
      TextEditingController();
  final TextEditingController _themeHexController = TextEditingController();
  final TextEditingController _topicEditorController = TextEditingController();
  final TextEditingController _disclaimerRegionNoteController =
      TextEditingController();
  final TextEditingController _adSponsorController = TextEditingController();
  final TextEditingController _adTitleController = TextEditingController();
  final TextEditingController _adSubtitleController = TextEditingController();
  final TextEditingController _adCtaController =
      TextEditingController(text: 'Learn more');
  final TextEditingController _adUrlController = TextEditingController();
  final TextEditingController _adKeywordsController = TextEditingController();
  final TextEditingController _adCategoriesController = TextEditingController();
  final TextEditingController _adPriorityController =
      TextEditingController(text: '50');
  final ScrollController _authScrollController = ScrollController();

  bool _premium = false;
  bool _loading = true;
  bool _authBusy = false;
  bool _submitting = false;
  bool _uploadingAttachment = false;
  bool _recordingAudio = false;
  bool _listeningNative = false;
  bool _audioPreviewPlaying = false;
  bool _adminBusy = false;
  bool _createAccountMode = false;
  bool _identityLookupBusy = false;
  bool _passwordVisible = false;
  bool _signInPasswordVisible = false;
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  bool _customThemeDarkMode = false;
  bool _updateAutoOpen = false;
  bool _themeHexInvalid = false;
  bool _appSettingsBusy = false;
  bool _deleteAccountBusy = false;
  bool _otpRequested = false;
  bool _signupPolicyAccepted = false;
  int _tabIndex = 0;

  String _selectedExpiry = '7d';
  String _selectedLanguage = 'English';
  String _selectedAccountRole = 'patient';
  String _selectedSpecialty = 'General Health';
  String _selectedSignInChannel = 'Email';
  String _selectedTemplateId = '_custom';
  String _selectedQuestionCategory = 'General';
  String? _questionFilterTopic;
  String? _selectedDoctorId;
  String _inviteDoctorLanguage = 'English';
  String _inviteDoctorSpecialty = 'General Health';
  String? _editingQuestionId;
  String _articleCategory = 'General Health';
  String _currentVersion = UpdateService.fallbackVersion;
  UpdateCheckFrequency _updateFrequency = UpdateCheckFrequency.daily;
  _QuestionFeedScope _questionFeedScope = _QuestionFeedScope.mine;
  _QuestionDateFilter _questionDateFilter = _QuestionDateFilter.allTime;
  _AuthMethod _selectedAuthMethod = _AuthMethod.password;
  String _selectedAdPlacement = 'home';
  String _selectedAdLanguage = 'English';

  UserProfile? _activeUser;
  UpdateInfo? _updateInfo;
  AppSettings? _appSettings;
  UserProfile? _matchedRosterUser;
  List<ForumQuestion> _questions = const [];
  List<EducationItem> _education = const [];
  List<BlogArticle> _blogArticles = const [];
  List<AdCampaign> _adCampaigns = const [];
  List<NotificationOutboxItem> _notifications = const [];
  NotificationSettings? _notificationSettings;
  List<UploadedAttachment> _uploadedAttachments = const [];
  List<TitleTemplate> _titleTemplates = const [];
  List<DoctorDirectoryEntry> _doctors = const [];
  String? _errorMessage;
  String? _authLookupMessage;
  String? _otpStatusMessage;
  String? _otpRequestedDestination;
  String? _phoneVerificationId;
  String? _voiceStatus;
  String? _audioAttachmentPath;
  SharedPreferences? _prefs;
  DateTimeRange? _customQuestionRange;
  BannerAd? _bannerAd;
  AppOpenAd? _appOpenAd;
  bool _bannerReady = false;
  bool _isShowingAppOpenAd = false;
  bool _mobileAdsInitialized = false;
  bool _useTestAds = false;
  String _bannerAdStatus = 'Not initialized yet.';
  String _appOpenAdStatus = 'Not initialized yet.';
  Timer? _emailLookupDebounce;
  Timer? _backendRetryTimer;
  Timer? _bannerRetryTimer;
  Timer? _appOpenRetryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedSignInChannel = _defaultSignInChannelForLocale();
    _syncSignInIdentifierWithSelection();
    _emailController.addListener(_scheduleIdentityLookup);
    _bootstrap();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _symptomsController.dispose();
    _signInIdentifierController.dispose();
    _otpCodeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _displayNameController.dispose();
    _phoneController.dispose();
    _adminTitleController.dispose();
    _doctorInviteNameController.dispose();
    _doctorInviteEmailController.dispose();
    _doctorInvitePhoneController.dispose();
    _articleTitleController.dispose();
    _articleSummaryController.dispose();
    _articleBodyController.dispose();
    _notificationPhraseController.dispose();
    _notificationTargetController.dispose();
    _emailStatusNoteController.dispose();
    _themeHexController.dispose();
    _topicEditorController.dispose();
    _disclaimerRegionNoteController.dispose();
    _adSponsorController.dispose();
    _adTitleController.dispose();
    _adSubtitleController.dispose();
    _adCtaController.dispose();
    _adUrlController.dispose();
    _adKeywordsController.dispose();
    _adCategoriesController.dispose();
    _adPriorityController.dispose();
    _authScrollController.dispose();
    _emailLookupDebounce?.cancel();
    _backendRetryTimer?.cancel();
    _bannerRetryTimer?.cancel();
    _appOpenRetryTimer?.cancel();
    _bannerAd?.dispose();
    _appOpenAd?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _voiceService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _showAppOpenAdIfReady();
    }
  }

  Future<void> _bootstrap() async {
    SharedPreferences? prefs;
    UpdateInfo? updateInfo;
    try {
      await _ensureBundledBackendForWindows();
      final results = await Future.wait([
        SharedPreferences.getInstance(),
      ]);
      if (!mounted) {
        return;
      }
      prefs = results[0];
      _loadThemePreferences(prefs);
      _loadUpdatePreferences(prefs);
      _loadAdPreferences(prefs);
      _loadAuthPreferences(prefs);
      final currentVersion = await _updateService.currentVersion();
      if (_updateService.shouldCheck(
        prefs: prefs,
        frequency: _updateFrequency,
      )) {
        updateInfo = await _updateService.checkForUpdates(
          currentVersion: currentVersion,
        );
        await _updateService.markChecked(prefs);
      }
      setState(() {
        _prefs = prefs;
        _updateInfo = updateInfo;
        _currentVersion = currentVersion;
        _loading = false;
      });
      if (updateInfo != null) {
        unawaited(_handleAutoUpdateIfNeeded(updateInfo));
      }
      unawaited(_initializeMobileAdsIfNeeded());
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _prefs = prefs;
        _updateInfo = updateInfo;
        _currentVersion = UpdateService.fallbackVersion;
        _loading = false;
        _errorMessage = error.toString();
      });
    }
    unawaited(_loadInitialRemoteData());
  }

  Future<void> _loadInitialRemoteData({int attempt = 0}) async {
    final backendHealthy = await _api.checkHealth();
    if (!mounted) {
      return;
    }
    if (!backendHealthy) {
      setState(() {
        _notificationSettings = NotificationSettings.fromJson(const {});
        _notificationPhraseController.text =
            _notificationSettings?.whatsAppActivationPhrase ?? '';
        _notificationTargetController.text =
            _notificationSettings?.whatsAppActivationTarget ?? '';
        _emailStatusNoteController.text =
            _notificationSettings?.emailStatusNote ?? '';
        _errorMessage = attempt < 6
            ? null
            : 'Service is taking longer than expected to become available. Please try again in a moment.';
        _voiceStatus = attempt < 6 ? 'Preparing secure services...' : _voiceStatus;
      });
      if (attempt < 6) {
        _backendRetryTimer?.cancel();
        _backendRetryTimer = Timer(
          Duration(seconds: 5 + (attempt * 5)),
          () {
            if (mounted) {
              unawaited(_loadInitialRemoteData(attempt: attempt + 1));
            }
          },
        );
      }
      return;
    }

    try {
      _backendRetryTimer?.cancel();
      final results = await Future.wait([
        _api.fetchQuestions(),
        _api.fetchEducation(),
        _api.fetchBlogArticles(),
        _api.fetchTitleTemplates(),
        _api.fetchDoctors(),
        _api.fetchNotificationSettings(),
        _api.fetchAdCampaigns(),
        _api.fetchAppSettings(),
      ]);
      if (!mounted) {
        return;
      }
      final doctors = results[4] as List<DoctorDirectoryEntry>;
      setState(() {
        _questions = results[0] as List<ForumQuestion>;
        _education = results[1] as List<EducationItem>;
        _blogArticles = results[2] as List<BlogArticle>;
        _titleTemplates = results[3] as List<TitleTemplate>;
        _doctors = doctors;
        _selectedDoctorId = doctors.isEmpty ? null : doctors.first.id;
        _notificationSettings = results[5] as NotificationSettings;
        _adCampaigns = results[6] as List<AdCampaign>;
        _appSettings = results[7] as AppSettings;
        _selectedQuestionCategory = _availableQuestionTopics.contains(
              _selectedQuestionCategory,
            )
            ? _selectedQuestionCategory
            : _availableQuestionTopics.first;
        if (_questionFilterTopic != null &&
            !_availableQuestionTopics.contains(_questionFilterTopic)) {
          _questionFilterTopic = null;
        }
        _disclaimerRegionNoteController.text =
            _appSettings?.defaultRegionNote ?? '';
        if (_errorMessage != null &&
            _errorMessage!.startsWith('Backend not reachable at ')) {
          _errorMessage = null;
        }
      });
      _notificationPhraseController.text =
          _notificationSettings?.whatsAppActivationPhrase ?? '';
      _notificationTargetController.text =
          _notificationSettings?.whatsAppActivationTarget ?? '';
      _emailStatusNoteController.text =
          _notificationSettings?.emailStatusNote ?? '';
      _initializeMobileAdsIfNeeded();
      _scheduleIdentityLookup();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _notificationSettings = NotificationSettings.fromJson(const {});
        _notificationPhraseController.text =
            _notificationSettings?.whatsAppActivationPhrase ?? '';
        _notificationTargetController.text =
            _notificationSettings?.whatsAppActivationTarget ?? '';
        _emailStatusNoteController.text =
            _notificationSettings?.emailStatusNote ?? '';
        _adCampaigns = const [];
        _errorMessage = attempt < 6
            ? null
            : 'Could not load service data right now. Please try again in a moment.';
        _voiceStatus = attempt < 6 ? 'Preparing secure services...' : _voiceStatus;
      });
      if (attempt < 6) {
        _backendRetryTimer?.cancel();
        _backendRetryTimer = Timer(
          Duration(seconds: 5 + (attempt * 5)),
          () {
            if (mounted) {
              unawaited(_loadInitialRemoteData(attempt: attempt + 1));
            }
          },
        );
      }
    }
  }

  static const String _themePresetKey = 'theme_preset';
  static const String _themeCustomHexKey = 'theme_custom_hex';
  static const String _themeCustomDarkKey = 'theme_custom_dark';
  static const String _useTestAdsPreferenceKey = 'ads_use_test_units';
  static const String _lastEmailPreferenceKey = 'auth_last_email';
  static const String _lastPhonePreferenceKey = 'auth_last_phone';

  void _loadThemePreferences(SharedPreferences prefs) {
    final presetName = prefs.getString(_themePresetKey);
    final preset = MedicoHubThemePreset.values.firstWhere(
      (value) => value.name == presetName,
      orElse: () => widget.themeConfig.preset,
    );
    final storedCustomHex =
        prefs.getString(_themeCustomHexKey) ?? widget.themeConfig.customSeedHex;
    final normalizedCustomHex = normalizeHexColor(storedCustomHex);
    final customHex = normalizedCustomHex.isEmpty
        ? kDefaultCustomThemeHex
        : normalizedCustomHex;
    final customDark =
        prefs.getBool(_themeCustomDarkKey) ?? widget.themeConfig.customDarkMode;
    final config = MedicoHubThemeConfig(
      preset: preset == MedicoHubThemePreset.custom &&
              normalizeHexColor(customHex).isEmpty
          ? MedicoHubThemePreset.dark
          : preset,
      customSeedHex: customHex,
      customDarkMode: customDark,
    );
    _themeHexController.text = customHex;
    _customThemeDarkMode = customDark;
    _themeHexInvalid = false;
    widget.onThemeChanged(config);
  }

  void _loadAuthPreferences(SharedPreferences prefs) {
    _emailController.text = prefs.getString(_lastEmailPreferenceKey) ?? '';
    _phoneController.text = prefs.getString(_lastPhonePreferenceKey) ?? '';
    _syncSignInIdentifierWithSelection();
  }

  Future<void> _persistAuthPreferences({
    String? email,
    String? phone,
  }) async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    if (email != null && email.trim().isNotEmpty) {
      await prefs.setString(_lastEmailPreferenceKey, email.trim());
    }
    if (phone != null && phone.trim().isNotEmpty) {
      await prefs.setString(_lastPhonePreferenceKey, phone.trim());
    }
  }

  Future<void> _persistThemePreferences(MedicoHubThemeConfig config) async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    await prefs.setString(_themePresetKey, config.preset.name);
    await prefs.setString(_themeCustomHexKey, config.customSeedHex);
    await prefs.setBool(_themeCustomDarkKey, config.customDarkMode);
  }

  void _loadUpdatePreferences(SharedPreferences prefs) {
    _updateFrequency = UpdateCheckFrequencyLabel.fromStorage(
      prefs.getString(UpdateService.preferenceFrequencyKey),
    );
    _updateAutoOpen = prefs.getBool(UpdateService.preferenceAutoOpenKey) ?? false;
  }

  void _loadAdPreferences(SharedPreferences prefs) {
    _useTestAds = prefs.getBool(_useTestAdsPreferenceKey) ?? false;
  }

  Future<void> _persistUpdatePreferences() async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    await prefs.setString(
      UpdateService.preferenceFrequencyKey,
      _updateFrequency.storageValue,
    );
    await prefs.setBool(
      UpdateService.preferenceAutoOpenKey,
      _updateAutoOpen,
    );
  }

  Future<void> _persistAdPreferences() async {
    final prefs = _prefs;
    if (prefs == null) {
      return;
    }
    await prefs.setBool(_useTestAdsPreferenceKey, _useTestAds);
  }

  bool get _supportsMobileAds => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  String get _bannerAdUnitId {
    if (Platform.isAndroid) {
      return (_useTestAds || kDebugMode)
          ? _androidTestBannerAdUnitId
          : _androidBannerAdUnitId;
    }
    if (Platform.isIOS) {
      return (_useTestAds || kDebugMode)
          ? _iosTestBannerAdUnitId
          : _iosBannerAdUnitId;
    }
    return '';
  }

  String get _appOpenAdUnitId {
    if (Platform.isAndroid) {
      return (_useTestAds || kDebugMode)
          ? _androidTestAppOpenAdUnitId
          : _androidAppOpenAdUnitId;
    }
    if (Platform.isIOS) {
      return (_useTestAds || kDebugMode)
          ? _iosTestAppOpenAdUnitId
          : _iosAppOpenAdUnitId;
    }
    return '';
  }

  String get _adModeLabel => _useTestAds || kDebugMode ? 'Test ads' : 'Live ads';

  Future<void> _initializeMobileAdsIfNeeded() async {
    if (!_supportsMobileAds) {
      return;
    }
    if (_mobileAdsInitialized) {
      _loadBannerAd();
      _loadAppOpenAd();
      return;
    }
    await MobileAds.instance.initialize();
    if (!mounted) {
      return;
    }
    setState(() {
      _mobileAdsInitialized = true;
      _bannerAdStatus = '$_adModeLabel initialized. Waiting for banner fill...';
      _appOpenAdStatus = '$_adModeLabel initialized. Waiting for app-open fill...';
    });
    _loadBannerAd();
    _loadAppOpenAd();
  }

  void _disposeLoadedAds() {
    _bannerRetryTimer?.cancel();
    _appOpenRetryTimer?.cancel();
    _bannerAd?.dispose();
    _appOpenAd?.dispose();
    _bannerAd = null;
    _appOpenAd = null;
    _bannerReady = false;
    _isShowingAppOpenAd = false;
  }

  Future<void> _reloadAds() async {
    _disposeLoadedAds();
    if (mounted) {
      setState(() {
        _bannerAdStatus = 'Reloading ${_adModeLabel.toLowerCase()}...';
        _appOpenAdStatus = 'Reloading ${_adModeLabel.toLowerCase()}...';
      });
    }
    await _initializeMobileAdsIfNeeded();
  }

  void _loadBannerAd() {
    if (!_supportsMobileAds || _bannerAd != null || _bannerAdUnitId.isEmpty) {
      return;
    }
    setState(() {
      _bannerReady = false;
      _bannerAdStatus = 'Loading ${_adModeLabel.toLowerCase()} banner...';
    });
    final banner = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _bannerReady = true;
            _bannerAdStatus = '$_adModeLabel banner loaded.';
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerRetryTimer?.cancel();
          if (!mounted) {
            return;
          }
          setState(() {
            _bannerAd = null;
            _bannerReady = false;
            _bannerAdStatus =
                '$_adModeLabel banner failed (${error.code}): ${error.message}';
          });
          _bannerRetryTimer = Timer(const Duration(seconds: 20), () {
            if (mounted) {
              _loadBannerAd();
            }
          });
        },
      ),
    );
    banner.load();
  }

  void _loadAppOpenAd() {
    if (!_supportsMobileAds || _appOpenAd != null || _appOpenAdUnitId.isEmpty) {
      return;
    }
    if (mounted) {
      setState(() {
        _appOpenAdStatus = 'Loading ${_adModeLabel.toLowerCase()} app-open ad...';
      });
    }
    AppOpenAd.load(
      adUnitId: _appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd?.dispose();
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _appOpenAd = ad;
            _appOpenAdStatus = '$_adModeLabel app-open ad loaded.';
          });
        },
        onAdFailedToLoad: (error) {
          _appOpenRetryTimer?.cancel();
          if (!mounted) {
            return;
          }
          setState(() {
            _appOpenAd = null;
            _appOpenAdStatus =
                '$_adModeLabel app-open failed (${error.code}): ${error.message}';
          });
          _appOpenRetryTimer = Timer(const Duration(seconds: 30), () {
            if (mounted) {
              _loadAppOpenAd();
            }
          });
        },
      ),
    );
  }

  void _showAppOpenAdIfReady() {
    if (!_supportsMobileAds ||
        _appOpenAd == null ||
        _isShowingAppOpenAd ||
        _activeUser == null) {
      return;
    }
    _isShowingAppOpenAd = true;
    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (!mounted) {
          return;
        }
        setState(() {
          _appOpenAd = null;
          _isShowingAppOpenAd = false;
          _appOpenAdStatus = '$_adModeLabel app-open was shown.';
        });
        _loadAppOpenAd();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        ad.dispose();
        if (!mounted) {
          return;
        }
        setState(() {
          _appOpenAd = null;
          _isShowingAppOpenAd = false;
          _appOpenAdStatus =
              '$_adModeLabel app-open could not show (${error.code}): ${error.message}';
        });
        _loadAppOpenAd();
      },
    );
    _appOpenAd!.show();
  }

  Future<void> _handleAutoUpdateIfNeeded(UpdateInfo info) async {
    final prefs = _prefs;
    if (prefs == null || !_updateAutoOpen) {
      return;
    }
    final lastOpened =
        prefs.getString(UpdateService.preferenceLastOpenedVersionKey);
    if (lastOpened == info.latestVersion) {
      return;
    }
    final url = _updateService.preferredDownloadUrl(info);
    if (url.isEmpty) {
      return;
    }
    await prefs.setString(
      UpdateService.preferenceLastOpenedVersionKey,
      info.latestVersion,
    );
    await _openExternalUrl(url);
  }

  Future<void> _checkForUpdatesNow() async {
    final prefs = _prefs;
    try {
      final info = await _updateService.checkForUpdates(
        currentVersion: _currentVersion,
      );
      if (prefs != null) {
        await _updateService.markChecked(prefs);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _updateInfo = info;
        _voiceStatus = info == null
            ? 'You are already on the latest MedicoHub version.'
            : 'Update ${info.latestVersion} is available.';
      });
      if (info != null) {
        await _handleAutoUpdateIfNeeded(info);
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Could not check for updates: $error';
      });
    }
  }

  Future<void> _openUpdateDownload() async {
    final info = _updateInfo;
    if (info == null) {
      setState(() {
        _voiceStatus = 'No pending update is available right now.';
      });
      return;
    }
    final url = _updateService.preferredDownloadUrl(info);
    if (url.isEmpty) {
      setState(() {
        _errorMessage = 'No download link is configured for this platform yet.';
      });
      return;
    }
    await _openExternalUrl(url);
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'This link is invalid: $url';
      });
      return;
    }
    final launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      setState(() {
        _errorMessage = 'Could not open $url';
      });
    }
  }

  Future<void> _ensureBundledBackendForWindows() async {
    if (!Platform.isWindows) {
      return;
    }
    if (await _api.checkHealth()) {
      return;
    }

    final executableDir = File(Platform.resolvedExecutable).parent;
    final backendExe = File(
      '${executableDir.path}${Platform.pathSeparator}medicohub_backend.exe',
    );
    if (!await backendExe.exists()) {
      return;
    }

    try {
      await Process.start(
        backendExe.path,
        const [],
        mode: ProcessStartMode.detached,
        runInShell: false,
      );
    } catch (_) {
      return;
    }

    for (var attempt = 0; attempt < 30; attempt++) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (await _api.checkHealth()) {
        return;
      }
    }
  }

  List<TitleTemplate> get _visibleTitleTemplates {
    return _titleTemplates.where((template) {
      return template.language == _selectedLanguage ||
          template.language == 'English';
    }).toList();
  }

  List<String> get _availableQuestionTopics {
    final topics = _appSettings?.questionTopics ?? _questionCategories;
    return topics.isEmpty ? _questionCategories : topics;
  }

  bool get _isAdminView => _activeUser?.isAdmin == true;

  List<ForumQuestion> get _roleScopedQuestions {
    final user = _activeUser;
    if (user == null) {
      return const [];
    }
    if (user.isAdmin) {
      return _questions;
    }
    if (user.isDoctor) {
      return _questions
          .where((question) =>
              question.targetDoctorId == user.id ||
              _normalizeEmail(question.targetDoctorEmail) ==
                  _normalizeEmail(user.email) ||
              question.isPublic)
          .toList();
    }
    return _questions
        .where((question) =>
            question.authorId == user.id || question.isPublic)
        .toList();
  }

  List<ForumQuestion> get _doctorCurrentQuestions {
    final user = _activeUser;
    if (user == null || !user.isDoctor) {
      return const [];
    }
    return _roleScopedQuestions.where((question) {
      if (!_isAssignedToActiveDoctor(question, user)) {
        return false;
      }
      return question.status == 'open' || _latestThreadMessageNeedsDoctor(question);
    }).toList()
      ..sort((a, b) => _latestConversationMoment(b).compareTo(_latestConversationMoment(a)));
  }

  List<ForumQuestion> get _doctorHistoryQuestions {
    final user = _activeUser;
    if (user == null || !user.isDoctor) {
      return const [];
    }
    return _roleScopedQuestions.where((question) {
      if (!_isAssignedToActiveDoctor(question, user)) {
        return false;
      }
      return !_doctorCurrentQuestions.any((current) => current.id == question.id);
    }).toList()
      ..sort((a, b) => _latestConversationMoment(b).compareTo(_latestConversationMoment(a)));
  }

  List<NotificationOutboxItem> get _whatsAppNotifications {
    final items = _notifications.where((item) => item.channel == 'whatsapp').toList();
    items.sort(
      (a, b) => _tryParseDate(b.createdAt).compareTo(_tryParseDate(a.createdAt)),
    );
    return items;
  }

  List<NotificationOutboxItem> get _emailComingLaterNotifications {
    return _notifications
        .where((item) => item.channel == 'email' && item.status != 'sent')
        .toList();
  }

  List<ForumQuestion> _filteredQuestionsForScope(_QuestionFeedScope scope) {
    final base = scope == _QuestionFeedScope.public
        ? _questions.where((question) => question.isPublic).toList()
        : _roleScopedQuestions.where((question) => !question.isPublic || question.authorId == _activeUser?.id || _activeUser?.isDoctor == true || _activeUser?.isAdmin == true).toList();
    final filtered = base.where((question) {
      if (_questionFilterTopic != null &&
          _questionFilterTopic!.isNotEmpty &&
          question.headingGroup != _questionFilterTopic &&
          !question.tags.contains(_questionFilterTopic)) {
        return false;
      }
      return _questionMatchesDateFilter(question);
    }).toList()
      ..sort(
        (a, b) => _latestConversationMoment(b).compareTo(
          _latestConversationMoment(a),
        ),
      );
    return filtered;
  }

  bool _questionMatchesDateFilter(ForumQuestion question) {
    final timestamp = _latestConversationMoment(question);
    final now = DateTime.now();
    switch (_questionDateFilter) {
      case _QuestionDateFilter.allTime:
        return true;
      case _QuestionDateFilter.last7Days:
        return timestamp.isAfter(now.subtract(const Duration(days: 7)));
      case _QuestionDateFilter.last30Days:
        return timestamp.isAfter(now.subtract(const Duration(days: 30)));
      case _QuestionDateFilter.thisMonth:
        return timestamp.year == now.year && timestamp.month == now.month;
      case _QuestionDateFilter.thisYear:
        return timestamp.year == now.year;
      case _QuestionDateFilter.customRange:
        final range = _customQuestionRange;
        if (range == null) {
          return true;
        }
        final start = DateTime(
          range.start.year,
          range.start.month,
          range.start.day,
        );
        final end = DateTime(
          range.end.year,
          range.end.month,
          range.end.day,
          23,
          59,
          59,
        );
        return !timestamp.isBefore(start) && !timestamp.isAfter(end);
    }
  }

  bool get _canConfigureNotificationSettings =>
      _activeUser?.isAdmin == true;

  String? get _whatsAppActivationPreferenceKey {
    final user = _activeUser;
    if (user == null) {
      return null;
    }
    return 'whatsapp_activation_until_${user.id}';
  }

  DateTime? get _whatsAppActivationCooldownUntil {
    final prefs = _prefs;
    final key = _whatsAppActivationPreferenceKey;
    if (prefs == null || key == null) {
      return null;
    }
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return DateTime.tryParse(raw)?.toLocal();
  }

  bool get _isWhatsAppActivationCoolingDown {
    final until = _whatsAppActivationCooldownUntil;
    if (until == null) {
      return false;
    }
    return DateTime.now().isBefore(until);
  }

  DoctorDirectoryEntry? get _selectedDoctor {
    final doctorId = _selectedDoctorId;
    if (doctorId == null) {
      return null;
    }
    for (final doctor in _doctors) {
      if (doctor.id == doctorId) {
        return doctor;
      }
    }
    return null;
  }

  bool get _canManageDoctorDirectory =>
      _activeUser?.canManageDoctors == true || _activeUser?.isAdmin == true;

  bool get _isSignInUsingEmail => _selectedSignInChannel == 'Email';

  String get _selectedDialCode =>
      _isSignInUsingEmail ? '' : (_signInChannelOptions[_selectedSignInChannel] ?? '+971');

  String get _formattedSignInDestination {
    final raw = _signInIdentifierController.text.trim();
    if (_isSignInUsingEmail) {
      return raw;
    }
    return _normalizeOtpPhoneDestination(raw);
  }

  String _defaultSignInChannelForLocale() {
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    return _defaultDialCodeByCountry[locale.countryCode?.toUpperCase()] ??
        'United Arab Emirates (+971)';
  }

  String _phoneDigitsWithoutCountryCode(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    for (final code in _signInChannelOptions.values.where((value) => value != 'email')) {
      final countryDigits = code.replaceAll('+', '');
      if (digits.startsWith(countryDigits)) {
        return digits.substring(countryDigits.length);
      }
    }
    return digits;
  }

  String _normalizeOtpPhoneDestination(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      return '';
    }
    final countryDigits = _selectedDialCode.replaceAll('+', '');
    if (digits.startsWith(countryDigits)) {
      digits = digits.substring(countryDigits.length);
    }
    while (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    return digits.isEmpty ? '' : '$_selectedDialCode$digits';
  }

  void _syncSignInIdentifierWithSelection() {
    _signInIdentifierController.text = _isSignInUsingEmail
        ? _emailController.text.trim()
        : _phoneDigitsWithoutCountryCode(_phoneController.text.trim());
  }

  void _handleSignInIdentifierChanged() {
    final raw = _signInIdentifierController.text.trim();
    if (_isSignInUsingEmail) {
      _emailController.text = raw;
    } else {
      _phoneController.text = _normalizeOtpPhoneDestination(raw);
    }
    if (_errorMessage != null || _otpStatusMessage != null) {
      setState(() {
        _errorMessage = null;
        _otpStatusMessage = null;
      });
    }
  }

  void _resetOtpJourney() {
    _otpRequested = false;
    _otpCodeController.clear();
    _otpStatusMessage = null;
    _otpRequestedDestination = null;
    _phoneVerificationId = null;
  }

  void _switchAuthSurface({
    required bool createAccountMode,
    _AuthMethod? authMethod,
  }) {
    setState(() {
      _createAccountMode = createAccountMode;
      _errorMessage = null;
      _authLookupMessage = null;
      if (authMethod != null) {
        _selectedAuthMethod = authMethod;
      }
      if (!createAccountMode) {
        _signupPolicyAccepted = false;
      }
      _resetOtpJourney();
      _syncSignInIdentifierWithSelection();
    });
  }

  @override
  Widget build(BuildContext context) {
    final signedIn = _activeUser != null;
    return Scaffold(
      appBar: signedIn ? _buildSignedInAppBar(context) : null,
      drawer: signedIn ? _buildNavigationDrawer(context) : null,
      floatingActionButton: signedIn
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _tabIndex = 1),
              label: Text(_editingQuestionId == null ? 'Ask' : 'Edit'),
              icon: Icon(
                _editingQuestionId == null
                    ? Icons.add_circle_outline_rounded
                    : Icons.edit_note_rounded,
              ),
            )
          : null,
      bottomNavigationBar: signedIn
          ? NavigationBar(
              selectedIndex: _tabIndex.clamp(0, 4),
              onDestinationSelected: (value) => setState(() => _tabIndex = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.add_circle_outline_rounded),
                  selectedIcon: Icon(Icons.add_comment_rounded),
                  label: 'Ask',
                ),
                NavigationDestination(
                  icon: Icon(Icons.forum_outlined),
                  selectedIcon: Icon(Icons.forum_rounded),
                  label: 'Questions',
                ),
                NavigationDestination(
                  icon: Icon(Icons.auto_stories_outlined),
                  selectedIcon: Icon(Icons.auto_stories_rounded),
                  label: 'Education',
                ),
                NavigationDestination(
                  icon: Icon(Icons.tune_outlined),
                  selectedIcon: Icon(Icons.tune_rounded),
                  label: 'Settings',
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : !signedIn
                ? _buildLoginGate(context)
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: IndexedStack(
                      index: _tabIndex.clamp(0, 4),
                      children: [
                        _buildHomeTab(context),
                        _buildAskTab(context),
                        _buildQuestionsTab(context),
                        _buildEducationTab(context),
                        _buildSettingsTab(context),
                      ],
                    ),
                  ),
      ),
    );
  }

  PreferredSizeWidget _buildSignedInAppBar(BuildContext context) {
    final user = _activeUser!;
    return AppBar(
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      titleSpacing: 0,
      title: Row(
        children: [
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.transparent,
            child: ClipOval(
              child: Image.asset(
                Theme.of(context).brightness == Brightness.dark
                    ? _brandIconDarkAsset
                    : _brandIconLightAsset,
                fit: BoxFit.cover,
                width: 36,
                height: 36,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MedicoHub',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                'We Connect',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Center(
            child: Chip(
              avatar: const Icon(Icons.person_outline_rounded, size: 18),
              label: Text(user.displayName.split(' ').first),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Sign out',
          onPressed: _signOut,
          icon: const Icon(Icons.logout_rounded),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildNavigationDrawer(BuildContext context) {
    final user = _activeUser!;
    final colorScheme = Theme.of(context).colorScheme;
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.surfaceContainerHighest,
                    colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset(
                    Theme.of(context).brightness == Brightness.dark
                        ? _brandDarkAsset
                        : _brandLightAsset,
                    height: 96,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.displayName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.role[0].toUpperCase()}${user.role.substring(1)} • ${user.email}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.home_rounded,
                    label: 'Home',
                    onTap: () => _selectDrawerTab(context, 0),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.add_comment_rounded,
                    label: 'Ask Question',
                    onTap: () => _selectDrawerTab(context, 1),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.forum_rounded,
                    label: 'My Questions',
                    onTap: () => _selectDrawerTab(context, 2),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.auto_stories_rounded,
                    label: 'Education',
                    onTap: () => _selectDrawerTab(context, 3),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person_outline_rounded,
                    label: 'Profile & Settings',
                    onTap: () => _selectDrawerTab(context, 4),
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.info_outline_rounded,
                    label: 'About',
                    onTap: () {
                      Navigator.of(context).pop();
                      _showAboutSheet();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: const Text('Logout'),
              onTap: () {
                Navigator.of(context).pop();
                _signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }

  void _selectDrawerTab(BuildContext context, int index) {
    Navigator.of(context).pop();
    setState(() => _tabIndex = index);
  }

  Future<void> _showLegalSheet({
    required String title,
    required String body,
  }) async {
    if (!mounted) {
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 12),
                  Text(body),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAboutSheet() async {
    final user = _activeUser;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Image.asset(
                        Theme.of(context).brightness == Brightness.dark
                            ? _brandDarkAsset
                            : _brandLightAsset,
                        height: 88,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MedicoHub',
                              style: Theme.of(context).textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'We Connect',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Purpose',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'MedicoHub brings patients, doctors, and administrators onto one calm educational platform for structured questions, clear replies, trusted articles, and guided follow-up.',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Vision',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'A friendlier digital clinical communication space where questions are easier to ask, answers are easier to understand, and care teams stay connected without noise.',
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Current experience',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user == null
                        ? 'Sign in to ask questions, follow thread updates, and explore multilingual education.'
                        : 'Signed in as ${user.displayName}. Use the side menu to move between questions, education, settings, and your dashboard tools.',
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginGate(BuildContext context) {
    final isSignup = _createAccountMode;
    final showPassword = !isSignup && _selectedAuthMethod == _AuthMethod.password;
    final showOtpActions = !isSignup && _selectedAuthMethod == _AuthMethod.otp;
    final brandAsset =
        Theme.of(context).brightness == Brightness.dark ? _brandDarkAsset : _brandLightAsset;
    final media = MediaQuery.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          controller: _authScrollController,
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + media.viewInsets.bottom,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 32,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.all(media.size.width < 420 ? 18 : 28),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 760;
                    if (isWide) {
                      return IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _buildAuthBrandPanel(
                                context,
                                assetPath: brandAsset,
                                compact: false,
                              ),
                            ),
                            const SizedBox(width: 28),
                            Expanded(
                              flex: 6,
                              child: _buildAuthCard(
                                context,
                                isSignup: isSignup,
                                showPassword: showPassword,
                                showOtpActions: showOtpActions,
                                compact: false,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildAuthBrandPanel(
                          context,
                          assetPath: brandAsset,
                          compact: true,
                        ),
                        const SizedBox(height: 16),
                        _buildAuthCard(
                          context,
                          isSignup: isSignup,
                          showPassword: showPassword,
                          showOtpActions: showOtpActions,
                          compact: true,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAuthBrandPanel(
    BuildContext context, {
    required String assetPath,
    required bool compact,
  }) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.65),
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: compact
          ? Row(
              children: [
                Image.asset(
                  assetPath,
                  height: 72,
                  width: 72,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'MedicoHub',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'We Connect',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Simple sign-in, clear questions, faster follow-up.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Center(
                  child: Image.asset(
                    assetPath,
                    height: 170,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'MedicoHub',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'We Connect',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
                const SizedBox(height: 16),
                Text(
                  'A simpler, calmer way to ask questions, follow trusted replies, and stay connected with your doctor and care team.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            ),
    );
  }

  Widget _buildAuthCard(
    BuildContext context, {
    required bool isSignup,
    required bool showPassword,
    required bool showOtpActions,
    required bool compact,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final spacing = compact ? 10.0 : 12.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          isSignup ? 'Create your account' : 'Sign in to your account',
          style: compact ? textTheme.titleLarge : textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          isSignup
              ? 'Register once, agree to the essentials, and continue.'
              : 'Use mobile or email and continue securely.',
          style: compact ? textTheme.bodySmall : textTheme.bodyMedium,
        ),
        if (_identityLookupBusy) ...[
          const SizedBox(height: 14),
          const LinearProgressIndicator(),
        ],
        if (_authLookupMessage != null && _authLookupMessage!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            _authLookupMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.primary),
          ),
        ],
        SizedBox(height: compact ? 16 : 20),
        if (isSignup) ...[
          TextField(
            controller: _displayNameController,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          SizedBox(height: spacing),
          if (compact) ...[
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            SizedBox(height: spacing),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Mobile number',
                prefixIcon: Icon(Icons.call_outlined),
              ),
            ),
            SizedBox(height: spacing),
            DropdownButtonFormField<String>(
              initialValue: _selectedAccountRole,
              decoration: const InputDecoration(labelText: 'Account role'),
              items: _accountRoles
                  .map(
                    (role) => DropdownMenuItem<String>(
                      value: role,
                      child: Text(role[0].toUpperCase() + role.substring(1)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedAccountRole = value);
                }
              },
            ),
            SizedBox(height: spacing),
            DropdownButtonFormField<String>(
              initialValue: _selectedLanguage,
              decoration: const InputDecoration(labelText: 'Preferred language'),
              items: _languageLocales.keys
                  .map(
                    (language) => DropdownMenuItem<String>(
                      value: language,
                      child: Text(language),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedLanguage = value);
                }
              },
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.mail_outline_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number',
                      prefixIcon: Icon(Icons.call_outlined),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedAccountRole,
                    decoration: const InputDecoration(labelText: 'Account role'),
                    items: _accountRoles
                        .map(
                          (role) => DropdownMenuItem<String>(
                            value: role,
                            child: Text(role[0].toUpperCase() + role.substring(1)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedAccountRole = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedLanguage,
                    decoration: const InputDecoration(labelText: 'Preferred language'),
                    items: _languageLocales.keys
                        .map(
                          (language) => DropdownMenuItem<String>(
                            value: language,
                            child: Text(language),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedLanguage = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
          if (_selectedAccountRole != 'patient') ...[
            SizedBox(height: spacing),
            DropdownButtonFormField<String>(
              initialValue: _selectedSpecialty,
              decoration: const InputDecoration(labelText: 'Specialty'),
              items: _specialties
                  .map(
                    (specialty) => DropdownMenuItem<String>(
                      value: specialty,
                      child: Text(specialty),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedSpecialty = value);
                }
              },
            ),
          ],
        ] else ...[
          Align(
            alignment: Alignment.centerLeft,
            child: SegmentedButton<bool>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment<bool>(
                  value: true,
                  icon: Icon(Icons.mail_outline_rounded),
                  label: Text('Email'),
                ),
                ButtonSegment<bool>(
                  value: false,
                  icon: Icon(Icons.call_outlined),
                  label: Text('Mobile'),
                ),
              ],
              selected: <bool>{_isSignInUsingEmail},
              onSelectionChanged: (selection) {
                final useEmail = selection.first;
                setState(() {
                  _selectedSignInChannel =
                      useEmail ? 'Email' : _defaultSignInChannelForLocale();
                  _errorMessage = null;
                  _resetOtpJourney();
                  if (!useEmail && _selectedAuthMethod == _AuthMethod.password) {
                    _selectedAuthMethod = _AuthMethod.otp;
                  }
                  _syncSignInIdentifierWithSelection();
                });
              },
            ),
          ),
          SizedBox(height: spacing),
          if (!_isSignInUsingEmail) ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedSignInChannel == 'Email'
                  ? _defaultSignInChannelForLocale()
                  : _selectedSignInChannel,
              decoration: const InputDecoration(labelText: 'Country/region code'),
              items: _signInChannelOptions.keys
                  .where((label) => label != 'Email')
                  .map(
                    (label) => DropdownMenuItem<String>(
                      value: label,
                      child: Text(label, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _selectedSignInChannel = value;
                  _errorMessage = null;
                  _resetOtpJourney();
                  _syncSignInIdentifierWithSelection();
                });
              },
            ),
            SizedBox(height: spacing),
          ],
          TextField(
            controller: _signInIdentifierController,
            keyboardType:
                _isSignInUsingEmail ? TextInputType.emailAddress : TextInputType.phone,
            autofillHints: _isSignInUsingEmail
                ? const [AutofillHints.username, AutofillHints.email]
                : const [AutofillHints.telephoneNumber],
            decoration: InputDecoration(
              labelText: _isSignInUsingEmail ? 'Email address' : 'Mobile number',
              helperText: _isSignInUsingEmail
                  ? 'Use this for App Review demo credentials and password sign-in.'
                  : 'Use mobile sign-in with OTP.',
              prefixIcon: Icon(
                _isSignInUsingEmail
                    ? Icons.mail_outline_rounded
                    : Icons.call_outlined,
              ),
              prefixText: _isSignInUsingEmail ? null : '$_selectedDialCode ',
            ),
            onChanged: (_) => _handleSignInIdentifierChanged(),
          ),
          SizedBox(height: spacing),
          Text(
            _isSignInUsingEmail
                ? 'Choose password or OTP for email sign-in.'
                : 'Mobile sign-in uses OTP. Switch to Email for password sign-in.',
            style: textTheme.bodySmall,
          ),
          SizedBox(height: spacing),
          SegmentedButton<_AuthMethod>(
            showSelectedIcon: false,
            style: compact
                ? const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )
                : null,
            segments: const [
              ButtonSegment<_AuthMethod>(
                value: _AuthMethod.password,
                icon: Icon(Icons.password_rounded),
                label: Text('Password'),
              ),
              ButtonSegment<_AuthMethod>(
                value: _AuthMethod.otp,
                icon: Icon(Icons.sms_outlined),
                label: Text('OTP'),
              ),
            ],
            selected: <_AuthMethod>{_selectedAuthMethod},
            onSelectionChanged: (selection) {
              setState(() {
                final chosen = selection.first;
                _selectedAuthMethod =
                    !_isSignInUsingEmail && chosen == _AuthMethod.password
                        ? _AuthMethod.otp
                        : chosen;
                _errorMessage = null;
                _resetOtpJourney();
              });
            },
          ),
          SizedBox(height: spacing),
        ],
        _buildAuthAgreement(context),
        if (isSignup) ...[
          const SizedBox(height: 8),
          CheckboxListTile(
            value: _signupPolicyAccepted,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (value) {
              setState(() => _signupPolicyAccepted = value ?? false);
            },
            title: const Text(
              'I have read the notice and agree to continue with account creation.',
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              TextButton(
                onPressed: _saveDisclaimerLocally,
                child: const Text('Save terms'),
              ),
              TextButton(
                onPressed: _emailDisclaimerToSelf,
                child: const Text('Email terms'),
              ),
            ],
          ),
        ],
        SizedBox(height: spacing),
        if (showPassword)
          TextField(
            controller: _passwordController,
            obscureText: !_signInPasswordVisible,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(
                  () => _signInPasswordVisible = !_signInPasswordVisible,
                ),
                icon: Icon(
                  _signInPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          )
        else if (isSignup)
          TextField(
            controller: _passwordController,
            obscureText: !_passwordVisible,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Create password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
                icon: Icon(
                  _passwordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
              ),
            ),
          ),
        if (showOtpActions) ...[
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _authBusy ? null : _requestInlineOtp,
              icon: const Icon(Icons.mark_email_read_outlined),
              label: Text(_otpRequested ? 'Resend OTP' : 'Send OTP'),
            ),
          ),
          if (_otpRequested) ...[
            SizedBox(height: spacing),
            TextField(
              controller: _otpCodeController,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: 'Enter OTP',
                prefixIcon: Icon(Icons.verified_user_outlined),
              ),
              onChanged: (value) {
                if (value.trim().length == 6 && !_authBusy) {
                  unawaited(_verifyInlineOtp());
                }
              },
            ),
          ],
          if (_otpStatusMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _otpStatusMessage!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ],
        if (_errorMessage != null) ...[
          const SizedBox(height: 10),
          Text(
            _errorMessage!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        SizedBox(height: compact ? 16 : 20),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _authBusy
                ? null
                : (isSignup
                    ? (_signupPolicyAccepted ? _registerFirebaseUser : null)
                    : (showOtpActions ? _verifyInlineOtp : _signInWithFirebase)),
            child: Text(
              _authBusy
                  ? (isSignup ? 'Creating...' : 'Please wait...')
                  : (isSignup
                      ? 'Continue'
                      : (showOtpActions ? 'Continue' : 'Continue')),
            ),
          ),
        ),
        if (!isSignup && showPassword) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _authBusy ? null : _sendPasswordReset,
              child: const Text('Reset Password'),
            ),
          ),
        ],
        SizedBox(height: compact ? 12 : 16),
        Center(
          child: Column(
            children: [
              Text(
                isSignup ? 'Already have an account?' : "Don't have an account?",
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _authBusy
                    ? null
                    : () => _switchAuthSurface(
                          createAccountMode: !isSignup,
                          authMethod: _AuthMethod.password,
                        ),
                child: Text(isSignup ? 'Back to Sign In' : 'Register'),
              ),
            ],
          ),
        ),
        if (kDebugMode && !compact) ...[
          const SizedBox(height: 8),
          TextButton(
            onPressed: _authBusy ? null : _useBackendDemoUser,
            child: const Text('Use Backend Demo'),
          ),
        ],
      ],
    );
  }

  Widget _buildAuthAgreement(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return RichText(
      text: TextSpan(
        style: style?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
        children: [
          const TextSpan(
            text: 'By clicking continue you acknowledge you have read and agreed to our ',
          ),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: InkWell(
              onTap: () => _showLegalSheet(
                title: 'Terms of Use',
                body:
                    '${_currentDisclaimerDocument.title}\n\n${_currentDisclaimerDocument.body}',
              ),
              child: Text(
                'Terms of Use',
                style: style?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const TextSpan(text: ' and '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: InkWell(
              onTap: () => _showLegalSheet(
                title: 'Privacy Policy',
                body:
                    'MedicoHub uses your sign-in, profile, and question data to deliver account access, secure thread updates, ads configuration, and educational content.\n\n$_currentRegionNote',
              ),
              child: Text(
                'Privacy Policy',
                style: style?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const TextSpan(text: '.'),
        ],
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    final user = _activeUser!;
    final scopedQuestions = _roleScopedQuestions;
    final pendingQuestions = scopedQuestions
        .where((question) => question.status == 'open')
        .length;
    final homeCampaigns = _matchingCampaignsForText(
      placement: 'home',
      primaryText: user.specialties.join(' '),
      secondaryText: scopedQuestions
          .take(5)
          .map((item) => '${item.title} ${item.body}')
          .join(' '),
      language: _selectedLanguage,
    );
    final AdCampaign? homeCampaign =
        homeCampaigns.isEmpty ? null : homeCampaigns.first;
    return ListView(
      children: [
        if (_errorMessage != null) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                _errorMessage!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.error),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        _buildHeroCard(context),
        const SizedBox(height: 16),
        _buildWhatsAppActivationBadge(context),
        const SizedBox(height: 16),
        _buildQuickLinksCard(context),
        const SizedBox(height: 16),
        if (_bannerReady) ...[
          _buildBannerAdCard(),
          const SizedBox(height: 16),
        ],
        if (homeCampaign != null) ...[
          _buildSponsoredCard(
            context,
            homeCampaign,
            label: 'Suggested sponsor',
          ),
          const SizedBox(height: 16),
        ],
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            final cards = <Widget>[
              _buildDashboardCard(
                context,
                title: user.isAdmin ? 'Admin Dashboard' : user.isDoctor ? 'Doctor Dashboard' : 'Patient Dashboard',
                body: user.isAdmin
                    ? 'Roster, moderation, education, and app operations in one place.'
                    : user.isDoctor
                        ? 'Assigned questions, education updates, and follow-ups in one place.'
                        : 'Your active threads, quick actions, and updates in one place.',
                statLines: [
                  'Visible threads: ${scopedQuestions.length}',
                  'Open threads: $pendingQuestions',
                  'Selected language: $_selectedLanguage',
                  'WhatsApp: ${_isWhatsAppActivationCoolingDown ? 'Activated today' : 'Needs activation'}',
                ],
              ),
            ];
            if (user.isAdmin) {
              cards.add(
                _buildDashboardCard(
                  context,
                  title: 'Doctor Dashboard',
                  body: 'Admins are also doctors in MedicoHub. Review questions routed to named doctors, post educational articles, and respond if coverage is needed.',
                  statLines: [
                    'Directed to you: ${_questions.where((item) => item.targetDoctorId == user.id).length}',
                    'Published articles: ${_blogArticles.where((item) => item.authorId == user.id).length}',
                    'WhatsApp alerts tracked: ${_whatsAppNotifications.length}',
                    'WhatsApp: ${_isWhatsAppActivationCoolingDown ? 'Activated today' : 'Needs activation'}',
                  ],
                ),
              );
            }
            if (wide) {
              return Wrap(
                spacing: 16,
                runSpacing: 16,
                children: cards
                    .map(
                      (card) => SizedBox(
                        width: constraints.maxWidth > 1300
                            ? (constraints.maxWidth - 32) / 3
                            : (constraints.maxWidth - 16) / 2,
                        child: card,
                      ),
                    )
                    .toList(),
              );
            }
            return Column(
              children: [
                for (var index = 0; index < cards.length; index++) ...[
                  if (index > 0) const SizedBox(height: 16),
                  cards[index],
                ],
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        if (user.isDoctor) ...[
          _buildDoctorQueueSection(
            context,
            title: 'Current Doctor Queue',
            subtitle:
                'Threads awaiting a doctor reply or reopened by a patient follow-up appear here.',
            questions: _doctorCurrentQuestions,
            emptyText:
                'No active doctor queue items right now. New questions or follow-ups will appear here.',
          ),
          const SizedBox(height: 16),
          _buildDoctorQueueSection(
            context,
            title: 'Doctor History',
            subtitle:
                'Previously answered threads remain accessible here for review and continued follow-up.',
            questions: _doctorHistoryQuestions,
            emptyText: 'No answered doctor history yet.',
          ),
          const SizedBox(height: 16),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('What is Live Now',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Text(
                  user.isAdmin
                      ? 'A quieter summary of the live system, with full details available when you open the relevant page.'
                      : 'A compact snapshot of the newest activity, so the home page feels lighter and easier to scan.',
                ),
                const SizedBox(height: 12),
                ...scopedQuestions.take(3).map(
                  (question) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.bolt_rounded),
                    title: Text(question.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      question.body,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: TextButton(
                      onPressed: () => setState(() => _tabIndex = 2),
                      child: const Text('Open'),
                    ),
                  ),
                ),
                if (_updateInfo != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Update available: ${_updateInfo!.latestVersion}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...scopedQuestions.take(4).expand((question) {
          final relatedCampaign = _matchingCampaignsForText(
            placement: 'question',
            primaryText: question.title,
            secondaryText:
                '${question.body} ${question.aiSummary} ${question.responses.map((item) => item.fullText).join(' ')}',
            category: question.headingGroup,
            language: question.language,
          ).take(1);
          return <Widget>[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _QuestionCard(
                question: question,
                onEdit: _canEditQuestion(question)
                    ? () => _startEditingQuestion(question)
                    : null,
                onTogglePublic: _canEditQuestion(question)
                    ? () => _toggleQuestionVisibility(question)
                    : null,
                onDelete: _canEditQuestion(question)
                    ? () => _deleteQuestion(question)
                    : null,
              ),
            ),
            for (final campaign in relatedCampaign)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildSponsoredCard(
                  context,
                  campaign,
                  label: 'Sponsored resource',
                ),
              ),
          ];
        }),
      ],
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String body,
    required List<String> statLines,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(body),
            const SizedBox(height: 12),
            ...statLines.map((line) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(line)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorQueueSection(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<ForumQuestion> questions,
    required String emptyText,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle),
            const SizedBox(height: 16),
            if (questions.isEmpty)
              Text(emptyText)
            else
              ...questions.take(5).map(
                (question) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _QuestionCard(
                    question: question,
                    followUpLabel: _activeUser?.isDoctor == true
                        ? 'Comment on Thread'
                        : 'Add Follow-up',
                    onRespond: _canRespondToQuestion(question)
                        ? () => _openDoctorResponseDialog(question)
                        : null,
                    onAddFollowUp: _canAddFollowUp(question)
                        ? () => _openThreadMessageDialog(question)
                        : null,
                    canModerateMessage: (message) =>
                        _canModerateThreadMessage(question, message),
                    onModerateMessage: (message, state) =>
                        _moderateThreadMessage(question, message, state),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final user = _activeUser!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${user.displayName.split(' ').first}',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'MedicoHub We Connect',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                    ],
                  ),
                ),
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(
                    user.isAdmin
                        ? Icons.admin_panel_settings_outlined
                        : user.isDoctor
                            ? Icons.medical_services_outlined
                            : Icons.favorite_border_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              user.isAdmin
                  ? 'Run the service, guide conversations, and keep the experience uncluttered.'
                  : user.isDoctor
                      ? 'Move from incoming questions to clear answers quickly.'
                      : 'Ask, follow, and learn through a lighter dashboard.',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(
                  avatar: const Icon(Icons.language_rounded, size: 18),
                  label: Text(_selectedLanguage),
                ),
                Chip(
                  avatar: const Icon(Icons.bolt_rounded, size: 18),
                  label: Text('${
                    _roleScopedQuestions.where((item) => item.status == 'open').length
                  } open threads'),
                ),
                Chip(
                  avatar: const Icon(Icons.auto_stories_rounded, size: 18),
                  label: Text('${_education.length} education items'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLinksCard(BuildContext context) {
    final items = <({IconData icon, String label, VoidCallback onTap})>[
      (
        icon: Icons.add_comment_outlined,
        label: 'Ask Question',
        onTap: () => setState(() => _tabIndex = 1),
      ),
      (
        icon: Icons.forum_outlined,
        label: 'My Questions',
        onTap: () => setState(() => _tabIndex = 2),
      ),
      (
        icon: Icons.auto_stories_outlined,
        label: 'Education',
        onTap: () => setState(() => _tabIndex = 3),
      ),
      (
        icon: Icons.person_outline_rounded,
        label: 'Profile',
        onTap: () => setState(() => _tabIndex = 4),
      ),
      (
        icon: Icons.settings_outlined,
        label: 'Settings',
        onTap: () => setState(() => _tabIndex = 4),
      ),
      (
        icon: Icons.info_outline_rounded,
        label: 'About',
        onTap: _showAboutSheet,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Links',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 760
                    ? 3
                    : constraints.maxWidth > 480
                        ? 2
                        : 1;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: crossAxisCount == 1 ? 4.4 : 2.7,
                  ),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return FilledButton.tonalIcon(
                      onPressed: item.onTap,
                      icon: Icon(item.icon),
                      label: Text(item.label),
                      style: FilledButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSponsoredCard(
    BuildContext context,
    AdCampaign campaign, {
    String label = 'Sponsored',
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(label),
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    campaign.sponsorName,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              campaign.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(campaign.subtitle),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton(
                onPressed: () => _launchAdCampaign(campaign),
                child: Text(campaign.ctaLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppActivationBadge(BuildContext context) {
    final activated = _isWhatsAppActivationCoolingDown;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: activated
                    ? Colors.green.withValues(alpha: 0.14)
                    : Theme.of(context).colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_rounded,
                color: activated ? Colors.green : Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      activated
                          ? 'WhatsApp ready for today'
                          : 'Activate WhatsApp notifications',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'How this works',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      activated
                          ? 'WhatsApp is already active for today on this device. You can review delivery settings from Settings.'
                          : 'Tap Activate to open the delivery-channel flow. Once WhatsApp is activated for the day, this badge will turn green.',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.info_outline_rounded),
            ),
            const SizedBox(width: 4),
            FilledButton(
              onPressed: _openNotificationSettingsTab,
              child: Text(activated ? 'Open' : 'Activate'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAskTab(BuildContext context) {
    final selectedDoctor = _selectedDoctor;
    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Ask clearly, avoid urgent/emergency issues here, and use the links if you want to review the latest MedicoHub notice.',
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () => _showLegalSheet(
                    title: _currentDisclaimerDocument.title,
                    body:
                        '${_currentDisclaimerDocument.body}\n\n$_currentRegionNote',
                  ),
                  child: const Text('Read notice'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _editingQuestionId == null
                      ? 'Submit a Question'
                      : 'Edit Question',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  _isAdminView
                      ? 'Pick a doctor, choose a broad heading, then use a plain-language title with patient terms like stroke, fits, or Parkinson\'s.'
                      : 'Choose the doctor and broad topic, then write a simple title using everyday health terms.',
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _selectedDoctorId,
                  decoration:
                      const InputDecoration(labelText: 'Doctor addressed'),
                  items: _doctors
                      .map(
                        (doctor) => DropdownMenuItem<String>(
                          value: doctor.id,
                          child: Text(doctor.displayName),
                        ),
                      )
                      .toList(),
                  onChanged: _editingQuestionId == null
                      ? (value) {
                          if (value != null) {
                            setState(() => _selectedDoctorId = value);
                          }
                        }
                      : null,
                ),
                if (selectedDoctor != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _isAdminView
                        ? 'Doctor languages: ${selectedDoctor.languages.join(', ')} • specialties: ${selectedDoctor.specialties.join(', ')}'
                        : 'Doctor specialty: ${selectedDoctor.specialties.join(', ')}',
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedQuestionCategory,
                  decoration:
                      const InputDecoration(labelText: 'General heading'),
                  items: _availableQuestionTopics
                      .map(
                        (category) => DropdownMenuItem<String>(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedQuestionCategory = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedLanguage,
                  decoration:
                      const InputDecoration(labelText: 'Question language'),
                  items: _languageLocales.keys
                      .map(
                        (language) => DropdownMenuItem<String>(
                          value: language,
                          child: Text(language),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedLanguage = value;
                        _selectedTemplateId = '_custom';
                      });
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedSpecialty,
                  decoration: const InputDecoration(labelText: 'Topic area'),
                  items: _specialties
                      .map(
                        (specialty) => DropdownMenuItem<String>(
                          value: specialty,
                          child: Text(specialty),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedSpecialty = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedTemplateId,
                  decoration:
                      const InputDecoration(labelText: 'Title example'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: '_custom',
                      child: Text('Custom title'),
                    ),
                    ..._visibleTitleTemplates.map(
                      (template) => DropdownMenuItem<String>(
                        value: template.id,
                        child: Text(template.title),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedTemplateId = value;
                      if (value == '_custom') {
                        return;
                      }
                      final template = _visibleTitleTemplates.firstWhere(
                        (item) => item.id == value,
                      );
                      _titleController.text = template.title;
                      _selectedSpecialty = template.specialty;
                    });
                  },
                ),
                const SizedBox(height: 12),
                Tooltip(
                  message:
                      'Use simple, searchable words like stroke, fits, tremor, Parkinson, migraine, or dizziness so question classification works better later.',
                  child: TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Title',
                      helperText: _isAdminView
                          ? 'Tip: include simple terms such as stroke, fits, Parkinson, tremor, or migraine.'
                          : 'Use simple condition words when possible.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyController,
                  maxLines: 5,
                  decoration:
                      const InputDecoration(labelText: 'Question details'),
                ),
                const SizedBox(height: 12),
                _buildVoiceCaptureCard(context),
                const SizedBox(height: 12),
                TextField(
                  controller: _symptomsController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Symptoms summary / current diagnosis',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedExpiry,
                  decoration:
                      const InputDecoration(labelText: 'Attachment expiry'),
                  items: const [
                    DropdownMenuItem(value: '24h', child: Text('24 hours')),
                    DropdownMenuItem(value: '7d', child: Text('7 days')),
                    DropdownMenuItem(value: '30d', child: Text('30 days')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedExpiry = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _premium,
                  onChanged: (value) => setState(() => _premium = value),
                  title: const Text('Paid second opinion'),
                  subtitle: const Text(
                      'Use for non-prescriptive educational review.'),
                ),
                SwitchListTile(
                  value: _editingQuestionId == null
                      ? false
                      : _roleScopedQuestions
                              .firstWhere(
                                (question) =>
                                    question.id == _editingQuestionId,
                                orElse: () => const ForumQuestion(
                                  id: '',
                                  title: '',
                                  body: '',
                                  type: 'forum',
                                  headingGroup: 'General',
                                  language: 'English',
                                  tags: [],
                                  premium: false,
                                  status: 'open',
                                  aiSummary: '',
                                  responseCount: 0,
                                  authorId: '',
                                  targetDoctorId: '',
                                  responses: [],
                                  threadMessages: [],
                                  createdAt: '',
                                  updatedAt: '',
                                ),
                              )
                              .isPublic ||
                          false,
                  onChanged: (_) {},
                  title: const Text('Current public status'),
                  subtitle: Text(_isAdminView
                      ? 'Change visibility from the My Questions list using the Public/Private action.'
                      : 'You can change visibility later from My Questions.'),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text(_selectedQuestionCategory)),
                    Chip(label: Text(_selectedLanguage)),
                    Chip(label: Text(_selectedSpecialty)),
                    if (_premium) const Chip(label: Text('Second opinion')),
                  ],
                ),
                const SizedBox(height: 16),
                _buildAttachmentPanel(context),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: _submitting ? null : _submitQuestion,
                      child:
                          Text(_submitting ? 'Saving...' : _editingQuestionId == null ? 'Submit Question' : 'Save Changes'),
                    ),
                    if (_editingQuestionId != null)
                      OutlinedButton(
                        onPressed: _cancelEditingQuestion,
                        child: const Text('Cancel Edit'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionsTab(BuildContext context) {
    final user = _activeUser!;
    final myQuestions = _filteredQuestionsForScope(_QuestionFeedScope.mine);
    final publicQuestions = _filteredQuestionsForScope(_QuestionFeedScope.public);
    if (user.isDoctor) {
      return ListView(
        children: [
          _buildQuestionFilterCard(context),
          const SizedBox(height: 16),
          _buildQuestionListSection(
            context,
            title: 'Current',
            questions: _doctorCurrentQuestions.where(_questionMatchesDateFilter).where((question) {
              if (_questionFilterTopic == null || _questionFilterTopic!.isEmpty) {
                return true;
              }
              return question.headingGroup == _questionFilterTopic;
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildQuestionListSection(
            context,
            title: 'History',
            questions: _doctorHistoryQuestions.where(_questionMatchesDateFilter).where((question) {
              if (_questionFilterTopic == null || _questionFilterTopic!.isEmpty) {
                return true;
              }
              return question.headingGroup == _questionFilterTopic;
            }).toList(),
          ),
        ],
      );
    }
    return Column(
      children: [
        _buildQuestionFilterCard(context),
        const SizedBox(height: 16),
        Expanded(
          child: DefaultTabController(
            length: 2,
            initialIndex: _questionFeedScope.index,
            child: Column(
              children: [
                TabBar(
                  onTap: (index) => setState(
                    () => _questionFeedScope = _QuestionFeedScope.values[index],
                  ),
                  tabs: const [
                    Tab(text: 'My Questions'),
                    Tab(text: 'Public Questions'),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: TabBarView(
                    children: [
                      SingleChildScrollView(
                        child: _buildQuestionListSection(
                          context,
                          title: 'My Questions',
                          questions: myQuestions,
                        ),
                      ),
                      SingleChildScrollView(
                        child: _buildQuestionListSection(
                          context,
                          title: 'Public Questions',
                          questions: publicQuestions,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionFilterCard(BuildContext context) {
    final range = _customQuestionRange;
    final rangeLabel = range == null
        ? 'Select dates'
        : '${range.start.day}/${range.start.month}/${range.start.year} → ${range.end.day}/${range.end.month}/${range.end.year}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort & Filter',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            DropdownButtonFormField<_QuestionDateFilter>(
              initialValue: _questionDateFilter,
              decoration: const InputDecoration(labelText: 'Date range'),
              items: _QuestionDateFilter.values
                  .map(
                    (value) => DropdownMenuItem<_QuestionDateFilter>(
                      value: value,
                      child: Text(value.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) async {
                if (value == null) {
                  return;
                }
                if (value == _QuestionDateFilter.customRange) {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: _customQuestionRange,
                  );
                  if (picked == null) {
                    return;
                  }
                  setState(() {
                    _customQuestionRange = picked;
                    _questionDateFilter = value;
                  });
                  return;
                }
                setState(() {
                  _questionDateFilter = value;
                });
              },
            ),
            if (_questionDateFilter == _QuestionDateFilter.customRange) ...[
              const SizedBox(height: 8),
              Text(rangeLabel),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _questionFilterTopic,
              decoration: const InputDecoration(labelText: 'Topic filter'),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All topics'),
                ),
                ..._availableQuestionTopics.map(
                  (topic) => DropdownMenuItem<String?>(
                    value: topic,
                    child: Text(topic),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _questionFilterTopic = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerAdCard() {
    if (!_bannerReady || _bannerAd == null || !_supportsMobileAds) {
      return const SizedBox.shrink();
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: _bannerAd!.size.width.toDouble(),
            height: _bannerAd!.size.height.toDouble(),
            child: AdWidget(ad: _bannerAd!),
          ),
        ),
      ),
    );
  }

  Widget _buildEducationTab(BuildContext context) {
    return ListView(
      children: [
        if (_blogArticles.isNotEmpty) ...[
          Text('Doctor Blog', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ..._blogArticles.expand(
            (article) {
              final campaigns = _matchingCampaignsForText(
                placement: 'blog',
                primaryText: article.title,
                secondaryText: '${article.summary} ${article.body}',
                category: article.category,
                language: article.language,
              ).take(1);
              return <Widget>[
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(article.category.toUpperCase(),
                              style: Theme.of(context).textTheme.labelLarge),
                          const SizedBox(height: 8),
                          Text(article.title,
                              style: Theme.of(context).textTheme.titleLarge),
                          const SizedBox(height: 8),
                          Text('By ${article.authorName} • ${article.language}'),
                          const SizedBox(height: 12),
                          Text(article.summary),
                          const SizedBox(height: 12),
                          Text(article.body),
                        ],
                      ),
                    ),
                  ),
                ),
                for (final campaign in campaigns)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildSponsoredCard(
                      context,
                      campaign,
                      label: 'Sponsored with this topic',
                    ),
                  ),
              ];
            },
          ),
          const SizedBox(height: 8),
        ],
        Text('Education Library', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ..._education.expand(
          (item) {
            final campaigns = _matchingCampaignsForText(
              placement: 'education',
              primaryText: item.title,
              secondaryText: item.summary,
              category: item.category,
              language: item.language,
            ).take(1);
            return <Widget>[
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.category.toUpperCase(),
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 8),
                        Text(item.title,
                            style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text(item.summary),
                        const SizedBox(height: 12),
                        Text('${item.type} • ${item.durationMinutes} min • ${item.language}'),
                      ],
                    ),
                  ),
                ),
              ),
              for (final campaign in campaigns)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSponsoredCard(
                    context,
                    campaign,
                    label: 'Sponsored resource',
                  ),
                ),
            ];
          },
        ),
        if (_bannerReady) ...[
          const SizedBox(height: 12),
          _buildBannerAdCard(),
        ],
      ],
    );
  }

  Widget _buildQuestionListSection(
    BuildContext context, {
    required String title,
    required List<ForumQuestion> questions,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            if (questions.isEmpty)
              const Text('No threads in this section yet.')
            else
              ...questions.expand(
                (question) {
                  final campaigns = _matchingCampaignsForText(
                    placement: 'question',
                    primaryText: question.title,
                    secondaryText:
                        '${question.body} ${question.aiSummary} ${question.responses.map((item) => item.fullText).join(' ')}',
                    category: question.headingGroup,
                    language: question.language,
                  ).take(1);
                  return <Widget>[
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _QuestionCard(
                        question: question,
                        followUpLabel: _activeUser?.isDoctor == true
                            ? 'Comment on Thread'
                            : 'Add Follow-up',
                        onEdit: _canEditQuestion(question)
                            ? () => _startEditingQuestion(question)
                            : null,
                        onTogglePublic: _canEditQuestion(question)
                            ? () => _toggleQuestionVisibility(question)
                            : null,
                        onDelete: _canEditQuestion(question)
                            ? () => _deleteQuestion(question)
                            : null,
                        onRespond: _canRespondToQuestion(question)
                            ? () => _openDoctorResponseDialog(question)
                            : null,
                        onAddFollowUp: _canAddFollowUp(question)
                            ? () => _openThreadMessageDialog(question)
                            : null,
                        canModerateMessage: (message) =>
                            _canModerateThreadMessage(question, message),
                        onModerateMessage: (message, state) =>
                            _moderateThreadMessage(question, message, state),
                      ),
                    ),
                    for (final campaign in campaigns)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildSponsoredCard(
                          context,
                          campaign,
                          label: 'Sponsored resource',
                        ),
                      ),
                  ];
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTab(BuildContext context) {
    final user = _activeUser!;
    return ListView(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile & Account',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.person_outline_rounded),
                  ),
                  title: Text(user.displayName),
                  subtitle: Text('${user.email}\n${user.role} • ${user.languages.join(', ')}'),
                  isThreeLine: true,
                ),
                if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('Mobile: ${user.phoneNumber}'),
                  ),
                Text(
                  'Biometric quick sign-in is planned for a dedicated secure-storage update, so account access remains stable across Android, iPhone, and Windows today.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Settings', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                DropdownButtonFormField<MedicoHubThemePreset>(
                  initialValue: widget.themeConfig.preset,
                  decoration: const InputDecoration(labelText: 'App theme'),
                  items: MedicoHubThemePreset.values
                      .map(
                        (preset) => DropdownMenuItem<MedicoHubThemePreset>(
                          value: preset,
                          child: Text(preset.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _applyThemeSelection(preset: value);
                    }
                  },
                ),
                if (widget.themeConfig.preset == MedicoHubThemePreset.custom) ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _themeHexController,
                    decoration: InputDecoration(
                      labelText: 'Custom accent HEX',
                      helperText: 'Use #RRGGBB or #AARRGGBB',
                      errorText: _themeHexInvalid
                          ? 'Please use only valid HEX characters (0-9, A-F).'
                          : null,
                    ),
                    onChanged: (_) {
                      if (_themeHexInvalid) {
                        setState(() => _themeHexInvalid = false);
                      }
                    },
                    onSubmitted: (value) {
                      _applyThemeSelection(
                        preset: MedicoHubThemePreset.custom,
                        customHex: value,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _customThemeDarkMode
                          ? const Color(0xFF0F172A)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: safeThemeSeedColor(_themeHexController.text),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Current accent',
                                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: _customThemeDarkMode ? Colors.white70 : null,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _themeHexController.text.isEmpty
                                    ? widget.themeConfig.customSeedHex
                                    : _themeHexController.text,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: _customThemeDarkMode ? Colors.white : null,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        FilledButton.tonal(
                          onPressed: _openThemeColorStudio,
                          child: const Text('Open Color Studio'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kThemeHexPalette
                        .map(
                          (hex) => InkWell(
                            onTap: () {
                              _themeHexController.text = hex;
                              _applyThemeSelection(
                                preset: MedicoHubThemePreset.custom,
                                customHex: hex,
                              );
                            },
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: safeThemeSeedColor(hex),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: widget.themeConfig.customSeedHex == hex
                                      ? Theme.of(context).colorScheme.onSurface
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _customThemeDarkMode,
                    onChanged: (value) {
                      setState(() => _customThemeDarkMode = value);
                      _applyThemeSelection(
                        preset: MedicoHubThemePreset.custom,
                        customHex: _themeHexController.text,
                        customDarkMode: value,
                      );
                    },
                    title: const Text('Use dark surfaces for custom theme'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
                const SizedBox(height: 12),
                Text('Current app version: $_currentVersion'),
                const SizedBox(height: 8),
                if (_isAdminView) ...[
                  const Text(
                    'Admin notes remain visible here so rollout planning, ad setup, and later legal-provider replacement stay easy to manage from the app.',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'WhatsApp is the primary live notification channel today. Email delivery stays in preview mode until a dedicated sender setup is finalized.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'If you later switch legal text to a service like iubenda, this section can be simplified further.',
                  ),
                ] else
                  Text(
                    'Notifications, updates, and theme choices can be managed here.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Updates',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<UpdateCheckFrequency>(
                  initialValue: _updateFrequency,
                  decoration:
                      const InputDecoration(labelText: 'Check for updates'),
                  items: UpdateCheckFrequency.values
                      .map(
                        (value) => DropdownMenuItem<UpdateCheckFrequency>(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() => _updateFrequency = value);
                    unawaited(_persistUpdatePreferences());
                  },
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _updateAutoOpen,
                  onChanged: (value) {
                    setState(() => _updateAutoOpen = value);
                    unawaited(_persistUpdatePreferences());
                  },
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-open update download when detected'),
                  subtitle: const Text(
                    'Useful for Android APK updates. Windows still requires normal download/extract steps.',
                  ),
                ),
                if (_updateInfo != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Latest available: ${_updateInfo!.latestVersion}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._updateInfo!.releaseNotes.map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $note'),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: _checkForUpdatesNow,
                      child: const Text('Check Now'),
                    ),
                    if (_updateInfo != null)
                      FilledButton(
                        onPressed: _openUpdateDownload,
                        child: Text(
                          Platform.isAndroid ? 'Download APK' : 'Open Update',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Ad Delivery',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _useTestAds,
                  onChanged: _supportsMobileAds
                      ? (value) {
                          setState(() => _useTestAds = value);
                          unawaited(_persistAdPreferences());
                          unawaited(_reloadAds());
                        }
                      : null,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Use test ads on this device'),
                  subtitle: Text(
                    _useTestAds
                        ? 'Safe for QA while Play Store / App Store ad serving is still being finalized.'
                        : 'Use live AdMob units. If serving is limited, the diagnostics below will show why the app is not receiving fill.',
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mode: $_adModeLabel',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Text('Banner: $_bannerAdStatus'),
                      const SizedBox(height: 6),
                      Text('App open: $_appOpenAdStatus'),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: _supportsMobileAds ? _reloadAds : null,
                      child: const Text('Reload Ads'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: _openChangePasswordDialog,
                      child: const Text('Update Password'),
                    ),
                    OutlinedButton(
                      onPressed: _sendPasswordReset,
                      child: const Text('Send Reset Email'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account deletion',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Permanently delete your sign-in account and MedicoHub profile. Your own question threads are removed from public lists.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: _deleteAccountBusy ? null : _openDeleteAccountDialog,
                        icon: _deleteAccountBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.delete_forever_outlined),
                        label: const Text('Delete Account'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: _signOut,
                  child: const Text('Sign Out'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Delivery Channels',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.chat_bubble_outline),
                  title: const Text('WhatsApp notifications'),
                  subtitle: Text(
                    _notificationSettings == null
                        ? 'Live now for question creation, answers, and thread updates.'
                        : (_isAdminView
                            ? 'Live now for question creation, answers, and thread updates. If you are using the Twilio sandbox, send "${_notificationSettings!.whatsAppActivationPhrase}" to ${_notificationSettings!.whatsAppActivationTarget} once per day to activate notifications.'
                            : 'Live now for question creation, answers, and thread updates. If today’s WhatsApp alert is inactive, use the activation button below.'),
                  ),
                  trailing: Chip(
                    label: Text(
                      _whatsAppNotifications.any((item) => item.status == 'sent')
                          ? 'Active'
                          : 'Configured',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isWhatsAppActivationCoolingDown
                            ? null
                            : _activateWhatsAppFor24Hours,
                        icon: const Icon(Icons.chat_outlined),
                        label: Text(
                          _isWhatsAppActivationCoolingDown
                              ? 'WhatsApp active for today'
                              : 'Activate WhatsApp for 24 hours',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _isWhatsAppActivationCoolingDown
                      ? 'This button will reactivate after local midnight on this device.'
                      : 'Tapping the button opens WhatsApp with the current sandbox activation text already filled in. After pressing Send in WhatsApp, come back and confirm activation.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('Email notifications'),
                  subtitle: Text(
                    _notificationSettings?.emailStatusNote ??
                        'Coming later once a dedicated sender domain is finalized.',
                  ),
                  trailing: const Chip(label: Text('Preview only')),
                ),
                if (_canConfigureNotificationSettings) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Admin controls',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notificationTargetController,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp activation target',
                      helperText: 'Example: +14155238886',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notificationPhraseController,
                    decoration: const InputDecoration(
                      labelText: 'WhatsApp activation phrase',
                      helperText: 'Example: join cloud-tired',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _emailStatusNoteController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Email status note',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saveNotificationSettings,
                    child: const Text('Save Delivery Settings'),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (user.isAdmin) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin: Topics & Notices',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Manage the question topic list used in Ask Question and the question filters. The multilingual notice is shown during consent and before first posting.',
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This is intentionally lightweight for now, so a later legal-text provider such as iubenda can replace or refine it without major app rewrites.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _topicEditorController,
                    decoration: const InputDecoration(
                      labelText: 'Add topic',
                      helperText:
                          'Examples: Related to my imaging, Insurance, Rehabilitation',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _appSettingsBusy ? null : _addQuestionTopic,
                    child: const Text('Add Topic'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _availableQuestionTopics
                        .map(
                          (topic) => InputChip(
                            label: Text(topic),
                            onDeleted: _availableQuestionTopics.length <= 1
                                ? null
                                : () => _removeQuestionTopic(topic),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _disclaimerRegionNoteController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Default region note',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _appSettingsBusy
                        ? null
                        : () => _saveAppSettings(),
                    child: const Text('Save Notice Settings'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sponsored Content',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Create subtle sponsored cards that are matched to blog topics and the health terms used in question-and-answer threads.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _adSponsorController,
                    decoration:
                        const InputDecoration(labelText: 'Sponsor label'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _adTitleController,
                    decoration:
                        const InputDecoration(labelText: 'Ad headline'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _adSubtitleController,
                    maxLines: 2,
                    decoration:
                        const InputDecoration(labelText: 'Short description'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _adUrlController,
                    decoration:
                        const InputDecoration(labelText: 'Target URL'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _adCtaController,
                    decoration: const InputDecoration(labelText: 'CTA label'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _adKeywordsController,
                    decoration: const InputDecoration(
                      labelText: 'Keywords',
                      helperText:
                          'Comma-separated terms such as stroke, migraine, tremor, diabetes',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _adCategoriesController,
                    decoration: const InputDecoration(
                      labelText: 'Categories',
                      helperText:
                          'Optional comma-separated categories like Neurology or General',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAdPlacement,
                    decoration:
                        const InputDecoration(labelText: 'Placement'),
                    items: _adPlacements
                        .map(
                          (placement) => DropdownMenuItem<String>(
                            value: placement,
                            child: Text(placement),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedAdPlacement = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAdLanguage,
                    decoration:
                        const InputDecoration(labelText: 'Language focus'),
                    items: [
                      const DropdownMenuItem<String>(
                        value: 'All',
                        child: Text('All languages'),
                      ),
                      ..._languageLocales.keys.map(
                        (language) => DropdownMenuItem<String>(
                          value: language,
                          child: Text(language),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedAdLanguage = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _adPriorityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Priority',
                      helperText: 'Higher numbers appear first',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _createAdCampaign,
                    child: const Text('Create Sponsored Card'),
                  ),
                  if (_adCampaigns.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Current sponsored cards',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    ..._adCampaigns.take(8).map(
                      (campaign) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(campaign.title),
                        subtitle: Text(
                          '${campaign.sponsorName} • ${campaign.placements.join(', ')} • priority ${campaign.priority}',
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            Chip(
                              label: Text(
                                campaign.active ? 'Active' : 'Paused',
                              ),
                            ),
                            TextButton(
                              onPressed: () => _toggleAdCampaignActive(campaign),
                              child: Text(
                                campaign.active ? 'Pause' : 'Resume',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
        if (_canManageDoctorDirectory) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin Module',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  const Text(
                    'Admins can add more doctors here. Those doctors can then complete Firebase sign-up using their invited email/phone.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _doctorInviteNameController,
                    decoration:
                        const InputDecoration(labelText: 'Doctor name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _doctorInviteEmailController,
                    decoration:
                        const InputDecoration(labelText: 'Doctor email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _doctorInvitePhoneController,
                    decoration:
                        const InputDecoration(labelText: 'Doctor phone'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _inviteDoctorSpecialty,
                    decoration:
                        const InputDecoration(labelText: 'Doctor specialty'),
                    items: _specialties
                        .map(
                          (specialty) => DropdownMenuItem<String>(
                            value: specialty,
                            child: Text(specialty),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _inviteDoctorSpecialty = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _inviteDoctorLanguage,
                    decoration:
                        const InputDecoration(labelText: 'Doctor language'),
                    items: _languageLocales.keys
                        .map(
                          (language) => DropdownMenuItem<String>(
                            value: language,
                            child: Text(language),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _inviteDoctorLanguage = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _adminBusy ? null : _inviteDoctorFromAdmin,
                    child: Text(_adminBusy ? 'Saving...' : 'Add Doctor'),
                  ),
                  const SizedBox(height: 16),
                  Text('Doctor Directory',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ..._doctors.map(
                    (doctor) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.medical_services_outlined),
                        title: Text(doctor.displayName),
                        subtitle: Text(
                          '${doctor.role} • ${doctor.specialties.join(', ')} • ${doctor.languages.join(', ')}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin: Title Templates',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  const Text(
                    'These examples help users create clearer searchable titles before AI-style classification arrives.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _adminTitleController,
                    decoration:
                        const InputDecoration(labelText: 'New title example'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _adminBusy ? null : _createAdminTitleTemplate,
                    child:
                        Text(_adminBusy ? 'Saving...' : 'Add Title Example'),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (user.isDoctor) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Doctor Publishing',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  const Text(
                    'Publish patient-friendly blog posts that appear in the Education tab. Comment threads and moderation actions will be added next.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _articleTitleController,
                    decoration: const InputDecoration(labelText: 'Article title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _articleSummaryController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Short summary'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _articleBodyController,
                    maxLines: 5,
                    decoration: const InputDecoration(labelText: 'Article body'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _articleCategory,
                    decoration: const InputDecoration(labelText: 'Article category'),
                    items: _specialties
                        .map(
                          (specialty) => DropdownMenuItem<String>(
                            value: specialty,
                            child: Text(specialty),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _articleCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _adminBusy ? null : _publishDoctorArticle,
                    child: Text(_adminBusy ? 'Publishing...' : 'Publish Article'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Doctor Sharing & Outreach',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  const Text(
                    'Doctors will be able to invite patients, share the app, publish blog posts, and moderate blog comments from this area in the next module.',
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_whatsAppNotifications.isNotEmpty ||
            _emailComingLaterNotifications.isNotEmpty) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('WhatsApp Delivery Center',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  const Text(
                    'These are the live WhatsApp notifications MedicoHub is tracking right now for questions, answers, and thread updates.',
                  ),
                  if (_emailComingLaterNotifications.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Email delivery is intentionally parked in preview mode for now (${_emailComingLaterNotifications.length} queued items).',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  ..._whatsAppNotifications.take(8).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.chat_bubble_outline),
                        title: Text('WhatsApp • ${item.subject}'),
                        subtitle: Text(
                          '${item.recipientName} • ${item.eventType} • ${_notificationStatusLabel(item)} • ${_formatTimestamp(item.createdAt)}',
                        ),
                        trailing: item.deepLink == null
                            ? null
                            : TextButton(
                                onPressed: () => _openNotificationLink(item.deepLink!),
                                child: const Text('Open Chat'),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVoiceCaptureCard(BuildContext context) {
    final hasAudio = _audioAttachmentPath != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voice Input',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              Platform.isAndroid
                  ? 'Android path: use Gboard or an Indic keyboard mic for quick speech-to-text, or record an audio note.'
                  : 'Windows path: record an audio note, preview it, redo it if needed, then upload it.',
            ),
            if (_voiceStatus != null) ...[
              const SizedBox(height: 12),
              Text(
                _voiceStatus!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.primary),
              ),
            ],
            if (_audioAttachmentPath != null) ...[
              const SizedBox(height: 8),
              Text('Latest audio note: $_audioAttachmentPath'),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed:
                      _recordingAudio ? _stopAudioRecording : _startAudioRecording,
                  icon: Icon(_recordingAudio
                      ? Icons.stop_circle_outlined
                      : Icons.mic_none_outlined),
                  label: Text(_recordingAudio
                      ? 'Stop Audio Note'
                      : 'Record Audio Note'),
                ),
                OutlinedButton.icon(
                  onPressed: hasAudio ? _toggleAudioPreview : null,
                  icon: Icon(_audioPreviewPlaying
                      ? Icons.stop_outlined
                      : Icons.play_arrow_outlined),
                  label: Text(
                      _audioPreviewPlaying ? 'Stop Preview' : 'Preview Audio'),
                ),
                OutlinedButton.icon(
                  onPressed: hasAudio ? _deleteAudioNote : null,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete / Redo'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      _listeningNative ? _stopNativeListening : _startNativeListening,
                  icon: Icon(_listeningNative
                      ? Icons.hearing_disabled_outlined
                      : Icons.hearing_outlined),
                  label: Text(_listeningNative
                      ? 'Stop Native Listen'
                      : 'Try Native Listen'),
                ),
                TextButton.icon(
                  onPressed: _showKeyboardVoiceHelp,
                  icon: const Icon(Icons.keyboard_voice_outlined),
                  label: const Text('Keyboard Mic Help'),
                ),
                OutlinedButton.icon(
                  onPressed:
                      hasAudio && !_uploadingAttachment ? _uploadRecordedAudio : null,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: const Text('Upload Audio Note'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentPanel(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reports & Attachments',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            const Text(
              'Users and doctors can attach PDFs, images, lab reports, or recorded audio notes. Expiry metadata is preserved on upload.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _uploadingAttachment ? null : _pickAndUploadReport,
              icon: const Icon(Icons.attach_file_outlined),
              label:
                  Text(_uploadingAttachment ? 'Uploading...' : 'Add Report File'),
            ),
            const SizedBox(height: 12),
            if (_uploadedAttachments.isEmpty)
              const Text('No attachments uploaded yet.')
            else
              ..._uploadedAttachments.map(
                (attachment) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.insert_drive_file_outlined),
                    title: Text(attachment.fileName),
                    subtitle: Text(
                        '${attachment.mimeType} • expires ${attachment.expiresAt}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () => _removeAttachment(attachment),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _signInWithFirebase() async {
    final email = _formattedSignInDestination;
    if (!_isSignInUsingEmail) {
      setState(() {
        _errorMessage =
            'Password sign-in currently works with email. Switch the first field to Email or choose OTP for mobile sign-in.';
      });
      return;
    }
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Enter a valid email address to continue.';
      });
      return;
    }
    setState(() {
      _authBusy = true;
      _errorMessage = null;
    });
    try {
      await _api.waitUntilReady();
      final firebaseUser = await _auth.signInWithEmail(
        email: email,
        password: _passwordController.text,
      );
      final profile = await _loadOrCreateBackendProfile(firebaseUser);
      if (!mounted) {
        return;
      }
      setState(() {
        _activeUser = profile;
        _selectedLanguage =
            profile.languages.isEmpty ? _selectedLanguage : profile.languages.first;
        _authBusy = false;
        _emailController.text = email;
        _phoneController.text = profile.phoneNumber ?? _phoneController.text;
        _resetOtpJourney();
      });
      await _persistAuthPreferences(
        email: email,
        phone: profile.phoneNumber,
      );
      await _refreshNotifications(profile.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _authBusy = false;
        _errorMessage = 'Firebase sign-in failed: ${_firebaseFriendlyError(error)}';
      });
    }
  }

  Future<void> _registerFirebaseUser() async {
    setState(() {
      _authBusy = true;
      _errorMessage = null;
    });
    try {
      await _api.waitUntilReady();
      _prevalidateRegistration();
      final firebaseUser = await _auth.registerWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        displayName: _displayNameController.text.trim().isEmpty
            ? _emailController.text.trim()
            : _displayNameController.text.trim(),
      );
      final profile = await _api.upsertUserProfile(
        id: firebaseUser.id,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName,
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        role: _selectedAccountRole,
        languages: [_selectedLanguage],
        specialties:
            _selectedAccountRole == 'patient' ? const [] : [_selectedSpecialty],
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _activeUser = profile;
        _authBusy = false;
        _selectedSignInChannel = 'Email';
        _syncSignInIdentifierWithSelection();
      });
      await _persistAuthPreferences(
        email: profile.email,
        phone: profile.phoneNumber,
      );
      await _refreshNotifications(profile.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _authBusy = false;
        _errorMessage =
            'Firebase registration failed: ${_firebaseFriendlyError(error)}';
      });
    }
  }

  void _prevalidateRegistration() {
    final email = _normalizeEmail(_emailController.text);
    final phone = _normalizePhone(_phoneController.text);
    if (_selectedAccountRole == 'patient') {
      return;
    }

    final rosterMatch = _matchedRosterUser;
    final rosterMatchesIdentity = rosterMatch != null &&
        (_normalizeEmail(rosterMatch.email) == email ||
            (phone.isNotEmpty &&
                _normalizePhone(rosterMatch.phoneNumber) == phone));
    if (rosterMatchesIdentity) {
      if (_selectedAccountRole == 'doctor' &&
          (rosterMatch.role == 'doctor' || rosterMatch.role == 'admin')) {
        return;
      }
      if (_selectedAccountRole == 'admin' && rosterMatch.role == 'admin') {
        return;
      }
    }

    final matchingDoctor = _doctors.where((doctor) {
      return _normalizeEmail(doctor.email) == email ||
          (phone.isNotEmpty &&
              _normalizePhone(doctor.phoneNumber) == phone);
    }).toList();

    if (_selectedAccountRole == 'doctor' && matchingDoctor.isEmpty) {
      throw Exception(
        'This doctor account is not yet in the MedicoHub doctor directory. An admin must add the doctor first.',
      );
    }

    if (_selectedAccountRole == 'admin' &&
        !matchingDoctor.any((doctor) => doctor.role == 'admin')) {
      throw Exception(
        'This admin email or phone is not on the MedicoHub admin allowlist.',
      );
    }
  }

  void _scheduleIdentityLookup() {
    _emailLookupDebounce?.cancel();
    _emailLookupDebounce = Timer(
      const Duration(milliseconds: 350),
      _lookupIdentityForCurrentEmail,
    );
  }

  Future<void> _lookupIdentityForCurrentEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      if (!mounted) {
        return;
      }
      setState(() {
        _matchedRosterUser = null;
        _identityLookupBusy = false;
        _authLookupMessage = null;
      });
      return;
    }

    setState(() {
      _identityLookupBusy = true;
    });

    try {
      final matched = await _api.lookupUserByEmail(email);
      if (!mounted || _emailController.text.trim() != email) {
        return;
      }
      if (matched == null) {
        setState(() {
          _matchedRosterUser = null;
          _identityLookupBusy = false;
          _createAccountMode = true;
          _selectedAccountRole = 'patient';
          _authLookupMessage =
              'No existing MedicoHub roster match found for this email. Create Account is recommended.';
        });
        return;
      }

      setState(() {
        _matchedRosterUser = matched;
        _displayNameController.text = matched.displayName;
        _phoneController.text = matched.phoneNumber ?? '';
        _selectedAccountRole = matched.role;
        if (matched.languages.isNotEmpty) {
          _selectedLanguage = matched.languages.first;
        }
        if (matched.specialties.isNotEmpty) {
          _selectedSpecialty = matched.specialties.first;
        }
        _identityLookupBusy = false;
        _createAccountMode = false;
        _authLookupMessage =
            'Existing ${matched.role} found: ${matched.displayName}. Use Sign In to continue.';
      });
    } catch (error) {
      if (!mounted || _emailController.text.trim() != email) {
        return;
      }
      setState(() {
        _identityLookupBusy = false;
        _authLookupMessage = 'Could not verify this email yet: $error';
      });
    }
  }

  Future<void> _useBackendDemoUser() async {
    setState(() {
      _authBusy = true;
      _errorMessage = null;
    });
    try {
      final user = await _api.loginAsDemo(_emailController.text.trim());
      if (!mounted) {
        return;
      }
      setState(() {
        _activeUser = user;
        _selectedLanguage =
            user.languages.isEmpty ? _selectedLanguage : user.languages.first;
        _authBusy = false;
      });
      await _refreshNotifications(user.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _authBusy = false;
        _errorMessage = 'Demo login failed: $error';
      });
    }
  }

  Future<void> _requestInlineOtp() async {
    final destination = _formattedSignInDestination;
    if (destination.isEmpty) {
      setState(() {
        _errorMessage = _isSignInUsingEmail
            ? 'Enter your email address before requesting an OTP.'
            : 'Enter your mobile number before requesting an OTP.';
      });
      return;
    }
    setState(() {
      _authBusy = true;
      _errorMessage = null;
      _otpStatusMessage = null;
    });
    try {
      if (!_isSignInUsingEmail) {
        final verificationId = await _auth.requestPhoneOtp(
          phoneNumber: destination,
          onAutoVerified: (firebaseUser) async {
            await _completePhoneSignIn(firebaseUser);
          },
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _authBusy = false;
          _otpRequested = true;
          _otpRequestedDestination = destination;
          _phoneVerificationId = verificationId;
          _otpStatusMessage =
              'OTP sent by Firebase. Enter the SMS code when it arrives.';
        });
        return;
      }
      final result = await _api.requestOtp(
        destination: destination,
        channel: 'email',
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _authBusy = false;
        _otpRequested = true;
        _otpRequestedDestination = destination;
        _otpStatusMessage = result.deliveryStatus == 'preview_only' &&
                _isSignInUsingEmail
            ? 'Email OTP is still in preview mode while MedicoHub completes its dedicated sender setup. Mobile OTP or password sign-in is more reliable for now.'
            : result.previewMessage ?? 'OTP sent successfully.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _authBusy = false;
        _errorMessage = 'Could not request OTP right now. Please try again.';
        _otpStatusMessage = null;
      });
    }
  }

  Future<void> _verifyInlineOtp() async {
    if (!_otpRequested) {
      setState(() {
        _errorMessage = 'Tap Send OTP first, then enter the code to continue.';
      });
      return;
    }
    if (_otpCodeController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Enter the OTP code to continue.';
      });
      return;
    }
    setState(() {
      _authBusy = true;
      _errorMessage = null;
    });
    try {
      if (!_isSignInUsingEmail) {
        final verificationId = _phoneVerificationId;
        if (verificationId == null || verificationId.isEmpty) {
          throw Exception('No Firebase phone verification session is active.');
        }
        final firebaseUser = await _auth.verifyPhoneOtp(
          verificationId: verificationId,
          smsCode: _otpCodeController.text.trim(),
        );
        await _completePhoneSignIn(firebaseUser);
        return;
      }
      final destination = _otpRequestedDestination ?? _formattedSignInDestination;
      final profile = await _api.verifyOtp(
        destination: destination,
        channel: 'email',
        code: _otpCodeController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _activeUser = profile;
        _selectedLanguage =
            profile.languages.isEmpty ? _selectedLanguage : profile.languages.first;
        _emailController.text = profile.email;
        _phoneController.text = profile.phoneNumber ?? _phoneController.text;
        _authBusy = false;
        _voiceStatus = 'Signed in successfully.';
        _resetOtpJourney();
      });
      await _refreshNotifications(profile.id);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _authBusy = false;
        _errorMessage = 'Could not verify the OTP. Please try again.';
      });
    }
  }

  Future<void> _completePhoneSignIn(UserProfile firebaseUser) async {
    final phone = _otpRequestedDestination ?? _formattedSignInDestination;
    await _api.waitUntilReady();
    final profile = await _api.lookupUserByPhone(phone);
    if (profile == null) {
      throw Exception(
        'No existing MedicoHub account matches this mobile number. Register with email first, then add the mobile number to the profile.',
      );
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _activeUser = profile;
      _selectedLanguage =
          profile.languages.isEmpty ? _selectedLanguage : profile.languages.first;
      _emailController.text = profile.email;
      _phoneController.text = profile.phoneNumber ?? phone;
      _authBusy = false;
      _voiceStatus = 'Signed in successfully.';
      _resetOtpJourney();
      _phoneVerificationId = null;
    });
    await _persistAuthPreferences(
      email: profile.email,
      phone: profile.phoneNumber ?? phone,
    );
    await _refreshNotifications(profile.id);
  }

  Future<UserProfile> _loadOrCreateBackendProfile(UserProfile firebaseUser) async {
    final existing = await _api.fetchUserProfile(firebaseUser.id);
    if (existing != null) {
      return existing;
    }
    final rosterMatch = await _resolveRosterMatch(firebaseUser.email);
    if (rosterMatch == null) {
      throw Exception(
        'This email is not yet part of the MedicoHub roster. Use Create Account for a new patient account, or ask an admin to add the doctor/admin first.',
      );
    }
    if (_normalizeEmail(rosterMatch.email) != _normalizeEmail(firebaseUser.email)) {
      throw Exception(
        'The signed-in Firebase email does not match the MedicoHub roster lookup result. Please sign out and try again.',
      );
    }
    return _api.upsertUserProfile(
      id: firebaseUser.id,
      email: firebaseUser.email,
      displayName: rosterMatch.displayName,
      phoneNumber: rosterMatch.phoneNumber,
      role: rosterMatch.role,
      languages: rosterMatch.languages.isEmpty
          ? [_selectedLanguage]
          : rosterMatch.languages,
      specialties: rosterMatch.specialties,
    );
  }

  Future<UserProfile?> _resolveRosterMatch(String email) async {
    final normalizedEmail = _normalizeEmail(email);
    final currentMatch = _matchedRosterUser;
    if (currentMatch != null &&
        _normalizeEmail(currentMatch.email) == normalizedEmail) {
      return currentMatch;
    }
    final freshLookup = await _api.lookupUserByEmail(email);
    if (!mounted) {
      return freshLookup;
    }
    if (freshLookup != null &&
        _normalizeEmail(_emailController.text) == normalizedEmail) {
      setState(() {
        _matchedRosterUser = freshLookup;
        _displayNameController.text = freshLookup.displayName;
        _phoneController.text = freshLookup.phoneNumber ?? '';
        _selectedAccountRole = freshLookup.role;
        if (freshLookup.languages.isNotEmpty) {
          _selectedLanguage = freshLookup.languages.first;
        }
        if (freshLookup.specialties.isNotEmpty) {
          _selectedSpecialty = freshLookup.specialties.first;
        }
        _createAccountMode = false;
        _authLookupMessage =
            'Existing ${freshLookup.role} found: ${freshLookup.displayName}. Use Sign In to continue.';
      });
    }
    return freshLookup;
  }

  Future<void> _refreshNotifications(String userId) async {
    try {
      final notifications = await _api.fetchNotifications(userId: userId);
      if (!mounted) {
        return;
      }
      setState(() {
        _notifications = notifications;
      });
    } catch (_) {}
  }

  bool _canRespondToQuestion(ForumQuestion question) {
    final user = _activeUser;
    if (user == null || !user.isDoctor) {
      return false;
    }
    return _isAssignedToActiveDoctor(question, user);
  }

  bool _canAddFollowUp(ForumQuestion question) {
    final user = _activeUser;
    if (user == null) {
      return false;
    }
    if (user.isPatient) {
      return question.authorId == user.id;
    }
    if (user.isDoctor) {
      return _isAssignedToActiveDoctor(question, user);
    }
    return false;
  }

  bool _canModerateThreadMessage(ForumQuestion question, ThreadMessage message) {
    final user = _activeUser;
    if (user == null) {
      return false;
    }
    if (user.isAdmin) {
      return true;
    }
    return user.isDoctor && _isAssignedToActiveDoctor(question, user);
  }

  bool _isAssignedToActiveDoctor(ForumQuestion question, UserProfile user) {
    return question.targetDoctorId == user.id ||
        _normalizeEmail(question.targetDoctorEmail) == _normalizeEmail(user.email);
  }

  bool _latestThreadMessageNeedsDoctor(ForumQuestion question) {
    if (question.threadMessages.isEmpty) {
      return question.status == 'open';
    }
    final latest = question.threadMessages.last;
    return latest.actorRole == 'patient';
  }

  DateTime _latestConversationMoment(ForumQuestion question) {
    final timestamps = <DateTime>[
      _tryParseDate(question.updatedAt),
      _tryParseDate(question.createdAt),
      ...question.threadMessages.map((message) => _tryParseDate(message.createdAt)),
      ...question.responses.map((response) => _tryParseDate(response.createdAt)),
    ]..sort();
    return timestamps.isEmpty
        ? DateTime.fromMillisecondsSinceEpoch(0)
        : timestamps.last;
  }

  DateTime _tryParseDate(String? raw) {
    if (raw == null || raw.isEmpty) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.tryParse(raw)?.toLocal() ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _formatTimestamp(String? raw) {
    final parsed = _tryParseDate(raw);
    if (parsed.millisecondsSinceEpoch == 0) {
      return 'just now';
    }
    final difference = DateTime.now().difference(parsed);
    if (difference.inMinutes < 1) {
      return 'just now';
    }
    if (difference.inHours < 1) {
      return '${difference.inMinutes} min ago';
    }
    if (difference.inDays < 1) {
      return '${difference.inHours} hr ago';
    }
    if (difference.inDays < 7) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
    return '${parsed.day}/${parsed.month}/${parsed.year}';
  }

  String _notificationStatusLabel(NotificationOutboxItem item) {
    if (item.channel == 'email' && item.status != 'sent') {
      return 'Coming later';
    }
    switch (item.status) {
      case 'sent':
        return 'Delivered';
      case 'preview_ready':
        return 'Prepared';
      default:
        return item.status;
    }
  }

  void _applyThemeSelection({
    required MedicoHubThemePreset preset,
    String? customHex,
    bool? customDarkMode,
  }) {
    final rawHex = customHex ?? _themeHexController.text;
    final hex = normalizeHexColor(rawHex);
    if (preset == MedicoHubThemePreset.custom && hex.isEmpty) {
      setState(() {
        _themeHexInvalid = true;
        _voiceStatus =
            'Theme not changed. Please enter a valid HEX color like #4F8C73.';
      });
      return;
    }
    final nextConfig = MedicoHubThemeConfig(
      preset: preset,
      customSeedHex: hex.isEmpty ? widget.themeConfig.customSeedHex : hex,
      customDarkMode: customDarkMode ?? _customThemeDarkMode,
    );
    _themeHexController.text = nextConfig.customSeedHex;
    _customThemeDarkMode = nextConfig.customDarkMode;
    widget.onThemeChanged(nextConfig);
    unawaited(_persistThemePreferences(nextConfig));
    setState(() {
      _themeHexInvalid = false;
      _voiceStatus = preset == MedicoHubThemePreset.custom
          ? 'Custom theme applied with seed ${nextConfig.customSeedHex}.'
          : '${preset.label} theme applied.';
    });
  }

  Future<void> _openThemeColorStudio() async {
    var selected = safeThemeSeedColor(
      _themeHexController.text.isEmpty
          ? widget.themeConfig.customSeedHex
          : _themeHexController.text,
    );
    var useDarkSurfaces = _customThemeDarkMode;
    final applied = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Color Studio',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Pick a color visually, fine-tune it like a paint palette, then apply it to your custom MedicoHub theme.',
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: useDarkSurfaces
                              ? const Color(0xFF0F172A)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.palette_outlined, color: selected),
                            const SizedBox(width: 10),
                            Text(
                              '#${selected.toARGB32().toRadixString(16).substring(2).toUpperCase()}',
                              style: TextStyle(
                                color: useDarkSurfaces ? Colors.white : null,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      ColorPicker(
                        pickerColor: selected,
                        enableAlpha: false,
                        labelTypes: const [ColorLabelType.hex],
                        pickerAreaBorderRadius:
                            const BorderRadius.all(Radius.circular(20)),
                        onColorChanged: (value) {
                          setModalState(() => selected = value);
                        },
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: useDarkSurfaces,
                        title: const Text('Use dark surfaces'),
                        onChanged: (value) {
                          setModalState(() => useDarkSurfaces = value);
                        },
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Apply Theme'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    if (applied != true) {
      return;
    }
    final hex = '#${selected.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    _themeHexController.text = hex;
    _applyThemeSelection(
      preset: MedicoHubThemePreset.custom,
      customHex: hex,
      customDarkMode: useDarkSurfaces,
    );
  }

  List<String> _parseCsv(String raw) => raw
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();

  DisclaimerDocument get _currentDisclaimerDocument {
    final documents = _appSettings?.disclaimerDocuments ?? const {};
    return documents[_selectedLanguage] ??
        documents['English'] ??
        const DisclaimerDocument(
          title: 'MedicoHub Educational Use Notice',
          body:
              'MedicoHub is an educational platform and not a substitute for direct medical care.',
        );
  }

  String get _currentRegionNote {
    final code = WidgetsBinding.instance.platformDispatcher.locale.countryCode
            ?.toUpperCase() ??
        '';
    if (code == 'AE' || code == 'SA' || code == 'QA' || code == 'KW') {
      return 'Regional note: use MedicoHub only for educational discussion. Urgent symptoms should be escalated through licensed local care channels and emergency services in your jurisdiction.';
    }
    if (code == 'IN') {
      return 'Regional note: MedicoHub is an educational forum and not a replacement for consultation with a registered medical practitioner in India.';
    }
    if (code == 'FR' || code == 'ES' || code == 'DE' || code == 'IT') {
      return 'Regional note: use MedicoHub as an educational discussion layer only. Formal diagnosis and treatment decisions should stay with your licensed local care team.';
    }
    if (code == 'CN') {
      return 'Regional note: MedicoHub content is educational only. Please rely on locally licensed care pathways for diagnosis, prescriptions, and urgent management.';
    }
    return _appSettings?.defaultRegionNote ??
        'This notice is educational and operational. It is not a substitute for country-specific legal advice.';
  }

  Future<void> _emailDisclaimerToSelf() async {
    final email = _activeUser?.email ?? _emailController.text.trim();
    if (email.isEmpty) {
      return;
    }
    final disclaimer = _currentDisclaimerDocument;
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      queryParameters: {
        'subject': disclaimer.title,
        'body': '${disclaimer.body}\n\n$_currentRegionNote',
      },
    );
    await launchUrl(uri);
  }

  Future<void> _saveDisclaimerLocally() async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}medicohub-disclaimer-${DateTime.now().millisecondsSinceEpoch}.txt',
    );
    final disclaimer = _currentDisclaimerDocument;
    await file.writeAsString(
      '${disclaimer.title}\n\n${disclaimer.body}\n\n$_currentRegionNote',
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _voiceStatus = 'Saved disclaimer copy to ${file.path}.';
    });
  }

  Future<void> _saveAppSettings({
    List<String>? questionTopics,
    Map<String, DisclaimerDocument>? disclaimerDocuments,
    String? defaultRegionNote,
  }) async {
    final user = _activeUser;
    if (user == null || !user.isAdmin) {
      return;
    }
    setState(() => _appSettingsBusy = true);
    try {
      final updated = await _api.updateAppSettings(
        actorId: user.id,
        questionTopics: questionTopics ?? _availableQuestionTopics,
        disclaimerDocuments:
            disclaimerDocuments ?? (_appSettings?.disclaimerDocuments ?? {}),
        defaultRegionNote:
            defaultRegionNote ?? _disclaimerRegionNoteController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _appSettings = updated;
        _selectedQuestionCategory = _availableQuestionTopics.contains(
              _selectedQuestionCategory,
            )
            ? _selectedQuestionCategory
            : _availableQuestionTopics.first;
        _voiceStatus = 'App settings updated.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Could not update app settings: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _appSettingsBusy = false);
      }
    }
  }

  Future<void> _addQuestionTopic() async {
    final raw = _topicEditorController.text.trim();
    if (raw.isEmpty) {
      return;
    }
    final nextTopics = <String>[
      ..._availableQuestionTopics,
      if (!_availableQuestionTopics.contains(raw)) raw,
    ];
    await _saveAppSettings(questionTopics: nextTopics);
    _topicEditorController.clear();
  }

  Future<void> _removeQuestionTopic(String topic) async {
    final nextTopics = _availableQuestionTopics
        .where((item) => item != topic)
        .toList();
    await _saveAppSettings(
      questionTopics:
          nextTopics.isEmpty ? List<String>.from(_questionCategories) : nextTopics,
    );
  }

  List<AdCampaign> _matchingCampaignsForText({
    required String placement,
    required String primaryText,
    String secondaryText = '',
    String category = '',
    String language = '',
  }) {
    final haystack =
        '$primaryText $secondaryText $category $language'.toLowerCase();
    final categoryLower = category.toLowerCase();
    final languageLower = language.toLowerCase();
    final campaigns = _adCampaigns.where((campaign) {
      if (!campaign.active) {
        return false;
      }
      if (!campaign.placements.contains(placement)) {
        return false;
      }
      if (campaign.languages.isNotEmpty &&
          !campaign.languages.any((item) => item.toLowerCase() == languageLower)) {
        return false;
      }
      if (campaign.categories.isNotEmpty &&
          !campaign.categories.any((item) => item.toLowerCase() == categoryLower)) {
        return false;
      }
      if (campaign.keywords.isEmpty) {
        return true;
      }
      return campaign.keywords.any((keyword) => haystack.contains(keyword.toLowerCase()));
    }).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    return campaigns;
  }

  Future<void> _launchAdCampaign(AdCampaign campaign) async {
    await _openExternalUrl(campaign.targetUrl);
  }

  Future<void> _createAdCampaign() async {
    final user = _activeUser;
    if (user == null || !user.isAdmin) {
      return;
    }
    if (_adTitleController.text.trim().isEmpty ||
        _adSubtitleController.text.trim().isEmpty ||
        _adUrlController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an ad title, subtitle, and target URL.';
      });
      return;
    }
    try {
      final created = await _api.createAdCampaign(
        actorId: user.id,
        sponsorName: _adSponsorController.text.trim().isEmpty
            ? 'Sponsored'
            : _adSponsorController.text.trim(),
        title: _adTitleController.text.trim(),
        subtitle: _adSubtitleController.text.trim(),
        ctaLabel: _adCtaController.text.trim().isEmpty
            ? 'Learn more'
            : _adCtaController.text.trim(),
        targetUrl: _adUrlController.text.trim(),
        keywords: _parseCsv(_adKeywordsController.text),
        categories: _parseCsv(_adCategoriesController.text),
        placements: <String>[_selectedAdPlacement],
        languages: _selectedAdLanguage == 'All'
            ? const []
            : <String>[_selectedAdLanguage],
        priority: int.tryParse(_adPriorityController.text.trim()) ?? 50,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _adCampaigns = <AdCampaign>[created, ..._adCampaigns]
          ..sort((a, b) => b.priority.compareTo(a.priority));
        _adSponsorController.clear();
        _adTitleController.clear();
        _adSubtitleController.clear();
        _adUrlController.clear();
        _adKeywordsController.clear();
        _adCategoriesController.clear();
        _adCtaController.text = 'Learn more';
        _adPriorityController.text = '50';
        _selectedAdPlacement = 'home';
        _selectedAdLanguage = 'English';
        _voiceStatus = 'Sponsored card created successfully.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Could not create sponsored card: $error';
      });
    }
  }

  Future<void> _toggleAdCampaignActive(AdCampaign campaign) async {
    final user = _activeUser;
    if (user == null || !user.isAdmin) {
      return;
    }
    try {
      final updated = await _api.updateAdCampaign(
        campaignId: campaign.id,
        actorId: user.id,
        active: !campaign.active,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _adCampaigns = _adCampaigns
            .map((item) => item.id == campaign.id ? updated : item)
            .toList()
          ..sort((a, b) => b.priority.compareTo(a.priority));
        _voiceStatus = updated.active
            ? 'Sponsored card activated.'
            : 'Sponsored card paused.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Could not update sponsored card: $error';
      });
    }
  }

  Future<void> _openDoctorResponseDialog(ForumQuestion question) async {
    final keyPointsController = TextEditingController();
    final meaningController = TextEditingController();
    final discussController = TextEditingController();
    final fullTextController = TextEditingController();
    var submitting = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Respond to ${question.title}'),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: keyPointsController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Key points'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: meaningController,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'What it means'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: discussController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'What to discuss with your doctor',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: fullTextController,
                        maxLines: 5,
                        decoration: const InputDecoration(labelText: 'Full educational reply'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (keyPointsController.text.trim().isEmpty ||
                              meaningController.text.trim().isEmpty ||
                              discussController.text.trim().isEmpty ||
                              fullTextController.text.trim().isEmpty) {
                            return;
                          }
                          setDialogState(() => submitting = true);
                          try {
                            final response = await _api.submitDoctorResponse(
                              questionId: question.id,
                              doctorId: _activeUser!.id,
                              keyPoints: keyPointsController.text.trim(),
                              whatItMeans: meaningController.text.trim(),
                              whatToDiscussWithDoctor: discussController.text.trim(),
                              fullText: fullTextController.text.trim(),
                            );
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _questions = _questions.map((item) {
                                if (item.id != question.id) {
                                  return item;
                                }
                                return ForumQuestion(
                                  id: item.id,
                                  title: item.title,
                                  body: item.body,
                                  type: item.type,
                                  headingGroup: item.headingGroup,
                                  language: item.language,
                                  tags: item.tags,
                                  premium: item.premium,
                                  status: 'answered',
                                  aiSummary: 'Question about ${item.title}. Latest reply highlights: ${response.keyPoints}',
                                  responseCount: item.responseCount + 1,
                                  authorId: item.authorId,
                                  targetDoctorId: item.targetDoctorId,
                                  responses: [...item.responses, response],
                                  threadMessages: item.threadMessages,
                                  createdAt: item.createdAt,
                                  updatedAt: response.createdAt,
                                  authorName: item.authorName,
                                  targetDoctorName: item.targetDoctorName,
                                  authorEmail: item.authorEmail,
                                  targetDoctorEmail: item.targetDoctorEmail,
                                  symptomsSummary: item.symptomsSummary,
                                  isPublic: item.isPublic,
                                );
                              }).toList();
                              _voiceStatus = 'Doctor response posted successfully.';
                            });
                            await _refreshNotifications(_activeUser!.id);
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          } catch (error) {
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _voiceStatus = 'Could not post doctor response: $error';
                            });
                            setDialogState(() => submitting = false);
                          }
                        },
                  child: Text(submitting ? 'Posting...' : 'Post Response'),
                ),
              ],
            );
          },
        );
      },
    );

    keyPointsController.dispose();
    meaningController.dispose();
    discussController.dispose();
    fullTextController.dispose();
  }

  Future<void> _openThreadMessageDialog(ForumQuestion question) async {
    final controller = TextEditingController();
    var submitting = false;
    final user = _activeUser;
    if (user == null) {
      controller.dispose();
      return;
    }
    final actionLabel = user.isPatient ? 'Add Follow-up' : 'Add Doctor Comment';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('$actionLabel for ${question.title}'),
              content: SizedBox(
                width: 520,
                child: TextField(
                  controller: controller,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    helperText: 'This will be added to the question thread and may reopen it for doctor attention.',
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          if (controller.text.trim().isEmpty) {
                            return;
                          }
                          setDialogState(() => submitting = true);
                          try {
                            final message = await _api.addThreadMessage(
                              questionId: question.id,
                              actorId: user.id,
                              body: controller.text.trim(),
                            );
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _questions = _questions.map((item) {
                                if (item.id != question.id) {
                                  return item;
                                }
                                return ForumQuestion(
                                  id: item.id,
                                  title: item.title,
                                  body: item.body,
                                  type: item.type,
                                  headingGroup: item.headingGroup,
                                  language: item.language,
                                  tags: item.tags,
                                  premium: item.premium,
                                  status: user.isPatient ? 'open' : item.status,
                                  aiSummary: user.isPatient
                                      ? 'Follow-up received for ${item.title}. Doctor attention is needed.'
                                      : item.aiSummary,
                                  responseCount: item.responseCount,
                                  authorId: item.authorId,
                                  targetDoctorId: item.targetDoctorId,
                                  responses: item.responses,
                                  threadMessages: [...item.threadMessages, message],
                                  createdAt: item.createdAt,
                                  updatedAt: message.createdAt,
                                  authorName: item.authorName,
                                  targetDoctorName: item.targetDoctorName,
                                  authorEmail: item.authorEmail,
                                  targetDoctorEmail: item.targetDoctorEmail,
                                  symptomsSummary: item.symptomsSummary,
                                  isPublic: item.isPublic,
                                );
                              }).toList();
                              _voiceStatus = user.isPatient
                                  ? 'Follow-up posted. The thread is back in the doctor’s current queue.'
                                  : 'Doctor comment added to the thread.';
                            });
                            await _refreshNotifications(user.id);
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          } catch (error) {
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _voiceStatus = 'Could not add thread message: $error';
                            });
                            setDialogState(() => submitting = false);
                          }
                        },
                  child: Text(submitting ? 'Posting...' : actionLabel),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
  }

  Future<void> _publishDoctorArticle() async {
    final user = _activeUser;
    if (user == null || !user.isDoctor) {
      return;
    }
    if (_articleTitleController.text.trim().isEmpty ||
        _articleSummaryController.text.trim().isEmpty ||
        _articleBodyController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Article title, summary, and body are required.';
      });
      return;
    }
    setState(() {
      _adminBusy = true;
      _errorMessage = null;
    });
    try {
      final article = await _api.createBlogArticle(
        authorId: user.id,
        title: _articleTitleController.text.trim(),
        summary: _articleSummaryController.text.trim(),
        body: _articleBodyController.text.trim(),
        category: _articleCategory,
        language: _selectedLanguage,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _blogArticles = [article, ..._blogArticles];
        _adminBusy = false;
        _articleTitleController.clear();
        _articleSummaryController.clear();
        _articleBodyController.clear();
        _voiceStatus = 'Article published to the Education tab.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _adminBusy = false;
        _errorMessage = 'Could not publish article: $error';
      });
    }
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Enter a valid email before requesting a password reset.';
      });
      return;
    }
    setState(() {
      _authBusy = true;
      _errorMessage = null;
    });
    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (!mounted) {
        return;
      }
      setState(() {
        _authBusy = false;
        _voiceStatus =
            'A Firebase password reset email has been requested for $email.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _authBusy = false;
        _errorMessage = 'Could not request password reset: ${_firebaseFriendlyError(error)}';
      });
    }
  }

  Future<void> _openChangePasswordDialog() async {
    final user = _activeUser;
    if (user == null) {
      return;
    }
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    var dialogBusy = false;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Update Password'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: currentPasswordController,
                      obscureText: !_currentPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'Current password',
                        suffixIcon: IconButton(
                          onPressed: () => setDialogState(() {
                            _currentPasswordVisible = !_currentPasswordVisible;
                          }),
                          icon: Icon(
                            _currentPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: newPasswordController,
                      obscureText: !_newPasswordVisible,
                      decoration: InputDecoration(
                        labelText: 'New password',
                        helperText:
                            'Choose a stronger password before sharing the app.',
                        suffixIcon: IconButton(
                          onPressed: () => setDialogState(() {
                            _newPasswordVisible = !_newPasswordVisible;
                          }),
                          icon: Icon(
                            _newPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: dialogBusy
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: dialogBusy
                      ? null
                      : () async {
                          if (currentPasswordController.text.isEmpty ||
                              newPasswordController.text.length < 8) {
                            return;
                          }
                          setDialogState(() => dialogBusy = true);
                          try {
                            await _auth.updatePassword(
                              email: user.email,
                              currentPassword:
                                  currentPasswordController.text.trim(),
                              newPassword: newPasswordController.text.trim(),
                            );
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _voiceStatus = 'Password updated successfully.';
                            });
                            if (dialogContext.mounted) {
                              Navigator.of(dialogContext).pop();
                            }
                          } catch (error) {
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _errorMessage =
                                  'Could not update password: ${_firebaseFriendlyError(error)}';
                            });
                            setDialogState(() => dialogBusy = false);
                          }
                        },
                  child: Text(dialogBusy ? 'Saving...' : 'Update Password'),
                ),
              ],
            );
          },
        );
      },
    );
    currentPasswordController.dispose();
    newPasswordController.dispose();
  }

  Future<void> _openDeleteAccountDialog() async {
    final user = _activeUser;
    if (user == null) {
      return;
    }
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    var dialogBusy = false;
    var passwordVisible = false;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Delete Account'),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This permanently deletes your Firebase sign-in account and MedicoHub profile for ${user.email}. Your own question threads are removed from public lists.',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passwordController,
                      obscureText: !passwordVisible,
                      decoration: InputDecoration(
                        labelText: 'Current password',
                        suffixIcon: IconButton(
                          onPressed: () => setDialogState(
                            () => passwordVisible = !passwordVisible,
                          ),
                          icon: Icon(
                            passwordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmController,
                      decoration: const InputDecoration(
                        labelText: 'Type DELETE to confirm',
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: dialogBusy
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: dialogBusy
                      ? null
                      : () async {
                          if (passwordController.text.isEmpty ||
                              confirmController.text.trim().toUpperCase() !=
                                  'DELETE') {
                            setState(() {
                              _errorMessage =
                                  'Enter your password and type DELETE to confirm account deletion.';
                            });
                            return;
                          }
                          setDialogState(() => dialogBusy = true);
                          await _deleteAccount(
                            password: passwordController.text.trim(),
                          );
                          if (dialogContext.mounted && _activeUser == null) {
                            Navigator.of(dialogContext).pop();
                          } else {
                            setDialogState(() => dialogBusy = false);
                          }
                        },
                  child: Text(dialogBusy ? 'Deleting...' : 'Delete Permanently'),
                ),
              ],
            );
          },
        );
      },
    );
    passwordController.dispose();
    confirmController.dispose();
  }

  Future<void> _deleteAccount({required String password}) async {
    final user = _activeUser;
    if (user == null) {
      return;
    }
    setState(() {
      _deleteAccountBusy = true;
      _errorMessage = null;
    });
    try {
      await _auth.deleteCurrentAccount(
        email: user.email,
        currentPassword: password,
      );
      await _api.deleteUserAccount(userId: user.id, actorId: user.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _deleteAccountBusy = false;
        _activeUser = null;
        _createAccountMode = false;
        _voiceStatus = 'Your MedicoHub account has been deleted.';
        _questions = const [];
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _deleteAccountBusy = false;
        _errorMessage =
            'Could not delete account: ${_firebaseFriendlyError(error)}';
      });
    }
  }

  Future<void> _openNotificationLink(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openNotificationSettingsTab() {
    setState(() {
      _tabIndex = 4;
      _voiceStatus = _isWhatsAppActivationCoolingDown
          ? 'Review the Delivery Channels section for today’s WhatsApp status.'
          : 'Open Delivery Channels and tap the WhatsApp activation button to enable notifications for today.';
    });
  }

  Future<void> _activateWhatsAppFor24Hours() async {
    final settings = _notificationSettings;
    final prefs = _prefs;
    final key = _whatsAppActivationPreferenceKey;
    if (settings == null || prefs == null || key == null) {
      setState(() {
        _errorMessage = 'WhatsApp activation is not ready yet. Please refresh the app.';
      });
      return;
    }
    if (!settings.whatsAppActivationEnabled) {
      setState(() {
        _errorMessage = 'WhatsApp activation is currently disabled by the administrator.';
      });
      return;
    }
    if (_isWhatsAppActivationCoolingDown) {
      final until = _whatsAppActivationCooldownUntil;
      setState(() {
        _voiceStatus = until == null
            ? 'WhatsApp activation is already marked for today.'
            : 'WhatsApp activation is already marked until ${until.hour.toString().padLeft(2, '0')}:${until.minute.toString().padLeft(2, '0')} tonight.';
      });
      return;
    }

    final activationLink = 'https://wa.me/'
        '${settings.whatsAppActivationTarget.replaceAll(RegExp(r"[^0-9]"), "")}'
        '?text=${Uri.encodeComponent(settings.whatsAppActivationPhrase)}';
    await _openNotificationLink(activationLink);
    if (!mounted) {
      return;
    }
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text('Confirm WhatsApp Activation'),
              content: Text(
                'WhatsApp opened with the activation message. After you press Send in WhatsApp, come back here and confirm so MedicoHub marks notifications active until midnight.\n\nCurrent phrase: ${settings.whatsAppActivationPhrase}',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Not yet'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text("I've sent it"),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!confirmed) {
      setState(() {
        _voiceStatus =
            'WhatsApp opened. After sending the activation message, return and use the badge or Delivery Channels section to confirm activation.';
      });
      return;
    }

    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    await prefs.setString(key, nextMidnight.toIso8601String());
    if (!mounted) {
      return;
    }
    setState(() {
      _voiceStatus =
          'WhatsApp activation confirmed for this device until midnight.';
    });
  }

  Future<void> _saveNotificationSettings() async {
    final user = _activeUser;
    if (user == null || !_canConfigureNotificationSettings) {
      return;
    }
    try {
      final updated = await _api.updateNotificationSettings(
        actorId: user.id,
        whatsAppActivationEnabled: true,
        whatsAppActivationTarget: _notificationTargetController.text.trim(),
        whatsAppActivationPhrase: _notificationPhraseController.text.trim(),
        emailStatusNote: _emailStatusNoteController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _notificationSettings = updated;
        _voiceStatus = 'Notification delivery settings updated.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Could not update notification settings: $error';
      });
    }
  }

  Future<void> _moderateThreadMessage(
    ForumQuestion question,
    ThreadMessage message,
    String moderationState,
  ) async {
    final user = _activeUser;
    if (user == null) {
      return;
    }
    try {
      final moderated = await _api.moderateThreadMessage(
        questionId: question.id,
        messageId: message.id,
        actorId: user.id,
        moderationState: moderationState,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _questions = _questions.map((item) {
          if (item.id != question.id) {
            return item;
          }
          return ForumQuestion(
            id: item.id,
            title: item.title,
            body: item.body,
            type: item.type,
            headingGroup: item.headingGroup,
            language: item.language,
            tags: item.tags,
            premium: item.premium,
            status: item.status,
            aiSummary: item.aiSummary,
            responseCount: item.responseCount,
            authorId: item.authorId,
            targetDoctorId: item.targetDoctorId,
            responses: item.responses,
            threadMessages: item.threadMessages
                .map((existing) => existing.id == message.id ? moderated : existing)
                .toList(),
            createdAt: item.createdAt,
            updatedAt: item.updatedAt,
            authorName: item.authorName,
            targetDoctorName: item.targetDoctorName,
            authorEmail: item.authorEmail,
            targetDoctorEmail: item.targetDoctorEmail,
            symptomsSummary: item.symptomsSummary,
            isPublic: item.isPublic,
          );
        }).toList();
        _voiceStatus = moderationState == 'hidden'
            ? 'Message hidden from the visible thread.'
            : 'Message restored to the visible thread.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Could not moderate thread message: $error';
      });
    }
  }

  String _normalizeEmail(String? value) => (value ?? '').trim().toLowerCase();

  String _normalizePhone(String? value) => (value ?? '').trim();

  Future<void> _submitQuestion() async {
    final user = _activeUser;
    final doctorId = _selectedDoctorId;
    if (user == null || doctorId == null) {
      return;
    }
    if (_titleController.text.trim().isEmpty ||
        _bodyController.text.trim().isEmpty) {
      setState(() {
        _voiceStatus = 'Title and question body are required.';
      });
      return;
    }

    setState(() {
      _submitting = true;
      _voiceStatus = null;
    });

    try {
      final tags = <String>[
        _selectedSpecialty,
        _selectedLanguage,
        _selectedQuestionCategory,
        if (_premium) 'Second opinion' else 'Forum',
      ];

      if (_editingQuestionId == null) {
        final created = await _api.submitQuestion(
          authorId: user.id,
          targetDoctorId: doctorId,
          headingGroup: _selectedQuestionCategory,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          symptomsSummary: _symptomsController.text.trim(),
          premium: _premium,
          isPublic: false,
          language: _selectedLanguage,
          tags: tags,
          attachmentIds: _uploadedAttachments.map((item) => item.id).toList(),
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _questions = [created, ..._questions];
          _voiceStatus =
              'Question submitted. Notification flows will be wired in the next messaging module.';
        });
      } else {
        final updated = await _api.updateQuestion(
          questionId: _editingQuestionId!,
          actorId: user.id,
          title: _titleController.text.trim(),
          body: _bodyController.text.trim(),
          headingGroup: _selectedQuestionCategory,
          language: _selectedLanguage,
          symptomsSummary: _symptomsController.text.trim(),
          attachmentIds: _uploadedAttachments.map((item) => item.id).toList(),
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _questions = _questions
              .map((question) =>
                  question.id == updated.id ? updated : question)
              .toList();
          _voiceStatus = 'Question updated successfully.';
        });
      }

      _resetAskForm();
      await _refreshNotifications(user.id);
      setState(() {
        _submitting = false;
        _tabIndex = 2;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _submitting = false;
        _voiceStatus = 'Submit failed: $error';
      });
    }
  }

  void _resetAskForm() {
    _titleController.clear();
    _bodyController.clear();
    _symptomsController.clear();
    _premium = false;
    _uploadedAttachments = const [];
    _audioAttachmentPath = null;
    _audioPreviewPlaying = false;
    _selectedTemplateId = '_custom';
    _selectedQuestionCategory = 'General';
    _editingQuestionId = null;
  }

  bool _canEditQuestion(ForumQuestion question) {
    final user = _activeUser;
    if (user == null) {
      return false;
    }
    return question.authorId == user.id || user.isAdmin;
  }

  void _startEditingQuestion(ForumQuestion question) {
    setState(() {
      _editingQuestionId = question.id;
      _titleController.text = question.title;
      _bodyController.text = question.body;
      _symptomsController.text = question.symptomsSummary ?? '';
      _selectedQuestionCategory = question.headingGroup;
      _selectedLanguage = question.language;
      _selectedDoctorId = question.targetDoctorId;
      _tabIndex = 1;
      _voiceStatus = 'Editing ${question.title}';
    });
  }

  void _cancelEditingQuestion() {
    setState(() {
      _resetAskForm();
      _voiceStatus = 'Edit cancelled.';
    });
  }

  Future<void> _toggleQuestionVisibility(ForumQuestion question) async {
    final user = _activeUser;
    if (user == null) {
      return;
    }
    try {
      final updated = await _api.updateQuestion(
        questionId: question.id,
        actorId: user.id,
        isPublic: !question.isPublic,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _questions = _questions
            .map((item) => item.id == updated.id ? updated : item)
            .toList();
        _voiceStatus = updated.isPublic
            ? 'Question is now public.'
            : 'Question is now private.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _voiceStatus = 'Could not update visibility: $error';
      });
    }
  }

  Future<void> _deleteQuestion(ForumQuestion question) async {
    final user = _activeUser;
    if (user == null) {
      return;
    }
    try {
      await _api.deleteQuestion(questionId: question.id, actorId: user.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _questions =
            _questions.where((item) => item.id != question.id).toList();
        if (_editingQuestionId == question.id) {
          _resetAskForm();
        }
        _voiceStatus = 'Question deleted.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _voiceStatus = 'Could not delete question: $error';
      });
    }
  }

  Future<void> _inviteDoctorFromAdmin() async {
    final user = _activeUser;
    if (user == null) {
      return;
    }
    setState(() {
      _adminBusy = true;
    });
    try {
      final created = await _api.inviteDoctor(
        actorId: user.id,
        email: _doctorInviteEmailController.text.trim(),
        displayName: _doctorInviteNameController.text.trim(),
        phoneNumber: _doctorInvitePhoneController.text.trim().isEmpty
            ? null
            : _doctorInvitePhoneController.text.trim(),
        specialties: [_inviteDoctorSpecialty],
        languages: [_inviteDoctorLanguage],
      );
      final refreshed = await _api.fetchDoctors();
      if (!mounted) {
        return;
      }
      setState(() {
        _doctors = refreshed;
        _selectedDoctorId ??= created.id;
        _doctorInviteNameController.clear();
        _doctorInviteEmailController.clear();
        _doctorInvitePhoneController.clear();
        _adminBusy = false;
        _voiceStatus =
            'Doctor ${created.displayName} added. They can now sign up with Firebase.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _adminBusy = false;
        _voiceStatus = 'Could not add doctor: $error';
      });
    }
  }

  Future<void> _startAudioRecording() async {
    try {
      await _voiceService.startAudioNote();
      if (!mounted) {
        return;
      }
      setState(() {
        _recordingAudio = true;
        _voiceStatus = 'Recording audio note...';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = _friendlyMicrophoneError(error);
      setState(() {
        _recordingAudio = false;
        _voiceStatus = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  String _friendlyMicrophoneError(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('permission') || raw.contains('denied')) {
      return 'Microphone access was not enabled. Please allow microphone access in the device permission prompt or Settings before recording an audio note.';
    }
    return 'Audio recording is not available on this device right now. You can still type your question or attach a file.';
  }

  Future<void> _stopAudioRecording() async {
    try {
      final result = await _voiceService.stopAudioNote();
      if (!mounted) {
        return;
      }
      setState(() {
        _recordingAudio = false;
        _audioAttachmentPath = result.audioPath;
        _audioPreviewPlaying = false;
        _voiceStatus =
            'Audio note captured. Preview it, delete and redo if needed, or upload it.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _recordingAudio = false;
        _voiceStatus = 'Could not stop recording: $error';
      });
    }
  }

  Future<void> _toggleAudioPreview() async {
    final path = _audioAttachmentPath;
    if (path == null) {
      return;
    }
    try {
      if (_audioPreviewPlaying) {
        await _voiceService.stopAudioPlayback();
      } else {
        await _voiceService.playAudioNote(path);
      }
      if (!mounted) {
        return;
      }
      setState(() {
        _audioPreviewPlaying = !_audioPreviewPlaying;
        _voiceStatus = _audioPreviewPlaying
            ? 'Playing local audio preview.'
            : 'Audio preview stopped.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _voiceStatus = 'Could not preview audio: $error';
      });
    }
  }

  Future<void> _deleteAudioNote() async {
    final path = _audioAttachmentPath;
    if (path == null) {
      return;
    }
    try {
      await _voiceService.deleteAudioNote(path);
      if (!mounted) {
        return;
      }
      setState(() {
        _audioAttachmentPath = null;
        _audioPreviewPlaying = false;
        _voiceStatus = 'Audio note deleted. You can record again now.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _voiceStatus = 'Could not delete audio note: $error';
      });
    }
  }

  Future<void> _startNativeListening() async {
    final available = await _voiceService.isRecognitionAvailable();
    if (!available) {
      if (!mounted) {
        return;
      }
      setState(() {
        _voiceStatus = Platform.isAndroid
            ? 'Native speech bridge is not active in this Android build yet. Use Gboard or Indic keyboard mic for $_selectedLanguage.'
            : 'Native speech bridge is not connected on this Windows build yet. Use audio note mode or Windows dictation plus keyboard entry.';
      });
      return;
    }

    final started = await _voiceService.startNativeListening(
      localeTag: _languageLocales[_selectedLanguage] ?? 'en-US',
      onPartial: (text) {
        _bodyController.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      },
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _listeningNative = started;
      _voiceStatus = started
          ? 'Native speech listener started for $_selectedLanguage.'
          : 'Native speech bridge is not connected in this build, so use keyboard mic or audio note mode.';
    });
  }

  Future<void> _stopNativeListening() async {
    final result = await _voiceService.stopNativeListening();
    if (!mounted) {
      return;
    }
    if (result.partialTranscript != null &&
        result.partialTranscript!.isNotEmpty) {
      _bodyController.value = TextEditingValue(
        text: result.partialTranscript!,
        selection: TextSelection.collapsed(
            offset: result.partialTranscript!.length),
      );
    }
    setState(() {
      _listeningNative = false;
      _voiceStatus = result.partialTranscript == null
          ? 'Native listener stopped.'
          : 'Applied speech transcript to the question body.';
    });
  }

  Future<void> _showKeyboardVoiceHelp() async {
    final text = '${_voiceService.keyboardVoiceInstructions()} '
        'Preferred language: $_selectedLanguage. '
        'On Android, Gboard or Indic Keyboard microphone is recommended.';
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    setState(() {
      _voiceStatus = '$text Copied to clipboard for quick reference.';
    });
  }

  Future<void> _pickAndUploadReport() async {
    final user = _activeUser;
    if (user == null) {
      return;
    }
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'png', 'jpg', 'jpeg', 'txt'],
    );
    final files = picked?.files ?? const <PlatformFile>[];
    if (files.isEmpty || files.first.bytes == null) {
      return;
    }
    final file = files.first;
    await _uploadAttachmentBytes(
      ownerId: user.id,
      fileName: file.name,
      mimeType: _mimeTypeFromName(file.name),
      bytes: file.bytes!,
    );
  }

  Future<void> _uploadRecordedAudio() async {
    final user = _activeUser;
    final path = _audioAttachmentPath;
    if (user == null || path == null) {
      return;
    }
    final bytes = await File(path).readAsBytes();
    await _uploadAttachmentBytes(
      ownerId: user.id,
      fileName: path.split(Platform.pathSeparator).last,
      mimeType: 'audio/wav',
      bytes: bytes,
    );
  }

  Future<void> _uploadAttachmentBytes({
    required String ownerId,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) async {
    setState(() {
      _uploadingAttachment = true;
      _voiceStatus = null;
    });
    try {
      final uploaded = await _api.uploadAttachment(
        ownerId: ownerId,
        fileName: fileName,
        mimeType: mimeType,
        bytes: bytes,
        expiryOption: _selectedExpiry,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _uploadedAttachments = [..._uploadedAttachments, uploaded];
        _uploadingAttachment = false;
        _voiceStatus = 'Uploaded ${uploaded.fileName}.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _uploadingAttachment = false;
        _voiceStatus = 'Attachment upload failed: $error';
      });
    }
  }

  Future<void> _removeAttachment(UploadedAttachment attachment) async {
    final user = _activeUser;
    if (user == null) {
      return;
    }
    try {
      await _api.revokeAttachment(
        attachmentId: attachment.id,
        actorId: user.id,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _uploadedAttachments =
            _uploadedAttachments.where((item) => item.id != attachment.id).toList();
        _voiceStatus = 'Removed ${attachment.fileName}.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _voiceStatus = 'Could not remove attachment: $error';
      });
    }
  }

  Future<void> _createAdminTitleTemplate() async {
    final user = _activeUser;
    if (user == null || !user.isAdmin) {
      return;
    }
    final title = _adminTitleController.text.trim();
    if (title.isEmpty) {
      setState(() {
        _voiceStatus = 'Enter a title example before saving.';
      });
      return;
    }

    setState(() {
      _adminBusy = true;
    });
    try {
      final created = await _api.createTitleTemplate(
        actorId: user.id,
        title: title,
        specialty: _selectedSpecialty,
        language: _selectedLanguage,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _titleTemplates = [..._titleTemplates, created];
        _adminTitleController.clear();
        _adminBusy = false;
        _voiceStatus = 'Added new title example for ${created.language}.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _adminBusy = false;
        _voiceStatus = 'Could not add title example: $error';
      });
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut();
    if (!mounted) {
      return;
    }
    setState(() {
      _activeUser = null;
      _tabIndex = 0;
      _uploadedAttachments = const [];
      _audioAttachmentPath = null;
      _audioPreviewPlaying = false;
      _voiceStatus = null;
      _editingQuestionId = null;
      _notifications = const [];
      _selectedAuthMethod = _AuthMethod.password;
      _selectedSignInChannel = _defaultSignInChannelForLocale();
      _syncSignInIdentifierWithSelection();
      _resetOtpJourney();
    });
  }

  String _mimeTypeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.txt')) return 'text/plain';
    return 'application/octet-stream';
  }

  String _firebaseFriendlyError(Object error) {
    final text = error.toString();
    if (text.contains('Firebase auth error: unknown-error') ||
        text.contains('firebase_auth/unknown-error')) {
      return '$text\n\nThe Firebase project is already responding correctly to direct email/password API calls, so this points to the Windows Firebase runtime/plugin layer. Please copy the full message above from the app UI or terminal so we can pinpoint the native failure.';
    }
    return text;
  }
}

DateTime _safeQuestionDate(String? raw) {
  if (raw == null || raw.isEmpty) {
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
  return DateTime.tryParse(raw)?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);
}

DateTime _questionLatestMoment(ForumQuestion question) {
  final timestamps = <DateTime>[
    _safeQuestionDate(question.updatedAt),
    _safeQuestionDate(question.createdAt),
    ...question.threadMessages.map((message) => _safeQuestionDate(message.createdAt)),
    ...question.responses.map((response) => _safeQuestionDate(response.createdAt)),
  ]..sort();
  return timestamps.isEmpty ? DateTime.fromMillisecondsSinceEpoch(0) : timestamps.last;
}

String _formatQuestionTimestamp(String? raw) {
  final parsed = _safeQuestionDate(raw);
  if (parsed.millisecondsSinceEpoch == 0) {
    return 'just now';
  }
  final difference = DateTime.now().difference(parsed);
  if (difference.inMinutes < 1) {
    return 'just now';
  }
  if (difference.inHours < 1) {
    return '${difference.inMinutes} min ago';
  }
  if (difference.inDays < 1) {
    return '${difference.inHours} hr ago';
  }
  if (difference.inDays < 7) {
    return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
  }
  return '${parsed.day}/${parsed.month}/${parsed.year}';
}

bool _questionNeedsDoctorReply(ForumQuestion question) {
  if (question.threadMessages.isEmpty) {
    return question.status == 'open';
  }
  return question.threadMessages.last.actorRole == 'patient';
}

String _questionStateLabel(ForumQuestion question) {
  if (_questionNeedsDoctorReply(question)) {
    return 'Needs doctor reply';
  }
  if (question.responses.isNotEmpty) {
    return 'Answered';
  }
  if (question.status == 'closed') {
    return 'Closed';
  }
  return 'Conversation active';
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({
    required this.question,
    this.followUpLabel = 'Add Follow-up',
    this.onEdit,
    this.onTogglePublic,
    this.onDelete,
    this.onRespond,
    this.onAddFollowUp,
    this.canModerateMessage,
    this.onModerateMessage,
  });

  final ForumQuestion question;
  final String followUpLabel;
  final VoidCallback? onEdit;
  final VoidCallback? onTogglePublic;
  final VoidCallback? onDelete;
  final VoidCallback? onRespond;
  final VoidCallback? onAddFollowUp;
  final bool Function(ThreadMessage message)? canModerateMessage;
  final void Function(ThreadMessage message, String moderationState)?
      onModerateMessage;

  @override
  Widget build(BuildContext context) {
    final hiddenMessageCount = question.threadMessages
        .where((message) => message.moderationState == 'hidden')
        .length;
    final latestMoment = _questionLatestMoment(question);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(question.title,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                if (question.premium)
                  Chip(
                    label: const Text('Paid'),
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Chip(label: Text(_questionStateLabel(question))),
                Chip(
                  label: Text(question.isPublic ? 'Public thread' : 'Private thread'),
                ),
                Chip(
                  label: Text('Updated ${_formatQuestionTimestamp(latestMoment.toIso8601String())}'),
                ),
                if (hiddenMessageCount > 0)
                  Chip(label: Text('$hiddenMessageCount hidden')),
              ],
            ),
            const SizedBox(height: 8),
            Text(question.body),
            const SizedBox(height: 12),
            Text(
              'From ${question.authorName ?? 'Unknown user'} to ${question.targetDoctorName ?? 'Unknown doctor'}',
            ),
            const SizedBox(height: 6),
            Text(
              '${question.headingGroup} • ${question.language} • ${question.isPublic ? 'Public' : 'Private'}',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: question.tags.map((tag) => Chip(label: Text(tag))).toList(),
            ),
            const SizedBox(height: 12),
            Text(
              question.aiSummary,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.primary),
            ),
            if (question.threadMessages.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Conversation',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...question.threadMessages.map(
                (message) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${message.actorName} • ${message.actorRole}',
                                  style: Theme.of(context).textTheme.labelLarge,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _formatQuestionTimestamp(message.createdAt),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (canModerateMessage?.call(message) == true &&
                              onModerateMessage != null)
                            PopupMenuButton<String>(
                              onSelected: (value) =>
                                  onModerateMessage!(message, value),
                              itemBuilder: (context) => [
                                PopupMenuItem<String>(
                                  value: message.moderationState == 'hidden'
                                      ? 'visible'
                                      : 'hidden',
                                  child: Text(
                                    message.moderationState == 'hidden'
                                        ? 'Show message'
                                        : 'Hide message',
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text(message.messageMode == 'voice' ? 'Voice note' : 'Text')),
                          if (message.attachmentIds.isNotEmpty)
                            Chip(label: Text('${message.attachmentIds.length} attachment${message.attachmentIds.length == 1 ? '' : 's'}')),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        message.moderationState == 'hidden'
                            ? '[Message hidden by moderation]'
                            : message.body,
                      ),
                    ],
                  ),
                ),
              ),
            ],
            if (question.responses.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...question.responses.map(
                (response) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Doctor response • ${response.responseMode}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatQuestionTimestamp(response.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: response.labels
                            .map((label) => Chip(label: Text(label)))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Text('Key points: ${response.keyPoints}'),
                      const SizedBox(height: 6),
                      Text('What it means: ${response.whatItMeans}'),
                      const SizedBox(height: 6),
                      Text(
                        'What to discuss with your doctor: ${response.whatToDiscussWithDoctor}',
                      ),
                      const SizedBox(height: 6),
                      Text(response.fullText),
                    ],
                  ),
                ),
              ),
            ],
            if (onRespond != null || onAddFollowUp != null || onEdit != null || onTogglePublic != null || onDelete != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (onRespond != null)
                    FilledButton(
                      onPressed: onRespond,
                      child: const Text('Respond'),
                    ),
                  if (onAddFollowUp != null)
                    OutlinedButton(
                      onPressed: onAddFollowUp,
                      child: Text(followUpLabel),
                    ),
                  if (onEdit != null)
                    OutlinedButton(
                      onPressed: onEdit,
                      child: const Text('Edit'),
                    ),
                  if (onTogglePublic != null)
                    OutlinedButton(
                      onPressed: onTogglePublic,
                      child:
                          Text(question.isPublic ? 'Make Private' : 'Make Public'),
                    ),
                  if (onDelete != null)
                    TextButton(
                      onPressed: onDelete,
                      child: const Text('Delete'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
