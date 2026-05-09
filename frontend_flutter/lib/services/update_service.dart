import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_models.dart';

enum UpdateCheckFrequency {
  everyLaunch,
  daily,
  weekly,
  never,
}

extension UpdateCheckFrequencyLabel on UpdateCheckFrequency {
  String get label {
    switch (this) {
      case UpdateCheckFrequency.everyLaunch:
        return 'Every launch';
      case UpdateCheckFrequency.daily:
        return 'Daily';
      case UpdateCheckFrequency.weekly:
        return 'Weekly';
      case UpdateCheckFrequency.never:
        return 'Never';
    }
  }

  String get storageValue {
    switch (this) {
      case UpdateCheckFrequency.everyLaunch:
        return 'every_launch';
      case UpdateCheckFrequency.daily:
        return 'daily';
      case UpdateCheckFrequency.weekly:
        return 'weekly';
      case UpdateCheckFrequency.never:
        return 'never';
    }
  }

  static UpdateCheckFrequency fromStorage(String? raw) {
    for (final value in UpdateCheckFrequency.values) {
      if (value.storageValue == raw) {
        return value;
      }
    }
    return UpdateCheckFrequency.daily;
  }
}

class UpdateService {
  UpdateService({http.Client? client}) : _client = client ?? http.Client();

  static const String fallbackVersion = '0.0.0';
  static const String updateUrl =
      'https://raw.githubusercontent.com/drraj1965/medicohub/main/update.json';
  static const String preferenceFrequencyKey = 'update_frequency';
  static const String preferenceLastCheckedKey = 'update_last_checked_at';
  static const String preferenceAutoOpenKey = 'update_auto_open_link';
  static const String preferenceLastOpenedVersionKey = 'update_last_opened_version';

  final http.Client _client;

  Future<String> currentVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      if (version.isNotEmpty) {
        return version;
      }
    } catch (_) {}
    return fallbackVersion;
  }

  Future<UpdateInfo?> checkForUpdates({
    required String currentVersion,
  }) async {
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

  bool shouldCheck({
    required SharedPreferences prefs,
    required UpdateCheckFrequency frequency,
    DateTime? now,
  }) {
    if (frequency == UpdateCheckFrequency.never) {
      return false;
    }
    if (frequency == UpdateCheckFrequency.everyLaunch) {
      return true;
    }
    final raw = prefs.getString(preferenceLastCheckedKey);
    if (raw == null || raw.isEmpty) {
      return true;
    }
    final lastChecked = DateTime.tryParse(raw);
    if (lastChecked == null) {
      return true;
    }
    final current = now ?? DateTime.now();
    final difference = current.difference(lastChecked);
    if (frequency == UpdateCheckFrequency.daily) {
      return difference.inHours >= 24;
    }
    return difference.inDays >= 7;
  }

  Future<void> markChecked(SharedPreferences prefs, {DateTime? now}) async {
    await prefs.setString(
      preferenceLastCheckedKey,
      (now ?? DateTime.now()).toIso8601String(),
    );
  }

  String preferredDownloadUrl(UpdateInfo info) {
    if (Platform.isAndroid) {
      if (info.releasePageUrl?.isNotEmpty ?? false) {
        return info.releasePageUrl!;
      }
      if (info.androidDownloadUrl?.isNotEmpty ?? false) {
        return info.androidDownloadUrl!;
      }
    }
    if (Platform.isIOS && (info.iosStoreUrl?.isNotEmpty ?? false)) {
      return info.iosStoreUrl!;
    }
    if (Platform.isWindows && (info.windowsDownloadUrl?.isNotEmpty ?? false)) {
      return info.windowsDownloadUrl!;
    }
    if (info.downloadUrl.isNotEmpty) {
      return info.downloadUrl;
    }
    return info.releasePageUrl ?? '';
  }

  int compareVersions(String left, String right) => _compareVersions(left, right);

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
