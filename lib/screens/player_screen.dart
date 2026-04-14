import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../widgets/visualizer_dial.dart';
import '../widgets/horizontal_progress.dart';
import '../widgets/preset_selector.dart';
import '../widgets/playback_controls.dart';
import '../providers/audio_providers.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/settings_provider.dart';
import 'equalizer_screen.dart';
import 'settings_screen.dart';

class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key});

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  bool _showVolumeSlider = false;
  Timer? _volumeTimer;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    // Initialize volume from saved settings
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final savedVolume = ref.read(settingsProvider).volume;
      setState(() {
        _volume = savedVolume;
      });
    });
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.microphone.status;
    if (!status.isGranted) {
      await Permission.microphone.request();
    }
  }

  void _resetVolumeTimer() {
    _volumeTimer?.cancel();
    _volumeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showVolumeSlider = false;
        });
      }
    });
  }

  void _toggleVolumeSlider() {
    setState(() {
      _showVolumeSlider = !_showVolumeSlider;
    });
    if (_showVolumeSlider) {
      _resetVolumeTimer();
    }
  }

  @override
  void dispose() {
    _volumeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSong = ref.watch(currentSongProvider).value;
    final playbackState = ref.watch(playbackStateProvider).value;
    // MOVED: position, duration and progress to HorizontalProgressBar to stop global flickering
    
    final playing = playbackState?.playing ?? false;

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                const SizedBox(height: 25),
                // 1. Header
                _buildHeader(context, currentSong?.title ?? "No Song Selected"),
                
                const Spacer(flex: 2),
                
                // 2. Song Info (Artist / Subtitle)
                Text(
                  (currentSong?.artist ?? "Unknown Artist").toUpperCase(),
                  style: GoogleFonts.outfit(
                    color: AppTheme.secondaryGrey.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 4.0,
                  ),
                ),
                
                const SizedBox(height: 15),
                
                // 3. Visualizer Dial Area (with Volume Overlay)
                Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    const VisualizerDial(),
                    
                    // Volume Control Panel (Right)
                    Positioned(
                      right: 0,
                      child: Column(
                        children: [
                          AnimatedOpacity(
                            opacity: _showVolumeSlider ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Container(
                              height: 120,
                              width: 35,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: AppTheme.pathfinderDarkDecoration(
                                borderRadius: 18,
                              ),
                              child: RotatedBox(
                                quarterTurns: 3,
                                child: SliderTheme(
                                  data: SliderThemeData(
                                    trackHeight: 6,
                                    activeTrackColor: AppTheme.neonCyan,
                                    inactiveTrackColor: AppTheme.secondaryGrey.withValues(alpha: 0.2),
                                    thumbColor: AppTheme.neonCyan,
                                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                                  ),
                                  child: Slider(
                                    value: _volume.clamp(0.0, 1.0),
                                    onChanged: (val) {
                                      setState(() {
                                        _volume = val;
                                      });
                                      ref.read(audioHandlerProvider).setVolume(val);
                                      ref.read(settingsProvider.notifier).setVolume(val);
                                      _resetVolumeTimer();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                          GestureDetector(
                            onTap: _toggleVolumeSlider,
                            child: Column(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: AppTheme.pathfinderDarkDecoration(isCircular: true, borderWidth: 1.5), // Switched to premium dark
                                  child: Center(
                                    child: Text(
                                      "${(_volume * 100).toInt()}%",
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.neonCyan,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Icon(
                                  LucideIcons.volume2,
                                  size: 18,
                                  color: Color(0xFF22D3EE),
                                  shadows: [
                                    Shadow(color: Color(0xFF22D3EE), blurRadius: 10),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const Spacer(flex: 2),
                
                // 4. Horizontal Progress (Now manages its own position/duration/progress internally)
                const HorizontalProgressBar(),
                
                const SizedBox(height: 45),
                
                // 5. Preset Selector
                const PresetSelector(),
                
                const Spacer(flex: 1),
                
                // 6. Playback Controls
                const PlaybackControls(),
                
                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const SettingsScreen()),
          ),
          child: Container(
            width: 48,
            height: 48,
            decoration: AppTheme.pathfinderDarkDecoration(borderRadius: 16, borderWidth: 1.8),
            child: const Icon(LucideIcons.settings, color: Colors.white, size: 24),
          ),
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Playlist \"Design\"",
                style: GoogleFonts.playfairDisplay(
                  fontSize: 13,
                  color: AppTheme.secondaryGrey.withValues(alpha: 0.7),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.deepDark,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (c) => const EqualizerScreen()),
          ),
          child: Container(
            width: 48,
            height: 48,
            decoration: AppTheme.pathfinderDarkDecoration(borderRadius: 16, borderWidth: 1.8),
            child: const Icon(Icons.sort, color: Colors.white, size: 24),
          ),
        ),
      ],
    );
  }
}
