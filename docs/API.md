# API Reference

## Base Configuration

- **Backend**: AWS Lambda via API Gateway
- **Region**: ap-south-1
- **HTTP Client**: Dio (`lib/data/services/dio_api_service.dart`)
- **Auth**: User ID passed as query parameter
- **Mock available**: `MockApiService` for offline development

## Service Interface

Defined in `lib/data/services/api_service.dart`:

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

## Endpoints

### POST `/mobile/v1/login`
- **Request**: `{ "user_id": "string" }`
- **Response**: `LoginResponse` — auth token + user role
- **Provider**: `authProvider`

### GET `/mobile/v1/home`
- **Auth**: User ID query param
- **Response**: `HomeResponse` — dashboard stats + subject summaries
- **Provider**: `userProvider`

### GET `/mobile/v1/subjects`
- **Auth**: User ID query param
- **Response**: `SubjectsResponse` — overall accuracy, subjects list, premium/teacher flags
- **Provider**: `worksheetProvider`

### GET `/mobile/v1/topics`
- **Query param**: `subject_id`
- **Response**: `TopicsResponse` — topics with progress + test list
- **Provider**: `testListProvider`

### GET `/mobile/v1/test-details`
- **Query param**: `test_id`
- **Response**: `TestDetailsResponse` — questions, timer config, pagination, pre-answered questions
- **Provider**: `quizProvider`

### POST `/mobile/v1/submit-answer`
- **Request**: `SubmitAnswerRequest` — question ID, answer, 50-50 flag
- **Response**: `AnswerResponse` — correct/incorrect + explanation
- **Provider**: `quizProvider`

### POST `/mobile/v1/submit-test`
- **Request**: `{ "test_id": "string" }`
- **Response**: `SubmitTestResponse` — final score + leaderboard entries
- **Provider**: `quizProvider`

## Data Models

### User & Auth (`lib/data/models/user_model.dart`)

```
LoginResponse
├── token: String
└── role: String

UserProfile
├── id: String
├── name: String
├── school: String
├── className: String
├── isPremium: bool
├── upPoints: int
└── initials: String (computed)
```

### Home (`lib/data/models/home_model.dart`)

```
HomeResponse
├── stats: HomeStats
│   ├── testsCompleted: int
│   ├── accuracy: double
│   └── upPoints: int
└── subjects: List<SubjectSummary>
    ├── id: String
    ├── name: String
    ├── accuracy: double
    └── topicsCompleted: int
```

### Subjects (`lib/data/models/subjects_model.dart`)

```
SubjectsResponse
├── overallAccuracy: double
├── subjects: List<SubjectSummary>
├── isPremium: bool
└── isTeacher: bool
```

### Topics (`lib/data/models/topics_model.dart`)

```
TopicsResponse
└── topics: List<Topic>
    ├── id: String
    ├── name: String
    ├── progress: double
    └── tests: List<TestInfo>
        ├── id: String
        ├── name: String
        └── status: String
```

### Quiz (`lib/data/models/quiz_model.dart`)

```
TestDetailsResponse
├── questions: List<Question>
├── timer: QuizTimer
├── pagination: Pagination
└── alreadyAnswered: List<AlreadyAnswered>

Question
├── id: String
├── text: String (may contain HTML)
├── type: String (MCQ, FILL_UP, TRUE_FALSE, INTEGER)
├── options: List<QuestionOption>?
└── solution: Solution?

QuestionOption
├── id: String
├── text: String
└── isCorrect: bool?

QuizTimer
├── durationMinutes: int
└── remainingSeconds: int?
```

### Submission (`lib/data/models/submit_model.dart`)

```
SubmitAnswerRequest
├── testId: String
├── questionId: String
├── answer: String
└── usedFiftyFifty: bool

AnswerResponse
├── isCorrect: bool
├── correctAnswer: String
└── explanation: String?

SubmitTestResponse
├── score: int
├── totalQuestions: int
├── accuracy: double
└── leaderboard: List<LeaderboardEntry>
```

## Switching Between Real & Mock API

The API implementation is injected via Riverpod in `lib/providers/auth_provider.dart`:

```dart
// To use real API:
final apiServiceProvider = Provider<ApiService>((ref) => DioApiService(userId: '...'));

// To use mock API:
final apiServiceProvider = Provider<ApiService>((ref) => MockApiService());
```
