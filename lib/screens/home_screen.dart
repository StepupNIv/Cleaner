import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/ad_service.dart';
import '../widgets/common_widgets.dart';
import 'junk_cleaner_screen.dart';
import 'large_files_screen.dart';
import 'duplicate_finder_screen.dart';
import 'storage_analyzer_screen.dart';
import 'app_manager_screen.dart';

class HomeScreen extends StatelessWidget {
  final AdService adService;
  const HomeScreen({super.key, required this.adService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildAppBar(context),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      const SizedBox(height: 8),
                      _StorageOverviewCard(),
                      const SizedBox(height: 24),
                      const _SectionLabel('Quick Clean'),
                      const SizedBox(height: 12),
                      _FeatureGrid(adService: adService),
                      const SizedBox(height: 32),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          BannerAdWidget(adService: adService),
        ],
      ),
    );
  }

  SliverAppBar _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppTheme.bg,
      floating: true,
      pinned: false,
      expandedHeight: 120,
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        title: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Smart Cleaner',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
            ),
            Text(
              'Keep your device clean & fast',
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: AppTheme.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _StorageOverviewCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1040), Color(0xFF0D1F3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.storage_rounded,
                  color: AppTheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Device Storage',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            'Tap any feature below to scan\nyour device for optimization opportunities.',
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accent.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.verified_rounded, color: AppTheme.accent, size: 16),
                SizedBox(width: 6),
                Text(
                  'No fake results — real files only',
                  style: TextStyle(
                    color: AppTheme.accent,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final AdService adService;
  const _FeatureGrid({required this.adService});

  @override
  Widget build(BuildContext context) {
    final features = [
      _FeatureConfig(
        title: 'Junk Cleaner',
        subtitle: 'Cache & temp files',
        icon: Icons.auto_delete_rounded,
        colors: [const Color(0xFF1A2744), const Color(0xFF0D1F3C)],
        accent: AppTheme.primary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => JunkCleanerScreen(adService: adService),
          ),
        ),
      ),
      _FeatureConfig(
        title: 'Large Files',
        subtitle: 'Files over 10 MB',
        icon: Icons.folder_zip_rounded,
        colors: [const Color(0xFF2A1040), const Color(0xFF1A0D3C)],
        accent: AppTheme.secondary,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LargeFilesScreen(adService: adService),
          ),
        ),
      ),
      _FeatureConfig(
        title: 'Duplicates',
        subtitle: 'Duplicate images',
        icon: Icons.copy_all_rounded,
        colors: [const Color(0xFF1A2A10), const Color(0xFF0D3C1D)],
        accent: AppTheme.accent,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DuplicateFinderScreen(adService: adService),
          ),
        ),
      ),
      _FeatureConfig(
        title: 'Storage Map',
        subtitle: 'Usage by category',
        icon: Icons.donut_large_rounded,
        colors: [const Color(0xFF2A1A10), const Color(0xFF3C250D)],
        accent: AppTheme.warning,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const StorageAnalyzerScreen(),
          ),
        ),
      ),
      _FeatureConfig(
        title: 'App Manager',
        subtitle: 'Uninstall apps',
        icon: Icons.apps_rounded,
        colors: [const Color(0xFF2A0D10), const Color(0xFF3C0D1A)],
        accent: AppTheme.danger,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AppManagerScreen(),
          ),
        ),
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: features.length,
      itemBuilder: (_, i) => _FeatureCard(config: features[i]),
    );
  }
}

class _FeatureConfig {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final Color accent;
  final VoidCallback onTap;

  _FeatureConfig({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.accent,
    required this.onTap,
  });
}

class _FeatureCard extends StatelessWidget {
  final _FeatureConfig config;
  const _FeatureCard({required this.config});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: config.onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: config.colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: config.accent.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: config.accent.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(config.icon, color: config.accent, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  config.subtitle,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
