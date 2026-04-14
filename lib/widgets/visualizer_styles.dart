import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../providers/audio_providers.dart';
import '../providers/settings_provider.dart';

class DynamicVisualizer extends ConsumerWidget {
  final bool isPlaying;
  final double height;
  final double width;
  final double opacity;

  const DynamicVisualizer({
    super.key, 
    required this.isPlaying,
    this.height = 100,
    this.width = double.infinity,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    if (!settings.visualizerEnabled) return const SizedBox();

    final magnitudesAsync = ref.watch(visualizerStreamProvider);
    
    return magnitudesAsync.when(
      data: (magnitudes) {
        // Safety Guard: If list is empty, avoid index errors in painters/generators
        if (magnitudes.isEmpty) return const SizedBox();

        switch (settings.visualizerStyle) {
          case 'Pulse Waves':
            return WaveVisualizer(key: const ValueKey('wave'), magnitudes: magnitudes, isPlaying: isPlaying, height: height, width: width, opacity: opacity);
          case 'Neon Pulse':
            return NeonPulseVisualizer(key: const ValueKey('neon_pulse'), magnitudes: magnitudes, isPlaying: isPlaying, height: height, width: width, opacity: opacity);
          case 'Gravity Drop':
            return GravityDropVisualizer(key: const ValueKey('gravity'), magnitudes: magnitudes, isPlaying: isPlaying, height: height, width: width, opacity: opacity);
          case 'Cyber Circuit':
            return CyberCircuitVisualizer(key: const ValueKey('cyber_circuit'), magnitudes: magnitudes, isPlaying: isPlaying, height: height, width: width, opacity: opacity);
          case 'Cyber Grid':
            return CyberGridVisualizer(key: const ValueKey('cyber_grid'), magnitudes: magnitudes, isPlaying: isPlaying, height: height, width: width, opacity: opacity);
          case 'Spectrum Dots':
            return SpectrumDotVisualizer(key: const ValueKey('dots'), magnitudes: magnitudes, isPlaying: isPlaying, height: height, width: width, opacity: opacity);
          case 'Neon Bars':
          default:
            return BarsVisualizer(key: const ValueKey('bars'), magnitudes: magnitudes, isPlaying: isPlaying, height: height, width: width, opacity: opacity);
        }
      },
      loading: () => const SizedBox(),
      error: (_, __) => const SizedBox(),
    );
  }
}

class BarsVisualizer extends StatelessWidget {
  final List<double> magnitudes;
  final bool isPlaying;
  final double height;
  final double width;
  final double opacity;

