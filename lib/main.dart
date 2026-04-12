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

class FamsicApp extends StatelessWidget {
  const FamsicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Famsic',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
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
  int _selectedIndex = 0; // Default to Library to show scanning progress

  @override
  void initState() {
    super.initState();
    _initGlobalEqualizer();
  }

  Future<void> _initGlobalEqualizer() async {
    final handler = ref.read(audioHandlerProvider);
    final eqNotifier = ref.read(equalizerProvider.notifier);

    // Poll for session ID briefly until it's available from the player.
    // This allows EQ settings to apply even if the user hasn't opened EQ screen yet.
    for (int i = 0; i < 20; i++) {
      final sessionId = handler.audioSessionId;
      if (sessionId != null && sessionId != 0) {
        // Apply EQ
        await eqNotifier.initialize(sessionId);
        
        // Apply Volume
        final savedVolume = ref.read(settingsProvider).volume;
        await handler.setVolume(savedVolume);
        break;
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  final List<Widget> _screens = [
    const LibraryScreen(),
    const FolderScreen(),
    const PlayerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.only(bottom: 20, top: 10),
        decoration: BoxDecoration(
          color: AppTheme.creamBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(0, Icons.library_music_outlined, 'LIBRARY'),
            _buildNavItem(1, Icons.folder_outlined, 'FOLDERS'),
            _buildNavItem(2, Icons.graphic_eq, 'PLAYER'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected ? AppTheme.accentNeon : AppTheme.secondaryGrey,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? AppTheme.accentNeon : AppTheme.secondaryGrey,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
