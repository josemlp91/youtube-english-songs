import 'package:uuid/uuid.dart';

class Song {
  final String id;
  final String youtubeId;
  final String title;
  final String artist;
  final String thumbnailUrl;
  final Duration? duration;
  final DateTime dateAdded;

  Song({
    String? id,
    required this.youtubeId,
    required this.title,
    this.artist = 'Unknown Artist',
    String? thumbnailUrl,
    this.duration,
    DateTime? dateAdded,
  })  : id = id ?? const Uuid().v4(),
        thumbnailUrl = thumbnailUrl ?? 'https://img.youtube.com/vi/$youtubeId/mqdefault.jpg',
        dateAdded = dateAdded ?? DateTime.now();

  String get youtubeUrl => 'https://www.youtube.com/watch?v=$youtubeId';

  Song copyWith({
    String? id,
    String? youtubeId,
    String? title,
    String? artist,
    String? thumbnailUrl,
    Duration? duration,
    DateTime? dateAdded,
  }) {
    return Song(
      id: id ?? this.id,
      youtubeId: youtubeId ?? this.youtubeId,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      duration: duration ?? this.duration,
      dateAdded: dateAdded ?? this.dateAdded,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'youtubeId': youtubeId,
      'title': title,
      'artist': artist,
      'thumbnailUrl': thumbnailUrl,
      'duration': duration?.inSeconds,
      'dateAdded': dateAdded.toIso8601String(),
    };
  }

  factory Song.fromJson(Map<String, dynamic> json) {
    return Song(
      id: json['id'] as String,
      youtubeId: json['youtubeId'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String? ?? 'Unknown Artist',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      duration: json['duration'] != null
          ? Duration(seconds: json['duration'] as int)
          : null,
      dateAdded: DateTime.parse(json['dateAdded'] as String),
    );
  }

  static String? extractYoutubeId(String url) {
    final regexPatterns = [
      RegExp(r'(?:youtube\.com\/watch\?v=|youtu\.be\/|youtube\.com\/embed\/)([a-zA-Z0-9_-]{11})'),
      RegExp(r'^([a-zA-Z0-9_-]{11})$'),
    ];

    for (final regex in regexPatterns) {
      final match = regex.firstMatch(url);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Song && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Song(id: $id, title: $title, artist: $artist)';
}
