import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/glossary_word.dart';
import '../../providers/glossary_provider.dart';
import '../../services/tts_service.dart';

class ListeningScreen extends StatefulWidget {
  const ListeningScreen({super.key});

  @override
  State<ListeningScreen> createState() => _ListeningScreenState();
}

class _ListeningScreenState extends State<ListeningScreen> {
  final TtsService _ttsService = TtsService();
  final TextEditingController _answerController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late List<GlossaryWord> _words;
  int _currentIndex = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  bool _isFinished = false;
  bool _hasSubmitted = false;
  bool _isCorrect = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  @override
  void dispose() {
    _answerController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _loadWords() {
    final provider = context.read<GlossaryProvider>();
    _words = provider.getWordsForPractice(limit: 10);
    _words.shuffle(Random());
  }

  Future<void> _playWord() async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    await _ttsService.speak(_words[_currentIndex].word);
    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  Future<void> _playWordSlow() async {
    if (_isPlaying) return;
    setState(() => _isPlaying = true);
    await _ttsService.speakSlowly(_words[_currentIndex].word);
    if (mounted) {
      setState(() => _isPlaying = false);
    }
  }

  void _submitAnswer() {
    final userAnswer = _answerController.text.trim().toLowerCase();
    final correctAnswer = _words[_currentIndex].word.toLowerCase();

    setState(() {
      _hasSubmitted = true;
      _isCorrect = userAnswer == correctAnswer;

      if (_isCorrect) {
        _correctCount++;
        context.read<GlossaryProvider>().recordCorrectAnswer(_words[_currentIndex].id);
      } else {
        _wrongCount++;
        context.read<GlossaryProvider>().recordWrongAnswer(_words[_currentIndex].id);
      }
    });
  }

  void _nextWord() {
    if (_currentIndex < _words.length - 1) {
      setState(() {
        _currentIndex++;
        _hasSubmitted = false;
        _isCorrect = false;
        _answerController.clear();
      });
      _focusNode.requestFocus();
    } else {
      setState(() => _isFinished = true);
    }
  }

  void _restart() {
    setState(() {
      _currentIndex = 0;
      _correctCount = 0;
      _wrongCount = 0;
      _isFinished = false;
      _hasSubmitted = false;
      _isCorrect = false;
      _answerController.clear();
    });
    _loadWords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escucha y escribe'),
        actions: [
          if (!_isFinished && _words.isNotEmpty)
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
              : _buildListeningExercise(),
    );
  }

  Widget _buildListeningExercise() {
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

          // Instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.hearing,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Escucha la palabra y escribela',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Play buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isPlaying ? null : _playWord,
                      icon: Icon(_isPlaying ? Icons.volume_up : Icons.volume_up_outlined),
                      label: const Text('Escuchar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _isPlaying ? null : _playWordSlow,
                      icon: const Icon(Icons.slow_motion_video),
                      label: const Text('Lento'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Answer input
          TextField(
            controller: _answerController,
            focusNode: _focusNode,
            enabled: !_hasSubmitted,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Escribe la palabra...',
              hintStyle: TextStyle(color: AppTheme.textSecondary.withAlpha(100)),
              filled: true,
              fillColor: AppTheme.surfaceColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
            ),
            onSubmitted: (_) {
              if (!_hasSubmitted && _answerController.text.isNotEmpty) {
                _submitAnswer();
              }
            },
          ),

          const SizedBox(height: 24),

          // Feedback
          if (_hasSubmitted) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isCorrect
                    ? AppTheme.successColor.withAlpha(30)
                    : AppTheme.errorColor.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isCorrect ? AppTheme.successColor : AppTheme.errorColor,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isCorrect ? Icons.check_circle : Icons.cancel,
                        color: _isCorrect ? AppTheme.successColor : AppTheme.errorColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isCorrect ? 'Correcto!' : 'Incorrecto',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _isCorrect ? AppTheme.successColor : AppTheme.errorColor,
                        ),
                      ),
                    ],
                  ),
                  if (!_isCorrect) ...[
                    const SizedBox(height: 12),
                    Text(
                      'La respuesta correcta es:',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      word.word,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    'Traduccion: ${word.translation}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const Spacer(),

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _hasSubmitted
                  ? _nextWord
                  : (_answerController.text.isNotEmpty ? _submitAnswer : null),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                _hasSubmitted
                    ? (_currentIndex < _words.length - 1 ? 'Siguiente' : 'Ver resultados')
                    : 'Comprobar',
              ),
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
