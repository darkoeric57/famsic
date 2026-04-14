import 'dart:math' as math;
import 'dart:async';
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
import 'package:permission_handler/permission_handler.dart';
import '../widgets/visualizer_styles.dart';
import '../providers/settings_provider.dart';
import '../widgets/hybrid_media_bar.dart';
import '../providers/collections_provider.dart';
import '../widgets/collection_card.dart';
import '../widgets/collection_creator_sheet.dart';
import '../models/local_collection.dart';


class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    // RECORD_AUDIO is required for the native visualizer to work
    await Permission.microphone.request();
  }

  @override
  Widget build(BuildContext context) {
    final songListAsync = ref.watch(filteredSongsProvider);
    final totalSongsAsync = ref.watch(songListProvider);
    final handler = ref.watch(audioHandlerProvider);
    final playbackState = ref.watch(playbackStateProvider).value;
    final isPlaying = playbackState?.playing ?? false;

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // 2. Recent Plays Section (Carousel) - Now at the Top
            _buildRecentPlaysSection(context, ref, totalSongsAsync),

            // 3. Local Collections List (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    _buildLocalCollections(context, ref, totalSongsAsync),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      // Persistent Mini Player 
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 24),
        child: const Row(
          children: [
            PlaybackControls(isMini: true),
            Expanded(child: HybridMediaBar()),
          ],
        ),
      ),
    );
  }


  Widget _buildRecentPlaysSection(BuildContext context, WidgetRef ref, AsyncValue<List<NativeSongModel>> totalSongsAsync) {
    final activePlaylist = ref.watch(activePlaylistProvider);
    final currentMediaItem = ref.watch(currentSongProvider).value;
    final handler = ref.watch(audioHandlerProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context, 
          activePlaylist.isEmpty ? "FANTASY COLLECTION" : "ACTIVE COLLECTION", 
          "HIGH-FIDELITY ACTIVE SOURCES",
          titleStyle: GoogleFonts.audiowide(
            fontSize: 16,
            color: AppTheme.neonCyan,
            letterSpacing: 2.5,
            shadows: [
              const BoxShadow(color: Color(0xFF00FFCC), blurRadius: 12, spreadRadius: 1),
              BoxShadow(color: AppTheme.neonCyan.withValues(alpha: 0.5), blurRadius: 4),
            ],
          ),
        ),
        SizedBox(
          height: 180, // Optimized height for better vertical density
          child: activePlaylist.isNotEmpty 
            ? RecentlyPlayedCarousel(
                songs: activePlaylist,
                currentMediaItem: currentMediaItem,
                handler: handler,
                cardBuilder: (context, song, {scale = 1.0, isActive = false, showButton = false}) {
                  return _buildRecentPlayCard(context, song, scale: scale, isActive: isActive, showButton: showButton);
                },
              )
            : totalSongsAsync.when(
                data: (songs) {
                  if (songs.isEmpty) return const SizedBox();
                  final recentSongs = songs.length > 10 ? songs.sublist(0, 10) : songs;
                  return RecentlyPlayedCarousel(
                    songs: recentSongs,
                    currentMediaItem: currentMediaItem,
                    handler: handler,
                    cardBuilder: (context, song, {scale = 1.0, isActive = false, showButton = false}) {
                      return _buildRecentPlayCard(context, song, scale: scale, isActive: isActive, showButton: showButton);
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox(),
              ),
        ),
      ],
    );
  }

  Widget _buildRecentPlayCard(
    BuildContext context, 
    NativeSongModel song, {
    double scale = 1.0, 
    bool isActive = false,
    bool showButton = false,
  }) {
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
          child: Consumer(
            builder: (context, ref, _) {
              final currentMediaItem = ref.watch(currentSongProvider).value;
              final playbackState = ref.watch(playbackStateProvider).value;
              final isActuallyPlaying = currentMediaItem?.id == song.uri;
              final isPaused = isActuallyPlaying && !(playbackState?.playing ?? false);
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final artworkAsync = ref.watch(artworkProvider(song.uri));
                        
                        return Container(
                          decoration: const BoxDecoration(
                            color: AppTheme.surfaceLight,
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
                                        opacity: AlwaysStoppedAnimation(0.2),
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
                                  opacity: AlwaysStoppedAnimation(0.5),
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
                              // Auto-hiding Play/Pause Button
                              if (isActive) ...[
                                Center(
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 300),
                                    opacity: showButton ? 1.0 : 0.0,
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme.neonCyan,
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.neonCyan.withValues(alpha: 0.4),
                                            blurRadius: 12,
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        isActuallyPlaying && !isPaused ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                        color: Colors.white,
                                        size: 40
                                      ),
                                    ),
                                  ),
                                ),
                                // Integrated Dynamic Visualizer with smart dimming
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 300),
                                    opacity: showButton ? 0.3 : 1.0,
                                    child: DynamicVisualizer(
                                      isPlaying: isActuallyPlaying && !isPaused,
                                      height: 60,
                                      opacity: showButton ? 0.3 : 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.5),
                    ),
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold, 
                            fontSize: 14,
                            color: AppTheme.deepDark,
                          ),
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
                        // Real-time progress line
                        if (isActuallyPlaying)
                          const CarouselProgressLine()
                        else
                          Container(
                            height: 3,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: AppTheme.secondaryGrey.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: 0.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.secondaryGrey,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }
          ),
        ),
      ),
    );
  }

  Widget _buildLocalCollections(BuildContext context, WidgetRef ref, AsyncValue<List<NativeSongModel>> totalSongsAsync) {
    final collectionsAsync = ref.watch(collectionsProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          context, 
          "LOCAL COLLECTIONS", 
          "ADD",
          onAction: () => _showCreateCollectionSheet(context),
          titleStyle: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppTheme.secondaryGrey,
            letterSpacing: 2.0,
          ),
        ),
        
        // Dynamic Persisted Collections Only
        collectionsAsync.when(
          data: (collections) {
            if (collections.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Text(
                  "NO COLLECTIONS CREATED YET. TAP 'ADD' TO BEGIN.",
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.secondaryGrey.withOpacity(0.5),
                    letterSpacing: 1.2,
                  ),
                ),
              );
            }
            return Column(
              children: collections.map((c) => CollectionCard(collection: c)).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox(),
        ),
      ],
    );
  }

  void _showCreateCollectionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const CollectionCreatorSheet(),
    );
  }

  Widget _buildCollectionItem(BuildContext context, String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: AppTheme.neumorphicDecoration(borderRadius: 16),
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
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, 
                    fontSize: 16,
                    color: AppTheme.deepDark,
                  ),
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
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.play_arrow_rounded, color: color, size: 20),
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
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              overflow: TextOverflow.ellipsis,
              style: titleStyle ?? GoogleFonts.outfit(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: AppTheme.deepDark,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (action.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 12),
              child: GestureDetector(
                onTap: onAction,
                child: Text(
                  action,
                  style: GoogleFonts.outfit(
                    color: AppTheme.neonCyan, 
                    fontWeight: FontWeight.w900, 
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
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
              color: AppTheme.surfaceLight,
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


class RecentlyPlayedCarousel extends ConsumerStatefulWidget {
  final List<NativeSongModel> songs;
  final MediaItem? currentMediaItem;
  final FamsicAudioHandler handler;
  final Widget Function(BuildContext, NativeSongModel, {double scale, bool isActive, bool showButton}) cardBuilder;

  const RecentlyPlayedCarousel({
    super.key, 
    required this.songs,
    required this.currentMediaItem,
    required this.handler,
    required this.cardBuilder,
  });

  @override
  ConsumerState<RecentlyPlayedCarousel> createState() => _RecentlyPlayedCarouselState();
}

class _RecentlyPlayedCarouselState extends ConsumerState<RecentlyPlayedCarousel> {
  late PageController _pageController;
  double _currentPage = 0.0;
  bool _isUserScrolling = false;
  bool _showPlayButton = false;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();
    final initialIndex = _calculateInitialIndex();
    _currentPage = initialIndex.toDouble();
    _pageController = PageController(viewportFraction: 0.7, initialPage: initialIndex)
      ..addListener(() {
        if (mounted) {
          setState(() {
            _currentPage = _pageController.page ?? 0.0;
          });
        }
      });
  }

  int _calculateInitialIndex() {
    if (widget.currentMediaItem == null) return 0;
    final index = widget.songs.indexWhere((s) => s.uri == widget.currentMediaItem!.id);
    return index != -1 ? index : 0;
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showPlayButton = false);
      }
    });
  }

  void _onCardTap(int index, bool isActive) {
    if (!isActive) {
      // If user taps a non-active card, maybe we want to scroll to it?
      // For now, only focus on active card interaction as requested.
      _pageController.animateToPage(index, duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
      return;
    }

    if (!_showPlayButton) {
      setState(() => _showPlayButton = true);
      _startHideTimer();
    } else {
      // Toggle play/pause
      _togglePlayback(index);
      _startHideTimer(); // Reset timer upon interaction
    }
  }

  void _togglePlayback(int index) async {
    final playbackState = ref.read(playbackStateProvider).value;
    final currentMediaItem = ref.read(currentSongProvider).value;
    final targetSong = widget.songs[index];

    // If no song is loaded or the current song isn't from this carousel's context, force sync the queue
    if (currentMediaItem == null || !widget.handler.queue.value.any((item) => item.id == targetSong.uri)) {
      final mediaItems = widget.songs.map((s) => MediaItem(
        id: s.uri,
        title: s.title,
        artist: s.artist,
        album: s.album,
        duration: Duration(milliseconds: s.duration),
        extras: {'id': s.id, 'albumId': s.albumId},
      )).toList();
      
      await widget.handler.updateQueue(mediaItems);
      await widget.handler.skipToQueueItem(index);
    } else if (currentMediaItem.id == targetSong.uri) {
      if (playbackState?.playing ?? false) {
        widget.handler.pause();
      } else {
        widget.handler.play();
      }
    } else {
      // Song is in queue but not active, skip to it
      await widget.handler.skipToQueueItem(index);
    }
  }

  @override
  void didUpdateWidget(RecentlyPlayedCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentMediaItem?.id != oldWidget.currentMediaItem?.id && !_isUserScrolling) {
      final newIndex = widget.songs.indexWhere((s) => s.uri == widget.currentMediaItem?.id);
      if (newIndex != -1 && newIndex != _currentPage.round()) {
        _pageController.animateToPage(
          newIndex, 
          duration: const Duration(milliseconds: 500), 
          curve: Curves.easeOutCubic
        );
      }
    }
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (notification is ScrollStartNotification) {
          _isUserScrolling = true;
          // Hide button when user starts scrolling to avoid floating button during swipe
          if (_showPlayButton) setState(() => _showPlayButton = false);
        }
        if (notification is ScrollEndNotification) _isUserScrolling = false;
        return false;
      },
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.songs.length,
        onPageChanged: (index) {
          final song = widget.songs[index];
          if (widget.currentMediaItem?.id != song.uri) {
            widget.handler.skipToQueueItem(index);
            widget.handler.play();
          }
          // Ensure button is hidden on new page
          setState(() => _showPlayButton = false);
        },
        itemBuilder: (context, index) {
          final song = widget.songs[index];
          final relativePosition = index - _currentPage;
          final scale = (1 - (relativePosition.abs() * 0.15)).clamp(0.8, 1.0);
          final isActive = relativePosition.abs() < 0.5;

          return GestureDetector(
            onTap: () => _onCardTap(index, isActive),
            child: widget.cardBuilder(
              context, 
              song, 
              scale: scale, 
              isActive: isActive,
              showButton: _showPlayButton
            ),
          );
        },
      ),
    );
  }
}

class CarouselProgressLine extends ConsumerWidget {
  const CarouselProgressLine({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final duration = ref.watch(durationProvider).value ?? Duration.zero;
    final progress = duration.inMilliseconds > 0 
        ? position.inMilliseconds / duration.inMilliseconds 
        : 0.0;

    return Container(
      height: 3,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.secondaryGrey.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.neonCyan,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(
                color: AppTheme.neonCyan.withOpacity(0.4),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
