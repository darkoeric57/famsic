import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/sleep_timer_provider.dart';

class UHeader extends ConsumerWidget {
  final Widget child;
  final double height;
  final String title;
  final String subtitle;
  final VoidCallback? onBack;
  final VoidCallback? onMenu;

  const UHeader({
    super.key,
    required this.child,
    this.height = 450,
    required this.title,
    required this.subtitle,
    this.onBack,
    this.onMenu,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timerState = ref.watch(sleepTimerProvider);
    
    return SizedBox.expand(
      child: Stack(
        children: [
          // Dark background container
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: height * 0.85,
              decoration: const BoxDecoration(
                color: AppTheme.deepDark,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(160),
                  bottomRight: Radius.circular(160),
                ),
              ),
            ),
          ),
          
          // Header Controls
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: AppTheme.white, size: 30),
                  onPressed: onBack ?? () => Navigator.maybePop(context),
                ),
                Row(
                  children: [
                    if (timerState.isRunning && timerState.remainingTime != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _TimerChip(
                          remainingTime: timerState.remainingTime!,
                          onTap: () => _showSleepTimerSheet(context, ref),
                        ),
                      )
                    else
                      IconButton(
                        icon: const Icon(Icons.timer_outlined, color: AppTheme.white, size: 24),
                        onPressed: () => _showSleepTimerSheet(context, ref),
                      ),
                    IconButton(
                      icon: const Icon(Icons.menu, color: AppTheme.white, size: 30),
                      onPressed: onMenu,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Central Artwork in Oval Cutout
          Positioned(
            top: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  width: 260,
                  height: 380,
                  decoration: BoxDecoration(
                    color: AppTheme.deepDark,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(130),
                      bottom: Radius.circular(130),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentNeon.withOpacity(0.3),
                        blurRadius: 40,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: child,
                ),
                const SizedBox(height: 25),
                Text(
                  title,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: AppTheme.white,
                    fontSize: 24,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.secondaryGrey,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSleepTimerSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SleepTimerSheet(ref: ref),
    );
  }
}

class _TimerChip extends StatelessWidget {
  final Duration remainingTime;
  final VoidCallback onTap;

  const _TimerChip({required this.remainingTime, required this.onTap});

  @override
  Widget build(BuildContext context) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    final minutes = twoDigits(remainingTime.inMinutes.remainder(60));
    final seconds = twoDigits(remainingTime.inSeconds.remainder(60));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: AppTheme.accentNeon.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.accentNeon.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentNeon.withOpacity(0.2),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer, color: AppTheme.accentNeon, size: 14),
            const SizedBox(width: 4),
            Text(
              "$minutes:$seconds",
              style: GoogleFonts.outfit(
                color: AppTheme.accentNeon,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SleepTimerSheet extends StatelessWidget {
  final WidgetRef ref;

  const _SleepTimerSheet({required this.ref});

  @override
  Widget build(BuildContext context) {
    final timerState = ref.watch(sleepTimerProvider);

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.deepDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(40),
          topRight: Radius.circular(40),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.secondaryGrey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            "Sleep Timer",
            style: GoogleFonts.outfit(
              color: AppTheme.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            timerState.isRunning
                ? "Music will stop automatically when the timer expires."
                : "Schedule when you want the music to stop.",
            style: const TextStyle(color: AppTheme.secondaryGrey, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          
          if (timerState.isRunning)
            _buildActiveTimerView(context)
          else
            _buildTimerOptions(context),
            
          const SizedBox(height: 30),
          if (timerState.isRunning)
            TextButton(
              onPressed: () {
                ref.read(sleepTimerProvider.notifier).cancelTimer();
                Navigator.pop(context);
              },
              child: const Text(
                "Cancel Timer",
                style: TextStyle(color: AppTheme.accentNeon, fontWeight: FontWeight.bold),
              ),
            ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildActiveTimerView(BuildContext context) {
    final timerState = ref.watch(sleepTimerProvider);
    final remaining = timerState.remainingTime ?? Duration.zero;
    
    return Column(
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.accentNeon.withOpacity(0.2), width: 8),
          ),
          child: Center(
            child: Text(
              "${remaining.inMinutes}:${(remaining.inSeconds % 60).toString().padLeft(2, '0')}",
              style: GoogleFonts.outfit(
                color: AppTheme.accentNeon,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(color: AppTheme.accentNeon.withOpacity(0.5), blurRadius: 20),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimerOptions(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _TimerOption(label: "15m", minutes: 15, ref: ref),
            _TimerOption(label: "30m", minutes: 30, ref: ref),
            _TimerOption(label: "45m", minutes: 45, ref: ref),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _TimerOption(label: "1h", minutes: 60, ref: ref),
            _TimerOption(label: "2h", minutes: 120, ref: ref),
            _TimerOption(
              label: "Custom",
              icon: Icons.edit_outlined,
              onTap: () => _showCustomInputDialog(context),
            ),
          ],
        ),
      ],
    );
  }

  void _showCustomInputDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.deepDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Custom Time", style: GoogleFonts.outfit(color: AppTheme.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(color: AppTheme.white),
          decoration: InputDecoration(
            hintText: "Minutes",
            hintStyle: TextStyle(color: AppTheme.secondaryGrey.withOpacity(0.5)),
            enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accentNeon)),
            focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.accentNeon, width: 2)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: AppTheme.secondaryGrey)),
          ),
          TextButton(
            onPressed: () {
              final mins = int.tryParse(controller.text);
              if (mins != null && mins > 0) {
                ref.read(sleepTimerProvider.notifier).setTimer(Duration(minutes: mins));
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Close sheet
              }
            },
            child: const Text("Set", style: TextStyle(color: AppTheme.accentNeon, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _TimerOption extends StatelessWidget {
  final String label;
  final int? minutes;
  final IconData? icon;
  final VoidCallback? onTap;
  final WidgetRef ref;

  const _TimerOption({
    required this.label,
    this.minutes,
    this.icon,
    this.onTap,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () {
        if (minutes != null) {
          ref.read(sleepTimerProvider.notifier).setTimer(Duration(minutes: minutes!));
          Navigator.pop(context);
        }
      },
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.white.withOpacity(0.1)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null)
              Icon(icon, color: AppTheme.accentNeon, size: 24)
            else
              Text(
                label,
                style: GoogleFonts.outfit(
                  color: AppTheme.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (icon != null) ...[
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(color: AppTheme.white, fontSize: 10)),
            ],
          ],
        ),
      ),
    );
  }
}
