import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_models.dart';

class UpdateService {
  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  static const currentVersion = '0.1.0';
  static const updateUrl =
      'https://raw.githubusercontent.com/your-org/medicohub/main/update.json';

  Future<UpdateInfo?> checkForUpdates() async {
    try {
      final response = await _client.get(Uri.parse(updateUrl));
      if (response.statusCode != 200) {
        return null;
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final info = UpdateInfo.fromJson(data);
      if (_compareVersions(info.latestVersion, currentVersion) > 0) {
        return info;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  int _compareVersions(String left, String right) {
    final leftParts = left.split('.').map(int.tryParse).map((e) => e ?? 0).toList();
    final rightParts = right.split('.').map(int.tryParse).map((e) => e ?? 0).toList();
    final maxLength = leftParts.length > rightParts.length ? leftParts.length : rightParts.length;
    for (var index = 0; index < maxLength; index++) {
      final leftValue = index < leftParts.length ? leftParts[index] : 0;
      final rightValue = index < rightParts.length ? rightParts[index] : 0;
      if (leftValue != rightValue) {
        return leftValue.compareTo(rightValue);
      }
    }
    return 0;
  }
}
