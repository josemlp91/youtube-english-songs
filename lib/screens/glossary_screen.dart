import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/glossary_word.dart';
import '../providers/glossary_provider.dart';
import '../services/tts_service.dart';
import '../widgets/empty_state.dart';

enum SortOption { dateDesc, dateAsc, alphabetical, timesReviewed }

class GlossaryScreen extends StatefulWidget {
  const GlossaryScreen({super.key});

  @override
  State<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends State<GlossaryScreen> {
  final TtsService _ttsService = TtsService();
  final TextEditingController _searchController = TextEditingController();

  bool _isSearching = false;
  String _searchQuery = '';
  SortOption _sortOption = SortOption.dateDesc;
  String? _filterBySongId;
  EntryType? _filterByType;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<GlossaryWord> _filterAndSortWords(List<GlossaryWord> words) {
    var filtered = words.toList();

    // Filtrar por búsqueda
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((w) =>
          w.word.toLowerCase().contains(query) ||
          w.translation.toLowerCase().contains(query)).toList();
    }

    // Filtrar por canción
    if (_filterBySongId != null) {
      filtered = filtered.where((w) => w.songId == _filterBySongId).toList();
    }

    // Filtrar por tipo
    if (_filterByType != null) {
      filtered = filtered.where((w) => w.entryType == _filterByType).toList();
    }

    // Ordenar
    switch (_sortOption) {
      case SortOption.dateDesc:
        filtered.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case SortOption.dateAsc:
        filtered.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
        break;
      case SortOption.alphabetical:
        filtered.sort((a, b) => a.word.toLowerCase().compareTo(b.word.toLowerCase()));
        break;
      case SortOption.timesReviewed:
        filtered.sort((a, b) => b.timesReviewed.compareTo(a.timesReviewed));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Buscar palabras...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                ),
                style: const TextStyle(color: AppTheme.textPrimary),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : const Text('Glosario'),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  _searchQuery = '';
                }
              });
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'sort',
                child: ListTile(
                  leading: Icon(Icons.sort),
                  title: Text('Ordenar'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'filterByType',
                child: ListTile(
                  leading: Icon(Icons.category),
                  title: Text('Filtrar por tipo'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'filterBySong',
                child: ListTile(
                  leading: Icon(Icons.music_note),
                  title: Text('Filtrar por cancion'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (_filterBySongId != null || _filterByType != null)
                const PopupMenuItem(
                  value: 'clearFilter',
                  child: ListTile(
                    leading: Icon(Icons.clear),
                    title: Text('Quitar filtros'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              const PopupMenuItem(
                value: 'addEntry',
                child: ListTile(
                  leading: Icon(Icons.add),
                  title: Text('Agregar entrada'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<GlossaryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.isEmpty) {
            return const EmptyState(
              icon: Icons.book_outlined,
              title: 'Tu glosario esta vacio',
              description: 'Las palabras que agregues desde el reproductor apareceran aqui',
            );
          }

          final filteredWords = _filterAndSortWords(provider.words);

          if (filteredWords.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty
                        ? 'No se encontraron palabras para "$_searchQuery"'
                        : 'No hay palabras con este filtro',
                    style: const TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Stats bar
              _buildStatsBar(provider, filteredWords.length),

              // Word list
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredWords.length,
                  itemBuilder: (context, index) {
                    final word = filteredWords[index];
                    return _WordCard(
                      word: word,
                      onPlay: () => _playWord(word.word),
                      onPlaySlow: () => _playWordSlow(word.word),
                      onEdit: () => _showEditDialog(context, word),
                      onDelete: () => _confirmDelete(context, provider, word),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsBar(GlossaryProvider provider, int filteredCount) {
    final hasFilter = _filterBySongId != null || _filterByType != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: AppTheme.surfaceColor,
      child: Row(
        children: [
          const Icon(Icons.library_books, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 8),
          Text(
            '$filteredCount entrada${filteredCount != 1 ? 's' : ''}',
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          if (hasFilter) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_filterByType != null) ...[
                    Text(_filterByType!.emoji, style: const TextStyle(fontSize: 12)),
                    const SizedBox(width: 4),
                  ] else ...[
                    const Icon(Icons.filter_alt, size: 12, color: AppTheme.primaryColor),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    _filterByType?.displayName ?? 'Filtrado',
                    style: const TextStyle(fontSize: 11, color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
          ],
          const Spacer(),
          // Sort indicator
          TextButton.icon(
            onPressed: () => _showSortDialog(),
            icon: const Icon(Icons.sort, size: 16),
            label: Text(_getSortLabel()),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        ],
      ),
    );
  }

  String _getSortLabel() {
    return switch (_sortOption) {
      SortOption.dateDesc => 'Recientes',
      SortOption.dateAsc => 'Antiguas',
      SortOption.alphabetical => 'A-Z',
      SortOption.timesReviewed => 'Mas repasadas',
    };
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'sort':
        _showSortDialog();
        break;
      case 'filterByType':
        _showFilterByTypeDialog();
        break;
      case 'filterBySong':
        _showFilterDialog();
        break;
      case 'clearFilter':
        setState(() {
          _filterBySongId = null;
          _filterByType = null;
        });
        break;
      case 'addEntry':
        _showAddEntryDialog(context);
        break;
    }
  }

  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ordenar por'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSortOption(SortOption.dateDesc, 'Mas recientes primero'),
            _buildSortOption(SortOption.dateAsc, 'Mas antiguas primero'),
            _buildSortOption(SortOption.alphabetical, 'Alfabeticamente (A-Z)'),
            _buildSortOption(SortOption.timesReviewed, 'Mas repasadas'),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(SortOption option, String label) {
    final isSelected = _sortOption == option;
    return ListTile(
      title: Text(label),
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
      ),
      selected: isSelected,
      onTap: () {
        setState(() => _sortOption = option);
        Navigator.pop(context);
      },
    );
  }

  void _showFilterByTypeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar por tipo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: EntryType.values.map((type) {
            final isSelected = _filterByType == type;
            return ListTile(
              leading: Text(type.emoji, style: const TextStyle(fontSize: 20)),
              title: Text(type.displayName),
              trailing: isSelected
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              selected: isSelected,
              onTap: () {
                setState(() => _filterByType = type);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          if (_filterByType != null)
            TextButton(
              onPressed: () {
                setState(() => _filterByType = null);
                Navigator.pop(context);
              },
              child: const Text('Quitar filtro'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    final glossaryProvider = context.read<GlossaryProvider>();

    // Obtener canciones únicas que tienen palabras en el glosario
    final songsWithWords = <String, String>{};
    for (final word in glossaryProvider.words) {
      if (word.songId != null && word.songTitle != null) {
        songsWithWords[word.songId!] = word.songTitle!;
      }
    }

    if (songsWithWords.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay palabras asociadas a canciones')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar por cancion'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: songsWithWords.entries.map((entry) {
              final wordCount = glossaryProvider.words
                  .where((w) => w.songId == entry.key)
                  .length;
              return ListTile(
                leading: const Icon(Icons.music_note),
                title: Text(
                  entry.value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('$wordCount palabra${wordCount != 1 ? 's' : ''}'),
                selected: _filterBySongId == entry.key,
                onTap: () {
                  setState(() => _filterBySongId = entry.key);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _playWord(String word) async {
    await _ttsService.speak(word);
  }

  void _playWordSlow(String word) async {
    await _ttsService.speakSlowly(word);
  }


  void _showEditDialog(BuildContext context, GlossaryWord word) {
    final translationController = TextEditingController(text: word.translation);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar "${word.word}"'),
        content: TextField(
          controller: translationController,
          decoration: const InputDecoration(
            labelText: 'Traduccion',
            hintText: 'Ingresa la traduccion correcta',
          ),
          autofocus: true,
          maxLines: 2,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTranslation = translationController.text.trim();
              if (newTranslation.isNotEmpty && newTranslation != word.translation) {
                final updatedWord = word.copyWith(translation: newTranslation);
                context.read<GlossaryProvider>().updateWord(updatedWord);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Traduccion actualizada'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              }
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, GlossaryProvider provider, GlossaryWord word) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar palabra'),
        content: Text('¿Eliminar "${word.word}" del glosario?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.errorColor),
            onPressed: () {
              provider.removeWord(word.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('"${word.word}" eliminada')),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showAddEntryDialog(BuildContext context) {
    final wordController = TextEditingController();
    final translationController = TextEditingController();
    final exampleController = TextEditingController();
    EntryType selectedType = EntryType.word;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar al glosario'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Entry type selector
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
                  children: EntryType.values.map((type) {
                    final isSelected = selectedType == type;
                    return ChoiceChip(
                      label: Text('${type.emoji} ${type.displayName}'),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setDialogState(() => selectedType = type);
                        }
                      },
                      selectedColor: AppTheme.primaryColor.withAlpha(50),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Word/phrase input
                TextField(
                  controller: wordController,
                  decoration: InputDecoration(
                    labelText: selectedType == EntryType.word
                        ? 'Palabra'
                        : selectedType == EntryType.phrasalVerb
                            ? 'Phrasal verb'
                            : 'Frase/Expresion',
                    hintText: selectedType == EntryType.phrasalVerb
                        ? 'ej: give up, look after'
                        : selectedType == EntryType.idiom
                            ? 'ej: break a leg'
                            : null,
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),

                // Translation input
                TextField(
                  controller: translationController,
                  decoration: const InputDecoration(
                    labelText: 'Traduccion',
                    hintText: 'Significado en espanol',
                  ),
                  maxLines: 2,
                ),

                // Example sentence (for phrases)
                if (selectedType != EntryType.word) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: exampleController,
                    decoration: const InputDecoration(
                      labelText: 'Ejemplo de uso (opcional)',
                      hintText: 'Frase de ejemplo en ingles',
                    ),
                    maxLines: 2,
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final word = wordController.text.trim();
                final translation = translationController.text.trim();

                if (word.isEmpty || translation.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Completa todos los campos requeridos'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                  return;
                }

                final entry = GlossaryWord(
                  word: word,
                  translation: translation,
                  entryType: selectedType,
                  example: exampleController.text.trim().isEmpty
                      ? null
                      : exampleController.text.trim(),
                );

                context.read<GlossaryProvider>().addWord(entry);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('"$word" agregada al glosario'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WordCard extends StatelessWidget {
  final GlossaryWord word;
  final VoidCallback onPlay;
  final VoidCallback onPlaySlow;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _WordCard({
    required this.word,
    required this.onPlay,
    required this.onPlaySlow,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Word and actions row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Entry type badge
                      if (word.entryType != EntryType.word)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getTypeColor(word.entryType).withAlpha(30),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${word.entryType.emoji} ${word.entryType.displayName}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: _getTypeColor(word.entryType),
                              ),
                            ),
                          ),
                        ),
                      Text(
                        word.word,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        word.translation,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      // Example sentence
                      if (word.example != null && word.example!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.backgroundColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.format_quote, size: 14, color: AppTheme.textSecondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  word.example!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontStyle: FontStyle.italic,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Actions
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: onPlay,
                      tooltip: 'Escuchar',
                      color: AppTheme.textSecondary,
                    ),
                    IconButton(
                      icon: const Icon(Icons.slow_motion_video),
                      onPressed: onPlaySlow,
                      tooltip: 'Escuchar lento',
                      color: AppTheme.textSecondary,
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: AppTheme.textSecondary),
                      onSelected: (value) {
                        if (value == 'edit') onEdit();
                        if (value == 'delete') onDelete();
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 8),
                              Text('Editar traduccion'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 20, color: AppTheme.errorColor),
                              SizedBox(width: 8),
                              Text('Eliminar', style: TextStyle(color: AppTheme.errorColor)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),

            // Metadata row
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (word.songTitle != null)
                  _MetadataChip(
                    icon: Icons.music_note,
                    label: word.songTitle!,
                  ),
                if (word.timesReviewed > 0)
                  _MetadataChip(
                    icon: Icons.refresh,
                    label: '${word.timesReviewed}x repasada',
                  ),
                _MetadataChip(
                  icon: Icons.calendar_today,
                  label: _formatDate(word.dateAdded),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getTypeColor(EntryType type) {
    switch (type) {
      case EntryType.word:
        return AppTheme.textSecondary;
      case EntryType.expression:
        return Colors.blue;
      case EntryType.idiom:
        return Colors.orange;
      case EntryType.phrasalVerb:
        return Colors.purple;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) return 'Hoy';
    if (diff.inDays == 1) return 'Ayer';
    if (diff.inDays < 7) return 'Hace ${diff.inDays} dias';
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _MetadataChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetadataChip({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.textSecondary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
