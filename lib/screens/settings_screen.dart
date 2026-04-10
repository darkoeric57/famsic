import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../providers/audio_providers.dart';
import '../providers/sleep_timer_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {

  String _formatCountdown(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final handler = ref.watch(audioHandlerProvider);
    final sleepTimer = ref.watch(sleepTimerProvider);

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.creamBackground,
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.deepDark),
        ),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppTheme.deepDark, size: 30),
          onPressed: () => Navigator.maybePop(context),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Sleep Timer ────────────────────────────────────────────────
            _buildSleepTimerCard(settings, sleepTimer),

            const SizedBox(height: 36),

            // ── Playback & Audio ───────────────────────────────────────────
            _buildSectionHeader('PLAYBACK & AUDIO'),

            _buildToggle(
              title: 'Gapless Playback',
              subtitle: 'Seamless transitions between tracks',
              icon: Icons.queue_music,
              value: settings.gaplessPlayback,
              onChanged: (v) async {
                await ref.read(settingsProvider.notifier).setGaplessPlayback(v);
                handler.applyGapless(v);
                _showSnack(v ? 'Gapless playback enabled' : 'Gapless playback disabled');
              },
            ),

            _buildToggle(
              title: 'High-Quality Audio',
              subtitle: 'Maximum fidelity — no lossy resampling',
              icon: Icons.high_quality,
              value: settings.highQualityAudio,
              onChanged: (v) async {
                await ref.read(settingsProvider.notifier).setHighQualityAudio(v);
                await handler.applyHighQuality(v);
                _showSnack(v
                    ? 'High-quality audio ON — audiophile mode 🎵'
                    : 'High-quality audio OFF');
              },
            ),

            const SizedBox(height: 36),

            // ── Current Scan Folder ────────────────────────────────────────
            _buildSectionHeader('MUSIC LIBRARY'),

            _buildInfoTile(
              title: 'Scan Folder',
              subtitle: settings.scanPath != null
                  ? settings.scanPath!.split('/').last
                  : 'All device storage',
              icon: Icons.folder_open,
              trailing: settings.scanPath != null
                  ? IconButton(
                      icon: const Icon(Icons.clear,
                          size: 18, color: AppTheme.secondaryGrey),
                      onPressed: () async {
                        await ref.read(settingsProvider.notifier).clearScanPath();
                        _showSnack('Scan folder cleared');
                      },
                    )
                  : const Icon(Icons.chevron_right,
                      color: AppTheme.secondaryGrey),
            ),

            const SizedBox(height: 36),

            // ── About ──────────────────────────────────────────────────────
            _buildSectionHeader('ABOUT'),

            _buildInfoTile(
              title: 'Famsic',
              subtitle: 'Version 1.0.0 — Built with ❤️',
              icon: Icons.music_note,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Sleep Timer Card ─────────────────────────────────────────────────────

  Widget _buildSleepTimerCard(SettingsState settings, SleepTimerState timerState) {
    final timerOptions = [5, 15, 30, 45, 60];
    final selectedMinutes = settings.sleepTimerMinutes;
    final isRunning = timerState.isRunning;
    final remaining = timerState.remainingTime ?? Duration.zero;

    // Progress: how much of the chosen duration has elapsed
    double progress = 0.0;
    if (isRunning && selectedMinutes > 0) {
      final total = Duration(minutes: selectedMinutes).inSeconds;
      final elapsed = total - remaining.inSeconds;
      progress = (elapsed / total).clamp(0.0, 1.0);
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: AppTheme.deepDark,
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'SLEEP TIMER',
            style: GoogleFonts.outfit(
                color: AppTheme.secondaryGrey,
                fontSize: 11,
                letterSpacing: 2,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 28),

          // Circular progress dial
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: CircularProgressIndicator(
                  value: isRunning ? progress : (selectedMinutes / 60.0),
                  strokeWidth: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  color: isRunning ? AppTheme.accentNeon : Colors.white24,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  isRunning
                      ? Text(
                          _formatCountdown(remaining),
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold),
                        )
                      : Text(
                          '$selectedMinutes',
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 60,
                              fontWeight: FontWeight.bold),
                        ),
                  Text(
                    isRunning ? 'REMAINING' : 'MINUTES',
                    style: GoogleFonts.outfit(
                        color: AppTheme.secondaryGrey,
                        fontSize: 10,
                        letterSpacing: 1.5),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 28),

          // Duration selector (disabled while timer is running)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: timerOptions.map((m) {
                final isSelected = m == selectedMinutes;
                return GestureDetector(
                  onTap: isRunning
                      ? null
                      : () => ref
                          .read(settingsProvider.notifier)
                          .setSleepTimerMinutes(m),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.accentNeon.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.accentNeon
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? AppTheme.accentNeon
                                : AppTheme.secondaryGrey.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$m',
                          style: GoogleFonts.outfit(
                            color: isSelected
                                ? AppTheme.accentNeon
                                : AppTheme.secondaryGrey,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 28),

          // Start / Cancel button
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isRunning) ...[
                OutlinedButton(
                  onPressed: () {
                    ref.read(sleepTimerProvider.notifier).cancelTimer();
                    ref.read(settingsProvider.notifier).setSleepTimerEnabled(false);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.secondaryGrey,
                    side: const BorderSide(color: AppTheme.secondaryGrey),
                    minimumSize: const Size(130, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18)),
                  ),
                  child: Text('CANCEL',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () {
                    ref.read(sleepTimerProvider.notifier).setTimer(Duration(minutes: selectedMinutes));
                    ref.read(settingsProvider.notifier).setSleepTimerEnabled(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentNeon,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 55),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    elevation: 0,
                  ),
                  child: Text('START TIMER',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 14),
      child: Text(
        title,
        style: GoogleFonts.outfit(
            color: AppTheme.secondaryGrey,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.8,
            fontSize: 11),
      ),
    );
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: value
                ? AppTheme.accentNeon.withValues(alpha: 0.1)
                : AppTheme.creamBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon,
              color: value ? AppTheme.accentNeon : AppTheme.secondaryGrey,
              size: 20),
        ),
        title: Text(title,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle,
            style: GoogleFonts.outfit(
                color: AppTheme.secondaryGrey, fontSize: 12)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: Colors.white,
          activeTrackColor: AppTheme.accentNeon,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: AppTheme.secondaryGrey.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.creamBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.accentNeon, size: 20),
        ),
        title: Text(title,
            style: GoogleFonts.outfit(
                fontWeight: FontWeight.w600, fontSize: 15)),
        subtitle: Text(subtitle,
            style: GoogleFonts.outfit(
                color: AppTheme.secondaryGrey, fontSize: 12)),
        trailing: trailing,
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.outfit()),
        backgroundColor: AppTheme.deepDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
