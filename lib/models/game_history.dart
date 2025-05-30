import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class GameHistory {
  final String difficulty;
  final int attempts;
  final Duration duration;
  final int targetNumber;
  final bool won;
  final DateTime timestamp;

  GameHistory({
    required this.difficulty,
    required this.attempts,
    required this.duration,
    required this.targetNumber,
    required this.won,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'difficulty': difficulty,
    'attempts': attempts,
    'duration': duration.inSeconds,
    'targetNumber': targetNumber,
    'won': won,
    'timestamp': timestamp.toIso8601String(),
  };

  factory GameHistory.fromJson(Map<String, dynamic> json) => GameHistory(
    difficulty: json['difficulty'],
    attempts: json['attempts'],
    duration: Duration(seconds: json['duration']),
    targetNumber: json['targetNumber'],
    won: json['won'],
    timestamp: DateTime.parse(json['timestamp']),
  );

  static const _storageKey = 'game_history';
  static const _maxHistorySize = 100;

  static Future<void> addGame({
    required String difficulty,
    required int attempts,
    required Duration duration,
    required int targetNumber,
    required bool won,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    
    history.insert(0, GameHistory(
      difficulty: difficulty,
      attempts: attempts,
      duration: duration,
      targetNumber: targetNumber,
      won: won,
    ));

    // Keep only the last _maxHistorySize games
    if (history.length > _maxHistorySize) {
      history.removeRange(_maxHistorySize, history.length);
    }

    await prefs.setString(_storageKey, 
      jsonEncode(history.map((g) => g.toJson()).toList())
    );
  }

  static Future<List<GameHistory>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final historyJson = prefs.getString(_storageKey);
    if (historyJson == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(historyJson);
      return decoded
        .map((item) => GameHistory.fromJson(item))
        .toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getStats() async {
    final history = await getHistory();
    if (history.isEmpty) {
      return {
        'totalGames': 0,
        'gamesWon': 0,
        'bestTime': null,
        'averageAttempts': 0,
        'winRate': 0.0,
        'difficultyStats': {
          'Easy': {'played': 0, 'won': 0},
          'Medium': {'played': 0, 'won': 0},
          'Hard': {'played': 0, 'won': 0},
          'Expert': {'played': 0, 'won': 0},
        },
      };
    }

    final gamesWon = history.where((g) => g.won).length;
    Duration? bestTime;
    
    if (history.any((g) => g.won)) {
      bestTime = history
        .where((g) => g.won)
        .map((g) => g.duration)
        .reduce((a, b) => a < b ? a : b);
    }

    // Calculate difficulty-specific stats
    final difficultyStats = {
      'Easy': {'played': 0, 'won': 0},
      'Medium': {'played': 0, 'won': 0},
      'Hard': {'played': 0, 'won': 0},
      'Expert': {'played': 0, 'won': 0},
    };

    for (final game in history) {
      if (difficultyStats.containsKey(game.difficulty)) {
        final stats = difficultyStats[game.difficulty]!;
        stats['played'] = (stats['played'] ?? 0) + 1;
        if (game.won) {
          stats['won'] = (stats['won'] ?? 0) + 1;
        }
      }
    }

    return {
      'totalGames': history.length,
      'gamesWon': gamesWon,
      'bestTime': bestTime,
      'averageAttempts': history.map((g) => g.attempts).reduce((a, b) => a + b) / history.length,
      'winRate': gamesWon / history.length * 100,
      'difficultyStats': difficultyStats,
    };
  }

  static Future<void> deleteGame(DateTime timestamp) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getHistory();
    
    history.removeWhere((game) => game.timestamp.isAtSameMomentAs(timestamp));

    await prefs.setString(_storageKey, 
      jsonEncode(history.map((g) => g.toJson()).toList())
    );
  }
} 