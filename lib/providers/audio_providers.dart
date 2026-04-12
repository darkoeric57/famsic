import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
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

final volumeProvider = StreamProvider<double>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.volumeStream;
});

/// Extracts unique folders with track counts from the loaded song list.
final foldersProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final songsAsync = ref.watch(songListProvider);
  return songsAsync.when(
    data: (songs) {
      final folderMap = <String, int>{};
      for (final song in songs) {
        final parts = song.data.split('/');
        if (parts.length > 1) {
          final folderPath = parts.sublist(0, parts.length - 1).join('/');
          folderMap[folderPath] = (folderMap[folderPath] ?? 0) + 1;
        }
      }
      
      final folders = folderMap.entries.map((e) {
        final path = e.key;
        final name = path.split('/').last;
        return {
          'path': path,
          'name': name,
          'count': e.value,
        };
      }).toList();
      
      folders.sort((a, b) => (a['name'] as String).compareTo(b['name'] as String));
      return folders;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

final artworkProvider = FutureProvider.family<Uint8List?, String>((ref, uri) async {
  if (uri.isEmpty) return null;
  final service = ref.watch(musicServiceProvider);
  return service.getArtwork(uri);
});
