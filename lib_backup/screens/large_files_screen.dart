import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../services/cleaner_service.dart';
import '../services/ad_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

class LargeFilesScreen extends StatefulWidget {
  final AdService adService;
  const LargeFilesScreen({super.key, required this.adService});

  @override
  State<LargeFilesScreen> createState() => _LargeFilesScreenState();
}

class _LargeFilesScreenState extends State<LargeFilesScreen> {
  final CleanerService _service = CleanerService();
  List<FileItem> _files = [];
  bool _loading = false;
  bool _scanned = false;
  bool _isDeleting = false;

  int get _selectedSize =>
      _files.where((f) => f.isSelected).fold(0, (s, f) => s + f.size);

  Future<void> _scan() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _scanned = false;
      _files = [];
    });
    final files = await _service.scanLargeFiles();
    if (!mounted) return;
    setState(() {
      _files = files;
      _loading = false;
      _scanned = true;
    });
    widget.adService.showInterstitial();
  }

  Future<void> _deleteSelected() async {
    final selected = _files.where((f) => f.isSelected).toList();
    if (selected.isEmpty) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete ${selected.length} File(s)?',
      message:
          'This will permanently delete ${formatBytes(_selectedSize)}. This cannot be undone.',
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    final paths = selected.map((f) => f.path).toList();
    await _service.deleteFiles(paths);
    if (!mounted) return;

    setState(() {
      _isDeleting = false;
      _files.removeWhere((f) => f.isSelected);
    });

    widget.adService.showInterstitial();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Freed ${formatBytes(_selectedSize)}'),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _files.where((f) => f.isSelected).length;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Large Files'),
        actions: [
          if (_scanned && _files.isNotEmpty)
            TextButton(
              onPressed: () {
                setState(() {
                  for (final f in _files) f.isSelected = true;
                });
              },
              child: const Text('Select All',
                  style: TextStyle(color: AppTheme.primary)),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: _buildBody()),
              BannerAdWidget(adService: widget.adService),
            ],
          ),
          if (_isDeleting) const LoadingOverlay(message: 'Deleting files...'),
        ],
      ),
      floatingActionButton: selectedCount > 0
          ? FloatingActionButton.extended(
              onPressed: _deleteSelected,
              backgroundColor: AppTheme.danger,
              icon: const Icon(Icons.delete_rounded, color: Colors.white),
              label: Text(
                'Delete $selectedCount file(s)',
                style: const TextStyle(
                  color: Colors.white,
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
              valueColor: AlwaysStoppedAnimation(AppTheme.secondary),
            ),
            SizedBox(height: 20),
            Text(
              'Scanning for large files...',
              style: TextStyle(color: AppTheme.textPrimary),
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
                  color: AppTheme.secondary.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.secondary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.folder_zip_rounded,
                  color: AppTheme.secondary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Find Large Files',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Scans your device for files larger than 10 MB\nthat may be taking up valuable space.',
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
                icon: const Icon(Icons.search_rounded),
                label: const Text('Scan Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_files.isEmpty) {
      return const EmptyState(
        icon: Icons.check_circle_rounded,
        title: 'No large files found',
        subtitle: 'Your storage looks healthy!',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      itemCount: _files.length,
      itemBuilder: (_, i) {
        final f = _files[i];
        return _LargeFileTile(
          file: f,
          rank: i + 1,
          onChanged: (val) => setState(() => f.isSelected = val ?? false),
        );
      },
    );
  }
}

class _LargeFileTile extends StatelessWidget {
  final FileItem file;
  final int rank;
  final ValueChanged<bool?> onChanged;

  const _LargeFileTile({
    required this.file,
    required this.rank,
    required this.onChanged,
  });

  Color get _sizeColor {
    final mb = file.size / (1024 * 1024);
    if (mb > 500) return AppTheme.danger;
    if (mb > 100) return AppTheme.warning;
    return AppTheme.secondary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: file.isSelected
            ? AppTheme.secondary.withOpacity(0.08)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: file.isSelected
              ? AppTheme.secondary.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: CheckboxListTile(
        value: file.isSelected,
        onChanged: onChanged,
        activeColor: AppTheme.secondary,
        secondary: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: _sizeColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '#$rank',
              style: TextStyle(
                color: _sizeColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        title: Text(
          file.name,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          file.path,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 11,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Padding(
          padding: const EdgeInsets.only(right: 8),
          child: SizeBadge(size: file.formattedSize, color: _sizeColor),
        ),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
