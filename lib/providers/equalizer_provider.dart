import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Data Models ────────────────────────────────────────────────────────────

class EqBand {
  final int index;
  final int centerFreqHz; // center freq in Hz (millihertz / 1000)
  final int levelMb; // current level in millibels

  EqBand({required this.index, required this.centerFreqHz, required this.levelMb});

  EqBand copyWith({int? levelMb}) =>
      EqBand(index: index, centerFreqHz: centerFreqHz, levelMb: levelMb ?? this.levelMb);

  String get freqLabel {
    final hz = centerFreqHz;
    if (hz >= 1000) return '${(hz / 1000).toStringAsFixed(hz % 1000 == 0 ? 0 : 1)}kHz';
    return '${hz}Hz';
  }
}

class EqualizerState {
  final List<EqBand> bands;
  final int minLevelMb;
  final int maxLevelMb;
  final bool enabled;
  final int bassStrength; // 0–1000
  final int loudnessGainMb; // 0–1000 millibels extra gain
  final String activePreset; // 'Flat','Bass','Rock','Pop','Classical','Custom'
  final bool initialized;

  EqualizerState({
    this.bands = const [],
    this.minLevelMb = -1500,
    this.maxLevelMb = 1500,
    this.enabled = true,
    this.bassStrength = 0,
    this.loudnessGainMb = 0,
    this.activePreset = 'Flat',
    this.initialized = false,
  });

  EqualizerState copyWith({
    List<EqBand>? bands,
    int? minLevelMb,
    int? maxLevelMb,
    bool? enabled,
    int? bassStrength,
    int? loudnessGainMb,
    String? activePreset,
    bool? initialized,
  }) {
    return EqualizerState(
      bands: bands ?? this.bands,
      minLevelMb: minLevelMb ?? this.minLevelMb,
      maxLevelMb: maxLevelMb ?? this.maxLevelMb,
      enabled: enabled ?? this.enabled,
      bassStrength: bassStrength ?? this.bassStrength,
      loudnessGainMb: loudnessGainMb ?? this.loudnessGainMb,
      activePreset: activePreset ?? this.activePreset,
      initialized: initialized ?? this.initialized,
    );
  }
}

// ─── Presets ─────────────────────────────────────────────────────────────────
// Values in millibels relative to 0. Device range is typically -1500..+1500.

const Map<String, List<int>> eqPresets = {
  'Flat': [0, 0, 0, 0, 0],
  'Bass': [1000, 600, 0, 0, 0],
  'Rock': [700, 200, -100, 400, 600],
  'Pop': [-100, 300, 700, 300, -100],
  'Classical': [500, 300, -200, 300, 500],
  'Club': [0, 400, 600, 500, 100],
  'Dance': [800, 0, 500, 0, 700],
};

// ─── Notifier ────────────────────────────────────────────────────────────────

class EqualizerNotifier extends Notifier<EqualizerState> {
  static const _ch = MethodChannel('com.famsic.app/equalizer');

  static const _pBass = 'eq_bass_strength';
  static const _pLoudness = 'eq_loudness_gain';
  static const _pPreset = 'eq_preset';
  static const _pEnabled = 'eq_enabled';
  static const _pBands = 'eq_bands';

  @override
  EqualizerState build() => EqualizerState();

