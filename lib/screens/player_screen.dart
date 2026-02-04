import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../config/theme.dart';
import '../config/constants.dart';
import '../models/song.dart';
import '../providers/player_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/interactive_subtitles.dart';
import '../services/tts_service.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  YoutubePlayerController? _controller;
  String? _currentVideoId;
  bool _isReady = false;
  StreamSubscription<void>? _ttsSubscription;

  // Loop A-B
  double? _loopStartSeconds;
  double? _loopEndSeconds;
  bool _isLoopActive = false;
  Timer? _loopCheckTimer;

  @override
  void dispose() {
    _controller?.close();
    _loopCheckTimer?.cancel();
    _ttsSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _ttsSubscription = TtsService().beforeSpeakStream.listen((_) {
      _pauseVideoIfPlaying();
    });
  }

  void _initController(String videoId) {
    if (_currentVideoId == videoId && _controller != null) return;

    _loopCheckTimer?.cancel();
    _currentVideoId = videoId;
    _isReady = false;
    _clearLoop();

    if (_controller != null) {
      _controller!.loadVideoById(videoId: videoId);
      setState(() {
        _isReady = true;
      });
      return;
    }

    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: true,
      params: const YoutubePlayerParams(
        showControls: false,
        showFullscreenButton: false,
        enableCaption: true,
        captionLanguage: 'en',
        playsInline: true,
        strictRelatedVideos: true,
      ),
    );

    _controller!.setFullScreenListener((isFullScreen) {});

    _controller!.listen((event) {
      if (!mounted) return;

      final playerProvider = context.read<PlayerProvider>();

      if (event.playerState == PlayerState.playing) {
        playerProvider.setPlaying(true);
        _startLoopCheck();
      } else if (event.playerState == PlayerState.paused ||
          event.playerState == PlayerState.ended) {
        playerProvider.setPlaying(false);
      }
    });

    setState(() {
      _isReady = true;
    });
  }

  void _startLoopCheck() {
    _loopCheckTimer?.cancel();
    if (!_isLoopActive || _loopStartSeconds == null || _loopEndSeconds == null) return;

    _loopCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      if (!mounted || !_isLoopActive) {
        _loopCheckTimer?.cancel();
        return;
      }

      final currentTime = await _controller?.currentTime ?? 0;
      if (currentTime >= _loopEndSeconds!) {
        _controller?.seekTo(seconds: _loopStartSeconds!, allowSeekAhead: true);
      }
    });
  }

  void _setLoopStart() async {
    final currentTime = await _controller?.currentTime ?? 0;
    setState(() {
      _loopStartSeconds = currentTime;
      if (_loopEndSeconds != null && _loopEndSeconds! <= currentTime) {
        _loopEndSeconds = null;
        _isLoopActive = false;
      }
    });
  }

  void _setLoopEnd() async {
    final currentTime = await _controller?.currentTime ?? 0;
    if (_loopStartSeconds != null && currentTime > _loopStartSeconds!) {
      setState(() {
        _loopEndSeconds = currentTime;
        _isLoopActive = true;
      });
      _startLoopCheck();
    }
  }

  void _clearLoop() {
    _loopCheckTimer?.cancel();
    setState(() {
      _loopStartSeconds = null;
      _loopEndSeconds = null;
      _isLoopActive = false;
    });
  }

  void _toggleLoop() {
    if (_loopStartSeconds != null && _loopEndSeconds != null) {
      setState(() {
        _isLoopActive = !_isLoopActive;
      });
      if (_isLoopActive) {
        _startLoopCheck();
      } else {
        _loopCheckTimer?.cancel();
      }
    }
  }

  Future<void> _skipBackward() async {
    final currentPos = await _controller?.currentTime ?? 0;
    _controller?.seekTo(
      seconds: (currentPos - AppConstants.defaultSkipSeconds).clamp(0, double.infinity),
      allowSeekAhead: true,
    );
  }

  Future<void> _skipForward() async {
    final currentPos = await _controller?.currentTime ?? 0;
    final duration = _controller?.metadata.duration.inSeconds ?? 0;
    _controller?.seekTo(
      seconds: (currentPos + AppConstants.defaultSkipSeconds).clamp(0, duration.toDouble()),
      allowSeekAhead: true,
    );
  }

  void _togglePlayPause() async {
    final state = await _controller?.playerState;
    if (state == PlayerState.playing) {
      _controller?.pauseVideo();
    } else {
      _controller?.playVideo();
    }
  }

  void _pauseVideoIfPlaying() async {
    final state = await _controller?.playerState;
    if (state == PlayerState.playing) {
      _controller?.pauseVideo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Consumer<PlayerProvider>(
        builder: (context, playerProvider, child) {
          final song = playerProvider.currentSong;

          if (song == null) {
            return const EmptyState(
              icon: Icons.play_circle_outline,
              title: 'Ninguna cancion seleccionada',
              description: 'Selecciona una cancion de tu playlist para empezar a aprender',
            );
          }

          if (_currentVideoId != song.youtubeId) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initController(song.youtubeId);
            });
          }

          return _buildPlayerContent(context, song, playerProvider);
        },
      ),
    );
  }

  Widget _buildPlayerContent(
    BuildContext context,
    Song song,
    PlayerProvider playerProvider,
  ) {
    final isDesktop = MediaQuery.of(context).size.width > 900;

    if (isDesktop) {
      return _buildDesktopLayout(context, song, playerProvider);
    }
    return _buildMobileLayout(context, song, playerProvider);
  }

  Widget _buildMobileLayout(
    BuildContext context,
    Song song,
    PlayerProvider playerProvider,
  ) {
    return Column(
      children: [
        _buildVideoPlayer(),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSongInfo(song),
                const SizedBox(height: 24),
                _buildProgressBar(playerProvider),
                const SizedBox(height: 16),
                _buildPlaybackControls(playerProvider),
                const SizedBox(height: 24),
                _buildLoopControls(),
                const SizedBox(height: 24),
                _buildSpeedControls(playerProvider),
                const SizedBox(height: 24),
                InteractiveSubtitles(
                  currentSong: song,
                  currentPosition: playerProvider.currentPosition,
                  onBeforeSpeak: _pauseVideoIfPlaying,
                ),
                SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    Song song,
    PlayerProvider playerProvider,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Column(
                    children: [
                      _buildVideoPlayer(),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: _buildProgressBar(playerProvider),
                      ),
                      const SizedBox(height: 16),
                      _buildPlaybackControls(playerProvider),
                      const SizedBox(height: 16),
                      _buildLoopControls(),
                      SizedBox(height: 16 + MediaQuery.of(context).padding.bottom),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          flex: 2,
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.surfaceColor,
              border: Border(
                left: BorderSide(color: AppTheme.backgroundColor, width: 1),
              ),
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSongInfo(song),
                  const SizedBox(height: 32),
                  _buildSpeedControls(playerProvider),
                  const SizedBox(height: 32),
                  InteractiveSubtitles(
                    currentSong: song,
                    currentPosition: playerProvider.currentPosition,
                    onBeforeSpeak: _pauseVideoIfPlaying,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVideoPlayer() {
    if (_controller == null || !_isReady) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          ),
        ),
      );
    }

    return YoutubePlayer(
      controller: _controller!,
      aspectRatio: 16 / 9,
    );
  }

  Widget _buildSongInfo(Song song) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          song.title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.person, size: 16, color: AppTheme.textSecondary),
            const SizedBox(width: 4),
            Text(
              song.artist,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar(PlayerProvider playerProvider) {
    return StreamBuilder<YoutubeVideoState>(
      stream: _controller?.videoStateStream,
      builder: (context, snapshot) {
        final position = snapshot.data?.position ?? Duration.zero;
        final duration = _controller?.metadata.duration ?? Duration.zero;

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            playerProvider.setCurrentPosition(position);
            if (duration > Duration.zero) {
              playerProvider.setTotalDuration(duration);
            }
          }
        });

        final maxMs = duration.inMilliseconds.toDouble().clamp(1.0, double.infinity);
        final valueMs = position.inMilliseconds
            .toDouble()
            .clamp(0.0, maxMs)
            .toDouble();

        return Column(
          children: [
            // Loop indicator
            if (_loopStartSeconds != null || _loopEndSeconds != null)
              _buildLoopIndicator(duration),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: AppTheme.primaryColor,
                inactiveTrackColor: AppTheme.surfaceColor,
                thumbColor: AppTheme.primaryColor,
                overlayColor: AppTheme.primaryColor.withAlpha(32),
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: valueMs,
                min: 0,
                max: maxMs,
                onChanged: (value) {
                  _controller?.seekTo(
                    seconds: value / 1000,
                    allowSeekAhead: true,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(position),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _formatDuration(duration),
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoopIndicator(Duration totalDuration) {
    if (totalDuration.inMilliseconds == 0) return const SizedBox.shrink();

    final totalMs = totalDuration.inMilliseconds.toDouble();
    final startPercent = _loopStartSeconds != null
        ? (_loopStartSeconds! * 1000 / totalMs).clamp(0.0, 1.0)
        : 0.0;
    final endPercent = _loopEndSeconds != null
        ? (_loopEndSeconds! * 1000 / totalMs).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      height: 8,
      margin: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              // Background
              Container(
                decoration: BoxDecoration(
                  color: AppTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              // Loop region
              if (_loopStartSeconds != null)
                Positioned(
                  left: constraints.maxWidth * startPercent,
                  width: constraints.maxWidth * (endPercent - startPercent),
                  top: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _isLoopActive
                          ? AppTheme.accentColor.withAlpha(150)
                          : AppTheme.accentColor.withAlpha(80),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlaybackControls(PlayerProvider playerProvider) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.replay_10),
          iconSize: 32,
          color: AppTheme.textPrimary,
          onPressed: _skipBackward,
          tooltip: 'Retroceder ${AppConstants.defaultSkipSeconds}s (←)',
        ),
        const SizedBox(width: 16),
        StreamBuilder<PlayerState>(
          stream: _controller?.stream.map((state) => state.playerState),
          builder: (context, snapshot) {
            final isPlaying = snapshot.data == PlayerState.playing;

            return Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(50),
              ),
              child: IconButton(
                icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                iconSize: 48,
                color: Colors.white,
                onPressed: _togglePlayPause,
                tooltip: isPlaying ? 'Pausar (Espacio)' : 'Reproducir (Espacio)',
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        IconButton(
          icon: const Icon(Icons.forward_10),
          iconSize: 32,
          color: AppTheme.textPrimary,
          onPressed: _skipForward,
          tooltip: 'Avanzar ${AppConstants.defaultSkipSeconds}s (→)',
        ),
      ],
    );
  }

  Widget _buildLoopControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.repeat,
                color: _isLoopActive ? AppTheme.accentColor : AppTheme.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Repetir seccion (A-B)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _isLoopActive ? AppTheme.accentColor : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Botón A (inicio)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _setLoopStart,
                  icon: const Icon(Icons.start, size: 18),
                  label: Text(
                    _loopStartSeconds != null
                        ? 'A: ${_formatSeconds(_loopStartSeconds!)}'
                        : 'Marcar A',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _loopStartSeconds != null
                        ? AppTheme.accentColor
                        : AppTheme.textSecondary,
                    side: BorderSide(
                      color: _loopStartSeconds != null
                          ? AppTheme.accentColor
                          : AppTheme.textSecondary.withAlpha(100),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Botón B (fin)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _loopStartSeconds != null ? _setLoopEnd : null,
                  icon: const Icon(Icons.stop, size: 18),
                  label: Text(
                    _loopEndSeconds != null
                        ? 'B: ${_formatSeconds(_loopEndSeconds!)}'
                        : 'Marcar B',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _loopEndSeconds != null
                        ? AppTheme.accentColor
                        : AppTheme.textSecondary,
                    side: BorderSide(
                      color: _loopEndSeconds != null
                          ? AppTheme.accentColor
                          : AppTheme.textSecondary.withAlpha(100),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // Toggle loop
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: (_loopStartSeconds != null && _loopEndSeconds != null)
                      ? _toggleLoop
                      : null,
                  icon: Icon(_isLoopActive ? Icons.pause : Icons.repeat),
                  label: Text(_isLoopActive ? 'Detener loop' : 'Iniciar loop'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoopActive
                        ? AppTheme.accentColor
                        : AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Clear
              IconButton(
                onPressed: (_loopStartSeconds != null || _loopEndSeconds != null)
                    ? _clearLoop
                    : null,
                icon: const Icon(Icons.clear),
                tooltip: 'Limpiar marcadores (C)',
                color: AppTheme.errorColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpeedControls(PlayerProvider playerProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Velocidad de reproduccion',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AppConstants.playbackRates.map((rate) {
            final isSelected = playerProvider.playbackRate == rate;
            return ChoiceChip(
              label: Text('${rate}x'),
              selected: isSelected,
              onSelected: (_) {
                playerProvider.setPlaybackRate(rate);
                _controller?.setPlaybackRate(rate);
              },
              selectedColor: AppTheme.primaryColor,
              backgroundColor: AppTheme.surfaceColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }



  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _formatSeconds(double seconds) {
    final mins = (seconds / 60).floor();
    final secs = (seconds % 60).floor();
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }
}
