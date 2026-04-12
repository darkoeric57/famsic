import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SettingsState {
  final String? scanPath;
  final bool isLoading;
  final bool gaplessPlayback;
  final bool highQualityAudio;
  final bool sleepTimerEnabled;
  final int sleepTimerMinutes;
  final double volume;
  final List<int> eqBands;

  SettingsState({
    this.scanPath,
    this.isLoading = false,
    this.gaplessPlayback = true,
    this.highQualityAudio = false,
    this.sleepTimerEnabled = false,
    this.sleepTimerMinutes = 30,
    this.volume = 1.0,
    this.eqBands = const [],
  });

  SettingsState copyWith({
    String? scanPath,
    bool? isLoading,
    bool clearPath = false,
    bool? gaplessPlayback,
    bool? highQualityAudio,
    bool? sleepTimerEnabled,
    int? sleepTimerMinutes,
    double? volume,
    List<int>? eqBands,
  }) {
    return SettingsState(
      scanPath: clearPath ? null : (scanPath ?? this.scanPath),
      isLoading: isLoading ?? this.isLoading,
      gaplessPlayback: gaplessPlayback ?? this.gaplessPlayback,
      highQualityAudio: highQualityAudio ?? this.highQualityAudio,
      sleepTimerEnabled: sleepTimerEnabled ?? this.sleepTimerEnabled,
      sleepTimerMinutes: sleepTimerMinutes ?? this.sleepTimerMinutes,
      volume: volume ?? this.volume,
      eqBands: eqBands ?? this.eqBands,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    _loadSettings();
    return SettingsState();
  }

  static const _scanPathKey = 'scan_path';
  static const _gaplessKey = 'gapless_playback';
  static const _hqAudioKey = 'high_quality_audio';
  static const _sleepEnabledKey = 'sleep_timer_enabled';
  static const _sleepMinutesKey = 'sleep_timer_minutes';
  static const _volumeKey = 'player_volume';
  static const _eqBandsKey = 'eq_bands';

  Future<void> _loadSettings() async {
    state = state.copyWith(isLoading: true);
    final prefs = await SharedPreferences.getInstance();
    state = SettingsState(
      scanPath: prefs.getString(_scanPathKey),
      isLoading: false,
      gaplessPlayback: prefs.getBool(_gaplessKey) ?? true,
      highQualityAudio: prefs.getBool(_hqAudioKey) ?? false,
      sleepTimerEnabled: prefs.getBool(_sleepEnabledKey) ?? false,
      sleepTimerMinutes: prefs.getInt(_sleepMinutesKey) ?? 30,
      volume: prefs.getDouble(_volumeKey) ?? 1.0,
      eqBands: prefs.getStringList(_eqBandsKey)?.map(int.parse).toList() ?? [],
    );
  }

  Future<void> updateScanPath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scanPathKey, path);
    state = state.copyWith(scanPath: path);
  }

  Future<void> clearScanPath() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_scanPathKey);
    state = state.copyWith(clearPath: true);
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
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, SettingsState>(SettingsNotifier.new);
