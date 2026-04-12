import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/native_song_model.dart';
import 'audio_providers.dart';

enum LibraryFilter { tracks, artists, albums, genres }

final libraryFilterProvider = NotifierProvider<LibraryFilterNotifier, LibraryFilter>(LibraryFilterNotifier.new);

class LibraryFilterNotifier extends Notifier<LibraryFilter> {
  @override
  LibraryFilter build() => LibraryFilter.tracks;

  void setFilter(LibraryFilter filter) => state = filter;
}

/// A provider that returns the list of songs grouped or processed based on the filter.
/// Currently, it just provides the raw list for 'tracks'. 
/// Future expansion will handle grouping logic for Artists/Albums.
final filteredSongsProvider = Provider<AsyncValue<List<NativeSongModel>>>((ref) {
  final songListAsync = ref.watch(songListProvider);
  final filter = ref.watch(libraryFilterProvider);

  return songListAsync.whenData((songs) {
    if (filter == LibraryFilter.tracks) {
      return songs;
    }
    
    // For now, we return the full list, but we can sort them
    final sorted = List<NativeSongModel>.from(songs);
    switch (filter) {
      case LibraryFilter.artists:
        sorted.sort((a, b) => a.artist.compareTo(b.artist));
        break;
      case LibraryFilter.albums:
        sorted.sort((a, b) => a.album.compareTo(b.album));
        break;
      default:
        break;
    }
    return sorted;
  });
});
