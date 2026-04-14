import 'dart:convert';

class LocalCollection {
  final String id;
  final String title;
  final String iconKey; // Key for LucideIcons lookup
  final List<String> trackUris;
  final DateTime createdAt;

  LocalCollection({
    required this.id,
    required this.title,
    required this.iconKey,
    required this.trackUris,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'iconKey': iconKey,
      'trackUris': trackUris,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory LocalCollection.fromMap(Map<String, dynamic> map) {
    return LocalCollection(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      iconKey: map['iconKey'] ?? 'music',
      trackUris: List<String>.from(map['trackUris'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  String toJson() => json.encode(toMap());

  factory LocalCollection.fromJson(String source) => 
      LocalCollection.fromMap(json.decode(source));

  LocalCollection copyWith({
    String? title,
    String? iconKey,
    List<String>? trackUris,
  }) {
    return LocalCollection(
      id: id,
      title: title ?? this.title,
      iconKey: iconKey ?? this.iconKey,
      trackUris: trackUris ?? this.trackUris,
      createdAt: createdAt,
    );
  }
}
