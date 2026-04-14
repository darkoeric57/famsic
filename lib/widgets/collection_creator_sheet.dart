import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import '../models/local_collection.dart';
import '../theme/app_theme.dart';
import '../providers/collections_provider.dart';
import '../providers/audio_providers.dart';
import '../core/native_song_model.dart';

class CollectionCreatorSheet extends ConsumerStatefulWidget {
  const CollectionCreatorSheet({super.key});

  @override
  ConsumerState<CollectionCreatorSheet> createState() => _CollectionCreatorSheetState();
}

class _CollectionCreatorSheetState extends ConsumerState<CollectionCreatorSheet> {
  final PageController _pageController = PageController();
  final TextEditingController _titleController = TextEditingController();
  
  int _currentStep = 0;
  String _selectedIconKey = 'music';
  final Set<String> _selectedUris = {};
  
  final List<Map<String, dynamic>> _iconPool = [
    {'key': 'heart', 'icon': LucideIcons.heart},
    {'key': 'star', 'icon': LucideIcons.star},
    {'key': 'flame', 'icon': LucideIcons.flame},
    {'key': 'coffee', 'icon': LucideIcons.coffee},
    {'key': 'music', 'icon': LucideIcons.music},
    {'key': 'dumbbell', 'icon': LucideIcons.dumbbell},
    {'key': 'moon', 'icon': LucideIcons.moon},
    {'key': 'sun', 'icon': LucideIcons.sun},
    {'key': 'zap', 'icon': LucideIcons.zap},
    {'key': 'headphones', 'icon': LucideIcons.headphones},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0 && _titleController.text.trim().isEmpty) return;
    
    // Auto-icon logic if user didn't change it
    if (_currentStep == 0 && _selectedIconKey == 'music') {
      _applyAutoIcon();
    }

    setState(() => _currentStep++);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _prevStep() {
    setState(() => _currentStep--);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _applyAutoIcon() {
    final title = _titleController.text.toLowerCase();
    if (title.contains('gym') || title.contains('work') || title.contains('fit')) _selectedIconKey = 'dumbbell';
    else if (title.contains('chill') || title.contains('relax') || title.contains('cafe')) _selectedIconKey = 'coffee';
    else if (title.contains('love') || title.contains('fav')) _selectedIconKey = 'heart';
    else if (title.contains('night') || title.contains('sleep')) _selectedIconKey = 'moon';
    else if (title.contains('energy') || title.contains('hype')) _selectedIconKey = 'zap';
    else if (title.contains('best') || title.contains('top')) _selectedIconKey = 'star';
    else if (title.contains('fire') || title.contains('hot')) _selectedIconKey = 'flame';
  }

  Future<void> _saveCollection() async {
    if (_selectedUris.isEmpty) return;

    final collection = LocalCollection(
      id: const Uuid().v4(),
      title: _titleController.text.trim(),
      iconKey: _selectedIconKey,
      trackUris: _selectedUris.toList(),
      createdAt: DateTime.now(),
    );

    await ref.read(collectionsProvider.notifier).addCollection(collection);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Header Indicator
          Container(
            margin: const EdgeInsets.symmetric(vertical: 16),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.secondaryGrey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
              ],
            ),
          ),
          
