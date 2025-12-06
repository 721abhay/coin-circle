# Change App Icon (Launcher Icon)

## Current Status:
- ✅ In-app logo added (splash screen)
- ❌ App icon still shows Flutter default

## To Change App Icon:

### Option 1: Use flutter_launcher_icons Package (Recommended)

1. **Add dependency to pubspec.yaml:**

```yaml
dev_dependencies:
  flutter_launcher_icons: ^0.13.1
```

2. **Add configuration to pubspec.yaml:**

```yaml
flutter_launcher_icons:
  android: true
  ios: true
  image_path: "assets/images/app_logo.png"
  adaptive_icon_background: "#FFFFFF"
  adaptive_icon_foreground: "assets/images/app_logo.png"
```

3. **Run the command:**

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

4. **Rebuild the app:**

```bash
flutter clean
flutter run
```

### Option 2: Manual Method (Android Only)

Replace these files in `android/app/src/main/res/`:

- `mipmap-mdpi/ic_launcher.png` (48x48)
- `mipmap-hdpi/ic_launcher.png` (72x72)
- `mipmap-xhdpi/ic_launcher.png` (96x96)
- `mipmap-xxhdpi/ic_launcher.png` (144x144)
- `mipmap-xxxhdpi/ic_launcher.png` (192x192)

### Quick Setup Script:

I'll create a script to set this up automatically.

## Important Notes:

1. **App icon must be square** (1024x1024 recommended)
2. **Background should be removed** or use white background
3. **Icon will be automatically resized** for different screen densities
4. **Changes require app reinstall** to see new icon

## After Setup:

1. Uninstall the app from your phone
2. Run `flutter run` again
3. New icon will appear!
