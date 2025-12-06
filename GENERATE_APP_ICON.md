# Generate App Icon - Step by Step

## What This Does:
Changes your app icon from the Flutter default to your Win Pool logo.

## Steps to Follow:

### Step 1: Get Dependencies
```bash
flutter pub get
```

### Step 2: Generate Icons
```bash
flutter pub run flutter_launcher_icons
```

### Step 3: Clean Build
```bash
flutter clean
```

### Step 4: Uninstall Old App
**IMPORTANT**: You must uninstall the old app from your phone first!
- Go to your phone settings
- Find "Coin Circle" app
- Uninstall it

### Step 5: Install with New Icon
```bash
flutter run
```

## Expected Output:

When you run `flutter pub run flutter_launcher_icons`, you should see:

```
Creating default icons Android
Creating adaptive icons Android
Overwriting default iOS launcher icon with new icon
```

## Result:

After reinstalling, your app icon will show the Win Pool logo instead of the Flutter default!

## Troubleshooting:

### If icon doesn't change:
1. Make sure you uninstalled the old app completely
2. Run `flutter clean`
3. Run `flutter run` again

### If you get errors:
1. Check that `assets/images/app_logo.png` exists
2. Make sure the image is a valid PNG file
3. Try running `flutter pub get` again

## Files Modified:

- `pubspec.yaml` - Added flutter_launcher_icons package and configuration
- Android icon files will be auto-generated in `android/app/src/main/res/mipmap-*/`
- iOS icon files will be auto-generated in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
