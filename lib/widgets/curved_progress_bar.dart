import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';

class CurvedProgressBar extends StatelessWidget {
  final double progress;
  final Duration position;
  final Duration duration;

  const CurvedProgressBar({
    super.key,
    required this.progress,
    required this.position,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 320,
      height: 320,
      child: CustomPaint(
        painter: _CurvedProgressPainter(progress: progress),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 280),
              Text(
                _formatDuration(position),
                style: const TextStyle(
                  color: AppTheme.deepDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "$twoDigitMinutes:$twoDigitSeconds";
  }
}

class _CurvedProgressPainter extends CustomPainter {
  final double progress;

  _CurvedProgressPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2 - 100);
    // Draw an arc that follows the oval bottom
    // We'll use a rect that matches the bottom curve of the oval center
    final rect = Rect.fromCenter(
      center: center,
      width: 300,
      height: 480,
    );

    final backgroundPaint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final progressPaint = Paint()
      ..color = AppTheme.deepDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    // Start angle is around 7 o'clock to 5 o'clock (radians)
    const startAngle = 0.8 * math.pi;
    const sweepAngle = 1.4 * math.pi;

    canvas.drawArc(rect, startAngle, sweepAngle, false, backgroundPaint);
    canvas.drawArc(rect, startAngle, sweepAngle * progress, false, progressPaint);

    // Draw Thumb (Dot)
    final thumbAngle = startAngle + (sweepAngle * progress);
    final thumbX = center.dx + (rect.width / 2) * math.cos(thumbAngle);
    final thumbY = center.dy + (rect.height / 2) * math.sin(thumbAngle);

    final thumbPaint = Paint()
      ..color = AppTheme.white
      ..style = PaintingStyle.fill;
    
    final thumbStrokePaint = Paint()
      ..color = AppTheme.deepDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    canvas.drawCircle(Offset(thumbX, thumbY), 8, thumbPaint);
    canvas.drawCircle(Offset(thumbX, thumbY), 8, thumbStrokePaint);
  }

  @override
  bool shouldRepaint(covariant _CurvedProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
