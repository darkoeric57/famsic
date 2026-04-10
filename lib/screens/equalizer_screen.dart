import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/playback_controls.dart';
import '../providers/audio_providers.dart';
import '../providers/equalizer_provider.dart';

class EqualizerScreen extends ConsumerStatefulWidget {
  const EqualizerScreen({super.key});

  @override
  ConsumerState<EqualizerScreen> createState() => _EqualizerScreenState();
}

class _EqualizerScreenState extends ConsumerState<EqualizerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  bool _initializing = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) => _initEq());
  }

  Future<void> _initEq() async {
    if (!mounted) return;
    final eqState = ref.read(equalizerProvider);
    if (eqState.initialized) return;

    setState(() => _initializing = true);

    final handler = ref.read(audioHandlerProvider);

    // Give the player a moment to open the audio session
    await Future.delayed(const Duration(milliseconds: 800));
    final sessionId = handler.audioSessionId ?? 0;

    if (mounted) {
      await ref
          .read(equalizerProvider.notifier)
          .initialize(sessionId);
      setState(() => _initializing = false);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eq = ref.watch(equalizerProvider);

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.creamBackground,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.chevron_left,
              color: AppTheme.deepDark, size: 30),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Equalizer',
          style: GoogleFonts.outfit(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: AppTheme.deepDark),
        ),
        actions: [
          // EQ ON/OFF master toggle
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Text(
                  eq.enabled ? 'ON' : 'OFF',
                  style: GoogleFonts.outfit(
                      color: eq.enabled
                          ? AppTheme.accentNeon
                          : AppTheme.secondaryGrey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
                const SizedBox(width: 6),
                Switch(
                  value: eq.enabled,
                  onChanged: (v) =>
                      ref.read(equalizerProvider.notifier).setEnabled(v),
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppTheme.accentNeon,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor:
                      AppTheme.secondaryGrey.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _initializing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: AppTheme.accentNeon),
                  SizedBox(height: 16),
                  Text('Initializing equalizer…',
                      style: TextStyle(color: AppTheme.secondaryGrey)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // Bass & Loudness dials
                        _buildBassLoudnessSection(eq),
                        const SizedBox(height: 20),

                        // Preset chips
                        _buildPresets(eq),
                        const SizedBox(height: 20),

                        // EQ Band sliders
                        _buildEqBands(eq),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                // Mini Player
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: const PlaybackControls(isMini: true),
                ),
              ],
            ),
    );
  }

  // ── Bass & Loudness ────────────────────────────────────────────────────────

  Widget _buildBassLoudnessSection(EqualizerState eq) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.deepDark,
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentNeon.withValues(alpha: 0.08),
            blurRadius: 30,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Section label
          Text(
            'SOUND ENHANCE',
            style: GoogleFonts.outfit(
                color: AppTheme.secondaryGrey,
                fontSize: 10,
                letterSpacing: 2,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 24),

          // Bass dial + Loudness dial side by side
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildDial(
                label: 'BASS BOOST',
                value: eq.bassStrength.toDouble(),
                min: 0,
                max: 1000,
                color: const Color(0xFF00E5FF),
                unit: '',
                displayValue:
                    '${(eq.bassStrength / 10).toStringAsFixed(0)}%',
                onChanged: (v) => ref
                    .read(equalizerProvider.notifier)
                    .setBassStrength(v.round()),
              ),
              Container(
                width: 1,
                height: 140,
                color: Colors.white.withValues(alpha: 0.06),
              ),
              _buildDial(
                label: 'LOUDNESS',
                value: eq.loudnessGainMb.toDouble(),
                min: 0,
                max: 1000,
                color: const Color(0xFFFFD600),
                unit: '',
                displayValue:
                    '+${(eq.loudnessGainMb / 10).toStringAsFixed(0)}dB',
                onChanged: (v) => ref
                    .read(equalizerProvider.notifier)
                    .setLoudnessGain(v.round()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDial({
    required String label,
    required double value,
    required double min,
    required double max,
    required Color color,
    required String unit,
    required String displayValue,
    required ValueChanged<double> onChanged,
  }) {
    final normalised = ((value - min) / (max - min)).clamp(0.0, 1.0);
    const size = 110.0;
    const strokeWidth = 9.0;

    return Column(
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                color: AppTheme.secondaryGrey,
                fontSize: 9,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        GestureDetector(
          onPanUpdate: (details) {
            // Dragging up increases, down decreases
            final delta = -details.delta.dy / 1.5;
            final newVal = (value + delta * (max - min) / 100)
                .clamp(min, max);
            onChanged(newVal);
          },
          child: AnimatedBuilder(
            animation: _glowController,
            builder: (_, __) {
              return SizedBox(
                width: size,
                height: size,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow behind arc
                    if (normalised > 0)
                      Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(
                                alpha: 0.15 +
                                    _glowController.value * 0.1 * normalised,
                              ),
                              blurRadius: 20,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    // Background arc
                    CustomPaint(
                      size: const Size(size, size),
                      painter: _ArcPainter(
                        progress: 0,
                        color: Colors.white.withValues(alpha: 0.06),
                        strokeWidth: strokeWidth,
                      ),
                    ),
                    // Filled arc
                    CustomPaint(
                      size: const Size(size, size),
                      painter: _ArcPainter(
                        progress: normalised,
                        color: color,
                        strokeWidth: strokeWidth,
                      ),
                    ),
                    // Center text
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayValue,
                          style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        if (unit.isNotEmpty)
                          Text(unit,
                              style: const TextStyle(
                                  color: AppTheme.secondaryGrey,
                                  fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Horizontal slider below dial
        SizedBox(
          width: 120,
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: color,
              inactiveTrackColor: Colors.white.withValues(alpha: 0.08),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: normalised,
              onChanged: (v) => onChanged(min + v * (max - min)),
            ),
          ),
        ),
      ],
    );
  }

  // ── Presets ────────────────────────────────────────────────────────────────

  Widget _buildPresets(EqualizerState eq) {
    return SizedBox(
      height: 42,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: eqPresets.keys.map((name) {
          final isSelected = eq.activePreset == name;
          return GestureDetector(
            onTap: () =>
                ref.read(equalizerProvider.notifier).applyPreset(name),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.deepDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.accentNeon
                      : Colors.transparent,
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.accentNeon.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 4,
                        ),
                      ],
              ),
              child: Text(
                name.toUpperCase(),
                style: GoogleFonts.outfit(
                  color: isSelected ? AppTheme.accentNeon : AppTheme.deepDark,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── EQ Bands ───────────────────────────────────────────────────────────────

  Widget _buildEqBands(EqualizerState eq) {
    if (eq.bands.isEmpty) {
      // Show placeholder sliders when not initialised
      return _buildEqBandsPlaceholder();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EQUALIZER BANDS',
                style: GoogleFonts.outfit(
                    color: AppTheme.secondaryGrey,
                    fontSize: 10,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600),
              ),
              GestureDetector(
                onTap: () =>
                    ref.read(equalizerProvider.notifier).applyPreset('Flat'),
                child: Text(
                  'RESET',
                  style: GoogleFonts.outfit(
                      color: AppTheme.accentNeon,
                      fontSize: 10,
                      letterSpacing: 1,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // dB scale labels + band sliders
          SizedBox(
            height: 220,
            child: Row(
              children: [
                // dB labels column
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _dbLabel('+15'),
                    _dbLabel('+7'),
                    _dbLabel('0'),
                    _dbLabel('-7'),
                    _dbLabel('-15'),
                  ],
                ),
                const SizedBox(width: 8),
                // Zero line + sliders
                Expanded(
                  child: Stack(
                    children: [
                      // Zero-line
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            height: 1,
                            color: AppTheme.secondaryGrey
                                .withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      // Band sliders
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: eq.bands.map((band) {
                          return _buildBandSlider(band, eq);
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          // Frequency labels
          Row(
            children: [
              const SizedBox(width: 34), // align with dB labels
              ...eq.bands.map((b) => Expanded(
                    child: Center(
                      child: Text(b.freqLabel,
                          style: GoogleFonts.outfit(
                              color: AppTheme.secondaryGrey,
                              fontSize: 9,
                              letterSpacing: 0.5)),
                    ),
                  )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBandSlider(EqBand band, EqualizerState eq) {
    final minMb = eq.minLevelMb.toDouble();
    final maxMb = eq.maxLevelMb.toDouble();
    // Clamp displayed value to device range
    final level = band.levelMb.toDouble().clamp(minMb, maxMb);
    final isPositive = level >= 0;

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: RotatedBox(
              quarterTurns: -1,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 4,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape:
                      const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: isPositive
                      ? AppTheme.accentNeon
                      : Colors.redAccent,
                  inactiveTrackColor:
                      AppTheme.secondaryGrey.withValues(alpha: 0.15),
                  thumbColor: Colors.white,
                  overlayColor:
                      AppTheme.accentNeon.withValues(alpha: 0.2),
                  valueIndicatorTextStyle:
                      GoogleFonts.outfit(color: Colors.white, fontSize: 10),
                  showValueIndicator: ShowValueIndicator.onDrag,
                ),
                child: Slider(
                  min: minMb,
                  max: maxMb,
                  value: level,
                  divisions: 30,
                  label: '${(level / 100).toStringAsFixed(1)}dB',
                  onChanged: eq.enabled
                      ? (v) => ref
                          .read(equalizerProvider.notifier)
                          .setBandLevel(band.index, v.round())
                      : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEqBandsPlaceholder() {
    // Show dummy sliders before EQ initialises
    const labels = ['60Hz', '230Hz', '910Hz', '3.6kHz', '14kHz'];
    final values = [0.0, 0.0, 0.0, 0.0, 0.0];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Text('EQUALIZER BANDS',
              style: GoogleFonts.outfit(
                  color: AppTheme.secondaryGrey,
                  fontSize: 10,
                  letterSpacing: 1.5)),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: labels.asMap().entries.map((e) {
                return Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: -1,
                          child: Slider(
                            min: -1500,
                            max: 1500,
                            value: values[e.key],
                            onChanged: null,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: labels
                .map((l) => Text(l,
                    style: GoogleFonts.outfit(
                        color: AppTheme.secondaryGrey, fontSize: 9)))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _dbLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.outfit(
          color: AppTheme.secondaryGrey,
          fontSize: 9,
          fontWeight: FontWeight.w600),
    );
  }
}

// ── Arc Painter ───────────────────────────────────────────────────────────────

class _ArcPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ArcPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: size.width / 2 - strokeWidth / 2,
    );
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Start from bottom-left (-210°) sweeping clockwise 240°
    const startAngle = math.pi * 0.75;
    const sweepFull = math.pi * 1.5;

    // Background full arc
    if (progress == 0) {
      canvas.drawArc(rect, startAngle, sweepFull, false, paint);
    } else {
      canvas.drawArc(rect, startAngle, sweepFull * progress, false, paint);
    }
  }

  @override
  bool shouldRepaint(_ArcPainter old) =>
      old.progress != progress || old.color != color;
}
