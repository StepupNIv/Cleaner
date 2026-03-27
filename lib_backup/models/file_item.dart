class FileItem {
  final String path;
  final String name;
  final int size;
  final DateTime? modified;
  final FileItemType type;
  bool isSelected;

  FileItem({
    required this.path,
    required this.name,
    required this.size,
    this.modified,
    this.type = FileItemType.other,
    this.isSelected = false,
  });

  factory FileItem.fromMap(Map<dynamic, dynamic> map) {
    return FileItem(
      path: map['path'] as String? ?? '',
      name: map['name'] as String? ?? '',
      size: (map['size'] as num?)?.toInt() ?? 0,
      modified: map['modified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['modified'] as int)
          : null,
      type: FileItemType.values.firstWhere(
        (e) => e.name == (map['type'] as String? ?? 'other'),
        orElse: () => FileItemType.other,
      ),
    );
  }

  String get formattedSize => _formatBytes(size);

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

enum FileItemType { cache, temp, log, image, video, audio, document, other }

class DuplicateGroup {
  final String hash;
  final List<FileItem> files;
  bool isSelected;

  DuplicateGroup({
    required this.hash,
    required this.files,
    this.isSelected = false,
  });

  int get totalSize => files.fold(0, (sum, f) => sum + f.size);
  int get duplicateSize => totalSize - (files.isEmpty ? 0 : files.first.size);
  String get formattedDuplicateSize => FileItem._formatBytes(duplicateSize);
}

class AppInfo {
  final String name;
  final String packageName;
  final int? installedSize;

  AppInfo({
    required this.name,
    required this.packageName,
    this.installedSize,
  });

  factory AppInfo.fromMap(Map<dynamic, dynamic> map) {
    return AppInfo(
      name: map['name'] as String? ?? '',
      packageName: map['packageName'] as String? ?? '',
      installedSize: (map['installedSize'] as num?)?.toInt(),
    );
  }
}

class StorageStats {
  final int images;
  final int videos;
  final int audio;
  final int documents;
  final int other;
  final int total;

  StorageStats({
    required this.images,
    required this.videos,
    required this.audio,
    required this.documents,
    required this.other,
    required this.total,
  });

  factory StorageStats.fromMap(Map<dynamic, dynamic> map) {
    return StorageStats(
      images: (map['images'] as num?)?.toInt() ?? 0,
      videos: (map['videos'] as num?)?.toInt() ?? 0,
      audio: (map['audio'] as num?)?.toInt() ?? 0,
      documents: (map['documents'] as num?)?.toInt() ?? 0,
      other: (map['other'] as num?)?.toInt() ?? 0,
      total: (map['total'] as num?)?.toInt() ?? 0,
    );
  }

  factory StorageStats.empty() => StorageStats(
        images: 0, videos: 0, audio: 0, documents: 0, other: 0, total: 0,
      );
}
