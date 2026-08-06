class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.verified,
    required this.languages,
    this.phoneNumber,
    this.phoneCountryCode,
    this.phoneNationalNumber,
    this.specialties = const [],
    this.doctorStatus = 'not_applicable',
    this.canManageDoctors = false,
    this.canModerateContent = false,
    this.permissions = const [],
    this.communicationPreferences = const <String, bool>{},
    this.emailSubscribed = true,
    this.createdAt = '',
    this.updatedAt = '',
    this.lastLoginAt = '',
  });

  final String id;
  final String email;
  final String displayName;
  final String role;
  final bool verified;
  final List<String> languages;
  final String? phoneNumber;
  final String? phoneCountryCode;
  final String? phoneNationalNumber;
  final List<String> specialties;
  final String doctorStatus;
  final bool canManageDoctors;
  final bool canModerateContent;
  final List<String> permissions;
  final Map<String, bool> communicationPreferences;
  final bool emailSubscribed;
  final String createdAt;
  final String updatedAt;
  final String lastLoginAt;

  bool get isAdmin => role == 'admin';
  bool get canAccessGrowthStudio =>
      role == 'admin' ||
      role == 'superAdmin' ||
      role == 'growthManager' ||
      role == 'analyticsViewer';
  bool get canManageGrowthStudio =>
      role == 'admin' || role == 'superAdmin' || role == 'growthManager';
  bool get canManageSocialAccounts =>
      role == 'superAdmin' || permissions.contains('socialAccounts.manage');
  bool get isDoctor => role == 'doctor' || role == 'admin';
  bool get isPatient => role == 'patient';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      role: json['role'] as String? ?? 'patient',
      verified: json['verified'] as bool? ?? false,
      phoneNumber: json['phone_number'] as String?,
      phoneCountryCode: json['phone_country_code'] as String?,
      phoneNationalNumber: json['phone_national_number'] as String?,
      languages: (json['languages'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      specialties: (json['specialties'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      doctorStatus: json['doctor_status'] as String? ?? 'not_applicable',
      canManageDoctors: json['can_manage_doctors'] as bool? ?? false,
      canModerateContent: json['can_moderate_content'] as bool? ?? false,
      permissions: (json['permissions'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      communicationPreferences: ((json['communication_preferences'] ??
                  json['communicationPreferences']) as Map<String, dynamic>? ??
              const <String, dynamic>{})
          .map((key, value) => MapEntry(key, value == true)),
      emailSubscribed:
          (json['email_subscribed'] ?? json['emailSubscribed']) as bool? ??
              true,
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      lastLoginAt: json['last_login_at'] as String? ?? '',
    );
  }

  factory UserProfile.fromFirebase({
    required String id,
    required String email,
    required String displayName,
    bool verified = false,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName,
      role: 'patient',
      verified: verified,
      languages: const ['English'],
    );
  }
}

class DoctorDirectoryEntry {
  const DoctorDirectoryEntry({
    required this.id,
    required this.displayName,
    required this.email,
    required this.role,
    required this.languages,
    required this.specialties,
    this.phoneNumber,
    this.phoneCountryCode,
    this.phoneNationalNumber,
  });

  final String id;
  final String displayName;
  final String email;
  final String role;
  final List<String> languages;
  final List<String> specialties;
  final String? phoneNumber;
  final String? phoneCountryCode;
  final String? phoneNationalNumber;

  factory DoctorDirectoryEntry.fromJson(Map<String, dynamic> json) {
    return DoctorDirectoryEntry(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'doctor',
      phoneNumber: json['phone_number'] as String?,
      phoneCountryCode: json['phone_country_code'] as String?,
      phoneNationalNumber: json['phone_national_number'] as String?,
      languages: (json['languages'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      specialties: (json['specialties'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class ContentShareReport {
  const ContentShareReport({
    required this.campaignId,
    required this.contentType,
    required this.contentId,
    required this.contentUrl,
    required this.subject,
    required this.totalRequested,
    required this.queuedCount,
    required this.skippedUnsubscribedCount,
    required this.skippedPreferenceCount,
    required this.skippedMissingEmailCount,
    required this.duplicateSkippedCount,
    required this.failedCount,
  });

  final String campaignId;
  final String contentType;
  final String contentId;
  final String contentUrl;
  final String subject;
  final int totalRequested;
  final int queuedCount;
  final int skippedUnsubscribedCount;
  final int skippedPreferenceCount;
  final int skippedMissingEmailCount;
  final int duplicateSkippedCount;
  final int failedCount;

  factory ContentShareReport.fromJson(Map<String, dynamic> json) {
    return ContentShareReport(
      campaignId: json['campaign_id'] as String? ?? '',
      contentType: json['content_type'] as String? ?? '',
      contentId: json['content_id'] as String? ?? '',
      contentUrl: json['content_url'] as String? ?? '',
      subject: json['subject'] as String? ?? '',
      totalRequested: json['total_requested'] as int? ?? 0,
      queuedCount: json['queued_count'] as int? ?? 0,
      skippedUnsubscribedCount: json['skipped_unsubscribed_count'] as int? ?? 0,
      skippedPreferenceCount: json['skipped_preference_count'] as int? ?? 0,
      skippedMissingEmailCount:
          json['skipped_missing_email_count'] as int? ?? 0,
      duplicateSkippedCount: json['duplicate_skipped_count'] as int? ?? 0,
      failedCount: json['failed_count'] as int? ?? 0,
    );
  }
}

class TitleTemplate {
  const TitleTemplate({
    required this.id,
    required this.title,
    required this.specialty,
    required this.language,
    required this.active,
    required this.createdBy,
  });

  final String id;
  final String title;
  final String specialty;
  final String language;
  final bool active;
  final String createdBy;

  factory TitleTemplate.fromJson(Map<String, dynamic> json) {
    return TitleTemplate(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      specialty: json['specialty'] as String? ?? 'General Health',
      language: json['language'] as String? ?? 'English',
      active: json['active'] as bool? ?? true,
      createdBy: json['created_by'] as String? ?? 'system',
    );
  }
}

class DisclaimerDocument {
  const DisclaimerDocument({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  factory DisclaimerDocument.fromJson(Map<String, dynamic> json) {
    return DisclaimerDocument(
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'body': body,
      };
}

class AppSettings {
  const AppSettings({
    required this.questionTopics,
    required this.disclaimerDocuments,
    required this.defaultRegionNote,
  });

  final List<String> questionTopics;
  final Map<String, DisclaimerDocument> disclaimerDocuments;
  final String defaultRegionNote;

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    final disclaimers = json['disclaimer_documents'] as Map<String, dynamic>? ??
        const <String, dynamic>{};
    return AppSettings(
      questionTopics: (json['question_topics'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      disclaimerDocuments: disclaimers.map(
        (key, value) => MapEntry(
          key,
          DisclaimerDocument.fromJson(value as Map<String, dynamic>),
        ),
      ),
      defaultRegionNote: json['default_region_note'] as String? ?? '',
    );
  }
}

class ForumQuestion {
  const ForumQuestion({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.headingGroup,
    required this.language,
    required this.tags,
    required this.premium,
    required this.status,
    required this.aiSummary,
    required this.responseCount,
    required this.authorId,
    required this.targetDoctorId,
    required this.responses,
    required this.threadMessages,
    required this.createdAt,
    required this.updatedAt,
    this.authorName,
    this.targetDoctorName,
    this.authorEmail,
    this.targetDoctorEmail,
    this.symptomsSummary,
    this.isPublic = false,
  });

  final String id;
  final String title;
  final String body;
  final String type;
  final String headingGroup;
  final String language;
  final List<String> tags;
  final bool premium;
  final String status;
  final String aiSummary;
  final int responseCount;
  final String authorId;
  final String targetDoctorId;
  final List<DoctorResponse> responses;
  final String createdAt;
  final String updatedAt;
  final String? authorName;
  final String? targetDoctorName;
  final String? authorEmail;
  final String? targetDoctorEmail;
  final String? symptomsSummary;
  final bool isPublic;
  final List<ThreadMessage> threadMessages;

  factory ForumQuestion.fromJson(Map<String, dynamic> json) {
    final responses = json['responses'] as List<dynamic>? ?? const [];
    final threadMessages =
        json['thread_messages'] as List<dynamic>? ?? const [];
    return ForumQuestion(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String? ?? 'forum',
      headingGroup: json['heading_group'] as String? ?? 'General',
      language: json['language'] as String? ?? 'English',
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      premium: json['premium'] as bool? ?? false,
      status: json['status'] as String? ?? 'open',
      aiSummary: json['ai_summary'] as String? ?? '',
      responseCount: responses.length,
      authorId: json['author_id'] as String? ?? '',
      targetDoctorId: json['target_doctor_id'] as String? ?? '',
      responses: responses
          .map((item) => DoctorResponse.fromJson(item as Map<String, dynamic>))
          .toList(),
      threadMessages: threadMessages
          .map((item) => ThreadMessage.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
      authorName: json['author_name'] as String?,
      targetDoctorName: json['target_doctor_name'] as String?,
      authorEmail: json['author_email'] as String?,
      targetDoctorEmail: json['target_doctor_email'] as String?,
      symptomsSummary: json['symptoms_summary'] as String?,
      isPublic: json['is_public'] as bool? ?? false,
    );
  }
}

class ThreadMessage {
  const ThreadMessage({
    required this.id,
    required this.questionId,
    required this.actorId,
    required this.actorRole,
    required this.actorName,
    required this.body,
    required this.messageMode,
    required this.attachmentIds,
    required this.moderationState,
    required this.createdAt,
  });

  final String id;
  final String questionId;
  final String actorId;
  final String actorRole;
  final String actorName;
  final String body;
  final String messageMode;
  final List<String> attachmentIds;
  final String moderationState;
  final String createdAt;

  factory ThreadMessage.fromJson(Map<String, dynamic> json) {
    return ThreadMessage(
      id: json['id'] as String? ?? '',
      questionId: json['question_id'] as String? ?? '',
      actorId: json['actor_id'] as String? ?? '',
      actorRole: json['actor_role'] as String? ?? 'patient',
      actorName: json['actor_name'] as String? ?? 'Unknown user',
      body: json['body'] as String? ?? '',
      messageMode: json['message_mode'] as String? ?? 'text',
      attachmentIds: (json['attachment_ids'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      moderationState: json['moderation_state'] as String? ?? 'visible',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class OtpRequestResult {
  const OtpRequestResult({
    required this.otpRequestId,
    required this.deliveryStatus,
    required this.channel,
    required this.destinationHint,
    required this.expiresAt,
    this.previewMessage,
    this.deliveryError,
  });

  final String otpRequestId;
  final String deliveryStatus;
  final String channel;
  final String destinationHint;
  final String expiresAt;
  final String? previewMessage;
  final String? deliveryError;

  factory OtpRequestResult.fromJson(Map<String, dynamic> json) {
    return OtpRequestResult(
      otpRequestId: json['otp_request_id'] as String? ?? '',
      deliveryStatus: json['delivery_status'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
      destinationHint: json['destination_hint'] as String? ?? '',
      expiresAt: json['expires_at'] as String? ?? '',
      previewMessage: json['preview_message'] as String?,
      deliveryError: json['delivery_error'] as String?,
    );
  }
}

class DoctorResponse {
  const DoctorResponse({
    required this.id,
    required this.questionId,
    required this.doctorId,
    required this.labels,
    required this.keyPoints,
    required this.whatItMeans,
    required this.whatToDiscussWithDoctor,
    required this.fullText,
    required this.responseMode,
    required this.createdAt,
  });

  final String id;
  final String questionId;
  final String doctorId;
  final List<String> labels;
  final String keyPoints;
  final String whatItMeans;
  final String whatToDiscussWithDoctor;
  final String fullText;
  final String responseMode;
  final String createdAt;

  factory DoctorResponse.fromJson(Map<String, dynamic> json) {
    return DoctorResponse(
      id: json['id'] as String? ?? '',
      questionId: json['question_id'] as String? ?? '',
      doctorId: json['doctor_id'] as String? ?? '',
      labels: (json['labels'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      keyPoints: json['key_points'] as String? ?? '',
      whatItMeans: json['what_it_means'] as String? ?? '',
      whatToDiscussWithDoctor:
          json['what_to_discuss_with_doctor'] as String? ?? '',
      fullText: json['full_text'] as String? ?? '',
      responseMode: json['response_mode'] as String? ?? 'text',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class EducationItem {
  const EducationItem({
    required this.id,
    required this.title,
    required this.category,
    required this.type,
    required this.summary,
    required this.language,
    required this.durationMinutes,
    required this.url,
  });

  final String id;
  final String title;
  final String category;
  final String type;
  final String summary;
  final String language;
  final int durationMinutes;
  final String url;

  factory EducationItem.fromJson(Map<String, dynamic> json) {
    return EducationItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      category: json['category'] as String? ?? '',
      type: json['type'] as String? ?? 'article',
      summary: json['summary'] as String? ?? '',
      language: json['language'] as String? ?? 'English',
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      url: json['url'] as String? ?? '',
    );
  }
}

class BlogArticleSection {
  const BlogArticleSection({
    required this.id,
    required this.label,
    required this.customTitle,
    required this.order,
    required this.richTextHtml,
    required this.plainText,
    this.quillDeltaJson = const <Map<String, dynamic>>[],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String label;
  final String customTitle;
  final int order;
  final String richTextHtml;
  final String plainText;
  final List<Map<String, dynamic>> quillDeltaJson;
  final String createdAt;
  final String updatedAt;

  String get title => customTitle.trim().isNotEmpty ? customTitle : label;
  bool get hasContent =>
      richTextHtml.trim().isNotEmpty || plainText.trim().isNotEmpty;

  factory BlogArticleSection.fromJson(Map<String, dynamic> json) {
    return BlogArticleSection(
      id: json['id'] as String? ?? '',
      label: json['label'] as String? ?? 'Section',
      customTitle: json['customTitle'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      richTextHtml: json['richTextHtml'] as String? ?? '',
      plainText: json['plainText'] as String? ?? '',
      quillDeltaJson: (json['quillDeltaJson'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      createdAt: json['createdAt'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'customTitle': customTitle,
        'order': order,
        'richTextHtml': richTextHtml,
        'plainText': plainText,
        'quillDeltaJson': quillDeltaJson,
      };
}

class BlogArticle {
  const BlogArticle({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.summary,
    required this.body,
    required this.category,
    required this.language,
    required this.sourceUrl,
    required this.imageUrl,
    required this.youtubeUrl,
    required this.youtubeVideoId,
    required this.bodyFormat,
    required this.defaultLanguage,
    required this.sectionOrder,
    required this.sections,
    required this.likeCount,
    required this.likedBy,
    required this.comments,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String summary;
  final String body;
  final String category;
  final String language;
  final String sourceUrl;
  final String imageUrl;
  final String youtubeUrl;
  final String youtubeVideoId;
  final String bodyFormat;
  final String defaultLanguage;
  final List<String> sectionOrder;
  final Map<String, BlogArticleSection> sections;
  final int likeCount;
  final List<String> likedBy;
  final List<BlogArticleComment> comments;
  final String status;
  final String createdAt;
  final String updatedAt;

  factory BlogArticle.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'] as Map<String, dynamic>? ?? const {};
    final sections = rawSections.map(
      (key, value) => MapEntry(
        key,
        BlogArticleSection.fromJson(value as Map<String, dynamic>),
      ),
    );
    final rawSectionOrder =
        (json['section_order'] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .where((id) => id.trim().isNotEmpty)
            .toList();
    final sectionOrder = rawSectionOrder.isNotEmpty
        ? rawSectionOrder
        : (sections.values.toList()..sort((a, b) => a.order.compareTo(b.order)))
            .map((section) => section.id)
            .where((id) => id.trim().isNotEmpty)
            .toList();
    return BlogArticle(
      id: json['id'] as String? ?? '',
      authorId: json['author_id'] as String? ?? '',
      authorName: json['author_name'] as String? ?? 'Unknown doctor',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      body: json['body'] as String? ?? '',
      category: json['category'] as String? ?? 'General Health',
      language: json['language'] as String? ?? 'English',
      sourceUrl: json['source_url'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      youtubeUrl: json['youtube_url'] as String? ?? '',
      youtubeVideoId: json['youtube_video_id'] as String? ?? '',
      bodyFormat: json['body_format'] as String? ?? 'markdown',
      defaultLanguage: json['default_language'] as String? ?? 'en',
      sectionOrder: sectionOrder,
      sections: sections,
      likeCount: json['like_count'] as int? ?? 0,
      likedBy: (json['liked_by'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      comments: (json['comments'] as List<dynamic>? ?? const [])
          .map((item) =>
              BlogArticleComment.fromJson(item as Map<String, dynamic>))
          .toList(),
      status: json['status'] as String? ?? 'published',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }

  bool likedByUser(String userId) => likedBy.contains(userId);

  BlogArticle copyWith({
    int? likeCount,
    List<String>? likedBy,
    List<BlogArticleComment>? comments,
  }) {
    return BlogArticle(
      id: id,
      authorId: authorId,
      authorName: authorName,
      title: title,
      summary: summary,
      body: body,
      category: category,
      language: language,
      sourceUrl: sourceUrl,
      imageUrl: imageUrl,
      youtubeUrl: youtubeUrl,
      youtubeVideoId: youtubeVideoId,
      bodyFormat: bodyFormat,
      defaultLanguage: defaultLanguage,
      sectionOrder: sectionOrder,
      sections: sections,
      likeCount: likeCount ?? this.likeCount,
      likedBy: likedBy ?? this.likedBy,
      comments: comments ?? this.comments,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

class BlogArticleComment {
  const BlogArticleComment({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.actorRole,
    required this.body,
    required this.parentId,
    required this.messageMode,
    required this.moderationState,
    required this.createdAt,
  });

  final String id;
  final String actorId;
  final String actorName;
  final String actorRole;
  final String body;
  final String parentId;
  final String messageMode;
  final String moderationState;
  final String createdAt;

  factory BlogArticleComment.fromJson(Map<String, dynamic> json) {
    return BlogArticleComment(
      id: json['id'] as String? ?? '',
      actorId: json['actor_id'] as String? ?? '',
      actorName: json['actor_name'] as String? ?? 'MedicoHub user',
      actorRole: json['actor_role'] as String? ?? 'patient',
      body: json['body'] as String? ?? '',
      parentId: json['parent_id'] as String? ?? '',
      messageMode: json['message_mode'] as String? ?? 'text',
      moderationState: json['moderation_state'] as String? ?? 'visible',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class NotificationOutboxItem {
  const NotificationOutboxItem({
    required this.id,
    required this.eventType,
    required this.channel,
    required this.recipientUserId,
    required this.recipientName,
    required this.subject,
    required this.body,
    required this.status,
    required this.createdAt,
    this.recipientEmail,
    this.recipientPhoneNumber,
    this.deepLink,
  });

  final String id;
  final String eventType;
  final String channel;
  final String recipientUserId;
  final String recipientName;
  final String subject;
  final String body;
  final String status;
  final String createdAt;
  final String? recipientEmail;
  final String? recipientPhoneNumber;
  final String? deepLink;

  factory NotificationOutboxItem.fromJson(Map<String, dynamic> json) {
    return NotificationOutboxItem(
      id: json['id'] as String? ?? '',
      eventType: json['event_type'] as String? ?? '',
      channel: json['channel'] as String? ?? '',
      recipientUserId: json['recipient_user_id'] as String? ?? '',
      recipientName: json['recipient_name'] as String? ?? '',
      recipientEmail: json['recipient_email'] as String?,
      recipientPhoneNumber: json['recipient_phone_number'] as String?,
      subject: json['subject'] as String? ?? '',
      body: json['body'] as String? ?? '',
      deepLink: json['deep_link'] as String?,
      status: json['status'] as String? ?? 'preview_ready',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class NotificationSettings {
  const NotificationSettings({
    required this.id,
    required this.whatsAppActivationEnabled,
    required this.whatsAppActivationTarget,
    required this.whatsAppActivationPhrase,
    required this.emailStatusNote,
    required this.updatedBy,
    required this.updatedAt,
  });

  final String id;
  final bool whatsAppActivationEnabled;
  final String whatsAppActivationTarget;
  final String whatsAppActivationPhrase;
  final String emailStatusNote;
  final String updatedBy;
  final String updatedAt;

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      id: json['id'] as String? ?? 'notification_settings',
      whatsAppActivationEnabled:
          json['whatsapp_activation_enabled'] as bool? ?? true,
      whatsAppActivationTarget:
          json['whatsapp_activation_target'] as String? ?? '+14155238886',
      whatsAppActivationPhrase:
          json['whatsapp_activation_phrase'] as String? ?? 'join cloud-tired',
      emailStatusNote: json['email_status_note'] as String? ??
          'Email notifications are coming later.',
      updatedBy: json['updated_by'] as String? ?? 'system',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

class UpdateInfo {
  const UpdateInfo({
    required this.latestVersion,
    required this.downloadUrl,
    required this.releaseNotes,
    this.releasePageUrl,
    this.windowsDownloadUrl,
    this.androidDownloadUrl,
    this.iosStoreUrl,
  });

  final String latestVersion;
  final String downloadUrl;
  final List<String> releaseNotes;
  final String? releasePageUrl;
  final String? windowsDownloadUrl;
  final String? androidDownloadUrl;
  final String? iosStoreUrl;

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      latestVersion: json['latest_version'] as String? ?? '',
      downloadUrl: json['download_url'] as String? ?? '',
      releasePageUrl: json['release_page_url'] as String?,
      windowsDownloadUrl: json['windows_download_url'] as String?,
      androidDownloadUrl: json['android_download_url'] as String?,
      iosStoreUrl: json['ios_store_url'] as String?,
      releaseNotes: (json['release_notes'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class AdCampaign {
  const AdCampaign({
    required this.id,
    required this.sponsorName,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.targetUrl,
    required this.keywords,
    required this.categories,
    required this.placements,
    required this.languages,
    required this.priority,
    required this.active,
    required this.createdBy,
    required this.updatedAt,
  });

  final String id;
  final String sponsorName;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final String targetUrl;
  final List<String> keywords;
  final List<String> categories;
  final List<String> placements;
  final List<String> languages;
  final int priority;
  final bool active;
  final String createdBy;
  final String updatedAt;

  factory AdCampaign.fromJson(Map<String, dynamic> json) {
    List<String> stringList(String key) =>
        (json[key] as List<dynamic>? ?? const [])
            .map((item) => item.toString())
            .toList();

    return AdCampaign(
      id: json['id'] as String? ?? '',
      sponsorName: json['sponsor_name'] as String? ?? 'Sponsored',
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      ctaLabel: json['cta_label'] as String? ?? 'Learn more',
      targetUrl: json['target_url'] as String? ?? '',
      keywords: stringList('keywords'),
      categories: stringList('categories'),
      placements: stringList('placements'),
      languages: stringList('languages'),
      priority: json['priority'] as int? ?? 50,
      active: json['active'] as bool? ?? true,
      createdBy: json['created_by'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

class GrowthOverview {
  const GrowthOverview({
    required this.dateRange,
    required this.sampleSize,
    required this.metrics,
    required this.topSources,
    required this.topContent,
    required this.smallSampleWarning,
  });

  final String dateRange;
  final Map<String, int> sampleSize;
  final Map<String, num> metrics;
  final List<MapEntry<String, int>> topSources;
  final List<MapEntry<String, int>> topContent;
  final bool smallSampleWarning;

  factory GrowthOverview.fromJson(Map<String, dynamic> json) {
    Map<String, int> intMap(String key) =>
        ((json[key] ?? const <String, dynamic>{}) as Map<String, dynamic>).map(
          (entryKey, value) =>
              MapEntry(entryKey, (value as num?)?.toInt() ?? 0),
        );
    List<MapEntry<String, int>> pairList(String key) =>
        (json[key] as List<dynamic>? ?? const [])
            .whereType<List<dynamic>>()
            .map((item) => MapEntry(
                  item.isNotEmpty ? item[0].toString() : '',
                  item.length > 1 ? ((item[1] as num?)?.toInt() ?? 0) : 0,
                ))
            .where((entry) => entry.key.isNotEmpty)
            .toList();
    return GrowthOverview(
      dateRange: json['date_range'] as String? ?? 'all_available',
      sampleSize: intMap('sample_size'),
      metrics: ((json['metrics'] ?? const <String, dynamic>{})
              as Map<String, dynamic>)
          .map((key, value) => MapEntry(key, (value as num?) ?? 0)),
      topSources: pairList('top_sources'),
      topContent: pairList('top_content'),
      smallSampleWarning: json['small_sample_warning'] as bool? ?? false,
    );
  }
}

class GrowthCampaign {
  const GrowthCampaign({
    required this.id,
    required this.name,
    required this.objective,
    required this.status,
    required this.primaryMetric,
    required this.targetAudience,
    required this.primaryCta,
    required this.channels,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String objective;
  final String status;
  final String primaryMetric;
  final String targetAudience;
  final String primaryCta;
  final List<String> channels;
  final String createdAt;
  final String updatedAt;

  factory GrowthCampaign.fromJson(Map<String, dynamic> json) {
    return GrowthCampaign(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      objective: json['objective'] as String? ?? 'activation',
      status: json['status'] as String? ?? 'draft',
      primaryMetric: json['primary_metric'] as String? ?? 'activated_users',
      targetAudience: json['target_audience'] as String? ?? '',
      primaryCta: json['primary_cta'] as String? ?? '',
      channels: (json['channels'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

class GrowthOpportunity {
  const GrowthOpportunity({
    required this.id,
    required this.title,
    required this.source,
    required this.specialty,
    required this.audience,
    required this.language,
    required this.estimatedValue,
    required this.urgency,
    required this.medicalRisk,
    required this.status,
    required this.recommendedCta,
  });

  final String id;
  final String title;
  final String source;
  final String specialty;
  final String audience;
  final String language;
  final int estimatedValue;
  final String urgency;
  final String medicalRisk;
  final String status;
  final String recommendedCta;

  factory GrowthOpportunity.fromJson(Map<String, dynamic> json) {
    return GrowthOpportunity(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      source: json['source'] as String? ?? 'manual',
      specialty: json['specialty'] as String? ?? 'General Health',
      audience: json['audience'] as String? ?? 'patient',
      language: json['language'] as String? ?? 'English',
      estimatedValue: json['estimated_value'] as int? ?? 0,
      urgency: json['urgency'] as String? ?? 'medium',
      medicalRisk: json['medical_risk'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'new',
      recommendedCta: json['recommended_cta'] as String? ?? '',
    );
  }
}

class GrowthDerivative {
  const GrowthDerivative({
    required this.id,
    required this.sourceArticleId,
    required this.assetType,
    required this.platform,
    required this.title,
    required this.approvalStatus,
    required this.publicationStatus,
    required this.outdatedReason,
  });

  final String id;
  final String sourceArticleId;
  final String assetType;
  final String platform;
  final String title;
  final String approvalStatus;
  final String publicationStatus;
  final String outdatedReason;

  factory GrowthDerivative.fromJson(Map<String, dynamic> json) {
    return GrowthDerivative(
      id: json['id'] as String? ?? '',
      sourceArticleId: json['source_article_id'] as String? ?? '',
      assetType: json['asset_type'] as String? ?? '',
      platform: json['platform'] as String? ?? '',
      title: json['title'] as String? ?? '',
      approvalStatus: json['approval_status'] as String? ?? 'draft',
      publicationStatus:
          json['publication_status'] as String? ?? 'not_scheduled',
      outdatedReason: json['outdated_reason'] as String? ?? '',
    );
  }
}

class GrowthIntegrationCatalogItem {
  const GrowthIntegrationCatalogItem({
    required this.provider,
    required this.label,
    required this.authMode,
    required this.oauthConfigured,
    required this.scopes,
    required this.supportsApiPublish,
    required this.recommended,
    required this.notes,
    required this.integrationId,
    required this.connectionStatus,
    required this.approvalStatus,
    required this.publishingMode,
    required this.callbackUrl,
    required this.canManageSocialAccounts,
  });

  final String provider;
  final String label;
  final String authMode;
  final bool oauthConfigured;
  final List<String> scopes;
  final bool supportsApiPublish;
  final bool recommended;
  final String notes;
  final String integrationId;
  final String connectionStatus;
  final String approvalStatus;
  final String publishingMode;
  final String callbackUrl;
  final bool canManageSocialAccounts;

  factory GrowthIntegrationCatalogItem.fromJson(Map<String, dynamic> json) {
    return GrowthIntegrationCatalogItem(
      provider: json['provider'] as String? ?? '',
      label: json['label'] as String? ?? '',
      authMode: json['auth_mode'] as String? ?? 'manual_export',
      oauthConfigured: json['oauth_configured'] as bool? ?? false,
      scopes: (json['scopes'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      supportsApiPublish: json['supports_api_publish'] as bool? ?? false,
      recommended: json['recommended'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
      integrationId: json['integration_id'] as String? ?? '',
      connectionStatus: json['connection_status'] as String? ?? 'not_connected',
      approvalStatus: json['approval_status'] as String? ?? 'draft',
      publishingMode: json['publishing_mode'] as String? ?? 'manual_export',
      callbackUrl: json['callback_url'] as String? ?? '',
      canManageSocialAccounts:
          json['can_manage_social_accounts'] as bool? ?? false,
    );
  }
}

class GrowthIntegration {
  const GrowthIntegration({
    required this.id,
    required this.provider,
    required this.ownerType,
    required this.ownerId,
    required this.displayName,
    required this.accountHandle,
    required this.accountUrl,
    required this.externalAccountId,
    required this.externalAccountName,
    required this.externalAccountType,
    required this.pageId,
    required this.instagramBusinessAccountId,
    required this.channelId,
    required this.authMode,
    required this.connectionStatus,
    required this.approvalStatus,
    required this.publishingMode,
    required this.tokenStatus,
    required this.callbackUrl,
    required this.scopes,
    required this.availableAccounts,
    required this.notes,
    required this.lastHealthCheckAt,
    required this.updatedAt,
  });

  final String id;
  final String provider;
  final String ownerType;
  final String ownerId;
  final String displayName;
  final String accountHandle;
  final String accountUrl;
  final String externalAccountId;
  final String externalAccountName;
  final String externalAccountType;
  final String pageId;
  final String instagramBusinessAccountId;
  final String channelId;
  final String authMode;
  final String connectionStatus;
  final String approvalStatus;
  final String publishingMode;
  final String tokenStatus;
  final String callbackUrl;
  final List<String> scopes;
  final List<Map<String, dynamic>> availableAccounts;
  final String notes;
  final String lastHealthCheckAt;
  final String updatedAt;

  factory GrowthIntegration.fromJson(Map<String, dynamic> json) {
    return GrowthIntegration(
      id: json['id'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      ownerType: json['owner_type'] as String? ?? 'organisation',
      ownerId: json['owner_id'] as String? ?? 'medicohub',
      displayName: json['display_name'] as String? ?? '',
      accountHandle: json['account_handle'] as String? ?? '',
      accountUrl: json['account_url'] as String? ?? '',
      externalAccountId: json['external_account_id'] as String? ?? '',
      externalAccountName: json['external_account_name'] as String? ?? '',
      externalAccountType: json['external_account_type'] as String? ?? '',
      pageId: json['page_id'] as String? ?? '',
      instagramBusinessAccountId:
          json['instagram_business_account_id'] as String? ?? '',
      channelId: json['channel_id'] as String? ?? '',
      authMode: json['auth_mode'] as String? ?? 'manual_export',
      connectionStatus: json['connection_status'] as String? ?? 'not_connected',
      approvalStatus: json['approval_status'] as String? ?? 'draft',
      publishingMode: json['publishing_mode'] as String? ?? 'manual_export',
      tokenStatus: json['token_status'] as String? ?? 'none',
      callbackUrl: json['callback_url'] as String? ?? '',
      scopes: (json['scopes'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      availableAccounts:
          (json['available_accounts'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .toList(),
      notes: json['notes'] as String? ?? '',
      lastHealthCheckAt: json['last_health_check_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

class GrowthPublishingRequest {
  const GrowthPublishingRequest({
    required this.id,
    required this.integrationId,
    required this.derivativeId,
    required this.provider,
    required this.title,
    required this.body,
    required this.status,
    required this.approvalNotes,
    required this.updatedAt,
  });

  final String id;
  final String integrationId;
  final String derivativeId;
  final String provider;
  final String title;
  final String body;
  final String status;
  final String approvalNotes;
  final String updatedAt;

  factory GrowthPublishingRequest.fromJson(Map<String, dynamic> json) {
    return GrowthPublishingRequest(
      id: json['id'] as String? ?? '',
      integrationId: json['integration_id'] as String? ?? '',
      derivativeId: json['derivative_id'] as String? ?? '',
      provider: json['provider'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      status: json['status'] as String? ?? 'pending_admin_approval',
      approvalNotes: json['approval_notes'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
    );
  }
}

class UploadedAttachment {
  const UploadedAttachment({
    required this.id,
    required this.fileName,
    required this.mimeType,
    required this.storageProvider,
    required this.temporaryUrl,
    required this.expiresAt,
    this.storagePath,
    this.extractedTextPreview,
  });

  final String id;
  final String fileName;
  final String mimeType;
  final String storageProvider;
  final String temporaryUrl;
  final String expiresAt;
  final String? storagePath;
  final String? extractedTextPreview;

  factory UploadedAttachment.fromJson(Map<String, dynamic> json) {
    return UploadedAttachment(
      id: json['id'] as String? ?? '',
      fileName: json['file_name'] as String? ?? '',
      mimeType: json['mime_type'] as String? ?? '',
      storageProvider: json['storage_provider'] as String? ?? '',
      temporaryUrl: json['temporary_url'] as String? ?? '',
      expiresAt: json['expires_at'] as String? ?? '',
      storagePath: json['storage_path'] as String?,
      extractedTextPreview: json['extracted_text_preview'] as String?,
    );
  }
}
