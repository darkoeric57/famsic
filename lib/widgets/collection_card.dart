import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:audio_service/audio_service.dart';
import '../models/local_collection.dart';
import '../theme/app_theme.dart';
import '../providers/audio_providers.dart';
import '../providers/collections_provider.dart';

class CollectionCard extends ConsumerWidget {
  final LocalCollection collection;

  const CollectionCard({super.key, required this.collection});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSong = ref.watch(currentSongProvider).value;
    final playbackState = ref.watch(playbackStateProvider).value;
    final handler = ref.watch(audioHandlerProvider);
    
    // Check if any song in this collection is currently playing
    final isPlayingThisCollection = _isCurrentlyPlaying(collection, currentSong);
    final isActuallyPlaying = isPlayingThisCollection && (playbackState?.playing ?? false);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: AppTheme.neumorphicDecoration(
        borderRadius: 24,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isPlayingThisCollection ? AppTheme.neonCyan : AppTheme.secondaryGrey).withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: (isPlayingThisCollection ? AppTheme.neonCyan : AppTheme.secondaryGrey).withOpacity(0.2),
            ),
          ),
          child: Icon(
            _getIconData(collection.iconKey),
            color: isPlayingThisCollection ? AppTheme.neonCyan : AppTheme.deepDark.withOpacity(0.6),
            size: 24,
          ),
        ),
        title: Text(
          collection.title.toUpperCase(),
          style: GoogleFonts.outfit(
            color: AppTheme.deepDark,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          '${collection.trackUris.length} TRACKS',
          style: GoogleFonts.outfit(
            color: AppTheme.secondaryGrey,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(LucideIcons.trash2, size: 18, color: Colors.red.withOpacity(0.4)),
              onPressed: () => _showDeleteConfirmation(context, ref),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _handlePlayToggle(ref, collection, isPlayingThisCollection, isActuallyPlaying),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActuallyPlaying ? AppTheme.neonCyan : Colors.black.withOpacity(0.05),
                  boxShadow: isActuallyPlaying ? [
                    BoxShadow(color: AppTheme.neonCyan.withOpacity(0.4), blurRadius: 10)
                  ] : [],
                ),
                child: Icon(
                  isActuallyPlaying ? LucideIcons.pause : LucideIcons.play,
                  color: isActuallyPlaying ? AppTheme.deepDark : AppTheme.neonCyan,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.creamBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          'DELETE COLLECTION?',
          style: GoogleFonts.monoton(fontSize: 18, color: AppTheme.deepDark),
        ),
        content: Text(
          'This will remove "${collection.title.toUpperCase()}" from your local soundscapes.',
          style: GoogleFonts.outfit(color: AppTheme.secondaryGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.secondaryGrey)),
          ),
          TextButton(
            onPressed: () {
              ref.read(collectionsProvider.notifier).removeCollection(collection.id);
              Navigator.pop(context);
            },
            child: Text('DELETE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red)),
          ),
        ],
      ),
    );
  }

  bool _isCurrentlyPlaying(LocalCollection collection, MediaItem? currentSong) {
    if (currentSong == null) return false;
    return collection.trackUris.contains(currentSong.id);
  }

  IconData _getIconData(String key) {
    switch (key.toLowerCase()) {
      case 'heart': return LucideIcons.heart;
      case 'star': return LucideIcons.star;
      case 'flame': return LucideIcons.flame;
      case 'coffee': return LucideIcons.coffee;
      case 'music': return LucideIcons.music;
      case 'dumbbell': return LucideIcons.dumbbell;
      case 'moon': return LucideIcons.moon;
      case 'sun': return LucideIcons.sun;
      case 'zap': return LucideIcons.zap;
      case 'headphones': return LucideIcons.headphones;
      default: return LucideIcons.music;
    }
  }

  void _handlePlayToggle(WidgetRef ref, LocalCollection collection, bool isThisCollection, bool isPlaying) async {
    final handler = ref.read(audioHandlerProvider);
    
    if (isThisCollection) {
      if (isPlaying) {
        await handler.pause();
      } else {
        await handler.play();
      }
    } else {
      // Load collection into queue and play
      final allSongs = ref.read(songListProvider).value ?? [];
      final collectionSongs = allSongs.where((s) => collection.trackUris.contains(s.uri)).toList();
      
      if (collectionSongs.isEmpty) return;

      // SYNC: Update the top flipping carousel with this collection's songs
      ref.read(activePlaylistProvider.notifier).setPlaylist(collectionSongs);

      final mediaItems = collectionSongs.map((s) => s.toMediaItem()).toList();
      await handler.updateQueue(mediaItems);
      await handler.skipToQueueItem(0);
      await handler.play();
    }
  }
}
