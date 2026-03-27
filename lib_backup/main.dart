import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/ad_service.dart';
import 'services/permission_service.dart';
import 'screens/permission_gate_screen.dart';
import 'screens/home_screen.dart';
import 'theme.dart';

Future<void> main() async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Lock to portrait
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
      );

      // Init AdMob
      final adService = AdService();
      await adService.initialize();

      // Check permissions
      final permService = PermissionService();
      final hasPermission = await permService.hasStoragePermission();

      // Handle uncaught Flutter errors
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        // Don't rethrow — prevent crash
      };

      runApp(SmartCleanerApp(
        adService: adService,
        hasPermission: hasPermission,
      ));
    },
    (error, stack) {
      // Catch all zone errors — prevent crash
      debugPrint('Zone error: $error\n$stack');
    },
  );
}

class SmartCleanerApp extends StatelessWidget {
  final AdService adService;
  final bool hasPermission;

  const SmartCleanerApp({
    super.key,
    required this.adService,
    required this.hasPermission,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Cleaner Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: hasPermission
          ? HomeScreen(adService: adService)
          : PermissionGateScreen(adService: adService),
      builder: (context, child) {
        // Prevent text scale from breaking layouts
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: const TextScaler.linear(1.0),
          ),
          child: child!,
        );
      },
    );
  }
}