          // Bottom Bar
          _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEW COLLECTION',
            style: GoogleFonts.monoton(fontSize: 28, color: AppTheme.deepDark),
          ),
          const SizedBox(height: 8),
          Text(
            'NAME YOUR SOVEREIGN VIBE',
            style: GoogleFonts.outfit(
              fontSize: 10, 
              fontWeight: FontWeight.w900, 
              color: AppTheme.secondaryGrey,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 32),
          
          TextField(
            controller: _titleController,
            autofocus: true,
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: 'Collection Title...',
              hintStyle: TextStyle(color: AppTheme.secondaryGrey.withOpacity(0.3)),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black12)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.neonCyan, width: 2)),
            ),
          ),
          
          const SizedBox(height: 40),
          
          Text(
            'SELECT ICON',
            style: GoogleFonts.outfit(
              fontSize: 10, 
              fontWeight: FontWeight.w900, 
              color: AppTheme.secondaryGrey,
              letterSpacing: 2.0,
            ),
          ),
          const SizedBox(height: 16),
          
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: _iconPool.length,
              itemBuilder: (context, index) {
                final item = _iconPool[index];
                final isSelected = _selectedIconKey == item['key'];
                return GestureDetector(
                  onTap: () => setState(() => _selectedIconKey = item['key']),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.neonCyan.withOpacity(0.1) : Colors.black.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppTheme.neonCyan : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      item['icon'],
                      color: isSelected ? AppTheme.neonCyan : AppTheme.secondaryGrey,
                      size: 20,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    final folders = ref.watch(foldersProvider);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'TRACKS',
                style: GoogleFonts.monoton(fontSize: 28, color: AppTheme.deepDark),
              ),
              const SizedBox(height: 8),
              Text(
                'HARVEST YOUR SOUNDSCAPE',
                style: GoogleFonts.outfit(
                  fontSize: 10, 
                  fontWeight: FontWeight.w900, 
                  color: AppTheme.secondaryGrey,
                  letterSpacing: 2.0,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: folders.length,
            itemBuilder: (context, index) {
              final folder = folders[index];
              return _FolderSelectionTile(
                folder: folder,
                selectedUris: _selectedUris,
                onSelectionChanged: () => setState(() {}),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    final bool isReady = _currentStep == 0 
        ? _titleController.text.trim().isNotEmpty 
        : _selectedUris.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: AppTheme.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, -5))
        ],
      ),
      child: Row(
        children: [
          if (_currentStep > 0) ...[
            IconButton(
              onPressed: _prevStep,
              icon: const Icon(Icons.arrow_back),
            ),
            const SizedBox(width: 16),
          ],
          
          if (_currentStep == 1)
            Expanded(
              child: Text(
                '${_selectedUris.length} TRACKS SELECTED',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.secondaryGrey),
              ),
            ),
            
          const Spacer(),
          
          GestureDetector(
            onTap: isReady ? (_currentStep == 0 ? _nextStep : _saveCollection) : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: isReady ? AppTheme.deepDark : AppTheme.secondaryGrey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                boxShadow: isReady ? [
                  BoxShadow(color: AppTheme.deepDark.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))
                ] : [],
              ),
              child: Text(
                _currentStep == 0 ? 'NEXT' : 'CREATE',
                style: GoogleFonts.outfit(
                  color: isReady ? AppTheme.white : AppTheme.secondaryGrey,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FolderSelectionTile extends ConsumerStatefulWidget {
  final Map<String, dynamic> folder;
  final Set<String> selectedUris;
  final VoidCallback onSelectionChanged;

  const _FolderSelectionTile({
    required this.folder,
    required this.selectedUris,
    required this.onSelectionChanged,
  });

  @override
  ConsumerState<_FolderSelectionTile> createState() => _FolderSelectionTileState();
}

class _FolderSelectionTileState extends ConsumerState<_FolderSelectionTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final path = widget.folder['path'] as String;
    final folderSongs = ref.watch(folderSongsProvider(path));
    
    // Check if entire folder is selected
    final bool isAllSelected = folderSongs.isNotEmpty && 
        folderSongs.every((s) => widget.selectedUris.contains(s.uri));

    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  _isExpanded ? LucideIcons.folderOpen : LucideIcons.folder,
                  color: AppTheme.secondaryGrey,
                  size: 20,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    (widget.folder['name'] as String).toUpperCase(),
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                // "Select All" Checkbox for folder
                Checkbox(
                  value: isAllSelected,
                  activeColor: AppTheme.neonCyan,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        for (var s in folderSongs) {
                          widget.selectedUris.add(s.uri);
                        }
                      } else {
                        for (var s in folderSongs) {
                          widget.selectedUris.remove(s.uri);
                        }
                      }
                    });
                    widget.onSelectionChanged();
                  },
                ),
              ],
            ),
          ),
        ),
        
        if (_isExpanded)
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 16),
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: folderSongs.length,
              itemBuilder: (context, idx) {
                final song = folderSongs[idx];
                final isSelected = widget.selectedUris.contains(song.uri);
                
                return CheckboxListTile(
                  value: isSelected,
                  activeColor: AppTheme.neonCyan,
                  dense: true,
                  title: Text(
                    song.title,
                    style: GoogleFonts.outfit(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onChanged: (val) {
                    setState(() {
                      if (val == true) widget.selectedUris.add(song.uri);
                      else widget.selectedUris.remove(song.uri);
                    });
                    widget.onSelectionChanged();
                  },
                );
              },
            ),
          ),
      ],
    );
  }
}
