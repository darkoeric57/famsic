import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/audio_providers.dart';

class HybridMediaBar extends ConsumerStatefulWidget {
  const HybridMediaBar({super.key});

  @override
  ConsumerState<HybridMediaBar> createState() => _HybridMediaBarState();
}

class _HybridMediaBarState extends ConsumerState<HybridMediaBar> {
  bool _isSeeking = false;
  double? _dragValue; // Local value during active seeking
  Timer? _revertTimer;

  void _startRevertTimer() {
    _revertTimer?.cancel();
    _revertTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _isSeeking = false);
      }
    });
  }

  @override
  void dispose() {
    _revertTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final duration = ref.watch(durationProvider).value ?? Duration.zero;
    final playbackState = ref.watch(playbackStateProvider).value;
    final isPlaying = playbackState?.playing ?? false;
    final magnitudesAsync = ref.watch(visualizerStreamProvider);

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isSeeking = true);
        _startRevertTimer();
      },
      onHorizontalDragUpdate: (_) {
        if (!_isSeeking) setState(() => _isSeeking = true);
        _startRevertTimer();
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },
        child: _isSeeking
            ? _buildProgressBar(position, duration)
            : _buildVisualizer(magnitudesAsync, isPlaying),
      ),
    );
  }

  Widget _buildProgressBar(Duration position, Duration duration) {
    final double progress = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      key: const ValueKey('progress_bar'),
      height: 40,
      padding: const EdgeInsets.only(left: 10, right: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  activeTrackColor: AppTheme.neonCyan,
                  inactiveTrackColor: Colors.white10,
                  thumbColor: AppTheme.neonCyan,
                  overlayColor: AppTheme.neonCyan.withValues(alpha: 0.1),
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                ),
                child: Slider(
                  value: _dragValue ?? progress,
                  onChanged: (value) {
                    setState(() {
                      _isSeeking = true;
                      _dragValue = value;
                    });
                    _startRevertTimer();
                  },
                  onChangeEnd: (value) {
                    final newPos = Duration(milliseconds: (duration.inMilliseconds * value).toInt());
                    ref.read(audioHandlerProvider).seek(newPos);
                    setState(() => _dragValue = null);
                    _startRevertTimer();
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizer(AsyncValue<List<double>> magnitudesAsync, bool isPlaying) {
    return magnitudesAsync.when(
      data: (magnitudes) => Container(
        key: const ValueKey('visualizer'),
        height: 40,
        alignment: Alignment.center,
        child: _MiniBarsVisualizer(
          magnitudes: magnitudes,
          isPlaying: isPlaying,
        ),
      ),
      loading: () => const SizedBox(height: 40),
      error: (_, __) => const SizedBox(height: 40),
    );
  }
}

class _MiniBarsVisualizer extends StatelessWidget {
  final List<double> magnitudes;
  final bool isPlaying;

  const _MiniBarsVisualizer({
    required this.magnitudes,
    required this.isPlaying,
  });

  @override
  Widget build(BuildContext context) {
    const barCount = 40;
    const barWidth = 3.0;
    const spacing = 2.0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(barCount, (i) {
        final bucketIndex = (i * magnitudes.length / barCount).floor();
        final magnitude = magnitudes[bucketIndex];
        final height = (magnitude * 30).clamp(4.0, 30.0);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: barWidth,
          height: isPlaying ? height : 4,
          margin: const EdgeInsets.symmetric(horizontal: spacing / 2),
          decoration: BoxDecoration(
            color: AppTheme.neonCyan.withValues(alpha: isPlaying ? 0.8 : 0.3),
            borderRadius: BorderRadius.circular(1),
            boxShadow: isPlaying ? [
              BoxShadow(
                color: AppTheme.neonCyan.withValues(alpha: 0.3),
                blurRadius: 4,
              )
            ] : [],
          ),
        );
      }),
    );
  }
}