  const BarsVisualizer({
    super.key, 
    required this.magnitudes, 
    required this.isPlaying,
    required this.height,
    required this.width,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (magnitudes.isEmpty) return const SizedBox();
    const barCount = 32;
    
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: height,
        width: width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(barCount, (i) {
            final bucketIndex = (i * magnitudes.length / barCount).floor().clamp(0, magnitudes.length - 1);
            final magnitude = magnitudes[bucketIndex];
            final barH = (magnitude * height * 0.8).clamp(4.0, height);

            return AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 3,
              height: isPlaying ? barH : 4,
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.neonCyan,
                    AppTheme.neonCyan.withOpacity(0.5),
                    AppTheme.neonPurple,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonCyan.withOpacity(0.3),
                    blurRadius: 6,
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class WaveVisualizer extends StatelessWidget {
  final List<double> magnitudes;
  final bool isPlaying;
  final double height;
  final double width;
  final double opacity;

  const WaveVisualizer({
    super.key, 
    required this.magnitudes, 
    required this.isPlaying,
    required this.height,
    required this.width,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (magnitudes.isEmpty) return const SizedBox();
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        size: Size(width, height),
        painter: WavePainter(
          magnitudes: magnitudes,
          isPlaying: isPlaying,
          color: AppTheme.neonCyan,
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final List<double> magnitudes;
  final bool isPlaying;
  final Color color;

  WavePainter({required this.magnitudes, required this.isPlaying, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (magnitudes.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final centerY = size.height / 2;
    final step = size.width / math.max(1, magnitudes.length - 1);

    for (int i = 0; i < magnitudes.length; i++) {
      final x = i * step;
      final magnitude = isPlaying ? magnitudes[i] * size.height * 0.5 : 0.0;
      final y = centerY + (i % 2 == 0 ? -magnitude : magnitude);
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawShadow(path, color.withOpacity(0.5), 10, true);
    canvas.drawPath(path, paint);
    
    final mirrorPath = Path();
    for (int i = 0; i < magnitudes.length; i++) {
      final x = i * step;
      final magnitude = isPlaying ? magnitudes[i] * size.height * 0.3 : 0.0;
      final y = centerY + (i % 2 == 0 ? magnitude : -magnitude);
      if (i == 0) mirrorPath.moveTo(x, y);
      else mirrorPath.lineTo(x, y);
    }
    paint.strokeWidth = 1.5;
    paint.color = color.withOpacity(0.4);
    canvas.drawPath(mirrorPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class NeonPulseVisualizer extends StatelessWidget {
  final List<double> magnitudes;
  final bool isPlaying;
  final double height;
  final double width;
  final double opacity;

  const NeonPulseVisualizer({
    super.key, 
    required this.magnitudes, 
    required this.isPlaying,
    required this.height,
    required this.width,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final avgMagnitude = magnitudes.isEmpty ? 0.0 : magnitudes.reduce((a, b) => a + b) / magnitudes.length;
    final intensity = (isPlaying ? avgMagnitude : 0.01).clamp(0.01, 1.0);

    return Opacity(
      opacity: opacity,
      child: Center(
        child: Stack(
          alignment: Alignment.center,
          children: List.generate(3, (index) {
            final scale = 1.0 + (index * 0.5) + (intensity * 0.8);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 40 * scale,
              height: 40 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.neonCyan.withOpacity((0.6 / (index + 1)) * intensity),
                  width: 2.0 / (index + 1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.neonCyan.withOpacity(0.2 * intensity),
                    blurRadius: 15 * scale,
                    spreadRadius: 2,
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class GravityDropVisualizer extends StatelessWidget {
  final List<double> magnitudes;
  final bool isPlaying;
  final double height;
  final double width;
  final double opacity;

  const GravityDropVisualizer({
    super.key, 
    required this.magnitudes, 
    required this.isPlaying,
    required this.height,
    required this.width,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (magnitudes.isEmpty) return const SizedBox();
    
    return Opacity(
      opacity: opacity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          height: height,
          width: width,
          child: CustomPaint(
            painter: GravityDropPainter(
              magnitudes: magnitudes,
              isPlaying: isPlaying,
              color: AppTheme.neonCyan,
            ),
          ),
        ),
      ),
    );
  }
}

class GravityDropPainter extends CustomPainter {
  final List<double> magnitudes;
  final bool isPlaying;
  final Color color;

  GravityDropPainter({
    required this.magnitudes,
    required this.isPlaying,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (magnitudes.isEmpty) return;
    
    final paint = Paint()
      ..style = PaintingStyle.fill;

    const barCount = 24;
    final spacing = size.width / barCount;
    final barWidth = spacing * 0.6;

    for (int i = 0; i < barCount; i++) {
      final bucketIndex = (i * magnitudes.length / barCount).floor().clamp(0, magnitudes.length - 1);
      final rawMag = magnitudes[bucketIndex];
      // strictly clamp magnitude to ensure no overflows
      final mag = isPlaying ? rawMag.clamp(0.0, 1.0) : 0.02;
      
      final barHeight = (mag * size.height).clamp(4.0, size.height);
      final x = (i * spacing) + (spacing - barWidth) / 2;
      final y = size.height - barHeight;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(4),
      );

      // Gradient effect
      paint.shader = LinearGradient(
        colors: [color, AppTheme.neonPurple],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(x, y, barWidth, barHeight));

      canvas.drawRRect(rect, paint);

      // Subtle glow for peak bars
      if (mag > 0.7) {
        final glowPaint = Paint()
          ..color = color.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
        canvas.drawRRect(rect, glowPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant GravityDropPainter oldDelegate) => true;
}

class CyberCircuitVisualizer extends StatelessWidget {
  final List<double> magnitudes;
  final bool isPlaying;
  final double height;
  final double width;
  final double opacity;

  const CyberCircuitVisualizer({
    super.key, 
    required this.magnitudes, 
    required this.isPlaying,
    required this.height,
    required this.width,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (magnitudes.isEmpty) return const SizedBox();
    return Opacity(
      opacity: opacity,
      child: CustomPaint(
        size: Size(width, height),
        painter: CircuitPainter(magnitudes: magnitudes, isPlaying: isPlaying),
      ),
    );
  }
}

class CircuitPainter extends CustomPainter {
  final List<double> magnitudes;
  final bool isPlaying;

  CircuitPainter({required this.magnitudes, required this.isPlaying});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isPlaying || magnitudes.isEmpty) return;
    
    final paint = Paint()
      ..color = AppTheme.neonCyan.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    for (int i = 0; i < 8; i++) {
      final index = (i * magnitudes.length / 8).floor().clamp(0, magnitudes.length - 1);
      final mag = magnitudes[index];
      if (mag < 0.3) continue;

      final angle = (i * math.pi / 4) + (mag * 0.2);
      final length = 40 + (mag * 60);
      
      final start = Offset(
        centerX + math.cos(angle) * 20,
        centerY + math.sin(angle) * 20,
      );
      
      final end = Offset(
        centerX + math.cos(angle) * length,
        centerY + math.sin(angle) * length,
      );

      // Draw main line
      canvas.drawLine(start, end, paint);
      
      // Draw perpendicular joint
      final joint = Offset(
        end.dx + math.cos(angle + math.pi/2) * (mag * 20),
        end.dy + math.sin(angle + math.pi/2) * (mag * 20),
      );
      canvas.drawLine(end, joint, paint);

      // Glow at the end
      final glowPaint = Paint()
        ..color = AppTheme.neonCyan.withOpacity(mag.clamp(0.0, 1.0))
        ..style = PaintingStyle.fill;
      canvas.drawCircle(joint, 3, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class CyberGridVisualizer extends StatelessWidget {
  final List<double> magnitudes;
  final bool isPlaying;
  final double height;
  final double width;
  final double opacity;

  const CyberGridVisualizer({
    super.key, 
    required this.magnitudes, 
    required this.isPlaying,
    required this.height,
    required this.width,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (magnitudes.isEmpty) return const SizedBox();
    const gridCount = 20;
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: height,
        width: width,
        child: Wrap(
          alignment: WrapAlignment.center,
          runAlignment: WrapAlignment.center,
          spacing: 4,
          runSpacing: 4,
          children: List.generate(gridCount, (i) {
            final bucketIndex = (i * magnitudes.length / gridCount).floor().clamp(0, magnitudes.length - 1);
            final mag = magnitudes[bucketIndex];
            final size = 8 + (mag * 12);
            
            return AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: isPlaying ? size : 8,
              height: isPlaying ? size : 8,
              decoration: BoxDecoration(
                color: AppTheme.neonCyan.withOpacity((mag + 0.1).clamp(0.0, 1.0)),
                borderRadius: BorderRadius.circular(2),
                boxShadow: mag > 0.5 ? [
                  BoxShadow(color: AppTheme.neonCyan.withOpacity(0.3), blurRadius: 8)
                ] : [],
              ),
            );
          }),
        ),
      ),
    );
  }
}

class SpectrumDotVisualizer extends StatelessWidget {
  final List<double> magnitudes;
  final bool isPlaying;
  final double height;
  final double width;
  final double opacity;

  const SpectrumDotVisualizer({
    super.key, 
    required this.magnitudes, 
    required this.isPlaying,
    required this.height,
    required this.width,
    this.opacity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    if (magnitudes.isEmpty) return const SizedBox();
    const dotCount = 15;
    return Opacity(
      opacity: opacity,
      child: SizedBox(
        height: height,
        width: width,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(dotCount, (i) {
            final bucketIndex = (i * magnitudes.length / dotCount).floor().clamp(0, magnitudes.length - 1);
            final mag = magnitudes[bucketIndex];
            final yOffset = mag * height * 0.4;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              transform: Matrix4.translationValues(0, isPlaying ? -yOffset : 0, 0),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i % 2 == 0 ? AppTheme.neonCyan : AppTheme.neonPurple,
                boxShadow: [
                  BoxShadow(
                    color: (i % 2 == 0 ? AppTheme.neonCyan : AppTheme.neonPurple).withOpacity(0.5),
                    blurRadius: 4,
                  )
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
