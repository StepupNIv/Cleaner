import 'package:flutter/material.dart';
import '../services/permission_service.dart';
import '../services/ad_service.dart';
import '../theme.dart';
import 'home_screen.dart';

class PermissionGateScreen extends StatefulWidget {
  final AdService adService;
  const PermissionGateScreen({super.key, required this.adService});

  @override
  State<PermissionGateScreen> createState() => _PermissionGateScreenState();
}

class _PermissionGateScreenState extends State<PermissionGateScreen> {
  final PermissionService _ps = PermissionService();
  bool _requesting = false;
  bool _denied = false;

  Future<void> _request() async {
    setState(() {
      _requesting = true;
      _denied = false;
    });
    final granted = await _ps.requestStoragePermissions();
    if (!mounted) return;
    if (granted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => HomeScreen(adService: widget.adService),
        ),
      );
    } else {
      setState(() {
        _requesting = false;
        _denied = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primary, AppTheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.security_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Storage Access\nRequired',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Smart Cleaner Pro needs access to your media\nfiles to scan for junk, duplicates and large files.',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 15,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                'No files are uploaded or shared. All operations\nrun completely on your device.',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (_denied)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppTheme.danger.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.warning_rounded,
                            color: AppTheme.danger, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Permission denied. Please grant access in Settings.',
                            style: TextStyle(
                              color: AppTheme.danger,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _requesting ? null : _request,
                  icon: _requesting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(AppTheme.bg),
                          ),
                        )
                      : const Icon(Icons.lock_open_rounded),
                  label: Text(_requesting
                      ? 'Requesting...'
                      : _denied
                          ? 'Open Settings'
                          : 'Grant Permission'),
                ),
              ),
              if (_denied)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: TextButton(
                    onPressed: () => _ps.openSettings(),
                    child: const Text(
                      'Open App Settings',
                      style: TextStyle(color: AppTheme.primary),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
