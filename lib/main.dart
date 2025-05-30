import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';
import 'providers/settings_provider.dart';
import 'services/update_checker.dart';
import 'widgets/update_dialog.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize settings provider
  final settingsProvider = SettingsProvider();
  await settingsProvider.initSettings();

  runApp(
    ChangeNotifierProvider(
      create: (_) => settingsProvider,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        final baseTextTheme = GoogleFonts.getFont(
          settings.selectedFont,
        ).copyWith(
          fontSize: 14,
          color: const Color(0xFF6B7280),
        );

        final textTheme = TextTheme(
          displayLarge: baseTextTheme.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1F2937),
          ),
          displayMedium: baseTextTheme.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
          displaySmall: baseTextTheme.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1F2937),
          ),
          bodyLarge: baseTextTheme.copyWith(
            fontSize: 16,
            color: const Color(0xFF4B5563),
          ),
          bodyMedium: baseTextTheme.copyWith(
            fontSize: 14,
            color: const Color(0xFF6B7280),
          ),
        );

        final darkTextTheme = TextTheme(
          displayLarge: baseTextTheme.copyWith(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          displayMedium: baseTextTheme.copyWith(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          displaySmall: baseTextTheme.copyWith(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          bodyLarge: baseTextTheme.copyWith(
            fontSize: 16,
            color: const Color(0xFFE5E7EB),
          ),
          bodyMedium: baseTextTheme.copyWith(
            fontSize: 14,
            color: const Color(0xFFD1D5DB),
          ),
        );

        return MaterialApp(
          title: 'MindDigits',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF6366F1),
              brightness: Brightness.light,
            ).copyWith(
              secondary: const Color(0xFF10B981),
              tertiary: const Color(0xFFF43F5E),
              background: const Color(0xFFFAFAFA),
              surface: Colors.white,
            ),
            useMaterial3: true,
            textTheme: textTheme,
            scaffoldBackgroundColor: const Color(0xFFFAFAFA),
            cardTheme: CardTheme(
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: Colors.white,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              labelStyle: TextStyle(
                fontFamily: settings.selectedFont,
                fontSize: 16,
              ),
              hintStyle: TextStyle(
                fontFamily: settings.selectedFont,
                fontSize: 16,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 2,
                shadowColor: const Color(0xFF6366F1).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 18,
                ),
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                textStyle: TextStyle(
                  fontFamily: settings.selectedFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.transparent,
              titleTextStyle: TextStyle(
                fontFamily: settings.selectedFont,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF6366F1),
              ),
              iconTheme: const IconThemeData(
                color: Color(0xFF6366F1),
                size: 28,
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              elevation: 8,
              height: 80,
              backgroundColor: Colors.white,
              indicatorColor: const Color(0xFF6366F1).withOpacity(0.12),
              labelTextStyle: MaterialStateProperty.all(
                TextStyle(
                  fontFamily: settings.selectedFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              iconTheme: MaterialStateProperty.all(
                const IconThemeData(size: 24),
              ),
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF818CF8),
              brightness: Brightness.dark,
            ).copyWith(
              secondary: const Color(0xFF34D399),
              tertiary: const Color(0xFFFB7185),
              background: const Color(0xFF1A1A1A),
              surface: const Color(0xFF262626),
            ),
            useMaterial3: true,
            textTheme: darkTextTheme,
            scaffoldBackgroundColor: const Color(0xFF1A1A1A),
            cardTheme: CardTheme(
              elevation: 2,
              shadowColor: Colors.black.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              color: const Color(0xFF262626),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF262626),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF818CF8), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              labelStyle: TextStyle(
                fontFamily: settings.selectedFont,
                fontSize: 16,
              ),
              hintStyle: TextStyle(
                fontFamily: settings.selectedFont,
                fontSize: 16,
                color: const Color(0xFF6B7280),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 2,
                shadowColor: const Color(0xFF818CF8).withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 18,
                ),
                backgroundColor: const Color(0xFF818CF8),
                foregroundColor: Colors.white,
                textStyle: TextStyle(
                  fontFamily: settings.selectedFont,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.transparent,
              titleTextStyle: TextStyle(
                fontFamily: settings.selectedFont,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF818CF8),
              ),
              iconTheme: const IconThemeData(
                color: Color(0xFF818CF8),
                size: 28,
              ),
            ),
            navigationBarTheme: NavigationBarThemeData(
              elevation: 8,
              height: 80,
              backgroundColor: const Color(0xFF262626),
              indicatorColor: const Color(0xFF818CF8).withOpacity(0.12),
              labelTextStyle: MaterialStateProperty.all(
                TextStyle(
                  fontFamily: settings.selectedFont,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              iconTheme: MaterialStateProperty.all(
                const IconThemeData(size: 24),
              ),
            ),
          ),
          home: const MainApp(),
        );
      },
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _showSplash = true;
  bool _checkingUpdate = true;
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const HistoryScreen(),
    const SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _loadApp();
  }

  Future<void> _loadApp() async {
    // Start splash screen timer
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showSplash = false);
      }
    });

    try {
      // Check for updates while splash screen is showing
      final updateInfo = await UpdateChecker.checkForUpdates();
      
      if (mounted && updateInfo['needsUpdate'] == true) {
        // Show update dialog
        if (context.mounted) {
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
        }
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    } finally {
      if (mounted) {
        setState(() => _checkingUpdate = false);
      }
    }
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'About MindDigits',
          style: GoogleFonts.poppins(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'MindDigits is a fun and challenging number guessing game that helps improve your logical thinking and deduction skills.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            Text(
              'How to Play:',
              style: GoogleFonts.poppins(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '• Try to guess the secret number\n• Get hints after each guess\n• Use logic to deduce the correct number\n• Challenge yourself to solve in fewer attempts',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it!',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }

    // If still checking for updates and splash screen is done, show loading
    if (_checkingUpdate) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      body: _screens[_currentIndex],
      appBar: AppBar(
        title: const Text('MindDigits'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
