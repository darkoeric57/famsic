import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/famsic_audio_handler.dart';
import '../core/music_service.dart';
import 'settings_provider.dart';

// Late initialization provider - will be overridden in main()
final audioHandlerProvider = Provider<FamsicAudioHandler>((ref) {
  throw UnimplementedError();
});

final musicServiceProvider = Provider((ref) => MusicService());

final songListProvider = FutureProvider<List<NativeSongModel>>((ref) async {
  final service = ref.watch(musicServiceProvider);
  final settings = ref.watch(settingsProvider);
  return service.fetchLocalSongs(scanPath: settings.scanPath);
});

final playbackStateProvider = StreamProvider<PlaybackState>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.playbackState;
});

final currentSongProvider = StreamProvider<MediaItem?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.mediaItem;
});

final positionProvider = StreamProvider<Duration>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.positionStream;
});

final durationProvider = StreamProvider<Duration?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.durationStream;
});
