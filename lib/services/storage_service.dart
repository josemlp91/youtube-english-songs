import 'package:hive_flutter/hive_flutter.dart';

import '../config/constants.dart';
import '../models/song.dart';
import '../models/glossary_word.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Boxes
  Box? _songsBox;
  Box? _glossaryBox;
  Box? _settingsBox;

  /// Inicializa el servicio de almacenamiento
  Future<void> init() async {
    await Hive.initFlutter();
    _songsBox = await Hive.openBox(AppConstants.songsBox);
    _glossaryBox = await Hive.openBox(AppConstants.glossaryBox);
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);
  }

  // ==================== SONGS ====================

  /// Obtiene todas las canciones
  List<Song> getAllSongs() {
    final box = _songsBox ?? Hive.box(AppConstants.songsBox);
    return box.values
        .map((data) => Song.fromJson(Map<String, dynamic>.from(data)))
        .toList();
  }

  /// Guarda una canción
  Future<void> saveSong(Song song) async {
    final box = _songsBox ?? Hive.box(AppConstants.songsBox);
    await box.put(song.id, song.toJson());
  }

  /// Elimina una canción
  Future<void> deleteSong(String songId) async {
    final box = _songsBox ?? Hive.box(AppConstants.songsBox);
    await box.delete(songId);
  }

  /// Obtiene una canción por ID
  Song? getSong(String songId) {
    final box = _songsBox ?? Hive.box(AppConstants.songsBox);
    final data = box.get(songId);
    if (data == null) return null;
    return Song.fromJson(Map<String, dynamic>.from(data));
  }

  /// Guarda todas las canciones (reemplaza)
  Future<void> saveAllSongs(List<Song> songs) async {
    final box = _songsBox ?? Hive.box(AppConstants.songsBox);
    await box.clear();
    for (final song in songs) {
      await box.put(song.id, song.toJson());
    }
  }

  // ==================== GLOSSARY ====================

  /// Obtiene todas las palabras del glosario
  List<GlossaryWord> getAllWords() {
    final box = _glossaryBox ?? Hive.box(AppConstants.glossaryBox);
    return box.values
        .map((data) => GlossaryWord.fromJson(Map<String, dynamic>.from(data)))
        .toList();
  }

  /// Guarda una palabra
  Future<void> saveWord(GlossaryWord word) async {
    final box = _glossaryBox ?? Hive.box(AppConstants.glossaryBox);
    await box.put(word.id, word.toJson());
  }

  /// Elimina una palabra
  Future<void> deleteWord(String wordId) async {
    final box = _glossaryBox ?? Hive.box(AppConstants.glossaryBox);
    await box.delete(wordId);
  }

  /// Obtiene una palabra por ID
  GlossaryWord? getWord(String wordId) {
    final box = _glossaryBox ?? Hive.box(AppConstants.glossaryBox);
    final data = box.get(wordId);
    if (data == null) return null;
    return GlossaryWord.fromJson(Map<String, dynamic>.from(data));
  }

  /// Busca si una palabra ya existe en el glosario
  bool wordExists(String word) {
    final words = getAllWords();
    return words.any((w) => w.word.toLowerCase() == word.toLowerCase());
  }

  // ==================== SETTINGS ====================

  /// Obtiene un valor de configuración
  T? getSetting<T>(String key, {T? defaultValue}) {
    final box = _settingsBox ?? Hive.box(AppConstants.settingsBox);
    return box.get(key, defaultValue: defaultValue) as T?;
  }

  /// Guarda un valor de configuración
  Future<void> setSetting<T>(String key, T value) async {
    final box = _settingsBox ?? Hive.box(AppConstants.settingsBox);
    await box.put(key, value);
  }

  /// Elimina un valor de configuración
  Future<void> deleteSetting(String key) async {
    final box = _settingsBox ?? Hive.box(AppConstants.settingsBox);
    await box.delete(key);
  }

  // ==================== UTILITY ====================

  /// Limpia todos los datos
  Future<void> clearAll() async {
    await _songsBox?.clear();
    await _glossaryBox?.clear();
    await _settingsBox?.clear();
  }

  /// Exporta todos los datos como JSON
  Map<String, dynamic> exportData() {
    return {
      'songs': getAllSongs().map((s) => s.toJson()).toList(),
      'glossary': getAllWords().map((w) => w.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Importa datos desde JSON
  Future<void> importData(Map<String, dynamic> data) async {
    if (data['songs'] != null) {
      final songs = (data['songs'] as List)
          .map((s) => Song.fromJson(Map<String, dynamic>.from(s)))
          .toList();
      await saveAllSongs(songs);
    }

    if (data['glossary'] != null) {
      final box = _glossaryBox ?? Hive.box(AppConstants.glossaryBox);
      await box.clear();
      for (final wordData in data['glossary']) {
        final word = GlossaryWord.fromJson(Map<String, dynamic>.from(wordData));
        await saveWord(word);
      }
    }
  }

  /// Cierra todas las cajas
  Future<void> close() async {
    await _songsBox?.close();
    await _glossaryBox?.close();
    await _settingsBox?.close();
  }
}
