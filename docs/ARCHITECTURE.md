# Architecture

## Overview

Upfunda App is a Flutter mobile education platform using a **feature-based architecture** with Riverpod for state management and GoRouter for navigation.

## Architecture Pattern

```
UI (Screens/Widgets)
    ↓ watches/reads
Providers (Riverpod StateNotifiers)
    ↓ calls
Services (ApiService interface)
    ↓ implements
DioApiService (HTTP) / MockApiService (mock data)
    ↓
Backend API (AWS Lambda)
```

### Layers

| Layer | Location | Responsibility |
|---|---|---|
| **UI** | `lib/features/` | Screens and widgets, consumes providers |
| **State** | `lib/providers/` | Business logic, Riverpod StateNotifiers |
| **Data** | `lib/data/services/` | API abstraction, HTTP calls via Dio |
| **Models** | `lib/data/models/` | JSON-serializable data classes |
| **Core** | `lib/core/` | Router, theme, validators |
| **Shared** | `lib/shared/` | Reusable widgets |

## State Management — Riverpod

All state is managed through Riverpod `StateNotifierProvider`s. The app is wrapped in a `ProviderScope` at the root (`main.dart`).

### Provider Dependency Graph

```
apiServiceProvider (Provider<ApiService>)
    ↑ used by
authProvider (StateNotifierProvider<AuthNotifier, AuthState>)
    ↑ watched by
routerProvider (Provider<GoRouter>)  ← auth redirect logic

userProvider (StateNotifierProvider<UserNotifier, UserState>)
    ↑ uses apiServiceProvider

quizProvider (StateNotifierProvider<QuizNotifier, QuizState>)
    ↑ uses apiServiceProvider

worksheetProvider (StateNotifierProvider<WorksheetNotifier, WorksheetState>)
    ↑ uses apiServiceProvider

testListProvider (StateNotifierProvider<TestListNotifier, TestListState>)
    ↑ uses apiServiceProvider
```

## Routing — GoRouter

Defined in `lib/core/router/app_router.dart`. Uses auth-based redirect:
- Unauthenticated users → `/login`
- Authenticated users visiting `/login` → `/student-home`

### Route Map

| Route | Screen | Parameters |
|---|---|---|
| `/login` | `LoginScreen` | — |
| `/student-home` | `StudentHomeScreen` | — |
| `/profile` | `ProfileScreen` | — |
| `/worksheets` | `WorksheetsScreen` | — |
| `/worksheets-list/:id` | `WorksheetListScreen` | `subjectId` (path param) |
| `/quiz/:id` | `QuizScreen` | `testId` (path param) |
| `/games` | `GamesHubScreen` | — |
| `/games/<game-name>` | Individual game screens | — (34 game routes) |

## API Layer

### Interface: `ApiService` (abstract)

```dart
abstract class ApiService {
  Future<LoginResponse> login(String userId);
  Future<HomeResponse> getHome();
  Future<SubjectsResponse> getSubjects();
  Future<TopicsResponse> getTopics(String subjectId);
  Future<TestDetailsResponse> getTestDetails(String testId);
  Future<AnswerResponse> submitAnswer(SubmitAnswerRequest request);
  Future<SubmitTestResponse> submitTest(String testId);
}
```

### Implementations

- **`DioApiService`**: Real HTTP calls to AWS Lambda backend
- **`MockApiService`**: Returns mock data with artificial delays for offline dev

### Backend

- **Base URL**: AWS Lambda via API Gateway (ap-south-1)
- **Endpoints**: Under `/mobile/v1/`
- **Auth**: User ID passed as query parameter (simplified auth)

## Theme

- **Design system**: Material 3
- **Primary font**: Montserrat (via `google_fonts`)
- **Colors**: Defined in `app_colors.dart` — brand colors, quiz palettes, answer states
- **Custom themes**: Button, input, AppBar, card component themes in `app_theme.dart`

## Data Models

| Model | File | Key Fields |
|---|---|---|
| `LoginResponse` | `user_model.dart` | token, role |
| `UserProfile` | `user_model.dart` | name, school, class, premium, UP points |
| `HomeResponse` | `home_model.dart` | stats, subject summaries |
| `SubjectsResponse` | `subjects_model.dart` | accuracy, subjects list |
| `TopicsResponse` | `topics_model.dart` | topics with progress, test list |
| `TestDetailsResponse` | `quiz_model.dart` | questions, timer, pagination |
| `Question` | `quiz_model.dart` | Supports MCQ, FILL_UP, TRUE_FALSE, INTEGER |
| `SubmitAnswerRequest` | `submit_model.dart` | Answer with 50-50 tracking |
| `SubmitTestResponse` | `submit_model.dart` | Score + leaderboard |
