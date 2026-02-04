import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/song.dart';
import '../providers/glossary_provider.dart';
import 'word_popup.dart';

class InteractiveSubtitles extends StatefulWidget {
  final Song? currentSong;
  final Duration currentPosition;

  const InteractiveSubtitles({
    super.key,
    this.currentSong,
    required this.currentPosition,
  });

  @override
  State<InteractiveSubtitles> createState() => _InteractiveSubtitlesState();
}

class _InteractiveSubtitlesState extends State<InteractiveSubtitles> {
  final TextEditingController _textController = TextEditingController();
  String _currentText = '';
  bool _isExpanded = true;
  bool _isSelectingPhrase = false;
  final Set<int> _selectedWordIndices = {};

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  List<String> _getWords(String text) {
    return text
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w.replaceAll(RegExp(r"[^\w']"), ''))
        .where((w) => w.isNotEmpty)
        .toList();
  }

  String _getSelectedPhrase(List<String> words) {
    if (_selectedWordIndices.isEmpty) return '';
    final sortedIndices = _selectedWordIndices.toList()..sort();
    return sortedIndices.map((i) => words[i]).join(' ');
  }

  void _showWordPopup(BuildContext context, String word) {
    final glossaryProvider = context.read<GlossaryProvider>();
    final cleanWord = word.toLowerCase().trim();

    if (cleanWord.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => WordPopup(
        word: cleanWord,
        songId: widget.currentSong?.id,
        songTitle: widget.currentSong?.title,
        timestamp: widget.currentPosition,
        isInGlossary: glossaryProvider.isWordInGlossary(cleanWord),
        onAddToGlossary: (glossaryWord) {
          glossaryProvider.addWord(glossaryWord);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${glossaryWord.word}" agregada al glosario'),
              backgroundColor: AppTheme.successColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _toggleWordSelection(int index) {
    setState(() {
      if (_selectedWordIndices.contains(index)) {
        _selectedWordIndices.remove(index);
      } else {
        _selectedWordIndices.add(index);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _isSelectingPhrase = false;
      _selectedWordIndices.clear();
    });
  }

  void _confirmPhraseSelection(List<String> words) {
    final phrase = _getSelectedPhrase(words);
    if (phrase.isNotEmpty) {
      _showWordPopup(context, phrase);
    }
    _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.touch_app, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Capturar vocabulario',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ),
          ),

          if (_isExpanded) ...[
            const Divider(height: 1, color: AppTheme.backgroundColor),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Instrucciones
                  Text(
                    _isSelectingPhrase
                        ? 'Selecciona las palabras de la frase y pulsa el boton para agregar'
                        : 'Toca una palabra para traducirla. Manten pulsado para seleccionar varias palabras como frase.',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Input de texto
                  TextField(
                    controller: _textController,
                    decoration: InputDecoration(
                      hintText: 'Escribe lo que escuchas...',
                      hintStyle: const TextStyle(color: AppTheme.textSecondary),
                      filled: true,
                      fillColor: AppTheme.backgroundColor,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_textController.text.isNotEmpty)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () {
                                _textController.clear();
                                setState(() {
                                  _currentText = '';
                                  _clearSelection();
                                });
                              },
                              color: AppTheme.textSecondary,
                            ),
                          IconButton(
                            icon: const Icon(Icons.check, size: 20),
                            onPressed: () {
                              setState(() => _currentText = _textController.text);
                              FocusScope.of(context).unfocus();
                            },
                            color: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                    style: const TextStyle(color: AppTheme.textPrimary),
                    maxLines: 2,
                    onSubmitted: (value) {
                      setState(() => _currentText = value);
                    },
                  ),

                  // Palabras clickeables
                  if (_currentText.isNotEmpty) ...[
                    const SizedBox(height: 16),

                    // Mode toggle and selection actions
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _isSelectingPhrase
                                ? 'Modo: Seleccionar frase'
                                : 'Haz clic en una palabra:',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                        if (_isSelectingPhrase) ...[
                          TextButton.icon(
                            onPressed: _clearSelection,
                            icon: const Icon(Icons.close, size: 16),
                            label: const Text('Cancelar'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.textSecondary,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ] else ...[
                          TextButton.icon(
                            onPressed: () => setState(() => _isSelectingPhrase = true),
                            icon: const Icon(Icons.select_all, size: 16),
                            label: const Text('Frase'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),

                    Consumer<GlossaryProvider>(
                      builder: (context, glossaryProvider, child) {
                        final words = _getWords(_currentText);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: words.asMap().entries.map((entry) {
                                final index = entry.key;
                                final word = entry.value;
                                final isInGlossary = glossaryProvider.isWordInGlossary(word);
                                final isSelected = _selectedWordIndices.contains(index);

                                return _WordChip(
                                  word: word,
                                  isInGlossary: isInGlossary,
                                  isSelected: isSelected,
                                  isSelectingMode: _isSelectingPhrase,
                                  onTap: () {
                                    if (_isSelectingPhrase) {
                                      _toggleWordSelection(index);
                                    } else {
                                      _showWordPopup(context, word);
                                    }
                                  },
                                  onLongPress: () {
                                    setState(() {
                                      _isSelectingPhrase = true;
                                      _selectedWordIndices.add(index);
                                    });
                                  },
                                );
                              }).toList(),
                            ),

                            // Selected phrase preview and confirm button
                            if (_isSelectingPhrase && _selectedWordIndices.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppTheme.primaryColor.withAlpha(50)),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Frase seleccionada:',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _getSelectedPhrase(words),
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => _confirmPhraseSelection(words),
                                      icon: const Icon(Icons.translate, size: 18),
                                      label: const Text('Traducir'),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ],

                  // Frases de ejemplo
                  if (_currentText.isEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'O prueba con estas frases:',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ExampleChip(
                          text: 'give up on your dreams',
                          onTap: () {
                            _textController.text = 'give up on your dreams';
                            setState(() => _currentText = 'give up on your dreams');
                          },
                        ),
                        _ExampleChip(
                          text: 'break a leg',
                          onTap: () {
                            _textController.text = 'break a leg';
                            setState(() => _currentText = 'break a leg');
                          },
                        ),
                        _ExampleChip(
                          text: 'I look forward to seeing you',
                          onTap: () {
                            _textController.text = 'I look forward to seeing you';
                            setState(() => _currentText = 'I look forward to seeing you');
                          },
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _WordChip extends StatelessWidget {
  final String word;
  final bool isInGlossary;
  final bool isSelected;
  final bool isSelectingMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _WordChip({
    required this.word,
    required this.isInGlossary,
    this.isSelected = false,
    this.isSelectingMode = false,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (isSelected) {
      backgroundColor = AppTheme.primaryColor.withAlpha(50);
      borderColor = AppTheme.primaryColor;
      textColor = AppTheme.primaryColor;
    } else if (isInGlossary) {
      backgroundColor = AppTheme.successColor.withAlpha(30);
      borderColor = AppTheme.successColor.withAlpha(100);
      textColor = AppTheme.successColor;
    } else {
      backgroundColor = AppTheme.primaryColor.withAlpha(20);
      borderColor = AppTheme.primaryColor.withAlpha(50);
      textColor = AppTheme.textPrimary;
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check, size: 14, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
              ],
              Text(
                word,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              if (isInGlossary && !isSelected) ...[
                const SizedBox(width: 4),
                const Icon(Icons.check_circle, size: 14, color: AppTheme.successColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _ExampleChip({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(text),
      onPressed: onTap,
      backgroundColor: AppTheme.backgroundColor,
      labelStyle: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 12,
      ),
    );
  }
}
