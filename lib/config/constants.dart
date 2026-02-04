class AppConstants {
  // App info
  static const String appName = 'YouTube English Songs';
  static const String appVersion = '1.0.0';

  // Hive box names
  static const String songsBox = 'songs';
  static const String glossaryBox = 'glossary';
  static const String settingsBox = 'settings';

  // Player settings
  static const int defaultSkipSeconds = 5;
  static const double defaultPlaybackRate = 1.0;
  static const List<double> playbackRates = [0.5, 0.75, 1.0, 1.25, 1.5];

  // YouTube
  static const String youtubeBaseUrl = 'https://www.youtube.com/watch?v=';
  static const String youtubeThumbnailUrl = 'https://img.youtube.com/vi/{videoId}/mqdefault.jpg';

  // Default songs to preload on first launch
  static const List<String> defaultSongIds = [
    'RBumgq5yVrA',
    'nSDgHBxUbVQ',
    'c-3vPxKdj6o',
    'LjhCEhWiKXk',
  ];

  // Languages
  static const String sourceLanguage = 'en';
  static const String targetLanguage = 'es';
}
