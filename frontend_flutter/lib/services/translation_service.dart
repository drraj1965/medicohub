import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MedicoHubLanguage {
  const MedicoHubLanguage({
    required this.code,
    required this.label,
    required this.nativeLabel,
    this.isRightToLeft = false,
  });

  final String code;
  final String label;
  final String nativeLabel;
  final bool isRightToLeft;
}

const List<MedicoHubLanguage> medicoHubLanguages = [
  MedicoHubLanguage(code: 'en', label: 'English', nativeLabel: 'English'),
  MedicoHubLanguage(
    code: 'ar',
    label: 'Arabic',
    nativeLabel: 'العربية',
    isRightToLeft: true,
  ),
  MedicoHubLanguage(code: 'ml', label: 'Malayalam', nativeLabel: 'മലയാളം'),
  MedicoHubLanguage(code: 'hi', label: 'Hindi', nativeLabel: 'हिन्दी'),
  MedicoHubLanguage(code: 'te', label: 'Telugu', nativeLabel: 'తెలుగు'),
  MedicoHubLanguage(code: 'ta', label: 'Tamil', nativeLabel: 'தமிழ்'),
  MedicoHubLanguage(code: 'gu', label: 'Gujarati', nativeLabel: 'ગુજરાતી'),
  MedicoHubLanguage(code: 'bn', label: 'Bengali', nativeLabel: 'বাংলা'),
];

class TranslationResult {
  const TranslationResult({
    required this.text,
    required this.fromCache,
    required this.provider,
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
    required this.qualityWarning,
    required this.errorMessage,
    this.notice,
  });

  final String text;
  final bool fromCache;
  final String provider;
  final String sourceLanguageCode;
  final String targetLanguageCode;
  final String qualityWarning;
  final String errorMessage;
  final String? notice;

  bool get hasError => errorMessage.trim().isNotEmpty;
}

class TranslationService {
  TranslationService({
    http.Client? client,
  }) : _client = client ?? http.Client();

  static const String _endpoint = String.fromEnvironment(
    'MEDICOHUB_TRANSLATE_ENDPOINT',
    defaultValue: 'https://medicohub-backend.fly.dev/api/translate',
  );
  final http.Client _client;

  static String contentHash(String value) {
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    return _fnv1a32(normalized).toRadixString(16);
  }

  Future<TranslationResult> translate({
    required String text,
    required String targetLanguageCode,
    String sourceLanguageCode = 'en',
    String contentType = 'article',
    bool medicalMode = true,
    bool allowPaidFallback = false,
  }) async {
    final cleanText = text.trim();
    final cleanSource =
        sourceLanguageCode.trim().isEmpty ? 'en' : sourceLanguageCode.trim();
    final cleanTarget =
        targetLanguageCode.trim().isEmpty ? 'en' : targetLanguageCode.trim();
    if (cleanText.isEmpty || cleanTarget == cleanSource) {
      return TranslationResult(
        text: cleanText,
        fromCache: false,
        provider: 'none',
        sourceLanguageCode: cleanSource,
        targetLanguageCode: cleanTarget,
        qualityWarning: '',
        errorMessage: '',
      );
    }

    if (_endpoint.trim().isEmpty) {
      return TranslationResult(
        text: cleanText,
        fromCache: false,
        provider: 'none',
        sourceLanguageCode: cleanSource,
        targetLanguageCode: cleanTarget,
        qualityWarning: '',
        errorMessage:
            'Translation backend is not configured. Please add Microsoft Translator credentials.',
        notice:
            'Translation backend is not configured. Please add Microsoft Translator credentials.',
      );
    }

    try {
      final payload = <String, Object?>{
        'text': cleanText,
        'sourceLang': cleanSource,
        'targetLang': cleanTarget,
        'contentType': contentType,
        'medicalMode': medicalMode,
        'allowPaidFallback': allowPaidFallback,
      };
      final response = await _client
          .post(
            Uri.parse(_endpoint),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 16));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        final error = _errorFromResponse(response.body) ??
            'Translation is temporarily unavailable. Please try again later.';
        return TranslationResult(
          text: cleanText,
          fromCache: false,
          provider: 'none',
          sourceLanguageCode: cleanSource,
          targetLanguageCode: cleanTarget,
          qualityWarning: '',
          errorMessage: error,
          notice: error,
        );
      }

      final decoded = jsonDecode(response.body);
      final responseMap =
          decoded is Map<String, dynamic> ? decoded : <String, dynamic>{};
      final translated =
          (responseMap['translatedText'] ?? responseMap['translation'])
              ?.toString();
      final provider = responseMap['provider']?.toString() ?? 'backend';
      final warning = responseMap['qualityWarning']?.toString() ?? '';
      final error = responseMap['errorMessage']?.toString() ?? '';
      final responseSource =
          responseMap['sourceLang']?.toString() ?? cleanSource;
      final responseTarget =
          responseMap['targetLang']?.toString() ?? cleanTarget;
      final cachedByBackend = responseMap['cached'] == true;

