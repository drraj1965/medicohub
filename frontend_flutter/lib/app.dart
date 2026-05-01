import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  'Hindi': 'hi-IN',
  'Marathi': 'mr-IN',
  'Tamil': 'ta-IN',
  'Telugu': 'te-IN',
  'Kannada': 'kn-IN',
  'Malayalam': 'ml-IN',
  'Gujarati': 'gu-IN',
  'Bengali': 'bn-IN',
};

class MedicoHubApp extends StatefulWidget {
  const MedicoHubApp({super.key});

  @override
  State<MedicoHubApp> createState() => _MedicoHubAppState();
}

class _MedicoHubAppState extends State<MedicoHubApp> {
  MedicoHubThemePreset _themePreset = MedicoHubThemePreset.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MedicoHub',
      debugShowCheckedModeBanner: false,
      theme: buildMedicoHubTheme(_themePreset),
      home: MedicoHubHomePage(
        themePreset: _themePreset,
        onThemeChanged: (preset) => setState(() => _themePreset = preset),
      ),
    );
  }
}

class MedicoHubHomePage extends StatefulWidget {
  const MedicoHubHomePage({
    super.key,
    required this.themePreset,
    required this.onThemeChanged,
  });

  final MedicoHubThemePreset themePreset;
  final ValueChanged<MedicoHubThemePreset> onThemeChanged;

  @override
  State<MedicoHubHomePage> createState() => _MedicoHubHomePageState();
}

class _MedicoHubHomePageState extends State<MedicoHubHomePage> {
  final AppApiService _api = AppApiService();
  final FirebaseAuthService _auth = FirebaseAuthService();
  final UpdateService _updateService = UpdateService();
  final MedicoHubVoiceService _voiceService = MedicoHubVoiceService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _symptomsController = TextEditingController();
  final TextEditingController _emailController =
      TextEditingController(text: 'drphaniraj1965@gmail.com');
  final TextEditingController _passwordController =
      TextEditingController(text: 'Passw0rd!');
  final TextEditingController _displayNameController =
      TextEditingController(text: 'Rajshekher Garikapati');
  final TextEditingController _phoneController =
      TextEditingController(text: '+919000611048');
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

  bool _consentAccepted = false;
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
  bool _currentPasswordVisible = false;
  bool _newPasswordVisible = false;
  int _tabIndex = 0;

  String _selectedExpiry = '7d';
  String _selectedLanguage = 'English';
  String _selectedAccountRole = 'patient';
  String _selectedSpecialty = 'General Health';
  String _selectedTemplateId = '_custom';
  String _selectedQuestionCategory = 'General';
  String? _selectedDoctorId;
  String _inviteDoctorLanguage = 'English';
  String _inviteDoctorSpecialty = 'General Health';
  String? _editingQuestionId;
  String _articleCategory = 'General Health';

