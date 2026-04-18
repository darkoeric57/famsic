import 'package:audio_service/audio_service.dart';
import 'package:rxdart/rxdart.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import '../audio_engine/audio_engine_bindings.dart';

class FamsicAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  Timer? _pollingTimer;
  Timer? _visualizerTimer;
  
  final _positionController = BehaviorSubject<Duration>.seeded(Duration.zero);
  final _durationController = BehaviorSubject<Duration?>.seeded(null);
  final _volumeController = BehaviorSubject<double>.seeded(1.0);
  final _playingController = BehaviorSubject<bool>.seeded(false);
  final _visualizerController = BehaviorSubject<List<double>>.seeded(List<double>.filled(7, 0.0));
  
  late final Pointer<Float> _vizPtr;

  bool _isUpdatingSource = false;
  int _currentIndex = 0;

  FamsicAudioHandler() {
    _init();
  }

  void _init() {
    try {
      print('Famsic: Initializing C++ Audio Engine...');
      final success = audioEngineInstance.initialize();
      if (!success) {
        print('Famsic: Native engine failed to initialize.');
      }
      _vizPtr = malloc<Float>(7);
      
      // Delay polling by 500ms to allow the native stack to settle and avoid the startup native_crash
      Future.delayed(const Duration(milliseconds: 500), () {
        if (_pollingTimer != null || _visualizerTimer != null) return; // Already started
        
        _pollingTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
          _pollEngine();
        });

        // Real-time visualizer polling (10Hz is enough for smooth UI transitions with the C++ ballistics)
        _visualizerTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
          if (_playingController.value) {
            try {
              audioEngineInstance.getMagnitudes(_vizPtr);
              final magnitudes = List<double>.generate(7, (i) => _vizPtr[i].toDouble());
              _visualizerController.add(magnitudes);
            } catch (e) {
              print('Famsic: Visualizer magnitude poll error: $e');
            }
          } else {
            _visualizerController.add(List<double>.filled(7, 0.0));
          }
        });
        print('Famsic: Native polling timers started.');
      });

      audioEngineInstance.setVolume(_volumeController.value);
    } catch (e, stack) {
      print('Famsic: CRITICAL Error initializing audio engine: $e');
      print(stack);
    }
  }

  void _pollEngine() {
    if (_isUpdatingSource) return;

    final isPlaying = audioEngineInstance.isPlaying();
    if (_playingController.value != isPlaying) {
      _playingController.add(isPlaying);
      _broadcastState();
    }

    if (isPlaying) {
      final posMs = audioEngineInstance.getPositionMs();
      final durMs = audioEngineInstance.getDurationMs();
      _positionController.add(Duration(milliseconds: posMs.toInt()));
      
      if (_durationController.value == null || _durationController.value!.inMilliseconds != durMs.toInt()) {
        if (durMs > 0) {
          _durationController.add(Duration(milliseconds: durMs.toInt()));
        }
      }

      // Check for track completion
      if (durMs > 0 && posMs >= durMs - 50) {
        skipToNext();
      }
    }
  }

  void _broadcastState() {
    playbackState.add(PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_playingController.value) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: AudioProcessingState.ready,
      playing: _playingController.value,
      updatePosition: _positionController.value,
      queueIndex: _currentIndex,
    ));
  }

  // ─── Native FX (Famsic C++ Engine) ──────────────────────────────────────

  Future<void> applyStereoEnhancement(bool enabled, int strength) async {
    // Optional, handled by EQ / modes
  }
  void applyGapless(bool enabled) {}
  Future<void> applyHighQuality(bool enabled) async {}

  // ─── Playback Controls ────────────────────────────────────────────────────

  @override
  Future<void> play() async {
    audioEngineInstance.play();
    _playingController.add(true);
    _broadcastState();
  }

  @override
  Future<void> pause() async {
    audioEngineInstance.pause();
    _playingController.add(false);
    _broadcastState();
  }

  @override
  Future<void> seek(Duration position) async {
    audioEngineInstance.seekToMs(position.inMilliseconds.toDouble());
    _positionController.add(position);
    _broadcastState();
  }

  @override
  Future<void> skipToNext() async {
    if (queue.value.isEmpty) return;
    int next = _currentIndex + 1;
    if (next >= queue.value.length) next = 0; // wrap around
    await skipToQueueItem(next);
  }

  @override
  Future<void> skipToPrevious() async {
    if (queue.value.isEmpty) return;
    
    if (_positionController.value.inSeconds > 3) {
      await seek(Duration.zero);
      return;
    }

    int prev = _currentIndex - 1;
    if (prev < 0) prev = queue.value.length - 1;
    await skipToQueueItem(prev);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    if (index < 0 || index >= queue.value.length) return;
    _isUpdatingSource = true;
    _currentIndex = index;
    final item = queue.value[index];
    mediaItem.add(item);
    
    // Instantly zero out visualizer for a clean transition
    _visualizerController.add(List<double>.filled(7, 0.0));

    try {
      final path = item.id;
      print('Famsic: Attempting to load song: $path');
      
      final success = audioEngineInstance.loadAndPlay(path);
      if (success) {
        print('Famsic: loadAndPlay result: true');
        playbackState.add(playbackState.value.copyWith(
          playing: true,
          controls: [MediaControl.pause, MediaControl.skipToNext, MediaControl.skipToPrevious],
          systemActions: {MediaAction.seek},
        ));
        _playingController.add(true);
        _positionController.add(Duration.zero);
      } else {
        print('Famsic: FAILED to open file. Check path and permissions.');
        _playingController.add(false);
      }
    } catch (e) {
      print('Famsic: skipToQueueItem error — $e');
    } finally {
      _isUpdatingSource = false;
    }
  }

  @override
  Future<void> addQueueItems(List<MediaItem> mediaItems) async {
    final currentQ = queue.value;
    currentQ.addAll(mediaItems);
    queue.add(currentQ);
    if (!audioEngineInstance.isPlaying()) {
      skipToQueueItem(0);
    }
  }

  @override
  Future<void> updateQueue(List<MediaItem> queue, {int initialIndex = 0}) async {
    if (queue.isEmpty) return;
    _isUpdatingSource = true;
    this.queue.add(queue);
    _isUpdatingSource = false;
    await skipToQueueItem(initialIndex);
  }

  // ─── Helper Streams ───────────────────────────────────────────────────────

  Stream<Duration> get positionStream => _positionController.stream;
  Stream<Duration?> get durationStream => _durationController.stream;
  Stream<bool> get playingStream => _playingController.stream;
  Stream<double> get volumeStream => _volumeController.stream;
  Stream<int?> get audioSessionIdStream => Stream.value(0); // unused
  
  Stream<List<double>> get visualizerStream => _visualizerController.stream;

  Future<void> setVolume(double volume) async {
    _volumeController.add(volume);
    audioEngineInstance.setVolume(volume);
  }
}
