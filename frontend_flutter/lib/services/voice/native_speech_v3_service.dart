import 'dart:async';

import 'package:flutter/services.dart';

class NativeSpeechV3Event {
  NativeSpeechV3Event({
    required this.type,
    required this.payload,
  });

  final String type;
  final Map<String, dynamic> payload;

  factory NativeSpeechV3Event.fromDynamic(dynamic data) {
    final map = (data as Map?)?.cast<dynamic, dynamic>() ?? <dynamic, dynamic>{};
    return NativeSpeechV3Event(
      type: (map['type'] ?? '').toString(),
      payload: ((map['payload'] as Map?)?.cast<String, dynamic>()) ??
          <String, dynamic>{},
    );
  }
}

class NativeSpeechV3Service {
  static const MethodChannel _methods =
      MethodChannel('dictoapp/native_speech_v3/methods');
  static const EventChannel _events =
      EventChannel('dictoapp/native_speech_v3/events');

  Stream<NativeSpeechV3Event> events() {
    return _events
        .receiveBroadcastStream()
        .map((dynamic e) => NativeSpeechV3Event.fromDynamic(e));
  }

  Future<bool> isRecognitionAvailable() async {
    try {
      final result =
          await _methods.invokeMethod<bool>('isRecognitionAvailable');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> startListening({
    required String localeTag,
    bool preferOffline = true,
    bool partialResults = true,
    bool preferOnDevice = true,
  }) async {
    try {
      final result = await _methods.invokeMethod<bool>('startListening', {
        'localeTag': localeTag,
        'preferOffline': preferOffline,
        'partialResults': partialResults,
        'preferOnDevice': preferOnDevice,
      });
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  Future<bool> stopListening() async {
    try {
      final result = await _methods.invokeMethod<bool>('stopListening');
      return result ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }
}
