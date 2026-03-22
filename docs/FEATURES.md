# Features Reference

## Auth (`lib/features/auth/`)

### LoginScreen
- Phone/email login with country code picker
- Validates input via `validators.dart`
- Calls `authProvider.login()` → persists token via SharedPreferences
- Redirects to `/student-home` on success

## Student Home (`lib/features/student_home/`)

### StudentHomeScreen
- Dashboard showing:
  - Student stats (accuracy, tests taken, UP points)
  - Subject grid with progress per subject
  - Navigation to profile, worksheets, games
- Loads data via `userProvider`

## Profile (`lib/features/profile/`)

### ProfileScreen
- Displays user profile (name, school, class, premium status)
- Gradient background with avatar showing initials
- Logout functionality via `authProvider`

## Worksheets (`lib/features/worksheets/`)

### WorksheetsScreen
- Lists all subjects with progress bars
- Each subject shows accuracy percentage
- Taps navigate to `/worksheets-list/:subjectId`
- Data from `worksheetProvider`

### WorksheetListScreen
- Shows topics for a specific subject
- Each topic lists available tests with status
- Search/filter functionality
- Taps navigate to `/quiz/:testId`
- Data from `testListProvider`

## Quiz (`lib/features/quiz/`)

### QuizScreen
Full quiz engine supporting:
- **Question types**: MCQ, FILL_UP, TRUE_FALSE, INTEGER
- **Timer**: Countdown with auto-submit on expiry
- **50-50 lifeline**: Removes two wrong options
- **Pagination**: Navigate between questions
- **Question status**: Answered, unanswered, marked for review
- **Submit flow**: Confirmation dialog → score + leaderboard

### Quiz Widgets (`lib/features/quiz/widgets/`)

| Widget | Purpose |
|---|---|
| `QuestionCard` | Renders question text (supports HTML via flutter_html) |
| `OptionTile` | MCQ option with selection states and answer colors |
| `FillUpInput` | Text input for fill-in-the-blank questions |
| `QuizTimer` | Countdown timer display |
| `NavigationButtons` | Previous/Next/Submit buttons |
| `StatusLegend` | Color legend for question states |
| `SubmissionDialog` | Pre-submit confirmation with stats |
| `ExitDialog` | Confirm quiz exit |
| `TimeUpDialog` | Auto-submit notification |

## Games (`lib/features/games/`)

### GamesHubScreen
- Grid of game cards with icons, descriptions, and colors
- Routes to individual game screens
- Some games marked as "coming soon"

### Game Categories

#### Arithmetic & Number Operations
| Game | File | Description |
|---|---|---|
| Master Arithmetic | `master_arithmetic_screen.dart` | +−×÷ practice across operations |
| Doubles Addition | `doubles_addition_screen.dart` | Adding doubles drill |
| Near Doubles | `near_doubles_screen.dart` | Near-doubles strategy practice |
| Making Tens | `making_tens_screen.dart` | Making 10 combinations |
| Making Next Ten | `making_next_ten_screen.dart` | Bridging to next ten strategy |
| Two-Digit Addition | `two_digit_addition_screen.dart` | 2-digit addition practice |
| Doubles Subtraction | `doubles_subtraction_screen.dart` | Doubles subtraction drill |
| Two-Digit Subtraction | `two_digit_subtraction_screen.dart` | 2-digit subtraction practice |
| Multiplication Tables | `multiplication_tables_screen.dart` | Times tables practice |
| Skip Counting | `skip_counting_screen.dart` | Skip counting sequences |
| Doubles & Halves | `doubles_halves_screen.dart` | Doubling and halving |
| Division | `division_screen.dart` | Division practice |
| Race to Finish | `race_to_finish_screen.dart` | Arithmetic racing game |
| Tug of War | `tug_of_war_screen.dart` | Math tug of war vs AI |

#### Number Puzzles & Logic
| Game | File | Description |
|---|---|---|
| 2048 | `game_2048_screen.dart` | Classic 2048 sliding puzzle |
| Sudoku | `sudoku_screen.dart` | Sudoku number puzzle |
| 75 | `seventy_five_screen.dart` | Reach the target number |
| What Comes Next | `what_comes_next_screen.dart` | Pattern recognition sequences |
| Number Detective | `number_detective_screen.dart` | Number deduction puzzle |
| Balance Numbers | `balance_numbers_screen.dart` | Number balancing equations |
| Find Missing Numbers | `find_missing_numbers_screen.dart` | Fill in the missing number |

#### Geometry & Symmetry
| Game | File | Description |
|---|---|---|
| Four Shapes | `four_shapes_screen.dart` | Geometry shape identification |
| Water Reflections | `water_reflections_screen.dart` | Symmetry via reflections |
| Mirror Images | `mirror_images_screen.dart` | Mirror/reflection symmetry |
| Lines of Symmetry | `lines_of_symmetry_screen.dart` | Identify lines of symmetry |

#### Words & Language
| Game | File | Description |
|---|---|---|
| Wordle | `wordle_screen.dart` | Word guessing game |
| Word Scramble | `word_scramble_screen.dart` | Unscramble words |

#### Money & Financial Literacy
| Game | File | Description |
|---|---|---|
| Lemonade Stand | `lemonade_stand_screen.dart` | Business/money simulation |
| Money Exchanger | `money_exchanger_screen.dart` | Currency conversion game |
| Saving vs Borrowing | `saving_vs_borrowing_screen.dart` | Interest & saving concepts |

#### Time
| Game | File | Description |
|---|---|---|
| Set Time | `set_time_screen.dart` | Set clock hands game |
| Read Time | `read_time_screen.dart` | Read clock time game |
| Time Conversion | `time_conversion_screen.dart` | Convert between time units |

#### Memory
| Game | File | Description |
|---|---|---|
| Memory Matching | `memory_matching_screen.dart` | Card matching memory game |
