import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';

// Typedefs for C functions
typedef _AE_Initialize_C = Bool Function();
typedef _AE_Initialize_Dart = bool Function();

typedef _AE_Deinitialize_C = Void Function();
typedef _AE_Deinitialize_Dart = void Function();

typedef _AE_LoadAndPlay_C = Bool Function(Pointer<Utf8> filePath);
typedef _AE_LoadAndPlay_Dart = bool Function(Pointer<Utf8> filePath);

typedef _AE_Pause_C = Void Function();
typedef _AE_Pause_Dart = void Function();

typedef _AE_Play_C = Void Function();
typedef _AE_Play_Dart = void Function();

typedef _AE_Stop_C = Void Function();
typedef _AE_Stop_Dart = void Function();

typedef _AE_SetVolume_C = Void Function(Float volume);
typedef _AE_SetVolume_Dart = void Function(double volume);

typedef _AE_SetEQEnabled_C = Void Function(Bool enabled);
typedef _AE_SetEQEnabled_Dart = void Function(bool enabled);

typedef _AE_SetEQBand_C = Void Function(Int32 bandIndex, Float gainDb);
typedef _AE_SetEQBand_Dart = void Function(int bandIndex, double gainDb);

typedef _AE_SetListeningMode_C = Void Function(Int32 mode);
typedef _AE_SetListeningMode_Dart = void Function(int mode);

typedef _AE_SetHeadsetMode_C = Void Function(Bool active);
typedef _AE_SetHeadsetMode_Dart = void Function(bool active);

typedef _AE_EnableVocalPurity_C = Void Function(Bool active);
typedef _AE_EnableVocalPurity_Dart = void Function(bool active);

typedef _AE_IsPlaying_C = Bool Function();
typedef _AE_IsPlaying_Dart = bool Function();

typedef _AE_GetDurationMs_C = Double Function();
typedef _AE_GetDurationMs_Dart = double Function();

typedef _AE_GetPositionMs_C = Double Function();
typedef _AE_GetPositionMs_Dart = double Function();

typedef _AE_SeekToMs_C = Void Function(Double positionMs);
typedef _AE_SeekToMs_Dart = void Function(double positionMs);

typedef _AE_GetMagnitudes_C = Void Function(Pointer<Float> magnitudes);
typedef _AE_GetMagnitudes_Dart = void Function(Pointer<Float> magnitudes);


class AudioEngineBindings {
  static final AudioEngineBindings _instance = AudioEngineBindings._internal();
  factory AudioEngineBindings() => _instance;

  late final DynamicLibrary _lib;

  late final _AE_Initialize_Dart _initialize;
  late final _AE_Deinitialize_Dart _deinitialize;
  late final _AE_LoadAndPlay_Dart _loadAndPlay;
  late final _AE_Pause_Dart _pause;
  late final _AE_Play_Dart _play;
  late final _AE_Stop_Dart _stop;
  late final _AE_SetVolume_Dart _setVolume;
  late final _AE_SetEQEnabled_Dart _setEqEnabled;
  late final _AE_SetEQBand_Dart _setEqBand;
  late final _AE_SetListeningMode_Dart _setListeningMode;
  late final _AE_SetHeadsetMode_Dart _setHeadsetMode;
  late final _AE_EnableVocalPurity_Dart _enableVocalPurity;
  late final _AE_IsPlaying_Dart _isPlaying;
  late final _AE_GetDurationMs_Dart _getDurationMs;
  late final _AE_GetPositionMs_Dart _getPositionMs;
  late final _AE_SeekToMs_Dart _seekToMs;
  late final _AE_GetMagnitudes_Dart _getMagnitudes;

