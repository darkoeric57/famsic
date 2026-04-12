import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/audio_providers.dart';

class VisualizerDial extends ConsumerWidget {
  const VisualizerDial({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final handler = ref.watch(audioHandlerProvider);
    final playbackState = ref.watch(playbackStateProvider);
    final isPlaying = playbackState.value?.playing ?? false;
    
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final duration = ref.watch(durationProvider).value ?? Duration.zero;
    final progress = duration.inMilliseconds > 0 
        ? position.inMilliseconds / duration.inMilliseconds 
        : 0.0;

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

          // 2. Outer Ring with Progress (Moved closer to the edge of the black circle)
          SizedBox(
            width: 232, // Just slightly larger than the 220 inner dial
            height: 232,
            child: CustomPaint(
              painter: _RingPainter(
                progress: progress,
                glowColor: const Color(0xFF22D3EE), // Cyan glow as per design
              ),
            ),
          ),

          // 3. Inner Dark Dial
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2D32), // Matches React dark dial
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: StreamBuilder<List<double>>(
                stream: handler.visualizerStream,
                builder: (context, snapshot) {
                  final magnitudes = snapshot.data ?? List.filled(7, 0.0);
                  
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(7, (i) {
                      final mag = magnitudes[i];
                      // Dynamic height based on real FFT magnitude, with a floor
                      final height = isPlaying ? (10.0 + mag * 1.5).clamp(10.0, 70.0) : 8.0;

                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.5),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: 6,
                          height: height,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22D3EE),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF22D3EE).withValues(alpha: 0.8),
                                blurRadius: isPlaying ? 12 : 4,
                                spreadRadius: isPlaying ? 1 : 0,
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _RingPainter extends CustomPainter {
  final double progress;
  final Color glowColor;

  _RingPainter({required this.progress, required this.glowColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    const strokeWidth = 8.0; // Slightly thicker for visibility

    // 1. Subtle Track
    final trackPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius - strokeWidth / 2, trackPaint);

    if (progress <= 0) return;

    // 2. Main Glowing Progress Line
    final progressPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          const Color(0xFFA855F7), // Magenta
          const Color(0xFF22D3EE), // Cyan
        ],
        stops: const [0, 1],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    final Rect rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);
    const double startAngle = -math.pi / 2;
    final double sweepAngle = progress * 2 * math.pi;

    // Draw the progress arc
    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);

    // 3. Intensive Outer Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF22D3EE).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth + 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);

    // 4. "Glow Head" - A bright particle at the top of the progress
    final double endAngle = startAngle + sweepAngle;
    final Offset headOffset = Offset(
      center.dx + (radius - strokeWidth / 2) * math.cos(endAngle),
      center.dy + (radius - strokeWidth / 2) * math.sin(endAngle),
    );

    // Bright core
    final headPaint = Paint()
      ..color = Colors.white
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
    canvas.drawCircle(headOffset, 3.5, headPaint);

    // External bloom
    final headGlowPaint = Paint()
      ..color = const Color(0xFF22D3EE)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(headOffset, 8, headGlowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
