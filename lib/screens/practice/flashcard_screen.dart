import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/glossary_word.dart';
import '../../providers/glossary_provider.dart';
import '../../services/tts_service.dart';

class FlashcardScreen extends StatefulWidget {
  const FlashcardScreen({super.key});

  @override
  State<FlashcardScreen> createState() => _FlashcardScreenState();
}

class _FlashcardScreenState extends State<FlashcardScreen> {
  final TtsService _ttsService = TtsService();
  late List<GlossaryWord> _words;
  int _currentIndex = 0;
  bool _isRevealed = false;
  int _correctCount = 0;
  int _wrongCount = 0;
  bool _isFinished = false;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  void _loadWords() {
    final provider = context.read<GlossaryProvider>();
    _words = provider.getWordsForPractice(limit: 10);
    _words.shuffle(Random());
  }

  void _revealCard() {
    setState(() => _isRevealed = true);
  }

  void _markCorrect() {
    final word = _words[_currentIndex];
    context.read<GlossaryProvider>().recordCorrectAnswer(word.id);
    setState(() {
      _correctCount++;
      _nextCard();
    });
  }

  void _markWrong() {
    final word = _words[_currentIndex];
    context.read<GlossaryProvider>().recordWrongAnswer(word.id);
    setState(() {
      _wrongCount++;
      _nextCard();
    });
  }

  void _nextCard() {
    if (_currentIndex < _words.length - 1) {
      setState(() {
        _currentIndex++;
        _isRevealed = false;
      });
    } else {
      setState(() => _isFinished = true);
    }
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _isRevealed = false;
      _correctCount = 0;
      _wrongCount = 0;
      _isFinished = false;
    });
    _loadWords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flashcards'),
        actions: [
          if (!_isFinished)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Text(
                  '${_currentIndex + 1}/${_words.length}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
      body: _words.isEmpty
          ? const Center(child: Text('No hay palabras para practicar'))
          : _isFinished
              ? _buildResultsScreen()
              : _buildFlashcard(),
    );
  }

  Widget _buildFlashcard() {
    final word = _words[_currentIndex];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _words.length,
            backgroundColor: AppTheme.backgroundColor,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatChip(Icons.check_circle, _correctCount, AppTheme.successColor),
              const SizedBox(width: 16),
              _buildStatChip(Icons.cancel, _wrongCount, AppTheme.errorColor),
            ],
          ),
          const SizedBox(height: 32),

          // Flashcard
          Expanded(
            child: GestureDetector(
              onTap: _isRevealed ? null : _revealCard,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Container(
                  key: ValueKey('$_currentIndex-$_isRevealed'),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(40),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Word
                        Text(
                          word.word,
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),

                        // Listen button
                        IconButton(
                          onPressed: () => _ttsService.speak(word.word),
                          icon: const Icon(Icons.volume_up, size: 32),
                          color: AppTheme.primaryColor,
                        ),

                        if (_isRevealed) ...[
                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 32),

                          // Translation
                          const Text(
                            'Traduccion',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            word.translation,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.primaryColor,
                            ),
                            textAlign: TextAlign.center,
                          ),

                          if (word.songTitle != null) ...[
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.backgroundColor,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.music_note, size: 14, color: AppTheme.textSecondary),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      word.songTitle!,
                                      style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ] else ...[
                          const SizedBox(height: 32),
                          Text(
                            'Toca para revelar',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary.withAlpha(150),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Action buttons
          if (_isRevealed)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _markWrong,
                    icon: const Icon(Icons.close),
                    label: const Text('No sabia'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _markCorrect,
                    icon: const Icon(Icons.check),
                    label: const Text('Lo sabia'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.successColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _revealCard,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Mostrar traduccion'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsScreen() {
    final total = _correctCount + _wrongCount;
    final accuracy = total > 0 ? (_correctCount / total * 100).round() : 0;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              accuracy >= 70 ? Icons.emoji_events : Icons.school,
              size: 80,
              color: accuracy >= 70 ? Colors.amber : AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              accuracy >= 70 ? 'Excelente!' : 'Sigue practicando',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 32),

            // Results
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.surfaceColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildResultRow('Correctas', _correctCount, AppTheme.successColor),
                  const SizedBox(height: 12),
                  _buildResultRow('Incorrectas', _wrongCount, AppTheme.errorColor),
                  const Divider(height: 32),
                  _buildResultRow('Precision', '$accuracy%', AppTheme.primaryColor),
                ],
              ),
            ),

            const SizedBox(height: 32),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Salir'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _restart,
                    child: const Text('Practicar de nuevo'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, dynamic value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
