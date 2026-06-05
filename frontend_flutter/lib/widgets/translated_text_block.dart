import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/translation_service.dart';

class TranslatedTextBlock extends StatefulWidget {
  const TranslatedTextBlock({
    super.key,
    required this.text,
    this.title = 'Read in',
    this.sourceLanguageCode = 'en',
    this.style,
    this.maxLines,
    this.overflow,
    this.showControls = true,
    this.contentType = 'article',
    this.medicalMode = true,
    this.allowPaidFallback = false,
    this.showDoctorReviewAction = false,
    this.showAdminControls = false,
  });

  final String text;
  final String title;
  final String sourceLanguageCode;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool showControls;
  final String contentType;
  final bool medicalMode;
  final bool allowPaidFallback;
  final bool showDoctorReviewAction;
  final bool showAdminControls;

  @override
  State<TranslatedTextBlock> createState() => _TranslatedTextBlockState();
}

class _TranslatedTextBlockState extends State<TranslatedTextBlock> {
  final TranslationService _translationService = TranslationService();
  String _sourceLanguageCode = 'en';
  String _selectedLanguageCode = 'en';
  String? _translatedText;
  String? _notice;
  String? _qualityWarning;
  String? _errorMessage;
  String? _provider;
  bool _fromCache = false;
  bool _loading = false;
  bool _hasAttemptedTranslation = false;

  @override
  void initState() {
    super.initState();
    _sourceLanguageCode = widget.sourceLanguageCode;
    _selectedLanguageCode = widget.sourceLanguageCode;
  }

  MedicoHubLanguage get _selectedLanguage => medicoHubLanguages.firstWhere(
        (language) => language.code == _selectedLanguageCode,
        orElse: () => medicoHubLanguages.first,
      );

  @override
  void didUpdateWidget(covariant TranslatedTextBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text ||
        oldWidget.sourceLanguageCode != widget.sourceLanguageCode) {
      _sourceLanguageCode = widget.sourceLanguageCode;
      if (_selectedLanguageCode == oldWidget.sourceLanguageCode) {
        _selectedLanguageCode = widget.sourceLanguageCode;
      }
      _clearLoadedTranslation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSuccessfulTranslation = _translatedText != null &&
        _translatedText!.trim().isNotEmpty &&
        (_errorMessage == null || _errorMessage!.trim().isEmpty) &&
        _selectedLanguageCode != _sourceLanguageCode;
    final shownText = hasSuccessfulTranslation ? _translatedText! : widget.text;
    final textDirection = hasSuccessfulTranslation && _selectedLanguage.isRightToLeft
        ? TextDirection.rtl
        : TextDirection.ltr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showControls) ...[
          _LanguageControlRow(
            title: widget.title,
            sourceLanguageCode: _sourceLanguageCode,
            selectedLanguageCode: _selectedLanguageCode,
            loading: _loading,
            onTargetSelected: (value) {
              setState(() {
                _selectedLanguageCode = value;
                _clearLoadedTranslation();
              });
            },
            onTranslate: _loadTranslation,
            onReset: _resetTranslation,
          ),
          const SizedBox(height: 8),
        ],
        Directionality(
          textDirection: textDirection,
          child: Align(
            alignment: hasSuccessfulTranslation && _selectedLanguage.isRightToLeft
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Text(
              shownText,
              style: widget.style,
              maxLines: widget.maxLines,
              overflow: widget.overflow,
            ),
          ),
        ),
        if (_notice != null) ...[
          const SizedBox(height: 6),
          Text(
            _notice!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
          ),
        ],
        if (_qualityWarning != null && _qualityWarning!.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          _TranslationNotice(
            icon: Icons.health_and_safety_rounded,
            text: _qualityWarning!,
          ),
        ],
        if (_hasAttemptedTranslation && widget.showControls) ...[
          const SizedBox(height: 8),
          _TranslationDiagnostics(
            provider: _provider ?? 'none',
            fromCache: _fromCache,
            sourceLanguageCode: _sourceLanguageCode,
            targetLanguageCode: _selectedLanguageCode,
            errorMessage: _errorMessage,
            onCopy: hasSuccessfulTranslation
                ? () {
                    Clipboard.setData(ClipboardData(text: shownText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Translation copied.')),
                    );
                  }
                : null,
            showDoctorReviewAction: widget.showDoctorReviewAction,
            showAdminControls: widget.showAdminControls,
          ),
        ],
      ],
    );
  }

  void _resetTranslation() {
    setState(() {
      _selectedLanguageCode = widget.sourceLanguageCode;
      _sourceLanguageCode = widget.sourceLanguageCode;
      _clearLoadedTranslation();
      _loading = false;
      _hasAttemptedTranslation = false;
    });
  }

  void _clearLoadedTranslation() {
    _translatedText = null;
    _notice = null;
    _qualityWarning = null;
    _errorMessage = null;
    _provider = null;
    _fromCache = false;
    _hasAttemptedTranslation = false;
  }

  Future<void> _loadTranslation() async {
    if (_selectedLanguageCode == _sourceLanguageCode) {
      _resetTranslation();
      return;
    }
    setState(() {
      _notice = null;
      _qualityWarning = null;
      _errorMessage = null;
      _provider = null;
      _fromCache = false;
      _loading = true;
      _hasAttemptedTranslation = true;
    });

    final result = await _translationService.translate(
      text: widget.text,
      sourceLanguageCode: _sourceLanguageCode,
      targetLanguageCode: _selectedLanguageCode,
      contentType: widget.contentType,
      medicalMode: widget.medicalMode,
      allowPaidFallback: widget.allowPaidFallback,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _translatedText = result.hasError ? null : result.text;
      _notice = result.notice;
      _qualityWarning = result.hasError
          ? null
          : result.qualityWarning.isNotEmpty
          ? result.qualityWarning
          : 'This is an automatic translation and may not be medically perfect.';
      _errorMessage = result.errorMessage;
      _provider = result.provider;
      _fromCache = result.fromCache;
      _loading = false;
    });
  }
}

