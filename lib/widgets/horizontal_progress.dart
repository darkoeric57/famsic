import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../providers/audio_providers.dart';

class HorizontalProgressBar extends ConsumerStatefulWidget {
  const HorizontalProgressBar({super.key});

  @override
  ConsumerState<HorizontalProgressBar> createState() => _HorizontalProgressBarState();
}

class _HorizontalProgressBarState extends ConsumerState<HorizontalProgressBar> {
  bool _isInteracting = false;
  double? _dragValue; // Local state to prevent jitter during seeking

  String formatDuration(Duration d) {
    final mins = d.inMinutes;
    final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$mins:$secs";
  }

  @override
  Widget build(BuildContext context) {
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final duration = ref.watch(durationProvider).value ?? Duration.zero;
    final progress = duration.inMilliseconds > 0 
        ? position.inMilliseconds / duration.inMilliseconds 
        : 0.0;

    // Determine the progress value to display: local drag value takes priority
    final displayProgress = (_dragValue ?? progress).clamp(0.0, 1.0);
    
    // Calculate display position for the text
    final displayPosition = _dragValue != null 
        ? Duration(milliseconds: (duration.inMilliseconds * _dragValue!).toInt())
        : position;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 35,
              child: Text(
                formatDuration(displayPosition),
                textAlign: TextAlign.right,
                style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 10),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapDown: (details) {
                      setState(() {
                        _isInteracting = true;
                        _dragValue = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                      });
                      // DEFERRED: No seek on tap down
                    },
                    onTapUp: (details) {
                      if (_dragValue != null && duration.inMilliseconds > 0) {
                        ref.read(audioHandlerProvider).seek(duration * _dragValue!);
                      }
                      setState(() {
                        _isInteracting = false;
                        _dragValue = null;
                      });
                    },
                    onTapCancel: () => setState(() {
                      _isInteracting = false;
                      _dragValue = null;
                    }),
                    onHorizontalDragStart: (_) => setState(() => _isInteracting = true),
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        _dragValue = (details.localPosition.dx / constraints.maxWidth).clamp(0.0, 1.0);
                      });
                      // DEFERRED: No seek on drag update
                    },
                    onHorizontalDragEnd: (_) {
                      if (_dragValue != null && duration.inMilliseconds > 0) {
                        ref.read(audioHandlerProvider).seek(duration * _dragValue!);
                      }
                      setState(() {
                        _isInteracting = false;
                        _dragValue = null;
                      });
                    },
                    child: Container(
                      height: 40, 
                      width: double.infinity,
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.centerLeft,
                        clipBehavior: Clip.none,
                        children: [
                          // Background Track - Fixed Height
                          Container(
                            height: 6,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.05),
                                width: 0.5,
                              ),
                            ),
                          ),
                          // Active Progress - Fixed Height
                          FractionallySizedBox(
                            widthFactor: displayProgress,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: AppTheme.neonCyan,
                                borderRadius: BorderRadius.circular(3),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.neonCyan.withOpacity(0.4),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          // Premium Pathfinder Thumb - Zero Latency Centered Position
                          Positioned(
                            left: (displayProgress * constraints.maxWidth),
                            child: FractionalTranslation(
                              translation: const Offset(-0.5, 0.0), // Perfect center alignment
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 800),
                                curve: Curves.elasticOut,
                                width: _isInteracting ? 18 : 14,
                                height: _isInteracting ? 18 : 14,
                                decoration: AppTheme.pathfinderDarkDecoration(
                                  isCircular: true,
                                  borderWidth: 1.5,
                                ),
                                child: Center(
                                  child: Container(
                                    width: 4,
                                    height: 4,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.neonCyan,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 35,
              child: Text(
                formatDuration(duration),
                style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 10),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
