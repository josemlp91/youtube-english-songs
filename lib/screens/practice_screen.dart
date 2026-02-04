import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/glossary_provider.dart';
import '../config/theme.dart';
import 'practice/flashcard_screen.dart';
import 'practice/listening_screen.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Repaso'),
      ),
      body: Consumer<GlossaryProvider>(
        builder: (context, provider, child) {
          if (provider.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 80,
                    color: AppTheme.textSecondary.withAlpha(128),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No hay palabras para repasar',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agrega palabras al glosario para poder practicar',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final stats = provider.getPracticeStats();
          final dueWords = stats['dueWords'] as int;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Stats card
                _buildStatsCard(context, stats),
                const SizedBox(height: 24),

                // Due words indicator
                if (dueWords > 0) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primaryColor.withAlpha(80)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_active, color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$dueWords palabra${dueWords != 1 ? 's' : ''} pendiente${dueWords != 1 ? 's' : ''} de repaso',
                            style: const TextStyle(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Section title
                const Text(
                  'Modos de practica',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Practice modes
                _buildPracticeModeCard(
                  context,
                  icon: Icons.style,
                  title: 'Flashcards',
                  description: 'Repasa las palabras con tarjetas',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const FlashcardScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                _buildPracticeModeCard(
                  context,
                  icon: Icons.hearing,
                  title: 'Escucha y escribe',
                  description: 'Practica la comprension auditiva',
                  color: Colors.teal,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ListeningScreen()),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsCard(BuildContext context, Map<String, dynamic> stats) {
    final totalWords = stats['totalWords'] as int;
    final totalReviews = stats['totalReviews'] as int;
    final accuracy = stats['accuracy'] as double;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withAlpha(200),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tu progreso',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.library_books,
                  value: '$totalWords',
                  label: 'Palabras',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.refresh,
                  value: '$totalReviews',
                  label: 'Repasos',
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.trending_up,
                  value: '${accuracy.round()}%',
                  label: 'Precision',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withAlpha(200), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withAlpha(180),
          ),
        ),
      ],
    );
  }

  Widget _buildPracticeModeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
