import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  Future<bool> requestStoragePermissions() async {
    try {
      // Android 13+ uses granular media permissions
      final statuses = await [
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ].request();

      final allGranted = statuses.values.every(
        (s) => s.isGranted || s.isLimited,
      );

      if (!allGranted) {
        // Fallback for older Android
        final legacy = await Permission.storage.request();
        return legacy.isGranted;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasStoragePermission() async {
    try {
      final photos = await Permission.photos.status;
      if (photos.isGranted) return true;
      final storage = await Permission.storage.status;
      return storage.isGranted;
    } catch (_) {
      return false;
    }
  }

  Future<void> openSettings() async {
    try {
      await openAppSettings();
    } catch (_) {}
  }
}
