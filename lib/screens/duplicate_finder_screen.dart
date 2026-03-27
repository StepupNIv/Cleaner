import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../services/cleaner_service.dart';
import '../services/ad_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

class DuplicateFinderScreen extends StatefulWidget {
  final AdService adService;
  const DuplicateFinderScreen({super.key, required this.adService});

  @override
  State<DuplicateFinderScreen> createState() => _DuplicateFinderScreenState();
}

class _DuplicateFinderScreenState extends State<DuplicateFinderScreen> {
  final CleanerService _service = CleanerService();
  List<DuplicateGroup> _groups = [];
  bool _loading = false;
  bool _scanned = false;
  bool _isDeleting = false;

  // Per-group selected file indices (keep one original per group)
  final Map<String, Set<String>> _selectedPaths = {};

  int get _totalSelectedSize {
    int total = 0;
    for (final g in _groups) {
      final sel = _selectedPaths[g.hash] ?? {};
      for (final f in g.files) {
        if (sel.contains(f.path)) total += f.size;
      }
    }
    return total;
  }

  int get _totalSelectedCount {
    return _selectedPaths.values.fold(0, (sum, s) => sum + s.length);
  }

  Future<void> _scan() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _scanned = false;
      _groups = [];
      _selectedPaths.clear();
    });
    final groups = await _service.scanDuplicates();
    if (!mounted) return;
    // Auto-select all duplicates except the first (original)
    final preSelected = <String, Set<String>>{};
    for (final g in groups) {
      preSelected[g.hash] = g.files.skip(1).map((f) => f.path).toSet();
    }
    setState(() {
      _groups = groups;
      _loading = false;
      _scanned = true;
      _selectedPaths.addAll(preSelected);
    });
    widget.adService.showInterstitial();
  }

  Future<void> _deleteSelected() async {
    final allPaths = _selectedPaths.values.expand((s) => s).toList();
    if (allPaths.isEmpty) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Duplicates?',
      message:
          'Delete ${allPaths.length} duplicate(s) (${formatBytes(_totalSelectedSize)})? Originals will be kept.',
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    await _service.deleteFiles(allPaths);
    if (!mounted) return;

    // Remove deleted files from groups
    setState(() {
      _isDeleting = false;
      for (final g in _groups) {
        final sel = _selectedPaths[g.hash] ?? {};
        g.files.removeWhere((f) => sel.contains(f.path));
      }
      _groups.removeWhere((g) => g.files.length <= 1);
      _selectedPaths.clear();
    });

    widget.adService.showInterstitial();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Freed ${formatBytes(_totalSelectedSize)} of duplicates'),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(title: const Text('Duplicate Images')),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: _buildBody()),
              BannerAdWidget(adService: widget.adService),
            ],
          ),
          if (_isDeleting)
            const LoadingOverlay(message: 'Removing duplicates...'),
        ],
      ),
      floatingActionButton: _totalSelectedCount > 0
          ? FloatingActionButton.extended(
              onPressed: _deleteSelected,
              backgroundColor: AppTheme.accent.withOpacity(0.9),
              icon: const Icon(Icons.delete_rounded, color: AppTheme.bg),
              label: Text(
                'Delete ${formatBytes(_totalSelectedSize)}',
                style: const TextStyle(
                  color: AppTheme.bg,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppTheme.accent),
            ),
            SizedBox(height: 20),
            Text(
              'Hashing images for duplicates...',
              style: TextStyle(color: AppTheme.textPrimary),
            ),
            SizedBox(height: 8),
            Text(
              'This may take a moment',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (!_scanned) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.accent.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.accent.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.copy_all_rounded,
                  color: AppTheme.accent,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Find Duplicate Images',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Uses MD5 hashing to find identical images.\nDuplicates are pre-selected; originals are kept safe.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: _scan,
                icon: const Icon(Icons.image_search_rounded),
                label: const Text('Scan Images'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: AppTheme.bg,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_groups.isEmpty) {
      return const EmptyState(
        icon: Icons.image_rounded,
        title: 'No duplicates found',
        subtitle: 'All your images are unique!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _groups.length,
      itemBuilder: (_, i) {
        final g = _groups[i];
        final sel = _selectedPaths[g.hash] ?? {};
        return _DuplicateGroupCard(
          group: g,
          selectedPaths: sel,
          onToggle: (path, selected) {
            setState(() {
              final s = _selectedPaths[g.hash] ?? {};
              if (selected) {
                s.add(path);
              } else {
                s.remove(path);
              }
              _selectedPaths[g.hash] = s;
            });
          },
        );
      },
    );
  }
}

class _DuplicateGroupCard extends StatelessWidget {
  final DuplicateGroup group;
  final Set<String> selectedPaths;
  final void Function(String path, bool selected) onToggle;

  const _DuplicateGroupCard({
    required this.group,
    required this.selectedPaths,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accent.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.accent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
                  ),
                  child: Text(
                    '${group.files.length} copies',
                    style: const TextStyle(
                      color: AppTheme.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Wastes ${group.formattedDuplicateSize}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: group.files.length,
              itemBuilder: (_, j) {
                final f = group.files[j];
                final isOriginal = j == 0;
                final isSelected = selectedPaths.contains(f.path);
                return _DuplicateImageTile(
                  file: f,
                  isOriginal: isOriginal,
                  isSelected: isSelected,
                  onTap: isOriginal
                      ? null
                      : () => onToggle(f.path, !isSelected),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DuplicateImageTile extends StatelessWidget {
  final FileItem file;
  final bool isOriginal;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DuplicateImageTile({
    required this.file,
    required this.isOriginal,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 8),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceAlt,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.danger
                      : isOriginal
                          ? AppTheme.accent
                          : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/placeholder.png',
                  width: 90,
                  height: 90,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 90,
                    height: 90,
                    color: AppTheme.surfaceAlt,
                    child: const Icon(
                      Icons.image_rounded,
                      color: AppTheme.textSecondary,
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
            if (isOriginal)
              Positioned(
                top: 4,
                left: 4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Keep',
                    style: TextStyle(
                      color: AppTheme.bg,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            if (isSelected)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.danger,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
