import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class UpdateChecker {
  
  
  static const String _githubApiUrl = 'https://api.github.com/repos/MurShidM01/MindDigits-App/releases/latest';
  
  static Future<Map<String, dynamic>> checkForUpdates() async {
    try {
      // Check internet connectivity first
      try {
        final result = await InternetAddress.lookup('google.com');
        if (result.isEmpty || result[0].rawAddress.isEmpty) {
          return {
            'error': 'No internet connection',
            'needsUpdate': false,
            'forceUpdate': false,
            'isConnectionError': true,
          };
        }
      } on SocketException catch (_) {
        return {
          'error': 'No internet connection',
          'needsUpdate': false,
          'forceUpdate': false,
          'isConnectionError': true,
        };
      }

      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;
      
      // Fetch latest release from GitHub
      final response = await http.get(Uri.parse(_githubApiUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to check for updates');
      }

      final data = json.decode(response.body);
      final latestVersion = data['tag_name'].toString().replaceAll('v', '');
      final releaseNotes = data['body'] ?? 'No release notes available';
      final downloadUrl = data['html_url'] ?? '';

      // Compare versions
      final needsUpdate = _compareVersions(currentVersion, latestVersion);

      return {
        'currentVersion': currentVersion,
        'latestVersion': latestVersion,
        'needsUpdate': needsUpdate,
        'releaseNotes': releaseNotes,
        'downloadUrl': downloadUrl,
        'forceUpdate': true, // Set to true to force users to update
        'isConnectionError': false,
      };
    } on SocketException catch (_) {
      return {
        'error': 'No internet connection',
        'needsUpdate': false,
        'forceUpdate': false,
        'isConnectionError': true,
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'needsUpdate': false,
        'forceUpdate': false,
        'isConnectionError': false,
      };
    }
  }

  static bool _compareVersions(String current, String latest) {
    List<int> currentParts = current.split('.').map(int.parse).toList();
    List<int> latestParts = latest.split('.').map(int.parse).toList();

    for (var i = 0; i < 3; i++) {
      final currentPart = i < currentParts.length ? currentParts[i] : 0;
      final latestPart = i < latestParts.length ? latestParts[i] : 0;

      if (latestPart > currentPart) return true;
      if (currentPart > latestPart) return false;
    }

    return false;
  }
} 