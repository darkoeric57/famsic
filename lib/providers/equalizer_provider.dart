import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../audio_engine/audio_engine_bindings.dart';

// ─── Data Models ───

const Map<String, List<double>> eqPresets = {
  'Flat': [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
  'Bass Boost': [10.0, 8.0, 4.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
  'Rock': [8.0, 5.0, 2.0, -1.0, -2.0, 2.0, 4.0, 6.0, 8.0, 9.0],
  'Pop': [-2.0, 0.0, 3.0, 5.0, 6.0, 5.0, 3.0, 0.0, -2.0, -2.0],
  'Classical': [5.0, 4.0, 2.0, 0.0, -2.0, 0.0, 2.0, 4.0, 5.0, 6.0],
};

class EqState {
  final List<double> bandLevels;
  final String activePreset;
  final bool isEnabled;
  final int listeningMode;
  final bool isHeadsetOptimized;
  final bool isVocalPurityEnabled;

  EqState({
    required this.bandLevels,
    required this.activePreset,
    required this.isEnabled,
    this.listeningMode = 0,
    this.isHeadsetOptimized = false,
    this.isVocalPurityEnabled = false,
  });

  EqState copyWith({
    List<double>? bandLevels,
    String? activePreset,
    bool? isEnabled,
    int? listeningMode,
    bool? isHeadsetOptimized,
    bool? isVocalPurityEnabled,
  }) {
    return EqState(
      bandLevels: bandLevels ?? this.bandLevels,
      activePreset: activePreset ?? this.activePreset,
      isEnabled: isEnabled ?? this.isEnabled,
      listeningMode: listeningMode ?? this.listeningMode,
      isHeadsetOptimized: isHeadsetOptimized ?? this.isHeadsetOptimized,
      isVocalPurityEnabled: isVocalPurityEnabled ?? this.isVocalPurityEnabled,
    );
  }
}

class EqController extends Notifier<EqState> {
  static const _pBands = 'eq_bands_10_v3';
  static const _pPreset = 'eq_active_preset_v3';
  static const _pEnabled = 'eq_enabled_v3';
  static const _pHeadsetMode = 'eq_headset_optimized_v3';
  static const _pVocalPurity = 'eq_vocal_purity_v1';

  Timer? _debounceTimer;

  @override
  EqState build() {
    // Initial state
    final state = EqState(
      bandLevels: List.filled(10, 0.0),
      activePreset: 'Flat',
      isEnabled: true,
      listeningMode: 0,
      isHeadsetOptimized: false,
      isVocalPurityEnabled: false,
    );
    
    // Asynchronously load settings
    _loadSettings();
    
    return state;
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_pEnabled) ?? true;
    final activePreset = prefs.getString(_pPreset) ?? 'Flat';
    final isHeadsetOptimized = prefs.getBool(_pHeadsetMode) ?? false;
    final isVocalPurity = prefs.getBool(_pVocalPurity) ?? false;
    
    List<double> bandLevels = List.filled(10, 0.0);
    final savedBands = prefs.getStringList(_pBands);
    if (savedBands != null && savedBands.length == 10) {
      bandLevels = savedBands.map(double.parse).toList();
    } else if (eqPresets.containsKey(activePreset)) {
      bandLevels = List.from(eqPresets[activePreset]!);
    }

    // Initialize FFI engine
    audioEngineInstance.setEqEnabled(isEnabled);
    audioEngineInstance.setHeadsetMode(isHeadsetOptimized);
    audioEngineInstance.enableVocalPurity(isVocalPurity);
    for (int i = 0; i < 10; i++) {
      audioEngineInstance.setEqBand(i, bandLevels[i]);
    }
    
    state = state.copyWith(
      isEnabled: isEnabled,
      activePreset: activePreset,
      bandLevels: bandLevels,
      isHeadsetOptimized: isHeadsetOptimized,
      isVocalPurityEnabled: isVocalPurity,
    );
  }

  void updateBandLevel(int index, double value) {
    if (index < 0 || index >= 10) return;
    
    final newBands = List<double>.from(state.bandLevels);
    newBands[index] = value.clamp(-12.0, 12.0);
    
    state = state.copyWith(
      bandLevels: newBands,
      activePreset: 'Custom',
    );
    
    // 1. Instant Auditory Feedback
    audioEngineInstance.setEqBand(index, newBands[index]);
    
    // 2. Debounced Persistence
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), _persistSettings);
  }

  void applyPreset(String presetName) {
    if (!eqPresets.containsKey(presetName)) return;
    
    final newBands = List<double>.from(eqPresets[presetName]!);

    state = state.copyWith(
      activePreset: presetName,
      bandLevels: newBands,
    );

    // 1. Sync Native Engine
    for (int i = 0; i < 10; i++) {
      audioEngineInstance.setEqBand(i, newBands[i]);
    }

    // 2. Persist
    _persistSettings();
  }

  void setEqEnabled(bool enabled) {
    state = state.copyWith(isEnabled: enabled);
    audioEngineInstance.setEqEnabled(enabled);
    _persistSettings();
  }

  void setListeningMode(int mode) {
    state = state.copyWith(listeningMode: mode);
    audioEngineInstance.setListeningMode(mode);
  }

  void toggleHeadsetOptimization() {
    final newState = !state.isHeadsetOptimized;
    state = state.copyWith(isHeadsetOptimized: newState);
    audioEngineInstance.setHeadsetMode(newState);
    _persistSettings();
  }

  void toggleVocalPurity() {
    final newState = !state.isVocalPurityEnabled;
    state = state.copyWith(isVocalPurityEnabled: newState);
    audioEngineInstance.enableVocalPurity(newState);
    _persistSettings();
  }

  void initialize() {
    // Explicit call to ensure settings are loaded and synced
    _loadSettings();
  }

  void nextPreset() {
    final keys = eqPresets.keys.toList();
    int index = keys.indexOf(state.activePreset);
    index = (index + 1) % keys.length;
    applyPreset(keys[index]);
  }

  void previousPreset() {
    final keys = eqPresets.keys.toList();
    int index = keys.indexOf(state.activePreset);
    if (index == -1) index = 0;
    index = (index - 1 + keys.length) % keys.length;
    applyPreset(keys[index]);
  }

  Future<void> _persistSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pEnabled, state.isEnabled);
    await prefs.setString(_pPreset, state.activePreset);
    await prefs.setBool(_pHeadsetMode, state.isHeadsetOptimized);
    await prefs.setBool(_pVocalPurity, state.isVocalPurityEnabled);
    await prefs.setStringList(_pBands, state.bandLevels.map((e) => e.toString()).toList());
  }
}

// ─── Riverpod Hook ───
final equalizerProvider = NotifierProvider<EqController, EqState>(() => EqController());
