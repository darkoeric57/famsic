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

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: Icon(Icons.shuffle, color: AppTheme.secondaryGrey, size: isMini ? 20 : 24),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.skip_previous, color: AppTheme.deepDark, size: isMini ? 28 : 34),
          onPressed: handler.skipToPrevious,
        ),
        GestureDetector(
          onTap: playing ? handler.pause : handler.play,
          child: Container(
            width: isMini ? 50 : 70,
            height: isMini ? 50 : 70,
            decoration: const BoxDecoration(
              color: AppTheme.deepDark,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 15,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Icon(
              playing ? Icons.pause : Icons.play_arrow,
              color: AppTheme.white,
              size: isMini ? 30 : 40,
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.skip_next, color: AppTheme.deepDark, size: isMini ? 28 : 34),
          onPressed: handler.skipToNext,
        ),
        IconButton(
          icon: Icon(Icons.repeat, color: AppTheme.secondaryGrey, size: isMini ? 20 : 24),
          onPressed: () {},
        ),
      ],
    );
  }
}
