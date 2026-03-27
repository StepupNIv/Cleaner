# Smart Cleaner Pro — Flutter + Kotlin

Production-ready Android storage cleaner. Real file scanning using official Android APIs. Play Store compliant.

---

## Project Structure

```
smart_cleaner_pro/
├── lib/
│   ├── main.dart                      # Entry point, crash-safety zone
│   ├── theme.dart                     # Dark theme, colors, formatBytes()
│   ├── models/
│   │   └── file_item.dart             # FileItem, DuplicateGroup, AppInfo, StorageStats
│   ├── services/
│   │   ├── cleaner_service.dart       # MethodChannel bridge (all calls)
│   │   ├── ad_service.dart            # AdMob banner / interstitial / rewarded
│   │   └── permission_service.dart    # Runtime permission requests
│   ├── screens/
│   │   ├── home_screen.dart           # Dashboard with feature grid
│   │   ├── permission_gate_screen.dart
│   │   ├── junk_cleaner_screen.dart   # Cache + temp + log scanner
│   │   ├── large_files_screen.dart    # MediaStore large file finder
│   │   ├── duplicate_finder_screen.dart # MD5 duplicate image finder
│   │   ├── storage_analyzer_screen.dart # fl_chart pie chart
│   │   └── app_manager_screen.dart   # Installed apps + uninstall
│   └── widgets/
│       └── common_widgets.dart        # BannerAdWidget, GradientCard, dialogs, etc.
│
└── android/app/src/main/
    ├── AndroidManifest.xml            # Play Store safe permissions
    ├── kotlin/com/smartcleaner/pro/
    │   ├── MainActivity.kt            # MethodChannel router
    │   ├── JunkScanner.kt             # App cache + junk extension scanner
    │   ├── LargeFileScanner.kt        # MediaStore query, files > 10 MB
    │   ├── DuplicateScanner.kt        # MD5 hashing, groups dupes
    │   ├── StorageAnalyzer.kt         # Categorized storage totals
    │   ├── AppScanner.kt              # PackageManager user apps
    │   └── FileDeleter.kt             # Safe deletion (File API + MediaStore)
    └── res/
        ├── values/styles.xml
        ├── drawable/launch_background.xml
        └── xml/network_security_config.xml
```

---

## Quick Start

### 1. Prerequisites
- Flutter 3.19+ (`flutter --version`)
- Android Studio / VS Code
- Android SDK 21+ device or emulator

### 2. Setup
```bash
cd smart_cleaner_pro
flutter pub get
```

### 3. Replace AdMob IDs
In `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-XXXXXXXXXXXXXXXX~XXXXXXXXXX" />  <!-- YOUR APP ID -->
```

In `lib/services/ad_service.dart`:
```dart
static const String _bannerAdUnitId      = 'ca-app-pub-XXXXX/XXXXX';
static const String _interstitialAdUnitId = 'ca-app-pub-XXXXX/XXXXX';
static const String _rewardedAdUnitId     = 'ca-app-pub-XXXXX/XXXXX';
```

### 4. Run
```bash
flutter run
# or for release build:
flutter build apk --release
```

---

## Permissions Used

| Permission | SDK | Purpose |
|---|---|---|
| `READ_MEDIA_IMAGES` | 33+ | Scan images for duplicates/large files |
| `READ_MEDIA_VIDEO` | 33+ | Scan videos for large files |
| `READ_MEDIA_AUDIO` | 33+ | Scan audio for large files |
| `READ_EXTERNAL_STORAGE` | ≤32 | Legacy media access |
| `WRITE_EXTERNAL_STORAGE` | ≤29 | Legacy file deletion |
| `REQUEST_DELETE_PACKAGES` | — | System uninstall intent |
| `INTERNET` | — | AdMob |

> ❌ `MANAGE_EXTERNAL_STORAGE` is NOT used — avoids Play Store rejection.

---

## AdMob Integration

| Ad Type | Trigger |
|---|---|
| Banner | Bottom of every screen |
| Interstitial | After each scan completes |
| Interstitial | After cleaning completes |
| Rewarded | "Deep Clean" (hook in JunkCleanerScreen) |

Ads never interrupt scanning or deletion. App works fully if ads fail to load.

---

## Crash-Safety Architecture

**Flutter side:**
- `runZonedGuarded` in `main()` — catches all unhandled async errors
- `FlutterError.onError` override — logs without rethrowing
- All service methods return empty list / 0 on failure
- `if (!mounted) return` guards before every `setState`

**Kotlin side:**
- Every scanner method wrapped in `try-catch`
- Per-file `try-catch` in `walkTopDown` loops
- `FileDeleter` counts successes, never throws

---

## Play Store Compliance

✅ No fake cleaning UI  
✅ No misleading "RAM Booster" claims  
✅ All deletions user-initiated with confirmation dialog  
✅ No background deletion  
✅ No `MANAGE_EXTERNAL_STORAGE`  
✅ Privacy policy included (display in-app Settings screen)

---

## Privacy Policy Text

> "Smart Cleaner Pro does not collect or share personal data. All file operations are performed locally on the device. No files are uploaded to any server."

Add this to your Play Store listing and in-app Settings screen.

---

## Production Checklist

- [ ] Replace test AdMob IDs with real IDs
- [ ] Create release keystore and update `build.gradle` signingConfig
- [ ] Set `applicationId` to your own package name
- [ ] Add app icon to `res/mipmap-*/`
- [ ] Add Lottie JSON animations to `assets/lottie/`
- [ ] Test on Android 10, 12, 13, 14
- [ ] Upload to Play Store Internal Testing first

---

## Known Limitations

1. **Duplicate images**: Hashing is limited to files ≤50 MB to prevent OOM. Very large images are skipped.
2. **Large file paths**: On Android 10+ scoped storage, `DATA` column may be empty for some files. MediaStore content URI should be used for deletion in those cases (already handled in `FileDeleter`).
3. **App sizes**: Showing exact installed app sizes requires `PACKAGE_USAGE_STATS` permission which requires user to manually grant in Settings. Currently omitted for simplicity.
