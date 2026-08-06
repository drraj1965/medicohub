import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_quill_delta_from_html/flutter_quill_delta_from_html.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:local_auth/local_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import 'features/vestibular/vestibular_home_page.dart';
import 'models/app_models.dart';
import 'services/app_api_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/translation_service.dart';
import 'services/update_service.dart';
import 'services/voice/medicohub_voice_service.dart';
import 'theme/app_theme.dart';
import 'widgets/translated_text_block.dart';

const List<String> _accountRoles = <String>['patient', 'doctor', 'admin'];
const Map<String, String> _articleSectionOptions = <String, String>{
  'summary': 'Summary',
  'patients': 'For Patients',
  'doctors': 'For Doctors',
  'citations': 'Citations / References',
  'faq': 'FAQ',
  'key_takeaways': 'Key Takeaways',
  'disclaimer': 'Disclaimer',
  'additional_notes': 'Additional Notes',
};

const Map<String, String> _legacyArticleSectionIdAliases = <String, String>{
  'body': 'summary',
  'notes': 'additional_notes',
  'takeaways': 'key_takeaways',
  'key-takeaways': 'key_takeaways',
  'additional-notes': 'additional_notes',
  'references': 'citations',
};

const String _releaseGitCommit = String.fromEnvironment(
  'MEDICOHUB_GIT_COMMIT',
  defaultValue: 'local',
);
const String _releaseBuildNumber = String.fromEnvironment(
  'MEDICOHUB_BUILD_NUMBER',
  defaultValue: '33',
);
const String _releaseBackendUrl = String.fromEnvironment(
  'MEDICOHUB_API_BASE_URL',
  defaultValue: 'https://medicohub-backend.fly.dev',
);
const String _releaseTranslateSectionEndpoint = '/api/translate-section';
const bool _releaseTranslationModuleEnabled = true;

T? safeDropdownValue<T>(T? currentValue, List<DropdownMenuItem<T>> items) {
  final values = items.map((item) => item.value).whereType<T>().toList();
  if (currentValue == null) {
    return null;
  }
  if (values.where((value) => value == currentValue).length == 1) {
    return currentValue;
  }
  return null;
}

