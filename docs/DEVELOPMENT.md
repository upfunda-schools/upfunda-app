# Development Guide

## Setup

### Prerequisites
- Flutter SDK ^3.9.0
- JDK 17 (for Android builds)
- Android SDK with API 35+
- VS Code with Flutter extension (recommended)

### First-time setup

```bash
git clone git@github.com:upfunda-schools/upfunda-app.git
cd upfunda-app
flutter pub get
flutter doctor        # verify everything is configured
```

### Running

```bash
flutter run -d chrome           # Web
flutter run -d emulator-5554    # Android emulator
flutter run -d windows          # Windows desktop
flutter run                     # Default device
```

## Adding a New Feature

### 1. Create the feature folder
```
lib/features/<feature_name>/
├── <feature_name>_screen.dart
└── widgets/                     # optional, for feature-specific widgets
```

### 2. Create the screen
```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FeatureNameScreen extends ConsumerWidget {
  const FeatureNameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Feature Name')),
      body: const Center(child: Text('Feature content')),
    );
  }
}
```

### 3. Add a route
In `lib/core/router/app_router.dart`, add:
```dart
GoRoute(
  path: '/feature-name',
  builder: (context, state) => const FeatureNameScreen(),
),
```

### 4. Add a provider (if needed)
In `lib/providers/feature_name_provider.dart`:
```dart
final featureNameProvider = StateNotifierProvider<FeatureNameNotifier, FeatureNameState>((ref) {
  return FeatureNameNotifier(ref.read(apiServiceProvider));
});
```

## Adding a New Game

1. Create `lib/features/games/<game_name>_screen.dart`
2. Add a `GoRoute` in `app_router.dart` under the games section
3. Add a `_GameInfo` entry in `games_hub_screen.dart` with title, description, icon, color, and route
4. Set `comingSoon: true` if the game is not yet playable

## Adding a New API Endpoint

1. Add the method signature to `lib/data/services/api_service.dart`
2. Implement in `lib/data/services/dio_api_service.dart` (HTTP call)
3. Implement in `lib/data/services/mock_api_service.dart` (mock data)
4. Create/update models in `lib/data/models/`
5. Add mock data in `lib/data/mock/mock_data.dart` if needed
6. Create or update the relevant provider in `lib/providers/`

## Adding a New Model

Models go in `lib/data/models/`. Follow this pattern:
```dart
class MyModel {
  final String id;
  final String name;

  const MyModel({required this.id, required this.name});

  factory MyModel.fromJson(Map<String, dynamic> json) {
    return MyModel(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'name': name};
}
```

## Adding a Shared Widget

1. Create `lib/shared/widgets/<widget_name>.dart`
2. Use `const` constructor
3. Keep it generic — no feature-specific dependencies

## Testing

```bash
flutter test                          # Run all tests
flutter test test/widget_test.dart    # Run specific test
flutter test --coverage               # Generate coverage report
```

## Code Quality

```bash
flutter analyze                       # Static analysis
dart format .                         # Auto-format all files
dart fix --apply                      # Apply automated fixes
```

## Building for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# Web
flutter build web --release

# Windows
flutter build windows --release
```

## Environment Notes

- The app currently uses a hardcoded user ID in the API service provider
- Auth is simplified (no Firebase/OAuth) — uses direct user ID with SharedPreferences persistence
- Mock API can be swapped in via the `apiServiceProvider` in `auth_provider.dart`
- All games run entirely on-device with no backend integration
