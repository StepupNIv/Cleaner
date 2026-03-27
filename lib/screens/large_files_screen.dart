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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Freed ${formatBytes(_selectedSize)}'),
        backgroundColor: AppTheme.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _files.where((f) => f.isSelected).length;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Large Files'),
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
              icon: const Icon(Icons.delete),
              label: Text('Delete $selectedCount'),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_scanned) {
      return Center(
        child: ElevatedButton(
          onPressed: _scan,
          child: const Text("Scan Large Files"),
        ),
      );
    }

    if (_files.isEmpty) {
      return const Center(child: Text("No large files found"));
    }

    return ListView.builder(
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
    if (mb > 500) return Colors.red;
    if (mb > 100) return Colors.orange;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: file.isSelected,
        onChanged: onChanged,
      ),
      title: Text(file.name),
      subtitle: Text(file.path),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('#$rank'),
          const SizedBox(width: 8),
          Text(file.formattedSize),
        ],
      ),
    );
  }
}
