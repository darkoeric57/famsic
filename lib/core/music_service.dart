import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'native_song_model.dart';

export 'native_song_model.dart';

class MusicService {
  static const _channel = MethodChannel('com.famsic.app/media_store');

  /// Request media/storage permission using permission_handler only.
  /// We do NOT use on_audio_query's permissionsRequest() — it shares
  /// the same Android activity-result channel as FilePicker and causes
  /// "IllegalStateException: Reply already submitted".
  Future<bool> ensurePermission() async {
    // Android 13+: READ_MEDIA_AUDIO; older: READ_EXTERNAL_STORAGE
    if (await Permission.audio.isGranted) return true;
    if (await Permission.storage.isGranted) return true;

    // Request only one at a time
    final audioResult = await Permission.audio.request();
    if (audioResult.isGranted) return true;

    final storageResult = await Permission.storage.request();
    return storageResult.isGranted;
  }

  Future<List<NativeSongModel>> fetchLocalSongs({String? scanPath}) async {
    try {
      final granted = await ensurePermission();
      print('Famsic: Permission granted: $granted');
      if (!granted) {
        print('Famsic: Permission denied — returning empty list.');
        return [];
      }

      // Give Android time to settle before querying MediaStore
      await Future.delayed(const Duration(milliseconds: 400));

      print('Famsic: Querying songs via native MediaStore channel...');
      final raw = await _channel.invokeMethod<List<dynamic>>('querySongs');
      final songs = (raw ?? [])
          .cast<Map<dynamic, dynamic>>()
          .map(NativeSongModel.fromMap)
          .where((s) => s.uri.isNotEmpty)
          .toList();

      print('Famsic: Found ${songs.length} songs.');

      if (scanPath != null && scanPath.isNotEmpty) {
        final filtered = songs.where((s) => s.data.startsWith(scanPath)).toList();
        print('Famsic: ${filtered.length} songs in scanned path.');
        return filtered;
      }

      return songs;
    } catch (e, stack) {
      print('Famsic: Error in fetchLocalSongs: $e');
      print('Famsic: $stack');
      return [];
    }
  }

  Future<Uint8List?> getArtwork(String uri) async {
    try {
      return await _channel.invokeMethod<Uint8List>('getArtwork', {'uri': uri});
    } catch (e) {
      print('Famsic: Error fetching artwork for $uri: $e');
      return null;
    }
  }
}
