import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/famsic_audio_handler.dart';
import 'providers/audio_providers.dart';
import 'providers/equalizer_provider.dart';
import 'theme/app_theme.dart';
import 'providers/settings_provider.dart';
import 'screens/library_screen.dart';
import 'screens/player_screen.dart';
import 'screens/folder_screen.dart';
import 'providers/navigation_provider.dart';

late FamsicAudioHandler _audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  _audioHandler = await AudioService.init(
    builder: () => FamsicAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.famsic.app.channel.audio',
      androidNotificationChannelName: 'Famsic Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        audioHandlerProvider.overrideWithValue(_audioHandler),
      ],
      child: const FamsicApp(),
    ),
  );
}

class FamsicApp extends ConsumerWidget {
  const FamsicApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(settingsProvider).isDarkMode;

    return MaterialApp(
      title: 'Famsic',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const MainLayout(),
    );
  }
}

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // Initialize controller with the current state from navigationProvider
    final initialIndex = ref.read(navigationProvider);
    _pageController = PageController(initialPage: initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  final List<Widget> _screens = [
    const LibraryScreen(),
    const FolderScreen(),
    const PlayerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Listen for navigation changes to trigger the animated transition
    ref.listen<int>(navigationProvider, (previous, next) {
      if (previous != next) {
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutQuart,
        );
      }
    });

    ref.listen<AsyncValue<int?>>(audioSessionIdProvider, (previous, next) {
      final sessionId = next.value;
      if (sessionId != null && sessionId != 0) {
        ref.read(equalizerProvider.notifier).initialize();
        
        // Ensure volume is initially set
        final savedVolume = ref.read(settingsProvider).volume;
        ref.read(audioHandlerProvider).setVolume(savedVolume);
      }
    });

    final selectedIndex = ref.watch(navigationProvider);

    return PopScope(
      canPop: selectedIndex == 2,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // If not on Player, navigate to Player instead of closing
          ref.read(navigationProvider.notifier).setIndex(2);
        }
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(), // Prevent manual swipe interference
          children: _screens,
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.only(bottom: 25, top: 15),
          decoration: BoxDecoration(
            color: AppTheme.creamBackground,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.library_music_outlined, 'LIBRARY', selectedIndex),
              _buildNavItem(1, Icons.folder_outlined, 'FOLDERS', selectedIndex),
              _buildNavItem(2, Icons.graphic_eq, 'PLAYER', selectedIndex),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, int selectedIndex) {
    final isSelected = selectedIndex == index;
    
    return GestureDetector(
      onTap: () => ref.read(navigationProvider.notifier).setIndex(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedScale(
        scale: isSelected ? 1.25 : 1.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.elasticOut,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accentNeon.withOpacity(0.1) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.accentNeon : AppTheme.secondaryGrey,
                size: 26,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 300),
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                color: isSelected ? AppTheme.accentNeon : AppTheme.secondaryGrey,
                letterSpacing: 1.0,
              ),
              child: Text(label),
            ),
            const SizedBox(height: 4),
            // Active Indicator Dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              height: 4,
              width: isSelected ? 4 : 0,
              decoration: BoxDecoration(
                color: AppTheme.accentNeon,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentNeon.withOpacity(0.5),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
