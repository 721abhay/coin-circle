# How to Add Logo to Other Screens

## Quick Reference

### Logo Already Added To:
✅ Splash Screen

### Add Logo to Login Screen:

**File**: `lib/features/auth/presentation/screens/login_screen.dart`

Find the top section (around line 50-80) and add:

```dart
// Add this at the top of the form
Center(
  child: Image.asset(
    'assets/images/app_logo.png',
    width: 120,
    height: 120,
  ),
),
const SizedBox(height: 24),
```

### Add Logo to Register Screen:

**File**: `lib/features/auth/presentation/screens/register_screen.dart`

Similar to login screen, add at the top:

```dart
Center(
  child: Image.asset(
    'assets/images/app_logo.png',
    width: 120,
    height: 120,
  ),
),
const SizedBox(height: 24),
```

### Add Small Logo to App Bar:

For any screen with an AppBar, you can add:

```dart
AppBar(
  title: Row(
    children: [
      Image.asset(
        'assets/images/app_logo.png',
        width: 32,
        height: 32,
      ),
      const SizedBox(width: 8),
      const Text('Coin Circle'),
    ],
  ),
)
```

### Circular Logo (Like Splash Screen):

```dart
Container(
  width: 100,
  height: 100,
  decoration: BoxDecoration(
    color: Colors.white,
    shape: BoxShape.circle,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 10,
        offset: const Offset(0, 5),
      ),
    ],
  ),
  child: ClipOval(
    child: Padding(
      padding: const EdgeInsets.all(15.0),
      child: Image.asset(
        'assets/images/app_logo.png',
        fit: BoxFit.contain,
      ),
    ),
  ),
)
```

### Square Logo:

```dart
Image.asset(
  'assets/images/app_logo.png',
  width: 150,
  height: 150,
  fit: BoxFit.contain,
)
```

## BoxFit Options:

- `BoxFit.contain` - Fit inside without cropping (recommended)
- `BoxFit.cover` - Fill entire space (may crop edges)
- `BoxFit.fill` - Stretch to fill (may distort)
- `BoxFit.fitWidth` - Fit width, height may overflow
- `BoxFit.fitHeight` - Fit height, width may overflow

## Common Sizes:

- **Splash Screen**: 200x200
- **Login/Register**: 120x120
- **App Bar**: 32x32 or 40x40
- **Profile/About**: 150x150
- **Small Icon**: 24x24

## To Apply Changes:

After adding logo to any screen:
1. Save the file
2. Hot reload (`r` in terminal) or Hot restart (`R` in terminal)
3. Navigate to that screen to see the logo
