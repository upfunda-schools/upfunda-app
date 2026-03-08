import '../models/user_model.dart';
import '../models/home_model.dart';
import '../models/subjects_model.dart';
import '../models/topics_model.dart';
import '../models/quiz_model.dart';
import '../models/submit_model.dart';

class MockData {
  MockData._();

  static final loginResponse = LoginResponse(
    customToken: 'mock-firebase-token-abc123',
    role: 'student',
  );

  static final userProfile = UserProfile(
    id: 'user-001',
    email: 'arjun@upfunda.com',
    role: 'student',
    name: 'Arjun Sharma',
    schoolName: 'Delhi Public School',
    gender: 'male',
    className: 'Grade 6',
    sectionName: 'A',
    upPoints: 1250,
    classId: 'class-001',
    schoolId: 'school-001',
    studentId: 'student-001',
    phone: '+919876543210',
    country: 'India',
    isPremiumUser: true,
  );

  static final homeResponse = HomeResponse(
    studentName: 'Arjun',
    studentId: 'student-001',
    schoolId: 'school-001',
    sectionId: 'section-001',
    upPoints: 1250,
    isPremiumUser: true,
    stats: HomeStats(
      overallAccuracy: 78.5,
      totalWorksheets: 48,
      solvedWorksheets: 32,
      pendingWorksheets: 16,
    ),
    subjects: _subjects,
  );

  static final List<SubjectSummary> _subjects = [
    SubjectSummary(
      subjectId: 'sub-001',
      name: 'Academic Math',
      solved: 15,
      open: 5,
      completedPercentage: 75,
    ),
    SubjectSummary(
      subjectId: 'sub-002',
      name: 'Mental Math',
      solved: 8,
      open: 4,
      completedPercentage: 66,
    ),
    SubjectSummary(
      subjectId: 'sub-003',
      name: 'Olympiad Math',
      solved: 5,
      open: 7,
      completedPercentage: 42,
    ),
    SubjectSummary(
      subjectId: 'sub-004',
      name: 'Logical Reasoning',
      solved: 4,
      open: 8,
      completedPercentage: 33,
    ),
  ];

  static final subjectsResponse = SubjectsResponse(
    overallAccuracy: 78.5,
    pendingWorksheets: 16,
    subjects: _subjects,
    hasTeacher: true,
    isPremiumUser: true,
  );

  static final topicsResponse = TopicsResponse(
    subjectId: 'sub-001',
    subjectName: 'Academic Math',
    teacherGated: false,
    topics: [
      Topic(
        topicId: 'topic-001',
        name: 'Fractions',
        isPremium: false,
        status: 'completed',
        progressPercentage: 100,
        tests: [
          TestInfo(testId: 'test-001', level: 1, status: 'completed'),
          TestInfo(testId: 'test-002', level: 2, status: 'completed'),
        ],
      ),
      Topic(
        topicId: 'topic-002',
        name: 'Decimals',
        isPremium: false,
        status: 'in_progress',
        progressPercentage: 50,
        tests: [
          TestInfo(testId: 'test-003', level: 1, status: 'completed'),
          TestInfo(testId: 'test-004', level: 2, status: 'not_started'),
        ],
      ),
      Topic(
        topicId: 'topic-003',
        name: 'Percentages',
        isPremium: false,
        status: 'not_started',
        progressPercentage: 0,
        tests: [
          TestInfo(testId: 'test-005', level: 1, status: 'not_started'),
          TestInfo(testId: 'test-006', level: 2, status: 'not_started'),
        ],
      ),
      Topic(
        topicId: 'topic-004',
        name: 'Algebra Basics',
        isPremium: true,
        status: 'not_started',
        progressPercentage: 0,
        tests: [
          TestInfo(testId: 'test-007', level: 1, status: 'not_started'),
        ],
      ),
      Topic(
        topicId: 'topic-005',
        name: 'Geometry',
        isPremium: false,
        status: 'in_progress',
        progressPercentage: 33,
        tests: [
          TestInfo(testId: 'test-008', level: 1, status: 'completed'),
          TestInfo(testId: 'test-009', level: 2, status: 'not_started'),
          TestInfo(testId: 'test-010', level: 3, status: 'not_started'),
        ],
      ),
    ],
  );

