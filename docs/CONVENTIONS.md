# Coding Conventions

## Language & Framework

- **Dart** with **Flutter** (SDK ^3.9.0)
- **Material 3** design system
- Strict analysis via `flutter_lints`

## File & Folder Naming

- All Dart files use **snake_case**: `student_home_screen.dart`, `quiz_provider.dart`
- Feature folders are **lowercase with underscores**: `student_home/`, `games/`
- Widget files match their class name in snake_case: `AppButton` → `app_button.dart`

## Class Naming

- **Screens**: `PascalCase` + `Screen` suffix: `LoginScreen`, `QuizScreen`
- **Widgets**: `PascalCase`: `AppButton`, `QuestionCard`, `OptionTile`
- **Models**: `PascalCase` + descriptive suffix: `LoginResponse`, `UserProfile`, `HomeStats`
- **Providers**: `camelCase` + `Provider` suffix: `authProvider`, `quizProvider`
- **StateNotifiers**: `PascalCase` + `Notifier` suffix: `AuthNotifier`, `QuizNotifier`
- **Services**: `PascalCase` + `Service` suffix: `ApiService`, `DioApiService`
- **Private classes**: Prefixed with `_`: `_GameInfo`, `_QuizState`

## Project Structure Convention

```
lib/
├── main.dart              # Entry point only
├── app.dart               # Root widget only
├── core/                  # Framework-level code (router, theme, utils)
├── data/
│   ├── models/            # Plain data classes with fromJson/toJson
│   ├── services/          # API layer (abstract + implementations)
│   └── mock/              # Mock data for development
├── providers/             # Riverpod providers (one file per domain)
├── features/              # Feature modules (one folder per feature)
│   └── <feature>/
│       ├── <feature>_screen.dart
│       └── widgets/       # Feature-specific widgets (optional)
└── shared/
    └── widgets/           # Reusable widgets across features
```

## State Management Rules

- Use `StateNotifierProvider` for stateful business logic
- One provider file per domain (auth, user, quiz, etc.)
- State classes are immutable with `copyWith` pattern
- Providers depend on `apiServiceProvider` for data fetching
- UI reads providers with `ref.watch()` and calls methods with `ref.read()`

## Widget Rules

- Screens are `ConsumerWidget` or `ConsumerStatefulWidget` (Riverpod)
- Shared widgets go in `lib/shared/widgets/`
- Feature-specific widgets go in `lib/features/<feature>/widgets/`
- Use `const` constructors wherever possible
- Prefer composition over inheritance for widget reuse

## Routing Rules

- All routes defined in `lib/core/router/app_router.dart`
- Use `context.push()` / `context.go()` for navigation
- Path parameters for IDs: `/quiz/:id`, `/worksheets-list/:id`
- Auth guard redirects handled in router config, not in widgets

## API & Model Rules

- All models have `factory fromJson(Map<String, dynamic> json)` constructors
- API service is abstracted behind `ApiService` interface
- Real implementation uses Dio; mock uses static data
- Provider is swapped at the provider level, not in UI code

## Style & Formatting

- Run `flutter analyze` before committing — zero warnings expected
- Run `dart format .` to auto-format all files
- Maximum line length: default Dart formatter rules
- Trailing commas encouraged for multi-line parameters
- Use cascading notation (`..`) for multiple method calls on same object
