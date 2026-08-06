import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;

  Future<void> start() async {
    if (kIsWeb) {
      throw Exception(
          'Audio note recording is not available in the web build.');
    }
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw Exception('Microphone permission denied.');
    }

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      throw Exception('Recorder permission check failed.');
    }

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    _currentPath = '${tempDir.path}/medicohub_$timestamp.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 256000,
      ),
      path: _currentPath!,
    );
  }

  Future<String> stop() async {
    final path = await _recorder.stop();
    final finalPath = path ?? _currentPath;

    if (finalPath == null || finalPath.isEmpty) {
      throw Exception('Recording file was not created.');
    }
    if (kIsWeb) {
      return finalPath;
    }

    final file = File(finalPath);
    if (!await file.exists()) {
      throw Exception('Recorded audio file not found: $finalPath');
    }

    return finalPath;
  }

  Future<void> discardCurrent() async {
    try {
      final path = await _recorder.stop();
      final finalPath = path ?? _currentPath;
      if (!kIsWeb && finalPath != null && finalPath.isNotEmpty) {
        final file = File(finalPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (_) {}
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
