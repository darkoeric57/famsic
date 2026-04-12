/// A simple song model populated from our native MediaStore channel.
class NativeSongModel {
  final int id;
  final String title;
  final String artist;
  final String album;
  final int albumId;
  final int duration; // milliseconds
  final String data;  // file path
  final String uri;   // content:// URI string
  final int dateAdded; // seconds since epoch

  NativeSongModel({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.albumId,
    required this.duration,
    required this.data,
    required this.uri,
    required this.dateAdded,
  });

  factory NativeSongModel.fromMap(Map<dynamic, dynamic> map) {
    return NativeSongModel(
      id: (map['id'] as num).toInt(),
      title: map['title'] as String? ?? 'Unknown',
      artist: map['artist'] as String? ?? 'Unknown Artist',
      album: map['album'] as String? ?? 'Unknown Album',
      albumId: (map['albumId'] as num?)?.toInt() ?? 0,
      duration: (map['duration'] as num?)?.toInt() ?? 0,
      data: map['data'] as String? ?? '',
      uri: map['uri'] as String? ?? '',
      dateAdded: (map['dateAdded'] as num?)?.toInt() ?? 0,
    );
  }
}
