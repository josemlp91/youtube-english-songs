import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/glossary_word.dart';
import '../services/translation_service.dart';
import '../services/tts_service.dart';

class WordPopup extends StatefulWidget {
  final String word;
  final String? songId;
  final String? songTitle;
  final Duration? timestamp;
  final bool isInGlossary;
  final Function(GlossaryWord) onAddToGlossary;
  final VoidCallback? onBeforeSpeak;

  const WordPopup({
    super.key,
    required this.word,
    this.songId,
    this.songTitle,
    this.timestamp,
    required this.isInGlossary,
    required this.onAddToGlossary,
    this.onBeforeSpeak,
  });

  @override
  State<WordPopup> createState() => _WordPopupState();
}

class _WordPopupState extends State<WordPopup> {
  final TranslationService _translationService = TranslationService();
  final TtsService _ttsService = TtsService();

  bool _isLoading = true;
  String? _translation;
  String? _error;
  bool _isPlaying = false;
  EntryType _selectedType = EntryType.word;

  @override
  void initState() {
    super.initState();
    _loadTranslation();
    _detectEntryType();
  }

  void _detectEntryType() {
    final wordLower = widget.word.toLowerCase();
    final wordCount = widget.word.split(' ').length;

    // Auto-detect type based on patterns
    if (wordCount >= 2) {
      // Check for common phrasal verb patterns
      final phrasalVerbParticles = ['up', 'down', 'in', 'out', 'on', 'off', 'away', 'back', 'over', 'through'];
      final words = wordLower.split(' ');
      if (words.length == 2 && phrasalVerbParticles.contains(words.last)) {
        _selectedType = EntryType.phrasalVerb;
      } else if (wordCount >= 3) {
        _selectedType = EntryType.idiom;
      } else {
        _selectedType = EntryType.expression;
      }
    }
  }

  Future<void> _loadTranslation() async {
    try {
      final result = await _translationService.translate(widget.word);
      if (mounted) {
        setState(() {
          _translation = result.translatedText;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al traducir';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _playPronunciation() async {
    setState(() => _isPlaying = true);
    widget.onBeforeSpeak?.call();
    await _ttsService.speak(widget.word);
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _playSlowPronunciation() async {
    setState(() => _isPlaying = true);
    widget.onBeforeSpeak?.call();
    await _ttsService.speakSlowly(widget.word);
    await Future.delayed(const Duration(milliseconds: 1000));
    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  void _addToGlossary() {
    if (_translation == null) return;

    final glossaryWord = GlossaryWord(
      word: widget.word,
      translation: _translation!,
      entryType: _selectedType,
      songId: widget.songId,
      songTitle: widget.songTitle,
      timestamp: widget.timestamp,
    );

    widget.onAddToGlossary(glossaryWord);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isPhrase = widget.word.split(' ').length > 1;

    return Dialog(
      backgroundColor: AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Palabra
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.word,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                if (widget.isInGlossary)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: AppTheme.successColor),
                        SizedBox(width: 4),
                        Text(
                          'En glosario',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.successColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Traducción
            if (_isLoading)
              const Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Traduciendo...', style: TextStyle(color: AppTheme.textSecondary)),
                ],
              )
            else if (_error != null)
              Text(_error!, style: const TextStyle(color: AppTheme.errorColor))
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Traduccion',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _translation ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 24),

            // Botones de pronunciación
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isPlaying ? null : _playPronunciation,
                    icon: Icon(_isPlaying ? Icons.volume_up : Icons.volume_up_outlined),
                    label: const Text('Escuchar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isPlaying ? null : _playSlowPronunciation,
                    icon: const Icon(Icons.slow_motion_video),
                    label: const Text('Lento'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.textPrimary,
                      side: const BorderSide(color: AppTheme.textSecondary),
                    ),
                  ),
                ),
              ],
            ),

            // Entry type selector (show for phrases or if user can choose)
            if (!widget.isInGlossary) ...[
              const SizedBox(height: 16),
              const Text(
                'Tipo de entrada',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: EntryType.values.map((type) {
                  final isSelected = _selectedType == type;
                  // Only show relevant types
                  if (!isPhrase && type != EntryType.word) {
                    return const SizedBox.shrink();
                  }
                  return ChoiceChip(
                    label: Text(
                      '${type.emoji} ${type.displayName}',
                      style: TextStyle(fontSize: 12),
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() => _selectedType = type);
                      }
                    },
                    selectedColor: AppTheme.primaryColor.withAlpha(50),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    visualDensity: VisualDensity.compact,
                  );
                }).toList(),
              ),
            ],

            // Info de contexto
            if (widget.songTitle != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.music_note, size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.songTitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.timestamp != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        _formatDuration(widget.timestamp!),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cerrar'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: widget.isInGlossary || _translation == null
                        ? null
                        : _addToGlossary,
                    icon: Icon(widget.isInGlossary ? Icons.check : Icons.add),
                    label: Text(widget.isInGlossary ? 'Ya agregada' : 'Agregar al glosario'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.isInGlossary
                          ? AppTheme.textSecondary
                          : AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
