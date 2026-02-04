import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../config/constants.dart';
import '../models/song.dart';
import '../services/youtube_service.dart';

class PlaylistProvider extends ChangeNotifier {
  List<Song> _songs = [];
  bool _isLoading = false;
  String? _error;

  List<Song> get songs => _songs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _songs.isEmpty;

  PlaylistProvider() {
    loadSongs();
  }

  Future<void> loadSongs() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final box = Hive.box(AppConstants.songsBox);
      final songsData = box.values.toList();
      _songs = songsData.map((data) => Song.fromJson(Map<String, dynamic>.from(data))).toList();
      _songs.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));

      // Load default songs on first launch
      if (_songs.isEmpty) {
        await _loadDefaultSongs();
      }
    } catch (e) {
      _error = 'Error al cargar las canciones: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadDefaultSongs() async {
    final youtubeService = YouTubeService();

    for (final videoId in AppConstants.defaultSongIds) {
      try {
        final song = await youtubeService.getVideoMetadata(videoId);
        if (song != null) {
          await addSong(song);
        }
      } catch (e) {
        // Continue with next song if one fails
        debugPrint('Error loading default song $videoId: $e');
      }
    }
  }

  Future<void> addSong(Song song) async {
    try {
      final box = Hive.box(AppConstants.songsBox);
      await box.put(song.id, song.toJson());
      _songs.insert(0, song);
      notifyListeners();
    } catch (e) {
      _error = 'Error al agregar la canción: $e';
      notifyListeners();
    }
  }

  Future<void> removeSong(String songId) async {
    try {
      final box = Hive.box(AppConstants.songsBox);
      await box.delete(songId);
      _songs.removeWhere((song) => song.id == songId);
      notifyListeners();
    } catch (e) {
      _error = 'Error al eliminar la canción: $e';
      notifyListeners();
    }
  }

  Song? getSongById(String id) {
    try {
      return _songs.firstWhere((song) => song.id == id);
    } catch (_) {
      return null;
    }
  }

  Song? getSongByYoutubeId(String youtubeId) {
    try {
      return _songs.firstWhere((song) => song.youtubeId == youtubeId);
    } catch (_) {
      return null;
    }
  }

  bool hasSongWithYoutubeId(String youtubeId) {
    return _songs.any((song) => song.youtubeId == youtubeId);
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
