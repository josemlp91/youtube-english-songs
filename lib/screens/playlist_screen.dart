import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/song.dart';
import '../providers/playlist_provider.dart';
import '../providers/player_provider.dart';
import '../services/youtube_service.dart';
import '../widgets/empty_state.dart';

class PlaylistScreen extends StatefulWidget {
  final VoidCallback? onNavigateToPlayer;

  const PlaylistScreen({super.key, this.onNavigateToPlayer});

  @override
  State<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends State<PlaylistScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Song> _filterSongs(List<Song> songs) {
    if (_searchQuery.isEmpty) return songs;
    final query = _searchQuery.toLowerCase();
    return songs.where((song) {
      return song.title.toLowerCase().contains(query) ||
          song.artist.toLowerCase().contains(query);
    }).toList();
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
                  hintText: 'Buscar canciones...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: AppTheme.textSecondary),
                ),
                style: const TextStyle(color: AppTheme.textPrimary),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text('Mi Playlist'),
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
        ],
      ),
      body: Consumer<PlaylistProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
                  const SizedBox(height: 16),
                  Text(provider.error!, style: const TextStyle(color: AppTheme.errorColor)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      provider.clearError();
                      provider.loadSongs();
                    },
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (provider.isEmpty) {
            return EmptyState(
              icon: Icons.queue_music,
              title: 'Tu playlist esta vacia',
              description: 'Agrega canciones de YouTube para empezar a aprender ingles con musica',
              actionLabel: 'Agregar cancion',
              onAction: () => _showAddSongDialog(context),
            );
          }

          final filteredSongs = _filterSongs(provider.songs);

          if (filteredSongs.isEmpty && _searchQuery.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  Text(
                    'No se encontraron canciones para "$_searchQuery"',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: filteredSongs.length,
            itemBuilder: (context, index) {
              final song = filteredSongs[index];
              return _SongCard(
                key: ValueKey(song.id),
                song: song,
                onTap: () => _playSong(context, song),
                onDelete: () => _confirmDelete(context, provider, song),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSongDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
      ),
    );
  }

  void _playSong(BuildContext context, Song song) {
    final playerProvider = context.read<PlayerProvider>();
    playerProvider.setCurrentSong(song);

    // Navegar al reproductor
    if (widget.onNavigateToPlayer != null) {
      widget.onNavigateToPlayer!();
    }
  }

  void _confirmDelete(BuildContext context, PlaylistProvider provider, Song song) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar cancion'),
        content: Text('¿Estas seguro de eliminar "${song.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            onPressed: () {
              provider.removeSong(song.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${song.title} eliminada')),
              );
            },
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showAddSongDialog(BuildContext context) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isLoading = false;
    String? errorMessage;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Agregar cancion'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: controller,
                  decoration: const InputDecoration(
                    hintText: 'https://youtube.com/watch?v=...',
                    prefixIcon: Icon(Icons.link),
                    labelText: 'URL de YouTube',
                  ),
                  autofocus: true,
                  enabled: !isLoading,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa una URL o ID de video';
                    }
                    if (!YouTubeService().isValidYoutubeUrl(value)) {
                      return 'URL o ID de YouTube no valido';
                    }
                    return null;
                  },
                ),
                if (errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    errorMessage!,
                    style: const TextStyle(color: AppTheme.errorColor, fontSize: 12),
                  ),
                ],
                if (isLoading) ...[
                  const SizedBox(height: 16),
                  const Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Obteniendo informacion del video...'),
                    ],
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;

                      setDialogState(() {
                        isLoading = true;
                        errorMessage = null;
                      });

                      try {
                        final youtubeService = YouTubeService();
                        final song = await youtubeService.getVideoMetadata(controller.text.trim());

                        if (song == null) {
                          setDialogState(() {
                            isLoading = false;
                            errorMessage = 'No se pudo obtener la informacion del video';
                          });
                          return;
                        }

                        if (context.mounted) {
                          final provider = context.read<PlaylistProvider>();

                          // Verificar si ya existe por youtubeId
                          if (provider.hasSongWithYoutubeId(song.youtubeId)) {
                            setDialogState(() {
                              isLoading = false;
                              errorMessage = 'Esta cancion ya esta en tu playlist';
                            });
                            return;
                          }

                          await provider.addSong(song);

                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('${song.title} agregada a la playlist'),
                                backgroundColor: AppTheme.successColor,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        setDialogState(() {
                          isLoading = false;
                          errorMessage = 'Error: $e';
                        });
                      }
                    },
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SongCard extends StatelessWidget {
  final Song song;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SongCard({
    super.key,
    required this.song,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  song.thumbnailUrl,
                  width: 100,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 100,
                    height: 70,
                    color: AppTheme.surfaceColor,
                    child: const Icon(Icons.music_note, size: 32),
                  ),
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(
                      width: 100,
                      height: 70,
                      color: AppTheme.surfaceColor,
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.play_circle_filled, color: AppTheme.primaryColor),
                    iconSize: 36,
                    onPressed: onTap,
                    tooltip: 'Reproducir',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: onDelete,
                    tooltip: 'Eliminar',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
