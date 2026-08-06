import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser;

import '../models/app_models.dart';

class AppApiService {
  AppApiService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static final String _baseUrl = _resolveBaseUrl();
  static const Duration _requestTimeout = Duration(seconds: 20);
  static const Duration _questionRequestTimeout = Duration(seconds: 30);
  static const Duration _shareRequestTimeout = Duration(seconds: 90);
  static const String _publicBackendUrl = 'https://medicohub-backend.fly.dev';

  String get baseUrl => _baseUrl;

  static String _resolveBaseUrl() {
    const configured = String.fromEnvironment('MEDICOHUB_API_BASE_URL');
    if (configured.isNotEmpty) {
      return configured;
    }
    if (kIsWeb) {
      return _publicBackendUrl;
    }
    if (Platform.isAndroid) {
      return kReleaseMode ? _publicBackendUrl : 'http://10.0.2.2:8012';
    }
    if (Platform.isIOS) {
      return _publicBackendUrl;
    }
    if (Platform.isMacOS) {
      return _publicBackendUrl;
    }
    if (Platform.isWindows) {
      return _publicBackendUrl;
    }
    return _publicBackendUrl;
  }

  Future<List<ForumQuestion>> fetchQuestions() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/questions'))
        .timeout(_questionRequestTimeout);
    _ensureSuccess(response, 'questions');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => ForumQuestion.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<bool> checkHealth() async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    }
  }

  Future<Map<String, dynamic>> fetchTranslationUsage() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/api/admin/translation-usage'))
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'translation usage');
    final decoded = jsonDecode(response.body);
    return decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
  }

  Future<GrowthOverview> fetchGrowthOverview({required String actorId}) async {
    final response = await _client
        .get(Uri.parse(
            '$_baseUrl/api/admin/growth/overview?actor_id=${Uri.encodeQueryComponent(actorId)}'))
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'growth overview');
    return GrowthOverview.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<GrowthCampaign>> fetchGrowthCampaigns({
    required String actorId,
  }) async {
    final response = await _client
        .get(Uri.parse(
            '$_baseUrl/api/admin/growth/campaigns?actor_id=${Uri.encodeQueryComponent(actorId)}'))
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'growth campaigns');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => GrowthCampaign.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<GrowthCampaign> createGrowthCampaign({
    required String actorId,
    required String name,
    required String objective,
    required String hypothesis,
    required String targetAudience,
    required String valueOffered,
    required String primaryCta,
    required String primaryMetric,
    required List<String> channels,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/admin/growth/campaigns'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'actor_id': actorId,
            'name': name,
            'objective': objective,
            'hypothesis': hypothesis,
            'target_audience': targetAudience,
            'value_offered': valueOffered,
            'primary_cta': primaryCta,
            'primary_metric': primaryMetric,
            'channels': channels,
            'minimum_observation_period_days': 14,
          }),
        )
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'create growth campaign');
    return GrowthCampaign.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<GrowthOpportunity>> fetchGrowthOpportunities({
    required String actorId,
  }) async {
    final response = await _client
        .get(Uri.parse(
            '$_baseUrl/api/admin/growth/opportunities?actor_id=${Uri.encodeQueryComponent(actorId)}'))
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'growth opportunities');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => GrowthOpportunity.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<GrowthDerivative>> fetchGrowthDerivatives({
    required String actorId,
    String? sourceArticleId,
  }) async {
    final params = <String, String>{
      'actor_id': actorId,
      if (sourceArticleId != null && sourceArticleId.isNotEmpty)
        'source_article_id': sourceArticleId,
    };
    final response = await _client
        .get(Uri.parse('$_baseUrl/api/admin/growth/content-derivatives')
            .replace(queryParameters: params))
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'growth derivatives');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => GrowthDerivative.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<GrowthDerivative> createGrowthDerivative({
    required String actorId,
    required String sourceArticleId,
    required String assetType,
    required String platform,
    required String title,
    required String body,
    String? campaignId,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/admin/growth/content-derivatives'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'actor_id': actorId,
            'source_article_id': sourceArticleId,
            'asset_type': assetType,
            'platform': platform,
            'title': title,
            'body': body,
            if (campaignId != null && campaignId.isNotEmpty)
              'campaign_id': campaignId,
          }),
        )
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'create growth derivative');
    return GrowthDerivative.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<GrowthIntegrationCatalogItem>> fetchGrowthIntegrationCatalog({
    required String actorId,
  }) async {
    final response = await _client
        .get(Uri.parse(
            '$_baseUrl/api/admin/growth/integrations/catalog?actor_id=${Uri.encodeQueryComponent(actorId)}'))
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'growth integration catalog');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) =>
            GrowthIntegrationCatalogItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<GrowthIntegration>> fetchGrowthIntegrations({
    required String actorId,
  }) async {
    final response = await _client
        .get(Uri.parse(
            '$_baseUrl/api/admin/growth/integrations?actor_id=${Uri.encodeQueryComponent(actorId)}'))
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'growth integrations');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => GrowthIntegration.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<GrowthIntegration> createGrowthIntegration({
    required String actorId,
    required String provider,
    required String displayName,
    required String authMode,
    List<String> scopes = const [],
    String accountHandle = '',
    String accountUrl = '',
    String notes = '',
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/admin/growth/integrations'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'actor_id': actorId,
            'provider': provider,
            'display_name': displayName,
            'account_handle': accountHandle,
            'account_url': accountUrl,
            'auth_mode': authMode,
            'scopes': scopes,
            'notes': notes,
          }),
        )
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'create growth integration');
    return GrowthIntegration.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> startGrowthIntegrationOAuth({
    required String actorId,
    required String integrationId,
  }) async {
    final response = await _client
        .post(
          Uri.parse(
              '$_baseUrl/api/admin/growth/integrations/$integrationId/oauth/start'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'actor_id': actorId}),
        )
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'start growth OAuth');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<GrowthIntegration> updateGrowthIntegrationApproval({
    required String actorId,
    required String integrationId,
    required String approvalStatus,
    String notes = '',
  }) async {
    final response = await _client
        .patch(
          Uri.parse(
              '$_baseUrl/api/admin/growth/integrations/$integrationId/approval'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'actor_id': actorId,
            'approval_status': approvalStatus,
            'notes': notes,
          }),
        )
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'update growth integration approval');
    return GrowthIntegration.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<GrowthIntegration> updateGrowthIntegrationSelection({
    required String actorId,
    required String integrationId,
    String externalAccountId = '',
    String externalAccountName = '',
    String externalAccountType = '',
    String pageId = '',
    String instagramBusinessAccountId = '',
    String channelId = '',
    String notes = '',
  }) async {
    final response = await _client
        .patch(
          Uri.parse(
              '$_baseUrl/api/admin/growth/integrations/$integrationId/selection'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'actor_id': actorId,
            'external_account_id': externalAccountId,
            'external_account_name': externalAccountName,
            'external_account_type': externalAccountType,
            'page_id': pageId,
            'instagram_business_account_id': instagramBusinessAccountId,
            'channel_id': channelId,
            'notes': notes,
          }),
        )
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'update growth integration selection');
    return GrowthIntegration.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> testGrowthIntegration({
    required String actorId,
    required String integrationId,
  }) async {
    final response = await _client
        .post(
          Uri.parse(
              '$_baseUrl/api/admin/growth/integrations/$integrationId/test'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'actor_id': actorId}),
        )
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'test growth integration');
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<GrowthPublishingRequest>> fetchGrowthPublishingRequests({
    required String actorId,
  }) async {
    final response = await _client
        .get(Uri.parse(
            '$_baseUrl/api/admin/growth/publishing-requests?actor_id=${Uri.encodeQueryComponent(actorId)}'))
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'growth publishing requests');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) =>
            GrowthPublishingRequest.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<GrowthPublishingRequest> createGrowthPublishingRequest({
    required String actorId,
    required String integrationId,
    required String provider,
    required String title,
    required String body,
    String derivativeId = '',
    String campaignId = '',
    String targetUrl = '',
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/admin/growth/publishing-requests'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'actor_id': actorId,
            'integration_id': integrationId,
            'provider': provider,
            'title': title,
            'body': body,
            if (derivativeId.isNotEmpty) 'derivative_id': derivativeId,
            if (campaignId.isNotEmpty) 'campaign_id': campaignId,
            'target_url': targetUrl,
          }),
        )
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'create growth publishing request');
    return GrowthPublishingRequest.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<GrowthPublishingRequest> updateGrowthPublishingRequest({
    required String actorId,
    required String publishId,
    required String status,
    String notes = '',
    String externalPostId = '',
  }) async {
    final response = await _client
        .patch(
          Uri.parse(
              '$_baseUrl/api/admin/growth/publishing-requests/$publishId/approval'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'actor_id': actorId,
            'status': status,
            'notes': notes,
            'external_post_id': externalPostId,
          }),
        )
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'update growth publishing request');
    return GrowthPublishingRequest.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> recordGrowthEvent({
    required String eventName,
    String? anonymousId,
    String? userId,
    String? sessionId,
    String? campaignId,
    String? source,
    String? medium,
    String? platform,
    String? contentId,
    String? language,
    String? region,
    Map<String, Object?> metadata = const {},
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/growth/events'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'event_name': eventName,
            'anonymous_id': anonymousId,
            'user_id': userId,
            'session_id': sessionId,
            'campaign_id': campaignId,
            'source': source,
            'medium': medium,
            'platform': platform,
            'content_id': contentId,
            'language': language,
            'region': region,
            'metadata': metadata,
          }),
        )
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'growth event');
  }

  Future<void> waitUntilReady({
    int attempts = 6,
    Duration initialDelay = const Duration(seconds: 2),
  }) async {
    for (var attempt = 0; attempt < attempts; attempt++) {
      if (await checkHealth()) {
        return;
      }
      if (attempt < attempts - 1) {
        await Future<void>.delayed(
          Duration(seconds: initialDelay.inSeconds + (attempt * 3)),
        );
      }
    }
    throw Exception('Backend is temporarily unavailable.');
  }

  Future<List<EducationItem>> fetchEducation() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/education/library'))
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'education');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => EducationItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<BlogArticle>> fetchBlogArticles() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/blog/articles'))
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'blog articles');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => BlogArticle.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<AdCampaign>> fetchAdCampaigns() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/ad-campaigns'))
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'ad campaigns');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => AdCampaign.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<TitleTemplate>> fetchTitleTemplates() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/title-templates'))
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'title templates');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => TitleTemplate.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<DoctorDirectoryEntry>> fetchDoctors() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/doctors'))
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'doctors');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) =>
            DoctorDirectoryEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<UserProfile>> fetchUsers() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/api/admin/users'))
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'users');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) => UserProfile.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ContentShareReport> shareContentByEmail({
    required String actorId,
    required String contentType,
    required String contentId,
    required List<String> recipientIds,
    required String customMessage,
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/api/admin/share-content'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'actor_id': actorId,
            'content_type': contentType,
            'content_id': contentId,
            'recipient_ids': recipientIds,
            'custom_message': customMessage,
            'send_email': true,
          }),
        )
        .timeout(_shareRequestTimeout);
    _ensureSuccess(response, 'share content');
    return ContentShareReport.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<UserProfile> updateCommunicationPreferences({
    required String userId,
    required String actorId,
    required bool emailSubscribed,
    required Map<String, bool> communicationPreferences,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/users/$userId/communication-preferences'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'actor_id': actorId,
        'email_subscribed': emailSubscribed,
        'communication_preferences': communicationPreferences,
      }),
    );
    _ensureSuccess(response, 'communication preferences');
    return UserProfile.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<UserProfile> loginAsDemo(String email) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/auth/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': 'Passw0rd!'}),
        )
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'login');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<OtpRequestResult> requestOtp({
    required String destination,
    required String channel,
    String purpose = 'sign_in',
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/otp/request'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'destination': destination,
        'channel': channel,
        'purpose': purpose,
      }),
    );
    _ensureSuccess(response, 'otp request');
    return OtpRequestResult.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<UserProfile> verifyOtp({
    required String destination,
    required String channel,
    required String code,
    String purpose = 'sign_in',
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/otp/verify'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'destination': destination,
        'channel': channel,
        'code': code,
        'purpose': purpose,
      }),
    );
    _ensureSuccess(response, 'otp verify');
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return UserProfile.fromJson(data['user'] as Map<String, dynamic>);
  }

  Future<UserProfile?> fetchUserProfile(String userId) async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/users/$userId'))
        .timeout(_requestTimeout);
    if (response.statusCode == 404) {
      return null;
    }
    _ensureSuccess(response, 'user profile');
    return UserProfile.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<UserProfile?> lookupUserByEmail(String email) async {
    final response = await _client
        .get(
          Uri.parse(
              '$_baseUrl/users/lookup/by-email?email=${Uri.encodeQueryComponent(email)}'),
        )
        .timeout(_requestTimeout);
    if (response.statusCode == 404 ||
        response.body.trim().isEmpty ||
        response.body.trim() == 'null') {
      return null;
    }
    _ensureSuccess(response, 'user lookup');
    return UserProfile.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<UserProfile?> lookupUserByPhone({
    String? phoneNumber,
    String? phoneCountryCode,
    String? phoneNationalNumber,
  }) async {
    final params = <String, String>{
      if (phoneNumber != null && phoneNumber.isNotEmpty)
        'phone_number': phoneNumber,
      if (phoneCountryCode != null && phoneCountryCode.isNotEmpty)
        'phone_country_code': phoneCountryCode,
      if (phoneNationalNumber != null && phoneNationalNumber.isNotEmpty)
        'phone_national_number': phoneNationalNumber,
    };
    final response = await _client
        .get(
          Uri.parse(
            '$_baseUrl/users/lookup/by-phone',
          ).replace(queryParameters: params),
        )
        .timeout(_requestTimeout);
    if (response.statusCode == 404 ||
        response.body.trim().isEmpty ||
        response.body.trim() == 'null') {
      return null;
    }
    _ensureSuccess(response, 'user lookup by phone');
    return UserProfile.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<NotificationOutboxItem>> fetchNotifications({
    String? userId,
  }) async {
    final suffix = userId == null || userId.isEmpty
        ? ''
        : '?user_id=${Uri.encodeQueryComponent(userId)}';
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/notifications/outbox$suffix'),
        )
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'notifications');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) =>
            NotificationOutboxItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<NotificationSettings> fetchNotificationSettings() async {
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/notification-settings'),
        )
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'notification settings');
    return NotificationSettings.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AppSettings> fetchAppSettings() async {
    final response = await _client
        .get(
          Uri.parse('$_baseUrl/app-settings'),
        )
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'app settings');
    return AppSettings.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<NotificationSettings> updateNotificationSettings({
    required String actorId,
    required bool whatsAppActivationEnabled,
    required String whatsAppActivationTarget,
    required String whatsAppActivationPhrase,
    required String emailStatusNote,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/notification-settings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'actor_id': actorId,
        'whatsapp_activation_enabled': whatsAppActivationEnabled,
        'whatsapp_activation_target': whatsAppActivationTarget,
        'whatsapp_activation_phrase': whatsAppActivationPhrase,
        'email_status_note': emailStatusNote,
      }),
    );
    _ensureSuccess(response, 'update notification settings');
    return NotificationSettings.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AppSettings> updateAppSettings({
    required String actorId,
    required List<String> questionTopics,
    required Map<String, DisclaimerDocument> disclaimerDocuments,
    required String defaultRegionNote,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/app-settings'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'actor_id': actorId,
        'question_topics': questionTopics,
        'disclaimer_documents': disclaimerDocuments.map(
          (key, value) => MapEntry(key, value.toJson()),
        ),
        'default_region_note': defaultRegionNote,
      }),
    );
    _ensureSuccess(response, 'update app settings');
    return AppSettings.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AdCampaign> createAdCampaign({
    required String actorId,
    required String sponsorName,
    required String title,
    required String subtitle,
    required String ctaLabel,
    required String targetUrl,
    required List<String> keywords,
    required List<String> categories,
    required List<String> placements,
    required List<String> languages,
    required int priority,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/ad-campaigns'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'actor_id': actorId,
        'sponsor_name': sponsorName,
        'title': title,
        'subtitle': subtitle,
        'cta_label': ctaLabel,
        'target_url': targetUrl,
        'keywords': keywords,
        'categories': categories,
        'placements': placements,
        'languages': languages,
        'priority': priority,
      }),
    );
    _ensureSuccess(response, 'create ad campaign');
    return AdCampaign.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<AdCampaign> updateAdCampaign({
    required String campaignId,
    required String actorId,
    bool? active,
  }) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/ad-campaigns/$campaignId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'actor_id': actorId,
        if (active != null) 'active': active,
      }),
    );
    _ensureSuccess(response, 'update ad campaign');
    return AdCampaign.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<UserProfile> upsertUserProfile({
    required String id,
    required String email,
    required String displayName,
    required String role,
    required List<String> languages,
    String? phoneNumber,
    String? phoneCountryCode,
    String? phoneNationalNumber,
    List<String> specialties = const [],
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/users/profile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'id': id,
        'email': email,
        'display_name': displayName,
        'phone_number': phoneNumber,
        'phone_country_code': phoneCountryCode,
        'phone_national_number': phoneNationalNumber,
        'role': role,
        'languages': languages,
        'specialties': specialties,
        'verified': role == 'doctor' || role == 'admin',
      }),
    );
    _ensureSuccess(response, 'user profile upsert');
    return UserProfile.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<DoctorDirectoryEntry> inviteDoctor({
    required String actorId,
    required String email,
    required String displayName,
    String? phoneNumber,
    List<String> specialties = const ['General Health'],
    List<String> languages = const ['English'],
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/doctors/invite'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'actor_id': actorId,
        'email': email,
        'display_name': displayName,
        'phone_number': phoneNumber,
        'specialties': specialties,
        'languages': languages,
      }),
    );
    _ensureSuccess(response, 'doctor invite');
    return DoctorDirectoryEntry.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ForumQuestion> submitQuestion({
    required String authorId,
    required String targetDoctorId,
    required String headingGroup,
    required String title,
    required String body,
    required String symptomsSummary,
    required bool premium,
    required bool isPublic,
    required String language,
    required List<String> tags,
    required List<String> attachmentIds,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/questions'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'author_id': authorId,
        'target_doctor_id': targetDoctorId,
        'type': premium ? 'second_opinion' : 'forum',
        'heading_group': headingGroup,
        'title': title,
        'body': body,
        'tags': tags,
        'language': language,
        'symptoms_summary': symptomsSummary,
        'premium': premium,
        'is_public': isPublic,
        'attachment_ids': attachmentIds,
      }),
    );
    _ensureSuccess(response, 'submit question');
    return ForumQuestion.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ForumQuestion> updateQuestion({
    required String questionId,
    required String actorId,
    String? title,
    String? body,
    String? headingGroup,
    String? language,
    String? symptomsSummary,
    bool? isPublic,
    List<String>? attachmentIds,
  }) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/questions/$questionId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'actor_id': actorId,
        'title': title,
        'body': body,
        'heading_group': headingGroup,
        'language': language,
        'symptoms_summary': symptomsSummary,
        'is_public': isPublic,
        'attachment_ids': attachmentIds,
      }),
    );
    _ensureSuccess(response, 'update question');
    return ForumQuestion.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<DoctorResponse> submitDoctorResponse({
    required String questionId,
    required String doctorId,
    required String keyPoints,
    required String whatItMeans,
    required String whatToDiscussWithDoctor,
    required String fullText,
    String responseMode = 'text',
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/doctor/respond'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'question_id': questionId,
        'doctor_id': doctorId,
        'key_points': keyPoints,
        'what_it_means': whatItMeans,
        'what_to_discuss_with_doctor': whatToDiscussWithDoctor,
        'full_text': fullText,
        'response_mode': responseMode,
      }),
    );
    _ensureSuccess(response, 'doctor response');
    return DoctorResponse.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteDoctorResponses({
    required String questionId,
    required String actorId,
    required List<String> responseIds,
  }) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/questions/$questionId/responses'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'actor_id': actorId,
        'response_ids': responseIds,
      }),
    );
    _ensureSuccess(response, 'delete doctor responses');
  }

  Future<ThreadMessage> addThreadMessage({
    required String questionId,
    required String actorId,
    required String body,
    String messageMode = 'text',
    List<String> attachmentIds = const [],
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/questions/$questionId/messages'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'question_id': questionId,
        'actor_id': actorId,
        'body': body,
        'message_mode': messageMode,
        'attachment_ids': attachmentIds,
      }),
    );
    _ensureSuccess(response, 'thread message');
    return ThreadMessage.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<ThreadMessage> moderateThreadMessage({
    required String questionId,
    required String messageId,
    required String actorId,
    required String moderationState,
  }) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/questions/$questionId/messages/$messageId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'actor_id': actorId,
        'moderation_state': moderationState,
      }),
    );
    _ensureSuccess(response, 'moderate thread message');
    return ThreadMessage.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> deleteQuestion({
    required String questionId,
    required String actorId,
  }) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/questions/$questionId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'actor_id': actorId}),
    );
    _ensureSuccess(response, 'delete question');
  }

  Future<void> deleteUserAccount({
    required String userId,
    required String actorId,
  }) async {
    final response = await _client.delete(
      Uri.parse('$_baseUrl/users/$userId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'actor_id': actorId}),
    );
    _ensureSuccess(response, 'delete user account');
  }

  Future<UploadedAttachment> uploadAttachment({
    required String ownerId,
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
    String expiryOption = '7d',
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/upload/file'),
    )
      ..fields['owner_id'] = ownerId
      ..fields['expiry_option'] = expiryOption
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: fileName,
          contentType: _contentTypeFor(mimeType),
        ),
      );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _ensureSuccess(response, 'upload attachment');
    return UploadedAttachment.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> revokeAttachment({
    required String attachmentId,
    required String actorId,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/upload/$attachmentId/revoke?actor_id=$actorId'),
    );
    _ensureSuccess(response, 'revoke attachment');
  }

  Future<TitleTemplate> createTitleTemplate({
    required String actorId,
    required String title,
    required String specialty,
    required String language,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/title-templates'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'actor_id': actorId,
        'title': title,
        'specialty': specialty,
        'language': language,
      }),
    );
    _ensureSuccess(response, 'create title template');
    return TitleTemplate.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<BlogArticle> createBlogArticle({
    required String authorId,
    required String title,
    required String summary,
    required String body,
    required String category,
    required String language,
    String sourceUrl = '',
    String imageUrl = '',
    String youtubeUrl = '',
    String youtubeVideoId = '',
    List<String> sectionOrder = const [],
    Map<String, BlogArticleSection> sections = const {},
  }) async {
    final response = await _client
        .post(
          Uri.parse('$_baseUrl/blog/articles'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'author_id': authorId,
            'title': title,
            'summary': summary,
            'body': body,
            'category': category,
            'language': language,
            'source_url': sourceUrl,
            'image_url': imageUrl,
            'youtube_url': youtubeUrl,
            'youtube_video_id': youtubeVideoId,
            'body_format': 'markdown',
            'default_language': 'en',
            'section_order': sectionOrder,
            'sections':
                sections.map((key, value) => MapEntry(key, value.toJson())),
          }),
        )
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'create blog article');
    return BlogArticle.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<BlogArticle> updateBlogArticle({
    required String articleId,
    required String actorId,
    required String title,
    required String summary,
    required String body,
    required String category,
    required String language,
    String sourceUrl = '',
    String imageUrl = '',
    String youtubeUrl = '',
    String youtubeVideoId = '',
    List<String> sectionOrder = const [],
    Map<String, BlogArticleSection> sections = const {},
  }) async {
    final response = await _client
        .patch(
          Uri.parse('$_baseUrl/blog/articles/$articleId'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'actor_id': actorId,
            'title': title,
            'summary': summary,
            'body': body,
            'category': category,
            'language': language,
            'source_url': sourceUrl,
            'image_url': imageUrl,
            'youtube_url': youtubeUrl,
            'youtube_video_id': youtubeVideoId,
            'body_format': 'markdown',
            'default_language': 'en',
            'section_order': sectionOrder,
            'sections':
                sections.map((key, value) => MapEntry(key, value.toJson())),
          }),
        )
        .timeout(_requestTimeout);
    _ensureSuccess(response, 'update blog article');
    return BlogArticle.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<BlogArticleComment> addBlogArticleComment({
    required String articleId,
    required String actorId,
    required String body,
    String parentId = '',
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/blog/articles/$articleId/comments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'actor_id': actorId,
        'body': body,
        if (parentId.isNotEmpty) 'parent_id': parentId,
        'message_mode': 'text',
      }),
    );
    _ensureSuccess(response, 'add article comment');
    return BlogArticleComment.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<BlogArticleComment> moderateBlogArticleComment({
    required String articleId,
    required String commentId,
    required String actorId,
    String moderationState = 'hidden',
  }) async {
    final response = await _client.patch(
      Uri.parse('$_baseUrl/blog/articles/$articleId/comments/$commentId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'actor_id': actorId,
        'moderation_state': moderationState,
      }),
    );
    _ensureSuccess(response, 'moderate article comment');
    return BlogArticleComment.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<BlogArticle> likeBlogArticle({
    required String articleId,
    required String actorId,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/blog/articles/$articleId/likes'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'actor_id': actorId}),
    );
    _ensureSuccess(response, 'like blog article');
    return BlogArticle.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  http_parser.MediaType _contentTypeFor(String mimeType) {
    final parts = mimeType.split('/');
    if (parts.length == 2) {
      return http_parser.MediaType(parts[0], parts[1]);
    }
    return http_parser.MediaType('application', 'octet-stream');
  }

  void _ensureSuccess(http.Response response, String label) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String detail = response.body;
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['detail'] != null) {
          detail = decoded['detail'].toString();
        }
      } catch (_) {}
      throw Exception(
          'Failed to load $label (${response.statusCode}): $detail');
    }
  }
}
