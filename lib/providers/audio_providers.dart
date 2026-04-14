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
  final allSongs = await service.fetchLocalSongs(scanPaths: settings.scanPaths);
  
  // Filter out songs in hidden paths
  if (settings.hiddenPaths.isEmpty) return allSongs;
  
  return allSongs.where((song) {
    return !settings.hiddenPaths.any((hiddenPath) => song.data.startsWith(hiddenPath));
  }).toList();
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

final visualizerStreamProvider = StreamProvider<List<double>>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.visualizerStream;
});

final audioSessionIdProvider = StreamProvider<int?>((ref) {
  final handler = ref.watch(audioHandlerProvider);
  return handler.audioSessionIdStream;
});

/// Extracts unique folders with track counts from the loaded song list.
/// Uses a Notifier to allow optimistic updates and avoid UI flashing during refreshes.
class FoldersNotifier extends Notifier<List<Map<String, dynamic>>> {
  @override
  List<Map<String, dynamic>> build() {
    final songsAsync = ref.watch(songListProvider);
    // Watch hiddenPaths directly to trigger synchronous rebuilds when they change
    final hiddenPaths = ref.watch(settingsProvider.select((s) => s.hiddenPaths));
    
    // Safely check for data. During loading/refreshing, Riverpod may still provide
    // the previous value. We apply the hiddenPaths filter manually to ensure
    // the UI immediately reflects the dismissal even before the fetch completes.
    if (songsAsync.hasValue) {
      final processed = _processFolders(songsAsync.value!);
      return processed.where((f) => !hiddenPaths.contains(f['path'])).toList();
    }

    try {
      // During background refreshes, we return the current state but 
      // apply the hiddenPaths filter to ensure optimistic removals persist.
      return state.where((f) => !hiddenPaths.contains(f['path'])).toList();
    } catch (_) {
      // First build or state unavailable
      return [];
    }
  }

  List<Map<String, dynamic>> _processFolders(List<NativeSongModel> songs) {
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
  }

  /// Optimistically removes a folder from the UI.
  /// This ensures that Dismissible animations are smooth and don't throw tree-sync errors.
  void removeFolderOptimistically(String path) {
    state = state.where((f) => f['path'] != path).toList();
  }
}

final foldersProvider = NotifierProvider<FoldersNotifier, List<Map<String, dynamic>>>(FoldersNotifier.new);

/// Returns songs filtered by their parent directory path.
/// Uses .value ?? [] to prevent list flickering during background re-scans.
final folderSongsProvider = Provider.family<List<NativeSongModel>, String>((ref, folderPath) {
  final songsAsync = ref.watch(songListProvider);
  final songs = songsAsync.value ?? [];
  return songs.where((s) => s.data.startsWith(folderPath)).toList();
});

final artworkProvider = FutureProvider.family<Uint8List?, String>((ref, uri) async {
  if (uri.isEmpty) return null;
  final service = ref.watch(musicServiceProvider);
  return service.getArtwork(uri);
});

/// Tracks the active list of songs for the Library carousel (e.g. from a specific Folder).
final activePlaylistProvider = NotifierProvider<ActivePlaylistNotifier, List<NativeSongModel>>(ActivePlaylistNotifier.new);

class ActivePlaylistNotifier extends Notifier<List<NativeSongModel>> {
  @override
  List<NativeSongModel> build() => [];
  
  void setPlaylist(List<NativeSongModel> playlist) => state = playlist;
}
