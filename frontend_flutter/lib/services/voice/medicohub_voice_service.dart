import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';

import 'audio_recorder_service.dart';
import 'native_speech_v3_service.dart';

class VoiceCaptureResult {
  const VoiceCaptureResult({
    this.audioPath,
    this.partialTranscript,
    required this.mode,
  });

  final String? audioPath;
  final String? partialTranscript;
  final String mode;
}

class MedicoHubVoiceService {
  MedicoHubVoiceService({
    AudioRecorderService? recorder,
    NativeSpeechV3Service? nativeSpeech,
  })  : _recorder = recorder ?? AudioRecorderService(),
        _nativeSpeech = nativeSpeech ?? NativeSpeechV3Service();

  final AudioRecorderService _recorder;
  final NativeSpeechV3Service _nativeSpeech;
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<NativeSpeechV3Event>? _sub;
  String _lastPartial = '';

  Future<void> startAudioNote() => _recorder.start();

  Future<VoiceCaptureResult> stopAudioNote() async {
    final path = await _recorder.stop();
    return VoiceCaptureResult(audioPath: path, mode: 'audio_note');
  }

  Future<bool> startNativeListening({
    String localeTag = 'en-US',
    void Function(String text)? onPartial,
  }) async {
    _lastPartial = '';
    await _sub?.cancel();
    _sub = _nativeSpeech.events().listen((event) {
      final transcript = (event.payload['text'] ?? '').toString().trim();
      if (transcript.isEmpty) {
        return;
      }
      _lastPartial = transcript;
      onPartial?.call(transcript);
    });

    return _nativeSpeech.startListening(localeTag: localeTag);
  }

  Future<VoiceCaptureResult> stopNativeListening() async {
    await _nativeSpeech.stopListening();
    await _sub?.cancel();
    _sub = null;
    return VoiceCaptureResult(
      partialTranscript: _lastPartial.isEmpty ? null : _lastPartial,
      mode: 'native_speech',
    );
  }

  String keyboardVoiceInstructions() {
    return 'Tap in the question field, open the mobile keyboard microphone, and dictate. '
        'This is the safest immediate path for device-native multilingual voice input.';
  }

  Future<bool> audioFileExists(String path) async {
    return File(path).exists();
  }

  Future<void> playAudioNote(String path) async {
    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  Future<void> stopAudioPlayback() async {
    await _player.stop();
  }

  Future<void> deleteAudioNote(String path) async {
    await _player.stop();
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> isRecognitionAvailable() {
    return _nativeSpeech.isRecognitionAvailable();
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _player.dispose();
    await _recorder.dispose();
  }
}
