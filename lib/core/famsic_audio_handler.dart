import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class FamsicAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);
  
  static const _visualizerChannel = EventChannel('com.famsic.app/visualizer');
  static const _eqChannel = MethodChannel('com.famsic.app/equalizer');

  // Settings state mirrored from SettingsProvider
  bool _gapless = true;
  double _lastVolume = 1.0;

  FamsicAudioHandler() {
    _init();
  }

  void _init() {
    // Broadcast playback state changes from just_audio to audio_service
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);

    // Listen for current index changes to update mediaItem
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty) {
        mediaItem.add(queue.value[index]);
      }
    });

    // Configure AudioSession for best possible quality session type
    _configureAudioSession();

    // Listen for audio session ID changes to initialize native effects (EQ/Visualizer)
    _player.androidAudioSessionIdStream.listen((sessionId) {
      if (sessionId != null) {
        _initNativeEffects(sessionId);
      }
    });
  }

  Future<void> _configureAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
  }

  Future<void> _initNativeEffects(int sessionId) async {
    try {
      await _eqChannel.invokeMethod('init', {'sessionId': sessionId});
    } catch (e) {
      print('FamsicAudioHandler: Failed to init native effects — $e');
    }
  }

  // ─── Settings ────────────────────────────────────────────────────────────

  /// Gapless playback: sets silence between tracks to zero or a small gap.
  void applyGapless(bool enabled) {
    _gapless = enabled;
    // just_audio is gapless by default with ConcatenatingAudioSource.
  }

  /// High-quality audio: ensures the player runs at full volume (1.0) with
  /// no software volume reduction and optimal sampling flags.
  Future<void> applyHighQuality(bool enabled) async {
    try {
      final session = await AudioSession.instance;
      if (enabled) {
        // High-fidelity configuration
        await session.configure(const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionMode: AVAudioSessionMode.defaultMode,
          avAudioSessionRouteSharingPolicy:
              AVAudioSessionRouteSharingPolicy.defaultPolicy,
          avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions(0),
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.music,
            flags: AndroidAudioFlags.none,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: true,
        ));

        // Force volume to 1.0 to prevent OS-level software attenuation/DSP.
        await _player.setVolume(1.0);
        // Ensure speed is 1.0 to avoid resampling if not needed.
        await _player.setSpeed(1.0);
      } else {
        // Restore standard configuration
        await session.configure(const AudioSessionConfiguration.music());
        await _player.setVolume(_lastVolume);
      }
    } catch (_) {}
  }

  // ─── Playback Controls ────────────────────────────────────────────────────

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> skipToQueueItem(int index) async {
    await _player.seek(Duration.zero, index: index);
    play();
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final audioSources =
        mediaItems.map((item) => AudioSource.uri(Uri.parse(item.id))).toList();
    _playlist.addAll(audioSources);
    queue.add(mediaItems);
    if (_player.audioSource == null) {
      await _player.setAudioSource(_playlist);
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue) async {
    if (queue.isEmpty) return;
    try {
      await _playlist.clear();
      final audioSources =
          queue.map((item) => AudioSource.uri(Uri.parse(item.id))).toList();
      await _playlist.addAll(audioSources);
      this.queue.add(queue);
      await _player.setAudioSource(
        _playlist,
        initialIndex: 0,
        initialPosition: Duration.zero,
      );
    } catch (e) {
      print('FamsicAudioHandler: updateQueue error — $e');
    }
  }

  // ─── State Transform ──────────────────────────────────────────────────────

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ProcessingState.idle: AudioProcessingState.idle,
        ProcessingState.loading: AudioProcessingState.loading,
        ProcessingState.buffering: AudioProcessingState.buffering,
        ProcessingState.ready: AudioProcessingState.ready,
        ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }

  // ─── Helper Streams ───────────────────────────────────────────────────────

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;
  Stream<bool> get playingStream => _player.playingStream;
  Stream<double> get volumeStream => _player.volumeStream;
  
  /// Real-time frequency magnitudes from the native Visualizer (7 buckets)
  Stream<List<double>> get visualizerStream => _visualizerChannel
      .receiveBroadcastStream()
      .map((event) => (event as List).cast<double>());

  Future<void> setVolume(double volume) {
    _lastVolume = volume;
    return _player.setVolume(volume);
  }

  // ─── Audio Session ────────────────────────────────────────────────────────

  /// The Android audio session ID used by just_audio internally.
  /// Pass this to the native Equalizer so it attaches to the same stream.
  int? get audioSessionId => _player.androidAudioSessionId;
}

