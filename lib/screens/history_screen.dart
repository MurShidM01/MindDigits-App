import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/game_history.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<GameHistory> _history = [];
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    final history = await GameHistory.getHistory();
    final stats = await GameHistory.getStats();
    setState(() {
      _history = history;
      _stats = stats;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: colorScheme.primary,
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadHistory,
              color: colorScheme.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Statistics Grid
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.5,
                        children: [
                          _buildStatCard(
                            context,
                            title: 'Total Games',
                            value: _stats['totalGames'].toString(),
                            icon: Icons.games,
                            color: colorScheme.primary,
                          ),
                          _buildStatCard(
                            context,
                            title: 'Games Won',
                            value: _stats['gamesWon'].toString(),
                            icon: Icons.emoji_events,
                            color: colorScheme.secondary,
                          ),
                          _buildStatCard(
                            context,
                            title: 'Best Time',
                            value: _stats['bestTime'] != null
                                ? '${(_stats['bestTime'] as Duration).inSeconds}s'
                                : 'N/A',
                            icon: Icons.timer,
                            color: colorScheme.tertiary,
                          ),
                          _buildStatCard(
                            context,
                            title: 'Win Rate',
                            value: '${_stats['winRate']?.toStringAsFixed(1)}%',
                            icon: Icons.trending_up,
                            color: const Color(0xFF10B981), // Emerald
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Difficulty Distribution
                      Card(
                        elevation: 4,
                        shadowColor: colorScheme.primary.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.bar_chart,
                                    color: colorScheme.primary,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Performance by Difficulty',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ..._buildDifficultyStats(context),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Recent Games
                      Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: colorScheme.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Recent Games',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_history.isEmpty)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.history,
                                size: 64,
                                color: colorScheme.primary.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No game history yet',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  color: colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Play some games to see your history here!',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _history.length,
                          itemBuilder: (context, index) => Dismissible(
                            key: Key(_history[index].timestamp.toIso8601String()),
                            background: Container(
                              decoration: BoxDecoration(
                                color: Colors.red.shade400,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              margin: const EdgeInsets.symmetric(vertical: 8.0),
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20.0),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            direction: DismissDirection.endToStart,
                            onDismissed: (direction) async {
                              final deletedGame = _history[index];
                              setState(() {
                                _history.removeAt(index);
                              });
                              await GameHistory.deleteGame(deletedGame.timestamp);
                              await _loadHistory(); // Refresh stats
                              
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('Game deleted'),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    onPressed: () async {
                                      setState(() {
                                        _history.insert(index, deletedGame);
                                      });
                                      await GameHistory.addGame(
                                        difficulty: deletedGame.difficulty,
                                        attempts: deletedGame.attempts,
                                        duration: deletedGame.duration,
                                        targetNumber: deletedGame.targetNumber,
                                        won: deletedGame.won,
                                      );
                                      await _loadHistory(); // Refresh stats
                                    },
                                  ),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: Theme.of(context).colorScheme.surface,
                                  elevation: 4,
                                ),
                              );
                            },
                            child: _buildGameCard(
                              context,
                              _history[index],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 180;
        return Card(
          elevation: 4,
          shadowColor: color.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 8.0 : 16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: color,
                    size: isSmallScreen ? 20 : 24,
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 8),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 18 : 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: isSmallScreen ? 10 : 12,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  List<Widget> _buildDifficultyStats(BuildContext context) {
    final difficulties = ['Easy', 'Medium', 'Hard', 'Expert'];
    final colorScheme = Theme.of(context).colorScheme;
    final difficultyColors = {
      'Easy': const Color(0xFF10B981), // Emerald
      'Medium': const Color(0xFFFCD34D), // Yellow
      'Hard': const Color(0xFFF43F5E), // Rose
      'Expert': const Color(0xFF8B5CF6), // Purple
    };

    return difficulties.map((difficulty) {
      final stats = _stats['difficultyStats']?[difficulty] ?? {};
      final played = stats['played'] ?? 0;
      final won = stats['won'] ?? 0;
      final winRate = played > 0 ? (won / played * 100).toStringAsFixed(1) : '0.0';

      return Padding(
        padding: const EdgeInsets.only(bottom: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  difficulty,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: difficultyColors[difficulty],
                  ),
                ),
                Text(
                  '$winRate% ($won/$played)',
                  style: GoogleFonts.poppins(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: played > 0 ? won / played : 0,
                backgroundColor: difficultyColors[difficulty]!.withOpacity(0.1),
                color: difficultyColors[difficulty],
                minHeight: 8,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildGameCard(BuildContext context, GameHistory game) {
    final colorScheme = Theme.of(context).colorScheme;
    final timeAgo = _getTimeAgo(game.timestamp);
    final difficultyColors = {
      'Easy': const Color(0xFF10B981),
      'Medium': const Color(0xFFFCD34D),
      'Hard': const Color(0xFFF43F5E),
      'Expert': const Color(0xFF8B5CF6),
    };
    final difficultyColor = difficultyColors[game.difficulty] ?? colorScheme.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shadowColor: colorScheme.primary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              game.won
                ? colorScheme.primary.withOpacity(0.05)
                : colorScheme.error.withOpacity(0.05),
              Colors.transparent,
            ],
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            backgroundColor: game.won
                ? colorScheme.primary.withOpacity(0.1)
                : colorScheme.error.withOpacity(0.1),
            child: Icon(
              game.won ? Icons.emoji_events : Icons.close,
              color: game.won ? colorScheme.primary : colorScheme.error,
            ),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: difficultyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  game.difficulty,
                  style: GoogleFonts.poppins(
                    color: difficultyColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Number: ${game.targetNumber}',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.refresh,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${game.attempts} attempts',
                    style: GoogleFonts.poppins(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.timer,
                    size: 16,
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${game.duration.inSeconds}s',
                    style: GoogleFonts.poppins(
                      color: colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                timeAgo,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
} 