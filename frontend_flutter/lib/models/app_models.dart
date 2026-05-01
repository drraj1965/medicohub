class UserProfile {
  const UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
    required this.verified,
    required this.languages,
    this.phoneNumber,
    this.specialties = const [],
    this.doctorStatus = 'not_applicable',
    this.canManageDoctors = false,
    this.canModerateContent = false,
  });

  final String id;
  final String email;
  final String displayName;
  final String role;
  final bool verified;
  final List<String> languages;
  final String? phoneNumber;
  final List<String> specialties;
  final String doctorStatus;
  final bool canManageDoctors;
  final bool canModerateContent;

  bool get isAdmin => role == 'admin';
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
      languages: (json['languages'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      specialties: (json['specialties'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      doctorStatus: json['doctor_status'] as String? ?? 'not_applicable',
      canManageDoctors: json['can_manage_doctors'] as bool? ?? false,
      canModerateContent: json['can_moderate_content'] as bool? ?? false,
    );
  }

  factory UserProfile.fromFirebase({
    required String id,
    required String email,
    required String displayName,
  }) {
    return UserProfile(
      id: id,
      email: email,
      displayName: displayName,
      role: 'patient',
      verified: false,
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
  });

  final String id;
  final String displayName;
  final String email;
  final String role;
  final List<String> languages;
  final List<String> specialties;
  final String? phoneNumber;

  factory DoctorDirectoryEntry.fromJson(Map<String, dynamic> json) {
    return DoctorDirectoryEntry(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'doctor',
      phoneNumber: json['phone_number'] as String?,
      languages: (json['languages'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      specialties: (json['specialties'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
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
    final threadMessages = json['thread_messages'] as List<dynamic>? ?? const [];
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
  final String status;
  final String createdAt;
  final String updatedAt;

  factory BlogArticle.fromJson(Map<String, dynamic> json) {
    return BlogArticle(
      id: json['id'] as String? ?? '',
      authorId: json['author_id'] as String? ?? '',
      authorName: json['author_name'] as String? ?? 'Unknown doctor',
      title: json['title'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      body: json['body'] as String? ?? '',
      category: json['category'] as String? ?? 'General Health',
      language: json['language'] as String? ?? 'English',
      status: json['status'] as String? ?? 'published',
      createdAt: json['created_at'] as String? ?? '',
      updatedAt: json['updated_at'] as String? ?? '',
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
  });

  final String latestVersion;
  final String downloadUrl;
  final List<String> releaseNotes;

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      latestVersion: json['latest_version'] as String? ?? '',
      downloadUrl: json['download_url'] as String? ?? '',
      releaseNotes: (json['release_notes'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
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
