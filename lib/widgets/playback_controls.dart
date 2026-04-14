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
      return GestureDetector(
        onTap: playing ? handler.pause : handler.play,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.surfaceLight,
            border: Border.all(
              color: AppTheme.neonCyan.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonCyan.withValues(alpha: 0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Consumer(
            builder: (context, ref, _) {
              return TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: playing ? 1.0 : 0.0),
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOutBack,
                builder: (context, value, child) {
                  return AnimatedIcon(
                    icon: AnimatedIcons.play_pause,
                    progress: AlwaysStoppedAnimation(value),
                    color: AppTheme.neonCyan,
                    size: 24,
                  );
                },
              );
            },
          ),
        ),
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
        decoration: AppTheme.pathfinderDarkDecoration(
          isCircular: true,
          borderWidth: isMain ? 3.0 : 2.2,
          rimColor: const Color(0xFF6F5F4B), // Premium Golden-Brown
        ),
        child: Center(
          child: Icon(
            icon,
            color: isMain ? AppTheme.neonCyan : Colors.white70,
            size: size * (isMain ? 0.5 : 0.45),
            shadows: [
              Shadow(
                color: AppTheme.neonCyan.withValues(alpha: 0.8),
                blurRadius: isMain ? 20 : 12,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
