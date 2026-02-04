import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../config/theme.dart';
import '../../models/glossary_word.dart';
import '../../providers/glossary_provider.dart';
import '../../services/tts_service.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  final TtsService _ttsService = TtsService();
  final Random _random = Random();
  late List<GlossaryWord> _words;
  late List<GlossaryWord> _allWords;
  int _currentIndex = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  bool _isFinished = false;
  String? _selectedAnswer;
  bool _hasAnswered = false;
  late List<String> _currentOptions;

  @override
  void initState() {
    super.initState();
    _loadWords();
  }

  void _loadWords() {
    final provider = context.read<GlossaryProvider>();
    _allWords = provider.words;
    _words = provider.getWordsForPractice(limit: 10);
    _words.shuffle(_random);
    if (_words.isNotEmpty) {
      _generateOptions();
    }
  }

  void _generateOptions() {
    final correctWord = _words[_currentIndex];
    final options = <String>[correctWord.translation];

    // Get random wrong answers from other words
    final otherWords = _allWords.where((w) => w.id != correctWord.id).toList();
    otherWords.shuffle(_random);

    for (var i = 0; i < 3 && i < otherWords.length; i++) {
      options.add(otherWords[i].translation);
    }

    // If we don't have enough words, add some placeholder translations
    while (options.length < 4) {
      options.add('Opcion ${options.length + 1}');
    }

    options.shuffle(_random);
    _currentOptions = options;
  }

  void _selectAnswer(String answer) {
    if (_hasAnswered) return;

    final correctAnswer = _words[_currentIndex].translation;
    final isCorrect = answer == correctAnswer;

    setState(() {
      _selectedAnswer = answer;
      _hasAnswered = true;
      if (isCorrect) {
        _correctCount++;
        context.read<GlossaryProvider>().recordCorrectAnswer(_words[_currentIndex].id);
      } else {
        _wrongCount++;
        context.read<GlossaryProvider>().recordWrongAnswer(_words[_currentIndex].id);
      }
    });
  }

  void _nextQuestion() {
    if (_currentIndex < _words.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
        _hasAnswered = false;
      });
      _generateOptions();
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
      _selectedAnswer = null;
      _hasAnswered = false;
    });
    _loadWords();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz'),
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
          ? const Center(child: Text('No hay suficientes palabras para el quiz'))
          : _isFinished
              ? _buildResultsScreen()
              : _buildQuizQuestion(),
    );
  }

  Widget _buildQuizQuestion() {
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

          // Question card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text(
                  'Cual es la traduccion de:',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  word.word,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                IconButton(
                  onPressed: () => _ttsService.speak(word.word),
                  icon: const Icon(Icons.volume_up),
                  color: AppTheme.primaryColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Options
          Expanded(
            child: ListView.separated(
              itemCount: _currentOptions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final option = _currentOptions[index];
                return _buildOptionButton(option, word.translation);
              },
            ),
          ),

          // Next button
          if (_hasAnswered)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _nextQuestion,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _currentIndex < _words.length - 1 ? 'Siguiente' : 'Ver resultados',
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOptionButton(String option, String correctAnswer) {
    final isSelected = _selectedAnswer == option;
    final isCorrect = option == correctAnswer;
    final showCorrect = _hasAnswered && isCorrect;
    final showWrong = _hasAnswered && isSelected && !isCorrect;

    Color backgroundColor = AppTheme.surfaceColor;
    Color borderColor = AppTheme.textSecondary.withAlpha(50);
    Color textColor = AppTheme.textPrimary;

    if (showCorrect) {
      backgroundColor = AppTheme.successColor.withAlpha(30);
      borderColor = AppTheme.successColor;
      textColor = AppTheme.successColor;
    } else if (showWrong) {
      backgroundColor = AppTheme.errorColor.withAlpha(30);
      borderColor = AppTheme.errorColor;
      textColor = AppTheme.errorColor;
    } else if (isSelected) {
      borderColor = AppTheme.primaryColor;
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _hasAnswered ? null : () => _selectAnswer(option),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  option,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor,
                    fontWeight: isSelected || showCorrect ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
              if (showCorrect)
                const Icon(Icons.check_circle, color: AppTheme.successColor)
              else if (showWrong)
                const Icon(Icons.cancel, color: AppTheme.errorColor),
            ],
          ),
        ),
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