  UserProfile? _activeUser;
  UpdateInfo? _updateInfo;
  UserProfile? _matchedRosterUser;
  List<ForumQuestion> _questions = const [];
  List<EducationItem> _education = const [];
  List<BlogArticle> _blogArticles = const [];
  List<NotificationOutboxItem> _notifications = const [];
  NotificationSettings? _notificationSettings;
  List<UploadedAttachment> _uploadedAttachments = const [];
  List<TitleTemplate> _titleTemplates = const [];
  List<DoctorDirectoryEntry> _doctors = const [];
  String? _errorMessage;
  String? _authLookupMessage;
  String? _voiceStatus;
  String? _audioAttachmentPath;
  SharedPreferences? _prefs;
  Timer? _emailLookupDebounce;
  late int _humanCheckLeft;
  late int _humanCheckRight;
  final TextEditingController _humanCheckController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _resetHumanCheck();
    _emailController.addListener(_scheduleIdentityLookup);
    _bootstrap();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _symptomsController.dispose();
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
    _humanCheckController.dispose();
    _emailLookupDebounce?.cancel();
    _voiceService.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final results = await Future.wait([
        _api.fetchQuestions(),
        _api.fetchEducation(),
        _api.fetchBlogArticles(),
        _api.fetchTitleTemplates(),
        _api.fetchDoctors(),
        _api.fetchNotificationSettings(),
        _updateService.checkForUpdates(),
        SharedPreferences.getInstance(),
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
        _updateInfo = results[6] as UpdateInfo?;
        _prefs = results[7] as SharedPreferences;
        _loading = false;
      });
      _notificationPhraseController.text =
          _notificationSettings?.whatsAppActivationPhrase ?? '';
      _notificationTargetController.text =
          _notificationSettings?.whatsAppActivationTarget ?? '';
      _emailStatusNoteController.text =
          _notificationSettings?.emailStatusNote ?? '';
      _scheduleIdentityLookup();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _errorMessage = error.toString();
      });
    }
  }

  List<TitleTemplate> get _visibleTitleTemplates {
    return _titleTemplates.where((template) {
      return template.language == _selectedLanguage ||
          template.language == 'English';
    }).toList();
  }

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

  String get _whatsAppActivationStatusLabel =>
      _isWhatsAppActivationCoolingDown
          ? 'WhatsApp notifications activated'
          : 'WhatsApp notifications to be activated';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MedicoHub'),
        actions: [
          if (_activeUser != null)
            TextButton.icon(
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
            ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                'Educational only',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _activeUser == null
            ? null
            : () => setState(() => _tabIndex = 1),
        label: Text(_editingQuestionId == null ? 'Ask' : 'Edit'),
        icon: const Icon(Icons.add_comment_outlined),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (value) => setState(() => _tabIndex = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.help_outline), label: 'Ask Question'),
          NavigationDestination(
              icon: Icon(Icons.forum_outlined), label: 'My Questions'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined), label: 'Education'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _activeUser == null
                ? _buildLoginGate(context)
                : _consentAccepted
                    ? Padding(
                        padding: const EdgeInsets.all(16),
                        child: IndexedStack(
                          index: _tabIndex,
                          children: [
                            _buildHomeTab(context),
                            _buildAskTab(context),
                            _buildQuestionsTab(context),
                            _buildEducationTab(context),
                            _buildSettingsTab(context),
                          ],
                        ),
                      )
                    : _buildConsentGate(context),
      ),
    );
  }

  Widget _buildLoginGate(BuildContext context) {
    final showSignupFields = _createAccountMode;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Card(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _createAccountMode ? 'Create Account' : 'Sign In',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                Text(
                  _createAccountMode
                      ? 'Patients can create accounts directly. Admins must be on the MedicoHub allowlist, and doctors must already exist in the doctor directory or be added by an admin first.'
                      : 'Use email and password to sign in. If this is your first time on a newly created Firebase account, switch to Create Account first.',
                ),
                if (_identityLookupBusy) ...[
                  const SizedBox(height: 12),
                  const LinearProgressIndicator(),
                ],
                if (_authLookupMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _authLookupMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (showSignupFields) ...[
                  TextField(
                    controller: _displayNameController,
                    decoration:
                        const InputDecoration(labelText: 'Display name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                        labelText: 'Mobile phone number'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedAccountRole,
                    decoration:
                        const InputDecoration(labelText: 'Account role'),
                    items: _accountRoles
                        .map(
                          (role) => DropdownMenuItem<String>(
                            value: role,
                            child: Text(
                                role[0].toUpperCase() + role.substring(1)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedAccountRole = value);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLanguage,
                    decoration:
                        const InputDecoration(labelText: 'Primary language'),
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
                  if (_selectedAccountRole != 'patient') ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSpecialty,
                      decoration: const InputDecoration(
                        labelText: 'Doctor specialty',
                        helperText:
                            'Shown only while creating doctor/admin accounts.',
                      ),
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
                  const SizedBox(height: 12),
                ],
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
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
                const SizedBox(height: 12),
                TextField(
                  controller: _humanCheckController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Human check',
                    helperText:
                        'Please solve $_humanCheckLeft + $_humanCheckRight before signing in.',
                    suffixIcon: IconButton(
                      onPressed: () => setState(_resetHumanCheck),
                      icon: const Icon(Icons.refresh_outlined),
                    ),
                  ),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  SelectableText(
                    _errorMessage!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.error),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton(
                      onPressed: _authBusy || (!_createAccountMode && _matchedRosterUser == null)
                          ? null
                          : (_createAccountMode
                              ? _registerFirebaseUser
                              : _signInWithFirebase),
                      child: Text(
                        _authBusy
                            ? (_createAccountMode
                                ? 'Creating...'
                                : 'Signing In...')
                            : (_createAccountMode
                                ? 'Create Account'
                                : 'Sign In'),
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _authBusy
                          ? null
                          : () {
                              setState(() {
                                _createAccountMode = !_createAccountMode;
                                _errorMessage = null;
                                _authLookupMessage = null;
                              });
                            },
                      child: Text(
                        _createAccountMode
                            ? 'Switch to Sign In'
                            : 'Switch to Create Account',
                      ),
                    ),
                    TextButton(
                      onPressed: _authBusy ? null : _useBackendDemoUser,
                      child: const Text('Use Backend Demo'),
                    ),
                    TextButton(
                      onPressed: _authBusy ? null : _sendPasswordReset,
                      child: const Text('Reset Password'),
                    ),
                    TextButton(
                      onPressed: _authBusy ? null : _openOtpSignInDialog,
                      child: const Text('Sign In with OTP'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Current seeded people: three named admins/doctors and one development patient account.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConsentGate(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Consent Required',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                const Text(
                    'This platform does NOT provide diagnosis or prescriptions.'),
                const SizedBox(height: 8),
                const Text('For emergency, contact local services immediately.'),
                const SizedBox(height: 8),
                const Text(
                    'Doctor replies are educational, general guidance, and opinion only.'),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: () => setState(() => _consentAccepted = true),
                  child: const Text('I understand and accept'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHomeTab(BuildContext context) {
    final user = _activeUser!;
    final scopedQuestions = _roleScopedQuestions;
    final pendingQuestions = scopedQuestions
        .where((question) => question.status == 'open')
        .length;
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
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth > 900;
            final cards = <Widget>[
              _buildProfileCard(context, user),
              _buildDashboardCard(
                context,
                title: user.isAdmin ? 'Admin Dashboard' : user.isDoctor ? 'Doctor Dashboard' : 'Patient Dashboard',
                body: user.isAdmin
                    ? 'Govern the doctor roster, moderate future discussions, curate question title examples, and oversee the full queue.'
                    : user.isDoctor
                        ? 'Review questions addressed to you, answer threads, publish educational blog posts, and prepare multilingual responses.'
                        : 'Ask questions, follow thread updates, read education content, and comment on future doctor blog posts.',
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
                const Text(
                  'Role-based accounts, doctor directory selection, targeted question threads, admin-managed title templates, file uploads, voice-note capture, and WhatsApp notifications are live. Email delivery is being kept in preview mode until a dedicated sender setup is ready.',
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
        ...scopedQuestions.take(4).map(
              (question) => Padding(
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
            ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, UserProfile user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(user.displayName),
            const SizedBox(height: 8),
            Text('Role: ${user.role}'),
            const SizedBox(height: 8),
            Text('Email: ${user.email}'),
            if (user.phoneNumber != null) ...[
              const SizedBox(height: 8),
              Text('Phone: ${user.phoneNumber}'),
            ],
            const SizedBox(height: 8),
            Text('Languages: ${user.languages.join(', ')}'),
            if (user.specialties.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Specialties: ${user.specialties.join(', ')}'),
            ],
          ],
        ),
      ),
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
                  child: Text(line),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Role-based doctor-patient education platform',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Text(
              'Admins govern the doctor roster, doctors answer educational questions, and patients can ask structured questions addressed to a specific doctor with files and voice notes.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhatsAppActivationBadge(BuildContext context) {
    final activated = _isWhatsAppActivationCoolingDown;
    final subtitle = activated
        ? 'WhatsApp notifications are marked active on this device for today. Tap to review delivery settings.'
        : 'WhatsApp notifications still need activation for today. Tap to open Delivery Channels in Settings.';
    return Card(
      child: ListTile(
        leading: Icon(
          activated ? Icons.verified_user_outlined : Icons.notification_important_outlined,
          color: activated
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        title: Text(_whatsAppActivationStatusLabel),
        subtitle: Text(subtitle),
        trailing: TextButton(
          onPressed: _openNotificationSettingsTab,
          child: Text(activated ? 'View' : 'Activate'),
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
                const Text(
                  'Pick a doctor, choose a broad heading, then use a plain-language title with patient terms like stroke, fits, or Parkinson\'s.',
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
                    'Doctor languages: ${selectedDoctor.languages.join(', ')} • specialties: ${selectedDoctor.specialties.join(', ')}',
                  ),
                ],
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _selectedQuestionCategory,
                  decoration:
                      const InputDecoration(labelText: 'General heading'),
                  items: _questionCategories
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
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      helperText:
                          'Tip: include simple terms such as stroke, fits, Parkinson, tremor, or migraine.',
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
                  subtitle: const Text(
                      'Change visibility from the My Questions list using the Public/Private action.'),
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
    final questions = _roleScopedQuestions;
    if (questions.isEmpty) {
      return const Center(
        child: Text('No question threads are visible for this account yet.'),
      );
    }
    final user = _activeUser!;
    if (user.isDoctor) {
      return ListView(
        children: [
          _buildQuestionListSection(
            context,
            title: 'Current',
            questions: _doctorCurrentQuestions,
          ),
          const SizedBox(height: 16),
          _buildQuestionListSection(
            context,
            title: 'History',
            questions: _doctorHistoryQuestions,
          ),
        ],
      );
    }
    return _buildQuestionListSection(
      context,
      title: 'Threads',
      questions: questions,
    );
  }

  Widget _buildEducationTab(BuildContext context) {
    return ListView(
      children: [
        if (_blogArticles.isNotEmpty) ...[
          Text('Doctor Blog', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ..._blogArticles.map(
            (article) => Padding(
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
          ),
          const SizedBox(height: 8),
        ],
        Text('Education Library', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        ..._education.map(
          (item) => Padding(
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
        ),
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
              ...questions.map(
                (question) => Padding(
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
                Text('Settings', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                DropdownButtonFormField<MedicoHubThemePreset>(
                  initialValue: widget.themePreset,
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
                      widget.onThemeChanged(value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                Text('Current app version: ${UpdateService.currentVersion}'),
                const SizedBox(height: 8),
                const Text(
                  'Next planned modules: blog posts, threaded comments, moderation tools, email notifications, WhatsApp notifications, and translation delivery.',
                ),
                const SizedBox(height: 8),
                Text(
                  'WhatsApp is the primary live notification channel today. Email delivery is intentionally held in preview mode until a dedicated sender domain is finalized.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Android testing: run the app on a phone with --dart-define=MEDICOHUB_API_BASE_URL=http://YOUR-LAN-IP:8012 so speech-to-text keyboards can be exercised on-device.',
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
                        : 'Live now for question creation, answers, and thread updates. If you are using the Twilio sandbox, send "${_notificationSettings!.whatsAppActivationPhrase}" to ${_notificationSettings!.whatsAppActivationTarget} once per day to activate notifications.',
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
    if (!_verifyHumanCheck()) {
      return;
    }
    setState(() {
      _authBusy = true;
      _errorMessage = null;
    });
    try {
      final firebaseUser = await _auth.signInWithEmail(
        email: _emailController.text.trim(),
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
        _humanCheckController.clear();
      });
      _resetHumanCheck();
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
    if (!_verifyHumanCheck()) {
      return;
    }
    setState(() {
      _authBusy = true;
      _errorMessage = null;
    });
    try {
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
        _humanCheckController.clear();
      });
      _resetHumanCheck();
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

  void _resetHumanCheck() {
    final random = Random();
    _humanCheckLeft = 2 + random.nextInt(8);
    _humanCheckRight = 1 + random.nextInt(9);
    _humanCheckController.clear();
  }

  bool _verifyHumanCheck() {
    final expected = _humanCheckLeft + _humanCheckRight;
    final actual = int.tryParse(_humanCheckController.text.trim());
    if (actual == expected) {
      return true;
    }
    setState(() {
      _errorMessage =
          'Please complete the human check correctly before signing in.';
      _resetHumanCheck();
    });
    return false;
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

  Future<void> _openOtpSignInDialog() async {
    final destinationController = TextEditingController(
      text: _createAccountMode
          ? (_selectedAccountRole == 'patient'
              ? _emailController.text.trim()
              : (_matchedRosterUser?.email ?? _emailController.text.trim()))
          : (_matchedRosterUser?.email.isNotEmpty == true
              ? _matchedRosterUser!.email
              : _emailController.text.trim()),
    );
    final codeController = TextEditingController();
    var selectedChannel = 'email';
    var dialogBusy = false;
    String? otpPreview;
    bool codeRequested = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Sign In with OTP'),
              content: SizedBox(
                width: 460,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: selectedChannel,
                      decoration: const InputDecoration(labelText: 'OTP channel'),
                      items: const [
                        DropdownMenuItem(value: 'email', child: Text('Email OTP')),
                        DropdownMenuItem(value: 'sms', child: Text('Mobile OTP')),
                      ],
                      onChanged: dialogBusy
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() {
                                  selectedChannel = value;
                                  if (value == 'sms') {
                                    destinationController.text =
                                        _matchedRosterUser?.phoneNumber ??
                                            _phoneController.text.trim();
                                  } else {
                                    destinationController.text =
                                        _matchedRosterUser?.email ??
                                            _emailController.text.trim();
                                  }
                                });
                              }
                            },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: destinationController,
                      decoration: InputDecoration(
                        labelText: selectedChannel == 'email'
                            ? 'Email address'
                            : 'Mobile phone number',
                      ),
                    ),
                    if (codeRequested) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'OTP code'),
                      ),
                    ],
                    if (otpPreview != null) ...[
                      const SizedBox(height: 12),
                      SelectableText(
                        otpPreview!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: dialogBusy
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Close'),
                ),
                if (!codeRequested)
                  FilledButton(
                    onPressed: dialogBusy
                        ? null
                        : () async {
                            setDialogState(() => dialogBusy = true);
                            try {
                              final result = await _api.requestOtp(
                                destination: destinationController.text.trim(),
                                channel: selectedChannel,
                              );
                              if (!mounted) {
                                return;
                              }
                              setDialogState(() {
                                dialogBusy = false;
                                codeRequested = true;
                                otpPreview = result.deliveryStatus == 'preview_only' &&
                                        selectedChannel == 'email'
                                    ? 'Email OTP is still in preview mode while MedicoHub completes a dedicated sender setup. Use password sign-in on desktop for now.'
                                    : result.previewMessage ??
                                        'OTP sent through ${result.channel}.';
                              });
                            } catch (error) {
                              if (!mounted) {
                                return;
                              }
                              setState(() {
                                _errorMessage = 'Could not request OTP: $error';
                              });
                              setDialogState(() => dialogBusy = false);
                            }
                          },
                    child: Text(dialogBusy ? 'Sending...' : 'Request OTP'),
                  )
                else
                  FilledButton(
                    onPressed: dialogBusy
                        ? null
                        : () async {
                            setDialogState(() => dialogBusy = true);
                            try {
                              final profile = await _api.verifyOtp(
                                destination: destinationController.text.trim(),
                                channel: selectedChannel,
                                code: codeController.text.trim(),
                              );
                              if (!mounted) {
                                return;
                              }
                              setState(() {
                                _activeUser = profile;
                                _selectedLanguage = profile.languages.isEmpty
                                    ? _selectedLanguage
                                    : profile.languages.first;
                                _voiceStatus = 'Signed in with OTP successfully.';
                              });
                              await _refreshNotifications(profile.id);
                              if (dialogContext.mounted) {
                                Navigator.of(dialogContext).pop();
                              }
                            } catch (error) {
                              if (!mounted) {
                                return;
                              }
                              setState(() {
                                _errorMessage = 'Could not verify OTP: $error';
                              });
                              setDialogState(() => dialogBusy = false);
                            }
                          },
                    child: Text(dialogBusy ? 'Verifying...' : 'Verify OTP'),
                  ),
              ],
            );
          },
        );
      },
    );
    destinationController.dispose();
    codeController.dispose();
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
      setState(() {
        _voiceStatus = 'Audio recorder unavailable: $error';
      });
    }
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
      _consentAccepted = false;
      _tabIndex = 0;
      _uploadedAttachments = const [];
      _audioAttachmentPath = null;
      _audioPreviewPlaying = false;
      _voiceStatus = null;
      _editingQuestionId = null;
      _notifications = const [];
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
