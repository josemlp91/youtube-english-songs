import 'package:flutter/foundation.dart';

import '../models/song.dart';
import '../config/constants.dart';

class PlayerProvider extends ChangeNotifier {
  Song? _currentSong;
  bool _isPlaying = false;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  double _playbackRate = AppConstants.defaultPlaybackRate;
  bool _subtitlesEnabled = true;

  // Loop A-B
  Duration? _loopStart;
  Duration? _loopEnd;
  bool _isLooping = false;

  Song? get currentSong => _currentSong;
  bool get isPlaying => _isPlaying;
  Duration get currentPosition => _currentPosition;
  Duration get totalDuration => _totalDuration;
  double get playbackRate => _playbackRate;
  bool get subtitlesEnabled => _subtitlesEnabled;
  Duration? get loopStart => _loopStart;
  Duration? get loopEnd => _loopEnd;
  bool get isLooping => _isLooping;

  void setCurrentSong(Song? song) {
    _currentSong = song;
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    _isPlaying = false;
    _loopStart = null;
    _loopEnd = null;
    _isLooping = false;
    notifyListeners();
  }

  void setPlaying(bool playing) {
    _isPlaying = playing;
    notifyListeners();
  }

  void setCurrentPosition(Duration position) {
    _currentPosition = position;
    notifyListeners();
  }

  void setTotalDuration(Duration duration) {
    _totalDuration = duration;
    notifyListeners();
  }

  void setPlaybackRate(double rate) {
    if (AppConstants.playbackRates.contains(rate)) {
      _playbackRate = rate;
      notifyListeners();
    }
  }

  void toggleSubtitles() {
    _subtitlesEnabled = !_subtitlesEnabled;
    notifyListeners();
  }

  void setLoopStart(Duration start) {
    _loopStart = start;
    notifyListeners();
  }

  void setLoopEnd(Duration end) {
    _loopEnd = end;
    _isLooping = true;
    notifyListeners();
  }

  void clearLoop() {
    _loopStart = null;
    _loopEnd = null;
    _isLooping = false;
    notifyListeners();
  }

  void toggleLoop() {
    if (_loopStart != null && _loopEnd != null) {
      _isLooping = !_isLooping;
      notifyListeners();
    }
  }

  Duration skipForward({int seconds = AppConstants.defaultSkipSeconds}) {
    final newPosition = _currentPosition + Duration(seconds: seconds);
    if (newPosition <= _totalDuration) {
      return newPosition;
    }
    return _totalDuration;
  }

  Duration skipBackward({int seconds = AppConstants.defaultSkipSeconds}) {
    final newPosition = _currentPosition - Duration(seconds: seconds);
    if (newPosition >= Duration.zero) {
      return newPosition;
    }
    return Duration.zero;
  }

  void reset() {
    _currentSong = null;
    _isPlaying = false;
    _currentPosition = Duration.zero;
    _totalDuration = Duration.zero;
    _playbackRate = AppConstants.defaultPlaybackRate;
    _loopStart = null;
    _loopEnd = null;
    _isLooping = false;
    notifyListeners();
  }
}
