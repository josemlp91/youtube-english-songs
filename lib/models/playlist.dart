import 'package:uuid/uuid.dart';

class Playlist {
  final String id;
  final String name;
  final List<String> songIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  Playlist({
    String? id,
    required this.name,
    List<String>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        songIds = songIds ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  int get songCount => songIds.length;
  bool get isEmpty => songIds.isEmpty;

  Playlist copyWith({
    String? id,
    String? name,
    List<String>? songIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Playlist(
      id: id ?? this.id,
      name: name ?? this.name,
      songIds: songIds ?? List.from(this.songIds),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Playlist addSong(String songId) {
    if (songIds.contains(songId)) return this;
    return copyWith(
      songIds: [...songIds, songId],
      updatedAt: DateTime.now(),
    );
  }

  Playlist removeSong(String songId) {
    return copyWith(
      songIds: songIds.where((id) => id != songId).toList(),
      updatedAt: DateTime.now(),
    );
  }

  Playlist reorderSongs(int oldIndex, int newIndex) {
    final newSongIds = List<String>.from(songIds);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final song = newSongIds.removeAt(oldIndex);
    newSongIds.insert(newIndex, song);
    return copyWith(
      songIds: newSongIds,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'songIds': songIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Playlist.fromJson(Map<String, dynamic> json) {
    return Playlist(
      id: json['id'] as String,
      name: json['name'] as String,
      songIds: (json['songIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Playlist && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Playlist(id: $id, name: $name, songs: $songCount)';
}
