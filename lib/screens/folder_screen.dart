import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart' as fp;
import '../providers/audio_providers.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';

class FolderScreen extends ConsumerStatefulWidget {
  const FolderScreen({super.key});

  @override
  ConsumerState<FolderScreen> createState() => _FolderScreenState();
}

class _FolderScreenState extends ConsumerState<FolderScreen> with SingleTickerProviderStateMixin {
  bool _fxEnabled = true;
  late AnimationController _syncController;

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
            child: Padding(
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
                  _buildActiveFolderTag(ref),
                  
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
                              return _buildFolderCard(folder, index);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
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
        decoration: BoxDecoration(
          color: isPrimary ? Colors.black : Colors.white.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isPrimary ? AppTheme.accentNeon : Colors.black.withOpacity(0.1),
            width: 1.5,
          ),
          boxShadow: isPrimary ? [
            BoxShadow(
              color: AppTheme.accentNeon.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Theme(
              data: Theme.of(context).copyWith(
                iconTheme: IconThemeData(
                  color: isPrimary ? AppTheme.accentNeon : Colors.black.withOpacity(0.6),
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
                color: isPrimary ? AppTheme.accentNeon : Colors.black.withOpacity(0.6),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFolderTag(WidgetRef ref) {
    final scanPath = ref.watch(settingsProvider).scanPath;
    if (scanPath == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.accentNeon.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppTheme.accentNeon.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_open, size: 14, color: AppTheme.accentNeon),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              scanPath.split('/').last.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentNeon,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ref.read(settingsProvider.notifier).clearScanPath(),
            child: Icon(Icons.close, size: 14, color: AppTheme.accentNeon),
          ),
        ],
      ),
    );
  }

  Future<void> _pickCustomFolder(WidgetRef ref) async {
    try {
      final String? selectedDirectory = await fp.FilePicker.getDirectoryPath();
      if (selectedDirectory != null) {
        await ref.read(settingsProvider.notifier).updateScanPath(selectedDirectory);
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
        decoration: BoxDecoration(
          color: _fxEnabled ? Colors.black : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _fxEnabled ? AppTheme.accentNeon : Colors.black.withOpacity(0.1),
            width: 1.5,
          ),
          boxShadow: _fxEnabled ? [
            BoxShadow(
              color: AppTheme.accentNeon.withOpacity(0.3),
              blurRadius: 8,
              spreadRadius: 1,
            )
          ] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'FX',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _fxEnabled ? AppTheme.accentNeon : Colors.black.withOpacity(0.3),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _fxEnabled ? AppTheme.accentNeon : Colors.black.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderCard(Map<String, dynamic> folder, int index) {
    // Generate a unique neon color based on index
    final List<Color> neonColors = [
      const Color(0xFF00FFFF), // Cyan
      const Color(0xFFFF00FF), // Neon Purple
      const Color(0xFF00FF66), // Neon Green
      const Color(0xFFFF6600), // Neon Orange
      const Color(0xFFFFFF00), // Yellow
    ];
    final color = neonColors[index % neonColors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Neon Status Strip
              Container(
                width: 4,
                color: color,
              ),
              const SizedBox(width: 16),
              // Icon Container with soft glow
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getFolderIcon(folder['name']),
                  color: color,
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
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${folder['count']} TRACKS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.black.withOpacity(0.4),
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Arrow
              Padding(
                padding: const EdgeInsets.only(right: 20),
                child: Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: Colors.black.withOpacity(0.2),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
