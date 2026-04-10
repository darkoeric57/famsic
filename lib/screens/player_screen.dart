import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../widgets/u_header.dart';
import '../widgets/curved_progress_bar.dart';
import '../widgets/playback_controls.dart';
import '../providers/audio_providers.dart';
import 'equalizer_screen.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider).value;
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final duration = ref.watch(durationProvider).value ?? Duration.zero;

    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 520,
              child: UHeader(
                title: currentSong?.title ?? "No Song Selected",
                subtitle: currentSong?.artist ?? "Unknown Artist",
                onMenu: () => Navigator.push(context,
                    MaterialPageRoute(builder: (c) => const EqualizerScreen())),
                child: Container(
                  color: AppTheme.deepDark,
                  child: currentSong != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.music_note,
                                color: AppTheme.accentNeon, size: 100),
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                currentSong.title,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        )
                      : const Icon(Icons.music_note,
                          color: AppTheme.accentNeon, size: 80),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // Curved Progress UI
            SizedBox(
              height: 320,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CurvedProgressBar(
                    progress: progress,
                    position: position,
                    duration: duration,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Playback Controls
            const PlaybackControls(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
