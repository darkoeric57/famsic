import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';
import '../providers/settings_provider.dart';
import '../providers/audio_providers.dart';
import '../providers/sleep_timer_provider.dart';
import '../core/famsic_audio_handler.dart';
import '../widgets/visualizer_styles.dart';


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
    final isDark = settings.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.surfaceDark : AppTheme.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildHeader(context, isDark),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Theme Toggle
                    _buildSectionHeader('DISPLAY & APPEARANCE', isDark),
                    _buildThemeToggleCard(context, isDark),
                    
                    const SizedBox(height: 36),

                    // Sleep Timer
                    _buildSleepTimerCard(settings, sleepTimer, isDark),

                    const SizedBox(height: 36),

                    // Playback & Audio
                    _buildSectionHeader('PLAYBACK & AUDIO', isDark),

                    _buildToggle(
                      title: 'Gapless Playback',
                      subtitle: 'Seamless transitions between tracks',
                      icon: LucideIcons.infinity,
                      value: settings.gaplessPlayback,
                      isDark: isDark,
                      onChanged: (v) async {
                        await ref.read(settingsProvider.notifier).setGaplessPlayback(v);
                        handler.applyGapless(v);
                        _showSnack(v ? 'Gapless playback enabled' : 'Gapless playback disabled');
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildToggle(
                      title: 'High-Quality Audio',
                      subtitle: 'Studio Mastering & High-Fidelity spatial processing',
                      icon: LucideIcons.music,
                      value: settings.highQualityAudio,
                      isDark: isDark,
                      onChanged: (v) async {
                        await ref.read(settingsProvider.notifier).setHighQualityAudio(v);
                        await handler.applyHighQuality(v);
                        _showSnack(v
                            ? 'Studio Mastering ON — Audiophile fidelity 🎵'
                            : 'Standard Audio Mode');
                      },
                    ),

                    const SizedBox(height: 36),

                    // Stereo Enhancement
                    _buildSectionHeader('STEREO ENHANCEMENT', isDark),
                    _buildStereoEnhancementCard(settings, handler, isDark),

                    const SizedBox(height: 36),

                    // Visualizer Engine
                    _buildSectionHeader('VISUALIZER ENGINE', isDark),
                    _buildVisualizerEngineCard(settings, isDark),

                    const SizedBox(height: 36),

                    // Music Library
                    _buildSectionHeader('MUSIC LIBRARY ENGINE', isDark),
                    _buildLibraryEngineCard(settings, isDark),

                    const SizedBox(height: 36),

                    // About
                    _buildSectionHeader('ABOUT', isDark),

                    _buildInfoTile(
                      title: 'Famsic',
                      subtitle: 'Version 1.0.0 — Ultimate Fidelity',
                      icon: LucideIcons.info,
                      isDark: isDark,
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 48,
              height: 48,
              decoration: isDark
                  ? AppTheme.pathfinderDarkDecoration(borderRadius: 16, borderWidth: 1.5)
                  : AppTheme.neumorphicDecoration(borderRadius: 16),
              child: Icon(Icons.chevron_left, color: isDark ? Colors.white : AppTheme.deepDark, size: 28),
            ),
          ),
          const SizedBox(width: 20),
          Text(
            "Settings",
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : AppTheme.deepDark,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeToggleCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: isDark
          ? AppTheme.pathfinderDarkDecoration(borderRadius: 24, borderWidth: 1.5)
          : AppTheme.neumorphicDecoration(borderRadius: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.neonCyan.withValues(alpha: 0.15) : Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDark
                ? [BoxShadow(color: AppTheme.neonCyan.withValues(alpha: 0.3), blurRadius: 10)]
                : [BoxShadow(color: Colors.orange.withValues(alpha: 0.3), blurRadius: 10)],
            ),
            child: Icon(
              isDark ? LucideIcons.moon : LucideIcons.sun,
              color: isDark ? AppTheme.neonCyan : Colors.orange,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Theme Mode",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.deepDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isDark ? "Dark & Premium" : "Light & Clean",
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : AppTheme.secondaryGrey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isDark,
            onChanged: (val) => ref.read(settingsProvider.notifier).setIsDarkMode(val),
            activeColor: isDark ? AppTheme.pathfinderDark : Colors.white,
            activeTrackColor: isDark ? AppTheme.neonCyan : Colors.orange,
            inactiveThumbColor: isDark ? AppTheme.pathfinderDark : Colors.white,
            inactiveTrackColor: isDark ? AppTheme.neonCyan : Colors.orange,
          ),
        ],
      ),
    );
  }

  // ── Sleep Timer Card ─────────────────────────────────────────────────────

  Widget _buildSleepTimerCard(SettingsState settings, SleepTimerState timerState, bool isDark) {
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
      // Premium look matching Sovereign Utility design
      decoration: isDark
          ? AppTheme.pathfinderDarkDecoration(borderRadius: 40, borderWidth: 2.0)
          : AppTheme.glowDecoration(color: Colors.black, opacity: 0.05, blurRadius: 30),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(LucideIcons.timer, size: 16, color: isDark ? AppTheme.neonCyan : AppTheme.accentNeon),
              const SizedBox(width: 8),
              Text(
                'SLEEP TIMER',
                style: GoogleFonts.outfit(
                    color: isDark ? AppTheme.neonCyan : AppTheme.accentNeon,
                    fontSize: 12,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Circular progress dial
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 180,
                height: 180,
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: isRunning ? progress : (selectedMinutes / 60.0)),
                  duration: const Duration(milliseconds: 300),
                  builder: (context, val, _) => CircularProgressIndicator(
                    value: val,
                    strokeWidth: 10,
                    backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.secondaryGrey.withValues(alpha: 0.1),
                    color: isRunning 
                        ? (isDark ? AppTheme.neonCyan : AppTheme.accentNeon)
                        : (isDark ? Colors.white24 : AppTheme.secondaryGrey.withValues(alpha: 0.3)),
                  ),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  isRunning
                      ? Text(
                          _formatCountdown(remaining),
                          style: GoogleFonts.outfit(
                              color: isDark ? Colors.white : AppTheme.deepDark,
                              fontSize: 44,
                              fontWeight: FontWeight.w900,
                              shadows: isDark ? [Shadow(color: AppTheme.neonCyan, blurRadius: 10)] : []),
                        )
                      : Text(
                          '$selectedMinutes',
                          style: GoogleFonts.outfit(
                              color: isDark ? Colors.white : AppTheme.deepDark,
                              fontSize: 60,
                              fontWeight: FontWeight.bold),
                        ),
                  Text(
                    isRunning ? 'REMAINING' : 'MINUTES',
                    style: GoogleFonts.outfit(
                        color: isDark ? Colors.white70 : AppTheme.secondaryGrey,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 35),

          // Duration selector (disabled while timer is running)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark ? AppTheme.neonCyan.withValues(alpha: 0.2) : AppTheme.accentNeon.withValues(alpha: 0.15))
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? (isDark ? AppTheme.neonCyan : AppTheme.accentNeon)
                            : Colors.transparent,
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$m',
                          style: GoogleFonts.outfit(
                            color: isSelected
                                ? (isDark ? AppTheme.neonCyan : AppTheme.accentNeon)
                                : (isDark ? Colors.white60 : AppTheme.secondaryGrey),
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 35),

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
                    foregroundColor: isDark ? Colors.white : AppTheme.secondaryGrey,
                    side: BorderSide(color: isDark ? Colors.white30 : AppTheme.secondaryGrey, width: 2),
                    minimumSize: const Size(140, 52),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('CANCEL',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, letterSpacing: 1)),
                ),
              ] else ...[
                ElevatedButton(
                  onPressed: () {
                    ref.read(sleepTimerProvider.notifier).setTimer(Duration(minutes: selectedMinutes));
                    ref.read(settingsProvider.notifier).setSleepTimerEnabled(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.neonCyan : AppTheme.accentNeon,
                    foregroundColor: isDark ? AppTheme.deepDark : Colors.white,
                    minimumSize: const Size(220, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: isDark ? 8 : 4,
                    shadowColor: isDark ? AppTheme.neonCyan : AppTheme.accentNeon,
                  ),
                  child: Text('START TIMER',
                      style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
            color: isDark ? AppTheme.neonCyan : AppTheme.accentNeon,
            fontWeight: FontWeight.bold,
            letterSpacing: 2.0,
            fontSize: 12),
      ),
    );
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: isDark
          ? AppTheme.pathfinderDarkDecoration(borderRadius: 20, borderWidth: 1)
          : AppTheme.neumorphicDecoration(borderRadius: 20),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark 
                ? (value ? AppTheme.neonCyan.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05))
                : (value ? AppTheme.accentNeon.withValues(alpha: 0.15) : AppTheme.creamBackground),
            borderRadius: BorderRadius.circular(14),
            border: isDark && value ? Border.all(color: AppTheme.neonCyan.withValues(alpha: 0.3)) : null,
          ),
          child: Icon(icon, color: isDark ? (value ? AppTheme.neonCyan : Colors.white60) : (value ? AppTheme.accentNeon : AppTheme.secondaryGrey), size: 22),
        ),
        title: Text(title,
            style: GoogleFonts.outfit(color: isDark ? Colors.white : AppTheme.deepDark, fontWeight: FontWeight.w700, fontSize: 16)),
        subtitle: Text(subtitle,
            style: GoogleFonts.outfit(color: isDark ? Colors.white60 : AppTheme.secondaryGrey, fontSize: 12)),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: isDark ? AppTheme.pathfinderDark : Colors.white,
          activeTrackColor: isDark ? AppTheme.neonCyan : AppTheme.accentNeon,
          inactiveThumbColor: isDark ? AppTheme.pathfinderDark : Colors.white,
          inactiveTrackColor: isDark ? Colors.white24 : AppTheme.secondaryGrey.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    required bool isDark,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: isDark
          ? AppTheme.pathfinderDarkDecoration(borderRadius: 20, borderWidth: 1)
          : AppTheme.neumorphicDecoration(borderRadius: 20),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.creamBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: isDark ? AppTheme.neonCyan : AppTheme.accentNeon, size: 22),
        ),
        title: Text(title,
            style: GoogleFonts.outfit(color: isDark ? Colors.white : AppTheme.deepDark, fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(subtitle,
            style: GoogleFonts.outfit(color: isDark ? Colors.white60 : AppTheme.secondaryGrey, fontSize: 12)),
        trailing: trailing,
      ),
    );
  }

  Widget _buildStereoEnhancementCard(SettingsState settings, FamsicAudioHandler handler, bool isDark) {
    final enabled = settings.stereoEnabled;
    final strength = settings.stereoStrength;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: isDark
          ? AppTheme.pathfinderDarkDecoration(borderRadius: 24, borderWidth: 1.5)
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              gradient: const LinearGradient(
                colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)], // Sophisticated metal-ish light gradient
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.neonCyan.withValues(alpha: 0.1) : AppTheme.accentNeon.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppTheme.neonCyan.withValues(alpha: 0.3) : AppTheme.accentNeon.withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(LucideIcons.radio, color: isDark ? AppTheme.neonCyan : AppTheme.accentNeon, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Stereo Wide / Surround",
                      style: GoogleFonts.outfit(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppTheme.deepDark,
                      ),
                    ),
                    Text(
                      "Holographic spatial depth",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : AppTheme.secondaryGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: (val) async {
                  await ref.read(settingsProvider.notifier).setStereoEnabled(val);
                  handler.applyStereoEnhancement(val, strength);
                  _showSnack(val ? 'Stereo Surround ON' : 'Stereo Surround OFF');
                },
                activeColor: isDark ? AppTheme.pathfinderDark : Colors.white,
                activeTrackColor: isDark ? AppTheme.neonCyan : AppTheme.accentNeon,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Spatial Intensity",
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white70 : AppTheme.deepDark.withValues(alpha: 0.8),
                  ),
                ),
                Text(
                  "${(strength / 10).toInt()}%",
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: isDark ? AppTheme.neonCyan : AppTheme.accentNeon,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Fancy Metallic Slider
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                border: Border.all(
                  color: isDark ? Colors.white10 : Colors.black12,
                ),
              ),
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  activeTrackColor: isDark ? AppTheme.neonCyan : AppTheme.accentNeon,
                  inactiveTrackColor: isDark ? Colors.white10 : Colors.black12,
                  thumbColor: isDark ? AppTheme.neonCyan : AppTheme.accentNeon,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                  trackShape: const RoundedRectSliderTrackShape(),
                ),
                child: Slider(
                  value: strength.toDouble(),
                  min: 0,
                  max: 1000,
                  onChanged: (val) {
                    final intVal = val.toInt();
                    ref.read(settingsProvider.notifier).setStereoStrength(intVal);
                    handler.applyStereoEnhancement(enabled, intVal);
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickScanFolder() async {
    try {
      final String? selectedDirectory = await FilePicker.getDirectoryPath();
      if (selectedDirectory != null) {
        await ref.read(settingsProvider.notifier).addScanPath(selectedDirectory);
        ref.invalidate(songListProvider);
        _showSnack('Added source: ${selectedDirectory.split('/').last}');
      }
    } catch (e) {
      _showSnack('Error selecting folder');
    }
  }

  Widget _buildLibraryEngineCard(SettingsState settings, bool isDark) {
    final scanPaths = settings.scanPaths;
    final hasPaths = scanPaths.isNotEmpty;
    final pathName = hasPaths 
        ? (scanPaths.length == 1 ? scanPaths.first.split('/').last : '${scanPaths.length} SOURCES')
        : 'All Device Storage';

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: isDark
          ? AppTheme.pathfinderDarkDecoration(borderRadius: 24, borderWidth: 1.5)
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
              gradient: const LinearGradient(
                colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.neonCyan.withValues(alpha: 0.1) : AppTheme.accentNeon.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(LucideIcons.hardDrive, color: isDark ? AppTheme.neonCyan : AppTheme.accentNeon, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Scan Engine",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppTheme.deepDark,
                      ),
                    ),
                    Text(
                      "Source: $pathName",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: isDark ? AppTheme.neonCyan.withValues(alpha: 0.8) : AppTheme.accentNeon,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (hasPaths)
                IconButton(
                  onPressed: () async {
                    // Logic to clear all paths
                    for (final path in List.from(settings.scanPaths)) {
                      await ref.read(settingsProvider.notifier).removeScanPath(path);
                    }
                    ref.invalidate(songListProvider);
                    _showSnack('Scan engine reset to global');
                  },
                  icon: Icon(LucideIcons.refreshCcw, size: 20, color: isDark ? Colors.white60 : AppTheme.secondaryGrey),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _pickScanFolder,
                  icon: const Icon(LucideIcons.folderInput, size: 18),
                  label: Text('ADD SOURCE', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? AppTheme.neonCyan : AppTheme.accentNeon,
                    foregroundColor: isDark ? AppTheme.deepDark : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                  ),
                ),
              ),
              if (hasPaths) ...[
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                  ),
                  child: IconButton(
                    onPressed: () {
                      ref.invalidate(songListProvider);
                      _showSnack('Refreshing Library...');
                    },
                    icon: Icon(LucideIcons.search, color: isDark ? Colors.white : AppTheme.deepDark),
                    tooltip: 'Rescan Engine',
                  ),
                ),
              ],
            ],
          ),
          if (!hasPaths) ...[
            const SizedBox(height: 16),
            Text(
              "Currently scanning all device storage. Select folders to focus your library.",
              style: GoogleFonts.outfit(fontSize: 11, color: isDark ? Colors.white38 : AppTheme.secondaryGrey),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildVisualizerEngineCard(SettingsState settings, bool isDark) {

    final enabled = settings.visualizerEnabled;
    final currentStyle = settings.visualizerStyle;
    final styles = ['Neon Bars', 'Pulse Waves', 'Neon Pulse', 'Gravity Drop', 'Cyber Circuit', 'Cyber Grid', 'Spectrum Dots'];
    final playbackState = ref.watch(playbackStateProvider).value;
    final isPlaying = playbackState?.playing ?? false;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: isDark
          ? AppTheme.pathfinderDarkDecoration(borderRadius: 24, borderWidth: 1.5)
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 1.5),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, 10)),
              ],
              gradient: const LinearGradient(
                colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.neonCyan.withValues(alpha: 0.1) : AppTheme.accentNeon.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: (isDark ? AppTheme.neonCyan : AppTheme.accentNeon).withValues(alpha: 0.2)),
                ),
                child: Icon(LucideIcons.activity, color: isDark ? AppTheme.neonCyan : AppTheme.accentNeon, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Visualizer Hub",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : AppTheme.deepDark,
                      ),
                    ),
                    Text(
                      "Dynamic Acoustic Analysis",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : AppTheme.secondaryGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: enabled,
                onChanged: (val) => ref.read(settingsProvider.notifier).setVisualizerEnabled(val),
                activeColor: isDark ? AppTheme.pathfinderDark : Colors.white,
                activeTrackColor: isDark ? AppTheme.neonCyan : AppTheme.accentNeon,
              ),
            ],
          ),
          if (enabled) ...[
            const SizedBox(height: 24),
            // Premium Preview Area
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Center(
                      child: DynamicVisualizer(
                        isPlaying: isPlaying,
                        height: 80,
                        width: double.infinity,
                      ),
                    ),
                    if (!isPlaying)
                      Center(
                        child: Text(
                          "PREVIEW (PLAY AUDIO TO ANIMATE)",
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white24 : Colors.black26,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "SELECT SOVEREIGN STYLE",
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isDark ? AppTheme.neonCyan.withValues(alpha: 0.7) : AppTheme.accentNeon,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: styles.length,
                itemBuilder: (context, index) {
                  final style = styles[index];
                  final isSelected = currentStyle == style;
                  return GestureDetector(
                    onTap: () => ref.read(settingsProvider.notifier).setVisualizerStyle(style),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? (isDark ? AppTheme.neonCyan.withValues(alpha: 0.2) : AppTheme.accentNeon.withValues(alpha: 0.1))
                            : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected 
                              ? (isDark ? AppTheme.neonCyan : AppTheme.accentNeon)
                              : (isDark ? Colors.white10 : Colors.black12),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected && isDark
                          ? [BoxShadow(color: AppTheme.neonCyan.withValues(alpha: 0.1), blurRadius: 10)]
                          : [],
                      ),
                      child: Center(
                        child: Text(
                          style.toUpperCase(),
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                            color: isSelected 
                                ? (isDark ? AppTheme.neonCyan : AppTheme.accentNeon)
                                : (isDark ? Colors.white60 : AppTheme.secondaryGrey),
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    final isDark = ref.read(settingsProvider).isDarkMode;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message, 
          style: GoogleFonts.outfit(color: isDark ? AppTheme.deepDark : Colors.white, fontWeight: FontWeight.w600)
        ),
        backgroundColor: isDark ? AppTheme.neonCyan : AppTheme.deepDark,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
