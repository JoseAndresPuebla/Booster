import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/api_constants.dart';

class UpdateInfo {
  final bool hasUpdate;
  final String currentVersion;
  final String latestVersion;
  final String releaseNotes;
  final String? apkDownloadUrl;

  const UpdateInfo({
    required this.hasUpdate,
    required this.currentVersion,
    required this.latestVersion,
    required this.releaseNotes,
    this.apkDownloadUrl,
  });
}

class UpdateService {
  static Future<UpdateInfo> checkForUpdates() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      final response = await http.get(
        Uri.parse(ApiConstants.githubLatestReleaseUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        String tag = data['tag_name'] as String? ?? 'v1.0.0';
        final cleanTag = tag.replaceAll('v', '').trim();
        final body = data['body'] as String? ?? 'Mejoras y correcciones.';

        String? apkUrl;
        final assets = data['assets'] as List<dynamic>? ?? [];
        for (final asset in assets) {
          final name = asset['name'] as String? ?? '';
          if (name.endsWith('.apk')) {
            apkUrl = asset['browser_download_url'] as String?;
            break;
          }
        }

        // Simple semver compare
        final hasUpdate = _isVersionGreater(cleanTag, currentVersion);

        return UpdateInfo(
          hasUpdate: hasUpdate,
          currentVersion: currentVersion,
          latestVersion: cleanTag,
          releaseNotes: body,
          apkDownloadUrl: apkUrl ?? data['html_url'] as String?,
        );
      }
    } catch (e) {
      debugPrint('Error checking GitHub updates: $e');
    }

    return const UpdateInfo(
      hasUpdate: false,
      currentVersion: '1.0.0',
      latestVersion: '1.0.0',
      releaseNotes: '',
    );
  }

  static bool _isVersionGreater(String remote, String local) {
    try {
      final remoteParts = remote.split('.').map(int.parse).toList();
      final localParts = local.split('.').map(int.parse).toList();

      for (int i = 0; i < remoteParts.length && i < localParts.length; i++) {
        if (remoteParts[i] > localParts[i]) return true;
        if (remoteParts[i] < localParts[i]) return false;
      }
      return remoteParts.length > localParts.length;
    } catch (_) {
      return remote != local;
    }
  }

  static Future<void> launchUpdateUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
