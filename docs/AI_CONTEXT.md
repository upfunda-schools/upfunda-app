# Project Context for AI Agents

This file provides structured context for AI coding agents working on the Upfunda App codebase.

## Quick Facts

| Key | Value |
|---|---|
| **Project** | Upfunda Education Platform — Student App |
| **Framework** | Flutter (Dart) |
| **SDK** | ^3.9.0 |
| **State Management** | Riverpod (StateNotifier pattern) |
| **Routing** | GoRouter with auth guards |
| **HTTP Client** | Dio |
| **Backend** | AWS Lambda (API Gateway, ap-south-1) |
| **Design System** | Material 3 with Montserrat font |
| **Auth** | Firebase Auth (email + password) |
| **Env Config** | `.env` via `flutter_dotenv` |
| **Package** | `com.upfunda.upfunda_app` |

## File Map — Where Things Live

| What you need | Where to find it |
|---|---|
| App entry point | `lib/main.dart` |
| Root widget & router setup | `lib/app.dart` |
| Route definitions | `lib/core/router/app_router.dart` |
| Theme & colors | `lib/core/theme/app_theme.dart`, `app_colors.dart` |
| Input validators | `lib/core/utils/validators.dart` |
| Environment config | `lib/core/utils/env_config.dart` |
| Firebase auth service | `lib/data/services/firebase_auth_service.dart` |
| Firebase options | `lib/firebase_options.dart` |
| API interface | `lib/data/services/api_service.dart` |
| Real API implementation | `lib/data/services/dio_api_service.dart` |
| Mock API implementation | `lib/data/services/mock_api_service.dart` |
| Mock data | `lib/data/mock/mock_data.dart` |
| Data models | `lib/data/models/*.dart` |
| Auth state | `lib/providers/auth_provider.dart` |
| User/profile state | `lib/providers/user_provider.dart` |
| Quiz state | `lib/providers/quiz_provider.dart` |
| Worksheet state | `lib/providers/worksheet_provider.dart` |
| Topic/test list state | `lib/providers/test_list_provider.dart` |
| Login screen | `lib/features/auth/login_screen.dart` |
| Home dashboard | `lib/features/student_home/student_home_screen.dart` |
| Profile screen | `lib/features/profile/profile_screen.dart` |
| Subject list | `lib/features/worksheets/worksheets_screen.dart` |
| Topic/test list | `lib/features/worksheets/worksheet_list_screen.dart` |
| Quiz engine | `lib/features/quiz/quiz_screen.dart` |
| Quiz widgets | `lib/features/quiz/widgets/*.dart` |
| Games hub | `lib/features/games/games_hub_screen.dart` |
| Individual games | `lib/features/games/*_screen.dart` |
| Shared widgets | `lib/shared/widgets/*.dart` |
| Android config | `android/app/build.gradle.kts` |
| Android settings | `android/settings.gradle.kts` |
| Pubspec | `pubspec.yaml` |
| Lint rules | `analysis_options.yaml` |

## Common Tasks & Patterns

### Creating a screen
- Extend `ConsumerWidget` or `ConsumerStatefulWidget`
- Place in `lib/features/<feature>/<feature>_screen.dart`
- Use `ref.watch()` for reactive state, `ref.read()` for one-time actions
- Add route in `lib/core/router/app_router.dart`

### Working with state
- State lives in `lib/providers/` as `StateNotifierProvider`
- Each provider has a `Notifier` class and a `State` class
- Notifiers take `ApiService` and call its methods
- State is immutable with loading/loaded/error patterns

### Adding API endpoints
1. Add method to `ApiService` interface
2. Implement in `DioApiService` (real HTTP)
3. Implement in `MockApiService` (return mock data)
4. Create model in `lib/data/models/`

### Working with the quiz
- Quiz state machine is in `lib/providers/quiz_provider.dart`
- Handles: initialization, answer selection, timer, 50-50, pagination, submission
- Question types: MCQ, FILL_UP, TRUE_FALSE, INTEGER
- Questions may contain HTML (rendered with `flutter_html`)

### Working with games
- All games are self-contained screens in `lib/features/games/`
- Games run entirely on-device (no backend calls)
- Register games in `games_hub_screen.dart` via `_GameInfo` objects
- Use `comingSoon: true` for placeholder entries

## Important Conventions

1. **snake_case** for file names, **PascalCase** for classes
2. Screens end with `Screen`, providers end with `Provider`, notifiers end with `Notifier`
3. All navigation uses GoRouter (`context.push()`, `context.go()`)
4. Models use `factory fromJson()` constructors
5. Use `const` constructors wherever possible
6. Feature-specific widgets go in `features/<feature>/widgets/`
7. Cross-feature widgets go in `shared/widgets/`

## Docs Index

| Document | Purpose |
|---|---|
| [ARCHITECTURE.md](ARCHITECTURE.md) | System architecture, layers, provider graph |
| [CONVENTIONS.md](CONVENTIONS.md) | Coding standards, naming, file structure rules |
| [FEATURES.md](FEATURES.md) | All features, screens, and games catalog |
| [API.md](API.md) | API endpoints, models, request/response schemas |
| [FIREBASE_AUTH.md](FIREBASE_AUTH.md) | Firebase Auth integration guide, auth flow, env setup |
| [DEVELOPMENT.md](DEVELOPMENT.md) | How to add features, models, tests, build releases |
