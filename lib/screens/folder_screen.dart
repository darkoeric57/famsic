import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../providers/audio_providers.dart';
import '../providers/settings_provider.dart';
import '../providers/navigation_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/horizontal_progress.dart';
import '../core/music_service.dart';
import '../core/famsic_audio_handler.dart';
import '../core/native_song_model.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/visualizer_styles.dart';

class FolderScreen extends ConsumerStatefulWidget {
  const FolderScreen({super.key});

  @override
  ConsumerState<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends ConsumerState<FolderScreen> with SingleTickerProviderStateMixin {
  bool _fxEnabled = true;
  late AnimationController _syncController;
  String? _expandedPath;

  @override
  void initState() {
    super.initState();
    _syncController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _syncController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final folders = ref.watch(foldersProvider);

    return Scaffold(
      backgroundColor: AppTheme.creamBackground,
      body: Stack(
        children: [
          // 1. Central Glowing Aura Background
          _buildAuraBackground(),

          // 2. Background Acoustic Visualizer (Subtle Wave)
          if (_fxEnabled) _buildBackgroundVisualizer(),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                   const SizedBox(height: 10),
                  // Header Title
                  Text(
                    'Local Folders',
                    style: GoogleFonts.monoton(
                      fontSize: 34,
                      color: Colors.black.withOpacity(0.8),
                      letterSpacing: 1.2,
                    ),
                  ),
                  
                  const SizedBox(height: 10),
                  
                  Row(
                    children: [
                      Text(
                        'AUDIO UTILITY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.black.withOpacity(0.4),
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: _buildActionButtons(context, ref),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  _buildActiveFolderTags(ref),
                  
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Folders List
                Expanded(
                  child: folders.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: folders.length,
                          itemBuilder: (context, index) {
                            final folder = folders[index];
                            final isExpanded = _expandedPath == folder['path'];
                            return _buildDismissibleFolder(folder, index, ref, isExpanded);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDismissibleFolder(Map<String, dynamic> folder, int index, WidgetRef ref, bool isExpanded) {
    return Dismissible(
      key: Key('folder_${folder['path']}'),
      direction: isExpanded ? DismissDirection.none : DismissDirection.endToStart,
      onDismissed: (direction) {
        final path = folder['path'] as String;
        // 1. Optimistically remove from UI for smooth sliding animation
        ref.read(foldersProvider.notifier).removeFolderOptimistically(path);
        
        // 2. Persist to hidden paths. This will trigger FoldersNotifier to rebuild 
        // and filter this path out permanently, even during provider refreshes.
        ref.read(settingsProvider.notifier).addHiddenPath(path);
        
        // songListProvider automatically refreshes because it watches settingsProvider
      },
      confirmDismiss: (direction) async {
        return await _showDeleteFolderConfirmation(context, ref, folder['name'], folder['path']);
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.9),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 15, spreadRadius: 2),
          ],
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 32),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'DELETING FOLDER: ${folder['name'].toUpperCase()}',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(width: 16),
            const Icon(LucideIcons.trash2, color: Colors.white, size: 22),
          ],
        ),
      ),
      child: _buildFolderExplorerItem(folder, index),
    );
  }

  Widget _buildAuraBackground() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.25,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          width: 300,
          height: 300,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00FFFF).withOpacity(0.15), // Cyan Glow
                blurRadius: 100,
                spreadRadius: 50,
              ),
              BoxShadow(
                color: const Color(0xFFFF00FF).withOpacity(0.12), // Purple Glow
                blurRadius: 150,
                spreadRadius: 20,
              ),
              BoxShadow(
                color: const Color(0xFF00FFCC).withOpacity(0.1), // Mint Glow
                blurRadius: 200,
                spreadRadius: 10,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundVisualizer() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.1,
        child: CustomPaint(
          painter: WavePainter(color: AppTheme.accentNeon),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActionButton(
          icon: RotationTransition(
            turns: CurvedAnimation(
              parent: _syncController,
              curve: Curves.easeInOutCubic,
            ),
            child: const Icon(Icons.sync, size: 16),
          ),
          label: 'SYNC',
          onTap: () {
            _syncController.forward(from: 0);
            ref.invalidate(songListProvider);
          },
        ),
        const SizedBox(width: 8),
        _buildActionButton(
          icon: const Icon(Icons.folder_shared_outlined, size: 16),
          label: 'STORAGE',
          onTap: () => _pickCustomFolder(ref),
          isPrimary: true,
        ),
        const SizedBox(width: 8),
        _buildFXToggle(),
      ],
    );
  }

  Widget _buildActionButton({
    required Widget icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: AppTheme.neumorphicDecoration(
          borderRadius: 12,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Theme(
              data: Theme.of(context).copyWith(
                iconTheme: IconThemeData(
                  color: isPrimary ? AppTheme.accentNeon : AppTheme.deepDark.withOpacity(0.6),
                ),
              ),
              child: icon,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: isPrimary ? AppTheme.accentNeon : AppTheme.deepDark.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFolderTags(WidgetRef ref) {
    final scanPaths = ref.watch(settingsProvider).scanPaths;
    if (scanPaths.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: scanPaths.map((path) => _buildPathTag(ref, path)).toList(),
      ),
    );
  }

  Widget _buildPathTag(WidgetRef ref, String path) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accentNeon.withOpacity(0.12),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.accentNeon.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentNeon.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open, size: 13, color: AppTheme.accentNeon),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              path.split('/').last.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: AppTheme.accentNeon,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ref.read(settingsProvider.notifier).removeScanPath(path),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: AppTheme.accentNeon.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, size: 10, color: AppTheme.accentNeon),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomFolder(WidgetRef ref) async {
    try {
      final String? selectedDirectory = await fp.FilePicker.getDirectoryPath();
      if (selectedDirectory != null) {
        await ref.read(settingsProvider.notifier).addScanPath(selectedDirectory);
        ref.invalidate(songListProvider);
      }
    } catch (e) {
      debugPrint('Famsic: Error picking directory: $e');
    }
  }

  Widget _buildFXToggle() {
    return GestureDetector(
      onTap: () => setState(() => _fxEnabled = !_fxEnabled),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: AppTheme.neumorphicDecoration(
          borderRadius: 12,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FX',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _fxEnabled ? AppTheme.accentNeon : AppTheme.deepDark.withOpacity(0.3),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _fxEnabled ? AppTheme.accentNeon : AppTheme.deepDark.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderExplorerItem(Map<String, dynamic> folder, int index) {
    final path = folder['path'] as String;
    final isExpanded = _expandedPath == path;

    return Column(
      children: [
        _buildFolderCard(folder, index, isExpanded),
        if (isExpanded) _buildFolderTracksList(path, index),
      ],
    );
  }

  Widget _buildFolderCard(Map<String, dynamic> folder, int index, bool isExpanded) {
    // Generate a unique neon color based on index
    final List<Color> neonColors = [
      const Color(0xFF00FFFF), // Cyan
      const Color(0xFFFF00FF), // Neon Purple
      const Color(0xFF00FF66), // Neon Green
      const Color(0xFFFF6600), // Neon Orange
      const Color(0xFFFFFF00), // Yellow
    ];
    final color = neonColors[index % neonColors.length];

    return GestureDetector(
      onTap: () {
        setState(() {
          if (_expandedPath == folder['path']) {
            _expandedPath = null;
          } else {
            _expandedPath = folder['path'];
          }
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        decoration: AppTheme.neumorphicDecoration(
          borderRadius: 24,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Neon Status Strip - Active glow if expanded
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 4,
                  decoration: BoxDecoration(
                    color: isExpanded ? color : color.withOpacity(0.4),
                    boxShadow: isExpanded ? [BoxShadow(color: color, blurRadius: 10, spreadRadius: 1)] : [],
                  ),
                ),
                const SizedBox(width: 16),
                // Icon Container with soft glow
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.2)),
                  ),
                  child: Icon(
                    _getFolderIcon(folder['name']),
                    color: isExpanded ? color : color.withOpacity(0.8),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                // Text Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          folder['name'].toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            color: AppTheme.deepDark,
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              '${folder['count']} TRACKS',
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.secondaryGrey,
                                letterSpacing: 1.5,
                              ),
                            ),
                            if (isExpanded) ...[
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  _syncController.forward(from: 0);
                                  ref.invalidate(songListProvider);
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    LucideIcons.refreshCcw,
                                    size: 10,
                                    color: color,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Animated Arrow
                Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: AnimatedRotation(
                    turns: isExpanded ? 0.25 : 0, // 90 degrees
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: AppTheme.secondaryGrey.withOpacity(0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFolderTracksList(String folderPath, int folderIndex) {
    final songs = ref.watch(folderSongsProvider(folderPath));
    final currentMediaItem = ref.watch(currentSongProvider).value;
    final handler = ref.watch(audioHandlerProvider);

    return Container(
      margin: const EdgeInsets.only(left: 20, bottom: 20, right: 4),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: Colors.black.withOpacity(0.05), width: 2)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: songs.length,
        itemBuilder: (context, idx) {
          final song = songs[idx];
          final isPlaying = currentMediaItem?.id == song.uri;
          final playbackState = ref.watch(playbackStateProvider).value;

          return Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 8),
            child: _buildTrackTile(song, isPlaying, playbackState, handler),
          );
        },
      ),
    );
  }

  Widget _buildTrackTile(NativeSongModel song, bool isPlaying, PlaybackState? playbackState, FamsicAudioHandler handler) {
    return GestureDetector(
      onTap: () async {
        final currentSong = ref.read(currentSongProvider).value;
        // Use the passed playbackState or read it fresh
        final currentPlaybackState = ref.read(playbackStateProvider).value;
        
        // SYNC: Update active playlist so Library carousel matches this folder
        final folderPath = song.data.substring(0, song.data.lastIndexOf('/'));
        final folderSongs = ref.read(folderSongsProvider(folderPath));
        ref.read(activePlaylistProvider.notifier).setPlaylist(folderSongs);

        if (currentSong?.id == song.uri) {
          // Same song, toggle playback
          if (currentPlaybackState?.playing ?? false) {
            await handler.pause();
          } else {
            await handler.play();
          }
        } else {
          // Different song, handle queue and skip
          final mediaItems = await _getMediaItemsForFolder(folderPath);
          
          // Efficiently update queue only if modified
          final currentQueue = handler.queue.value;
          bool needsUpdate = currentQueue.length != mediaItems.length;
          if (!needsUpdate) {
            for (int i = 0; i < mediaItems.length; i++) {
              if (mediaItems[i].id != currentQueue[i].id) {
                needsUpdate = true;
                break;
              }
            }
          }

          final index = mediaItems.indexWhere((item) => item.id == song.uri);
          if (needsUpdate) {
            await handler.updateQueue(mediaItems, initialIndex: index != -1 ? index : 0);
          } else if (index != -1) {
            await handler.skipToQueueItem(index);
          }
        }

        // REMOVED: auto-navigate to Library
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPlaying ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isPlaying ? [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ] : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isPlaying ? AppTheme.neonCyan.withOpacity(0.1) : Colors.black.withOpacity(0.03),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isPlaying 
                      ? (playbackState?.playing ?? false ? LucideIcons.pause : LucideIcons.play) 
                      : LucideIcons.music,
                    size: 14,
                    color: isPlaying ? AppTheme.neonCyan : AppTheme.secondaryGrey,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: isPlaying ? FontWeight.w900 : FontWeight.w600,
                          color: AppTheme.deepDark,
                        ),
                      ),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          color: AppTheme.secondaryGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPlaying)
                  const AnimatedBarChart(),
              ],
            ),
            if (isPlaying) ...[
              const SizedBox(height: 8),
              const SleekListProgress(),
            ],
          ],
        ),
      ),
    );
  }

  Future<bool> _showDeleteFolderConfirmation(BuildContext context, WidgetRef ref, String name, String path) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.creamBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: Text(
          'REMOVE FOLDER?',
          style: GoogleFonts.monoton(fontSize: 18, color: AppTheme.deepDark),
        ),
        content: Text(
          'This will remove "${name.toUpperCase()}" from your music explorer. The files will not be deleted.',
          style: GoogleFonts.outfit(color: AppTheme.secondaryGrey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.secondaryGrey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('REMOVE', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<List<MediaItem>> _getMediaItemsForFolder(String folderPath) async {
    final songs = ref.read(folderSongsProvider(folderPath));
    return songs.map((s) => s.toMediaItem()).toList();
  }

  IconData _getFolderIcon(String name) {
    final n = name.toLowerCase();
    if (n.contains('download')) return Icons.file_download_outlined;
    if (n.contains('record')) return Icons.mic_none_outlined;
    if (n.contains('music')) return Icons.library_music_outlined;
    if (n.contains('whatsapp')) return Icons.chat_outlined;
    return Icons.folder_open_outlined;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_off_outlined, size: 64, color: Colors.black.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            'NO LOCAL FOLDERS FOUND',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black.withOpacity(0.3),
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// A real-time animated bar chart that reflects frequency data from the audio handler.
class AnimatedBarChart extends ConsumerWidget {
  const AnimatedBarChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visualizerData = ref.watch(visualizerStreamProvider).value ?? [0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7];
    
    // We take a subset of the 7 buckets for a small icon (e.g., 3-4 bars)
    final displayBuckets = [
      visualizerData[1], // Low-mid
      visualizerData[3], // Mid
      visualizerData[5], // High-mid
    ];

    return SizedBox(
      height: 14,
      width: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: displayBuckets.map((val) {
          // Normalize and scale the value for the 14px height
          final height = (val * 14).clamp(3.0, 14.0);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 3,
            height: height,
            decoration: BoxDecoration(
              color: AppTheme.neonCyan,
              borderRadius: BorderRadius.circular(1),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonCyan.withOpacity(0.3),
                  blurRadius: 2,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// An ultra-sleek, minimalist progress bar for the folder track list.
class SleekListProgress extends ConsumerWidget {
  const SleekListProgress({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(positionProvider).value ?? Duration.zero;
    final duration = ref.watch(durationProvider).value ?? Duration.zero;
    final progress = duration.inMilliseconds > 0 
        ? position.inMilliseconds / duration.inMilliseconds 
        : 0.0;

    return Stack(
      children: [
        // Background Track
        Container(
          height: 2,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        // Active Progress
        FractionallySizedBox(
          widthFactor: progress.clamp(0.0, 1.0),
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: AppTheme.neonCyan,
              borderRadius: BorderRadius.circular(1),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.neonCyan.withOpacity(0.4),
                  blurRadius: 4,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class WavePainter extends CustomPainter {
  final Color color;
  WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    final yCenter = size.height * 0.4;
    
    path.moveTo(0, yCenter);
    for (double x = 0; x <= size.width; x++) {
      final y = yCenter + 20 * (x / size.width) * (x / size.width); // Subtle curve
       path.lineTo(x, y);
    }
    
    // More complex wave for "Acoustic Visualizer" feel
    final path2 = Path();
    path2.moveTo(0, yCenter + 50);
    for (double x = 0; x <= size.width; x++) {
       path2.lineTo(x, yCenter + 50 + 10 * (x % 50) / 50);
    }

    canvas.drawPath(path, paint);
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
