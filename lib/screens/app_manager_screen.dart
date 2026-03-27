import 'package:flutter/material.dart';
import '../models/file_item.dart';
import '../services/cleaner_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

class AppManagerScreen extends StatefulWidget {
  const AppManagerScreen({super.key});

  @override
  State<AppManagerScreen> createState() => _AppManagerScreenState();
}

class _AppManagerScreenState extends State<AppManagerScreen> {
  final CleanerService _service = CleanerService();
  List<AppInfo> _apps = [];
  List<AppInfo> _filtered = [];
  bool _loading = false;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final apps = await _service.getInstalledApps();
    if (!mounted) return;
    setState(() {
      _apps = apps;
      _filtered = apps;
      _loading = false;
    });
  }

  void _search(String q) {
    setState(() {
      _query = q;
      _filtered = q.isEmpty
          ? _apps
          : _apps
              .where((a) =>
                  a.name.toLowerCase().contains(q.toLowerCase()) ||
                  a.packageName.toLowerCase().contains(q.toLowerCase()))
              .toList();
    });
  }

  Future<void> _uninstall(AppInfo app) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Uninstall ${app.name}?',
      message:
          'This will open the system uninstall dialog for "${app.name}".\nYou must confirm in the next screen.',
      confirmText: 'Continue',
      confirmColor: AppTheme.danger,
    );
    if (!confirmed || !mounted) return;
    await _service.uninstallApp(app.packageName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('App Manager'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: _search,
              style: const TextStyle(color: AppTheme.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search apps...',
                hintStyle: const TextStyle(color: AppTheme.textSecondary),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: AppTheme.textSecondary),
                filled: true,
                fillColor: AppTheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.danger),
              ),
            )
          : _filtered.isEmpty
              ? const EmptyState(
                  icon: Icons.apps_rounded,
                  title: 'No apps found',
                  subtitle: 'Try a different search term.',
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) {
                    final app = _filtered[i];
                    return _AppTile(
                      app: app,
                      onUninstall: () => _uninstall(app),
                    );
                  },
                ),
    );
  }
}

class _AppTile extends StatelessWidget {
  final AppInfo app;
  final VoidCallback onUninstall;

  const _AppTile({required this.app, required this.onUninstall});

  String get _initial =>
      app.name.isNotEmpty ? app.name[0].toUpperCase() : '?';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.danger.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                _initial,
                style: const TextStyle(
                  color: AppTheme.danger,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  app.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  app.packageName,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppTheme.danger,
              size: 22,
            ),
            onPressed: onUninstall,
            tooltip: 'Uninstall',
          ),
        ],
      ),
    );
  }
}
