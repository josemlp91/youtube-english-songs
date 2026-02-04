import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../config/constants.dart';
import '../models/glossary_word.dart';

class GlossaryProvider extends ChangeNotifier {
  List<GlossaryWord> _words = [];
  bool _isLoading = false;
  String? _error;

  List<GlossaryWord> get words => _words;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isEmpty => _words.isEmpty;
  int get wordCount => _words.length;

  GlossaryProvider() {
    loadWords();
  }

  Future<void> loadWords() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final box = Hive.box(AppConstants.glossaryBox);
      final wordsData = box.values.toList();
      _words = wordsData.map((data) => GlossaryWord.fromJson(Map<String, dynamic>.from(data))).toList();
      _words.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    } catch (e) {
      _error = 'Error al cargar el glosario: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addWord(GlossaryWord word) async {
    // Verificar si la palabra ya existe
    if (_words.any((w) => w.word.toLowerCase() == word.word.toLowerCase())) {
      _error = 'La palabra "${word.word}" ya existe en el glosario';
      notifyListeners();
      return;
    }

    try {
      final box = Hive.box(AppConstants.glossaryBox);
      await box.put(word.id, word.toJson());
      _words.insert(0, word);
      notifyListeners();
    } catch (e) {
      _error = 'Error al agregar la palabra: $e';
      notifyListeners();
    }
  }

  Future<void> removeWord(String wordId) async {
    try {
      final box = Hive.box(AppConstants.glossaryBox);
      await box.delete(wordId);
      _words.removeWhere((word) => word.id == wordId);
      notifyListeners();
    } catch (e) {
      _error = 'Error al eliminar la palabra: $e';
      notifyListeners();
    }
  }

  Future<void> updateWord(GlossaryWord updatedWord) async {
    try {
      final box = Hive.box(AppConstants.glossaryBox);
      await box.put(updatedWord.id, updatedWord.toJson());
      final index = _words.indexWhere((w) => w.id == updatedWord.id);
      if (index != -1) {
        _words[index] = updatedWord;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error al actualizar la palabra: $e';
      notifyListeners();
    }
  }

  Future<void> incrementTimesReviewed(String wordId) async {
    final word = _words.firstWhere((w) => w.id == wordId);
    final updatedWord = word.copyWith(timesReviewed: word.timesReviewed + 1);
    await updateWord(updatedWord);
  }

  bool isWordInGlossary(String word) {
    return _words.any((w) => w.word.toLowerCase() == word.toLowerCase());
  }

  List<GlossaryWord> getWordsBySong(String songId) {
    return _words.where((w) => w.songId == songId).toList();
  }

  List<GlossaryWord> searchWords(String query) {
    final lowerQuery = query.toLowerCase();
    return _words.where((w) =>
        w.word.toLowerCase().contains(lowerQuery) ||
        w.translation.toLowerCase().contains(lowerQuery)).toList();
  }

  // Get words for practice, prioritized by spaced repetition
  List<GlossaryWord> getWordsForPractice({int limit = 10}) {
    final sortedWords = List<GlossaryWord>.from(_words)
      ..sort((a, b) => b.reviewPriority.compareTo(a.reviewPriority));
    return sortedWords.take(limit).toList();
  }

  // Get words due for review
  List<GlossaryWord> getDueWords() {
    return _words.where((w) => w.isDueForReview).toList();
  }

  // Record correct answer for a word
  Future<void> recordCorrectAnswer(String wordId) async {
    final index = _words.indexWhere((w) => w.id == wordId);
    if (index != -1) {
      final updatedWord = _words[index].recordCorrect();
      await updateWord(updatedWord);
    }
  }

  // Record wrong answer for a word
  Future<void> recordWrongAnswer(String wordId) async {
    final index = _words.indexWhere((w) => w.id == wordId);
    if (index != -1) {
      final updatedWord = _words[index].recordWrong();
      await updateWord(updatedWord);
    }
  }

  // Get practice statistics
  Map<String, dynamic> getPracticeStats() {
    final totalReviews = _words.fold<int>(0, (sum, w) => sum + w.timesReviewed);
    final totalCorrect = _words.fold<int>(0, (sum, w) => sum + w.timesCorrect);
    final dueWords = getDueWords().length;

    return {
      'totalWords': _words.length,
      'totalReviews': totalReviews,
      'totalCorrect': totalCorrect,
      'accuracy': totalReviews > 0 ? (totalCorrect / totalReviews * 100) : 0.0,
      'dueWords': dueWords,
    };
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
