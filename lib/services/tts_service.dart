import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  static final TtsService _instance = TtsService._internal();
  factory TtsService() => _instance;
  TtsService._internal();

  final FlutterTts _flutterTts = FlutterTts();
  static final StreamController<void> _beforeSpeakController =
      StreamController<void>.broadcast();
  bool _isInitialized = false;
  bool _voiceLocked = false;
  bool _isWarmedUp = false;

  // Configuración
  double _speechRate = 1.0; // 0.0 - 1.0
  double _pitch = 1.0; // 0.5 - 2.0
  double _volume = 1.0; // 0.0 - 1.0
  String _language = 'en-US';
  String _preferredLocale = 'en-GB';

  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;
  String get language => _language;
  Stream<void> get beforeSpeakStream => _beforeSpeakController.stream;

  /// Inicializa el servicio TTS
  Future<void> init() async {
    if (_isInitialized) return;

    _language = _preferredLocale;
    await _flutterTts.setLanguage(_language);
    await _flutterTts.setSpeechRate(_speechRate);
    await _flutterTts.setVolume(_volume);
    await _flutterTts.setPitch(_pitch);
    await _setPreferredEnglishVoice();

    _isInitialized = true;
    await _warmUpEngine();
  }

  /// Reproduce texto en inglés
  Future<void> speak(String text) async {
    if (!_isInitialized) await init();

    await stop(); // Detener cualquier reproducción anterior
    // Ensure the engine is set to English before speaking (first utterance bug fix).
    await _flutterTts.setLanguage(_language);
    if (!_voiceLocked) {
      await _setPreferredEnglishVoice();
      _voiceLocked = true;
    }
    if (!_isWarmedUp) {
      await _warmUpEngine();
    }
    _beforeSpeakController.add(null);
    await _flutterTts.speak(text);
  }

  /// Detiene la reproducción
  Future<void> stop() async {
    await _flutterTts.stop();
  }

  /// Pausa la reproducción
  Future<void> pause() async {
    await _flutterTts.pause();
  }

  /// Cambia la velocidad de habla
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.0, 1.0);
    await _flutterTts.setSpeechRate(_speechRate);
  }

  /// Cambia el tono
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 2.0);
    await _flutterTts.setPitch(_pitch);
  }

  /// Cambia el volumen
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _flutterTts.setVolume(_volume);
  }

  /// Cambia el idioma
  Future<void> setLanguage(String languageCode) async {
    _language = languageCode;
    await _flutterTts.setLanguage(_language);
    await _setPreferredEnglishVoice();
  }

  /// Obtiene la lista de idiomas disponibles
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages ?? []);
    } catch (_) {
      return ['en-US', 'en-GB'];
    }
  }

  /// Obtiene la lista de voces disponibles
  Future<List<Map<String, String>>> getAvailableVoices() async {
    try {
      final voices = await _flutterTts.getVoices;
      return List<Map<String, String>>.from(
        (voices ?? []).map((v) => Map<String, String>.from(v)),
      );
    } catch (_) {
      return [];
    }
  }

  /// Establece una voz específica
  Future<void> setVoice(String voiceName, String locale) async {
    await _flutterTts.setVoice({'name': voiceName, 'locale': locale});
    _language = locale;
    await _flutterTts.setLanguage(_language);
  }

  Future<void> _setPreferredEnglishVoice() async {
    try {
      final voices = await _flutterTts.getVoices;
      final voiceList = (voices ?? [])
          .map((v) => Map<String, String>.from(v))
          .toList();

      if (voiceList.isEmpty) return;

      Map<String, String>? pick;

      // Prefer "native-sounding" voices when available.
      // Heuristics: en-US first, then other en-*; then prefer neural/premium/etc.
      int scoreVoice(Map<String, String> v) {
        final locale = (v['locale'] ?? '').toLowerCase();
        final name = (v['name'] ?? '').toLowerCase();
        int score = 0;
        if (name.contains('google')) score += 40;
        if (name.contains('female')) score += 25;
        if (name.contains('woman')) score += 20;
        if (locale.startsWith('en-gb')) score += 110;
        if (locale.startsWith('en-us')) score += 100;
        if (locale.startsWith('en-')) score += 50;
        if (name.contains('neural')) score += 30;
        if (name.contains('premium')) score += 20;
        if (name.contains('enhanced')) score += 15;
        if (name.contains('wavenet')) score += 15;
        if (name.contains('standard')) score -= 5;
        if (locale.contains('es')) score -= 100;
        return score;
      }

      voiceList.sort((a, b) => scoreVoice(b).compareTo(scoreVoice(a)));
      pick = voiceList.first;

      final name = pick?['name'] ?? '';
      final locale = pick?['locale'] ?? _preferredLocale;

      if (name.isNotEmpty && locale.isNotEmpty) {
        _language = locale;
        await _flutterTts.setVoice({
          'name': name,
          'locale': locale,
        });
        await _flutterTts.setLanguage(_language);
        _voiceLocked = true;
      }
    } catch (_) {
      // If voices are unavailable on a platform, rely on default TTS voice.
    }
  }

  Future<void> _warmUpEngine() async {
    if (_isWarmedUp) return;
    try {
      final previousVolume = _volume;
      await _flutterTts.setVolume(0.0);
      await _flutterTts.speak(' ');
      await _flutterTts.stop();
      await _flutterTts.setVolume(previousVolume);
      _isWarmedUp = true;
    } catch (_) {
      _isWarmedUp = true;
    }
  }

  /// Verifica si TTS está disponible
  Future<bool> isAvailable() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return languages != null && (languages as List).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Reproduce palabra lentamente (útil para aprender pronunciación)
  Future<void> speakSlowly(String text) async {
    final previousRate = _speechRate;
    await setSpeechRate(0.3);
    await speak(text);
    // Restaurar velocidad después de un delay estimado
    Future.delayed(Duration(milliseconds: (text.length * 200).clamp(500, 5000)), () {
      setSpeechRate(previousRate);
    });
  }

  /// Libera recursos
  Future<void> dispose() async {
    await stop();
  }
}