      if (error.trim().isNotEmpty) {
        return TranslationResult(
          text: translated != null && translated.trim().isNotEmpty
              ? translated
              : cleanText,
          fromCache: cachedByBackend,
          provider: provider,
          sourceLanguageCode: responseSource,
          targetLanguageCode: responseTarget,
          qualityWarning: warning,
          errorMessage: error,
          notice: error,
        );
      }
      if (translated == null || translated.trim().isEmpty) {
        return TranslationResult(
          text: cleanText,
          fromCache: false,
          provider: 'none',
          sourceLanguageCode: cleanSource,
          targetLanguageCode: cleanTarget,
          qualityWarning: '',
          errorMessage: 'Translation returned no readable text.',
          notice: 'Translation returned no readable text.',
        );
      }

      if (cleanTarget != cleanSource &&
          translated.trim().toLowerCase() == cleanText.toLowerCase()) {
        return TranslationResult(
          text: cleanText,
          fromCache: cachedByBackend,
          provider: provider,
          sourceLanguageCode: responseSource,
          targetLanguageCode: responseTarget,
          qualityWarning: warning,
          errorMessage: 'Translation failed: provider returned unchanged text.',
          notice: 'Translation failed: provider returned unchanged text.',
        );
      }
      return TranslationResult(
        text: translated,
        fromCache: cachedByBackend,
        provider: provider,
        sourceLanguageCode: responseSource,
        targetLanguageCode: responseTarget,
        qualityWarning: warning,
        errorMessage: '',
      );
    } catch (error) {
      final message = 'Translation could not be completed: $error';
      return TranslationResult(
        text: cleanText,
        fromCache: false,
        provider: 'none',
        sourceLanguageCode: cleanSource,
        targetLanguageCode: cleanTarget,
        qualityWarning: '',
        errorMessage: message,
        notice: message,
      );
    }
  }

  String? _errorFromResponse(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error =
            decoded['errorMessage'] ?? decoded['detail'] ?? decoded['message'];
        return error?.toString();
      }
    } catch (_) {
      if (body.trim().isNotEmpty) {
        return body.trim();
      }
    }
    return null;
  }

  Future<SectionTranslationResult> translateSection({
    required String articleId,
    required String sectionId,
    required String sourceLanguageCode,
    required String targetLanguageCode,
    required String richTextHtml,
    required String plainText,
    String sourceUpdatedAt = '',
  }) async {
    final sourceText =
        plainText.trim().isNotEmpty ? plainText.trim() : richTextHtml.trim();
    final hash =
        contentHash(richTextHtml.trim().isNotEmpty ? richTextHtml : sourceText);
    if (sourceText.isEmpty) {
      return SectionTranslationResult.failure(
        articleId: articleId,
        sectionId: sectionId,
        sourceLanguageCode: sourceLanguageCode,
        targetLanguageCode: targetLanguageCode,
        contentHash: hash,
        message: 'This section is empty.',
      );
    }
    if (sourceLanguageCode == targetLanguageCode) {
      return SectionTranslationResult(
        success: true,
        articleId: articleId,
        sectionId: sectionId,
        sourceLanguageCode: sourceLanguageCode,
        targetLanguageCode: targetLanguageCode,
        contentHash: hash,
        translatedRichTextHtml: richTextHtml,
        translatedPlainText: sourceText,
        provider: 'none',
        cacheSource: 'local',
        warning: '',
        message: '',
      );
    }

    final prefs = await SharedPreferences.getInstance();
    final cacheKey =
        'medicohub_translation_v1:$articleId:$sectionId:$targetLanguageCode:$hash';
    final cached = prefs.getString(cacheKey);
    if (cached != null) {
      final decoded = jsonDecode(cached);
      if (decoded is Map<String, dynamic>) {
        return SectionTranslationResult.fromJson(decoded, cacheSource: 'local');
      }
    }

    try {
      final response = await _client
          .post(
            Uri.parse(_endpoint.replaceFirst(
                '/api/translate', '/api/translate-section')),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'articleId': articleId,
              'sectionId': sectionId,
              'sourceLang': sourceLanguageCode,
              'targetLang': targetLanguageCode,
              'richTextHtml': richTextHtml,
              'plainText': sourceText,
              'sourceUpdatedAt': sourceUpdatedAt,
            }),
          )
          .timeout(const Duration(seconds: 20));
      final decoded = jsonDecode(response.body);
      final result = decoded is Map<String, dynamic>
          ? SectionTranslationResult.fromJson(decoded)
          : SectionTranslationResult.failure(
              articleId: articleId,
              sectionId: sectionId,
              sourceLanguageCode: sourceLanguageCode,
              targetLanguageCode: targetLanguageCode,
              contentHash: hash,
              message: 'Could not translate now. Please try again later.',
            );
      if (result.success) {
        await prefs.setString(
          cacheKey,
          jsonEncode({
            'success': true,
            'articleId': articleId,
            'sectionId': sectionId,
            'sourceLang': sourceLanguageCode,
            'targetLang': targetLanguageCode,
            'contentHash': result.contentHash,
            'translatedRichTextHtml': result.translatedRichTextHtml,
            'translatedPlainText': result.translatedPlainText,
            'provider': result.provider,
            'cacheSource': result.cacheSource,
            'warning': result.warning,
            'sourceUpdatedAt': sourceUpdatedAt,
            'savedAt': DateTime.now().toIso8601String(),
          }),
        );
      }
      return result;
    } catch (_) {
      return SectionTranslationResult.failure(
        articleId: articleId,
        sectionId: sectionId,
        sourceLanguageCode: sourceLanguageCode,
        targetLanguageCode: targetLanguageCode,
        contentHash: hash,
        message: 'Could not translate now. Please try again later.',
      );
    }
  }

  Future<List<SectionTranslationResult>> savedSectionTranslations({
    required String articleId,
    required String sectionId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'medicohub_translation_v1:$articleId:$sectionId:';
    final results = <SectionTranslationResult>[];
    for (final key in prefs.getKeys().where((key) => key.startsWith(prefix))) {
      final cached = prefs.getString(key);
      if (cached == null) {
        continue;
      }
      try {
        final decoded = jsonDecode(cached);
        if (decoded is Map<String, dynamic>) {
          results.add(
              SectionTranslationResult.fromJson(decoded, cacheSource: 'local'));
        }
      } catch (_) {
        continue;
      }
    }
    results
        .sort((a, b) => a.targetLanguageCode.compareTo(b.targetLanguageCode));
    return results;
  }

  Future<void> clearSavedSectionTranslations({
    required String articleId,
    required String sectionId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final prefix = 'medicohub_translation_v1:$articleId:$sectionId:';
    for (final key
        in prefs.getKeys().where((key) => key.startsWith(prefix)).toList()) {
      await prefs.remove(key);
    }
  }

  static int _fnv1a32(String text) {
    var hash = 0x811c9dc5;
    for (final byte in utf8.encode(text)) {
      hash ^= byte;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }
}

class SectionTranslationResult {
  const SectionTranslationResult({
    required this.success,
    required this.articleId,
    required this.sectionId,
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
    required this.contentHash,
    required this.translatedRichTextHtml,
    required this.translatedPlainText,
    required this.provider,
    required this.cacheSource,
    required this.warning,
    required this.message,
  });

  final bool success;
  final String articleId;
  final String sectionId;
  final String sourceLanguageCode;
  final String targetLanguageCode;
  final String contentHash;
  final String translatedRichTextHtml;
  final String translatedPlainText;
  final String provider;
  final String cacheSource;
  final String warning;
  final String message;

  factory SectionTranslationResult.fromJson(
    Map<String, dynamic> json, {
    String? cacheSource,
  }) {
    return SectionTranslationResult(
      success: json['success'] == true,
      articleId: json['articleId'] as String? ?? '',
      sectionId: json['sectionId'] as String? ?? '',
      sourceLanguageCode: json['sourceLang'] as String? ?? '',
      targetLanguageCode: json['targetLang'] as String? ?? '',
      contentHash: json['contentHash'] as String? ?? '',
      translatedRichTextHtml: json['translatedRichTextHtml'] as String? ?? '',
      translatedPlainText: json['translatedPlainText'] as String? ?? '',
      provider: json['provider'] as String? ?? 'microsoft-azure',
      cacheSource: cacheSource ?? json['cacheSource'] as String? ?? 'provider',
      warning: json['warning'] as String? ?? '',
      message: json['message'] as String? ?? '',
    );
  }

  factory SectionTranslationResult.failure({
    required String articleId,
    required String sectionId,
    required String sourceLanguageCode,
    required String targetLanguageCode,
    required String contentHash,
    required String message,
  }) {
    return SectionTranslationResult(
      success: false,
      articleId: articleId,
      sectionId: sectionId,
      sourceLanguageCode: sourceLanguageCode,
      targetLanguageCode: targetLanguageCode,
      contentHash: contentHash,
      translatedRichTextHtml: '',
      translatedPlainText: '',
      provider: 'microsoft-azure',
      cacheSource: 'none',
      warning: '',
      message: message,
    );
  }
}
