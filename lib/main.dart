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
import 'widgets/liquid_nav_bar.dart';

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
  final List<Widget> _screens = [
    const LibraryScreen(), // 0
    const FolderScreen(),  // 1
    const PlayerScreen(),  // 2
  ];

  @override
  Widget build(BuildContext context) {
    // Sync with Audio Session
    ref.listen<AsyncValue<int?>>(audioSessionIdProvider, (previous, next) {
      final sessionId = next.value;
      if (sessionId != null && sessionId != 0) {
        ref.read(equalizerProvider.notifier).initialize();
        final savedVolume = ref.read(settingsProvider).volume;
        ref.read(audioHandlerProvider).setVolume(savedVolume);
      }
    });

    final navState = ref.watch(navigationProvider);

    return PopScope(
      canPop: navState.currentIndex == 2,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          ref.read(navigationProvider.notifier).setIndex(2);
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black, 
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 650), // Sync with Gooey jump
          switchInCurve: Curves.easeIn,
          switchOutCurve: Curves.easeOut,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(opacity: animation, child: child);
          },
          child: Container(
            key: ValueKey<int>(navState.currentIndex),
            child: _screens[navState.currentIndex],
          ),
        ),
        bottomNavigationBar: const LiquidDippingNavBar(),
      ),
    );
  }
}
