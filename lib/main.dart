import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/famsic_audio_handler.dart';
import 'providers/audio_providers.dart';
import 'theme/app_theme.dart';
import 'screens/library_screen.dart';
import 'screens/player_screen.dart';

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

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0; // Default to Library to show scanning progress

  final List<Widget> _screens = [
    const LibraryScreen(), // Library
    const Center(child: Text('Discover')), // Discover
    const Center(child: Text('Search')), // Search
    const PlayerScreen(), // Player
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
            _buildNavItem(1, Icons.explore_outlined, 'DISCOVER'),
            _buildNavItem(2, Icons.search, 'SEARCH'),
            _buildNavItem(3, Icons.graphic_eq, 'PLAYER'),
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