Future<bool> _launchExternalLink(String url) async {
  final trimmed = url.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  final candidate = trimmed.contains(':') ? trimmed : 'https://$trimmed';
  final uri = Uri.tryParse(candidate);
  if (uri == null || uri.scheme.isEmpty) {
    return false;
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

HtmlWidget _linkedHtmlWidget(
  String html, {
  TextStyle? textStyle,
}) {
  return HtmlWidget(
    html,
    onTapUrl: _launchExternalLink,
    textStyle: textStyle,
  );
}

List<DropdownMenuItem<String>> _languageDropdownItemsExcluding(
    String sourceLanguageCode) {
  final seen = <String>{};
  return medicoHubLanguages
      .where((language) => language.code != sourceLanguageCode)
      .where((language) => seen.add(language.code))
      .map(
        (language) => DropdownMenuItem<String>(
          value: language.code,
          child: Text('${language.nativeLabel} (${language.label})'),
        ),
      )
      .toList();
}

const bool _youtubeOauthActionsEnabled = bool.fromEnvironment(
  'YOUTUBE_OAUTH_ACTIONS_ENABLED',
  defaultValue: false,
);
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
const List<String> _adPlacements = <String>[
  'home',
  'question',
  'education',
  'blog'
];
const String _androidBannerAdUnitId = 'ca-app-pub-9639630926363418/8715517435';
const String _androidAppOpenAdUnitId = 'ca-app-pub-9639630926363418/3417519336';
const String _iosBannerAdUnitId = 'ca-app-pub-9639630926363418/4253455835';
const String _iosAppOpenAdUnitId = 'ca-app-pub-9639630926363418/8422205095';
const String _androidTestBannerAdUnitId =
    'ca-app-pub-3940256099942544/6300978111';
const String _androidTestAppOpenAdUnitId =
    'ca-app-pub-3940256099942544/9257395921';
const String _iosTestBannerAdUnitId = 'ca-app-pub-3940256099942544/2934735716';
const String _iosTestAppOpenAdUnitId = 'ca-app-pub-3940256099942544/5575463023';
const String _brandLightAsset =
    'assets/branding/medicohub_we_connect_light.png';
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

enum _QuestionFeedScope { mine, public }

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
      localizationsDelegates: const [
        FlutterQuillLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
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
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

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
  final List<_ArticleSectionEditorData> _articleSectionEditors = [];
  final TextEditingController _articleSourceUrlController =
      TextEditingController();
  final TextEditingController _articleImageUrlController =
      TextEditingController();
  final TextEditingController _articleYoutubeUrlController =
      TextEditingController();
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
  final FocusNode _signInIdentifierFocusNode = FocusNode();
  final FocusNode _signupEmailFocusNode = FocusNode();

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
  final bool _identityLookupBusy = false;
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
  bool _biometricEnabled = false;
  bool _biometricAvailable = false;
  bool _biometricBusy = false;
  bool _emailVerified = false;
  bool _emailVerificationBusy = false;
  bool _bottomNavigationExpanded = true;
  bool _questionsRefreshing = false;
  int _tabIndex = 0;

  String _selectedExpiry = '7d';
  String _selectedLanguage = 'English';
  String _selectedAccountRole = 'patient';
  String _selectedSpecialty = 'General Health';
  String _selectedSignInChannel = 'Email';
  String? _selectedSignupPhoneChannel;
  String _selectedQuestionCategory = 'General';
  String? _questionFilterTopic;
  String? _selectedDoctorId;
  String _inviteDoctorLanguage = 'English';
  String _inviteDoctorSpecialty = 'General Health';
  String? _editingQuestionId;
  String _articleCategory = 'General Health';
  String? _editingArticleId;
  String _currentVersion = UpdateService.fallbackVersion;
  UpdateCheckFrequency _updateFrequency = UpdateCheckFrequency.daily;
  _QuestionFeedScope _questionFeedScope = _QuestionFeedScope.mine;
  _QuestionDateFilter _questionDateFilter = _QuestionDateFilter.allTime;
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
  final Set<String> _likingArticleIds = <String>{};
  String? _errorMessage;
  String? _articlePublishError;
  String? _authLookupMessage;
  String? _otpStatusMessage;
  String? _otpRequestedDestination;
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
  Timer? _backendRetryTimer;
  Timer? _bannerRetryTimer;
  Timer? _appOpenRetryTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _selectedSignInChannel = _defaultSignInChannelForLocale();
    _syncSignInIdentifierWithSelection();
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
    for (final section in _articleSectionEditors) {
      section.dispose();
    }
    _articleSourceUrlController.dispose();
    _articleImageUrlController.dispose();
    _articleYoutubeUrlController.dispose();
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
    _backendRetryTimer?.cancel();
    _bannerRetryTimer?.cancel();
    _appOpenRetryTimer?.cancel();
    _bannerAd?.dispose();
    _appOpenAd?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _voiceService.dispose();
    _signInIdentifierFocusNode.dispose();
    _signupEmailFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _showAppOpenAdIfReady();
      if (_activeUser != null) {
        unawaited(_refreshEmailVerificationState());
      }
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
      _signInIdentifierFocusNode
          .addListener(_handleSignInIdentifierFocusChange);
      _signupEmailFocusNode.addListener(_handleSignupEmailFocusChange);
      if (updateInfo != null) {
        unawaited(_handleAutoUpdateIfNeeded(updateInfo));
      }
      unawaited(_initializeMobileAdsIfNeeded());
      unawaited(_refreshBiometricAvailability());
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
        _voiceStatus =
            attempt < 6 ? 'Preparing secure services...' : _voiceStatus;
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
        _tryLoad(_api.fetchQuestions()),
        _tryLoad(_api.fetchEducation()),
        _tryLoad(_api.fetchBlogArticles()),
        _tryLoad(_api.fetchTitleTemplates()),
        _tryLoad(_api.fetchDoctors()),
        _tryLoad(_api.fetchNotificationSettings()),
        _tryLoad(_api.fetchAdCampaigns()),
        _tryLoad(_api.fetchAppSettings()),
      ]);
      if (!mounted) {
        return;
      }
      final questions = results[0] as List<ForumQuestion>?;
      final education = results[1] as List<EducationItem>?;
      final blogArticles = results[2] as List<BlogArticle>?;
      final titleTemplates = results[3] as List<TitleTemplate>?;
      final doctors = results[4] as List<DoctorDirectoryEntry>?;
      final notificationSettings = results[5] as NotificationSettings?;
      final adCampaigns = results[6] as List<AdCampaign>?;
      final appSettings = results[7] as AppSettings?;
      setState(() {
        if (questions != null) {
          _questions = questions;
        }
        if (education != null) {
          _education = education;
        }
        if (blogArticles != null) {
          _blogArticles = blogArticles;
        }
        if (titleTemplates != null) {
          _titleTemplates = titleTemplates;
        }
        if (doctors != null) {
          _doctors = doctors;
          _selectedDoctorId = doctors.isEmpty ? null : doctors.first.id;
        }
        if (notificationSettings != null) {
          _notificationSettings = notificationSettings;
        }
        if (adCampaigns != null) {
          _adCampaigns = adCampaigns;
        }
        if (appSettings != null) {
          _appSettings = appSettings;
        }
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
        _voiceStatus =
            attempt < 6 ? 'Preparing secure services...' : _voiceStatus;
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
  static const String _lastPhoneCountryCodePreferenceKey =
      'auth_last_phone_country_code';
  static const String _lastPhoneNationalNumberPreferenceKey =
      'auth_last_phone_national_number';
  static const String _biometricEnabledPreferenceKey = 'auth_biometric_enabled';
  static const String _secureEmailKey = 'medicohub_secure_email';
  static const String _securePasswordKey = 'medicohub_secure_password';

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
    final savedCountryCode =
        prefs.getString(_lastPhoneCountryCodePreferenceKey);
    final savedNationalNumber =
        prefs.getString(_lastPhoneNationalNumberPreferenceKey);
    _selectedSignupPhoneChannel = _labelForDialCode(savedCountryCode);
    _phoneController.text = savedNationalNumber ??
        _phoneDigitsWithoutCountryCode(
            prefs.getString(_lastPhonePreferenceKey) ?? '');
    _biometricEnabled = prefs.getBool(_biometricEnabledPreferenceKey) ?? false;
    _syncSignInIdentifierWithSelection();
  }

  Future<void> _persistAuthPreferences({
    String? email,
    String? phone,
    String? phoneCountryCode,
    String? phoneNationalNumber,
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
    if (phoneCountryCode != null && phoneCountryCode.trim().isNotEmpty) {
      await prefs.setString(
          _lastPhoneCountryCodePreferenceKey, phoneCountryCode.trim());
    }
    if (phoneNationalNumber != null && phoneNationalNumber.trim().isNotEmpty) {
      await prefs.setString(
        _lastPhoneNationalNumberPreferenceKey,
        phoneNationalNumber.trim(),
      );
    }
  }

  Future<void> _refreshBiometricAvailability() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      final available = supported && canCheck;
      if (!mounted) {
        return;
      }
      setState(() {
        _biometricAvailable = available;
        if (!available) {
          _biometricEnabled = false;
        }
      });
      if (!available) {
        await _prefs?.setBool(_biometricEnabledPreferenceKey, false);
      }
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _biometricAvailable = false;
        _biometricEnabled = false;
      });
    }
  }

  Future<void> _clearSecureSignIn() async {
    await _prefs?.setBool(_biometricEnabledPreferenceKey, false);
    await _secureStorage.delete(key: _secureEmailKey);
    await _secureStorage.delete(key: _securePasswordKey);
    if (mounted) {
      setState(() => _biometricEnabled = false);
    }
  }

  Future<void> _saveSecureSignInCredentials({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      return;
    }
    await _secureStorage.write(key: _secureEmailKey, value: normalizedEmail);
    await _secureStorage.write(key: _securePasswordKey, value: password);
  }

  Future<({String email, String password})?>
      _readSecureSignInCredentials() async {
    final email = await _secureStorage.read(key: _secureEmailKey);
    final password = await _secureStorage.read(key: _securePasswordKey);
    if (email == null ||
        email.trim().isEmpty ||
        password == null ||
        password.isEmpty) {
      return null;
    }
    return (email: email.trim(), password: password);
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
    _updateAutoOpen =
        prefs.getBool(UpdateService.preferenceAutoOpenKey) ?? false;
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

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;
  bool get _isIOS => !kIsWeb && Platform.isIOS;
  bool get _isMacOS => !kIsWeb && Platform.isMacOS;
  bool get _isWindows => !kIsWeb && Platform.isWindows;
  String get _platformName => kIsWeb ? 'web' : Platform.operatingSystem;

  bool get _supportsMobileAds => _isAndroid || _isIOS;

  String get _bannerAdUnitId {
    if (_isAndroid) {
      return (_useTestAds || kDebugMode)
          ? _androidTestBannerAdUnitId
          : _androidBannerAdUnitId;
    }
    if (_isIOS) {
      return (_useTestAds || kDebugMode)
          ? _iosTestBannerAdUnitId
          : _iosBannerAdUnitId;
    }
    return '';
  }

  String get _appOpenAdUnitId {
    if (_isAndroid) {
      return (_useTestAds || kDebugMode)
          ? _androidTestAppOpenAdUnitId
          : _androidAppOpenAdUnitId;
    }
    if (_isIOS) {
      return (_useTestAds || kDebugMode)
          ? _iosTestAppOpenAdUnitId
          : _iosAppOpenAdUnitId;
    }
    return '';
  }

  String get _adModeLabel =>
      _useTestAds || kDebugMode ? 'Test ads' : 'Live ads';

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
      _appOpenAdStatus =
          '$_adModeLabel initialized. Waiting for app-open fill...';
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
        _appOpenAdStatus =
            'Loading ${_adModeLabel.toLowerCase()} app-open ad...';
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

  Future<void> _showVideoPlayerSheet({
    required String videoId,
    required String videoUrl,
    required String title,
  }) async {
    if (videoId.isEmpty) {
      await _openExternalUrl(videoUrl);
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) {
        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.9,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Back to previous page',
                        onPressed: () => Navigator.of(context).maybePop(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close video',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Center(
                      child: SingleChildScrollView(
                        child: _ArticleYouTubePlayer(
                          videoId: videoId,
                          onOpenExternally: () => _openExternalUrl(videoUrl),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Use Back or Close above to return to MedicoHub without leaving the app.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _shareArticle(BlogArticle article) async {
    if (_activeUser?.isAdmin == true) {
      await _openAdminShareDialog(
        contentType: 'article',
        contentId: article.id,
        title: article.title,
        summary: article.summary,
      );
      return;
    }
    final videoUrl = article.youtubeUrl.isNotEmpty
        ? article.youtubeUrl
        : article.youtubeVideoId.isNotEmpty
            ? _normalizedYouTubeUrl(article.youtubeVideoId)
            : '';
    final text = [
      article.title,
      if (article.summary.isNotEmpty) article.summary,
      if (article.sourceUrl.isNotEmpty) article.sourceUrl,
      if (videoUrl.isNotEmpty) videoUrl,
    ].join('\n\n');
    await SharePlus.instance.share(
      ShareParams(
        subject: article.title,
        text: text,
      ),
    );
    unawaited(
      _api.recordGrowthEvent(
        eventName: 'article_shared',
        userId: _activeUser?.id,
        platform: _platformName,
        contentId: article.id,
        language: article.language,
        metadata: <String, Object?>{
          'content_type': 'article',
          'category': article.category,
        },
      ).catchError((_) {}),
    );
  }

  Future<void> _openAdminShareDialog({
    required String contentType,
    required String contentId,
    required String title,
    required String summary,
  }) async {
    final admin = _activeUser;
    if (admin == null || !admin.isAdmin) {
      return;
    }
    try {
      final users = await _api.fetchUsers();
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (context) => _AdminShareEmailDialog(
          api: _api,
          admin: admin,
          users: users,
          contentType: contentType,
          contentId: contentId,
          title: title,
          summary: summary,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load share recipients: $error')),
      );
    }
  }

  String _normalizedYouTubeUrl(String videoId) {
    return 'https://www.youtube.com/watch?v=$videoId';
  }

  String _extractYouTubeVideoId(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return '';
    }
    if (RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(trimmed)) {
      return trimmed;
    }
    final uri =
        Uri.tryParse(trimmed.contains('://') ? trimmed : 'https://$trimmed');
    if (uri == null) {
      return '';
    }
    final host = uri.host.toLowerCase().replaceFirst('www.', '');
    if (host == 'youtu.be') {
      final id = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      return RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id) ? id : '';
    }
    if (host == 'youtube.com' ||
        host == 'm.youtube.com' ||
        host == 'music.youtube.com') {
      final watchId = uri.queryParameters['v'];
      if (watchId != null && RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(watchId)) {
        return watchId;
      }
      if (uri.pathSegments.length >= 2 &&
          (uri.pathSegments.first == 'shorts' ||
              uri.pathSegments.first == 'embed')) {
        final id = uri.pathSegments[1];
        return RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(id) ? id : '';
      }
    }
    return '';
  }

  Widget _buildArticleHtml(BuildContext context, String value) {
    final html = value.trim().isEmpty ? '<p></p>' : value;
    return _linkedHtmlWidget(
      html,
      textStyle: Theme.of(context).textTheme.bodyMedium,
    );
  }

  String _escapeHtml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');

  bool _looksLikeHtml(String value) =>
      RegExp(r'<[a-zA-Z][\s\S]*>').hasMatch(value.trim());

  String _canonicalArticleSectionId(String id) {
    final normalized = id
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (normalized.isEmpty) {
      return 'summary';
    }
    return _legacyArticleSectionIdAliases[normalized] ?? normalized;
  }

  String _defaultArticleSectionLabel(String id, String fallback) {
    final canonical = _canonicalArticleSectionId(id);
    return _articleSectionOptions[canonical] ??
        (fallback.trim().isNotEmpty ? fallback.trim() : 'Section');
  }

  List<_DisplayArticleSection> normalizeArticleForDisplay(BlogArticle article) {
    final displaySections = <_DisplayArticleSection>[];
    final seen = <String>{};
    final orderedIds = <String>[
      ...article.sectionOrder,
      ...article.sections.keys
          .where((id) => !article.sectionOrder.contains(id)),
    ];

    for (final rawId in orderedIds) {
      final section = article.sections[rawId];
      if (section == null) {
        continue;
      }
      var id = _canonicalArticleSectionId(
          section.id.isNotEmpty ? section.id : rawId);
      if (seen.contains(id)) {
        id = '${id}_${seen.length + 1}';
      }
      final richHtml = _sectionContentToHtml(
        richTextHtml: section.richTextHtml,
        plainText: section.plainText,
      );
      final plainText = section.plainText.trim().isNotEmpty
          ? section.plainText.trim()
          : _plainTextFromHtmlOrMarkdown(section.richTextHtml);
      if (richHtml.trim().isEmpty && plainText.trim().isEmpty) {
        continue;
      }
      seen.add(id);
      displaySections.add(
        _DisplayArticleSection(
          id: id,
          label: _defaultArticleSectionLabel(id, section.label),
          customTitle: section.customTitle,
          richTextHtml: richHtml,
          plainText: plainText,
          updatedAt: section.updatedAt,
          isLegacyFallback: false,
          quillDeltaJson: section.quillDeltaJson,
        ),
      );
    }

    if (displaySections.isNotEmpty) {
      return displaySections;
    }

    final legacyContent =
        article.body.trim().isNotEmpty ? article.body : article.summary;
    final legacyHtml = _sectionContentToHtml(
      richTextHtml: article.bodyFormat == 'plain' ? '' : legacyContent,
      plainText: article.bodyFormat == 'plain' ? legacyContent : '',
    );
    final legacyPlain = _plainTextFromHtmlOrMarkdown(legacyContent);
    if (legacyHtml.trim().isEmpty && legacyPlain.trim().isEmpty) {
      return const <_DisplayArticleSection>[];
    }
    return <_DisplayArticleSection>[
      _DisplayArticleSection(
        id: 'summary',
        label: 'Summary',
        customTitle: '',
        richTextHtml: legacyHtml,
        plainText: legacyPlain,
        updatedAt: article.updatedAt,
        isLegacyFallback: true,
      ),
    ];
  }

  String _sectionContentToHtml({
    required String richTextHtml,
    required String plainText,
  }) {
    final rich = richTextHtml.trim();
    if (rich.isNotEmpty) {
      return _looksLikeHtml(rich) ? rich : _markdownishToHtml(rich);
    }
    final plain = plainText.trim();
    if (plain.isEmpty) {
      return '';
    }
    return _plainTextToParagraphHtml(plain);
  }

  String _markdownishToHtml(String value) {
    final lines = value.replaceAll('\r\n', '\n').split('\n');
    final buffer = StringBuffer();
    var inUl = false;
    var inOl = false;

    void closeLists() {
      if (inUl) {
        buffer.write('</ul>');
        inUl = false;
      }
      if (inOl) {
        buffer.write('</ol>');
        inOl = false;
      }
    }

    for (final rawLine in lines) {
      final line = rawLine.trimRight();
      if (line.trim().isEmpty) {
        closeLists();
        continue;
      }
      final headingMatch = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(line.trim());
      if (headingMatch != null) {
        closeLists();
        final level = headingMatch.group(1)!.length;
        buffer.write(
            '<h$level>${_inlineMarkdownToHtml(headingMatch.group(2)!)}</h$level>');
        continue;
      }
      final bulletMatch = RegExp(r'^\s*[-*]\s+(.+)$').firstMatch(line);
      if (bulletMatch != null) {
        if (inOl) {
          buffer.write('</ol>');
          inOl = false;
        }
        if (!inUl) {
          buffer.write('<ul>');
          inUl = true;
        }
        buffer
            .write('<li>${_inlineMarkdownToHtml(bulletMatch.group(1)!)}</li>');
        continue;
      }
      final numberMatch = RegExp(r'^\s*\d+\.\s+(.+)$').firstMatch(line);
      if (numberMatch != null) {
        if (inUl) {
          buffer.write('</ul>');
          inUl = false;
        }
        if (!inOl) {
          buffer.write('<ol>');
          inOl = true;
        }
        buffer
            .write('<li>${_inlineMarkdownToHtml(numberMatch.group(1)!)}</li>');
        continue;
      }
      closeLists();
      final quoteMatch = RegExp(r'^\s*>\s+(.+)$').firstMatch(line);
      if (quoteMatch != null) {
        buffer.write(
            '<blockquote>${_inlineMarkdownToHtml(quoteMatch.group(1)!)}</blockquote>');
      } else {
        buffer.write('<p>${_inlineMarkdownToHtml(line.trim())}</p>');
      }
    }
    closeLists();
    return buffer.toString();
  }

  String _plainTextToParagraphHtml(String value) {
    final paragraphs = value
        .replaceAll('\r\n', '\n')
        .split(RegExp(r'\n\s*\n'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    return paragraphs
        .map((part) => '<p>${_escapeHtml(part).replaceAll('\n', '<br>')}</p>')
        .join();
  }

  String _inlineMarkdownToHtml(String value) {
    var html = _escapeHtml(value);
    html = html.replaceAllMapped(
      RegExp(r'\[([^\]]+)\]\(([^)]+)\)'),
      (match) =>
          '<a href="${_escapeHtml(match.group(2) ?? '')}">${_escapeHtml(match.group(1) ?? '')}</a>',
    );
    html = html.replaceAllMapped(
      RegExp(r'\*\*(.+?)\*\*'),
      (match) => '<strong>${match.group(1)}</strong>',
    );
    html = html.replaceAllMapped(
      RegExp(r'__(.+?)__'),
      (match) => '<strong>${match.group(1)}</strong>',
    );
    html = html.replaceAllMapped(
      RegExp(r'\*(.+?)\*'),
      (match) => '<em>${match.group(1)}</em>',
    );
    html = html.replaceAllMapped(
      RegExp(r'_(.+?)_'),
      (match) => '<em>${match.group(1)}</em>',
    );
    html = html.replaceAll('&lt;u&gt;', '<u>').replaceAll('&lt;/u&gt;', '</u>');
    return html;
  }

  String _plainTextFromHtmlOrMarkdown(String value) {
    return value
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'!\[[^\]]*\]\([^)]+\)'), '')
        .replaceAllMapped(
          RegExp(r'\[([^\]]+)\]\([^)]+\)'),
          (match) => match.group(1) ?? '',
        )
        .replaceAll(RegExp(r'[*_`#>]'), '')
        .replaceAll(RegExp(r'^\s*[-*]\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^\s*\d+\.\s+', multiLine: true), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _canModerateOrOwnArticleComment(BlogArticleComment comment) {
    final user = _activeUser;
    if (user == null) {
      return false;
    }
    return user.isDoctor || user.isAdmin || comment.actorId == user.id;
  }

  bool _canEditArticle(BlogArticle article) {
    final user = _activeUser;
    if (user == null) {
      return false;
    }
    return user.isAdmin || article.authorId == user.id;
  }

  Future<BlogArticle?> _likeArticle(String articleId) async {
    final user = _activeUser;
    if (user == null || _likingArticleIds.contains(articleId)) {
      return null;
    }
    final current = _blogArticles.firstWhere(
      (article) => article.id == articleId,
      orElse: () => const BlogArticle(
        id: '',
        authorId: '',
        authorName: '',
        title: '',
        summary: '',
        body: '',
        category: '',
        language: '',
        sourceUrl: '',
        imageUrl: '',
        youtubeUrl: '',
        youtubeVideoId: '',
        bodyFormat: 'markdown',
        defaultLanguage: 'en',
        sectionOrder: [],
        sections: {},
        likeCount: 0,
        likedBy: [],
        comments: [],
        status: 'published',
        createdAt: '',
        updatedAt: '',
      ),
    );
    final wasLiked = current.likedByUser(user.id);
    final optimisticLikedBy = <String>{
      ...current.likedBy,
      if (!wasLiked) user.id,
    }..removeWhere((id) => wasLiked && id == user.id);
    final optimistic = current.id.isEmpty
        ? null
        : current.copyWith(
            likedBy: optimisticLikedBy.toList(),
            likeCount: optimisticLikedBy.length,
          );
    try {
      if (optimistic != null) {
        setState(() {
          _likingArticleIds.add(articleId);
          _blogArticles = _blogArticles
              .map((article) => article.id == articleId ? optimistic : article)
              .toList();
        });
      }
      final updated = await _api.likeBlogArticle(
        articleId: articleId,
        actorId: user.id,
      );
      if (!mounted) {
        return updated;
      }
      setState(() {
        _likingArticleIds.remove(articleId);
        _blogArticles = _blogArticles
            .map((article) => article.id == updated.id ? updated : article)
            .toList();
      });
      return updated;
    } catch (error) {
      if (mounted) {
        setState(() {
          _likingArticleIds.remove(articleId);
          if (optimistic != null) {
            _blogArticles = _blogArticles
                .map((article) => article.id == articleId ? current : article)
                .toList();
          }
          _errorMessage = 'Could not update article like: $error';
        });
      }
      return null;
    }
  }

  Future<BlogArticle?> _addArticleComment(String articleId, String body) async {
    final user = _activeUser;
    if (user == null || body.trim().isEmpty) {
      return null;
    }
    try {
      await _api.addBlogArticleComment(
        articleId: articleId,
        actorId: user.id,
        body: body.trim(),
      );
      final articles = await _api.fetchBlogArticles();
      if (!mounted) {
        return null;
      }
      setState(() {
        _blogArticles = articles;
        _voiceStatus = 'Comment posted.';
      });
      for (final article in articles) {
        if (article.id == articleId) {
          return article;
        }
      }
      return null;
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not post comment: $error');
      }
      return null;
    }
  }

  Future<void> _hideArticleComment(String articleId, String commentId) async {
    final user = _activeUser;
    if (user == null) {
      return;
    }
    try {
      await _api.moderateBlogArticleComment(
        articleId: articleId,
        commentId: commentId,
        actorId: user.id,
      );
      final articles = await _api.fetchBlogArticles();
      if (!mounted) {
        return;
      }
      setState(() {
        _blogArticles = articles;
        _voiceStatus = 'Comment removed.';
      });
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Could not remove comment: $error');
      }
    }
  }

  Future<void> _showYouTubeCommentConsent(BlogArticle article) async {
    // Phase 2 scaffold only: keep disabled in production until Google OAuth
    // verification approves https://www.googleapis.com/auth/youtube.force-ssl.
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('YouTube posting is not live yet'),
        content: const Text(
          'When enabled, this will post your comment publicly on YouTube using your Google/YouTube account. '
          'This feature is waiting for Google OAuth verification and will handle consent, quota, disabled comments, and invalid video errors before release.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _ensureBundledBackendForWindows() async {
    if (!_isWindows) {
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

  List<String> get _availableQuestionTopics {
    final topics = _appSettings?.questionTopics ?? _questionCategories;
    return topics.isEmpty ? _questionCategories : topics;
  }

  bool get _isAdminView => _activeUser?.isAdmin == true;

  bool get _canAccessGrowthStudio => _activeUser?.canAccessGrowthStudio == true;

  bool get _canViewOperationalDiagnostics {
    final user = _activeUser;
    return user?.isAdmin == true || user?.isDoctor == true;
  }

  bool get _canAccessDoctorPublishing {
    final user = _activeUser;
    return user?.isAdmin == true || user?.isDoctor == true;
  }

  int get _maxTabIndex => _canAccessDoctorPublishing ? 5 : 4;

  List<ForumQuestion> get _roleScopedQuestions {
    final user = _activeUser;
    if (user == null) {
      return const [];
    }
    final availableQuestions = _questions
        .where((question) => question.status.toLowerCase() != 'deleted')
        .toList();
    if (user.isAdmin) {
      return availableQuestions;
    }
    if (user.isDoctor) {
      return availableQuestions
          .where((question) =>
              _isAssignedToActiveDoctor(question, user) || question.isPublic)
          .toList();
    }
    return availableQuestions
        .where((question) =>
            _isAuthoredByActiveUser(question, user) || question.isPublic)
        .toList();
  }

  List<ForumQuestion> get _doctorCurrentQuestions {
    final user = _activeUser;
    if (user == null || !user.isDoctor) {
      return const [];
    }
    return _roleScopedQuestions.where((question) {
      if (!user.isAdmin && !_isAssignedToActiveDoctor(question, user)) {
        return false;
      }
      return question.status == 'open' ||
          _latestThreadMessageNeedsDoctor(question);
    }).toList()
      ..sort((a, b) =>
          _latestConversationMoment(b).compareTo(_latestConversationMoment(a)));
  }

  List<ForumQuestion> get _doctorHistoryQuestions {
    final user = _activeUser;
    if (user == null || !user.isDoctor) {
      return const [];
    }
    final currentIds =
        _doctorCurrentQuestions.map((question) => question.id).toSet();
    return _roleScopedQuestions.where((question) {
      if (!user.isAdmin && !_isAssignedToActiveDoctor(question, user)) {
        return false;
      }
      return !currentIds.contains(question.id);
    }).toList()
      ..sort((a, b) =>
          _latestConversationMoment(b).compareTo(_latestConversationMoment(a)));
  }

  List<NotificationOutboxItem> get _whatsAppNotifications {
    final items =
        _notifications.where((item) => item.channel == 'whatsapp').toList();
    items.sort(
      (a, b) =>
          _tryParseDate(b.createdAt).compareTo(_tryParseDate(a.createdAt)),
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
        ? _questions
            .where((question) =>
                question.status.toLowerCase() != 'deleted' && question.isPublic)
            .toList()
        : _roleScopedQuestions.where((question) {
            final user = _activeUser;
            if (user == null) {
              return false;
            }
            if (user.isAdmin || user.isDoctor) {
              return true;
            }
            return _isAuthoredByActiveUser(question, user);
          }).toList();
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

  bool get _canConfigureNotificationSettings => _activeUser?.isAdmin == true;

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

  bool get _supportsGoogleSignIn => kIsWeb || _isAndroid || _isIOS;

  String get _selectedDialCode => _isSignInUsingEmail
      ? ''
      : (_signInChannelOptions[_selectedSignInChannel] ?? '');

  String? get _selectedSignupDialCode => _selectedSignupPhoneChannel == null
      ? null
      : _signInChannelOptions[_selectedSignupPhoneChannel!];

  String get _formattedSignInDestination {
    final raw = _signInIdentifierController.text.trim();
    if (_isSignInUsingEmail) {
      return raw;
    }
    return _normalizeOtpPhoneDestination(raw);
  }

  String _defaultSignInChannelForLocale() {
    return 'Email';
  }

  String? _labelForDialCode(String? dialCode) {
    if (dialCode == null || dialCode.isEmpty) {
      return null;
    }
    for (final entry in _signInChannelOptions.entries) {
      if (entry.value == dialCode) {
        return entry.key;
      }
    }
    return null;
  }

  String _phoneDigitsWithoutCountryCode(String value) {
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    for (final code
        in _signInChannelOptions.values.where((value) => value != 'email')) {
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

  String? _composePhoneNumber(String? countryCode, String nationalNumber) {
    final code = (countryCode ?? '').replaceAll(RegExp(r'[^0-9]'), '');
    final national = _phoneDigitsWithoutCountryCode(nationalNumber);
    if (code.isEmpty || national.isEmpty) {
      return null;
    }
    return '+$code$national';
  }

  void _hydratePhoneFields(UserProfile profile) {
    final countryCode = profile.phoneCountryCode;
    final nationalNumber = profile.phoneNationalNumber ??
        _phoneDigitsWithoutCountryCode(profile.phoneNumber ?? '');
    _selectedSignupPhoneChannel = _labelForDialCode(countryCode);
    _phoneController.text = nationalNumber;
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

  void _handleSignInIdentifierFocusChange() {
    // Phone/email account checks now happen only after Continue is pressed.
  }

  void _handleSignupEmailFocusChange() {
    // Signup validation now happens only after Continue is pressed.
  }

  void _resetOtpJourney() {
    _otpRequested = false;
    _otpCodeController.clear();
    _otpStatusMessage = null;
    _otpRequestedDestination = null;
  }

  void _switchAuthSurface({
    required bool createAccountMode,
  }) {
    setState(() {
      _createAccountMode = createAccountMode;
      _errorMessage = null;
      _authLookupMessage = null;
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
      bottomNavigationBar: signedIn ? _buildBottomNavigationBar(context) : null,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : !signedIn
                  ? _buildLoginGate(context)
                  : Padding(
                      padding: const EdgeInsets.all(16),
                      child: RefreshIndicator(
                        onRefresh: _refreshCurrentPage,
                        child: IndexedStack(
                          index: _tabIndex.clamp(0, _maxTabIndex),
                          children: [
                            _buildHomeTab(context),
                            _buildAskTab(context),
                            _buildQuestionsTab(context),
                            _buildEducationTab(context),
                            _buildSettingsTab(context),
                            if (_canAccessDoctorPublishing)
                              _buildDoctorPublishingTab(context),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final destinations = <NavigationDestination>[
      const NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home_rounded),
        label: 'Home',
      ),
      const NavigationDestination(
        icon: Icon(Icons.add_circle_outline_rounded),
        selectedIcon: Icon(Icons.add_comment_rounded),
        label: 'Ask',
      ),
      const NavigationDestination(
        icon: Icon(Icons.forum_outlined),
        selectedIcon: Icon(Icons.forum_rounded),
        label: 'Questions',
      ),
      const NavigationDestination(
        icon: Icon(Icons.auto_stories_outlined),
        selectedIcon: Icon(Icons.auto_stories_rounded),
        label: 'Education',
      ),
      const NavigationDestination(
        icon: Icon(Icons.tune_outlined),
        selectedIcon: Icon(Icons.tune_rounded),
        label: 'Settings',
      ),
      if (_canAccessDoctorPublishing)
        const NavigationDestination(
          icon: Icon(Icons.edit_document),
          selectedIcon: Icon(Icons.edit_document),
          label: 'Publish',
        ),
    ];
    final selectedIndex = _tabIndex.clamp(0, destinations.length - 1);
    return Material(
      elevation: 4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              tooltip: _bottomNavigationExpanded
                  ? 'Hide navigation bar'
                  : 'Show navigation bar',
              icon: Icon(
                _bottomNavigationExpanded
                    ? Icons.keyboard_arrow_down_rounded
                    : Icons.keyboard_arrow_up_rounded,
              ),
              onPressed: () => setState(
                () => _bottomNavigationExpanded = !_bottomNavigationExpanded,
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: _bottomNavigationExpanded
                ? NavigationBar(
                    key: const ValueKey('expanded-navigation'),
                    selectedIndex: selectedIndex,
                    onDestinationSelected: (value) =>
                        setState(() => _tabIndex = value),
                    destinations: destinations,
                  )
                : const SizedBox.shrink(key: ValueKey('collapsed-navigation')),
          ),
        ],
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
          _buildBrandLogoImage(
            context,
            assetPath: Theme.of(context).brightness == Brightness.dark
                ? _brandIconDarkAsset
                : _brandIconLightAsset,
            height: 36,
            width: 36,
            radius: 18,
            overfill: 1.24,
            imageAlignment: Alignment.bottomLeft,
            canvasColor: _brandLogoShellColor(context),
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
            child: ActionChip(
              avatar: const Icon(Icons.person_outline_rounded, size: 18),
              label: Text(user.displayName.split(' ').first),
              onPressed: () => setState(() => _tabIndex = 4),
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
                  _buildBrandLogoImage(
                    context,
                    assetPath: Theme.of(context).brightness == Brightness.dark
                        ? _brandDarkAsset
                        : _brandLightAsset,
                    height: 96,
                    width: 116,
                    radius: 16,
                    overfill: 1.24,
                    imageAlignment: Alignment.bottomLeft,
                    canvasColor: _brandLogoShellColor(context),
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
                    icon: Icons.balance_rounded,
                    label: 'Vestibular Exercises',
                    onTap: () {
                      Navigator.of(context).pop();
                      _openVestibularExercises();
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.person_outline_rounded,
                    label: 'Profile & Settings',
                    onTap: () => _selectDrawerTab(context, 4),
                  ),
                  if (_canAccessDoctorPublishing)
                    _buildDrawerItem(
                      context,
                      icon: Icons.edit_document,
                      label: 'Doctor Publishing',
                      onTap: () => _selectDrawerTab(context, 5),
                    ),
                  if (_isAdminView)
                    _buildDrawerItem(
                      context,
                      icon: Icons.dataset_linked_outlined,
                      label: 'Admin Data Console',
                      onTap: () {
                        Navigator.of(context).pop();
                        _openAdminDataConsole();
                      },
                    ),
                  if (_canAccessGrowthStudio)
                    _buildDrawerItem(
                      context,
                      icon: Icons.trending_up_rounded,
                      label: 'Growth Studio',
                      onTap: () {
                        Navigator.of(context).pop();
                        _openGrowthStudio();
                      },
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

  void _jumpToTabFromConsole(int index) {
    setState(() => _tabIndex = index.clamp(0, _maxTabIndex));
  }

  void _openVestibularExercises() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const VestibularExerciseHomePage(),
      ),
    );
  }

  void _openAdminDataConsole() {
    final admin = _activeUser;
    if (admin == null || !admin.isAdmin) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdminDataConsolePage(
          api: _api,
          admin: admin,
          initialQuestions: _questions,
          initialDoctors: _doctors,
          initialArticles: _blogArticles,
          initialEducation: _education,
          initialSettings: _appSettings,
          onOpenQuestions: () => _jumpToTabFromConsole(2),
          onOpenSettings: () => _jumpToTabFromConsole(4),
          onOpenDoctorPublishing: _canAccessDoctorPublishing
              ? () => _jumpToTabFromConsole(5)
              : null,
        ),
      ),
    );
  }

  void _openGrowthStudio() {
    final admin = _activeUser;
    if (admin == null || !admin.canAccessGrowthStudio) {
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GrowthStudioPage(
          api: _api,
          admin: admin,
          articles: _blogArticles,
        ),
      ),
    );
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
                      _buildBrandLogoImage(
                        context,
                        assetPath:
                            Theme.of(context).brightness == Brightness.dark
                                ? _brandDarkAsset
                                : _brandLightAsset,
                        height: 88,
                        width: 106,
                        radius: 14,
                        overfill: 1.24,
                        imageAlignment: Alignment.bottomLeft,
                        canvasColor: _brandLogoShellColor(context),
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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.primary,
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
                  const SizedBox(height: 16),
                  Text(
                    'Build features',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  SelectableText(
                    'translationModule: ${_releaseTranslationModuleEnabled ? 'enabled' : 'disabled'}\n'
                    'translateSectionEndpoint: $_releaseTranslateSectionEndpoint\n'
                    'gitCommit: $_releaseGitCommit\n'
                    'buildNumber: $_releaseBuildNumber\n'
                    'backendUrl: $_releaseBackendUrl',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showEducationItemSheet(EducationItem item) async {
    final videoId =
        item.type == 'video' ? _extractYouTubeVideoId(item.url) : '';
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
                  Text(
                    item.category.toUpperCase(),
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.title,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                      '${item.type} • ${item.durationMinutes} min • ${item.language}'),
                  const SizedBox(height: 16),
                  TranslatedTextBlock(
                    text: item.summary,
                    title: 'Read summary in',
                  ),
                  if (item.url.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () {
                        if (videoId.isNotEmpty) {
                          _showVideoPlayerSheet(
                            videoId: videoId,
                            videoUrl: item.url,
                            title: item.title,
                          );
                        } else {
                          _openExternalUrl(item.url);
                        }
                      },
                      icon: Icon(
                        item.type == 'video'
                            ? Icons.play_circle_outline_rounded
                            : Icons.open_in_new_rounded,
                      ),
                      label: Text(item.type == 'video'
                          ? 'Watch full video'
                          : 'Read full source'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showBlogArticleSheet(BlogArticle article) async {
    final commentController = TextEditingController();
    var sheetArticle = article;
    final videoId = article.youtubeVideoId.isNotEmpty
        ? article.youtubeVideoId
        : _extractYouTubeVideoId(article.youtubeUrl);
    final videoUrl = article.youtubeUrl.isNotEmpty
        ? article.youtubeUrl
        : videoId.isNotEmpty
            ? _normalizedYouTubeUrl(videoId)
            : '';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
            final activeUserId = _activeUser?.id ?? '';
            final userLiked = activeUserId.isNotEmpty &&
                sheetArticle.likedByUser(activeUserId);
            final likeBusy = _likingArticleIds.contains(sheetArticle.id);
            return AnimatedPadding(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              padding: EdgeInsets.only(bottom: keyboardInset),
              child: SafeArea(
                child: FractionallySizedBox(
                  heightFactor: 0.94,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Back to app',
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.arrow_back_rounded),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Close',
                              onPressed: () => Navigator.of(context).pop(),
                              icon: const Icon(Icons.close_rounded),
                            ),
                          ],
                        ),
                        Text(
                          sheetArticle.category.toUpperCase(),
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          sheetArticle.title,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                            'By ${sheetArticle.authorName} • ${sheetArticle.language}'),
                        const SizedBox(height: 16),
                        _ArticleBulkTranslationPanel(
                          article: sheetArticle,
                          sections: _visibleArticleSections(sheetArticle),
                        ),
                        const SizedBox(height: 16),
                        for (final section
                            in _visibleArticleSections(sheetArticle)) ...[
                          Text(
                            section.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          _buildArticleHtml(
                            context,
                            section.richTextHtml.isNotEmpty
                                ? section.richTextHtml
                                : '<p>${_escapeHtml(section.plainText)}</p>',
                          ),
                          const SizedBox(height: 8),
                          _ArticleSectionTranslationControls(
                            article: sheetArticle,
                            section: section,
                          ),
                          const SizedBox(height: 18),
                        ],
                        if (videoId.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          _ArticleYouTubePlayer(
                            videoId: videoId,
                            onOpenExternally: () => _openExternalUrl(videoUrl),
                          ),
                        ],
                        if (sheetArticle.imageUrl.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              sheetArticle.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Text(
                                  'Article image could not be loaded.'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: likeBusy
                                  ? null
                                  : () async {
                                      final updated =
                                          await _likeArticle(sheetArticle.id);
                                      if (updated != null && context.mounted) {
                                        setSheetState(
                                            () => sheetArticle = updated);
                                      }
                                    },
                              icon: Icon(userLiked
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded),
                              label: Text(
                                userLiked
                                    ? 'Liked (${sheetArticle.likeCount})'
                                    : 'Like (${sheetArticle.likeCount})',
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _shareArticle(sheetArticle),
                              icon: const Icon(Icons.share_rounded),
                              label: const Text('Share'),
                            ),
                            if (sheetArticle.sourceUrl.isNotEmpty)
                              OutlinedButton.icon(
                                onPressed: () =>
                                    _openExternalUrl(sheetArticle.sourceUrl),
                                icon: const Icon(Icons.article_outlined),
                                label: const Text('Source'),
                              ),
                            if (videoUrl.isNotEmpty)
                              FilledButton.icon(
                                onPressed: () => _showVideoPlayerSheet(
                                  videoId: videoId,
                                  videoUrl: videoUrl,
                                  title: sheetArticle.title,
                                ),
                                icon: const Icon(
                                    Icons.play_circle_outline_rounded),
                                label: const Text('Open video'),
                              ),
                            if (_canEditArticle(sheetArticle))
                              FilledButton.tonalIcon(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  _startEditArticle(sheetArticle);
                                },
                                icon: const Icon(Icons.edit_rounded),
                                label: const Text('Edit article'),
                              ),
                            if (_youtubeOauthActionsEnabled &&
                                videoId.isNotEmpty)
                              OutlinedButton.icon(
                                // Pending Google OAuth verification. This action must not
                                // be exposed until the YouTube force-ssl scope is approved.
                                onPressed: () =>
                                    _showYouTubeCommentConsent(sheetArticle),
                                icon: const Icon(Icons.public_rounded),
                                label: const Text('Post to YouTube'),
                              ),
                          ],
                        ),
                        for (final campaign in _matchingCampaignsForText(
                          placement: 'article',
                          primaryText: sheetArticle.title,
                          secondaryText:
                              '${sheetArticle.summary} ${sheetArticle.body}',
                          category: sheetArticle.category,
                          language: sheetArticle.language,
                        ).take(1)) ...[
                          const SizedBox(height: 12),
                          _buildSponsoredCard(
                            context,
                            campaign,
                            label: 'Sponsored with this article',
                          ),
                        ],
                        const SizedBox(height: 24),
                        Text('Comments',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        TextField(
                          controller: commentController,
                          textCapitalization: TextCapitalization.sentences,
                          scrollPadding: EdgeInsets.only(
                            bottom: keyboardInset + 180,
                          ),
                          minLines: 2,
                          maxLines: 4,
                          onTapOutside: (_) => FocusScope.of(context).unfocus(),
                          decoration: const InputDecoration(
                            labelText: 'Add a comment',
                            helperText:
                                'Emojis and device speech-to-text are supported by your keyboard.',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton.icon(
                            onPressed: () async {
                              final updated = await _addArticleComment(
                                  sheetArticle.id, commentController.text);
                              if (updated != null && context.mounted) {
                                setSheetState(() {
                                  sheetArticle = updated;
                                  commentController.clear();
                                });
                                FocusScope.of(context).unfocus();
                              }
                            },
                            icon: const Icon(Icons.send_rounded),
                            label: const Text('Post comment'),
                          ),
                        ),
                        const SizedBox(height: 12),
                        for (final comment in sheetArticle.comments
                            .where((item) => item.moderationState == 'visible'))
                          Card(
                            child: ListTile(
                              title: Text(comment.actorName),
                              subtitle: TranslatedTextBlock(
                                text: comment.body,
                                title: 'Translate comment',
                              ),
                              trailing: _canModerateOrOwnArticleComment(comment)
                                  ? IconButton(
                                      tooltip: 'Delete comment',
                                      onPressed: () => _hideArticleComment(
                                        sheetArticle.id,
                                        comment.id,
                                      ),
                                      icon: const Icon(
                                          Icons.delete_outline_rounded),
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
    commentController.dispose();
  }

  List<_DisplayArticleSection> _visibleArticleSections(BlogArticle article) =>
      normalizeArticleForDisplay(article);

  Widget _buildLoginGate(BuildContext context) {
    final isSignup = _createAccountMode;
    final showPassword = !isSignup;
    const showOtpActions = false;
    final brandAsset = Theme.of(context).brightness == Brightness.dark
        ? _brandDarkAsset
        : _brandLightAsset;
    final media = MediaQuery.of(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.65),
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
                color: Theme.of(context)
                    .colorScheme
                    .surface
                    .withValues(alpha: 0.94),
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

  Widget _buildBrandLogoImage(
    BuildContext context, {
    required String assetPath,
    required double height,
    double? width,
    double radius = 16,
    double overfill = 1.04,
    Alignment imageAlignment = Alignment.center,
    Color? canvasColor,
  }) {
    final resolvedCanvasColor = canvasColor ??
        (Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surfaceContainerHighest);
    final imageWidth = width ?? height * 1.2;

    return SizedBox(
      width: imageWidth,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: DecoratedBox(
          decoration: BoxDecoration(color: resolvedCanvasColor),
          child: Transform.scale(
            scale: overfill,
            child: Image.asset(
              assetPath,
              width: imageWidth,
              height: height,
              fit: BoxFit.cover,
              alignment: imageAlignment,
            ),
          ),
        ),
      ),
    );
  }

  Color _brandLogoShellColor(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tint = colors.primary.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? 0.08 : 0.05,
    );
    return Color.alphaBlend(tint, colors.surface);
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
            Theme.of(context)
                .colorScheme
                .primaryContainer
                .withValues(alpha: 0.65),
            Theme.of(context).colorScheme.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: compact
          ? Row(
              children: [
                _buildBrandLogoImage(
                  context,
                  assetPath: Theme.of(context).brightness == Brightness.dark
                      ? _brandIconDarkAsset
                      : _brandIconLightAsset,
                  height: 72,
                  width: 72,
                  radius: 18,
                  overfill: 1.24,
                  imageAlignment: Alignment.bottomLeft,
                  canvasColor: _brandLogoShellColor(context),
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
                  child: _buildBrandLogoImage(
                    context,
                    assetPath: assetPath,
                    height: 170,
                    width: 204,
                    radius: 14,
                    overfill: 1.24,
                    imageAlignment: Alignment.bottomLeft,
                    canvasColor: _brandLogoShellColor(context),
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
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Full name',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
          ),
          SizedBox(height: spacing),
          if (compact) ...[
            TextField(
              controller: _emailController,
              focusNode: _signupEmailFocusNode,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.mail_outline_rounded),
              ),
            ),
            SizedBox(height: spacing),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Mobile number without country code',
                prefixIcon: Icon(Icons.call_outlined),
              ),
            ),
            SizedBox(height: spacing),
            DropdownButtonFormField<String>(
              initialValue: _selectedSignupPhoneChannel,
              decoration:
                  const InputDecoration(labelText: 'Country/region code'),
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
                setState(() => _selectedSignupPhoneChannel = value);
              },
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
              decoration:
                  const InputDecoration(labelText: 'Preferred language'),
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
                    focusNode: _signupEmailFocusNode,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autocorrect: false,
                    enableSuggestions: false,
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
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Mobile number without country code',
                      prefixIcon: Icon(Icons.call_outlined),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing),
            DropdownButtonFormField<String>(
              initialValue: _selectedSignupPhoneChannel,
              decoration:
                  const InputDecoration(labelText: 'Country/region code'),
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
                setState(() => _selectedSignupPhoneChannel = value);
              },
            ),
            SizedBox(height: spacing),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedAccountRole,
                    decoration:
                        const InputDecoration(labelText: 'Account role'),
                    items: _accountRoles
                        .map(
                          (role) => DropdownMenuItem<String>(
                            value: role,
                            child:
                                Text(role[0].toUpperCase() + role.substring(1)),
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
                    decoration:
                        const InputDecoration(labelText: 'Preferred language'),
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
                      useEmail ? 'Email' : (_selectedSignupPhoneChannel ?? '');
                  _errorMessage = null;
                  _resetOtpJourney();
                  _syncSignInIdentifierWithSelection();
                });
              },
            ),
          ),
          SizedBox(height: spacing),
          if (!_isSignInUsingEmail) ...[
            DropdownButtonFormField<String>(
              initialValue: _selectedSignInChannel.isEmpty
                  ? null
                  : _selectedSignInChannel,
              decoration:
                  const InputDecoration(labelText: 'Country/region code'),
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
            focusNode: _signInIdentifierFocusNode,
            keyboardType: _isSignInUsingEmail
                ? TextInputType.emailAddress
                : TextInputType.phone,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: _isSignInUsingEmail
                ? const [AutofillHints.username, AutofillHints.email]
                : const [AutofillHints.telephoneNumber],
            decoration: InputDecoration(
              labelText:
                  _isSignInUsingEmail ? 'Email address' : 'Mobile number',
              helperText: _isSignInUsingEmail
                  ? 'Use the email address registered with your account.'
                  : 'Use the mobile number registered with your account.',
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
            'Use the same password with either your email address or your registered mobile number.',
            style: textTheme.bodySmall,
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
            textInputAction: TextInputAction.done,
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
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'Create password',
              prefixIcon: const Icon(Icons.lock_outline_rounded),
              suffixIcon: IconButton(
                onPressed: () =>
                    setState(() => _passwordVisible = !_passwordVisible),
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
          _buildErrorNotice(context, _errorMessage!),
        ],
        if (!isSignup && _biometricEnabled && _biometricAvailable) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  _authBusy || _biometricBusy ? null : _signInWithBiometrics,
              icon: _biometricBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fingerprint_rounded),
              label: Text(
                _biometricBusy
                    ? 'Unlocking...'
                    : 'Use biometric / device unlock',
              ),
            ),
          ),
        ],
        if (_supportsGoogleSignIn) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _authBusy ? null : _signInWithGoogle,
              icon: const Icon(Icons.g_mobiledata_rounded),
              label: Text(
                  isSignup ? 'Sign up with Google' : 'Continue with Google'),
            ),
          ),
        ] else ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.g_mobiledata_rounded),
              label: const Text('Google sign-in on Android/iOS'),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Use email/password on Windows. Google sign-in remains enabled for phone and tablet builds.',
            style: Theme.of(context).textTheme.bodySmall,
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
                    : (showOtpActions
                        ? _verifyInlineOtp
                        : _signInWithFirebase)),
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
                isSignup
                    ? 'Already have an account?'
                    : "Don't have an account?",
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _authBusy
                    ? null
                    : () => _switchAuthSurface(
                          createAccountMode: !isSignup,
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
        style: style?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant),
        children: [
          const TextSpan(
            text:
                'By clicking continue you acknowledge you have read and agreed to our ',
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
    final pendingQuestions =
        scopedQuestions.where((question) => question.status == 'open').length;
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
          _buildErrorNotice(context, _errorMessage!),
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
                title: user.isAdmin
                    ? 'Admin Dashboard'
                    : user.isDoctor
                        ? 'Doctor Dashboard'
                        : 'Patient Dashboard',
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
                  body:
                      'Admins are also doctors in MedicoHub. Review questions routed to named doctors, post educational articles, and respond if coverage is needed.',
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
                        title: Text(question.title,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
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
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.primary),
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
                canDeleteResponses: _canDeleteDoctorResponses(question),
                onDeleteResponses: (responses) =>
                    _deleteDoctorResponses(question, responses),
                onShare: _activeUser?.isAdmin == true
                    ? () => _openAdminShareDialog(
                          contentType: 'question',
                          contentId: question.id,
                          title: question.title,
                          summary: question.aiSummary.isNotEmpty
                              ? question.aiSummary
                              : question.body,
                        )
                    : null,
                onShareResponse: _activeUser?.isAdmin == true
                    ? (response) => _openAdminShareDialog(
                          contentType: 'answer',
                          contentId: response.id,
                          title: question.title,
                          summary: response.fullText,
                        )
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
                        onShare: _activeUser?.isAdmin == true
                            ? () => _openAdminShareDialog(
                                  contentType: 'question',
                                  contentId: question.id,
                                  title: question.title,
                                  summary: question.aiSummary.isNotEmpty
                                      ? question.aiSummary
                                      : question.body,
                                )
                            : null,
                        onShareResponse: _activeUser?.isAdmin == true
                            ? (response) => _openAdminShareDialog(
                                  contentType: 'answer',
                                  contentId: response.id,
                                  title: question.title,
                                  summary: response.fullText,
                                )
                            : null,
                        canModerateMessage: (message) =>
                            _canModerateThreadMessage(question, message),
                        onModerateMessage: (message, state) =>
                            _moderateThreadMessage(question, message, state),
                        canDeleteResponses: _canDeleteDoctorResponses(question),
                        onDeleteResponses: (responses) =>
                            _deleteDoctorResponses(question, responses),
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
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
                ActionChip(
                  avatar: const Icon(Icons.bolt_rounded, size: 18),
                  label: Text(
                      '${_roleScopedQuestions.where((item) => item.status == 'open').length} open threads'),
                  onPressed: () => setState(() => _tabIndex = 2),
                ),
                ActionChip(
                  avatar: const Icon(Icons.auto_stories_rounded, size: 18),
                  label: Text('${_education.length} education items'),
                  onPressed: () => setState(() => _tabIndex = 3),
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
        icon: Icons.balance_outlined,
        label: 'Vestibular Exercises',
        onTap: _openVestibularExercises,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
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
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
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
                color: activated
                    ? Colors.green
                    : Theme.of(context).colorScheme.error,
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
              onPressed: _openWhatsAppActivationFlow,
              child: Text(activated ? 'Open' : 'Activate'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAskTab(BuildContext context) {
    final selectedDoctor = _selectedDoctor;
    final showAdvancedClassification =
        _isAdminView || _editingQuestionId != null;
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
                      ? 'Pick a doctor, confirm the language, and write the question. The broad heading can be adjusted here for sorting when needed.'
                      : 'Choose the doctor, confirm the language, and write the question. The title is optional; MedicoHub can create one from your question.',
                ),
                const SizedBox(height: 16),
                if (_doctors.isEmpty)
                  _QuestionEmptyState(
                    title: 'Doctor list is still loading',
                    message:
                        'The app could not show the doctor directory yet. Pull down to refresh or reopen the app; questions should not be submitted until a doctor is selected.',
                  )
                else
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
                if (showAdvancedClassification) ...[
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
                ],
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
                      setState(() => _selectedLanguage = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'MedicoHub will use a safe default heading for sorting. Doctors and admins can refine this later if needed.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Tooltip(
                  message:
                      'Optional. If this is left blank, MedicoHub will create a short title from the first words of the question.',
                  child: TextField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Title (optional)',
                      helperText: _isAdminView
                          ? 'Tip: keep this short and searchable.'
                          : 'Leave blank if unsure; MedicoHub will create one.',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _bodyController,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Question details',
                    helperText:
                        'Required. Describe your concern in everyday words.',
                  ),
                ),
                const SizedBox(height: 12),
                _buildVoiceCaptureCard(context),
                const SizedBox(height: 12),
                TextField(
                  controller: _symptomsController,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
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
                                (question) => question.id == _editingQuestionId,
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
                if (_premium || showAdvancedClassification) ...[
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (showAdvancedClassification)
                        Chip(label: Text(_selectedQuestionCategory)),
                      Chip(label: Text(_selectedLanguage)),
                      if (_premium) const Chip(label: Text('Second opinion')),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
                _buildAttachmentPanel(context),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: _submitting ? null : _submitQuestion,
                      child: Text(_submitting
                          ? 'Saving...'
                          : _editingQuestionId == null
                              ? 'Submit Question'
                              : 'Save Changes'),
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
    final publicQuestions =
        _filteredQuestionsForScope(_QuestionFeedScope.public);
    if (user.isDoctor) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildQuestionFilterCard(context),
          const SizedBox(height: 16),
          _buildQuestionListSection(
            context,
            title: 'Current',
            questions: _doctorCurrentQuestions
                .where(_questionMatchesDateFilter)
                .where((question) {
              if (_questionFilterTopic == null ||
                  _questionFilterTopic!.isEmpty) {
                return true;
              }
              return question.headingGroup == _questionFilterTopic;
            }).toList(),
          ),
          const SizedBox(height: 16),
          _buildQuestionHistorySections(
            context,
            title:
                user.isAdmin ? 'Admin History & Moderation' : 'Doctor History',
            questions: _doctorHistoryQuestions,
          ),
        ],
      );
    }
    return DefaultTabController(
      length: 2,
      initialIndex: _questionFeedScope.index,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          _buildQuestionFilterCard(context),
          const SizedBox(height: 16),
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
          if (_questionFeedScope == _QuestionFeedScope.mine)
            _buildQuestionHistorySections(
              context,
              title: 'My Question History',
              questions: myQuestions,
            )
          else
            _buildQuestionListSection(
              context,
              title: 'Public Questions',
              questions: publicQuestions,
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionHistorySections(
    BuildContext context, {
    required String title,
    required List<ForumQuestion> questions,
  }) {
    final filtered = _questionsMatchingActiveFilters(questions);
    final latest =
        filtered.isEmpty ? <ForumQuestion>[] : <ForumQuestion>[filtered.first];
    final latestId = latest.isEmpty ? null : latest.first.id;
    final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
    final lastMonth = filtered
        .where((question) =>
            question.id != latestId &&
            !_latestConversationMoment(question).isBefore(oneMonthAgo))
        .toList();
    final older = filtered
        .where((question) =>
            _latestConversationMoment(question).isBefore(oneMonthAgo))
        .toList();
    return Column(
      children: [
        _buildQuestionListSection(
          context,
          title: '$title: Latest',
          questions: latest,
        ),
        const SizedBox(height: 16),
        _buildQuestionListSection(
          context,
          title: 'Posted in the last month',
          questions: lastMonth,
        ),
        const SizedBox(height: 16),
        _buildQuestionListSection(
          context,
          title: 'Older than one month',
          questions: older,
        ),
      ],
    );
  }

  List<ForumQuestion> _questionsMatchingActiveFilters(
    List<ForumQuestion> source,
  ) {
    return source.where((question) {
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
  }

  Widget _buildQuestionFilterCard(BuildContext context) {
    final range = _customQuestionRange;
    final rangeLabel = range == null
        ? 'Select dates'
        : '${range.start.day}/${range.start.month}/${range.start.year} → ${range.end.day}/${range.end.month}/${range.end.year}';
    return Card(
      child: ExpansionTile(
        leading: const Icon(Icons.tune_rounded),
        title: const Text('Sort & Filter'),
        subtitle: Text(
          _questionFilterTopic == null
              ? _questionDateFilter.label
              : '${_questionDateFilter.label} • $_questionFilterTopic',
        ),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        children: [
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
      physics: const AlwaysScrollableScrollPhysics(),
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
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _showBlogArticleSheet(article),
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
                            Text(
                                'By ${article.authorName} • ${article.language}'),
                            const SizedBox(height: 12),
                            Text(article.summary),
                            const SizedBox(height: 12),
                            Text(
                              article.body,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                Chip(
                                  avatar: const Icon(Icons.favorite_rounded),
                                  label: Text('${article.likeCount} likes'),
                                ),
                                Chip(
                                  avatar: const Icon(
                                      Icons.chat_bubble_outline_rounded),
                                  label: Text(
                                      '${article.comments.where((item) => item.moderationState == 'visible').length} comments'),
                                ),
                                if (article.sourceUrl.isNotEmpty)
                                  const Chip(label: Text('Source linked')),
                                if (article.youtubeUrl.isNotEmpty)
                                  const Chip(label: Text('Video')),
                              ],
                            ),
                          ],
                        ),
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
        Text('Education Library',
            style: Theme.of(context).textTheme.titleLarge),
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
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _showEducationItemSheet(item),
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
                          Text(
                              '${item.type} • ${item.durationMinutes} min • ${item.language}'),
                          if (item.url.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              item.type == 'video'
                                  ? 'Tap to watch the full video.'
                                  : 'Tap to read the full source.',
                            ),
                          ],
                        ],
                      ),
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
            Row(
              children: [
                Expanded(
                  child: Text(title,
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                Chip(label: Text('${questions.length}')),
              ],
            ),
            const SizedBox(height: 16),
            if (questions.isEmpty)
              _QuestionEmptyState(
                title: 'No visible threads here yet',
                message:
                    'MedicoHub fetched ${_questions.length} thread${_questions.length == 1 ? '' : 's'} from the server. This section only shows threads matching your role, public/private scope, date range, and topic filter.',
              )
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
                        canDeleteResponses: _canDeleteDoctorResponses(question),
                        onDeleteResponses: (responses) =>
                            _deleteDoctorResponses(question, responses),
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

  Widget _buildErrorNotice(BuildContext context, String message) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: kDebugMode ? colors.error : colors.errorContainer,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (kDebugMode) ...[
            Text(
              'Debug notice',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onErrorContainer,
                  ),
            ),
            const SizedBox(height: 4),
          ],
          Text(
            message,
            style: TextStyle(color: colors.onErrorContainer),
          ),
          if (kDebugMode &&
              (message.contains('Firebase sign-in failed') ||
                  message.contains('Firebase auth'))) ...[
            const SizedBox(height: 8),
            Text(
              'Technical details were written to the console. The app now keeps the login screen readable for users.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onErrorContainer,
                  ),
            ),
          ],
        ],
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
                  subtitle: Text(
                      '${user.email}\n${user.role} • ${user.languages.join(', ')}'),
                  isThreeLine: true,
                ),
                if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('Mobile: ${user.phoneNumber}'),
                  ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _emailVerified
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _emailVerified
                                ? Icons.verified_outlined
                                : Icons.mark_email_unread_outlined,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _emailVerified
                                  ? 'Email verified'
                                  : 'Verify your email once',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _emailVerified
                            ? 'Your Firebase sign-in email has been confirmed.'
                            : 'Open the verification link sent to ${user.email}. This helps protect account recovery and notifications.',
                      ),
                      if (!_emailVerified) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: _emailVerificationBusy
                                  ? null
                                  : () => unawaited(
                                        _sendEmailVerificationLink(
                                            manual: true),
                                      ),
                              child: Text(
                                _emailVerificationBusy
                                    ? 'Sending...'
                                    : 'Resend verification',
                              ),
                            ),
                            FilledButton.tonal(
                              onPressed: _emailVerificationBusy
                                  ? null
                                  : () => unawaited(
                                        _refreshEmailVerificationState(
                                          showStatus: true,
                                        ),
                                      ),
                              child: const Text('Check verification'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Biometric/device-unlock sign-in is optional and free on supported phones and computers. If enabled, your password is saved only in this device’s encrypted secure storage.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 20),
                Text('Settings', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.mark_email_read_outlined),
                  title: const Text('Email notifications'),
                  subtitle: Text(user.emailSubscribed
                      ? 'Subscribed to MedicoHub email updates that match your preferences.'
                      : 'Unsubscribed. Turn this on to receive MedicoHub emails again.'),
                  value: user.emailSubscribed,
                  onChanged: (value) =>
                      unawaited(_updateMyEmailSubscription(value)),
                ),
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
                if (widget.themeConfig.preset ==
                    MedicoHubThemePreset.custom) ...[
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
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                      color: _customThemeDarkMode
                                          ? Colors.white70
                                          : null,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _themeHexController.text.isEmpty
                                    ? widget.themeConfig.customSeedHex
                                    : _themeHexController.text,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                      color: _customThemeDarkMode
                                          ? Colors.white
                                          : null,
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
                          _isAndroid ? 'Download APK' : 'Open Update',
                        ),
                      ),
                  ],
                ),
                if (_canViewOperationalDiagnostics) ...[
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
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
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
                ],
                const SizedBox(height: 16),
                SwitchListTile(
                  value: _biometricEnabled,
                  onChanged: _biometricAvailable
                      ? (value) => unawaited(_setBiometricSignInEnabled(value))
                      : null,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Biometric / device-unlock sign-in'),
                  subtitle: Text(
                    _biometricAvailable
                        ? 'Optional. Saves your password in this device’s encrypted storage and unlocks it with biometrics/device PIN.'
                        : 'Not available on this device. Password sign-in remains active.',
                  ),
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
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onErrorContainer,
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
                        onPressed: _deleteAccountBusy
                            ? null
                            : _openDeleteAccountDialog,
                        icon: _deleteAccountBusy
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
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
                      _whatsAppNotifications
                              .any((item) => item.status == 'sent')
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
            child: ListTile(
              contentPadding: const EdgeInsets.all(20),
              leading: const Icon(Icons.dataset_linked_outlined),
              title: const Text('Admin Data Console'),
              subtitle: const Text(
                'View live app data summaries and jump to safe moderation, publishing, and settings screens.',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _openAdminDataConsole,
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
                    onPressed:
                        _appSettingsBusy ? null : () => _saveAppSettings(),
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
                    decoration: const InputDecoration(labelText: 'Ad headline'),
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
                    decoration: const InputDecoration(labelText: 'Target URL'),
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
                    decoration: const InputDecoration(labelText: 'Placement'),
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
                                  onPressed: () =>
                                      _toggleAdCampaignActive(campaign),
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
                    decoration: const InputDecoration(labelText: 'Doctor name'),
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
                    child: Text(_adminBusy ? 'Saving...' : 'Add Title Example'),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (_canAccessDoctorPublishing) ...[
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.edit_document),
              title: const Text('Doctor Publishing'),
              subtitle: const Text(
                'Write patient-friendly articles from a dedicated doctor/admin workspace.',
              ),
              trailing: const Icon(Icons.arrow_forward_rounded),
              onTap: () => setState(() => _tabIndex = 5),
            ),
          ),
        ],
        if (_canViewOperationalDiagnostics &&
            (_whatsAppNotifications.isNotEmpty ||
                _emailComingLaterNotifications.isNotEmpty)) ...[
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
                                    onPressed: () =>
                                        _openNotificationLink(item.deepLink!),
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
            Text('Voice Input', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              _isAndroid
                  ? 'Android path: use Gboard or an Indic keyboard mic for quick speech-to-text, or record an audio note.'
                  : kIsWeb
                      ? 'Web path: use your keyboard microphone or type your question, then attach files if needed.'
                      : 'Windows path: record an audio note, preview it, redo it if needed, then upload it.',
            ),
            if (_voiceStatus != null) ...[
              const SizedBox(height: 12),
              Text(
                _voiceStatus!,
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
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
                  onPressed: _recordingAudio
                      ? _stopAudioRecording
                      : _startAudioRecording,
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
                  onPressed: _listeningNative
                      ? _stopNativeListening
                      : _startNativeListening,
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
                  onPressed: hasAudio && !_uploadingAttachment
                      ? _uploadRecordedAudio
                      : null,
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
              label: Text(
                  _uploadingAttachment ? 'Uploading...' : 'Add Report File'),
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
    var email = _formattedSignInDestination;
    if (!_isSignInUsingEmail) {
      if (_selectedDialCode.isEmpty ||
          _signInIdentifierController.text.trim().isEmpty) {
        setState(() {
          _errorMessage =
              'Choose a country code and enter your mobile number to continue.';
        });
        return;
      }
      final profile = await _api.lookupUserByPhone(
        phoneCountryCode: _selectedDialCode,
        phoneNationalNumber: _phoneDigitsWithoutCountryCode(
          _signInIdentifierController.text.trim(),
        ),
      );
      if (profile == null || profile.email.isEmpty) {
        setState(() {
          _errorMessage =
              'No account was found for this mobile number. Try your email address or register first.';
        });
        return;
      }
      email = profile.email;
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
        _emailVerified =
            firebaseUser.verified || _auth.currentUserEmailVerified;
        _selectedLanguage = profile.languages.isEmpty
            ? _selectedLanguage
            : profile.languages.first;
        _authBusy = false;
        _emailController.text = email;
        _hydratePhoneFields(profile);
        _resetOtpJourney();
      });
      await _persistAuthPreferences(
        email: email,
        phone: profile.phoneNumber,
        phoneCountryCode: profile.phoneCountryCode,
        phoneNationalNumber: profile.phoneNationalNumber,
      );
      if (_biometricEnabled) {
        await _saveSecureSignInCredentials(
          email: email,
          password: _passwordController.text,
        );
      }
      await _promptEmailVerificationIfNeeded(email);
      await _refreshNotifications(profile.id);
      await _refreshQuestions(showStatus: false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _authBusy = false;
        _errorMessage = _signInFriendlyError(error);
      });
    }
  }

  Future<void> _signInWithGoogle() async {
    if (!_supportsGoogleSignIn || _authBusy) {
      return;
    }
    setState(() {
      _authBusy = true;
      _errorMessage = null;
    });
    try {
      await _api.waitUntilReady();
      final firebaseUser = await _auth.signInWithGoogle();
      final profile = await _loadOrCreateGoogleBackendProfile(firebaseUser);
      if (!mounted) {
        return;
      }
      setState(() {
        _activeUser = profile;
        _emailVerified =
            firebaseUser.verified || _auth.currentUserEmailVerified;
        _selectedLanguage = profile.languages.isEmpty
            ? _selectedLanguage
            : profile.languages.first;
        _authBusy = false;
        _emailController.text = profile.email;
        _selectedSignInChannel = 'Email';
        _signInIdentifierController.text = profile.email;
        _hydratePhoneFields(profile);
        _resetOtpJourney();
      });
      await _persistAuthPreferences(
        email: profile.email,
        phone: profile.phoneNumber,
        phoneCountryCode: profile.phoneCountryCode,
        phoneNationalNumber: profile.phoneNationalNumber,
      );
      await _refreshNotifications(profile.id);
      await _refreshQuestions(showStatus: false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _authBusy = false;
        final message = _firebaseFriendlyError(error);
        _errorMessage = message.contains('cancelled')
            ? 'Google sign-in was cancelled.'
            : 'Google sign-in failed: $message';
      });
    }
  }

  Future<void> _signInWithBiometrics() async {
    if (!_biometricAvailable || !_biometricEnabled || _biometricBusy) {
      return;
    }
    setState(() {
      _biometricBusy = true;
      _errorMessage = null;
    });
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Unlock your saved MedicoHub sign-in on this device.',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (!authenticated) {
        if (mounted) {
          setState(() => _biometricBusy = false);
        }
        return;
      }
      final credentials = await _readSecureSignInCredentials();
      if (credentials == null) {
        await _clearSecureSignIn();
        if (!mounted) {
          return;
        }
        setState(() {
          _biometricBusy = false;
          _errorMessage =
              'No saved password was found on this device. Please sign in once with your password, then enable biometric sign-in again.';
        });
        return;
      }
      final firebaseProfile = await _auth.signInWithEmail(
        email: credentials.email,
        password: credentials.password,
      );
      final profile = await _loadOrCreateBackendProfile(firebaseProfile);
      if (!mounted) {
        return;
      }
      setState(() {
        _activeUser = profile;
        _emailVerified =
            firebaseProfile.verified || _auth.currentUserEmailVerified;
        _biometricBusy = false;
        _selectedLanguage = profile.languages.isEmpty
            ? _selectedLanguage
            : profile.languages.first;
        _emailController.text = profile.email;
        _selectedSignInChannel = 'Email';
        _signInIdentifierController.text = profile.email;
        _passwordController.text = credentials.password;
        _hydratePhoneFields(profile);
        _resetOtpJourney();
      });
      await _persistAuthPreferences(
        email: profile.email,
        phone: profile.phoneNumber,
        phoneCountryCode: profile.phoneCountryCode,
        phoneNationalNumber: profile.phoneNationalNumber,
      );
      await _refreshNotifications(profile.id);
      await _refreshQuestions(showStatus: false);
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _biometricBusy = false;
        _errorMessage = 'Biometric sign-in is not available: $error';
      });
    }
  }

  Future<void> _setBiometricSignInEnabled(bool value) async {
    if (!value) {
      await _clearSecureSignIn();
      return;
    }
    final user = _activeUser;
    if (user == null) {
      return;
    }
    if (!_biometricAvailable) {
      setState(() {
        _errorMessage =
            'Biometric or device-unlock sign-in is not available on this device.';
      });
      return;
    }
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _errorMessage =
            'Enter your password once before enabling biometric sign-in on this device.';
      });
      return;
    }
    final authenticated = await _localAuth.authenticate(
      localizedReason:
          'Confirm device unlock to save your MedicoHub password on this device.',
      options: const AuthenticationOptions(stickyAuth: true),
    );
    if (!authenticated) {
      return;
    }
    await _saveSecureSignInCredentials(
      email: user.email,
      password: password,
    );
    await _prefs?.setBool(_biometricEnabledPreferenceKey, true);
    if (!mounted) {
      return;
    }
    setState(() {
      _biometricEnabled = true;
      _voiceStatus =
          'Biometric/device sign-in is enabled. Your password is saved only in this device’s encrypted secure storage.';
    });
  }

  String _emailVerificationPromptKey(String email) {
    return 'email_verification_prompted_${_normalizeEmail(email)}';
  }

  Future<void> _refreshEmailVerificationState({bool showStatus = false}) async {
    try {
      await _auth.reloadCurrentUser();
      final verified = _auth.currentUserEmailVerified;
      if (!mounted) {
        return;
      }
      setState(() {
        _emailVerified = verified;
        if (showStatus) {
          _voiceStatus = verified
              ? 'Email verification is complete.'
              : 'Email is not verified yet. Check your inbox for the verification link.';
        }
      });
    } catch (error) {
      if (!mounted || !showStatus) {
        return;
      }
      setState(() {
        _voiceStatus = 'Could not refresh email verification status: $error';
      });
    }
  }

  Future<void> _sendEmailVerificationLink({bool manual = false}) async {
    final user = _activeUser;
    if (user == null || user.email.isEmpty || _emailVerificationBusy) {
      return;
    }
    if (!_auth.hasCurrentFirebaseUser) {
      setState(() {
        _voiceStatus =
            'Email verification is available after native Firebase sign-in. You can continue using the app now.';
      });
      return;
    }
    setState(() {
      _emailVerificationBusy = true;
      _errorMessage = null;
    });
    try {
      await _auth.sendEmailVerification();
      await _prefs?.setBool(_emailVerificationPromptKey(user.email), true);
      if (!mounted) {
        return;
      }
      setState(() {
        _emailVerificationBusy = false;
        _voiceStatus =
            'Verification email sent to ${user.email}. Open the link once, then return and tap Check verification.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _emailVerificationBusy = false;
        _errorMessage =
            'Could not send verification email: ${_firebaseFriendlyError(error)}';
      });
    }
  }

  Future<void> _promptEmailVerificationIfNeeded(String email) async {
    if (!_auth.hasCurrentFirebaseUser) {
      return;
    }
    await _refreshEmailVerificationState();
    if (_emailVerified) {
      return;
    }
    final prompted =
        _prefs?.getBool(_emailVerificationPromptKey(email)) ?? false;
    if (!prompted) {
      await _sendEmailVerificationLink();
      return;
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _voiceStatus =
          'Please verify your email once from the link we sent earlier. You can resend it from Settings.';
    });
  }

  Future<void> _registerFirebaseUser() async {
    setState(() {
      _authBusy = true;
      _errorMessage = null;
    });
    try {
      await _api.waitUntilReady();
      if (_phoneController.text.trim().isNotEmpty &&
          _selectedSignupDialCode == null) {
        throw Exception('Choose a country code for the mobile number.');
      }
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
        phoneNumber: _composePhoneNumber(
          _selectedSignupDialCode,
          _phoneController.text.trim(),
        ),
        phoneCountryCode: _selectedSignupDialCode,
        phoneNationalNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneDigitsWithoutCountryCode(_phoneController.text.trim()),
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
        _emailVerified =
            firebaseUser.verified || _auth.currentUserEmailVerified;
        _authBusy = false;
        _selectedSignInChannel = 'Email';
        _syncSignInIdentifierWithSelection();
      });
      await _persistAuthPreferences(
        email: profile.email,
        phone: profile.phoneNumber,
        phoneCountryCode: profile.phoneCountryCode,
        phoneNationalNumber: profile.phoneNationalNumber,
      );
      if (_biometricEnabled) {
        await _saveSecureSignInCredentials(
          email: profile.email,
          password: _passwordController.text,
        );
      }
      await _sendEmailVerificationLink();
      await _refreshNotifications(profile.id);
      await _refreshQuestions(showStatus: false);
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
    final phone = _normalizePhone(
      _composePhoneNumber(_selectedSignupDialCode, _phoneController.text),
    );
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
          (phone.isNotEmpty && _normalizePhone(doctor.phoneNumber) == phone);
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

  Future<T?> _tryLoad<T>(Future<T> request) async {
    try {
      return await request;
    } catch (_) {
      return null;
    }
  }

  Future<void> _refreshCurrentPage() async {
    if (_activeUser == null) {
      return;
    }
    if (_tabIndex == 2) {
      await _refreshQuestions();
      return;
    }
    if (_tabIndex == 3 || (_canAccessDoctorPublishing && _tabIndex == 5)) {
      final results = await Future.wait([
        _tryLoad(_api.fetchEducation()),
        _tryLoad(_api.fetchBlogArticles()),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        final education = results[0] as List<EducationItem>?;
        final articles = results[1] as List<BlogArticle>?;
        if (education != null) {
          _education = education;
        }
        if (articles != null) {
          _blogArticles = articles;
        }
        _voiceStatus = 'Education content refreshed.';
      });
      return;
    }
    await _loadInitialRemoteData();
  }

  Future<void> _refreshQuestions({bool showStatus = true}) async {
    if (_questionsRefreshing) {
      return;
    }
    if (mounted) {
      setState(() {
        _questionsRefreshing = true;
        if (showStatus) {
          _voiceStatus = 'Refreshing question history...';
        }
      });
    }
    try {
      final questions = await _api.fetchQuestions();
      if (!mounted) {
        return;
      }
      setState(() {
        _questions = questions;
        _questionsRefreshing = false;
        if (showStatus) {
          _voiceStatus =
              'Loaded ${questions.length} question${questions.length == 1 ? '' : 's'}.';
        }
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _questionsRefreshing = false;
        _voiceStatus = 'Question history could not be refreshed: $error';
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
      await _refreshQuestions(showStatus: false);
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
        throw Exception('Mobile OTP sign-in is currently disabled.');
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
        throw Exception('Mobile OTP sign-in is currently disabled.');
      }
      final destination =
          _otpRequestedDestination ?? _formattedSignInDestination;
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
        _selectedLanguage = profile.languages.isEmpty
            ? _selectedLanguage
            : profile.languages.first;
        _emailController.text = profile.email;
        _hydratePhoneFields(profile);
        _authBusy = false;
        _voiceStatus = 'Signed in successfully.';
        _resetOtpJourney();
      });
      await _refreshNotifications(profile.id);
      await _refreshQuestions(showStatus: false);
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

  Future<UserProfile> _loadOrCreateBackendProfile(
      UserProfile firebaseUser) async {
    final existing = await _api.fetchUserProfile(firebaseUser.id);
    if (existing != null) {
      return existing;
    }
    final rosterMatch = await _resolveRosterMatch(firebaseUser.email);
    if (rosterMatch != null &&
        _normalizeEmail(rosterMatch.email) !=
            _normalizeEmail(firebaseUser.email)) {
      throw Exception(
        'The signed-in Firebase email does not match the MedicoHub roster lookup result. Please sign out and try again.',
      );
    }
    if (rosterMatch == null) {
      return _api.upsertUserProfile(
        id: firebaseUser.id,
        email: firebaseUser.email,
        displayName: firebaseUser.displayName.isEmpty
            ? firebaseUser.email
            : firebaseUser.displayName,
        role: 'patient',
        languages: [_selectedLanguage],
        specialties: const [],
      );
    }
    return _api.upsertUserProfile(
      id: firebaseUser.id,
      email: firebaseUser.email,
      displayName: rosterMatch.displayName,
      phoneNumber: rosterMatch.phoneNumber,
      phoneCountryCode: rosterMatch.phoneCountryCode,
      phoneNationalNumber: rosterMatch.phoneNationalNumber,
      role: rosterMatch.role,
      languages: rosterMatch.languages.isEmpty
          ? [_selectedLanguage]
          : rosterMatch.languages,
      specialties: rosterMatch.specialties,
    );
  }

  Future<UserProfile> _loadOrCreateGoogleBackendProfile(
    UserProfile firebaseUser,
  ) async {
    final existing = await _api.fetchUserProfile(firebaseUser.id);
    if (existing != null) {
      return existing;
    }
    final rosterMatch = await _resolveRosterMatch(firebaseUser.email);
    if (rosterMatch != null &&
        _normalizeEmail(rosterMatch.email) ==
            _normalizeEmail(firebaseUser.email)) {
      return _api.upsertUserProfile(
        id: firebaseUser.id,
        email: firebaseUser.email,
        displayName: rosterMatch.displayName,
        phoneNumber: rosterMatch.phoneNumber,
        phoneCountryCode: rosterMatch.phoneCountryCode,
        phoneNationalNumber: rosterMatch.phoneNationalNumber,
        role: rosterMatch.role,
        languages: rosterMatch.languages.isEmpty
            ? [_selectedLanguage]
            : rosterMatch.languages,
        specialties: rosterMatch.specialties,
      );
    }
    return _api.upsertUserProfile(
      id: firebaseUser.id,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName.isEmpty
          ? firebaseUser.email
          : firebaseUser.displayName,
      role: 'patient',
      languages: [_selectedLanguage],
      specialties: const [],
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
        _hydratePhoneFields(freshLookup);
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

  Widget _buildDoctorPublishingTab(BuildContext context) {
    final user = _activeUser!;
    if (!_canAccessDoctorPublishing) {
      return const Center(
        child: Text('Doctor publishing is not available for this account.'),
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_document),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Doctor Publishing',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  user.isAdmin
                      ? 'Publish or coordinate patient-friendly education posts for the MedicoHub blog.'
                      : 'Publish patient-friendly education posts that appear in the Education blog page.',
                ),
                if (_articlePublishError != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorNotice(context, _articlePublishError!),
                ],
                const SizedBox(height: 16),
                TextField(
                  controller: _articleTitleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Article title'),
                ),
                const SizedBox(height: 12),
                _buildArticleSectionEditors(context),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _articleCategory,
                  decoration:
                      const InputDecoration(labelText: 'Article category'),
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
                const SizedBox(height: 12),
                TextField(
                  controller: _articleSourceUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Source / full article URL',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _articleImageUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Image URL',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _articleYoutubeUrlController,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'YouTube video URL',
                    helperText:
                        'Paste a watch, shorts, embed, youtu.be URL, or video ID.',
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: _adminBusy ? null : _publishDoctorArticle,
                      icon: Icon(_editingArticleId == null
                          ? Icons.publish_rounded
                          : Icons.save_rounded),
                      label: Text(_adminBusy
                          ? 'Saving...'
                          : _editingArticleId == null
                              ? 'Publish Article'
                              : 'Save Changes'),
                    ),
                    if (_editingArticleId != null)
                      OutlinedButton.icon(
                        onPressed: _clearArticleEditor,
                        icon: const Icon(Icons.close_rounded),
                        label: const Text('Cancel edit'),
                      ),
                  ],
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
                  'Published Blog Articles',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                if (_blogArticles.isEmpty)
                  const Text('No doctor articles have been published yet.')
                else
                  ..._blogArticles.map(
                    (article) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.article_outlined),
                      title: Text(article.title),
                      subtitle:
                          Text('${article.category} • ${article.authorName}'),
                      onTap: () => _showBlogArticleSheet(article),
                      trailing: _canEditArticle(article)
                          ? IconButton(
                              tooltip: 'Edit article',
                              onPressed: () => _startEditArticle(article),
                              icon: const Icon(Icons.edit_rounded),
                            )
                          : null,
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
                Text(
                  'Doctor Sharing & Outreach',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'This area is reserved for doctor-facing publishing, patient invitations, and future blog comment moderation. It is intentionally hidden from patient accounts.',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _canRespondToQuestion(ForumQuestion question) {
    final user = _activeUser;
    if (user == null || !user.isDoctor) {
      return false;
    }
    if (user.isAdmin) {
      if (_isAssignedToActiveDoctor(question, user)) {
        return true;
      }
      final hasWaitedLongEnough = DateTime.now()
              .difference(_latestConversationMoment(question))
              .inHours >=
          24;
      return _latestThreadMessageNeedsDoctor(question) && hasWaitedLongEnough;
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
      return user.isAdmin || _isAssignedToActiveDoctor(question, user);
    }
    return false;
  }

  bool _canModerateThreadMessage(
      ForumQuestion question, ThreadMessage message) {
    final user = _activeUser;
    if (user == null) {
      return false;
    }
    return user.isAdmin || user.isDoctor || user.canModerateContent;
  }

  bool _canDeleteDoctorResponses(ForumQuestion question) {
    final user = _activeUser;
    return user?.isAdmin == true ||
        user?.isDoctor == true ||
        user?.canModerateContent == true;
  }

  bool _isAssignedToActiveDoctor(ForumQuestion question, UserProfile user) {
    return question.targetDoctorId == user.id ||
        _normalizeEmail(question.targetDoctorEmail) ==
            _normalizeEmail(user.email);
  }

  bool _isAuthoredByActiveUser(ForumQuestion question, UserProfile user) {
    return question.authorId == user.id ||
        _normalizeEmail(question.authorEmail) == _normalizeEmail(user.email);
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
      ...question.threadMessages
          .map((message) => _tryParseDate(message.createdAt)),
      ...question.responses
          .map((response) => _tryParseDate(response.createdAt)),
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
    final hex =
        '#${selected.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
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
    final disclaimer = _currentDisclaimerDocument;
    if (kIsWeb) {
      await Clipboard.setData(
        ClipboardData(
          text:
              '${disclaimer.title}\n\n${disclaimer.body}\n\n$_currentRegionNote',
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _voiceStatus = 'Disclaimer copied to clipboard.';
      });
      return;
    }
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}${Platform.pathSeparator}medicohub-disclaimer-${DateTime.now().millisecondsSinceEpoch}.txt',
    );
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
    final nextTopics =
        _availableQuestionTopics.where((item) => item != topic).toList();
    await _saveAppSettings(
      questionTopics: nextTopics.isEmpty
          ? List<String>.from(_questionCategories)
          : nextTopics,
    );
  }

  List<AdCampaign> _matchingCampaignsForText({
    required String placement,
    required String primaryText,
    String secondaryText = '',
    String category = '',
    String language = '',
  }) {
    final baseText = '$primaryText $secondaryText $category $language';
    final haystack = '$baseText ${_adContextAliases(baseText)}'.toLowerCase();
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
          !campaign.languages
              .any((item) => item.toLowerCase() == languageLower)) {
        return false;
      }
      if (campaign.categories.isNotEmpty &&
          !campaign.categories
              .any((item) => item.toLowerCase() == categoryLower)) {
        return false;
      }
      if (campaign.keywords.isEmpty) {
        return true;
      }
      return campaign.keywords
          .any((keyword) => haystack.contains(keyword.toLowerCase()));
    }).toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    return campaigns;
  }

  String _adContextAliases(String text) {
    final lower = text.toLowerCase();
    final aliases = <String>[];
    if (RegExp(r'\bms\b').hasMatch(lower) ||
        lower.contains('multiple sclerosis')) {
      aliases.add('multiple sclerosis ms demyelination');
    }
    if (lower.contains('migraine') || lower.contains('headache')) {
      aliases.add('migraine headache');
    }
    if (lower.contains('stroke') || lower.contains('tia')) {
      aliases.add('stroke tia rehabilitation');
    }
    if (lower.contains('parkinson')) {
      aliases.add('parkinson parkinsons movement disorder');
    }
    if (lower.contains('vertigo') ||
        lower.contains('vestibular') ||
        lower.contains('dizziness')) {
      aliases.add('vertigo vestibular dizziness balance');
    }
    if (lower.contains('seizure') ||
        lower.contains('epilepsy') ||
        lower.contains('fits')) {
      aliases.add('epilepsy seizure fits');
    }
    if (lower.contains('diabetes') || lower.contains('sugar')) {
      aliases.add('diabetes sugar');
    }
    if (RegExp(r'\bbp\b').hasMatch(lower) ||
        lower.contains('blood pressure') ||
        lower.contains('hypertension')) {
      aliases.add('hypertension blood pressure bp');
    }
    return aliases.join(' ');
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
                        decoration:
                            const InputDecoration(labelText: 'Key points'),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: meaningController,
                        maxLines: 3,
                        decoration:
                            const InputDecoration(labelText: 'What it means'),
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
                        decoration: const InputDecoration(
                            labelText: 'Full educational reply'),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
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
                              whatToDiscussWithDoctor:
                                  discussController.text.trim(),
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
                                  aiSummary:
                                      'Question about ${item.title}. Latest reply highlights: ${response.keyPoints}',
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
                              _voiceStatus =
                                  'Doctor response posted successfully.';
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
                              _voiceStatus =
                                  'Could not post doctor response: $error';
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
                    helperText:
                        'This will be added to the question thread and may reopen it for doctor attention.',
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
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
                                  threadMessages: [
                                    ...item.threadMessages,
                                    message
                                  ],
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
                              _voiceStatus =
                                  'Could not add thread message: $error';
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
        _articleSectionEditors.every(
          (section) => section.plainText.trim().isEmpty,
        )) {
      final message =
          'Article title and at least one non-empty section are required before publishing.';
      setState(() {
        _articlePublishError = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }
    setState(() {
      _adminBusy = true;
      _errorMessage = null;
      _articlePublishError = null;
    });
    try {
      final wasEditing = _editingArticleId != null;
      final youtubeInput = _articleYoutubeUrlController.text.trim();
      final youtubeVideoId = _extractYouTubeVideoId(youtubeInput);
      if (youtubeInput.isNotEmpty && youtubeVideoId.isEmpty) {
        throw Exception('Enter a valid YouTube video URL.');
      }
      final youtubeUrl = youtubeVideoId.isEmpty
          ? ''
          : youtubeInput.contains('://') || youtubeInput.contains('youtu')
              ? youtubeInput
              : _normalizedYouTubeUrl(youtubeVideoId);
      final sections = _articleSectionsForSave();
      final sectionOrder = sections.keys.toList();
      final summaryText = sections['summary']?.plainText ??
          (sections.isNotEmpty ? sections.values.first.plainText : '');
      final bodyText = sections.values
          .map((section) => section.richTextHtml)
          .where((text) => text.trim().isNotEmpty)
          .join('\n\n');
      final article = !wasEditing
          ? await _api.createBlogArticle(
              authorId: user.id,
              title: _articleTitleController.text.trim(),
              summary: summaryText,
              body: bodyText,
              category: _articleCategory,
              language: _selectedLanguage,
              sourceUrl: _articleSourceUrlController.text.trim(),
              imageUrl: _articleImageUrlController.text.trim(),
              youtubeUrl: youtubeUrl,
              youtubeVideoId: youtubeVideoId,
              sectionOrder: sectionOrder,
              sections: sections,
            )
          : await _api.updateBlogArticle(
              articleId: _editingArticleId!,
              actorId: user.id,
              title: _articleTitleController.text.trim(),
              summary: summaryText,
              body: bodyText,
              category: _articleCategory,
              language: _selectedLanguage,
              sourceUrl: _articleSourceUrlController.text.trim(),
              imageUrl: _articleImageUrlController.text.trim(),
              youtubeUrl: youtubeUrl,
              youtubeVideoId: youtubeVideoId,
              sectionOrder: sectionOrder,
              sections: sections,
            );
      if (!mounted) {
        return;
      }
      setState(() {
        _blogArticles = [
          article,
          ..._blogArticles.where((item) => item.id != article.id),
        ];
        _adminBusy = false;
        _clearArticleEditor();
        _voiceStatus = !wasEditing
            ? 'Article published to the Education tab.'
            : 'Article updated in the Education tab.';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(!wasEditing
              ? 'Article published to the Education tab.'
              : 'Article updated in the Education tab.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      final message = _friendlyArticlePublishError(error);
      setState(() {
        _adminBusy = false;
        _articlePublishError = message;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Widget _buildArticleSectionEditors(BuildContext context) {
    if (_articleSectionEditors.isEmpty) {
      _addArticleSection('summary');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Article sections',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'Add section',
              onSelected: (id) => setState(() => _addArticleSection(id)),
              itemBuilder: (context) => _articleSectionOptions.entries
                  .where((entry) => !_articleSectionEditors
                      .any((item) => item.id == entry.key))
                  .map(
                    (entry) => PopupMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    ),
                  )
                  .toList(),
              child: FilledButton.icon(
                onPressed: null,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Section'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        for (var index = 0; index < _articleSectionEditors.length; index++)
          _buildArticleSectionEditor(
              context, _articleSectionEditors[index], index),
      ],
    );
  }

  Widget _buildArticleSectionEditor(
    BuildContext context,
    _ArticleSectionEditorData section,
    int index,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final sectionItems = _sectionDropdownItemsFor(section);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue:
                        safeDropdownValue<String>(section.id, sectionItems),
                    decoration:
                        const InputDecoration(labelText: 'Section label'),
                    items: sectionItems,
                    onChanged: (value) {
                      if (value == null || value == section.id) {
                        return;
                      }
                      if (_articleSectionEditors
                          .any((item) => item.id == value)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('That section already exists.')),
                        );
                        return;
                      }
                      setState(() {
                        section.id = value;
                        section.label =
                            _articleSectionOptions[value] ?? section.label;
                      });
                    },
                  ),
                ),
                IconButton(
                  tooltip: index == 0 ? 'Already first' : 'Move up',
                  onPressed: index == 0
                      ? null
                      : () => setState(() {
                            final item = _articleSectionEditors.removeAt(index);
                            _articleSectionEditors.insert(index - 1, item);
                          }),
                  icon: const Icon(Icons.arrow_upward_rounded),
                ),
                IconButton(
                  tooltip: index == _articleSectionEditors.length - 1
                      ? 'Already last'
                      : 'Move down',
                  onPressed: index == _articleSectionEditors.length - 1
                      ? null
                      : () => setState(() {
                            final item = _articleSectionEditors.removeAt(index);
                            _articleSectionEditors.insert(index + 1, item);
                          }),
                  icon: const Icon(Icons.arrow_downward_rounded),
                ),
                IconButton(
                  tooltip: section.collapsed ? 'Expand' : 'Collapse',
                  onPressed: () =>
                      setState(() => section.collapsed = !section.collapsed),
                  icon: Icon(section.collapsed
                      ? Icons.expand_more_rounded
                      : Icons.expand_less_rounded),
                ),
                IconButton(
                  tooltip: 'Delete section',
                  onPressed: () => _confirmDeleteArticleSection(section),
                  icon: Icon(Icons.delete_outline_rounded,
                      color: colorScheme.error),
                ),
              ],
            ),
            if (!section.collapsed) ...[
              const SizedBox(height: 8),
              TextField(
                controller: section.titleController,
                decoration: const InputDecoration(
                  labelText: 'Custom section title (optional)',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Section content',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    QuillSimpleToolbar(
                      controller: section.quillController,
                      config: const QuillSimpleToolbarConfig(
                        multiRowsDisplay: true,
                        showFontFamily: false,
                        showFontSize: false,
                        showInlineCode: false,
                        showCodeBlock: false,
                        showSearchButton: false,
                        showAlignmentButtons: true,
                        showDirection: false,
                      ),
                    ),
                    Divider(height: 1, color: colorScheme.outlineVariant),
                    SizedBox(
                      height: 260,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: QuillEditor(
                          controller: section.quillController,
                          focusNode: section.focusNode,
                          scrollController: section.scrollController,
                          config: const QuillEditorConfig(
                            placeholder:
                                'Write this section. Empty sections are not shown to readers.',
                            expands: false,
                            padding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _sectionDropdownItemsFor(
      _ArticleSectionEditorData section) {
    final entries = <String, String>{
      ..._articleSectionOptions,
      if (!_articleSectionOptions.containsKey(section.id))
        section.id:
            section.label.trim().isNotEmpty ? section.label : 'Custom section',
    };
    final seen = <String>{};
    return entries.entries.where((entry) => seen.add(entry.key)).map((entry) {
      return DropdownMenuItem<String>(
        value: entry.key,
        child: Text(entry.value),
      );
    }).toList();
  }

  void _addArticleSection(String id) {
    final canonicalId = _canonicalArticleSectionId(id);
    if (_articleSectionEditors.any((section) => section.id == canonicalId)) {
      return;
    }
    _articleSectionEditors.add(
      _ArticleSectionEditorData(
        id: canonicalId,
        label: _articleSectionOptions[canonicalId] ?? 'Custom Section',
      ),
    );
  }

  Future<void> _confirmDeleteArticleSection(
      _ArticleSectionEditorData section) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete section?'),
        content: Text('Remove "${section.label}" from this article?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      setState(() {
        _articleSectionEditors.remove(section);
        section.dispose();
      });
    }
  }

  Map<String, BlogArticleSection> _articleSectionsForSave() {
    final sections = <String, BlogArticleSection>{};
    for (var index = 0; index < _articleSectionEditors.length; index++) {
      final editor = _articleSectionEditors[index];
      final plainText = editor.plainText.trim();
      if (plainText.isEmpty) {
        continue;
      }
      final html = editor.toHtml().trim();
      sections[editor.id] = BlogArticleSection(
        id: editor.id,
        label: editor.label,
        customTitle: editor.titleController.text.trim(),
        order: sections.length + 1,
        richTextHtml: html,
        plainText: plainText,
        quillDeltaJson: editor.deltaJson,
        createdAt: '',
        updatedAt: '',
      );
    }
    return sections;
  }

  String _friendlyArticlePublishError(Object error) {
    final raw = error.toString().replaceFirst('Exception: ', '').trim();
    final lower = raw.toLowerCase();
    if (lower.contains('youtube')) {
      return 'Please check the YouTube URL. Paste a normal YouTube watch link, shorts link, youtu.be link, embed link, or an 11-character video ID.';
    }
    if (lower.contains('403') ||
        lower.contains('doctor') ||
        lower.contains('admin') ||
        lower.contains('not allowed') ||
        lower.contains('forbidden')) {
      return 'This account is not allowed to publish articles. Please sign in as a doctor or admin account and try again.';
    }
    if (lower.contains('socket') ||
        lower.contains('connection') ||
        lower.contains('clientfailed') ||
        lower.contains('failed to fetch') ||
        lower.contains('host') ||
        lower.contains('timeout')) {
      return 'MedicoHub could not reach the publishing service. Please check the backend connection and try again.';
    }
    if (raw.isEmpty) {
      return 'The article could not be published. Please review the fields and try again.';
    }
    return 'The article could not be published: $raw';
  }

  void _startEditArticle(BlogArticle article) {
    setState(() {
      _editingArticleId = article.id;
      _articleTitleController.text = article.title;
      _articleSummaryController.text = article.summary;
      _articleBodyController.text = article.body;
      _articleCategory = article.category;
      _articleSourceUrlController.text = article.sourceUrl;
      _articleImageUrlController.text = article.imageUrl;
      _articleYoutubeUrlController.text = article.youtubeUrl;
      for (final section in _articleSectionEditors) {
        section.dispose();
      }
      _articleSectionEditors
        ..clear()
        ..addAll(
          normalizeArticleForDisplay(article).map(
            (section) => _ArticleSectionEditorData.fromDisplaySection(section),
          ),
        );
      if (_articleSectionEditors.isEmpty) {
        _addArticleSection('summary');
      }
      _articlePublishError = null;
      _tabIndex = _maxTabIndex;
      _voiceStatus = 'Editing ${article.title}.';
    });
  }

  void _clearArticleEditor() {
    _editingArticleId = null;
    _articleTitleController.clear();
    _articleSummaryController.clear();
    _articleBodyController.clear();
    for (final section in _articleSectionEditors) {
      section.dispose();
    }
    _articleSectionEditors
      ..clear()
      ..add(_ArticleSectionEditorData(id: 'summary', label: 'Summary'));
    _articleSourceUrlController.clear();
    _articleImageUrlController.clear();
    _articleYoutubeUrlController.clear();
  }

  Future<void> _sendPasswordReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage =
            'Enter a valid email before requesting a password reset.';
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
        _errorMessage =
            'Could not request password reset: ${_firebaseFriendlyError(error)}';
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
                  child:
                      Text(dialogBusy ? 'Deleting...' : 'Delete Permanently'),
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

  Future<void> _openWhatsAppActivationFlow() async {
    final settings = _notificationSettings;
    if (settings == null) {
      setState(() {
        _errorMessage =
            'WhatsApp activation is still loading. Please try again in a moment.';
      });
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              24,
              8,
              24,
              24 + MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _isWhatsAppActivationCoolingDown
                            ? Colors.green.withValues(alpha: 0.14)
                            : Theme.of(context).colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.chat_rounded,
                        color: _isWhatsAppActivationCoolingDown
                            ? Colors.green
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'WhatsApp Notifications',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _isWhatsAppActivationCoolingDown
                      ? 'WhatsApp is marked active for today on this device.'
                      : 'Tap Open WhatsApp, send the prepared activation message, then return here to confirm it.',
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.call_outlined),
                  title: const Text('Send to'),
                  subtitle: Text(settings.whatsAppActivationTarget),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.message_outlined),
                  title: const Text('Message'),
                  subtitle: Text(settings.whatsAppActivationPhrase),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _isWhatsAppActivationCoolingDown
                            ? null
                            : () async {
                                Navigator.of(sheetContext).pop();
                                await _activateWhatsAppFor24Hours();
                              },
                        icon: const Icon(Icons.open_in_new_rounded),
                        label: Text(
                          _isWhatsAppActivationCoolingDown
                              ? 'Active Today'
                              : 'Open WhatsApp',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _activateWhatsAppFor24Hours() async {
    final settings = _notificationSettings;
    final prefs = _prefs;
    final key = _whatsAppActivationPreferenceKey;
    if (settings == null || prefs == null || key == null) {
      setState(() {
        _errorMessage =
            'WhatsApp activation is not ready yet. Please refresh the app.';
      });
      return;
    }
    if (!settings.whatsAppActivationEnabled) {
      setState(() {
        _errorMessage =
            'WhatsApp activation is currently disabled by the administrator.';
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

  Future<void> _updateMyEmailSubscription(bool subscribed) async {
    final user = _activeUser;
    if (user == null) {
      return;
    }
    try {
      final updated = await _api.updateCommunicationPreferences(
        userId: user.id,
        actorId: user.id,
        emailSubscribed: subscribed,
        communicationPreferences: user.communicationPreferences,
      );
      if (!mounted) {
        return;
      }
      setState(() => _activeUser = updated);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(subscribed
              ? 'Email notifications enabled.'
              : 'Email notifications disabled.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update email preference: $error')),
      );
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
                .map((existing) =>
                    existing.id == message.id ? moderated : existing)
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

  Future<void> _deleteDoctorResponses(
    ForumQuestion question,
    List<DoctorResponse> responses,
  ) async {
    final user = _activeUser;
    if (user == null || responses.isEmpty) {
      return;
    }
    try {
      await _api.deleteDoctorResponses(
        questionId: question.id,
        actorId: user.id,
        responseIds: responses.map((response) => response.id).toList(),
      );
      if (!mounted) {
        return;
      }
      final deletedIds = responses.map((response) => response.id).toSet();
      setState(() {
        _questions = _questions.map((item) {
          if (item.id != question.id) {
            return item;
          }
          final remainingResponses = item.responses
              .where((response) => !deletedIds.contains(response.id))
              .toList();
          return ForumQuestion(
            id: item.id,
            title: item.title,
            body: item.body,
            type: item.type,
            headingGroup: item.headingGroup,
            language: item.language,
            tags: item.tags,
            premium: item.premium,
            status: remainingResponses.isEmpty && item.status == 'answered'
                ? 'open'
                : item.status,
            aiSummary: item.aiSummary,
            responseCount: remainingResponses.length,
            authorId: item.authorId,
            targetDoctorId: item.targetDoctorId,
            responses: remainingResponses,
            threadMessages: item.threadMessages,
            createdAt: item.createdAt,
            updatedAt: DateTime.now().toIso8601String(),
            authorName: item.authorName,
            targetDoctorName: item.targetDoctorName,
            authorEmail: item.authorEmail,
            targetDoctorEmail: item.targetDoctorEmail,
            symptomsSummary: item.symptomsSummary,
            isPublic: item.isPublic,
          );
        }).toList();
        _voiceStatus = responses.length == 1
            ? 'Doctor response deleted.'
            : '${responses.length} doctor responses deleted.';
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = 'Could not delete doctor response: $error';
      });
    }
  }

  String _normalizeEmail(String? value) => (value ?? '').trim().toLowerCase();

  String _normalizePhone(String? value) => (value ?? '').trim();

  String _deriveQuestionTitle(String body) {
    final normalized = body.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.isEmpty) {
      return 'Question for doctor';
    }
    final words = normalized.split(' ');
    final title = words.take(10).join(' ');
    if (title.length <= 84 && words.length <= 10) {
      return title;
    }
    final shortened = title.length > 84 ? title.substring(0, 84).trim() : title;
    return '$shortened...';
  }

  String _effectiveQuestionCategory() {
    final category = _selectedQuestionCategory.trim();
    return category.isEmpty ? 'General' : category;
  }

  String _effectiveQuestionLanguage() {
    final language = _selectedLanguage.trim();
    return language.isEmpty ? 'English' : language;
  }

  String _effectiveQuestionSpecialty(String category) {
    final specialty = _selectedSpecialty.trim();
    if (specialty.isNotEmpty) {
      return specialty;
    }
    return category == 'General' ? 'General Health' : category;
  }

  void _showAskFormIssue(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _voiceStatus = message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _submitQuestion() async {
    final user = _activeUser;
    final doctorId = _selectedDoctorId;
    if (user == null) {
      _showAskFormIssue('Please sign in before submitting a question.');
      return;
    }
    if (doctorId == null || doctorId.isEmpty) {
      _showAskFormIssue('Please choose the doctor you want to address.');
      return;
    }
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      _showAskFormIssue(
        'Please enter the question details before submitting.',
      );
      return;
    }
    final headingGroup = _effectiveQuestionCategory();
    final language = _effectiveQuestionLanguage();
    final specialty = _effectiveQuestionSpecialty(headingGroup);
    final title = _titleController.text.trim().isEmpty
        ? _deriveQuestionTitle(body)
        : _titleController.text.trim();

    setState(() {
      _submitting = true;
      _voiceStatus = null;
    });

    try {
      final tags = <String>{
        specialty,
        language,
        headingGroup,
        if (_premium) 'Second opinion' else 'Forum',
      }.where((item) => item.trim().isNotEmpty).toList();

      if (_editingQuestionId == null) {
        final created = await _api.submitQuestion(
          authorId: user.id,
          targetDoctorId: doctorId,
          headingGroup: headingGroup,
          title: title,
          body: body,
          symptomsSummary: _symptomsController.text.trim(),
          premium: _premium,
          isPublic: false,
          language: language,
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
          title: title,
          body: body,
          headingGroup: headingGroup,
          language: language,
          symptomsSummary: _symptomsController.text.trim(),
          attachmentIds: _uploadedAttachments.map((item) => item.id).toList(),
        );
        if (!mounted) {
          return;
        }
        setState(() {
          _questions = _questions
              .map((question) => question.id == updated.id ? updated : question)
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
      final message =
          'Submit failed. Please check the required fields and try again.';
      setState(() {
        _submitting = false;
        _voiceStatus = '$message Details: $error';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
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
        _voiceStatus = _isAndroid
            ? 'Use the keyboard microphone in Gboard or your preferred Indic keyboard for $_selectedLanguage.'
            : _isIOS || _isMacOS
                ? 'Use Apple Dictation from the iPhone, iPad, or Mac keyboard microphone to enter speech directly into this field.'
                : 'Use your system dictation keyboard or audio note mode.';
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
        selection:
            TextSelection.collapsed(offset: result.partialTranscript!.length),
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
        '${_isIOS || _isMacOS ? 'On Apple devices, use the built-in keyboard microphone / Dictation key.' : _isAndroid ? 'On Android, Gboard or Indic Keyboard microphone is recommended.' : 'On web, use your browser or keyboard dictation tools.'}';
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
    if (kIsWeb) {
      setState(() {
        _voiceStatus = 'Audio note upload is not available in the web build.';
      });
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
        _uploadedAttachments = _uploadedAttachments
            .where((item) => item.id != attachment.id)
            .toList();
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
    if (error is FirebaseAuthDiagnosticException) {
      final details = error.details.toUpperCase();
      if (details.contains('INVALID_LOGIN_CREDENTIALS') ||
          details.contains('INVALID_PASSWORD') ||
          details.contains('EMAIL_NOT_FOUND')) {
        return 'Email or password is not correct for this account. Please re-enter the password or use Reset Password.';
      }
      if (details.contains('USER_DISABLED')) {
        return 'This Firebase account is disabled. Please contact support.';
      }
      if (error.operation == 'signInWithEmailRestFallback') {
        return 'Email sign-in could not be completed. Please try again or use Reset Password.';
      }
      return error.summary;
    }
    final text = error.toString();
    if (text.contains('Firebase auth error: unknown-error') ||
        text.contains('firebase_auth/unknown-error')) {
      return 'Email sign-in could not be completed by the Windows Firebase layer. Please try again, or use mobile/email password sign-in on Android or iOS. The technical details are saved in the console for debugging.';
    }
    return text;
  }

  String _signInFriendlyError(Object error) {
    final message = _firebaseFriendlyError(error);
    if (message.contains('Backend is temporarily unavailable') ||
        message.contains('SocketException') ||
        message.contains('Connection refused') ||
        message.contains('Failed host lookup')) {
      return 'MedicoHub profile sign-in failed: $message';
    }
    return 'Firebase sign-in failed: $message';
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
    ...question.threadMessages
        .map((message) => _safeQuestionDate(message.createdAt)),
    ...question.responses
        .map((response) => _safeQuestionDate(response.createdAt)),
  ]..sort();
  return timestamps.isEmpty
      ? DateTime.fromMillisecondsSinceEpoch(0)
      : timestamps.last;
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
    this.onShare,
    this.onShareResponse,
    this.canModerateMessage,
    this.onModerateMessage,
    this.canDeleteResponses = false,
    this.onDeleteResponses,
  });

  final ForumQuestion question;
  final String followUpLabel;
  final VoidCallback? onEdit;
  final VoidCallback? onTogglePublic;
  final VoidCallback? onDelete;
  final VoidCallback? onRespond;
  final VoidCallback? onAddFollowUp;
  final VoidCallback? onShare;
  final ValueChanged<DoctorResponse>? onShareResponse;
  final bool Function(ThreadMessage message)? canModerateMessage;
  final void Function(ThreadMessage message, String moderationState)?
      onModerateMessage;
  final bool canDeleteResponses;
  final ValueChanged<List<DoctorResponse>>? onDeleteResponses;

  @override
  Widget build(BuildContext context) {
    final visibleThreadMessages = question.threadMessages
        .where((message) =>
            message.moderationState != 'hidden' ||
            canModerateMessage?.call(message) == true)
        .toList();
    final hiddenMessageCount = question.threadMessages
        .where((message) => message.moderationState == 'hidden')
        .length;
    final latestMoment = _questionLatestMoment(question);
    final previewText = _compactQuestionPreview(question);
    final actionButtons = _buildActionButtons();
    return Card(
      child: ExpansionTile(
        tilePadding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
        childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Text(question.title,
            style: Theme.of(context).textTheme.titleMedium),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(_questionStateLabel(question))),
                  Chip(label: Text(question.isPublic ? 'Public' : 'Private')),
                  Chip(
                    label: Text(
                      'Updated ${_formatQuestionTimestamp(latestMoment.toIso8601String())}',
                    ),
                  ),
                  if (hiddenMessageCount > 0)
                    Chip(label: Text('$hiddenMessageCount hidden')),
                  if (question.premium) const Chip(label: Text('Paid')),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                previewText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'From ${question.authorName ?? 'Unknown user'} to ${question.targetDoctorName ?? 'Unknown doctor'}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        children: [
          TranslatedTextBlock(
            text: question.body,
            title: 'Read question in',
          ),
          const SizedBox(height: 12),
          Text(
            '${question.headingGroup} • ${question.language} • ${question.isPublic ? 'Public thread' : 'Private thread'}',
          ),
          if (question.tags.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  question.tags.map((tag) => Chip(label: Text(tag))).toList(),
            ),
          ],
          if (question.aiSummary.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            TranslatedTextBlock(
              text: question.aiSummary,
              title: 'Read summary in',
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ],
          if (visibleThreadMessages.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text('Conversation',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...visibleThreadMessages.map((message) => _ThreadMessageTile(
                  message: message,
                  canModerate: canModerateMessage?.call(message) == true,
                  onModerate: onModerateMessage == null
                      ? null
                      : (state) => onModerateMessage!(message, state),
                )),
          ],
          if (question.responses.isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Doctor Responses',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (canDeleteResponses &&
                    onDeleteResponses != null &&
                    question.responses.length > 1)
                  TextButton.icon(
                    onPressed: () => onDeleteResponses!(question.responses),
                    icon: const Icon(Icons.delete_sweep_outlined),
                    label: const Text('Delete all'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            ...question.responses.map(
              (response) => _DoctorResponseTile(
                response: response,
                onDelete: canDeleteResponses && onDeleteResponses != null
                    ? () => onDeleteResponses!([response])
                    : null,
                onShare: onShareResponse == null
                    ? null
                    : () => onShareResponse!(response),
              ),
            ),
          ],
          if (actionButtons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: actionButtons),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons() {
    return [
      if (onRespond != null)
        FilledButton(onPressed: onRespond, child: const Text('Respond')),
      if (onAddFollowUp != null)
        OutlinedButton(onPressed: onAddFollowUp, child: Text(followUpLabel)),
      if (onShare != null)
        OutlinedButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.share_outlined),
          label: const Text('Share'),
        ),
      if (onEdit != null)
        OutlinedButton(onPressed: onEdit, child: const Text('Edit')),
      if (onTogglePublic != null)
        OutlinedButton(
          onPressed: onTogglePublic,
          child: Text(question.isPublic ? 'Make Private' : 'Make Public'),
        ),
      if (onDelete != null)
        TextButton(onPressed: onDelete, child: const Text('Delete')),
    ];
  }
}

class _QuestionEmptyState extends StatelessWidget {
  const _QuestionEmptyState({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.forum_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(message),
        ],
      ),
    );
  }
}

String _compactQuestionPreview(ForumQuestion question) {
  final parts = <String>[
    question.body,
    if (question.threadMessages.isNotEmpty)
      question.threadMessages.last.moderationState == 'hidden'
          ? ''
          : question.threadMessages.last.body,
    if (question.responses.isNotEmpty) question.responses.last.fullText,
  ];
  return parts
      .map((part) => part.replaceAll(RegExp(r'\s+'), ' ').trim())
      .firstWhere((part) => part.isNotEmpty,
          orElse: () => 'Tap to open this thread.');
}

class _ThreadMessageTile extends StatelessWidget {
  const _ThreadMessageTile({
    required this.message,
    required this.canModerate,
    this.onModerate,
  });

  final ThreadMessage message;
  final bool canModerate;
  final ValueChanged<String>? onModerate;

  @override
  Widget build(BuildContext context) {
    return Container(
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
              if (canModerate && onModerate != null)
                PopupMenuButton<String>(
                  onSelected: onModerate,
                  itemBuilder: (context) => [
                    PopupMenuItem<String>(
                      value: message.moderationState == 'hidden'
                          ? 'visible'
                          : 'hidden',
                      child: Text(
                        message.moderationState == 'hidden'
                            ? 'Restore message'
                            : 'Delete message',
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
              Chip(
                  label: Text(
                      message.messageMode == 'voice' ? 'Voice note' : 'Text')),
              if (message.attachmentIds.isNotEmpty)
                Chip(
                  label: Text(
                    '${message.attachmentIds.length} attachment${message.attachmentIds.length == 1 ? '' : 's'}',
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          TranslatedTextBlock(
            text: message.moderationState == 'hidden'
                ? '[Message hidden by moderation]'
                : message.body,
            title: 'Read message in',
          ),
        ],
      ),
    );
  }
}

class _DoctorResponseTile extends StatelessWidget {
  const _DoctorResponseTile({
    required this.response,
    this.onDelete,
    this.onShare,
  });

  final DoctorResponse response;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Doctor response • ${response.responseMode}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (onDelete != null)
                IconButton(
                  tooltip: 'Delete response',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              if (onShare != null)
                IconButton(
                  tooltip: 'Share response',
                  onPressed: onShare,
                  icon: const Icon(Icons.share_outlined),
                ),
            ],
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
          TranslatedTextBlock(
            text: 'Key points: ${response.keyPoints}',
            title: 'Read response in',
          ),
          const SizedBox(height: 6),
          TranslatedTextBlock(
            text: 'What it means: ${response.whatItMeans}',
            title: 'Read response in',
          ),
          const SizedBox(height: 6),
          TranslatedTextBlock(
            text:
                'What to discuss with your doctor: ${response.whatToDiscussWithDoctor}',
            title: 'Read response in',
          ),
          const SizedBox(height: 6),
          TranslatedTextBlock(
            text: response.fullText,
            title: 'Read full reply in',
          ),
        ],
      ),
    );
  }
}

class AdminDataConsolePage extends StatefulWidget {
  const AdminDataConsolePage({
    super.key,
    required this.api,
    required this.admin,
    required this.initialQuestions,
    required this.initialDoctors,
    required this.initialArticles,
    required this.initialEducation,
    required this.initialSettings,
    required this.onOpenQuestions,
    required this.onOpenSettings,
    this.onOpenDoctorPublishing,
  });

  final AppApiService api;
  final UserProfile admin;
  final List<ForumQuestion> initialQuestions;
  final List<DoctorDirectoryEntry> initialDoctors;
  final List<BlogArticle> initialArticles;
  final List<EducationItem> initialEducation;
  final AppSettings? initialSettings;
  final VoidCallback onOpenQuestions;
  final VoidCallback onOpenSettings;
  final VoidCallback? onOpenDoctorPublishing;

  @override
  State<AdminDataConsolePage> createState() => _AdminDataConsolePageState();
}

class _AdminDataConsolePageState extends State<AdminDataConsolePage> {
  late List<ForumQuestion> _questions = List.of(widget.initialQuestions);
  late List<DoctorDirectoryEntry> _doctors = List.of(widget.initialDoctors);
  late List<BlogArticle> _articles = List.of(widget.initialArticles);
  late List<EducationItem> _education = List.of(widget.initialEducation);
  List<UserProfile> _users = const <UserProfile>[];
  late AppSettings? _settings = widget.initialSettings;
  Map<String, dynamic> _translationUsage = const <String, dynamic>{};
  String _userSearch = '';
  String _userRoleFilter = 'all';
  String _userSort = 'name';
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (_questions.isEmpty ||
        _doctors.isEmpty ||
        _articles.isEmpty ||
        _education.isEmpty ||
        _settings == null) {
      unawaited(_refresh());
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final questions = await widget.api.fetchQuestions();
      final doctors = await widget.api.fetchDoctors();
      final articles = await widget.api.fetchBlogArticles();
      final education = await widget.api.fetchEducation();
      final users = await widget.api.fetchUsers();
      final settings = await widget.api.fetchAppSettings();
      final translationUsage = await widget.api.fetchTranslationUsage();
      if (!mounted) {
        return;
      }
      setState(() {
        _questions = questions;
        _doctors = doctors;
        _articles = articles;
        _education = education;
        _users = users;
        _settings = settings;
        _translationUsage = translationUsage;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error =
            'Could not refresh admin data. Existing cached app data is still shown.';
      });
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _closeAndRun(VoidCallback callback) {
    Navigator.of(context).pop();
    callback();
  }

  List<UserProfile> _visibleUsers() {
    final query = _userSearch.trim().toLowerCase();
    final users = _users.where((user) {
      final roleMatches =
          _userRoleFilter == 'all' || user.role == _userRoleFilter;
      final textMatches = query.isEmpty ||
          user.displayName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          (user.phoneNumber ?? '').toLowerCase().contains(query);
      return roleMatches && textMatches;
    }).toList();
    users.sort((a, b) {
      switch (_userSort) {
        case 'email':
          return a.email.toLowerCase().compareTo(b.email.toLowerCase());
        case 'role':
          return a.role.compareTo(b.role);
        case 'verified':
          return b.verified.toString().compareTo(a.verified.toString());
        case 'created':
          return b.createdAt.compareTo(a.createdAt);
        case 'last_login':
          return b.lastLoginAt.compareTo(a.lastLoginAt);
        case 'name':
        default:
          return a.displayName.toLowerCase().compareTo(
                b.displayName.toLowerCase(),
              );
      }
    });
    return users;
  }

  @override
  Widget build(BuildContext context) {
    final openQuestions = _questions
        .where((question) => question.status.toLowerCase() == 'open')
        .length;
    final publicQuestions =
        _questions.where((question) => question.isPublic).length;
    final publishedArticles = _articles
        .where((article) => article.status.toLowerCase() == 'published')
        .length;
    final topics = _settings?.questionTopics.length ?? 0;
    final translationCalls =
        (_translationUsage['providerCalls'] ?? 0).toString();
    final translationCharacters =
        (_translationUsage['charactersTranslated'] ?? 0).toString();
    final visibleUsers = _visibleUsers();
    final latestQuestions = List<ForumQuestion>.of(_questions)
      ..sort((a, b) => _sortMoment(b).compareTo(_sortMoment(a)));
    final latestArticles = List<BlogArticle>.of(_articles)
      ..sort((a, b) => _sortTextMoment(b.updatedAt, b.createdAt)
          .compareTo(_sortTextMoment(a.updatedAt, a.createdAt)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Data Console'),
        actions: [
          IconButton(
            tooltip: 'Refresh live data',
            onPressed: _loading ? null : _refresh,
            icon: _loading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _AdminNoticeCard(
              title: 'Safe admin access',
              message:
                  'This console reads live app data through the existing backend and routes edits through audited screens. It does not expose raw Firestore document editing.',
              icon: Icons.admin_panel_settings_outlined,
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _AdminNoticeCard(
                title: 'Refresh notice',
                message: _error!,
                icon: Icons.info_outline_rounded,
                isWarning: true,
              ),
            ],
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _AdminMetricCard(
                  label: 'Users',
                  value: _users.length.toString(),
                  detail:
                      '${_users.where((user) => user.verified).length} verified',
                  icon: Icons.people_alt_outlined,
                ),
                _AdminMetricCard(
                  label: 'Questions',
                  value: _questions.length.toString(),
                  detail: '$openQuestions open • $publicQuestions public',
                  icon: Icons.forum_outlined,
                ),
                _AdminMetricCard(
                  label: 'Doctors',
                  value: _doctors.length.toString(),
                  detail: 'Directory entries',
                  icon: Icons.medical_services_outlined,
                ),
                _AdminMetricCard(
                  label: 'Articles',
                  value: _articles.length.toString(),
                  detail: '$publishedArticles published',
                  icon: Icons.article_outlined,
                ),
                _AdminMetricCard(
                  label: 'Education',
                  value: _education.length.toString(),
                  detail: 'Library items',
                  icon: Icons.auto_stories_outlined,
                ),
                _AdminMetricCard(
                  label: 'Topics',
                  value: topics.toString(),
                  detail: 'Ask Question filters',
                  icon: Icons.sell_outlined,
                ),
                _AdminMetricCard(
                  label: 'Azure Translation',
                  value: translationCalls,
                  detail: '$translationCharacters characters',
                  icon: Icons.translate_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _AdminTranslationUsageCard(usage: _translationUsage),
            const SizedBox(height: 16),
            _AdminUsersCard(
              users: visibleUsers,
              search: _userSearch,
              roleFilter: _userRoleFilter,
              sort: _userSort,
              onSearchChanged: (value) => setState(() => _userSearch = value),
              onRoleFilterChanged: (value) {
                if (value != null) {
                  setState(() => _userRoleFilter = value);
                }
              },
              onSortChanged: (value) {
                if (value != null) {
                  setState(() => _userSort = value);
                }
              },
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Safe edit shortcuts',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Use these for controlled changes. Raw database editing should stay in Firebase Console or purpose-built audited screens.',
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () => _closeAndRun(widget.onOpenQuestions),
                          icon: const Icon(Icons.rule_folder_outlined),
                          label: const Text('Question moderation'),
                        ),
                        if (widget.onOpenDoctorPublishing != null)
                          OutlinedButton.icon(
                            onPressed: () => _closeAndRun(
                              widget.onOpenDoctorPublishing!,
                            ),
                            icon: const Icon(Icons.edit_document),
                            label: const Text('Doctor publishing'),
                          ),
                        OutlinedButton.icon(
                          onPressed: () => _closeAndRun(widget.onOpenSettings),
                          icon: const Icon(Icons.settings_outlined),
                          label: const Text('Topics, ads & settings'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _AdminSectionCard(
              title: 'Latest Questions',
              emptyMessage: 'No questions were returned by the backend.',
              children: latestQuestions.take(6).map((question) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    question.status.toLowerCase() == 'open'
                        ? Icons.mark_chat_unread_outlined
                        : Icons.check_circle_outline_rounded,
                  ),
                  title: Text(question.title.isEmpty
                      ? 'Untitled question'
                      : question.title),
                  subtitle: Text(
                    [
                      question.headingGroup,
                      question.language,
                      question.isPublic ? 'Public' : 'Private',
                      'Updated ${_formatQuestionTimestamp(question.updatedAt.isEmpty ? question.createdAt : question.updatedAt)}',
                    ].join(' • '),
                  ),
                  trailing: Chip(label: Text(question.status)),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _AdminSectionCard(
              title: 'Doctor Directory',
              emptyMessage: 'No doctors were returned by the backend.',
              children: _doctors.take(6).map((doctor) {
                final specialty = doctor.specialties.isEmpty
                    ? 'General'
                    : doctor.specialties.join(', ');
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_search_outlined),
                  title: Text(doctor.displayName),
                  subtitle: Text('${doctor.email} • $specialty'),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            _AdminSectionCard(
              title: 'Published Content',
              emptyMessage: 'No articles were returned by the backend.',
              children: latestArticles.take(6).map((article) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.article_outlined),
                  title: Text(article.title),
                  subtitle: Text(
                    '${article.category} • ${article.language} • ${article.status}',
                  ),
                  trailing: Text(_formatQuestionTimestamp(
                    article.updatedAt.isEmpty
                        ? article.createdAt
                        : article.updatedAt,
                  )),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _sortMoment(ForumQuestion question) {
    return _sortTextMoment(question.updatedAt, question.createdAt);
  }

  DateTime _sortTextMoment(String primary, String fallback) {
    return DateTime.tryParse(primary) ??
        DateTime.tryParse(fallback) ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}

class _AdminMetricCard extends StatelessWidget {
  const _AdminMetricCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 12),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 4),
              Text(value, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(detail),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdminUsersCard extends StatelessWidget {
  const _AdminUsersCard({
    required this.users,
    required this.search,
    required this.roleFilter,
    required this.sort,
    required this.onSearchChanged,
    required this.onRoleFilterChanged,
    required this.onSortChanged,
  });

  final List<UserProfile> users;
  final String search;
  final String roleFilter;
  final String sort;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onRoleFilterChanged;
  final ValueChanged<String?> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final roleItems = const <DropdownMenuItem<String>>[
      DropdownMenuItem(value: 'all', child: Text('All roles')),
      DropdownMenuItem(value: 'patient', child: Text('Patients')),
      DropdownMenuItem(value: 'doctor', child: Text('Doctors')),
      DropdownMenuItem(value: 'admin', child: Text('Admins')),
    ];
    final sortItems = const <DropdownMenuItem<String>>[
      DropdownMenuItem(value: 'name', child: Text('Name')),
      DropdownMenuItem(value: 'email', child: Text('Email')),
      DropdownMenuItem(value: 'role', child: Text('Role')),
      DropdownMenuItem(value: 'verified', child: Text('Verified first')),
      DropdownMenuItem(value: 'created', child: Text('Created date')),
      DropdownMenuItem(value: 'last_login', child: Text('Last login')),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.people_alt_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Users',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 280,
                  child: TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      labelText: 'Search users',
                      hintText: 'Name, email, or phone',
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue:
                        safeDropdownValue<String>(roleFilter, roleItems),
                    decoration: const InputDecoration(labelText: 'Role'),
                    items: roleItems,
                    onChanged: onRoleFilterChanged,
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: DropdownButtonFormField<String>(
                    initialValue: safeDropdownValue<String>(sort, sortItems),
                    decoration: const InputDecoration(labelText: 'Sort by'),
                    items: sortItems,
                    onChanged: onSortChanged,
                  ),
                ),
                Chip(label: Text('${users.length} shown')),
              ],
            ),
            const SizedBox(height: 12),
            if (users.isEmpty)
              const Text('No users match the current filters.')
            else
              ...users.take(30).map((user) {
                final title = user.displayName.trim().isEmpty
                    ? user.email
                    : user.displayName;
                final languageText = user.languages.isEmpty
                    ? 'No language set'
                    : user.languages.join(', ');
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    child: Icon(
                      user.isAdmin
                          ? Icons.admin_panel_settings_outlined
                          : user.isDoctor
                              ? Icons.medical_services_outlined
                              : Icons.person_outline_rounded,
                    ),
                  ),
                  title: Text(title),
                  subtitle: Text(
                    [
                      user.email,
                      user.emailSubscribed ? 'Subscribed' : 'Unsubscribed',
                      if ((user.phoneNumber ?? '').isNotEmpty)
                        user.phoneNumber!,
                      if (user.createdAt.isNotEmpty)
                        'Created ${_formatQuestionTimestamp(user.createdAt)}',
                      if (user.lastLoginAt.isNotEmpty)
                        'Last login ${_formatQuestionTimestamp(user.lastLoginAt)}',
                      languageText,
                    ].join(' • '),
                  ),
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      Chip(label: Text(user.role)),
                      Chip(
                          label: Text(user.emailSubscribed
                              ? 'Subscribed'
                              : 'Opted out')),
                      if (user.verified) const Chip(label: Text('Verified')),
                    ],
                  ),
                );
              }),
            if (users.length > 30) ...[
              const SizedBox(height: 8),
              Text(
                'Showing first 30 matches. Use search or filters to narrow the list.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdminShareEmailDialog extends StatefulWidget {
  const _AdminShareEmailDialog({
    required this.api,
    required this.admin,
    required this.users,
    required this.contentType,
    required this.contentId,
    required this.title,
    required this.summary,
  });

  final AppApiService api;
  final UserProfile admin;
  final List<UserProfile> users;
  final String contentType;
  final String contentId;
  final String title;
  final String summary;

  @override
  State<_AdminShareEmailDialog> createState() => _AdminShareEmailDialogState();
}

class _AdminShareEmailDialogState extends State<_AdminShareEmailDialog> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  final Set<String> _selectedIds = <String>{};
  String _roleFilter = 'all';
  bool _verifiedOnly = false;
  bool _subscribedOnly = true;
  bool _sending = false;
  ContentShareReport? _report;
  String? _error;

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  List<UserProfile> get _filteredUsers {
    final query = _searchController.text.trim().toLowerCase();
    return widget.users.where((user) {
      if (_roleFilter != 'all' && user.role != _roleFilter) {
        return false;
      }
      if (_verifiedOnly && !user.verified) {
        return false;
      }
      if (_subscribedOnly && !user.emailSubscribed) {
        return false;
      }
      if (user.email.trim().isEmpty) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return user.displayName.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query);
    }).toList()
      ..sort((a, b) =>
          a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredUsers;
    return AlertDialog(
      title: Text('Email ${widget.contentType}'),
      content: SizedBox(
        width: 720,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                widget.summary.isEmpty
                    ? 'No summary is available.'
                    : widget.summary,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _messageController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Custom message',
                  hintText: 'Optional note from the MedicoHub team',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 230,
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        labelText: 'Search recipients',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  DropdownButton<String>(
                    value: _roleFilter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All users')),
                      DropdownMenuItem(
                          value: 'patient', child: Text('Patients')),
                      DropdownMenuItem(value: 'doctor', child: Text('Doctors')),
                      DropdownMenuItem(value: 'admin', child: Text('Admins')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _roleFilter = value);
                      }
                    },
                  ),
                  FilterChip(
                    label: const Text('Verified only'),
                    selected: _verifiedOnly,
                    onSelected: (value) =>
                        setState(() => _verifiedOnly = value),
                  ),
                  FilterChip(
                    label: const Text('Subscribed only'),
                    selected: _subscribedOnly,
                    onSelected: (value) =>
                        setState(() => _subscribedOnly = value),
                  ),
                  OutlinedButton(
                    onPressed: filtered.isEmpty
                        ? null
                        : () => setState(() {
                              _selectedIds
                                ..clear()
                                ..addAll(filtered.map((user) => user.id));
                            }),
                    child: const Text('Select filtered'),
                  ),
                  TextButton(
                    onPressed: _selectedIds.isEmpty
                        ? null
                        : () => setState(_selectedIds.clear),
                    child: const Text('Clear'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                  '${_selectedIds.length} selected • ${filtered.length} shown'),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 260),
                child: ListView(
                  shrinkWrap: true,
                  children: filtered.map((user) {
                    final selected = _selectedIds.contains(user.id);
                    return CheckboxListTile(
                      value: selected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedIds.add(user.id);
                          } else {
                            _selectedIds.remove(user.id);
                          }
                        });
                      },
                      title: Text(user.displayName.isEmpty
                          ? user.email
                          : user.displayName),
                      subtitle: Text(
                        '${user.email} • ${user.role} • ${user.emailSubscribed ? 'subscribed' : 'unsubscribed'}',
                      ),
                    );
                  }).toList(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!,
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
              ],
              if (_report != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(label: Text('Queued: ${_report!.queuedCount}')),
                    Chip(
                        label: Text(
                            'Skipped unsubscribed: ${_report!.skippedUnsubscribedCount}')),
                    Chip(
                        label: Text(
                            'Skipped preferences: ${_report!.skippedPreferenceCount}')),
                    Chip(label: Text('Failed: ${_report!.failedCount}')),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        FilledButton.icon(
          onPressed: _sending || _selectedIds.isEmpty ? null : _send,
          icon: _sending
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.email_outlined),
          label: Text(_sending ? 'Queueing...' : 'Send Email'),
        ),
      ],
    );
  }

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
      _report = null;
    });
    try {
      final report = await widget.api.shareContentByEmail(
        actorId: widget.admin.id,
        contentType: widget.contentType,
        contentId: widget.contentId,
        recipientIds: _selectedIds.toList(),
        customMessage: _messageController.text.trim(),
      );
      if (!mounted) {
        return;
      }
      setState(() => _report = report);
    } catch (error) {
      if (!mounted) {
        return;
      }
      final raw = error.toString();
      final lower = raw.toLowerCase();
      final message = lower.contains('timeout') ||
              lower.contains('future not completed')
          ? 'The campaign is taking longer than expected. It may still have been queued; check Campaign History before sending again.'
          : 'Could not queue campaign: $raw';
      setState(() => _error = message);
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }
}

class _AdminTranslationUsageCard extends StatelessWidget {
  const _AdminTranslationUsageCard({required this.usage});

  final Map<String, dynamic> usage;

  @override
  Widget build(BuildContext context) {
    final languagePairs =
        (usage['languagePairs'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{};
    final providers = (usage['providers'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final sections = (usage['sections'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Translation Usage',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              usage['note']?.toString() ??
                  'Provider calls are logged only when Azure creates a new translation.',
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _usageChip('Provider calls', usage['providerCalls']),
                _usageChip('Characters', usage['charactersTranslated']),
                for (final entry in providers.entries)
                  _usageChip('Provider ${entry.key}', entry.value),
                for (final entry in languagePairs.entries)
                  _usageChip(entry.key, entry.value),
                for (final entry in sections.entries.take(6))
                  _usageChip('Section ${entry.key}', entry.value),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _usageChip(String label, Object? value) {
    return Chip(label: Text('$label: ${value ?? 0}'));
  }
}

class _AdminNoticeCard extends StatelessWidget {
  const _AdminNoticeCard({
    required this.title,
    required this.message,
    required this.icon,
    this.isWarning = false,
  });

  final String title;
  final String message;
  final IconData icon;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWarning ? colors.errorContainer : colors.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: isWarning
                ? colors.onErrorContainer
                : colors.onSecondaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: isWarning
                            ? colors.onErrorContainer
                            : colors.onSecondaryContainer,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: TextStyle(
                    color: isWarning
                        ? colors.onErrorContainer
                        : colors.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminSectionCard extends StatelessWidget {
  const _AdminSectionCard({
    required this.title,
    required this.emptyMessage,
    required this.children,
  });

  final String title;
  final String emptyMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            if (children.isEmpty) Text(emptyMessage) else ...children,
          ],
        ),
      ),
    );
  }
}

class _ArticleYouTubePlayer extends StatefulWidget {
  const _ArticleYouTubePlayer({
    required this.videoId,
    required this.onOpenExternally,
  });

  final String videoId;
  final VoidCallback onOpenExternally;

  @override
  State<_ArticleYouTubePlayer> createState() => _ArticleYouTubePlayerState();
}

class _ArticleYouTubePlayerState extends State<_ArticleYouTubePlayer> {
  YoutubePlayerController? _controller;

  bool get _shouldUseInlinePlayer {
    return kIsWeb &&
        defaultTargetPlatform != TargetPlatform.iOS &&
        defaultTargetPlatform != TargetPlatform.android;
  }

  @override
  void initState() {
    super.initState();
    if (_shouldUseInlinePlayer) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: widget.videoId,
        autoPlay: false,
        params: const YoutubePlayerParams(
          showControls: true,
          showFullscreenButton: true,
          strictRelatedVideos: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    if (controller == null) {
      return _MobileYouTubeOpenCard(
        videoId: widget.videoId,
        onOpenExternally: widget.onOpenExternally,
      );
    }
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          YoutubePlayer(
            controller: controller,
            aspectRatio: 16 / 9,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.smart_display_rounded),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('YouTube video embedded in MedicoHub'),
                ),
                TextButton.icon(
                  onPressed: widget.onOpenExternally,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileYouTubeOpenCard extends StatelessWidget {
  const _MobileYouTubeOpenCard({
    required this.videoId,
    required this.onOpenExternally,
  });

  final String videoId;
  final VoidCallback onOpenExternally;

  @override
  Widget build(BuildContext context) {
    final thumbnailUrl = 'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.network(
                  thumbnailUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(
                    color: Color(0xFF111827),
                    child: Center(
                      child: Icon(
                        Icons.smart_display_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.05),
                        Colors.black.withValues(alpha: 0.42),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: FilledButton.icon(
                    onPressed: onOpenExternally,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Open on YouTube'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.smart_display_rounded),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text('Video opens in YouTube on this device'),
                ),
                TextButton.icon(
                  onPressed: onOpenExternally,
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Open'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DisplayArticleSection {
  const _DisplayArticleSection({
    required this.id,
    required this.label,
    required this.customTitle,
    required this.richTextHtml,
    required this.plainText,
    required this.updatedAt,
    required this.isLegacyFallback,
    this.quillDeltaJson = const <Map<String, dynamic>>[],
  });

  final String id;
  final String label;
  final String customTitle;
  final String richTextHtml;
  final String plainText;
  final String updatedAt;
  final bool isLegacyFallback;
  final List<Map<String, dynamic>> quillDeltaJson;

  String get title => customTitle.trim().isNotEmpty ? customTitle : label;
}

class _ArticleBulkTranslationPanel extends StatefulWidget {
  const _ArticleBulkTranslationPanel({
    required this.article,
    required this.sections,
  });

  final BlogArticle article;
  final List<_DisplayArticleSection> sections;

  @override
  State<_ArticleBulkTranslationPanel> createState() =>
      _ArticleBulkTranslationPanelState();
}

class _ArticleBulkTranslationPanelState
    extends State<_ArticleBulkTranslationPanel> {
  final TranslationService _service = TranslationService();
  final Map<String, SectionTranslationResult> _results =
      <String, SectionTranslationResult>{};
  final Set<String> _selected = <String>{};
  String _targetLanguage = 'ar';
  bool _loading = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _selected.addAll(widget.sections.map((section) => section.id));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sections.isEmpty) {
      return const SizedBox.shrink();
    }
    final languageItems =
        _languageDropdownItemsExcluding(widget.article.defaultLanguage);
    final successful = _results.values.where((result) => result.success).length;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Translate article',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<String>(
                  value:
                      safeDropdownValue<String>(_targetLanguage, languageItems),
                  hint: const Text('Language'),
                  items: languageItems,
                  onChanged: _loading
                      ? null
                      : (value) => setState(
                          () => _targetLanguage = value ?? _targetLanguage),
                ),
                FilledButton.icon(
                  onPressed: _loading ? null : () => _translate(_selected),
                  icon: _loading
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.translate_rounded),
                  label:
                      Text(_loading ? 'Translating...' : 'Translate selected'),
                ),
                OutlinedButton.icon(
                  onPressed: _loading
                      ? null
                      : () => _translate(
                            widget.sections
                                .map((section) => section.id)
                                .toSet(),
                          ),
                  icon: const Icon(Icons.done_all_rounded),
                  label: const Text('Translate all'),
                ),
                if (successful > 0)
                  OutlinedButton.icon(
                    onPressed: () => _export('html'),
                    icon: const Icon(Icons.html_rounded),
                    label: const Text('Export HTML'),
                  ),
                if (successful > 0)
                  OutlinedButton.icon(
                    onPressed: () => _export('txt'),
                    icon: const Icon(Icons.description_rounded),
                    label: const Text('Export TXT'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.sections.map((section) {
                return FilterChip(
                  label: Text(section.title),
                  selected: _selected.contains(section.id),
                  onSelected: _loading
                      ? null
                      : (selected) => setState(() {
                            if (selected) {
                              _selected.add(section.id);
                            } else {
                              _selected.remove(section.id);
                            }
                          }),
                );
              }).toList(),
            ),
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_status, style: Theme.of(context).textTheme.bodySmall),
            ],
            if (successful > 0) ...[
              const SizedBox(height: 8),
              Text(
                'Machine translation may contain errors. Please consult a doctor for medical decisions.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
              const SizedBox(height: 8),
              for (final section in widget.sections)
                if (_results[section.id]?.success == true) ...[
                  Text(section.title,
                      style: Theme.of(context).textTheme.titleSmall),
                  _linkedHtmlWidget(
                    _results[section.id]!.translatedRichTextHtml,
                  ),
                  const SizedBox(height: 8),
                ],
            ],
          ],
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>> _languageDropdownItemsExcluding(
      String sourceLanguageCode) {
    final seen = <String>{};
    return medicoHubLanguages
        .where((language) => language.code != sourceLanguageCode)
        .where((language) => seen.add(language.code))
        .map(
          (language) => DropdownMenuItem<String>(
            value: language.code,
            child: Text('${language.nativeLabel} (${language.label})'),
          ),
        )
        .toList();
  }

  Future<void> _translate(Set<String> sectionIds) async {
    if (_loading || sectionIds.isEmpty) {
      return;
    }
    setState(() {
      _loading = true;
      _status = 'Preparing translation...';
    });
    var completed = 0;
    for (final section
        in widget.sections.where((item) => sectionIds.contains(item.id))) {
      final result = await _service.translateSection(
        articleId: widget.article.id,
        sectionId: section.id,
        sourceLanguageCode: widget.article.defaultLanguage,
        targetLanguageCode: _targetLanguage,
        richTextHtml: section.richTextHtml,
        plainText: section.plainText,
        sourceUpdatedAt: section.updatedAt,
      );
      if (!mounted) {
        return;
      }
      completed += 1;
      setState(() {
        _results[section.id] = result;
        _status =
            'Translated $completed of ${sectionIds.length}. Last source: ${result.cacheSource}.';
      });
    }
    if (mounted) {
      setState(() {
        _loading = false;
        _status =
            'Translation ready. Saved sections can be reused on this device.';
      });
    }
  }

  Future<void> _export(String format) async {
    final successful = widget.sections
        .where((section) => _results[section.id]?.success == true)
        .toList();
    if (successful.isEmpty) {
      return;
    }
    final safeTitle = widget.article.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final date = DateTime.now().toIso8601String().split('T').first;
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}\\${safeTitle}_${_targetLanguage}_$date.$format',
    );
    final content = format == 'html'
        ? _combinedHtml(successful, date)
        : _combinedText(successful, date);
    await file.writeAsString(content);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${file.path}')),
      );
    }
  }

  String _combinedHtml(List<_DisplayArticleSection> sections, String date) {
    final buffer = StringBuffer()
      ..write(
          '<h1>${_ArticleSectionEditorData._escapeStaticHtml(widget.article.title)}</h1>')
      ..write('<p>Original language: ${widget.article.defaultLanguage}<br>')
      ..write(
          'Translation language: $_targetLanguage<br>Date saved: $date</p>');
    for (final section in sections) {
      buffer
        ..write(
            '<h2>${_ArticleSectionEditorData._escapeStaticHtml(section.title)}</h2>')
        ..write(_results[section.id]!.translatedRichTextHtml);
    }
    buffer.write(
      '<p><strong>This is machine-translated content and may contain errors.</strong></p>',
    );
    return buffer.toString();
  }

  String _combinedText(List<_DisplayArticleSection> sections, String date) {
    final buffer = StringBuffer()
      ..writeln(widget.article.title)
      ..writeln('Original language: ${widget.article.defaultLanguage}')
      ..writeln('Translation language: $_targetLanguage')
      ..writeln('Date saved: $date')
      ..writeln();
    for (final section in sections) {
      buffer
        ..writeln(section.title)
        ..writeln(_results[section.id]!.translatedPlainText)
        ..writeln();
    }
    buffer
        .writeln('This is machine-translated content and may contain errors.');
    return buffer.toString();
  }
}

class _ArticleSectionTranslationControls extends StatefulWidget {
  const _ArticleSectionTranslationControls({
    required this.article,
    required this.section,
  });

  final BlogArticle article;
  final _DisplayArticleSection section;

  @override
  State<_ArticleSectionTranslationControls> createState() =>
      _ArticleSectionTranslationControlsState();
}

class _ArticleSectionTranslationControlsState
    extends State<_ArticleSectionTranslationControls> {
  final TranslationService _service = TranslationService();
  String _targetLanguage = 'ar';
  bool _loading = false;
  SectionTranslationResult? _result;
  List<SectionTranslationResult> _saved = const <SectionTranslationResult>[];
  String _status = '';

  @override
  void initState() {
    super.initState();
    unawaited(_loadSaved());
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    final languageItems =
        _languageDropdownItemsExcluding(widget.article.defaultLanguage);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                DropdownButton<String>(
                  value:
                      safeDropdownValue<String>(_targetLanguage, languageItems),
                  hint: const Text('Language'),
                  items: languageItems,
                  onChanged: _loading
                      ? null
                      : (value) {
                          if (value != null) {
                            setState(() => _targetLanguage = value);
                          }
                        },
                ),
                FilledButton.icon(
                  onPressed: _loading ? null : _translate,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.translate_rounded),
                  label:
                      Text(_loading ? 'Translating...' : 'Translate section'),
                ),
                if (result != null && result.success)
                  OutlinedButton.icon(
                    onPressed: () => _export('html'),
                    icon: const Icon(Icons.html_rounded),
                    label: const Text('Export HTML'),
                  ),
                if (result != null && result.success)
                  OutlinedButton.icon(
                    onPressed: () => _export('txt'),
                    icon: const Icon(Icons.description_rounded),
                    label: const Text('Export TXT'),
                  ),
                if (_saved.isNotEmpty)
                  PopupMenuButton<SectionTranslationResult>(
                    tooltip: 'Load saved translation',
                    onSelected: (saved) {
                      setState(() {
                        _targetLanguage = saved.targetLanguageCode;
                        _result = saved;
                        _status = 'Using saved translation';
                      });
                    },
                    itemBuilder: (context) => _saved
                        .map(
                          (saved) => PopupMenuItem<SectionTranslationResult>(
                            value: saved,
                            child: Text('Saved ${saved.targetLanguageCode}'),
                          ),
                        )
                        .toList(),
                    child: OutlinedButton.icon(
                      onPressed: null,
                      icon: const Icon(Icons.download_done_rounded),
                      label: Text('Saved (${_saved.length})'),
                    ),
                  ),
                if (_saved.isNotEmpty)
                  IconButton(
                    tooltip: 'Clear saved translations for this section',
                    onPressed: _clearSaved,
                    icon: const Icon(Icons.delete_sweep_outlined),
                  ),
              ],
            ),
            if (_status.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_status, style: Theme.of(context).textTheme.bodySmall),
            ],
            if (result != null && result.success) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                      label: Text(
                          'Provider: ${result.provider == 'microsoft-azure' ? 'Microsoft Azure' : result.provider}')),
                  Chip(label: Text('Cache: ${result.cacheSource}')),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Machine translation may contain errors. Please consult a doctor for medical decisions.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
              ),
              const SizedBox(height: 8),
              _linkedHtmlWidget(result.translatedRichTextHtml),
            ],
            if (result != null && !result.success) ...[
              const SizedBox(height: 8),
              Text(
                result.message.isEmpty
                    ? 'Could not translate now. Please try again later.'
                    : result.message,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _translate() async {
    if (_loading) {
      return;
    }
    setState(() {
      _loading = true;
      _status = '';
    });
    final result = await _service.translateSection(
      articleId: widget.article.id,
      sectionId: widget.section.id,
      sourceLanguageCode: widget.article.defaultLanguage,
      targetLanguageCode: _targetLanguage,
      richTextHtml: widget.section.richTextHtml,
      plainText: widget.section.plainText,
      sourceUpdatedAt: widget.section.updatedAt,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      _result = result;
      _status = result.success
          ? result.cacheSource == 'local'
              ? 'Using saved translation'
              : result.cacheSource == 'server'
                  ? 'Using saved translation'
                  : 'New translation generated'
          : result.message.isNotEmpty
              ? result.message
              : 'Translation failed';
    });
    await _loadSaved();
  }

  Future<void> _loadSaved() async {
    final saved = await _service.savedSectionTranslations(
      articleId: widget.article.id,
      sectionId: widget.section.id,
    );
    if (mounted) {
      setState(() => _saved = saved);
    }
  }

  Future<void> _clearSaved() async {
    await _service.clearSavedSectionTranslations(
      articleId: widget.article.id,
      sectionId: widget.section.id,
    );
    if (mounted) {
      setState(() {
        _saved = const <SectionTranslationResult>[];
        _status = 'Saved translations cleared from this device.';
      });
    }
  }

  Future<void> _export(String format) async {
    final result = _result;
    if (result == null || !result.success) {
      return;
    }
    final safeTitle = widget.article.title
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final date = DateTime.now().toIso8601String().split('T').first;
    final directory = await getApplicationDocumentsDirectory();
    final file = File(
      '${directory.path}\\${safeTitle}_${result.targetLanguageCode}_$date.$format',
    );
    final escapedTitle =
        _ArticleSectionEditorData._escapeStaticHtml(widget.article.title);
    final escapedSection =
        _ArticleSectionEditorData._escapeStaticHtml(widget.section.title);
    final content = format == 'html'
        ? '<h1>$escapedTitle</h1><p>Original language: ${result.sourceLanguageCode}<br>Translation language: ${result.targetLanguageCode}<br>Date saved: $date</p><h2>$escapedSection</h2>${result.translatedRichTextHtml}<p><strong>This is machine-translated content and may contain errors.</strong></p>'
        : '${widget.article.title}\nOriginal language: ${result.sourceLanguageCode}\nTranslation language: ${result.targetLanguageCode}\nDate saved: $date\n\n${widget.section.title}\n${result.translatedPlainText}\n\nThis is machine-translated content and may contain errors.\n';
    await file.writeAsString(content);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${file.path}')),
      );
    }
  }
}

class _ArticleSectionEditorData {
  _ArticleSectionEditorData({
    required String id,
    required String label,
    String customTitle = '',
    String body = '',
    List<Map<String, dynamic>> quillDeltaJson = const <Map<String, dynamic>>[],
  })  : id = _canonicalStaticSectionId(id),
        label = label.trim().isNotEmpty
            ? label
            : _articleSectionOptions[_canonicalStaticSectionId(id)] ??
                'Custom Section',
        titleController = TextEditingController(text: customTitle),
        quillController = _quillControllerFromDeltaHtmlOrText(
          quillDeltaJson,
          body,
        ),
        focusNode = FocusNode(),
        scrollController = ScrollController(),
        collapsed = false;

  factory _ArticleSectionEditorData.fromDisplaySection(
      _DisplayArticleSection section) {
    return _ArticleSectionEditorData(
      id: section.id,
      label: section.label,
      customTitle: section.customTitle,
      body: section.richTextHtml.isNotEmpty
          ? section.richTextHtml
          : section.plainText,
      quillDeltaJson: section.quillDeltaJson,
    );
  }

  String id;
  String label;
  bool collapsed;
  final TextEditingController titleController;
  final QuillController quillController;
  final FocusNode focusNode;
  final ScrollController scrollController;

  String get plainText => quillController.document.toPlainText().trim();

  List<Map<String, dynamic>> get deltaJson => quillController.document
      .toDelta()
      .toJson()
      .map((item) => Map<String, dynamic>.from(item as Map))
      .toList();

  String toHtml() {
    final deltaJson = quillController.document.toDelta().toJson();
    final converter = QuillDeltaToHtmlConverter(
      List.castFrom<dynamic, Map<String, dynamic>>(deltaJson),
      ConverterOptions.forEmail(),
    );
    return converter.convert();
  }

  void dispose() {
    titleController.dispose();
    quillController.dispose();
    focusNode.dispose();
    scrollController.dispose();
  }

  static QuillController _quillControllerFromDeltaHtmlOrText(
    List<Map<String, dynamic>> deltaJson,
    String value,
  ) {
    if (deltaJson.isNotEmpty) {
      try {
        return QuillController(
          document: Document.fromJson(deltaJson),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } catch (_) {
        // Fall through to HTML/text compatibility path.
      }
    }
    try {
      final content = value.trim();
      if (content.isEmpty) {
        return QuillController.basic();
      }
      final looksLikeHtml = RegExp(r'<[a-zA-Z][\s\S]*>').hasMatch(content);
      final html = looksLikeHtml ? content : _markdownishToHtml(content);
      final delta = HtmlToDelta().convert(html, transformTableAsEmbed: false);
      return QuillController(
        document: Document.fromDelta(delta),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (_) {
      return QuillController(
        document: Document()..insert(0, value),
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
  }

  static String _canonicalStaticSectionId(String id) {
    final normalized = id
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (normalized.isEmpty) {
      return 'summary';
    }
    return _legacyArticleSectionIdAliases[normalized] ?? normalized;
  }

  static String _markdownishToHtml(String value) {
    final buffer = StringBuffer();
    for (final rawLine in value.replaceAll('\r\n', '\n').split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        continue;
      }
      final heading = RegExp(r'^(#{1,3})\s+(.+)$').firstMatch(line);
      if (heading != null) {
        final level = heading.group(1)!.length;
        buffer.write(
            '<h$level>${_escapeStaticHtml(heading.group(2)!)}</h$level>');
      } else if (line.startsWith('- ') || line.startsWith('* ')) {
        buffer
            .write('<ul><li>${_escapeStaticHtml(line.substring(2))}</li></ul>');
      } else if (RegExp(r'^\d+\.\s+').hasMatch(line)) {
        buffer.write(
            '<ol><li>${_escapeStaticHtml(line.replaceFirst(RegExp(r'^\d+\.\s+'), ''))}</li></ol>');
      } else {
        buffer.write('<p>${_escapeStaticHtml(line)}</p>');
      }
    }
    return buffer.toString();
  }

  static String _escapeStaticHtml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}

class GrowthStudioPage extends StatefulWidget {
  const GrowthStudioPage({
    super.key,
    required this.api,
    required this.admin,
    required this.articles,
  });

  final AppApiService api;
  final UserProfile admin;
  final List<BlogArticle> articles;

  @override
  State<GrowthStudioPage> createState() => _GrowthStudioPageState();
}

class _GrowthStudioPageState extends State<GrowthStudioPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _campaignNameController = TextEditingController();
  final _campaignHypothesisController = TextEditingController();
  final _campaignAudienceController = TextEditingController();
  final _campaignValueController = TextEditingController();
  final _campaignCtaController = TextEditingController();
  final _campaignMetricController =
      TextEditingController(text: 'activated_users');
  final _campaignChannelsController =
      TextEditingController(text: 'MedicoHub, email, WhatsApp');
  final _derivativeTitleController = TextEditingController();
  final _derivativeBodyController = TextEditingController();
  final _publishTitleController = TextEditingController();
  final _publishBodyController = TextEditingController();
  String _campaignObjective = 'activation';
  String _derivativeType = 'social_post';
  String _derivativePlatform = 'MedicoHub';
  String? _selectedArticleId;
  String? _selectedIntegrationId;
  GrowthOverview? _overview;
  List<GrowthCampaign> _campaigns = const [];
  List<GrowthOpportunity> _opportunities = const [];
  List<GrowthDerivative> _derivatives = const [];
  List<GrowthIntegrationCatalogItem> _integrationCatalog = const [];
  List<GrowthIntegration> _integrations = const [];
  List<GrowthPublishingRequest> _publishingRequests = const [];
  bool _canManageSocialAccounts = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    final publishedArticles =
        widget.articles.where((article) => article.status == 'published');
    _selectedArticleId =
        publishedArticles.isNotEmpty ? publishedArticles.first.id : null;
    _refresh();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _campaignNameController.dispose();
    _campaignHypothesisController.dispose();
    _campaignAudienceController.dispose();
    _campaignValueController.dispose();
    _campaignCtaController.dispose();
    _campaignMetricController.dispose();
    _campaignChannelsController.dispose();
    _derivativeTitleController.dispose();
    _derivativeBodyController.dispose();
    _publishTitleController.dispose();
    _publishBodyController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<dynamic>([
        widget.api.fetchGrowthOverview(actorId: widget.admin.id),
        widget.api.fetchGrowthCampaigns(actorId: widget.admin.id),
        widget.api.fetchGrowthOpportunities(actorId: widget.admin.id),
        widget.api.fetchGrowthDerivatives(actorId: widget.admin.id),
        widget.api.fetchGrowthIntegrationCatalog(actorId: widget.admin.id),
        widget.api.fetchGrowthIntegrations(actorId: widget.admin.id),
        widget.api.fetchGrowthPublishingRequests(actorId: widget.admin.id),
      ]);
      if (!mounted) return;
      setState(() {
        _overview = results[0] as GrowthOverview;
        _campaigns = results[1] as List<GrowthCampaign>;
        _opportunities = results[2] as List<GrowthOpportunity>;
        _derivatives = results[3] as List<GrowthDerivative>;
        _integrationCatalog = results[4] as List<GrowthIntegrationCatalogItem>;
        _integrations = results[5] as List<GrowthIntegration>;
        _publishingRequests = results[6] as List<GrowthPublishingRequest>;
        _canManageSocialAccounts = widget.admin.canManageSocialAccounts ||
            _integrationCatalog.any((item) => item.canManageSocialAccounts);
        _selectedIntegrationId ??= _integrations
            .where((item) => item.approvalStatus == 'approved')
            .map((item) => item.id)
            .cast<String?>()
            .firstOrNull;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _startOAuth(GrowthIntegration integration) async {
    if (!_canManageSocialAccounts || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await widget.api.startGrowthIntegrationOAuth(
        actorId: widget.admin.id,
        integrationId: integration.id,
      );
      final url = result['authorization_url']?.toString() ?? '';
      if (url.isNotEmpty) {
        await _launchExternalLink(url);
      }
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _connectCatalogItem(GrowthIntegrationCatalogItem item) async {
    if (!_canManageSocialAccounts || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      var integration = _integrations
          .where((candidate) => candidate.id == item.integrationId)
          .cast<GrowthIntegration?>()
          .firstOrNull;
      integration ??= await widget.api.createGrowthIntegration(
        actorId: widget.admin.id,
        provider: item.provider,
        displayName: item.label,
        authMode: item.authMode,
        scopes: item.scopes,
        notes: item.notes,
      );
      if (item.authMode == 'oauth2') {
        final result = await widget.api.startGrowthIntegrationOAuth(
          actorId: widget.admin.id,
          integrationId: integration.id,
        );
        final url = result['authorization_url']?.toString() ?? '';
        if (url.isNotEmpty) {
          await _launchExternalLink(url);
        }
      }
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _approveIntegration(
    GrowthIntegration integration,
    String status,
  ) async {
    if (!_canManageSocialAccounts || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.updateGrowthIntegrationApproval(
        actorId: widget.admin.id,
        integrationId: integration.id,
        approvalStatus: status,
      );
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _queuePublishingRequest() async {
    final integrationId = _selectedIntegrationId;
    final integration = _integrations
        .where((item) => item.id == integrationId)
        .cast<GrowthIntegration?>()
        .firstOrNull;
    if (!widget.admin.canManageGrowthStudio || integration == null || _saving) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.createGrowthPublishingRequest(
        actorId: widget.admin.id,
        integrationId: integration.id,
        provider: integration.provider,
        title: _publishTitleController.text.trim(),
        body: _publishBodyController.text.trim(),
      );
      _publishTitleController.clear();
      _publishBodyController.clear();
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updatePublishingRequest(
    GrowthPublishingRequest request,
    String status,
  ) async {
    if ((status == 'approved' || status == 'exported') &&
        !_canManageSocialAccounts) {
      return;
    }
    if (!widget.admin.canManageGrowthStudio || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.updateGrowthPublishingRequest(
        actorId: widget.admin.id,
        publishId: request.id,
        status: status,
      );
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied')),
    );
  }

  Future<void> _testIntegration(GrowthIntegration integration) async {
    if (!_canManageSocialAccounts || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await widget.api.testGrowthIntegration(
        actorId: widget.admin.id,
        integrationId: integration.id,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connection check: ${result['status'] ?? 'unknown'}',
          ),
        ),
      );
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _showDestinationDialog(GrowthIntegration integration) async {
    if (!_canManageSocialAccounts || _saving) return;
    final accountIdController =
        TextEditingController(text: integration.externalAccountId);
    final accountNameController =
        TextEditingController(text: integration.externalAccountName);
    final accountTypeController =
        TextEditingController(text: integration.externalAccountType);
    final pageIdController = TextEditingController(text: integration.pageId);
    final instagramIdController =
        TextEditingController(text: integration.instagramBusinessAccountId);
    final channelIdController =
        TextEditingController(text: integration.channelId);
    final notesController = TextEditingController(text: integration.notes);
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Select ${integration.displayName} destination'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: accountNameController,
                decoration:
                    const InputDecoration(labelText: 'Connected account name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: accountTypeController,
                decoration: const InputDecoration(labelText: 'Account type'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: accountIdController,
                decoration:
                    const InputDecoration(labelText: 'External account ID'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: pageIdController,
                decoration:
                    const InputDecoration(labelText: 'Facebook Page ID'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: instagramIdController,
                decoration: const InputDecoration(
                  labelText: 'Instagram Business Account ID',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: channelIdController,
                decoration:
                    const InputDecoration(labelText: 'YouTube Channel ID'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Notes'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (saved != true) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.updateGrowthIntegrationSelection(
        actorId: widget.admin.id,
        integrationId: integration.id,
        externalAccountId: accountIdController.text.trim(),
        externalAccountName: accountNameController.text.trim(),
        externalAccountType: accountTypeController.text.trim(),
        pageId: pageIdController.text.trim(),
        instagramBusinessAccountId: instagramIdController.text.trim(),
        channelId: channelIdController.text.trim(),
        notes: notesController.text.trim(),
      );
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _createCampaign() async {
    if (!widget.admin.canManageGrowthStudio || _saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.createGrowthCampaign(
        actorId: widget.admin.id,
        name: _campaignNameController.text.trim(),
        objective: _campaignObjective,
        hypothesis: _campaignHypothesisController.text.trim(),
        targetAudience: _campaignAudienceController.text.trim(),
        valueOffered: _campaignValueController.text.trim(),
        primaryCta: _campaignCtaController.text.trim(),
        primaryMetric: _campaignMetricController.text.trim(),
        channels: _campaignChannelsController.text
            .split(',')
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList(),
      );
      _campaignNameController.clear();
      _campaignHypothesisController.clear();
      _campaignAudienceController.clear();
      _campaignValueController.clear();
      _campaignCtaController.clear();
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _createDerivative() async {
    final articleId = _selectedArticleId;
    if (!widget.admin.canManageGrowthStudio || articleId == null || _saving) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.api.createGrowthDerivative(
        actorId: widget.admin.id,
        sourceArticleId: articleId,
        assetType: _derivativeType,
        platform: _derivativePlatform,
        title: _derivativeTitleController.text.trim(),
        body: _derivativeBodyController.text.trim(),
      );
      _derivativeTitleController.clear();
      _derivativeBodyController.clear();
      await _refresh();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.rocket_launch_rounded),
        title: const Text('MedicoHub Growth Studio'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.space_dashboard_rounded), text: 'Overview'),
            Tab(icon: Icon(Icons.campaign_rounded), text: 'Campaigns'),
            Tab(
                icon: Icon(Icons.travel_explore_rounded),
                text: 'Opportunities'),
            Tab(icon: Icon(Icons.ios_share_rounded), text: 'Promotion'),
            Tab(icon: Icon(Icons.hub_rounded), text: 'Integrations'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_error != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.error_outline_rounded),
                        title: const Text('Growth Studio could not refresh'),
                        subtitle: Text(_error!),
                      ),
                    ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height -
                        kToolbarHeight -
                        128,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverview(context),
                        _buildCampaigns(context),
                        _buildOpportunities(context),
                        _buildPromotion(context),
                        _buildIntegrations(context),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildOverview(BuildContext context) {
    final overview = _overview;
    if (overview == null) {
      return const Center(child: Text('No growth metrics available yet.'));
    }
    final metrics = <MapEntry<String, num>>[
      MapEntry('Registrations', overview.metrics['new_registrations'] ?? 0),
      MapEntry('Activated users', overview.metrics['activated_users'] ?? 0),
      MapEntry('Activation rate', overview.metrics['activation_rate'] ?? 0),
      MapEntry('DAU', overview.metrics['daily_active_users'] ?? 0),
      MapEntry('WAU', overview.metrics['weekly_active_users'] ?? 0),
      MapEntry('MAU', overview.metrics['monthly_active_users'] ?? 0),
      MapEntry('Questions', overview.metrics['questions_submitted'] ?? 0),
      MapEntry('Shares', overview.metrics['shares'] ?? 0),
      MapEntry('Referral activations',
          overview.metrics['referral_activations'] ?? 0),
    ];
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.rocket_launch_rounded,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: const Text('Growth Command Center'),
            subtitle: const Text(
              'Attract, convert, activate, retain, and learn from useful participation.',
            ),
          ),
          const SizedBox(height: 8),
          if (overview.smallSampleWarning)
            const ListTile(
              leading: Icon(Icons.info_outline_rounded),
              title: Text('Small sample size'),
              subtitle: Text(
                'Percentages are directional until more events are collected.',
              ),
            ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: metrics
                .map((metric) => SizedBox(
                      width: 180,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(metric.key,
                                  style:
                                      Theme.of(context).textTheme.labelLarge),
                              const SizedBox(height: 8),
                              Text(
                                metric.key == 'Activation rate'
                                    ? '${metric.value}%'
                                    : metric.value.toString(),
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
          _buildPairList('Top acquisition sources', overview.topSources),
          _buildPairList('Top content', overview.topContent),
          ListTile(
            leading: const Icon(Icons.dataset_rounded),
            title: const Text('Sample size'),
            subtitle: Text(overview.sampleSize.entries
                .map((entry) => '${entry.key}: ${entry.value}')
                .join(' | ')),
          ),
        ],
      ),
    );
  }

  Widget _buildPairList(String title, List<MapEntry<String, int>> entries) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const Divider(),
            if (entries.isEmpty)
              const Text('No events recorded yet.')
            else
              for (final entry in entries)
                ListTile(
                  dense: true,
                  title: Text(entry.key),
                  trailing: Text(entry.value.toString()),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildCampaigns(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Create Growth Campaign',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _campaignNameController,
                    decoration:
                        const InputDecoration(labelText: 'Campaign name'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _campaignObjective,
                    decoration: const InputDecoration(labelText: 'Objective'),
                    items: const [
                      DropdownMenuItem(
                          value: 'activation', child: Text('Activation')),
                      DropdownMenuItem(
                          value: 'registration', child: Text('Registration')),
                      DropdownMenuItem(
                          value: 'referral', child: Text('Referral')),
                      DropdownMenuItem(
                          value: 're_engagement', child: Text('Re-engagement')),
                      DropdownMenuItem(
                          value: 'article_engagement',
                          child: Text('Article engagement')),
                    ],
                    onChanged: (value) => setState(
                      () => _campaignObjective = value ?? 'activation',
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _campaignHypothesisController,
                    decoration: const InputDecoration(labelText: 'Hypothesis'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _campaignAudienceController,
                    decoration:
                        const InputDecoration(labelText: 'Target audience'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _campaignValueController,
                    decoration:
                        const InputDecoration(labelText: 'Value offered'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _campaignCtaController,
                    decoration: const InputDecoration(labelText: 'Primary CTA'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _campaignMetricController,
                    decoration:
                        const InputDecoration(labelText: 'Primary metric'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _campaignChannelsController,
                    decoration: const InputDecoration(labelText: 'Channels'),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: widget.admin.canManageGrowthStudio && !_saving
                        ? _createCampaign
                        : null,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Create campaign'),
                  ),
                ],
              ),
            ),
          ),
          for (final campaign in _campaigns)
            Card(
              child: ListTile(
                leading: const Icon(Icons.campaign_rounded),
                title: Text(campaign.name),
                subtitle: Text(
                  '${campaign.objective} | ${campaign.primaryMetric} | ${campaign.targetAudience}',
                ),
                trailing: Chip(label: Text(campaign.status)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOpportunities(BuildContext context) {
    return ListView(
      children: [
        for (final opportunity in _opportunities)
          Card(
            child: ListTile(
              leading: const Icon(Icons.travel_explore_rounded),
              title: Text(opportunity.title),
              subtitle: Text(
                '${opportunity.source} | ${opportunity.specialty} | ${opportunity.language}\nCTA: ${opportunity.recommendedCta}',
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(opportunity.estimatedValue.toString()),
                  Text(opportunity.urgency),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPromotion(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text('Create Article Derivative',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedArticleId,
                    decoration:
                        const InputDecoration(labelText: 'Source article'),
                    items: widget.articles
                        .where((article) => article.status == 'published')
                        .map(
                          (article) => DropdownMenuItem<String>(
                            value: article.id,
                            child: Text(
                              article.title,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedArticleId = value),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _derivativeType,
                    decoration: const InputDecoration(labelText: 'Asset type'),
                    items: const [
                      DropdownMenuItem(
                          value: 'social_post', child: Text('Social post')),
                      DropdownMenuItem(
                          value: 'instagram_carousel',
                          child: Text('Instagram carousel')),
                      DropdownMenuItem(
                          value: 'short_video_script',
                          child: Text('Short-video script')),
                      DropdownMenuItem(
                          value: 'linkedin_post', child: Text('LinkedIn post')),
                      DropdownMenuItem(
                          value: 'whatsapp_message',
                          child: Text('WhatsApp message')),
                      DropdownMenuItem(
                          value: 'email_digest_item',
                          child: Text('Email digest item')),
                    ],
                    onChanged: (value) => setState(
                        () => _derivativeType = value ?? 'social_post'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _derivativeTitleController,
                    decoration:
                        const InputDecoration(labelText: 'Derivative title'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _derivativeBodyController,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(labelText: 'Draft copy'),
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                          value: 'MedicoHub', label: Text('MedicoHub')),
                      ButtonSegment(value: 'LinkedIn', label: Text('LinkedIn')),
                      ButtonSegment(value: 'WhatsApp', label: Text('WhatsApp')),
                    ],
                    selected: {_derivativePlatform},
                    onSelectionChanged: (value) =>
                        setState(() => _derivativePlatform = value.first),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: widget.admin.canManageGrowthStudio && !_saving
                        ? _createDerivative
                        : null,
                    icon: const Icon(Icons.add_link_rounded),
                    label: const Text('Create derivative'),
                  ),
                ],
              ),
            ),
          ),
          for (final derivative in _derivatives)
            Card(
              child: ListTile(
                leading: const Icon(Icons.ios_share_rounded),
                title: Text(derivative.title),
                subtitle: Text(
                  '${derivative.assetType} | ${derivative.platform} | ${derivative.publicationStatus}'
                  '${derivative.outdatedReason.isEmpty ? '' : '\n${derivative.outdatedReason}'}',
                ),
                trailing: Chip(label: Text(derivative.approvalStatus)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildIntegrations(BuildContext context) {
    final approvedIntegrations = _integrations
        .where((item) => item.approvalStatus == 'approved')
        .toList();
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.admin_panel_settings_rounded),
              title: const Text('Official Social Accounts'),
              subtitle: const Text(
                'Phase 1 connects only MedicoHub-managed organisation accounts. Other admins may draft and request approval, but only social-account managers can reconnect or change destinations.',
              ),
              trailing: Chip(
                avatar: const Icon(Icons.verified_user_rounded, size: 18),
                label: Text(
                    _canManageSocialAccounts ? 'Can manage' : 'Draft only'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final item in _integrationCatalog)
                SizedBox(
                  width: 320,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(_integrationIcon(item.provider)),
                            title: Text(item.label),
                            subtitle: Text(item.notes),
                            trailing: item.recommended
                                ? const Icon(Icons.star_rounded)
                                : null,
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Chip(label: Text(item.authMode)),
                              if (item.supportsApiPublish)
                                Chip(
                                  avatar: Icon(
                                    item.oauthConfigured
                                        ? Icons.key_rounded
                                        : Icons.key_off_rounded,
                                    size: 18,
                                  ),
                                  label: Text(item.oauthConfigured
                                      ? 'OAuth configured'
                                      : 'OAuth app needed'),
                                )
                              else
                                const Chip(label: Text('Manual workflow')),
                              Chip(
                                label: Text(_catalogStatusLabel(item)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _canManageSocialAccounts &&
                                          !_saving &&
                                          (item.authMode != 'oauth2' ||
                                              item.oauthConfigured)
                                      ? () => _connectCatalogItem(item)
                                      : null,
                                  icon: Icon(item.authMode == 'oauth2'
                                      ? Icons.login_rounded
                                      : Icons.add_link_rounded),
                                  label: Text(item.authMode == 'oauth2'
                                      ? item.integrationId.isEmpty
                                          ? 'Connect'
                                          : 'Reconnect'
                                      : item.integrationId.isEmpty
                                          ? 'Enable export'
                                          : 'Enabled'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                tooltip: 'Copy setup details',
                                onPressed: (item.scopes.isEmpty &&
                                        item.callbackUrl.isEmpty)
                                    ? null
                                    : () => _copyText(
                                          _integrationSetupDetails(item),
                                        ),
                                icon: const Icon(Icons.copy_rounded),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text('Connected official accounts',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (_integrations.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.info_outline_rounded),
                title: Text('No channels enabled yet'),
                subtitle: Text(
                  'Start with manual export, then configure OAuth app credentials for API publishing.',
                ),
              ),
            )
          else
            for (final integration in _integrations)
              Card(
                child: ListTile(
                  leading: Icon(_integrationIcon(integration.provider)),
                  title: Text(
                    integration.externalAccountName.isNotEmpty
                        ? integration.externalAccountName
                        : integration.displayName,
                  ),
                  subtitle: Text(
                    '${integration.provider} | ${integration.externalAccountType.isEmpty ? 'organisation' : integration.externalAccountType} | ${integration.connectionStatus}'
                    '\nPermissions: ${integration.scopes.isEmpty ? 'manual export' : integration.scopes.join(', ')}'
                    '\nToken: ${integration.tokenStatus} | Last check: ${integration.lastHealthCheckAt.isEmpty ? 'not checked' : integration.lastHealthCheckAt}'
                    '${integration.pageId.isEmpty ? '' : '\nPage: ${integration.pageId}'}'
                    '${integration.instagramBusinessAccountId.isEmpty ? '' : '\nInstagram: ${integration.instagramBusinessAccountId}'}'
                    '${integration.channelId.isEmpty ? '' : '\nChannel: ${integration.channelId}'}'
                    '\n${integration.approvalStatus} | ${integration.publishingMode}'
                    '${integration.callbackUrl.isEmpty ? '' : '\nCallback: ${integration.callbackUrl}'}',
                  ),
                  isThreeLine: true,
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        tooltip: 'Copy callback URL',
                        onPressed: integration.callbackUrl.isEmpty
                            ? null
                            : () => _copyText(integration.callbackUrl),
                        icon: const Icon(Icons.copy_rounded),
                      ),
                      if (integration.authMode == 'oauth2')
                        IconButton(
                          tooltip: integration.connectionStatus ==
                                  'oauth_callback_received'
                              ? 'Reconnect'
                              : 'Connect',
                          onPressed: _canManageSocialAccounts && !_saving
                              ? () => _startOAuth(integration)
                              : null,
                          icon: const Icon(Icons.login_rounded),
                        ),
                      IconButton(
                        tooltip: 'Select destination',
                        onPressed: _canManageSocialAccounts && !_saving
                            ? () => _showDestinationDialog(integration)
                            : null,
                        icon: const Icon(Icons.ads_click_rounded),
                      ),
                      IconButton(
                        tooltip: 'Test connection',
                        onPressed: _canManageSocialAccounts && !_saving
                            ? () => _testIntegration(integration)
                            : null,
                        icon: const Icon(Icons.health_and_safety_rounded),
                      ),
                      IconButton(
                        tooltip: 'Approve integration',
                        onPressed: _canManageSocialAccounts &&
                                !_saving &&
                                integration.approvalStatus != 'approved'
                            ? () => _approveIntegration(
                                  integration,
                                  'approved',
                                )
                            : null,
                        icon: const Icon(Icons.verified_rounded),
                      ),
                      IconButton(
                        tooltip: 'Disable integration',
                        onPressed: _canManageSocialAccounts && !_saving
                            ? () => _approveIntegration(
                                  integration,
                                  'disabled',
                                )
                            : null,
                        icon: const Icon(Icons.block_rounded),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 12),
          Text('Publishing approval queue',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: _integrationDropdownValue(
                      _selectedIntegrationId,
                      approvedIntegrations.map((item) => item.id),
                    ),
                    decoration:
                        const InputDecoration(labelText: 'Approved channel'),
                    items: approvedIntegrations
                        .map(
                          (integration) => DropdownMenuItem<String>(
                            value: integration.id,
                            child: Text(integration.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedIntegrationId = value),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _publishTitleController,
                    decoration: const InputDecoration(labelText: 'Post title'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _publishBodyController,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Approved post copy',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: approvedIntegrations.isNotEmpty &&
                            widget.admin.canManageGrowthStudio &&
                            !_saving
                        ? _queuePublishingRequest
                        : null,
                    icon: const Icon(Icons.rule_rounded),
                    label: const Text('Queue for approval'),
                  ),
                ],
              ),
            ),
          ),
          if (_publishingRequests.isEmpty)
            const Card(
              child: ListTile(
                leading: Icon(Icons.pending_actions_rounded),
                title: Text('No publishing requests yet'),
                subtitle: Text(
                  'Create approved copy here before exporting or publishing on any channel.',
                ),
              ),
            )
          else
            for (final request in _publishingRequests)
              Card(
                child: ListTile(
                  leading: Icon(_integrationIcon(request.provider)),
                  title: Text(request.title),
                  subtitle: Text(
                    '${request.provider} | ${request.status}\n${request.body}',
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                  isThreeLine: true,
                  trailing: Wrap(
                    spacing: 6,
                    children: [
                      IconButton(
                        tooltip: 'Copy post copy',
                        onPressed: () => _copyText(
                          '${request.title}\n\n${request.body}',
                        ),
                        icon: const Icon(Icons.copy_rounded),
                      ),
                      IconButton(
                        tooltip: 'Approve',
                        onPressed: widget.admin.canManageGrowthStudio &&
                                !_saving &&
                                request.status != 'approved' &&
                                _canManageSocialAccounts
                            ? () => _updatePublishingRequest(
                                  request,
                                  'approved',
                                )
                            : null,
                        icon: const Icon(Icons.check_circle_rounded),
                      ),
                      IconButton(
                        tooltip: 'Mark exported',
                        onPressed: _canManageSocialAccounts && !_saving
                            ? () => _updatePublishingRequest(
                                  request,
                                  'exported',
                                )
                            : null,
                        icon: const Icon(Icons.file_upload_outlined),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  IconData _integrationIcon(String provider) {
    switch (provider) {
      case 'linkedin':
        return Icons.business_center_rounded;
      case 'facebook':
      case 'instagram':
      case 'meta':
      case 'threads':
        return Icons.groups_rounded;
      case 'youtube':
      case 'tiktok':
        return Icons.play_circle_outline_rounded;
      case 'google_business':
        return Icons.storefront_rounded;
      case 'reddit':
        return Icons.forum_rounded;
      case 'x':
        return Icons.alternate_email_rounded;
      case 'whatsapp':
        return Icons.chat_rounded;
      case 'newsletter':
        return Icons.mark_email_read_rounded;
      default:
        return Icons.ios_share_rounded;
    }
  }

  String _friendlyStatus(String status) {
    switch (status) {
      case 'oauth_pending':
        return 'Ready to connect';
      case 'oauth_callback_received':
        return 'Callback received';
      case 'token_reference_configured':
      case 'connected':
        return 'Connected';
      case 'manual_export_ready':
        return 'Export enabled';
      case 'oauth_not_configured':
        return 'OAuth app needed';
      case 'needs_reauth':
        return 'Reconnect needed';
      case 'disabled':
        return 'Disabled';
      case 'not_connected':
        return 'Not connected';
      default:
        return status.replaceAll('_', ' ');
    }
  }

  String _catalogStatusLabel(GrowthIntegrationCatalogItem item) {
    if (item.integrationId.isNotEmpty) {
      return _friendlyStatus(item.connectionStatus);
    }
    if (item.authMode == 'oauth2') {
      return item.oauthConfigured ? 'Ready to add' : 'App setup needed';
    }
    return 'Ready to enable';
  }

  String _integrationSetupDetails(GrowthIntegrationCatalogItem item) {
    final lines = <String>[
      '${item.label} (${item.provider})',
      if (item.callbackUrl.isNotEmpty) 'Callback URL: ${item.callbackUrl}',
      if (item.scopes.isNotEmpty) 'Scopes: ${item.scopes.join(' ')}',
    ];
    return lines.join('\n');
  }

  String? _integrationDropdownValue(
    String? currentValue,
    Iterable<String> values,
  ) {
    if (currentValue == null) {
      return null;
    }
    return values.contains(currentValue) ? currentValue : null;
  }
}
