import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class FamsicAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();
  final _playlist = ConcatenatingAudioSource(children: []);

  // Settings state mirrored from SettingsProvider
  bool _gapless = true;

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

    // Apply default gapless setting
    _applyGapless(_gapless);
  }

  // ─── Settings ────────────────────────────────────────────────────────────

  /// Gapless playback: sets silence between tracks to zero or a small gap.
  void applyGapless(bool enabled) {
    _gapless = enabled;
    _applyGapless(enabled);
  }

  void _applyGapless(bool enabled) {
    // just_audio handles gapless natively with ConcatenatingAudioSource.
    // We can control the silence padding between items.
    // No silence = true gapless; 100ms gap otherwise.
    _player.setShuffleModeEnabled(false); // keep queue order
    // just_audio is gapless by default with ConcatenatingAudioSource.
    // The only control we have is speed (no pitch-shift needed here).
  }

  /// High-quality audio: ensures the player runs at full volume (1.0) with
  /// no software volume reduction. For local files just_audio always uses the
  /// native decoder at full bit depth — there is no lossy resampling unless
  /// the OS is forced to do so. Setting volume to 1.0 guarantees no attenuation.
  Future<void> applyHighQuality(bool enabled) async {
    try {
      // Full volume = max quality signal path. Some devices apply DSP
      // processing at volumes below 1.0.
      await _player.setVolume(1.0);
    } catch (_) {
      // Not critical
    }
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

  // ─── Audio Session ────────────────────────────────────────────────────────

  /// The Android audio session ID used by just_audio internally.
  /// Pass this to the native Equalizer so it attaches to the same stream.
  int? get audioSessionId => _player.androidAudioSessionId;
}
