# Upfunda App

**Upfunda Education Platform — Student App**

A Flutter-based mobile education platform for students featuring interactive worksheets, quizzes, and 35+ educational math/logic games. Built with Riverpod for state management and GoRouter for navigation.

## Prerequisites

| Dependency | Minimum Version | Notes |
|---|---|---|
| **Flutter SDK** | `^3.9.0` | [Install Flutter](https://docs.flutter.dev/get-started/install) |
| **Dart SDK** | Included with Flutter | Bundled with the Flutter SDK |
| **JDK** | 17 | Required for Android builds. [Microsoft OpenJDK 17](https://learn.microsoft.com/en-us/java/openjdk/download#openjdk-17) recommended |
| **Android SDK** | API 35+ | Install via Android Studio or [command-line tools](https://developer.android.com/studio#command-tools) |
| **Git** | Any recent version | [Download Git](https://git-scm.com/downloads) |
| **VS Code** (optional) | Latest | With [Flutter extension](https://marketplace.visualstudio.com/items?itemName=Dart-Code.flutter) |

### Platform-specific

- **Android**: Android SDK with platform-tools, build-tools 35, NDK 28+, emulator + system image
- **iOS**: Xcode 15+ and CocoaPods (macOS only)
- **Web**: Chrome or Edge browser
- **Windows desktop**: Visual Studio with "Desktop development with C++" workload

## Getting Started

### 1. Clone the repository

```bash
git clone git@github.com:upfunda-schools/upfunda-app.git
cd upfunda-app
```

### 2. Set up environment variables

Copy the example environment file and fill in your values:

```bash
cp .env.example .env
```

Edit `.env` with your Firebase project keys and API URL. Get the Firebase values from [Firebase Console](https://console.firebase.google.com/) → Project Settings → General.

See [docs/FIREBASE_AUTH.md](docs/FIREBASE_AUTH.md) for details on where each value comes from.

### 3. Install dependencies

```bash
flutter pub get
```

### 4. (Optional) Configure native Firebase

For Android/iOS development, run FlutterFire CLI to generate native config files:

```bash
dart pub global activate flutterfire_cli
flutterfire configure --project=upfuna-academy
```

This generates `google-services.json` (Android) and `GoogleService-Info.plist` (iOS). These files are gitignored.

### 5. Verify your setup

```bash
flutter doctor
```

Resolve any issues reported by `flutter doctor` before proceeding.

### 6. Run the app

**Android emulator:**
```bash
# List available emulators
flutter emulators

# Launch an emulator
flutter emulators --launch <emulator_id>

# Run the app
flutter run -d emulator-5554
```

**Chrome (web):**
```bash
flutter run -d chrome
```

**Windows desktop:**
```bash
flutter run -d windows
```

**Connected physical device:**
```bash
flutter devices          # List connected devices
flutter run -d <device>  # Run on a specific device
```

### 7. Development commands

```bash
# Hot reload (while app is running)
r

# Hot restart
R

# Run tests
flutter test

# Analyze code
flutter analyze

# Build release APK
flutter build apk --release

# Build release app bundle
flutter build appbundle --release
```

## Project Structure

```
lib/
├── main.dart                  # App entry point (ProviderScope)
├── app.dart                   # MaterialApp.router with theme + GoRouter
├── core/
│   ├── router/
│   │   └── app_router.dart    # GoRouter config with 40+ routes & auth guard
│   ├── theme/
│   │   ├── app_theme.dart     # Material3 theme (Montserrat, custom component themes)
│   │   └── app_colors.dart    # Brand colors & palettes
│   └── utils/
│       └── validators.dart    # Input validators (email, phone, password)
├── data/
│   ├── mock/
│   │   └── mock_data.dart     # Mock data for offline development
│   ├── models/                # Data models (user, home, subjects, quiz, etc.)
│   └── services/
│       ├── api_service.dart       # Abstract API interface
│       ├── dio_api_service.dart   # Real HTTP implementation (Dio)
│       └── mock_api_service.dart  # Mock implementation with delays
├── providers/                 # Riverpod state providers
│   ├── auth_provider.dart     # Auth state + persistence
│   ├── user_provider.dart     # User profile & home data
│   ├── quiz_provider.dart     # Quiz lifecycle (timer, answers, 50-50, submit)
│   ├── worksheet_provider.dart # Subjects list
│   └── test_list_provider.dart # Topics per subject with search
├── features/
│   ├── auth/                  # Login screen
│   ├── student_home/          # Dashboard with stats & subject grid
│   ├── profile/               # User profile
│   ├── worksheets/            # Subject list & topic/test browser
│   ├── quiz/                  # Quiz engine with MCQ, fill-up, timer, 50-50
│   │   └── widgets/           # Quiz UI components
│   └── games/                 # 35 educational games (math, logic, words, time)
└── shared/
    └── widgets/               # Reusable UI components (buttons, cards, loaders)
```

## Key Dependencies

| Package | Purpose |
|---|---|
| `flutter_riverpod` | State management (StateNotifier pattern) |
| `go_router` | Declarative routing with auth guards |
| `dio` | HTTP client for API calls |
| `google_fonts` | Montserrat typography |
| `shimmer` | Skeleton loading effects |
| `flutter_animate` | UI animations |
| `percent_indicator` | Progress indicators |
| `fl_chart` | Charts for stats display |
| `flutter_html` | Render HTML content in quiz questions |
| `firebase_core` | Firebase initialization |
| `firebase_auth` | Firebase Authentication (email/password) |
| `flutter_dotenv` | Load environment variables from `.env` |
| `shared_preferences` | Local data persistence |
| `audioplayers` | Sound effects for games |

## Android Build Info

| Setting | Value |
|---|---|
| Namespace | `com.upfunda.upfunda_app` |
| Android Gradle Plugin | 8.9.1 |
| Kotlin | 2.1.0 |
| Java compatibility | Java 11 |
| AndroidX | Enabled |
