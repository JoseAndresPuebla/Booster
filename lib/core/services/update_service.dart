import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
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

  static Future<void> downloadAndInstallApk({
    required String url,
    required void Function(double progress, int receivedBytes, int totalBytes) onProgress,
    required void Function(String error) onError,
    required void Function(String filePath) onComplete,
  }) async {
    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(url));
      final response = await client.send(request);

      if (response.statusCode != 200) {
        onError('Error en el servidor al descargar: HTTP ${response.statusCode}');
        client.close();
        return;
      }

      final totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/booster_update.apk');
      if (await file.exists()) {
        await file.delete();
      }

      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        receivedBytes += chunk.length;
        sink.add(chunk);
        final progress = totalBytes > 0 ? (receivedBytes / totalBytes) : 0.0;
        onProgress(progress, receivedBytes, totalBytes);
      }

      await sink.flush();
      await sink.close();
      client.close();

      onComplete(file.path);

      // Open the APK using OpenFilex which invokes Android's native package installer
      final result = await OpenFilex.open(
        file.path,
        type: 'application/vnd.android.package-archive',
      );
      debugPrint('OpenFilex result: ${result.type} - ${result.message}');
    } catch (e) {
      debugPrint('Error downloading and installing APK: $e');
      onError(e.toString());
    }
  }

  static Future<void> launchUpdateUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
