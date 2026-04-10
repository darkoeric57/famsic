import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../theme/app_theme.dart';
import '../providers/audio_providers.dart';
import '../providers/settings_provider.dart';
import '../core/famsic_audio_handler.dart';
import '../core/music_service.dart';
import 'settings_screen.dart';

class LibraryScreen extends ConsumerWidget {
  const LibraryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final songListAsync = ref.watch(songListProvider);
    final handler = ref.watch(audioHandlerProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, ref),

          // Current Scan Filter Info
          _buildScanFilterInfo(context, ref),
          // Favorites Summary Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: _buildRedesignedFavoritesCard(context, ref),
            ),
          ),

          // Folders Quick Access
          SliverToBoxAdapter(
            child: _buildSectionHeader(context, "Folders", "MANAGE"),
          ),
          SliverToBoxAdapter(
            child: _buildFolderHorizontalList(context, ref),
          ),

          // Filters / Categories
          SliverToBoxAdapter(
            child: _buildFilterChips(context, ref),
          ),

          // Playlists Section
          SliverToBoxAdapter(
            child: _buildSectionHeader(context, "Playlists", "VIEW ALL"),
          ),
          SliverToBoxAdapter(
            child: _buildHorizontalList(context),
          ),

          // Recently Added (Tracklist)
          SliverToBoxAdapter(
            child: _buildSectionHeader(context, "Recently Added", ""),
          ),

          songListAsync.when(
            data: (songs) {
              final currentSongAsync = ref.watch(currentSongProvider);
              final currentSongId = currentSongAsync.value?.id;

              if (songs.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.library_music_outlined,
                            size: 80,
                            color: AppTheme.secondaryGrey.withValues(alpha: 0.5)),
                        const SizedBox(height: 20),
                        Text(
                          "No music found on this device",
                          style: GoogleFonts.outfit(
                              fontSize: 18, color: AppTheme.secondaryGrey),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "Ensure you have music files and permission is granted.",
                          style: TextStyle(
                              color: AppTheme.secondaryGrey, fontSize: 13),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 30),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(songListProvider),
                          icon: const Icon(Icons.refresh),
                          label: const Text("RESCAN STORAGE"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentNeon,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final song = songs[index];
                    final isCurrent = song.uri == currentSongId;
                    return _buildTrackItem(
                        context, song, handler, index, songs, isCurrent);
                  },
                  childCount: songs.length,
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.accentNeon),
                    SizedBox(height: 20),
                    Text("Scanning storage for music...",
                        style: TextStyle(color: AppTheme.secondaryGrey)),
                  ],
                ),
              ),
            ),
            error: (err, stack) => SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text("Failed to load music",
                          style: GoogleFonts.outfit(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(err.toString(),
                          style:
                              const TextStyle(color: Colors.red, fontSize: 12),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => ref.invalidate(songListProvider),
                        icon: const Icon(Icons.refresh),
                        label: const Text("RETRY"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accentNeon,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, WidgetRef ref) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 80,
      backgroundColor: AppTheme.creamBackground,
      title: Text(
        "Library",
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.create_new_folder_outlined,
              color: AppTheme.deepDark),
          tooltip: "Select Scan Folder",
          onPressed: () async {
            try {
              String? selectedDirectory =
                  await FilePicker.getDirectoryPath();

              if (selectedDirectory != null && context.mounted) {
                // Stabilization delay: give Android time to fully close the
                // FilePicker native activity before we touch any other channel.
                await Future.delayed(const Duration(milliseconds: 2500));

                if (context.mounted) {
                  await ref
                      .read(settingsProvider.notifier)
                      .updateScanPath(selectedDirectory);
                  if (context.mounted) {
                    ref.invalidate(songListProvider);
                  }
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to select folder: $e')),
                );
              }
            }
          },
        ),
        IconButton(
          icon:
              const Icon(Icons.settings_outlined, color: AppTheme.deepDark),
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (c) => const SettingsScreen())),
        ),
      ],
    );
  }

  Widget _buildScanFilterInfo(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    if (settings.scanPath == null) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.accentNeon.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
                color: AppTheme.accentNeon.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.folder_open,
                  color: AppTheme.accentNeon, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Scanning specific folder:",
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.deepDark.withValues(alpha: 0.6)),
                    ),
                    Text(
                      settings.scanPath!.split('/').last,
                      style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.deepDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close,
                    size: 18, color: AppTheme.secondaryGrey),
                onPressed: () async {
                  await ref
                      .read(settingsProvider.notifier)
                      .clearScanPath();
                  await Future.delayed(const Duration(milliseconds: 500));
                  ref.invalidate(songListProvider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRedesignedFavoritesCard(BuildContext context, WidgetRef ref) {
    final songListAsync = ref.watch(songListProvider);
    return songListAsync.when(
      data: (songs) {
        // Just as a placeholder for premium look: take first few track arts
        // In a real app we'd filter for isFavorite == true
        return Container(
          height: 180,
          decoration: BoxDecoration(
            color: AppTheme.deepDark,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: AppTheme.accentNeon.withValues(alpha: 0.15),
                blurRadius: 25,
                spreadRadius: 2,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // Background Mosaic Vignette
              Positioned.fill(
                child: Opacity(
                  opacity: 0.25,
                  child: Wrap(
                    spacing: 0,
                    runSpacing: 0,
                    children: List.generate(4, (i) {
                      return Container(
                        width: 170, // Rough estimate for mosaic tiles
                        height: 90,
                        color: i % 2 == 0 ? Colors.grey[800] : Colors.grey[900],
                        child: const Icon(Icons.music_note, color: Colors.white10, size: 40),
                      );
                    }),
                  ),
                ),
              ),
              // Gradient Overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.deepDark.withValues(alpha: 0.95),
                        AppTheme.deepDark.withValues(alpha: 0.4),
                        Colors.transparent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                  ),
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accentNeon.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "PREMIUM COLLECTION",
                            style: GoogleFonts.outfit(
                              color: AppTheme.accentNeon,
                              fontSize: 9,
                              letterSpacing: 1.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "Favorites",
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "${songs.length} Tracks • 8.4 GB",
                          style: GoogleFonts.outfit(
                            color: AppTheme.secondaryGrey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.play_arrow_rounded, size: 20),
                      label: const Text("SHUFFLE ALL"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentNeon,
                        foregroundColor: Colors.white,
                        elevation: 8,
                        shadowColor: AppTheme.accentNeon.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(height: 180),
      error: (_, __) => Container(height: 180),
    );
  }

  Widget _buildFolderHorizontalList(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final folderName = settings.scanPath?.split('/').last ?? "Internal Storage";

    return SizedBox(
      height: 70,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: 2,
        itemBuilder: (context, index) {
          final isSelected = index == 0; // Just for UI demo
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.accentNeon.withValues(alpha: 0.1) : Colors.white,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: isSelected ? AppTheme.accentNeon : AppTheme.secondaryGrey.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  index == 0 ? Icons.folder : Icons.folder_shared_outlined,
                  size: 18,
                  color: isSelected ? AppTheme.accentNeon : AppTheme.deepDark,
                ),
                const SizedBox(width: 10),
                Text(
                  index == 0 ? folderName : "Downloads",
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppTheme.accentNeon : AppTheme.deepDark,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, WidgetRef ref) {
    final filters = ["ARTISTS", "ALBUMS", "GENRES", "YEAR"];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 40,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 15),
          itemCount: filters.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: Text(
                  filters[index],
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                backgroundColor: Colors.white,
                side: BorderSide(color: AppTheme.secondaryGrey.withValues(alpha: 0.1)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
      BuildContext context, String title, String action) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          if (action.isNotEmpty)
            Text(
              action,
              style: const TextStyle(
                  color: AppTheme.accentNeon,
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
            ),
        ],
      ),
    );
  }

  Widget _buildHorizontalList(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        itemCount: 5,
        itemBuilder: (context, index) {
          return Container(
            width: 120,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppTheme.deepDark,
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: AppTheme.accentNeon, width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child:
                      const Icon(Icons.music_note, color: Colors.white),
                ),
                const SizedBox(height: 10),
                const Text("Daily Mix",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrackItem(
    BuildContext context,
    NativeSongModel song,
    FamsicAudioHandler handler,
    int index,
    List<NativeSongModel> allSongs,
    bool isCurrent,
  ) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isCurrent
              ? AppTheme.accentNeon.withValues(alpha: 0.1)
              : AppTheme.deepDark.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: isCurrent
              ? Border.all(color: AppTheme.accentNeon.withValues(alpha: 0.3))
              : null,
        ),
        child: Icon(
          isCurrent ? Icons.pause : Icons.music_note,
          color: isCurrent ? AppTheme.accentNeon : AppTheme.deepDark,
          size: 20,
        ),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            song.title,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
              fontSize: 15,
              color: isCurrent ? AppTheme.accentNeon : AppTheme.deepDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (isCurrent) ...[
            const SizedBox(height: 6),
            const ActiveTrackProgressBar(),
            const SizedBox(height: 4),
          ],
        ],
      ),
      subtitle: Text(
        song.artist,
        style: const TextStyle(
            color: AppTheme.secondaryGrey, fontSize: 12),
      ),
      trailing: Text(
        _formatDuration(Duration(milliseconds: song.duration)),
        style: const TextStyle(
            color: AppTheme.secondaryGrey, fontSize: 12),
      ),
      onTap: () async {
        // All songs already have valid URIs (filtered in MusicService)
        final mediaItems = allSongs
            .map((s) => MediaItem(
                  id: s.uri,
                  title: s.title,
                  artist: s.artist,
                  album: s.album,
                  duration: Duration(milliseconds: s.duration),
                  extras: {'id': s.id, 'albumId': s.albumId},
                ))
            .toList();

        await handler.updateQueue(mediaItems);
        await handler.skipToQueueItem(index);
      },
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    return "${twoDigits(duration.inMinutes.remainder(60))}:${twoDigits(duration.inSeconds.remainder(60))}";
  }
}

class ActiveTrackProgressBar extends ConsumerWidget {
  const ActiveTrackProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positionAsync = ref.watch(positionProvider);
    final durationAsync = ref.watch(durationProvider);

    final position = positionAsync.value ?? Duration.zero;
    final duration = durationAsync.value ?? Duration.zero;

    double progress = 0.0;
    if (duration.inMilliseconds > 0) {
      progress = (position.inMilliseconds / duration.inMilliseconds)
          .clamp(0.0, 1.0);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Background track
            Container(
              height: 3,
              width: constraints.maxWidth,
              decoration: BoxDecoration(
                color: AppTheme.accentNeon.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Progress filling with Glow
            Container(
              height: 3,
              width: constraints.maxWidth * progress,
              decoration: BoxDecoration(
                color: AppTheme.accentNeon,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentNeon.withValues(alpha: 0.6),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
