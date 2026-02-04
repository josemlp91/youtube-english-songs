import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/song.dart';
import '../models/subtitle.dart';

class YouTubeService {
  static final YouTubeService _instance = YouTubeService._internal();
  factory YouTubeService() => _instance;
  YouTubeService._internal();

  /// Extrae el ID del video de una URL de YouTube
  String? extractVideoId(String url) {
    return Song.extractYoutubeId(url);
  }

  /// Obtiene los metadatos de un video usando oEmbed (no requiere API key)
  Future<Song?> getVideoMetadata(String urlOrId) async {
    final videoId = extractVideoId(urlOrId) ?? urlOrId;

    if (videoId.length != 11) {
      return null;
    }

    try {
      final oEmbedUrl = Uri.parse(
        'https://www.youtube.com/oembed?url=https://www.youtube.com/watch?v=$videoId&format=json',
      );

      final response = await http.get(oEmbedUrl);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        final fullTitle = data['title'] as String? ?? 'Unknown Title';
        final authorName = data['author_name'] as String? ?? 'Unknown Artist';

        // Intentar separar título y artista si el formato es "Artista - Canción"
        String title = fullTitle;
        String artist = authorName;

        if (fullTitle.contains(' - ')) {
          final parts = fullTitle.split(' - ');
          if (parts.length >= 2) {
            artist = parts[0].trim();
            title = parts.sublist(1).join(' - ').trim();
          }
        }

        return Song(
          youtubeId: videoId,
          title: title,
          artist: artist,
        );
      }
    } catch (e) {
      // Si falla oEmbed, crear canción con datos básicos
    }

    // Fallback: crear canción solo con el ID
    return Song(
      youtubeId: videoId,
      title: 'Video $videoId',
      artist: 'Unknown Artist',
    );
  }

  /// Obtiene la URL de la miniatura del video
  String getThumbnailUrl(String videoId, {ThumbnailQuality quality = ThumbnailQuality.medium}) {
    final qualityPath = switch (quality) {
      ThumbnailQuality.default_ => 'default',
      ThumbnailQuality.medium => 'mqdefault',
      ThumbnailQuality.high => 'hqdefault',
      ThumbnailQuality.standard => 'sddefault',
      ThumbnailQuality.maxres => 'maxresdefault',
    };
    return 'https://img.youtube.com/vi/$videoId/$qualityPath.jpg';
  }

  /// Parsea subtítulos en formato SRT
  List<Subtitle> parseSrtSubtitles(String srtContent) {
    final subtitles = <Subtitle>[];
    final blocks = srtContent.trim().split(RegExp(r'\n\n+'));

    for (final block in blocks) {
      final lines = block.split('\n');
      if (lines.length < 3) continue;

      // Línea de tiempo: "00:00:01,000 --> 00:00:04,000"
      final timeLine = lines[1];
      final timeMatch = RegExp(
        r'(\d{2}):(\d{2}):(\d{2})[,.](\d{3})\s*-->\s*(\d{2}):(\d{2}):(\d{2})[,.](\d{3})',
      ).firstMatch(timeLine);

      if (timeMatch == null) continue;

      final startTime = Duration(
        hours: int.parse(timeMatch.group(1)!),
        minutes: int.parse(timeMatch.group(2)!),
        seconds: int.parse(timeMatch.group(3)!),
        milliseconds: int.parse(timeMatch.group(4)!),
      );

      final endTime = Duration(
        hours: int.parse(timeMatch.group(5)!),
        minutes: int.parse(timeMatch.group(6)!),
        seconds: int.parse(timeMatch.group(7)!),
        milliseconds: int.parse(timeMatch.group(8)!),
      );

      // Texto del subtítulo (puede ser múltiples líneas)
      final text = lines.sublist(2).join(' ').trim();

      if (text.isNotEmpty) {
        subtitles.add(Subtitle(
          text: text,
          startTime: startTime,
          endTime: endTime,
        ));
      }
    }

    return subtitles;
  }

  /// Parsea subtítulos en formato VTT
  List<Subtitle> parseVttSubtitles(String vttContent) {
    final subtitles = <Subtitle>[];
    final lines = vttContent.split('\n');

    int i = 0;
    // Saltar cabecera WEBVTT
    while (i < lines.length && !lines[i].contains('-->')) {
      i++;
    }

    while (i < lines.length) {
      final line = lines[i].trim();

      if (line.contains('-->')) {
        final timeMatch = RegExp(
          r'(\d{2}):(\d{2})[:\.](\d{2})[,.](\d{3})\s*-->\s*(\d{2}):(\d{2})[:\.](\d{2})[,.](\d{3})',
        ).firstMatch(line);

        if (timeMatch != null) {
          final startTime = Duration(
            hours: int.parse(timeMatch.group(1)!),
            minutes: int.parse(timeMatch.group(2)!),
            seconds: int.parse(timeMatch.group(3)!),
            milliseconds: int.parse(timeMatch.group(4)!),
          );

          final endTime = Duration(
            hours: int.parse(timeMatch.group(5)!),
            minutes: int.parse(timeMatch.group(6)!),
            seconds: int.parse(timeMatch.group(7)!),
            milliseconds: int.parse(timeMatch.group(8)!),
          );

          // Recoger líneas de texto hasta línea vacía
          i++;
          final textLines = <String>[];
          while (i < lines.length && lines[i].trim().isNotEmpty) {
            textLines.add(lines[i].trim());
            i++;
          }

          final text = textLines.join(' ')
              .replaceAll(RegExp(r'<[^>]*>'), '') // Eliminar tags HTML
              .trim();

          if (text.isNotEmpty) {
            subtitles.add(Subtitle(
              text: text,
              startTime: startTime,
              endTime: endTime,
            ));
          }
        }
      }
      i++;
    }

    return subtitles;
  }

  /// Valida si una URL o ID es válido
  bool isValidYoutubeUrl(String urlOrId) {
    final videoId = extractVideoId(urlOrId);
    return videoId != null && videoId.length == 11;
  }
}

enum ThumbnailQuality {
  default_,
  medium,
  high,
  standard,
  maxres,
}
