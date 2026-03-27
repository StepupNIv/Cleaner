import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../services/cleaner_service.dart';
import '../services/ad_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

enum ScanState { idle, scanning, done }

class JunkCleanerScreen extends StatefulWidget {
  final AdService adService;
  const JunkCleanerScreen({super.key, required this.adService});

  @override
  State<JunkCleanerScreen> createState() => _JunkCleanerScreenState();
}

class _JunkCleanerScreenState extends State<JunkCleanerScreen> {
  final CleanerService _service = CleanerService();
  ScanState _state = ScanState.idle;
  List<FileItem> _files = [];
  bool _selectAll = false;
  bool _isDeleting = false;

  int get _selectedCount => _files.where((f) => f.isSelected).length;
  int get _selectedSize =>
      _files.where((f) => f.isSelected).fold(0, (s, f) => s + f.size);
  int get _totalSize => _files.fold(0, (s, f) => s + f.size);

  Future<void> _scan() async {
    if (!mounted) return;
    setState(() => _state = ScanState.scanning);
    final files = await _service.scanJunk();
    if (!mounted) return;
    setState(() {
      _files = files;
      _state = ScanState.done;
      _selectAll = false;
    });
    // Show interstitial after scan
    widget.adService.showInterstitial();
  }

  void _toggleSelectAll(bool val) {
    setState(() {
      _selectAll = val;
      for (final f in _files) {
        f.isSelected = val;
      }
    });
  }

  Future<void> _deleteSelected() async {
    final paths = _files.where((f) => f.isSelected).map((f) => f.path).toList();
    if (paths.isEmpty) return;

    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete Junk Files?',
      message:
          'Delete ${paths.length} file(s) (${formatBytes(_selectedSize)})? This cannot be undone.',
    );
    if (!confirmed || !mounted) return;

    setState(() => _isDeleting = true);
    final deleted = await _service.deleteFiles(paths);
    if (!mounted) return;

    setState(() {
      _isDeleting = false;
      _files.removeWhere((f) => f.isSelected);
    });

    widget.adService.showInterstitial();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cleaned $deleted file(s) — ${formatBytes(_selectedSize)}'),
        backgroundColor: AppTheme.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Junk Cleaner'),
        leading: const BackButton(),
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
      floatingActionButton: _state == ScanState.done && _selectedCount > 0
          ? FloatingActionButton.extended(
              onPressed: _deleteSelected,
              backgroundColor: AppTheme.danger,
              icon: const Icon(Icons.delete_rounded, color: Colors.white),
              label: Text(
                'Delete ${formatBytes(_selectedSize)}',
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
    switch (_state) {
      case ScanState.idle:
        return _buildIdle();
      case ScanState.scanning:
        return _buildScanning();
      case ScanState.done:
        return _buildResults();
    }
  }

  Widget _buildIdle() {
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
                color: AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                Icons.auto_delete_rounded,
                color: AppTheme.primary,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Scan for Junk Files',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Finds cache files, temp files, and logs\nfrom your apps to free up storage.',
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
              label: const Text('Start Scan'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanning() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Scanning for junk files...',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Checking app caches and temp directories',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_files.isEmpty) {
      return Column(
        children: [
          const Expanded(
            child: EmptyState(
              icon: Icons.check_circle_rounded,
              title: 'Your device is clean!',
              subtitle: 'No junk files found. Great job keeping it tidy.',
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: _scan,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Scan Again'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primary,
                side: const BorderSide(color: AppTheme.primary),
              ),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        // Summary bar
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_files.length} junk files found',
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Total: ${formatBytes(_totalSize)}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  const Text(
                    'Select All',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  Checkbox(
                    value: _selectAll,
                    onChanged: (v) => _toggleSelectAll(v ?? false),
                    activeColor: AppTheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
        // File list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
            itemCount: _files.length,
            itemBuilder: (_, i) {
              final f = _files[i];
              return _FileListTile(
                file: f,
                onChanged: (val) {
                  setState(() {
                    f.isSelected = val ?? false;
                    _selectAll = _files.every((f) => f.isSelected);
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FileListTile extends StatelessWidget {
  final FileItem file;
  final ValueChanged<bool?> onChanged;

  const _FileListTile({required this.file, required this.onChanged});

  IconData get _icon {
    switch (file.type) {
      case FileItemType.cache:
        return Icons.cached_rounded;
      case FileItemType.log:
        return Icons.description_rounded;
      case FileItemType.temp:
        return Icons.hourglass_empty_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: file.isSelected
            ? AppTheme.primary.withOpacity(0.08)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: file.isSelected
              ? AppTheme.primary.withOpacity(0.3)
              : Colors.transparent,
        ),
      ),
      child: CheckboxListTile(
        value: file.isSelected,
        onChanged: onChanged,
        activeColor: AppTheme.primary,
        secondary: Icon(_icon, color: AppTheme.textSecondary, size: 22),
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
          file.formattedSize,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
