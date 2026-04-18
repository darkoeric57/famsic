import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/playback_controls.dart';
import '../providers/equalizer_provider.dart';

class EqualizerScreen extends ConsumerStatefulWidget {
  const EqualizerScreen({super.key});

  @override
  ConsumerState<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends ConsumerState<EqualizerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the EqState for ANY changes
    final state = ref.watch(equalizerProvider);
    final controller = ref.read(equalizerProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.creamBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left, color: AppTheme.deepDark, size: 30),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Professional EQ',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: AppTheme.deepDark,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Text(
                  state.isEnabled ? 'ACTIVE' : 'BYPASS',
                  style: GoogleFonts.outfit(
                    color: state.isEnabled ? AppTheme.accentNeon : AppTheme.secondaryGrey,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(width: 8),
                Switch(
                  value: state.isEnabled,
                  onChanged: (v) => controller.setEqEnabled(v),
                  activeTrackColor: AppTheme.accentNeon,
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  // Presets Section
                  _buildPresetsHeader(state),
                  const SizedBox(height: 12),
                  _buildPresetsList(state, controller),
                  
                  const SizedBox(height: 30),
                  
                  // Main 10-Band EQ Engine
                  _buildMainEngine(state, controller),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
          
          // Mini Player
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceLight,
              border: Border(top: BorderSide(color: Colors.black.withOpacity(0.05))),
            ),
            child: const PlaybackControls(isMini: true),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsHeader(EqState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'PRESETS',
          style: GoogleFonts.outfit(
            color: AppTheme.deepDark.withOpacity(0.4),
            fontSize: 10,
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          state.activePreset.toUpperCase(),
          style: GoogleFonts.outfit(
            color: AppTheme.accentNeon,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildPresetsList(EqState state, EqController controller) {
    final presets = eqPresets.keys.toList();
    return SizedBox(
      height: 45,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: presets.length,
        itemBuilder: (context, index) {
          final name = presets[index];
          final isSelected = state.activePreset == name;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: ChoiceChip(
              label: Text(name),
              selected: isSelected,
              onSelected: (v) => controller.applyPreset(name),
              selectedColor: AppTheme.accentNeon.withOpacity(0.2),
              labelStyle: GoogleFonts.outfit(
                color: isSelected ? AppTheme.accentNeon : AppTheme.deepDark,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainEngine(EqState state, EqController controller) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: AppTheme.pathfinderDarkDecoration(borderRadius: 36, borderWidth: 2.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '10-BAND PRECISION DSP',
                style: GoogleFonts.outfit(
                  color: Colors.white38,
                  fontSize: 9,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Icon(Icons.equalizer, color: Colors.white24, size: 16),
            ],
          ),
          const SizedBox(height: 30),
          
          // The Sliders Window
          SizedBox(
            height: 240,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(10, (index) {
                return _buildVerticalBand(index, state, controller);
              }),
            ),
          ),
          
          const SizedBox(height: 10),
          // dB Axis Markers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _dbLegend('-12dB'),
              _dbLegend('0dB'),
              _dbLegend('+12dB'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalBand(int index, EqState state, EqController controller) {
    final freqLabels = ['32', '64', '125', '250', '500', '1k', '2k', '4k', '8k', '16k'];
    final level = state.bandLevels[index];

    return Expanded(
      child: Column(
        children: [
          // The Slider
          Expanded(
            child: RotatedBox(
              quarterTurns: -1,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: AppTheme.neonCyan,
                  inactiveTrackColor: Colors.white.withOpacity(0.05),
                  thumbColor: Colors.white,
                  valueIndicatorTextStyle: GoogleFonts.outfit(color: Colors.black, fontSize: 10),
                  showValueIndicator: ShowValueIndicator.always,
                ),
                child: Slider(
                  min: -12.0,
                  max: 12.0,
                  value: level,
                  onChanged: (v) => controller.updateBandLevel(index, v),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Freq Label
          Text(
            freqLabels[index],
            style: GoogleFonts.outfit(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _dbLegend(String label) {
    return Text(label, style: GoogleFonts.outfit(color: Colors.white24, fontSize: 8, fontWeight: FontWeight.bold));
  }
}