class _LanguageControlRow extends StatelessWidget {
  const _LanguageControlRow({
    required this.title,
    required this.sourceLanguageCode,
    required this.selectedLanguageCode,
    required this.loading,
    required this.onTargetSelected,
    required this.onTranslate,
    required this.onReset,
  });

  final String title;
  final String sourceLanguageCode;
  final String selectedLanguageCode;
  final bool loading;
  final ValueChanged<String> onTargetSelected;
  final VoidCallback onTranslate;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelLarge),
        _LanguageDropdown(
          label: 'Language',
          value: selectedLanguageCode,
          loading: loading,
          onChanged: onTargetSelected,
        ),
        FilledButton.icon(
          onPressed: loading || sourceLanguageCode == selectedLanguageCode
              ? null
              : onTranslate,
          icon: const Icon(Icons.translate_rounded),
          label: const Text('Translate'),
        ),
        if (selectedLanguageCode != sourceLanguageCode)
          TextButton.icon(
            onPressed: loading ? null : onReset,
            icon: const Icon(Icons.undo_rounded),
            label: const Text('Original'),
          ),
        if (loading)
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
      ],
    );
  }
}

class _LanguageDropdown extends StatelessWidget {
  const _LanguageDropdown({
    required this.label,
    required this.value,
    required this.loading,
    required this.onChanged,
  });

  final String label;
  final String value;
  final bool loading;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonHideUnderline(
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: DropdownButton<String>(
            value: value,
            borderRadius: BorderRadius.circular(16),
            hint: Text(label),
            items: medicoHubLanguages
                .map(
                  (language) => DropdownMenuItem<String>(
                    value: language.code,
                    child: Text('${language.nativeLabel} (${language.label})'),
                  ),
                )
                .toList(),
            onChanged: loading
                ? null
                : (next) {
                    if (next != null) {
                      onChanged(next);
                    }
                  },
          ),
        ),
      ),
    );
  }
}

class _TranslationDiagnostics extends StatelessWidget {
  const _TranslationDiagnostics({
    required this.provider,
    required this.fromCache,
    required this.sourceLanguageCode,
    required this.targetLanguageCode,
    required this.errorMessage,
    required this.onCopy,
    required this.showDoctorReviewAction,
    required this.showAdminControls,
  });

  final String provider;
  final bool fromCache;
  final String sourceLanguageCode;
  final String targetLanguageCode;
  final String? errorMessage;
  final VoidCallback? onCopy;
  final bool showDoctorReviewAction;
  final bool showAdminControls;

  @override
  Widget build(BuildContext context) {
    final cleanError = errorMessage?.trim() ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Chip(
              avatar: const Icon(Icons.translate_rounded, size: 16),
              label: Text('Provider: $provider'),
              visualDensity: VisualDensity.compact,
            ),
            Chip(
              avatar: const Icon(Icons.offline_bolt_rounded, size: 16),
              label: Text('Cached: ${fromCache ? 'yes' : 'no'}'),
              visualDensity: VisualDensity.compact,
            ),
            Chip(
              avatar: const Icon(Icons.input_rounded, size: 16),
              label: Text('Source: $sourceLanguageCode'),
              visualDensity: VisualDensity.compact,
            ),
            Chip(
              avatar: const Icon(Icons.output_rounded, size: 16),
              label: Text('Target: $targetLanguageCode'),
              visualDensity: VisualDensity.compact,
            ),
            TextButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded),
              label: const Text('Copy'),
            ),
            if (showDoctorReviewAction)
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.verified_rounded),
                label: const Text('Request doctor-reviewed translation'),
              ),
            if (showAdminControls)
              OutlinedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.save_as_rounded),
                label: const Text('Save reviewed version'),
              ),
          ],
        ),
        if (cleanError.isNotEmpty) ...[
          const SizedBox(height: 8),
          _TranslationNotice(
            icon: Icons.error_outline_rounded,
            text: cleanError,
          ),
        ],
      ],
    );
  }
}

class _TranslationNotice extends StatelessWidget {
  const _TranslationNotice({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 18, color: colorScheme.onSecondaryContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
