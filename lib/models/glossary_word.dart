import 'package:uuid/uuid.dart';

enum EntryType {
  word,       // Palabra individual
  expression, // Expresión
  idiom,      // Frase hecha
  phrasalVerb // Phrasal verb
}

extension EntryTypeExtension on EntryType {
  String get displayName {
    switch (this) {
      case EntryType.word:
        return 'Palabra';
      case EntryType.expression:
        return 'Expresión';
      case EntryType.idiom:
        return 'Frase hecha';
      case EntryType.phrasalVerb:
        return 'Phrasal verb';
    }
  }

  String get emoji {
    switch (this) {
      case EntryType.word:
        return '📝';
      case EntryType.expression:
        return '💬';
      case EntryType.idiom:
        return '🎯';
      case EntryType.phrasalVerb:
        return '🔗';
    }
  }
}

class GlossaryWord {
  final String id;
  final String word;
  final String translation;
  final EntryType entryType;
  final String? phonetic;
  final String? example; // Example sentence for expressions/idioms
  final String? songId;
  final String? songTitle;
  final Duration? timestamp;
  final DateTime dateAdded;
  final int timesReviewed;
  final int timesCorrect;
  final int timesWrong;
  final DateTime? lastReviewedAt;
  final double easeFactor; // For spaced repetition (2.5 default)
  final DateTime? nextReviewAt;

  GlossaryWord({
    String? id,
    required this.word,
    required this.translation,
    this.entryType = EntryType.word,
    this.phonetic,
    this.example,
    this.songId,
    this.songTitle,
    this.timestamp,
    DateTime? dateAdded,
    this.timesReviewed = 0,
    this.timesCorrect = 0,
    this.timesWrong = 0,
    this.lastReviewedAt,
    this.easeFactor = 2.5,
    this.nextReviewAt,
  })  : id = id ?? const Uuid().v4(),
        dateAdded = dateAdded ?? DateTime.now();

  // Check if entry is a phrase (multiple words)
  bool get isPhrase => entryType != EntryType.word;

  // Accuracy percentage (0-100)
  double get accuracy {
    final total = timesCorrect + timesWrong;
    if (total == 0) return 0;
    return (timesCorrect / total) * 100;
  }

  // Priority score for spaced repetition (higher = needs more review)
  double get reviewPriority {
    if (nextReviewAt == null) return 100.0; // Never reviewed
    final now = DateTime.now();
    if (nextReviewAt!.isBefore(now)) {
      // Overdue - higher priority based on how overdue
      final overdueDays = now.difference(nextReviewAt!).inDays;
      return 90.0 + (overdueDays * 2).clamp(0, 10).toDouble();
    }
    // Not due yet - lower priority
    return 50.0 - (nextReviewAt!.difference(now).inDays).clamp(0, 50).toDouble();
  }

  // Check if word is due for review
  bool get isDueForReview {
    if (nextReviewAt == null) return true;
    return DateTime.now().isAfter(nextReviewAt!);
  }

  GlossaryWord copyWith({
    String? id,
    String? word,
    String? translation,
    EntryType? entryType,
    String? phonetic,
    String? example,
    String? songId,
    String? songTitle,
    Duration? timestamp,
    DateTime? dateAdded,
    int? timesReviewed,
    int? timesCorrect,
    int? timesWrong,
    DateTime? lastReviewedAt,
    double? easeFactor,
    DateTime? nextReviewAt,
  }) {
    return GlossaryWord(
      id: id ?? this.id,
      word: word ?? this.word,
      translation: translation ?? this.translation,
      entryType: entryType ?? this.entryType,
      phonetic: phonetic ?? this.phonetic,
      example: example ?? this.example,
      songId: songId ?? this.songId,
      songTitle: songTitle ?? this.songTitle,
      timestamp: timestamp ?? this.timestamp,
      dateAdded: dateAdded ?? this.dateAdded,
      timesReviewed: timesReviewed ?? this.timesReviewed,
      timesCorrect: timesCorrect ?? this.timesCorrect,
      timesWrong: timesWrong ?? this.timesWrong,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      easeFactor: easeFactor ?? this.easeFactor,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
    );
  }

  // Record a correct answer with spaced repetition
  GlossaryWord recordCorrect() {
    final newEase = (easeFactor + 0.1).clamp(1.3, 2.5);
    final interval = _calculateInterval(timesCorrect + 1, newEase);
    return copyWith(
      timesReviewed: timesReviewed + 1,
      timesCorrect: timesCorrect + 1,
      lastReviewedAt: DateTime.now(),
      easeFactor: newEase,
      nextReviewAt: DateTime.now().add(Duration(days: interval)),
    );
  }

  // Record a wrong answer
  GlossaryWord recordWrong() {
    final newEase = (easeFactor - 0.2).clamp(1.3, 2.5);
    return copyWith(
      timesReviewed: timesReviewed + 1,
      timesWrong: timesWrong + 1,
      lastReviewedAt: DateTime.now(),
      easeFactor: newEase,
      nextReviewAt: DateTime.now().add(const Duration(days: 1)), // Review tomorrow
    );
  }

  int _calculateInterval(int consecutiveCorrect, double ease) {
    if (consecutiveCorrect == 1) return 1;
    if (consecutiveCorrect == 2) return 3;
    // Simple SM-2 like algorithm
    return (3 * ease * (consecutiveCorrect - 1)).round().clamp(1, 30);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'translation': translation,
      'entryType': entryType.name,
      'phonetic': phonetic,
      'example': example,
      'songId': songId,
      'songTitle': songTitle,
      'timestamp': timestamp?.inSeconds,
      'dateAdded': dateAdded.toIso8601String(),
      'timesReviewed': timesReviewed,
      'timesCorrect': timesCorrect,
      'timesWrong': timesWrong,
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'easeFactor': easeFactor,
      'nextReviewAt': nextReviewAt?.toIso8601String(),
    };
  }

  factory GlossaryWord.fromJson(Map<String, dynamic> json) {
    return GlossaryWord(
      id: json['id'] as String,
      word: json['word'] as String,
      translation: json['translation'] as String,
      entryType: EntryType.values.firstWhere(
        (e) => e.name == json['entryType'],
        orElse: () => EntryType.word,
      ),
      phonetic: json['phonetic'] as String?,
      example: json['example'] as String?,
      songId: json['songId'] as String?,
      songTitle: json['songTitle'] as String?,
      timestamp: json['timestamp'] != null
          ? Duration(seconds: json['timestamp'] as int)
          : null,
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      timesReviewed: json['timesReviewed'] as int? ?? 0,
      timesCorrect: json['timesCorrect'] as int? ?? 0,
      timesWrong: json['timesWrong'] as int? ?? 0,
      lastReviewedAt: json['lastReviewedAt'] != null
          ? DateTime.parse(json['lastReviewedAt'] as String)
          : null,
      easeFactor: (json['easeFactor'] as num?)?.toDouble() ?? 2.5,
      nextReviewAt: json['nextReviewAt'] != null
          ? DateTime.parse(json['nextReviewAt'] as String)
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlossaryWord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'GlossaryWord(word: $word, translation: $translation)';
}
