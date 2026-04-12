import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/audio_providers.dart';

class PlaybackControls extends ConsumerWidget {
  final bool isMini;

  const PlaybackControls({super.key, this.isMini = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playbackState = ref.watch(playbackStateProvider).value;
    final playing = playbackState?.playing ?? false;
    final handler = ref.watch(audioHandlerProvider);

    if (isMini) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(Icons.skip_previous, color: AppTheme.deepDark, size: 28),
            onPressed: handler.skipToPrevious,
          ),
          IconButton(
            icon: Icon(playing ? Icons.pause : Icons.play_arrow, color: AppTheme.deepDark, size: 30),
            onPressed: playing ? handler.pause : handler.play,
          ),
          IconButton(
            icon: Icon(Icons.skip_next, color: AppTheme.deepDark, size: 28),
            onPressed: handler.skipToNext,
          ),
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _NeumorphicButton(
          icon: Icons.fast_rewind,
          size: 70,
          onPressed: handler.skipToPrevious,
        ),
        _NeumorphicButton(
          icon: playing ? Icons.pause : Icons.play_arrow,
          size: 100,
          isMain: true,
          onPressed: () async {
            if (playing) {
              handler.pause();
            } else {
              final current = ref.read(currentSongProvider).value;
              if (current == null) {
                // Pick the first song if none selected
                final songsAsync = ref.read(songListProvider);
                songsAsync.whenData((songs) async {
                  if (songs.isNotEmpty) {
                    final mediaItems = songs.map((s) => MediaItem(
                      id: s.uri,
                      title: s.title,
                      artist: s.artist,
                      album: s.album,
                      duration: Duration(milliseconds: s.duration),
                      extras: {'id': s.id, 'albumId': s.albumId},
                    )).toList();
                    await handler.updateQueue(mediaItems);
                    await handler.skipToQueueItem(0);
                  }
                });
              } else {
                handler.play();
              }
            }
          },
        ),
        _NeumorphicButton(
          icon: Icons.fast_forward,
          size: 70,
          onPressed: handler.skipToNext,
        ),
      ],
    );
  }
}

class _NeumorphicButton extends StatelessWidget {
  final IconData icon;
  final double size;
  final bool isMain;
  final VoidCallback onPressed;

  const _NeumorphicButton({
    required this.icon,
    required this.size,
    this.isMain = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: size,
        height: size,
        decoration: AppTheme.neumorphicDecoration(
          borderRadius: size / 2,
        ).copyWith(
          // Ensure clean neumorphic surface
          boxShadow: [
            BoxShadow(
              color: Colors.white,
              offset: const Offset(-5, -5),
              blurRadius: 10,
            ),
            BoxShadow(
              color: const Color(0xFFAEB2B9).withOpacity(0.4),
              offset: const Offset(5, 5),
              blurRadius: 10,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            color: AppTheme.neonCyan,
            size: size * (isMain ? 0.5 : 0.4),
            shadows: [
              Shadow(
                color: AppTheme.neonCyan.withOpacity(0.8),
                blurRadius: isMain ? 20 : 12, // Icon-only glow
              ),
            ],
          ),
        ),
      ),
    );
  }
}
