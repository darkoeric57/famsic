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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _buildFavoritesCard(context),
            ),
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
                    return _buildTrackItem(
                        context, song, handler, index, songs);
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

  Widget _buildFavoritesCard(BuildContext context) {
    return Container(
      height: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(Icons.favorite,
                color: AppTheme.accentNeon.withValues(alpha: 0.6),
                size: 150),
          ),
          Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Favorites",
                      style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "128 Tracks",
                      style: TextStyle(color: AppTheme.secondaryGrey),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                  ),
                  child: const Text("Play All",
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
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
  ) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 25, vertical: 5),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.deepDark.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child:
            const Icon(Icons.music_note, color: AppTheme.deepDark, size: 20),
      ),
      title: Text(
        song.title,
        style:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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
