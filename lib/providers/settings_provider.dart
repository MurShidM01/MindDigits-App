import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:flutter/services.dart';
import '../services/update_checker.dart';
import '../widgets/update_dialog.dart';

class SettingsProvider extends ChangeNotifier {
  static const String _themeModeKey = 'themeMode';
  static const String _soundEnabledKey = 'soundEnabled';
  static const String _vibrationEnabledKey = 'vibrationEnabled';
  static const String _selectedFontKey = 'selectedFont';

  late SharedPreferences _prefs;
  final Map<String, AudioPlayer> _audioPlayers = {};
  bool _canVibrate = false;

  ThemeMode _themeMode = ThemeMode.system;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _selectedFont = 'Poppins';

  // Sound file paths
  static const Map<String, String> _soundPaths = {
    'success': 'sounds/success.mp3',
    'error': 'sounds/error.mp3',
    'click': 'sounds/click.mp3',
  };

  ThemeMode get themeMode => _themeMode;
  bool get soundEnabled => _soundEnabled;
  bool get vibrationEnabled => _vibrationEnabled;
  String get selectedFont => _selectedFont;

  SettingsProvider() {
    _initAudioPlayers();
    initSettings();
  }

  void _initAudioPlayers() {
    for (var soundType in ['success', 'error', 'click']) {
      _audioPlayers[soundType] = AudioPlayer();
    }
  }

  Future<void> _initAudio() async {
    try {
      // Initialize each audio player with proper configuration
      for (var entry in _soundPaths.entries) {
        final soundType = entry.key;
        final soundPath = entry.value;
        final player = _audioPlayers[soundType];

        if (player != null) {
          try {
            debugPrint('Initializing sound: $soundPath');
            await player.setReleaseMode(ReleaseMode.stop);
            await player.setVolume(1.0);
            await player.setSourceAsset(soundPath);
            await player.setPlayerMode(PlayerMode.lowLatency);
            debugPrint('Successfully initialized sound: $soundPath');
          } catch (e) {
            debugPrint('Error initializing sound $soundPath: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error in audio initialization: $e');
      _soundEnabled = false;
      notifyListeners();
    }
  }

  Future<void> initSettings() async {
    await _loadSettings();
    await _initAudio();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    
    // Load theme mode
    final themeModeString = _prefs.getString(_themeModeKey);
    if (themeModeString != null) {
      _themeMode = ThemeMode.values.firstWhere(
        (mode) => mode.toString() == themeModeString,
        orElse: () => ThemeMode.system,
      );
    }

    // Load sound setting
    _soundEnabled = _prefs.getBool(_soundEnabledKey) ?? true;

    // Load vibration setting and check capability
    _vibrationEnabled = _prefs.getBool(_vibrationEnabledKey) ?? true;
    try {
      _canVibrate = await Vibrate.canVibrate;
      debugPrint('Device vibration capability: ${_canVibrate ? 'Yes' : 'No'}');
    } catch (e) {
      debugPrint('Error checking vibration capability: $e');
      _canVibrate = false;
    }

    // Load font setting
    _selectedFont = _prefs.getString(_selectedFontKey) ?? 'Poppins';

    notifyListeners();
  }

  void setThemeMode(ThemeMode mode) async {
    if (_themeMode != mode) {
      _themeMode = mode;
      await _prefs.setString(_themeModeKey, mode.toString());
      notifyListeners();
    }
  }

  void toggleSound() {
    _soundEnabled = !_soundEnabled;
    _prefs.setBool(_soundEnabledKey, _soundEnabled);
    notifyListeners();
  }

  void toggleVibration() {
    _vibrationEnabled = !_vibrationEnabled;
    _prefs.setBool(_vibrationEnabledKey, _vibrationEnabled);
    notifyListeners();
  }

  void setFont(String font) async {
    if (_selectedFont != font) {
      _selectedFont = font;
      await _prefs.setString(_selectedFontKey, font);
      // Force a rebuild of the entire app
      notifyListeners();
    }
  }

  Future<void> playGameSound(String soundType) async {
    if (!_soundEnabled) {
      debugPrint('Sound is disabled');
      return;
    }

    try {
      final player = _audioPlayers[soundType];
      if (player == null) {
        debugPrint('Invalid sound type: $soundType');
        return;
      }

      debugPrint('Attempting to play sound: $soundType');
      
      // Reset the player before playing
      await player.stop();
      await player.seek(Duration.zero);
      
      // Play with error handling
      try {
        await player.resume();
        debugPrint('Successfully played sound: $soundType');
      } catch (e) {
        debugPrint('Error during sound playback: $e');
        // Try to reinitialize and play again
        try {
          await player.setSourceAsset(_soundPaths[soundType]!);
          await player.resume();
          debugPrint('Successfully played sound after reinitialization: $soundType');
        } catch (e) {
          debugPrint('Failed to play sound even after reinitialization: $e');
        }
      }
    } catch (e) {
      debugPrint('Error in playGameSound: $e');
    }
  }

  Future<void> vibrate(String pattern) async {
    if (!_vibrationEnabled || !_canVibrate) {
      debugPrint('Vibration disabled or not supported');
      return;
    }

    try {
      FeedbackType? feedbackType;
      switch (pattern) {
        case 'success':
          feedbackType = FeedbackType.success;
          break;
        case 'error':
          feedbackType = FeedbackType.error;
          break;
        case 'click':
          feedbackType = FeedbackType.selection;
          break;
        default:
          debugPrint('Invalid vibration pattern: $pattern');
          return;
      }

      Vibrate.feedback(feedbackType);
      debugPrint('Vibration executed: $pattern');
    } catch (e) {
      debugPrint('Error during vibration ($pattern): $e');
      // If vibration fails, disable it to prevent further attempts
      _canVibrate = false;
      notifyListeners();
    }
  }

  Future<void> checkForUpdates(BuildContext context) async {
    try {
      final updateInfo = await UpdateChecker.checkForUpdates();
      
      if (updateInfo['isConnectionError'] == true) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.signal_wifi_off, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('No internet connection'),
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      if (context.mounted && updateInfo['needsUpdate'] == true) {
        await showDialog(
          context: context,
          barrierDismissible: !updateInfo['forceUpdate'],
          builder: (context) => UpdateDialog(
            currentVersion: updateInfo['currentVersion'],
            latestVersion: updateInfo['latestVersion'],
            releaseNotes: updateInfo['releaseNotes'],
            downloadUrl: updateInfo['downloadUrl'],
            forceUpdate: updateInfo['forceUpdate'],
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text('You are using the latest version!'),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to check for updates: $e'),
                ),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var player in _audioPlayers.values) {
      player.dispose();
    }
    _audioPlayers.clear();
    super.dispose();
  }
} 