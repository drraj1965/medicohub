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
  static const Duration _requestTimeout = Duration(seconds: 8);

  String get baseUrl => _baseUrl;

  static String _resolveBaseUrl() {
    const configured = String.fromEnvironment('MEDICOHUB_API_BASE_URL');
    if (configured.isNotEmpty) {
      return configured;
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8012';
    }
    if (Platform.isAndroid) {
      return 'http://10.0.2.2:8012';
    }
    return 'http://127.0.0.1:8012';
  }

  Future<List<ForumQuestion>> fetchQuestions() async {
    final response = await _client
        .get(Uri.parse('$_baseUrl/questions'))
        .timeout(_requestTimeout);
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
        .map((item) => DoctorDirectoryEntry.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<UserProfile> loginAsDemo(String email) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': 'Passw0rd!'}),
    ).timeout(_requestTimeout);
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
    return UserProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<UserProfile?> lookupUserByEmail(String email) async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/users/lookup/by-email?email=${Uri.encodeQueryComponent(email)}'),
    ).timeout(_requestTimeout);
    if (response.statusCode == 404 || response.body.trim().isEmpty || response.body.trim() == 'null') {
      return null;
    }
    _ensureSuccess(response, 'user lookup');
    return UserProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<List<NotificationOutboxItem>> fetchNotifications({
    String? userId,
  }) async {
    final suffix = userId == null || userId.isEmpty
        ? ''
        : '?user_id=${Uri.encodeQueryComponent(userId)}';
    final response = await _client.get(
      Uri.parse('$_baseUrl/notifications/outbox$suffix'),
    ).timeout(_requestTimeout);
    _ensureSuccess(response, 'notifications');
    final data = jsonDecode(response.body) as List<dynamic>;
    return data
        .map((item) =>
            NotificationOutboxItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<NotificationSettings> fetchNotificationSettings() async {
    final response = await _client.get(
      Uri.parse('$_baseUrl/notification-settings'),
    ).timeout(_requestTimeout);
    _ensureSuccess(response, 'notification settings');
    return NotificationSettings.fromJson(
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
        'role': role,
        'languages': languages,
        'specialties': specialties,
        'verified': role == 'doctor' || role == 'admin',
      }),
    );
    _ensureSuccess(response, 'user profile upsert');
    return UserProfile.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
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
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/blog/articles'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'author_id': authorId,
        'title': title,
        'summary': summary,
        'body': body,
        'category': category,
        'language': language,
      }),
    );
    _ensureSuccess(response, 'create blog article');
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
      throw Exception('Failed to load $label (${response.statusCode}): $detail');
    }
  }
}
