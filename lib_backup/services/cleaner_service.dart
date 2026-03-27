import 'dart:async';
import 'package:flutter/services.dart';
import '../models/file_item.dart';

class CleanerService {
  static const MethodChannel _channel = MethodChannel('smart_cleaner');

  // ── Junk Scan ──────────────────────────────────────────────────────────────
  Future<List<FileItem>> scanJunk() async {
    try {
      final result = await _channel.invokeMethod('scanJunk');
      if (result == null) return [];
      final list = result as List<dynamic>;
      return list
          .whereType<Map>()
          .map((m) => FileItem.fromMap(m))
          .where((f) => f.path.isNotEmpty)
          .toList();
    } on PlatformException catch (e) {
      _log('scanJunk error: ${e.message}');
      return [];
    } catch (e) {
      _log('scanJunk unexpected: $e');
      return [];
    }
  }

  // ── Large Files ────────────────────────────────────────────────────────────
  Future<List<FileItem>> scanLargeFiles() async {
    try {
      final result = await _channel.invokeMethod('scanLargeFiles');
      if (result == null) return [];
      final list = result as List<dynamic>;
      return list
          .whereType<Map>()
          .map((m) => FileItem.fromMap(m))
          .where((f) => f.path.isNotEmpty && f.size > 0)
          .toList();
    } on PlatformException catch (e) {
      _log('scanLargeFiles error: ${e.message}');
      return [];
    } catch (e) {
      _log('scanLargeFiles unexpected: $e');
      return [];
    }
  }

  // ── Duplicate Images ───────────────────────────────────────────────────────
  Future<List<DuplicateGroup>> scanDuplicates() async {
    try {
      final result = await _channel.invokeMethod('scanDuplicates');
      if (result == null) return [];
      final list = result as List<dynamic>;
      return list.whereType<Map>().map((groupMap) {
        final hash = groupMap['hash'] as String? ?? '';
        final filesRaw = groupMap['files'] as List<dynamic>? ?? [];
        final files = filesRaw
            .whereType<Map>()
            .map((m) => FileItem.fromMap(m))
            .toList();
        return DuplicateGroup(hash: hash, files: files);
      }).where((g) => g.files.length > 1).toList();
    } on PlatformException catch (e) {
      _log('scanDuplicates error: ${e.message}');
      return [];
    } catch (e) {
      _log('scanDuplicates unexpected: $e');
      return [];
    }
  }

  // ── Storage Stats ──────────────────────────────────────────────────────────
  Future<StorageStats> getStorageStats() async {
    try {
      final result = await _channel.invokeMethod('getStorageStats');
      if (result == null) return StorageStats.empty();
      return StorageStats.fromMap(result as Map);
    } on PlatformException catch (e) {
      _log('getStorageStats error: ${e.message}');
      return StorageStats.empty();
    } catch (e) {
      _log('getStorageStats unexpected: $e');
      return StorageStats.empty();
    }
  }

  // ── Installed Apps ─────────────────────────────────────────────────────────
  Future<List<AppInfo>> getInstalledApps() async {
    try {
      final result = await _channel.invokeMethod('getInstalledApps');
      if (result == null) return [];
      final list = result as List<dynamic>;
      return list
          .whereType<Map>()
          .map((m) => AppInfo.fromMap(m))
          .where((a) => a.packageName.isNotEmpty)
          .toList();
    } on PlatformException catch (e) {
      _log('getInstalledApps error: ${e.message}');
      return [];
    } catch (e) {
      _log('getInstalledApps unexpected: $e');
      return [];
    }
  }

  // ── Delete Files ───────────────────────────────────────────────────────────
  Future<int> deleteFiles(List<String> paths) async {
    if (paths.isEmpty) return 0;
    try {
      final result = await _channel.invokeMethod('deleteFiles', {'paths': paths});
      return (result as num?)?.toInt() ?? 0;
    } on PlatformException catch (e) {
      _log('deleteFiles error: ${e.message}');
      return 0;
    } catch (e) {
      _log('deleteFiles unexpected: $e');
      return 0;
    }
  }

  // ── Uninstall App ──────────────────────────────────────────────────────────
  Future<void> uninstallApp(String packageName) async {
    try {
      await _channel.invokeMethod('uninstallApp', {'package': packageName});
    } on PlatformException catch (e) {
      _log('uninstallApp error: ${e.message}');
    } catch (e) {
      _log('uninstallApp unexpected: $e');
    }
  }

  void _log(String msg) {
    // ignore: avoid_print
    print('[CleanerService] $msg');
  }
}
