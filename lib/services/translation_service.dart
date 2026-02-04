import 'package:translator/translator.dart';
import 'package:hive_flutter/hive_flutter.dart';

class TranslationService {
  static final TranslationService _instance = TranslationService._internal();
  factory TranslationService() => _instance;
  TranslationService._internal();

  final GoogleTranslator _translator = GoogleTranslator();

  // Caché en memoria para traducciones frecuentes
  final Map<String, TranslationResult> _memoryCache = {};

  // Nombre del box de Hive para caché persistente
  static const String _cacheBoxName = 'translation_cache';

  /// Traduce una palabra o frase de inglés a español
  Future<TranslationResult> translate(String text, {
    String from = 'en',
    String to = 'es',
  }) async {
    final cacheKey = '${text.toLowerCase()}_${from}_$to';

    // Buscar en caché de memoria
    if (_memoryCache.containsKey(cacheKey)) {
      return _memoryCache[cacheKey]!;
    }

    // Buscar en caché persistente
    final cachedResult = await _getFromCache(cacheKey);
    if (cachedResult != null) {
      _memoryCache[cacheKey] = cachedResult;
      return cachedResult;
    }

    // Realizar traducción
    try {
      final translation = await _translator.translate(
        text,
        from: from,
        to: to,
      );

      final result = TranslationResult(
        originalText: text,
        translatedText: translation.text,
        sourceLanguage: from,
        targetLanguage: to,
      );

      // Guardar en caché
      _memoryCache[cacheKey] = result;
      await _saveToCache(cacheKey, result);

      return result;
    } catch (e) {
      return TranslationResult(
        originalText: text,
        translatedText: text, // Devolver el original si falla
        sourceLanguage: from,
        targetLanguage: to,
        error: e.toString(),
      );
    }
  }

  /// Traduce múltiples palabras en batch
  Future<List<TranslationResult>> translateBatch(List<String> texts, {
    String from = 'en',
    String to = 'es',
  }) async {
    final results = <TranslationResult>[];

    for (final text in texts) {
      final result = await translate(text, from: from, to: to);
      results.add(result);

      // Pequeña pausa para evitar rate limiting
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return results;
  }

  /// Obtiene traducción del caché persistente
  Future<TranslationResult?> _getFromCache(String key) async {
    try {
      final box = await Hive.openBox(_cacheBoxName);
      final data = box.get(key);

      if (data != null) {
        return TranslationResult.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (_) {
      // Ignorar errores de caché
    }
    return null;
  }

  /// Guarda traducción en caché persistente
  Future<void> _saveToCache(String key, TranslationResult result) async {
    try {
      final box = await Hive.openBox(_cacheBoxName);
      await box.put(key, result.toJson());
    } catch (_) {
      // Ignorar errores de caché
    }
  }

  /// Limpia el caché de traducciones
  Future<void> clearCache() async {
    _memoryCache.clear();
    try {
      final box = await Hive.openBox(_cacheBoxName);
      await box.clear();
    } catch (_) {
      // Ignorar errores
    }
  }

  /// Obtiene el número de traducciones en caché
  Future<int> getCacheSize() async {
    try {
      final box = await Hive.openBox(_cacheBoxName);
      return box.length;
    } catch (_) {
      return _memoryCache.length;
    }
  }
}

class TranslationResult {
  final String originalText;
  final String translatedText;
  final String sourceLanguage;
  final String targetLanguage;
  final String? error;

  TranslationResult({
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    this.error,
  });

  bool get hasError => error != null;
  bool get isSuccessful => error == null;

  Map<String, dynamic> toJson() => {
    'originalText': originalText,
    'translatedText': translatedText,
    'sourceLanguage': sourceLanguage,
    'targetLanguage': targetLanguage,
    'error': error,
  };

  factory TranslationResult.fromJson(Map<String, dynamic> json) {
    return TranslationResult(
      originalText: json['originalText'] as String,
      translatedText: json['translatedText'] as String,
      sourceLanguage: json['sourceLanguage'] as String,
      targetLanguage: json['targetLanguage'] as String,
      error: json['error'] as String?,
    );
  }
}
