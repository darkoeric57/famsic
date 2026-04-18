import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/audio_providers.dart';
import '../providers/equalizer_provider.dart';

class VisualizerDial extends ConsumerStatefulWidget {
  const VisualizerDial({super.key});

  @override
  ConsumerState<VisualizerDial> createState() => _VisualizerDialState();
}

class _VisualizerDialState extends ConsumerState<VisualizerDial> with SingleTickerProviderStateMixin {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final handler = ref.watch(audioHandlerProvider);
    final playbackState = ref.watch(playbackStateProvider);
    final isPlaying = playbackState.value?.playing ?? false;
    
    // REMOVED: Global watch for position to prevent full dial rebuilds
    
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. Bottom Shadow / Glow for the whole unit
          Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTheme.pathfinderShadow.withValues(alpha: 0.4),
                  offset: const Offset(10, 10),
                  blurRadius: 30,
                ),
                BoxShadow(
                  color: AppTheme.pathfinderHighlight,
                  offset: const Offset(-10, -10),
                  blurRadius: 30,
                ),
              ],
            ),
          ),

          // 2. Inner Dark Dial (Now with Artwork Background)
          ClipOval(
            child: Container(
              width: 220,
              height: 220,
              decoration: AppTheme.pathfinderDarkDecoration(
                isCircular: true,
                borderWidth: 2.0,
              ),
              child: Consumer(
                builder: (context, ref, _) {
                  final currentSong = ref.watch(currentSongProvider).value;
                  final artworkUri = currentSong?.extras?['uri'] as String? ?? "";
                  final artworkAsync = ref.watch(artworkProvider(artworkUri));
                  
                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // 2a. Artwork Background Layer
                      artworkAsync.when(
                        data: (bytes) {
                          if (bytes == null || bytes.isEmpty) return const SizedBox.shrink();
                          return Image.memory(
                            bytes,
                            fit: BoxFit.cover,
                            gaplessPlayback: true,
                          );
                        },
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                      
                      // 2b. Premium Dark Overlay / Blend
                      // Ensures the artwork blends into the dark theme and neon bars pop
                      Container(
                        decoration: BoxDecoration(
                          gradient: RadialGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.4),
                              Colors.black.withValues(alpha: 0.85),
                            ],
                            center: Alignment.center,
                            radius: 0.8,
                          ),
                        ),
                      ),

                      // 2c. Visualizer & Indicator Content
                      Center(
                        child: Consumer(
                          builder: (context, ref, _) {
                            final visualizerDataAsync = ref.watch(visualizerStreamProvider);
                            final magnitudes = visualizerDataAsync.value ?? List.filled(7, 0.0);
                            final playbackState = ref.watch(playbackStateProvider);
                            final isPlaying = playbackState.value?.playing ?? false;
                            
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                // Preset Indicator in the center behind bars
                                Consumer(
                                  builder: (context, ref, _) {
                                    final eqState = ref.watch(equalizerProvider);
                                    final keys = eqPresets.keys.toList();
                                    final currentIndex = keys.indexOf(eqState.activePreset);
                                    final displayIndex = currentIndex == -1 ? "C" : (currentIndex + 1).toString();
                                    
                                    return Opacity(
                                      opacity: 0.1,
                                      child: Text(
                                        displayIndex,
                                        style: GoogleFonts.outfit(
                                          fontSize: 100,
                                          fontWeight: FontWeight.w900,
                                          color: AppTheme.neonCyan,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(7, (i) {
                                    final mag = magnitudes[i];
                                    final height = isPlaying ? (10.0 + mag * 1.2).clamp(10.0, 65.0) : 8.0;

                                    return Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 3.5),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 100),
                                        width: 6,
                                        height: height,
                                        decoration: BoxDecoration(
                                          color: AppTheme.neonCyan,
                                          borderRadius: BorderRadius.circular(3),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.neonCyan.withValues(alpha: 0.8),
                                              blurRadius: isPlaying ? 12 : 4,
                                              spreadRadius: isPlaying ? 1 : 0,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // 3. Outer Ring + Indicator (Purely for display now)
          Consumer(
            builder: (context, ref, child) {
              final position = ref.watch(positionProvider).value ?? Duration.zero;
              final duration = ref.watch(durationProvider).value ?? Duration.zero;
              final progress = duration.inMilliseconds > 0 
                  ? position.inMilliseconds / duration.inMilliseconds 
                  : 0.0;

              return SizedBox(
                width: 220,
                height: 220,
                child: CustomPaint(
                  painter: _RingPainter(
                    progress: progress,
                    expansion: 0.0, // Fixed size for display indicator
                    glowColor: AppTheme.neonCyan,
                  ),
                ),
              );
            },
          ),

        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final double expansion; // 0.0 to 1.0
  final Color glowColor;

  _RingPainter({
    required this.progress,
    required this.expansion,
    required this.glowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Sleek and tiny stroke width
    const strokeWidth = 2.5;

    // 1. Track
    final trackPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, trackPaint);

    if (progress <= 0) return;

    // 2. Main Progress Arc
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: const [
          Color(0xFFA855F7), // Magenta
          Color(0xFF22D3EE), // Cyan
        ],
        stops: const [0, 1],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final Rect rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    const double startAngle = -math.pi / 2;
    final double sweepAngle = (progress * 2 * math.pi).clamp(0.001, 2 * math.pi);

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

    // 3. Selective Glow (Constant for the ring, expansive for the thumb)
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth + 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

    // 4. "Pathfinder Thumb" at the head (ONLY this part expands)
    final double endAngle = startAngle + sweepAngle;
    final Offset headOffset = Offset(
      center.dx + (radius - strokeWidth / 2) * math.cos(endAngle),
      center.dy + (radius - strokeWidth / 2) * math.sin(endAngle),
    );

    // Indicator size: slightly larger for the "sneak" look
    final double thumbRadius = 3.5;

    // Deep hanging shadow
    final headShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.6 * expansion)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    if (expansion > 0.1) {
      canvas.drawCircle(headOffset + const Offset(2, 2), thumbRadius, headShadowPaint);
    }

    // Main Thumb Color (Neon Cyan)
    final thumbColorPaint = Paint()..color = glowColor;
    canvas.drawCircle(headOffset, thumbRadius, thumbColorPaint);

    // Sovereign Highlight (Whitish)
    final headHighlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.9 * expansion)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    if (expansion > 0.1) {
      canvas.drawCircle(headOffset - const Offset(2, 2), thumbRadius * 0.6, headHighlightPaint);
    }

    // Glow Bloom
    final headBloomPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.6)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12 + (8 * expansion));
    canvas.drawCircle(headOffset, thumbRadius + 2, headBloomPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.expansion != expansion;
}
