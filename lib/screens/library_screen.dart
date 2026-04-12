import 'dart:math' as math;
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../providers/audio_providers.dart';
import '../providers/library_filter_provider.dart';
import '../core/famsic_audio_handler.dart';
import '../core/native_song_model.dart';
import '../widgets/playback_controls.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool _visualizerEnabled = true;

  @override
  Widget build(BuildContext context) {
    final songListAsync = ref.watch(filteredSongsProvider);
    final totalSongsAsync = ref.watch(songListProvider);
    final handler = ref.watch(audioHandlerProvider);
    final playbackState = ref.watch(playbackStateProvider).value;
    final isPlaying = playbackState?.playing ?? false;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Visualizer Header
            _buildVisualizerHeader(context, ref, isPlaying && _visualizerEnabled),

            // 2. Recent Plays Section (Carousel)
            _buildRecentPlaysSection(context, ref, totalSongsAsync),

            // 3. Local Collections List (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: _buildLocalCollections(context, ref, totalSongsAsync),
              ),
            ),
          ],
        ),
      ),
      // Persistent Mini Player 
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.only(bottom: 24, top: 12),
        child: const PlaybackControls(isMini: true),
      ),
    );
  }

  Widget _buildVisualizerHeader(BuildContext context, WidgetRef ref, bool isPlaying) {
    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Acoustic Visualizer",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.deepDark,
                      ),
                    ),
                    Text(
                      "Now Playing",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppTheme.secondaryGrey,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                // Neon ON Switch Decoration
                GestureDetector(
                  onTap: () => setState(() => _visualizerEnabled = !_visualizerEnabled),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _visualizerEnabled 
                          ? AppTheme.neonCyan.withValues(alpha: 0.1)
                          : AppTheme.secondaryGrey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        if (_visualizerEnabled)
                          BoxShadow(
                            color: AppTheme.neonCyan.withValues(alpha: 0.2),
                            blurRadius: 15,
                            spreadRadius: 2,
                          ),
                      ],
                      border: Border.all(
                        color: _visualizerEnabled 
                            ? AppTheme.neonCyan.withValues(alpha: 0.3)
                            : AppTheme.secondaryGrey.withValues(alpha: 0.3)
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _visualizerEnabled ? "ON" : "OFF",
                          style: GoogleFonts.outfit(
                            color: _visualizerEnabled ? AppTheme.neonCyan : AppTheme.secondaryGrey,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(width: 8),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _visualizerEnabled ? AppTheme.neonCyan : Colors.transparent,
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 80,
            child: AcousticVisualizer(isPlaying: isPlaying),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPlaysSection(BuildContext context, WidgetRef ref, AsyncValue<List<NativeSongModel>> totalSongsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context, 
          "RECENTLY PLAYING", 
          "",
          titleStyle: GoogleFonts.monoton(
            fontSize: 15,
            color: AppTheme.neonCyan,
            letterSpacing: 2,
          ),
        ),
        SizedBox(
          height: 185,
          child: totalSongsAsync.when(
            data: (songs) {
              if (songs.isEmpty) return const SizedBox();
              // For "Recent Plays", we could also use a different sorting or just shuffled for demo
              return RecentlyPlayedCarousel(
                songs: songs.length > 10 ? songs.sublist(0, 10) : songs,
                cardBuilder: _buildRecentPlayCard,
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const SizedBox(),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentPlayCard(BuildContext context, NativeSongModel song, {double scale = 1.0, bool isActive = false}) {
    return Transform.scale(
      scale: scale,
      child: Container(
        width: 160,
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: AppTheme.glowDecoration(
          color: isActive ? AppTheme.neonCyan : AppTheme.neonPurple,
          opacity: isActive ? 0.3 : 0.05,
          borderRadius: BorderRadius.circular(20),
          blurRadius: isActive ? 15 : 8,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Consumer(
                  builder: (context, ref, _) {
                    final artworkAsync = ref.watch(artworkProvider(song.uri));
                    
                    return Container(
                      decoration: BoxDecoration(
                        color: AppTheme.deepDark,
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          artworkAsync.when(
                            data: (bytes) => bytes != null 
                                ? Image.memory(bytes, fit: BoxFit.cover)
                                : const Image(
                                    image: AssetImage('assets/images/placeholder.png'),
                                    fit: BoxFit.cover,
                                    opacity: const AlwaysStoppedAnimation(0.5),
                                  ),
                            loading: () => const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white24),
                              ),
                            ),
                            error: (_, __) => const Image(
                              image: AssetImage('assets/images/placeholder.png'),
                              fit: BoxFit.cover,
                              opacity: const AlwaysStoppedAnimation(0.5),
                            ),
                          ),
                          // Overlay Gradient for Depth
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.4),
                                ],
                              ),
                            ),
                          ),
                          Center(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                boxShadow: isActive ? [
                                  BoxShadow(color: AppTheme.neonCyan.withValues(alpha: 0.5), blurRadius: 20)
                                ] : [],
                              ),
                              child: Icon(
                                isActive ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 40
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),
              ),
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      song.title,
                      style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      song.artist,
                      style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.secondaryGrey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Mini progress line
                    Container(
                      height: 3,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppTheme.creamBackground,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: isActive ? 0.6 : 0.3,
                        child: Container(
                          decoration: BoxDecoration(
                            color: isActive ? AppTheme.neonCyan : AppTheme.secondaryGrey,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocalCollections(BuildContext context, WidgetRef ref, AsyncValue<List<NativeSongModel>> totalSongsAsync) {
    final count = totalSongsAsync.value?.length ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(context, "Local Collections", "", fontSize: 16),
        _buildCollectionItem(
          context, 
          "Favorite Tracks", 
          "$count tracks", 
          Icons.favorite_rounded, 
          AppTheme.accentNeon
        ),
        _buildCollectionItem(
          context, 
          "High-Res Selection", 
          "Premium Audio", 
          Icons.auto_awesome_rounded, 
          AppTheme.neonCyan
        ),
        _buildCollectionItem(
          context, 
          "Personal Mixtapes", 
          "AI Generated", 
          Icons.graphic_eq_rounded, 
          AppTheme.neonPurple
        ),
        _buildCollectionItem(
          context, 
          "Recent Downloads", 
          "Last 24 hours", 
          Icons.download_for_offline_rounded, 
          AppTheme.accentNeon
        ),
        _buildCollectionItem(
          context, 
          "Classic Archives", 
          "Legacy Quality", 
          Icons.album_rounded, 
          AppTheme.secondaryGrey
        ),
      ],
    );
  }

  Widget _buildCollectionItem(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.secondaryGrey),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.creamBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.play_arrow_rounded, color: AppTheme.secondaryGrey, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, 
    String title, 
    String action, {
    VoidCallback? onAction, 
    double fontSize = 20,
    TextStyle? titleStyle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: titleStyle ?? GoogleFonts.outfit(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: AppTheme.deepDark,
            ),
          ),
          if (action.isNotEmpty)
            TextButton(
              onPressed: onAction,
              child: Text(
                action,
                style: GoogleFonts.outfit(color: AppTheme.neonCyan, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTrackItem(BuildContext context, NativeSongModel song, FamsicAudioHandler handler, int index, List<NativeSongModel> allSongs) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Consumer(
        builder: (context, ref, _) {
          final artworkAsync = ref.watch(artworkProvider(song.uri));
          return Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.creamBackground,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: artworkAsync.when(
                data: (bytes) => bytes != null 
                    ? Image.memory(bytes, fit: BoxFit.cover)
                    : const Icon(Icons.music_note, color: AppTheme.secondaryGrey),
                loading: () => const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const Icon(Icons.music_note, color: AppTheme.secondaryGrey),
              ),
            ),
          );
        }
      ),
      title: Text(
        song.title,
        style: GoogleFonts.outfit(fontWeight: FontWeight.w600, fontSize: 15),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artist,
        style: GoogleFonts.outfit(fontSize: 12, color: AppTheme.secondaryGrey),
      ),
      trailing: const Icon(Icons.more_vert, color: AppTheme.secondaryGrey),
      onTap: () async {
        final mediaItems = allSongs.map((s) => MediaItem(
          id: s.uri,
          title: s.title,
          artist: s.artist,
          album: s.album,
          duration: Duration(milliseconds: s.duration),
          extras: {'id': s.id, 'albumId': s.albumId},
        )).toList();

        await handler.updateQueue(mediaItems);
        await handler.skipToQueueItem(index);
      },
    );
  }
}

// ── Supporting High-Fidelity Widgets ──────────────────────────────────────────

class AcousticVisualizer extends StatefulWidget {
  final bool isPlaying;
  const AcousticVisualizer({super.key, required this.isPlaying});

  @override
  State<AcousticVisualizer> createState() => _AcousticVisualizerState();
}

class _AcousticVisualizerState extends State<AcousticVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _barHeights = List.generate(40, (i) => 4.0);
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    )..addListener(() {
      if (widget.isPlaying) {
        setState(() {
          for (int i = 0; i < _barHeights.length; i++) {
            _barHeights[i] = 10 + _random.nextDouble() * 50;
          }
        });
      }
    });

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(AcousticVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
        setState(() {
          for (int i = 0; i < _barHeights.length; i++) {
            _barHeights[i] = 4.0;
          }
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_barHeights.length, (i) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: 4,
          height: _barHeights[i],
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.neonCyan,
                AppTheme.neonCyan.withValues(alpha: 0.5),
                AppTheme.neonPurple,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              if (widget.isPlaying)
                BoxShadow(
                  color: AppTheme.neonCyan.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
            ],
          ),
        );
      }),
    );
  }
}

class RecentlyPlayedCarousel extends StatefulWidget {
  final List<NativeSongModel> songs;
  final Widget Function(BuildContext, NativeSongModel, {double scale, bool isActive}) cardBuilder;

  const RecentlyPlayedCarousel({
    super.key, 
    required this.songs,
    required this.cardBuilder,
  });

  @override
  State<RecentlyPlayedCarousel> createState() => _RecentlyPlayedCarouselState();
}

class _RecentlyPlayedCarouselState extends State<RecentlyPlayedCarousel> {
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.7)
      ..addListener(() {
        setState(() {
          _currentPage = _pageController.page ?? 0.0;
        });
      });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.songs.length,
      itemBuilder: (context, index) {
        final song = widget.songs[index];
        final relativePosition = index - _currentPage;
        final scale = (1 - (relativePosition.abs() * 0.15)).clamp(0.8, 1.0);
        final isActive = relativePosition.abs() < 0.5;

        return widget.cardBuilder(
          context, 
          song, 
          scale: scale, 
          isActive: isActive
        );
      },
    );
  }
}