  static final testDetailsResponse = TestDetailsResponse(
    testId: 'test-005',
    testName: 'Percentages Level 1',
    durationSeconds: 600,
    timer: QuizTimer(
      remainingSeconds: 600,
      isPaused: false,
      totalPausedSeconds: 0,
    ),
    questions: [
      Question(
        questionId: 'q-001',
        text: '<p>What is <strong>25%</strong> of 200?</p>',
        type: 'MCQ',
        options: [
          QuestionOption(optionId: 'opt-001a', text: '25'),
          QuestionOption(optionId: 'opt-001b', text: '50'),
          QuestionOption(optionId: 'opt-001c', text: '75'),
          QuestionOption(optionId: 'opt-001d', text: '100'),
        ],
        solution: Solution(
          answer: '50',
          explanation: '25% of 200 = (25/100) × 200 = 50',
          correctOptionId: 'opt-001b',
        ),
      ),
      Question(
        questionId: 'q-002',
        text: '<p>Convert <strong>3/4</strong> to a percentage.</p>',
        type: 'MCQ',
        options: [
          QuestionOption(optionId: 'opt-002a', text: '25%'),
          QuestionOption(optionId: 'opt-002b', text: '50%'),
          QuestionOption(optionId: 'opt-002c', text: '75%'),
          QuestionOption(optionId: 'opt-002d', text: '80%'),
        ],
        solution: Solution(
          answer: '75%',
          explanation: '3/4 = 0.75 = 75%',
          correctOptionId: 'opt-002c',
        ),
      ),
      Question(
        questionId: 'q-003',
        text: '<p>A shirt costs ₹800. If there is a 15% discount, what is the selling price?</p>',
        type: 'FILL_UP',
        options: [],
        solution: Solution(
          answer: '680',
          explanation: 'Discount = 15% of 800 = 120. Selling price = 800 - 120 = 680',
          correctOptionId: null,
        ),
      ),
      Question(
        questionId: 'q-004',
        text: '<p>True or False: 50% of a number is always equal to half of that number.</p>',
        type: 'TRUE_FALSE',
        options: [
          QuestionOption(optionId: 'opt-004a', text: 'True'),
          QuestionOption(optionId: 'opt-004b', text: 'False'),
        ],
        solution: Solution(
          answer: 'True',
          explanation: '50% means 50/100 = 1/2, which is half.',
          correctOptionId: 'opt-004a',
        ),
      ),
      Question(
        questionId: 'q-005',
        text: '<p>If 40% of a number is 60, what is the number?</p>',
        type: 'INTEGER',
        options: [],
        solution: Solution(
          answer: '150',
          explanation: 'Let the number be x. 40% of x = 60 → 0.4x = 60 → x = 150',
          correctOptionId: null,
        ),
      ),
    ],
    alreadyAnswered: [],
    pagination: Pagination(
      currentPage: 1,
      pageSize: 10,
      totalQuestions: 5,
      totalPages: 1,
      hasNext: false,
      hasPrevious: false,
    ),
  );

  static final submitTestResponse = SubmitTestResponse(
    correctCount: 4,
    totalCount: 5,
    score: 80,
    leaderboard: [
      LeaderboardEntry(rank: 1, studentName: 'Priya M.', studentId: 's-002', score: 100),
      LeaderboardEntry(rank: 2, studentName: 'Arjun S.', studentId: 'student-001', score: 80),
      LeaderboardEntry(rank: 3, studentName: 'Rohan K.', studentId: 's-003', score: 60),
    ],
  );

  static final answerResponse = AnswerResponse(status: 'submitted');
}
