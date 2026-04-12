import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HorizontalProgressBar extends StatelessWidget {
  final double progress; // 0.0 to 1.0
  final Duration position;
  final Duration duration;

  const HorizontalProgressBar({
    super.key,
    required this.progress,
    required this.position,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    String formatDuration(Duration d) {
      final mins = d.inMinutes;
      final secs = (d.inSeconds % 60).toString().padLeft(2, '0');
      return "$mins:$secs";
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              formatDuration(position),
              style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 10),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.pathfinderShadow.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: progress.clamp(0.0, 1.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.neonCyan,
                          borderRadius: BorderRadius.circular(2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.neonCyan.withOpacity(0.6),
                              blurRadius: 10,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              formatDuration(duration),
              style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}