  AudioEngineBindings._internal() {
    print('FamsicAudio: Loading native library...');
    try {
      if (Platform.isAndroid) {
        _lib = DynamicLibrary.open('libaudio_engine.so');
      } else if (Platform.isWindows) {
        _lib = DynamicLibrary.open('audio_engine.dll');
      } else {
        _lib = DynamicLibrary.process();
      }

      _initialize = _lib.lookupFunction<_AE_Initialize_C, _AE_Initialize_Dart>('AE_Initialize');
      _deinitialize = _lib.lookupFunction<_AE_Deinitialize_C, _AE_Deinitialize_Dart>('AE_Deinitialize');
      _loadAndPlay = _lib.lookupFunction<_AE_LoadAndPlay_C, _AE_LoadAndPlay_Dart>('AE_LoadAndPlay');
      _pause = _lib.lookupFunction<_AE_Pause_C, _AE_Pause_Dart>('AE_Pause');
      _play = _lib.lookupFunction<_AE_Play_C, _AE_Play_Dart>('AE_Play');
      _stop = _lib.lookupFunction<_AE_Stop_C, _AE_Stop_Dart>('AE_Stop');
      _setVolume = _lib.lookupFunction<_AE_SetVolume_C, _AE_SetVolume_Dart>('AE_SetVolume');
      _setEqEnabled = _lib.lookupFunction<_AE_SetEQEnabled_C, _AE_SetEQEnabled_Dart>('AE_SetEQEnabled');
      _setEqBand = _lib.lookupFunction<_AE_SetEQBand_C, _AE_SetEQBand_Dart>('AE_SetEQBand');
      _setListeningMode = _lib.lookupFunction<_AE_SetListeningMode_C, _AE_SetListeningMode_Dart>('AE_SetListeningMode');
      _setHeadsetMode = _lib.lookupFunction<_AE_SetHeadsetMode_C, _AE_SetHeadsetMode_Dart>('AE_SetHeadsetMode');
      _enableVocalPurity = _lib.lookupFunction<_AE_EnableVocalPurity_C, _AE_EnableVocalPurity_Dart>('AE_EnableVocalPurity');
      _isPlaying = _lib.lookupFunction<_AE_IsPlaying_C, _AE_IsPlaying_Dart>('AE_IsPlaying');
      _getDurationMs = _lib.lookupFunction<_AE_GetDurationMs_C, _AE_GetDurationMs_Dart>('AE_GetDurationMs');
      _getPositionMs = _lib.lookupFunction<_AE_GetPositionMs_C, _AE_GetPositionMs_Dart>('AE_GetPositionMs');
      _seekToMs = _lib.lookupFunction<_AE_SeekToMs_C, _AE_SeekToMs_Dart>('AE_SeekToMs');
      _getMagnitudes = _lib.lookupFunction<_AE_GetMagnitudes_C, _AE_GetMagnitudes_Dart>('AE_GetMagnitudes');
      
      print('FamsicAudio: Native library loaded and symbols bound.');
    } catch (e) {
      print('FamsicAudio: CRITICAL ERROR loading native library: $e');
    }
  }

  bool initialize() {
    print('FamsicAudio: Calling AE_Initialize...');
    return _initialize();
  }

  void deinitialize() => _deinitialize();

  bool loadAndPlay(String filePath) {
    final ptr = filePath.toNativeUtf8();
    try {
      print('FamsicAudio: Calling AE_LoadAndPlay($filePath)...');
      return _loadAndPlay(ptr);
    } finally {
      malloc.free(ptr);
    }
  }

  void pause() => _pause();
  void play() => _play();
  void stop() => _stop();
  void setVolume(double volume) => _setVolume(volume);

  void setEqEnabled(bool enabled) {
    print('FamsicAudio: Calling AE_SetEQEnabled($enabled)...');
    _setEqEnabled(enabled);
  }

  void setEqBand(int bandIndex, double gainDb) {
    print('FamsicAudio: Calling AE_SetEQBand(index: $bandIndex, gain: $gainDb)...');
    _setEqBand(bandIndex, gainDb);
  }

  void setListeningMode(int mode) {
    print('FamsicAudio: Calling AE_SetListeningMode(mode: $mode)...');
    _setListeningMode(mode);
  }

  void setHeadsetMode(bool active) {
    print('FamsicAudio: Calling AE_SetHeadsetMode(active: $active)...');
    _setHeadsetMode(active);
  }

  void enableVocalPurity(bool active) {
    print('FamsicAudio: Calling AE_EnableVocalPurity(active: $active)...');
    _enableVocalPurity(active);
  }

  bool isPlaying() => _isPlaying();
  double getDurationMs() => _getDurationMs();
  double getPositionMs() => _getPositionMs();
  void seekToMs(double positionMs) => _seekToMs(positionMs);
  void getMagnitudes(Pointer<Float> magnitudes) => _getMagnitudes(magnitudes);
}

final audioEngineInstance = AudioEngineBindings();