  /// Call this once you have the just_audio session ID.
  Future<void> initialize(int audioSessionId) async {
    try {
      final raw = await _ch.invokeMethod<Map>('init', {'sessionId': audioSessionId});
      final info = raw ?? {};
      final prefs = await SharedPreferences.getInstance();

      // Restore persisted values
      final savedBass = prefs.getInt(_pBass) ?? 0;
      final savedLoudness = prefs.getInt(_pLoudness) ?? 0;
      final savedPreset = prefs.getString(_pPreset) ?? 'Flat';
      final savedEnabled = prefs.getBool(_pEnabled) ?? true;
      final savedBandLevels = prefs.getStringList(_pBands);

      final rawBands = (info['bands'] as List?) ?? [];
      final minMb = (info['minLevel'] as num?)?.toInt() ?? -1500;
      final maxMb = (info['maxLevel'] as num?)?.toInt() ?? 1500;

      List<EqBand> bands = rawBands.map<EqBand>((b) {
        final map = b as Map;
        return EqBand(
          index: (map['index'] as num).toInt(),
          centerFreqHz: ((map['centerFreq'] as num).toInt()) ~/ 1000,
          levelMb: (map['level'] as num).toInt(),
        );
      }).toList();

      // Restore saved band levels
      if (savedBandLevels != null && savedBandLevels.length == bands.length) {
        final levels = savedBandLevels.map(int.parse).toList();
        await _ch.invokeMethod('applyBands', {'levels': levels});
        bands = bands
            .asMap()
            .entries
            .map((e) => e.value.copyWith(levelMb: levels[e.key]))
            .toList();
      } else if (eqPresets.containsKey(savedPreset)) {
        await _applyPresetNative(savedPreset, bands.length, minMb, maxMb);
      }

      await _ch.invokeMethod('setBassBoost', {'strength': savedBass});
      await _ch.invokeMethod('setLoudness', {'gainMb': savedLoudness});
      await _ch.invokeMethod('setEnabled', {'enabled': savedEnabled});

      state = EqualizerState(
        bands: bands,
        minLevelMb: minMb,
        maxLevelMb: maxMb,
        enabled: savedEnabled,
        bassStrength: savedBass,
        loudnessGainMb: savedLoudness,
        activePreset: savedPreset,
        initialized: true,
      );
    } catch (e) {
      print('EqualizerNotifier.initialize error: $e');
      state = state.copyWith(initialized: false);
    }
  }

  Future<void> setBandLevel(int bandIndex, int levelMb) async {
    try {
      await _ch.invokeMethod('setBandLevel', {'band': bandIndex, 'level': levelMb});
      final newBands = state.bands
          .map((b) => b.index == bandIndex ? b.copyWith(levelMb: levelMb) : b)
          .toList();
      state = state.copyWith(bands: newBands, activePreset: 'Custom');
      await _persistBands(newBands);
    } catch (e) {
      print('EqualizerNotifier.setBandLevel error: $e');
    }
  }

  Future<void> applyPreset(String presetName) async {
    final levels = eqPresets[presetName];
    if (levels == null) return;
    try {
      final numBands = state.bands.length;
      await _applyPresetNative(presetName, numBands, state.minLevelMb, state.maxLevelMb);

      // Scale preset values to device range
      final scaledLevels = levels.take(numBands).toList();
      final newBands = state.bands
          .asMap()
          .entries
          .map((e) {
            final level = e.key < scaledLevels.length ? scaledLevels[e.key] : 0;
            return e.value.copyWith(levelMb: level.clamp(state.minLevelMb, state.maxLevelMb));
          })
          .toList();

      state = state.copyWith(bands: newBands, activePreset: presetName);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pPreset, presetName);
      await _persistBands(newBands);
    } catch (e) {
      print('EqualizerNotifier.applyPreset error: $e');
    }
  }

  Future<void> _applyPresetNative(
      String presetName, int numBands, int minMb, int maxMb) async {
    final levels = eqPresets[presetName] ?? List.filled(numBands, 0);
    final scaled = List.generate(numBands, (i) {
      final v = i < levels.length ? levels[i] : 0;
      return v.clamp(minMb, maxMb);
    });
    await _ch.invokeMethod('applyBands', {'levels': scaled});
  }

  Future<void> setBassStrength(int strength) async {
    final clamped = strength.clamp(0, 1000);
    try {
      await _ch.invokeMethod('setBassBoost', {'strength': clamped});
      state = state.copyWith(bassStrength: clamped);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_pBass, clamped);
    } catch (e) {
      print('EqualizerNotifier.setBassStrength error: $e');
    }
  }

  Future<void> setLoudnessGain(int gainMb) async {
    final clamped = gainMb.clamp(0, 1000);
    try {
      await _ch.invokeMethod('setLoudness', {'gainMb': clamped});
      state = state.copyWith(loudnessGainMb: clamped);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_pLoudness, clamped);
    } catch (e) {
      print('EqualizerNotifier.setLoudnessGain error: $e');
    }
  }

  Future<void> setEnabled(bool enabled) async {
    try {
      await _ch.invokeMethod('setEnabled', {'enabled': enabled});
      state = state.copyWith(enabled: enabled);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_pEnabled, enabled);
    } catch (e) {
      print('EqualizerNotifier.setEnabled error: $e');
    }
  }

  Future<void> _persistBands(List<EqBand> bands) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_pBands, bands.map((b) => b.levelMb.toString()).toList());
  }
}

final equalizerProvider =
    NotifierProvider<EqualizerNotifier, EqualizerState>(EqualizerNotifier.new);
