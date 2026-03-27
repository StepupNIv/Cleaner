import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/file_item.dart';
import '../services/cleaner_service.dart';
import '../theme.dart';
import '../widgets/common_widgets.dart';

class StorageAnalyzerScreen extends StatefulWidget {
  const StorageAnalyzerScreen({super.key});

  @override
  State<StorageAnalyzerScreen> createState() => _StorageAnalyzerScreenState();
}

class _StorageAnalyzerScreenState extends State<StorageAnalyzerScreen> {
  final CleanerService _service = CleanerService();
  StorageStats? _stats;
  bool _loading = false;
  int _touchedIndex = -1;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final stats = await _service.getStorageStats();
    if (!mounted) return;
    setState(() {
      _stats = stats;
      _loading = false;
    });
  }

  static const _categories = [
    _Category('Images', AppTheme.primary, Icons.image_rounded),
    _Category('Videos', AppTheme.secondary, Icons.videocam_rounded),
    _Category('Audio', AppTheme.accent, Icons.music_note_rounded),
    _Category('Documents', AppTheme.warning, Icons.description_rounded),
    _Category('Other', Color(0xFF8892A4), Icons.folder_rounded),
  ];

  List<int> _getValues(StorageStats s) =>
      [s.images, s.videos, s.audio, s.documents, s.other];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('Storage Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppTheme.warning),
              ),
            )
          : _stats == null
              ? const EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Could not load storage info',
                  subtitle: 'Check permissions and try again.',
                )
              : _buildContent(_stats!),
    );
  }

  Widget _buildContent(StorageStats stats) {
    final values = _getValues(stats);
    final total = values.fold(0, (s, v) => s + v);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Total badge
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A2010), Color(0xFF0D3C1D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.warning.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.storage_rounded,
                  color: AppTheme.warning,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Media',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      formatBytes(total),
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Pie Chart
          if (total > 0)
            SizedBox(
              height: 260,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        _touchedIndex = response?.touchedSection
                                ?.touchedSectionIndex ??
                            -1;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 3,
                  centerSpaceRadius: 60,
                  sections: List.generate(_categories.length, (i) {
                    final val = values[i];
                    if (val == 0) return null;
                    final pct = total > 0 ? (val / total * 100) : 0.0;
                    final isTouched = i == _touchedIndex;
                    return PieChartSectionData(
                      color: _categories[i].color,
                      value: val.toDouble(),
                      title: '${pct.toStringAsFixed(1)}%',
                      radius: isTouched ? 90 : 80,
                      titleStyle: TextStyle(
                        fontSize: isTouched ? 14 : 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    );
                  }).whereType<PieChartSectionData>().toList(),
                ),
              ),
            ),
          const SizedBox(height: 24),
          // Legend
          ...List.generate(_categories.length, (i) {
            final val = values[i];
            final pct = total > 0 ? (val / total * 100) : 0.0;
            return _CategoryRow(
              category: _categories[i],
              size: val,
              percent: pct,
            );
          }),
        ],
      ),
    );
  }
}

class _Category {
  final String name;
  final Color color;
  final IconData icon;
  const _Category(this.name, this.color, this.icon);
}

class _CategoryRow extends StatelessWidget {
  final _Category category;
  final int size;
  final double percent;

  const _CategoryRow({
    required this.category,
    required this.size,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: category.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(category.icon, color: category.color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                formatBytes(size),
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: AppTheme.surfaceAlt,
              valueColor: AlwaysStoppedAnimation(category.color),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }
}
