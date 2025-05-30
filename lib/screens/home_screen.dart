import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:confetti/confetti.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/game_history.dart';
import '../providers/settings_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _guessController = TextEditingController();
  final Random _random = Random();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late ConfettiController _confettiController;
  
  static const String _currentStreakKey = 'current_streak';
  static const String _bestStreakKey = 'best_streak';

  int? _targetNumber;
  int _attempts = 0;
  int _maxAttempts = 10;
  String _message = '';
  bool _gameWon = false;
  bool _gameLost = false;
  DateTime? _startTime;
  String _feedback = '';
  bool _isHot = false;
  int _hintsRemaining = 3;
  int _currentStreak = 0;
  int _bestStreak = 0;
  bool _showHintAnimation = false;
  Set<int> _previousGuesses = {};
  int _lastHintType = 0;
  
  String _difficulty = 'Easy';
  final Map<String, Map<String, dynamic>> _difficultyRanges = {
    'Easy': {
      'range': 50,
      'maxAttempts': 10,
      'color': const Color(0xFF10B981),
      'icon': Icons.sentiment_satisfied,
    },
    'Medium': {
      'range': 100,
      'maxAttempts': 8,
      'color': const Color(0xFFFCD34D),
      'icon': Icons.sentiment_neutral,
    },
    'Hard': {
      'range': 500,
      'maxAttempts': 6,
      'color': const Color(0xFFF43F5E),
      'icon': Icons.sentiment_dissatisfied,
    },
    'Expert': {
      'range': 1000,
      'maxAttempts': 4,
      'color': const Color(0xFF8B5CF6),
      'icon': Icons.psychology,
    },
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadBestStreak();
    _startNewGame();
  }

  Future<void> _loadBestStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
        _bestStreak = prefs.getInt(_bestStreakKey) ?? 0;
      });
    } catch (e) {
      debugPrint('Error loading streaks: $e');
    }
  }

  Future<void> _updateStreaks({required bool won}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        if (won) {
          _currentStreak++;
          if (_currentStreak > _bestStreak) {
            _bestStreak = _currentStreak;
          }
        } else {
          _currentStreak = 0;
        }
      });
      
      await prefs.setInt(_currentStreakKey, _currentStreak);
      await prefs.setInt(_bestStreakKey, _bestStreak);
    } catch (e) {
      debugPrint('Error updating streaks: $e');
    }
  }

  void _startNewGame() {
    setState(() {
      _targetNumber = _random.nextInt(_difficultyRanges[_difficulty]!['range']!) + 1;
      _attempts = 0;
      _maxAttempts = _difficultyRanges[_difficulty]!['maxAttempts'] as int;
      _message = 'Guess a number between 1 and ${_difficultyRanges[_difficulty]!['range']}';
      _gameWon = false;
      _gameLost = false;
      _startTime = DateTime.now();
      _guessController.clear();
      _feedback = '';
      _isHot = false;
      _hintsRemaining = 3;
      _showHintAnimation = false;
      _previousGuesses.clear();
      _lastHintType = -1;
    });
  }

  void _useHint() {
    if (_hintsRemaining <= 0 || _gameWon) return;

    setState(() {
      _hintsRemaining--;
      final range = _difficultyRanges[_difficulty]!['range'] as int;
      
      _lastHintType = (_lastHintType + 1) % 4;
      
      switch (_lastHintType) {
        case 0:
          final hintRange = range ~/ 4;
          final lowerBound = max(1, _targetNumber! - hintRange);
          final upperBound = min(range, _targetNumber! + hintRange);
          _message = 'The number is between $lowerBound and $upperBound';
          break;
        case 1:
          _message = 'The number is ${_targetNumber! % 2 == 0 ? 'even' : 'odd'}';
          break;
        case 2:
          int sum = _targetNumber!.toString().split('').map(int.parse).reduce((a, b) => a + b);
          _message = 'The sum of digits is $sum';
          break;
        case 3:
          if (_targetNumber! > 1) {
            for (int i = 2; i <= _targetNumber! / 2; i++) {
              if (_targetNumber! % i == 0) {
                _message = '$i is a factor of the number';
                break;
              }
            }
            if (_message == '') {
              _message = 'The number is prime';
            }
          }
          break;
      }
      
      _showHintAnimation = true;
      context.read<SettingsProvider>().playGameSound('click');
      context.read<SettingsProvider>().vibrate('click');
    });

    // Reset hint animation after a delay
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() => _showHintAnimation = false);
      }
    });
  }

  void _checkGuess() {
    if (_gameWon || _gameLost) return;

    final guess = int.tryParse(_guessController.text);
    if (guess == null) {
      setState(() {
        _message = 'Please enter a valid number';
        _feedback = 'Invalid Input ❌';
      });
      _animateError();
      context.read<SettingsProvider>().playGameSound('error');
      context.read<SettingsProvider>().vibrate('error');
      return;
    }

    final range = _difficultyRanges[_difficulty]!['range'] as int;
    if (guess < 1 || guess > range) {
      setState(() {
        _message = 'Please enter a number between 1 and $range';
        _feedback = 'Out of Range ⚠️';
      });
      _animateError();
      context.read<SettingsProvider>().playGameSound('error');
      context.read<SettingsProvider>().vibrate('error');
      return;
    }

    if (_previousGuesses.contains(guess)) {
      setState(() {
        _message = 'You already guessed this number';
        _feedback = 'Repeated Guess 🔄';
      });
      _animateError();
      context.read<SettingsProvider>().playGameSound('error');
      context.read<SettingsProvider>().vibrate('error');
      return;
    }

    _previousGuesses.add(guess);

    setState(() {
      _attempts++;
      if (guess == _targetNumber) {
        _gameWon = true;
        _updateStreaks(won: true);
        final duration = DateTime.now().difference(_startTime!);
        _message = 'Congratulations! You won in $_attempts attempts and ${duration.inSeconds} seconds!';
        _feedback = 'Perfect! 🎯';
        GameHistory.addGame(
          difficulty: _difficulty,
          attempts: _attempts,
          duration: duration,
          targetNumber: _targetNumber!,
          won: true,
        );
        _showConfetti();
        context.read<SettingsProvider>().playGameSound('success');
        context.read<SettingsProvider>().vibrate('success');
      } else {
        if (_attempts >= _maxAttempts) {
          _gameLost = true;
          _updateStreaks(won: false);
          _message = 'Game Over! The number was $_targetNumber';
          _feedback = 'Try Again! 🔄';
          GameHistory.addGame(
            difficulty: _difficulty,
            attempts: _attempts,
            duration: DateTime.now().difference(_startTime!),
            targetNumber: _targetNumber!,
            won: false,
          );
          context.read<SettingsProvider>().playGameSound('error');
          context.read<SettingsProvider>().vibrate('error');
          return;
        }

        final difference = (_targetNumber! - guess).abs();
        final range = _difficultyRanges[_difficulty]!['range'] as int;
        
        if (difference <= range ~/ 20) {
          _feedback = 'Very Hot! 🔥';
          _isHot = true;
        } else if (difference <= range ~/ 10) {
          _feedback = 'Hot! 🌡️';
          _isHot = true;
        } else if (difference <= range ~/ 5) {
          _feedback = 'Warm 😊';
          _isHot = false;
        } else {
          _feedback = 'Cold ❄️';
          _isHot = false;
        }

        if (guess < _targetNumber!) {
          _message = 'Too low! Try again.';
        } else {
          _message = 'Too high! Try again.';
        }
        _animateError();
        context.read<SettingsProvider>().playGameSound('error');
        context.read<SettingsProvider>().vibrate('error');
      }
    });
    _guessController.clear();
  }

  void _animateError() {
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }

  void _showConfetti() {
    _confettiController.play();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final difficultyColor = _difficultyRanges[_difficulty]!['color'] as Color;
    
    return Stack(
      children: [
        SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Streaks Card
                  Card(
                    elevation: 4,
                    shadowColor: colorScheme.primary.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary.withOpacity(0.1),
                            colorScheme.secondary.withOpacity(0.1),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final isSmallScreen = constraints.maxWidth < 300;
                            return Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                Expanded(
                                  child: _buildStreakIndicator(
                                    'Current Streak',
                                    _currentStreak,
                                    Icons.local_fire_department,
                                    colorScheme.primary,
                                    isSmallScreen,
                                  ),
                                ),
                                Container(
                                  height: 40,
                                  width: 1,
                                  color: colorScheme.onSurface.withOpacity(0.1),
                                ),
                                Expanded(
                                  child: _buildStreakIndicator(
                                    'Best Streak',
                                    _bestStreak,
                                    Icons.emoji_events,
                                    colorScheme.secondary,
                                    isSmallScreen,
                                  ),
                                ),
                              ],
                            );
                          }
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Difficulty Card
                  Card(
                    elevation: 4,
                    shadowColor: difficultyColor.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            difficultyColor.withOpacity(0.1),
                            difficultyColor.withOpacity(0.05),
                          ],
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  _difficultyRanges[_difficulty]!['icon'] as IconData,
                                  color: difficultyColor,
                                  size: 24,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Select Difficulty',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: difficultyColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: _difficultyRanges.entries.map((entry) {
                                final isSelected = _difficulty == entry.key;
                                final color = entry.value['color'] as Color;
                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    final isSmallScreen = constraints.maxWidth < 150;
                                    return AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      curve: Curves.easeInOut,
                                      transform: Matrix4.identity()
                                        ..scale(isSelected ? 1.05 : 1.0),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _gameWon ? null : () {
                                            setState(() {
                                              _difficulty = entry.key;
                                              _startNewGame();
                                            });
                                            HapticFeedback.selectionClick();
                                          },
                                          borderRadius: BorderRadius.circular(16),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: isSmallScreen ? 12 : 20,
                                              vertical: isSmallScreen ? 8 : 12,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected
                                                ? color.withOpacity(0.2)
                                                : colorScheme.surface,
                                              borderRadius: BorderRadius.circular(16),
                                              border: Border.all(
                                                color: isSelected
                                                  ? color
                                                  : color.withOpacity(0.2),
                                                width: 2,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  entry.value['icon'] as IconData,
                                                  color: isSelected ? color : color.withOpacity(0.7),
                                                  size: isSmallScreen ? 16 : 20,
                                                ),
                                                SizedBox(width: isSmallScreen ? 4 : 8),
                                                Text(
                                                  entry.key,
                                                  style: GoogleFonts.poppins(
                                                    fontSize: isSmallScreen ? 12 : 14,
                                                    fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                    color: isSelected ? color : color.withOpacity(0.7),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Game Card
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: _scaleAnimation.value,
                      child: child,
                    ),
                    child: Card(
                      elevation: 4,
                      shadowColor: (_isHot ? colorScheme.error : colorScheme.primary).withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.surface,
                              _isHot 
                                ? colorScheme.error.withOpacity(0.1)
                                : colorScheme.primary.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: _showHintAnimation
                                  ? AnimatedTextKit(
                                      animatedTexts: [
                                        FlickerAnimatedText(
                                          _message,
                                          textStyle: GoogleFonts.poppins(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: difficultyColor,
                                          ),
                                        ),
                                      ],
                                      isRepeatingAnimation: false,
                                    )
                                  : Text(
                                      _message,
                                      key: ValueKey(_message),
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: _gameWon 
                                          ? colorScheme.primary
                                          : difficultyColor,
                                        fontWeight: _gameWon ? FontWeight.bold : null,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              if (_feedback.isNotEmpty)
                                AnimatedOpacity(
                                  opacity: _feedback.isEmpty ? 0.0 : 1.0,
                                  duration: const Duration(milliseconds: 300),
                                  child: Text(
                                    _feedback,
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: _gameWon
                                          ? colorScheme.primary
                                          : _isHot
                                              ? difficultyColor
                                              : colorScheme.error,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final isSmallScreen = constraints.maxWidth < 200;
                                  return Column(
                                    children: [
                                      _buildAttemptsIndicator(context, isSmallScreen),
                                      const SizedBox(height: 16),
                                      _buildGameControls(context, isSmallScreen),
                                    ],
                                  );
                                }
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            maxBlastForce: 5,
            minBlastForce: 2,
            emissionFrequency: 0.05,
            numberOfParticles: 50,
            gravity: 0.1,
            shouldLoop: false,
            colors: [
              colorScheme.primary,
              colorScheme.secondary,
              colorScheme.tertiary,
              Colors.pink,
              Colors.orange,
              Colors.purple,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreakIndicator(String label, int value, IconData icon, Color color, bool isSmallScreen) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 300),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: color,
                size: isSmallScreen ? 24 : 28,
              ),
              SizedBox(height: isSmallScreen ? 4 : 8),
              FittedBox(
                child: Text(
                  value.toString(),
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
              FittedBox(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 10 : 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameControls(BuildContext context, bool isSmallScreen) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _guessController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                enabled: !_gameWon && !_gameLost,
                style: GoogleFonts.poppins(
                  fontSize: isSmallScreen ? 16 : 18,
                ),
                decoration: InputDecoration(
                  labelText: 'Enter your guess',
                  labelStyle: GoogleFonts.poppins(
                    fontSize: isSmallScreen ? 14 : 16,
                  ),
                  prefixIcon: Icon(
                    Icons.casino,
                    color: _difficultyRanges[_difficulty]!['color'] as Color,
                    size: isSmallScreen ? 20 : 24,
                  ),
                  filled: true,
                  fillColor: (_gameWon || _gameLost)
                    ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
                    : Theme.of(context).colorScheme.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: (_difficultyRanges[_difficulty]!['color'] as Color).withOpacity(0.2),
                      width: 2,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _difficultyRanges[_difficulty]!['color'] as Color,
                      width: 2,
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 20,
                    vertical: isSmallScreen ? 12 : 16,
                  ),
                ),
                onSubmitted: (_) => _checkGuess(),
              ),
            ),
            const SizedBox(width: 12),
            if (!_gameWon && !_gameLost) ...[
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      (_difficultyRanges[_difficulty]!['color'] as Color).withOpacity(0.8),
                      (_difficultyRanges[_difficulty]!['color'] as Color),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (_difficultyRanges[_difficulty]!['color'] as Color).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _checkGuess,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                  ),
                ),
              ),
            ] else ...[
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      Theme.of(context).colorScheme.primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _startNewGame,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      child: Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                        size: isSmallScreen ? 20 : 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (!_gameWon && !_gameLost) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  (_difficultyRanges[_difficulty]!['color'] as Color).withOpacity(0.8),
                  (_difficultyRanges[_difficulty]!['color'] as Color),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (_difficultyRanges[_difficulty]!['color'] as Color).withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _hintsRemaining > 0 ? _useHint : null,
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: isSmallScreen ? 12 : 16,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.lightbulb,
                        color: _hintsRemaining > 0 ? Colors.white : Colors.white.withOpacity(0.5),
                        size: isSmallScreen ? 20 : 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Use Hint ($_hintsRemaining remaining)',
                        style: GoogleFonts.poppins(
                          fontSize: isSmallScreen ? 14 : 16,
                          fontWeight: FontWeight.w600,
                          color: _hintsRemaining > 0 ? Colors.white : Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAttemptsIndicator(BuildContext context, bool isSmallScreen) {
    final remainingAttempts = _maxAttempts - _attempts;
    final progress = remainingAttempts / _maxAttempts;
    final color = _difficultyRanges[_difficulty]!['color'] as Color;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.timer_outlined,
              size: isSmallScreen ? 16 : 20,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              'Remaining Attempts: $remainingAttempts',
              style: GoogleFonts.poppins(
                fontSize: isSmallScreen ? 14 : 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _guessController.dispose();
    _animationController.dispose();
    _confettiController.dispose();
    super.dispose();
  }
} 