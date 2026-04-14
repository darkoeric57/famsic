import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final List<String> scanPaths;
  final bool isLoading;
  final bool gaplessPlayback;
  final bool highQualityAudio;
  final bool sleepTimerEnabled;
  final int sleepTimerMinutes;
  final double volume;
  final List<int> eqBands;
  final bool isDarkMode;
  final bool stereoEnabled;
  final int stereoStrength; // 0-1000
  final bool visualizerEnabled;
  final String visualizerStyle;
  final List<String> hiddenPaths;

  SettingsState({
    this.scanPaths = const [],
    this.isLoading = false,
    this.gaplessPlayback = true,
    this.highQualityAudio = false,
    this.sleepTimerEnabled = false,
    this.sleepTimerMinutes = 30,
    this.volume = 1.0,
    this.eqBands = const [],
    this.isDarkMode = false,
    this.stereoEnabled = false,
    this.stereoStrength = 0,
    this.visualizerEnabled = true,
    this.visualizerStyle = 'Neon Bars',
    this.hiddenPaths = const [],
  });

  SettingsState copyWith({
    List<String>? scanPaths,
    bool? isLoading,
    bool? gaplessPlayback,
    bool? highQualityAudio,
    bool? sleepTimerEnabled,
    int? sleepTimerMinutes,
    double? volume,
    List<int>? eqBands,
    bool? isDarkMode,
    bool? stereoEnabled,
    int? stereoStrength,
    bool? visualizerEnabled,
    String? visualizerStyle,
    List<String>? hiddenPaths,
  }) {
    return SettingsState(
      scanPaths: scanPaths ?? this.scanPaths,
      isLoading: isLoading ?? this.isLoading,
      gaplessPlayback: gaplessPlayback ?? this.gaplessPlayback,
      highQualityAudio: highQualityAudio ?? this.highQualityAudio,
      sleepTimerEnabled: sleepTimerEnabled ?? this.sleepTimerEnabled,
      sleepTimerMinutes: sleepTimerMinutes ?? this.sleepTimerMinutes,
      volume: volume ?? this.volume,
      eqBands: eqBands ?? this.eqBands,
      isDarkMode: isDarkMode ?? this.isDarkMode,
      stereoEnabled: stereoEnabled ?? this.stereoEnabled,
      stereoStrength: stereoStrength ?? this.stereoStrength,
      visualizerEnabled: visualizerEnabled ?? this.visualizerEnabled,
      visualizerStyle: visualizerStyle ?? this.visualizerStyle,
      hiddenPaths: hiddenPaths ?? this.hiddenPaths,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadSettings();
    return SettingsState();
  }

  static const _scanPathsKey = 'scan_paths_list';
  static const _oldScanPathKey = 'scan_path';
  static const _gaplessKey = 'gapless_playback';
  static const _hqAudioKey = 'high_quality_audio';
  static const _sleepEnabledKey = 'sleep_timer_enabled';
  static const _sleepMinutesKey = 'sleep_timer_minutes';
  static const _volumeKey = 'player_volume';
  static const _eqBandsKey = 'eq_bands';
  static const _isDarkModeKey = 'is_dark_mode';
  static const _stereoEnabledKey = 'stereo_enabled';
  static const _stereoStrengthKey = 'stereo_strength';
  static const _visualizerEnabledKey = 'visualizer_enabled';
  static const _visualizerStyleKey = 'visualizer_style';
  static const _hiddenPathsKey = 'hidden_paths_list';

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    
    // Migration logic: if old path exists but no new list, convert to list
    List<String> paths = prefs.getStringList(_scanPathsKey) ?? [];
    if (paths.isEmpty) {
      final oldPath = prefs.getString(_oldScanPathKey);
      if (oldPath != null && oldPath.isNotEmpty) {
        paths = [oldPath];
        await prefs.setStringList(_scanPathsKey, paths);
      }
    }

    state = SettingsState(
      scanPaths: paths,
      isLoading: false,
      gaplessPlayback: prefs.getBool(_gaplessKey) ?? true,
      highQualityAudio: prefs.getBool(_hqAudioKey) ?? false,
      sleepTimerEnabled: prefs.getBool(_sleepEnabledKey) ?? false,
      sleepTimerMinutes: prefs.getInt(_sleepMinutesKey) ?? 30,
      volume: prefs.getDouble(_volumeKey) ?? 1.0,
      eqBands: prefs.getStringList(_eqBandsKey)?.map(int.parse).toList() ?? [],
      isDarkMode: prefs.getBool(_isDarkModeKey) ?? false,
      stereoEnabled: prefs.getBool(_stereoEnabledKey) ?? false,
      stereoStrength: prefs.getInt(_stereoStrengthKey) ?? 0,
      visualizerEnabled: prefs.getBool(_visualizerEnabledKey) ?? true,
      visualizerStyle: prefs.getString(_visualizerStyleKey) ?? 'Neon Bars',
      hiddenPaths: prefs.getStringList(_hiddenPathsKey) ?? [],
    );
  }

  Future<void> addScanPath(String path) async {
    if (state.scanPaths.contains(path)) return;
    
    final newPaths = [...state.scanPaths, path];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_scanPathsKey, newPaths);
    state = state.copyWith(scanPaths: newPaths);
  }

  Future<void> removeScanPath(String path) async {
    final newPaths = state.scanPaths.where((p) => p != path).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_scanPathsKey, newPaths);
    state = state.copyWith(scanPaths: newPaths);
  }

  Future<void> setGaplessPlayback(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_gaplessKey, value);
    state = state.copyWith(gaplessPlayback: value);
  }

  Future<void> setHighQualityAudio(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hqAudioKey, value);
    state = state.copyWith(highQualityAudio: value);
  }

  Future<void> setSleepTimerMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sleepMinutesKey, minutes);
    state = state.copyWith(sleepTimerMinutes: minutes);
  }

  Future<void> setSleepTimerEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_sleepEnabledKey, value);
    state = state.copyWith(sleepTimerEnabled: value);
  }

  Future<void> setVolume(double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_volumeKey, value);
    state = state.copyWith(volume: value);
  }

  Future<void> setEqBands(List<int> bands) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_eqBandsKey, bands.map((e) => e.toString()).toList());
    state = state.copyWith(eqBands: bands);
  }

  Future<void> setIsDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isDarkModeKey, value);
    state = state.copyWith(isDarkMode: value);
  }

  Future<void> setStereoEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_stereoEnabledKey, value);
    state = state.copyWith(stereoEnabled: value);
  }

  Future<void> setStereoStrength(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_stereoStrengthKey, value);
    state = state.copyWith(stereoStrength: value);
  }

  Future<void> setVisualizerEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_visualizerEnabledKey, value);
    state = state.copyWith(visualizerEnabled: value);
  }

  Future<void> setVisualizerStyle(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_visualizerStyleKey, value);
    state = state.copyWith(visualizerStyle: value);
  }
  
  Future<void> addHiddenPath(String path) async {
    if (state.hiddenPaths.contains(path)) return;
    final newPaths = [...state.hiddenPaths, path];
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_hiddenPathsKey, newPaths);
    state = state.copyWith(hiddenPaths: newPaths);
  }

  Future<void> removeHiddenPath(String path) async {
    final newPaths = state.hiddenPaths.where((p) => p != path).toList();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_hiddenPathsKey, newPaths);
    state = state.copyWith(hiddenPaths: newPaths);
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
