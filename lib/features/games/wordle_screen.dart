import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Constants & Word Lists
// ─────────────────────────────────────────────────────────────────────────────

const _targetWords = [
  'APPLE', 'BREAD', 'CHAIR', 'DANCE', 'EARTH', 'FAIRY', 'GRAPE', 'HAPPY',
  'JUICE', 'LAUGH', 'MAGIC', 'OCEAN', 'PEACE', 'QUEEN', 'RIVER', 'SMILE',
  'TIGER', 'UNDER', 'WATER', 'YOUNG', 'BEACH', 'CLOCK', 'DREAM', 'FLAME',
  'GIANT', 'HORSE', 'LIGHT', 'MOUSE', 'NIGHT', 'PLANT', 'QUICK', 'STORM',
  'TABLE', 'UNCLE', 'VOICE', 'WHALE', 'BRAVE', 'CROWN', 'FIELD', 'GRASS',
  'HEART', 'JELLY', 'LEMON', 'MUSIC', 'NORTH', 'PARTY', 'ROUND', 'SLEEP',
  'SWEET', 'TRAIN', 'WORLD', 'BRAIN', 'CHIEF', 'DOING', 'EIGHT', 'FLOUR',
  'GREEN', 'HOUSE', 'JEWEL', 'KNIFE', 'LUNCH', 'MONEY', 'NEVER', 'PAINT',
  'ROBOT', 'SHAPE', 'THINK', 'TRUTH', 'WATCH', 'YOUTH', 'CLOUD', 'FRESH',
];

const _extraValidWords = [
  'ABOUT', 'ABOVE', 'ABUSE', 'ACTOR', 'ACUTE', 'ADMIT', 'ADOPT', 'ADULT',
  'AFTER', 'AGAIN', 'AGENT', 'AGREE', 'AHEAD', 'ALARM', 'ALBUM', 'ALERT',
  'ALIKE', 'ALIVE', 'ALLEY', 'ALLOW', 'ALOFT', 'ALONE', 'ALONG', 'ALOUD',
  'ALTAR', 'ALTER', 'AMBER', 'AMEND', 'ANGEL', 'ANGLE', 'ANGRY', 'ANIME',
  'ANNEX', 'APART', 'APHID', 'APRIL', 'APRON', 'ARGUE', 'ARISE', 'ARMOR',
  'AROMA', 'AROSE', 'ARROW', 'ASIDE', 'ASKED', 'ATLAS', 'ATTIC', 'AUDIO',
  'AUDIT', 'AUNTS', 'AVOID', 'AWARD', 'AWARE', 'AWFUL', 'BASIC', 'BASIN',
  'BASIS', 'BATCH', 'BEGAN', 'BEGIN', 'BEING', 'BELOW', 'BENCH', 'BIRTH',
  'BISON', 'BITES', 'BLACK', 'BLADE', 'BLAME', 'BLAND', 'BLANK', 'BLAST',
  'BLAZE', 'BLEED', 'BLEND', 'BLESS', 'BLIND', 'BLOCK', 'BLOOD', 'BLOWN',
  'BLUES', 'BLUNT', 'BLUSH', 'BOARD', 'BOOST', 'BOOTS', 'BOTCH', 'BOUND',
  'BOXER', 'BRIDE', 'BRIEF', 'BRING', 'BRISK', 'BROAD', 'BROKE', 'BROOK',
  'BROWN', 'BRUSH', 'BRUTE', 'BUILD', 'BUILT', 'BUNCH', 'BURNS', 'BURST',
  'BUYER', 'CABIN', 'CAMEL', 'CANDY', 'CARGO', 'CARRY', 'CATCH', 'CAUSE',
  'CAVES', 'CEDAR', 'CELLS', 'CHAIN', 'CHALK', 'CHAOS', 'CHARM', 'CHART',
  'CHASE', 'CHEAP', 'CHECK', 'CHEEK', 'CHEER', 'CHESS', 'CHICK', 'CHILD',
  'CHINA', 'CHIPS', 'CHORD', 'CHOSE', 'CHUNK', 'CITED', 'CIVIC', 'CIVIL',
  'CLAIM', 'CLAMP', 'CLANK', 'CLASH', 'CLASP', 'CLASS', 'CLEAN', 'CLEAR',
  'CLERK', 'CLICK', 'CLIMB', 'CLINK', 'CLIP', 'CLONE', 'CLOSE', 'CLOTH',
  'CLOUT', 'CLOWN', 'CLUBS', 'CLUCK', 'CLUED', 'CLUMP', 'COAST', 'COBRA',
  'COLOR', 'COMET', 'COMIC', 'COMMA', 'CORAL', 'COULD', 'COUNT', 'COURT',
  'COVER', 'CRAFT', 'CRANE', 'CRASH', 'CRAZY', 'CREEK', 'CREEP', 'CRIME',
  'CRISP', 'CROSS', 'CRUEL', 'CUBIC', 'CURVE', 'CYCLE', 'DAILY', 'DAIRY',
  'DAISY', 'DATUM', 'DEBUT', 'DECAL', 'DECAY', 'DECOY', 'DELTA', 'DEPOT',
  'DEPTH', 'DERBY', 'DEVIL', 'DIGIT', 'DINER', 'DISCO', 'DITCH', 'DITTY',
  'DIZZY', 'DODGE', 'DONOR', 'DOUBT', 'DOUGH', 'DRANK', 'DRAWN', 'DREAD',
  'DRIFT', 'DRILL', 'DRINK', 'DRIVE', 'DROVE', 'DRYER', 'DUCKS', 'DWELL',
  'EAGER', 'EAGLE', 'EARLY', 'EATEN', 'EBONY', 'EDGES', 'EERIE', 'ELDER',
  'ELECT', 'ELITE', 'EMAIL', 'EMBER', 'EMPTY', 'ENDED', 'ENEMY', 'ENJOY',
  'ENTER', 'ENTRY', 'EQUAL', 'ERROR', 'ESSAY', 'EVADE', 'EVENT', 'EVERY',
  'EXACT', 'EXCEL', 'EXIST', 'EXTRA', 'FABLE', 'FACED', 'FACTS', 'FADED',
  'FALLS', 'FALSE', 'FANCY', 'FATAL', 'FAULT', 'FEAST', 'FENCE', 'FERRY',
  'FETCH', 'FEVER', 'FEWER', 'FLAIR', 'FLARE', 'FLASH', 'FLASK', 'FLATS',
  'FLESH', 'FLIES', 'FLOCK', 'FLOOD', 'FLOOR', 'FLOSS', 'FLUTE', 'FOCAL',
  'FOLKS', 'FORCE', 'FORGE', 'FORTH', 'FORUM', 'FOUND', 'FRAME', 'FRANK',
  'FRAUD', 'FRONT', 'FROST', 'FROZE', 'FRUIT', 'FULLY', 'FUNNY', 'FURRY',
  'FUZZY', 'GAINS', 'GAMES', 'GAUGE', 'GAVEL', 'GEARS', 'GEESE', 'GENES',
  'GENRE', 'GHOST', 'GIVEN', 'GIZMO', 'GLAND', 'GLARE', 'GLASS', 'GLIDE',
  'GLOOM', 'GLORY', 'GLOSS', 'GLOVE', 'GNOME', 'GOING', 'GRADE', 'GRAIN',
  'GRAND', 'GRANT', 'GRASP', 'GRAZE', 'GREED', 'GREET', 'GRILL', 'GRIND',
  'GROAN', 'GROIN', 'GROOM', 'GROSS', 'GROUP', 'GROVE', 'GROWN', 'GUARD',
  'GUESS', 'GUEST', 'GUIDE', 'GUILD', 'GUILE', 'GUILT', 'GUISE', 'GUSTO',
  'HABIT', 'HARSH', 'HASTE', 'HAUNT', 'HAVEN', 'HAZEL', 'HEADS', 'HEADY',
  'HEARD', 'HEDGE', 'HEIST', 'HERDS', 'HERBS', 'HINGE', 'HIPPO', 'HOIST',
  'HOLLY', 'HOMER', 'HONOR', 'HOPED', 'HOTEL', 'HOUND', 'HOVER', 'HUMAN',
  'HUMID', 'HUMMM', 'HUMPH', 'HURRY', 'HYENA', 'IDEAL', 'IMAGE', 'IMPLY',
  'INDEX', 'INDIE', 'INFER', 'INPUT', 'INTER', 'INTRO', 'ISSUE', 'IVORY',
  'JAUNT', 'JAZZY', 'JOINT', 'JOUST', 'JUDGE', 'JUICY', 'JUMBO', 'JUMPY',
  'KAYAK', 'KETCH', 'KHAKI', 'KNACK', 'KNEEL', 'KNELT', 'KNOBS', 'KNOCK',
  'KNOLL', 'KNOWN', 'LABEL', 'LANCE', 'LARGE', 'LASER', 'LATER', 'LAYER',
  'LEARN', 'LEASE', 'LEAST', 'LEGAL', 'LEVEL', 'LILAC', 'LIMIT', 'LINER',
  'LISTS', 'LIVES', 'LLAMA', 'LOBBY', 'LOCAL', 'LODGE', 'LOGIC', 'LOOSE',
  'LOWER', 'LOYAL', 'LUCKY', 'LUSTY', 'LYRIC', 'MAKER', 'MANOR', 'MAPLE',
  'MARCH', 'MARSH', 'MATCH', 'MANOR', 'MAYOR', 'MEALS', 'MEANT', 'MERGE',
  'MERIT', 'METAL', 'MINOR', 'MINUS', 'MISTY', 'MIXED', 'MODEL', 'MONKS',
  'MONTH', 'MORAL', 'MOTOR', 'MOUNT', 'MOVIE', 'MUDDY', 'MURAL', 'MURKY',
  'NABOB', 'NADIR', 'NASAL', 'NIFTY', 'NINJA', 'NOISE', 'NOVEL', 'NURSE',
  'NYMPH', 'OASIS', 'OCCUR', 'OLIVE', 'ONSET', 'ORBIT', 'ORDER', 'OTHER',
  'OTTER', 'OUGHT', 'OUNCE', 'OUTER', 'OUTDO', 'OVEN', 'OVARY', 'OWNED',
  'OXIDE', 'OZONE', 'PADDY', 'PAGES', 'PANIC', 'PAPER', 'PATCH', 'PAUSE',
  'PEARL', 'PEDAL', 'PHASE', 'PHONE', 'PHOTO', 'PIANO', 'PIECE', 'PILOT',
  'PINCH', 'PITCH', 'PIXEL', 'PLACE', 'PLAID', 'PLAIN', 'PLANE', 'PLANK',
  'PLAZA', 'PLEAD', 'PLUCK', 'PLUMB', 'PLUME', 'PLUMP', 'PLUNGE','PLUNK',
  'POINT', 'POKER', 'POLAR', 'POPPY', 'PORCH', 'POUCH', 'POWER', 'PRESS',
  'PRICE', 'PRICK', 'PRIDE', 'PRIME', 'PRISM', 'PRIZE', 'PROBE', 'PRONE',
  'PROOF', 'PROSE', 'PROXY', 'PROUD', 'PROVE', 'PROWL', 'PSALM', 'PULSE',
  'PUNCH', 'PUPPY', 'PURSE', 'PUSHY', 'PYGMY', 'QUERY', 'QUEUE', 'QUIRK',
  'QUOTA', 'QUOTE', 'RABID', 'RADAR', 'RADIX', 'RADON', 'RALLY', 'RANCH',
  'RANGE', 'RAPID', 'RASPY', 'RATIO', 'REACH', 'REACT', 'READY', 'REALM',
  'REBUS', 'REBEL', 'RECAP', 'RECUT', 'REEDY', 'REGAL', 'RELAY', 'REPAY',
  'REPEL', 'REPLY', 'RERUN', 'RIDER', 'RIDGE', 'RISKY', 'RIVAL', 'ROCKY',
  'ROMAN', 'ROOMY', 'ROUGH', 'ROUTE', 'ROWDY', 'ROYAL', 'RUGBY', 'RULER',
  'RUMOR', 'RUSTY', 'SADLY', 'SAINT', 'SALAD', 'SANDY', 'SAUCE', 'SAVOR',
  'SCARY', 'SCENE', 'SCONE', 'SCOUT', 'SCUFF', 'SEIZE', 'SERVE', 'SETUP',
  'SEVEN', 'SHADE', 'SHALL', 'SHAME', 'SHARP', 'SHARK', 'SHEAF', 'SHEAR',
  'SHEEP', 'SHEER', 'SHIFT', 'SHINE', 'SHIRT', 'SHOCK', 'SHOOT', 'SHORT',
  'SHOUT', 'SHRUB', 'SHRUG', 'SIGHT', 'SIGMA', 'SILLY', 'SINCE', 'SIXTH',
  'SIXTY', 'SIZED', 'SKILL', 'SKULL', 'SKUNK', 'SLANT', 'SLASH', 'SLATE',
  'SLAVE', 'SLEEK', 'SLEET', 'SLEPT', 'SLICK', 'SLIDE', 'SLING', 'SLOTH',
  'SMALL', 'SMART', 'SMELL', 'SMELT', 'SMIRK', 'SMITE', 'SMOKE', 'SNACK',
  'SNAKE', 'SNARE', 'SNEAK', 'SNIFF', 'SNORE', 'SNORT', 'SNOUT', 'SNOWY',
  'SOAPY', 'SOLAR', 'SOLID', 'SOLVE', 'SONIC', 'SOUTH', 'SPACE', 'SPADE',
  'SPANK', 'SPARE', 'SPARK', 'SPAWN', 'SPEAK', 'SPEED', 'SPEND', 'SPICE',
  'SPILL', 'SPINE', 'SPITE', 'SPLIT', 'SPOKE', 'SPOOL', 'SPOON', 'SPORE',
  'SPORT', 'SPOUT', 'SPRAY', 'SPREE', 'SPRIG', 'SPUNK', 'SQUAT', 'STACK',
  'STAFF', 'STAGE', 'STAIN', 'STAIR', 'STAKE', 'STALE', 'STAND', 'STANK',
  'STARE', 'STARK', 'START', 'STASH', 'STATE', 'STAYS', 'STEAL', 'STEAM',
  'STEEL', 'STEEP', 'STEER', 'STERN', 'STICK', 'STIFF', 'STILL', 'STING',
  'STOCK', 'STONE', 'STOOD', 'STORE', 'STOUT', 'STRAW', 'STRIP', 'STRUT',
  'STUCK', 'STUDY', 'STYLE', 'SUGAR', 'SUPER', 'SURGE', 'SWAMP', 'SWEAR',
  'SWEEP', 'SWIFT', 'SWIPE', 'SWIRL', 'SWORD', 'SWORE', 'SWUNG', 'SYRUP',
  'TALLY', 'TAPIR', 'TASTE', 'TAUNT', 'TAWNY', 'TEMPO', 'TENSE', 'TENTH',
  'TEPID', 'THEFT', 'THORN', 'THOSE', 'THREW', 'THREE', 'THREW', 'THROW',
  'THUMB', 'THUMP', 'TIARA', 'TIDAL', 'TIGHT', 'TIMER', 'TIRED', 'TITLE',
  'TOAST', 'TODAY', 'TOKEN', 'TOPIC', 'TORCH', 'TOTAL', 'TOUCH', 'TOUGH',
  'TOXIC', 'TRACK', 'TRADE', 'TRAIL', 'TRAIT', 'TRAMP', 'TRASH', 'TREAD',
  'TREAT', 'TREND', 'TRIAL', 'TRIBE', 'TRICK', 'TRIED', 'TROOP', 'TROUT',
  'TRUCE', 'TRUCK', 'TRULY', 'TRUNK', 'TRUSS', 'TRUST', 'TULIP', 'TUNER',
  'TUTOR', 'TWEAK', 'TWICE', 'TWIRL', 'TWIST', 'ULTRA', 'UNFIT', 'UNION',
  'UNTIL', 'UPPER', 'UPSET', 'URBAN', 'USUAL', 'UTTER', 'VAGUE', 'VALID',
  'VALUE', 'VAPOR', 'VAULT', 'VICAR', 'VIGOR', 'VIRAL', 'VIRAL', 'VISIT',
  'VISTA', 'VIVID', 'VIXEN', 'VOCAL', 'VOTER', 'VYING', 'WACKY', 'WALTZ',
  'WAVER', 'WEARY', 'WEAVE', 'WEDGE', 'WEEDY', 'WEIRD', 'WHACK', 'WHEEL',
  'WHERE', 'WHICH', 'WHILE', 'WHIFF', 'WHIRL', 'WHISK', 'WHITE', 'WHOLE',
  'WHOSE', 'WIDER', 'WIELD', 'WITTY', 'WOMAN', 'WOMEN', 'WOODS', 'WORDY',
  'WORST', 'WORTH', 'WOULD', 'WRATH', 'WRITE', 'WRONG', 'WROTE', 'XENON',
  'YACHT', 'YEARN', 'YODEL', 'YOKEL', 'YOURS', 'ZAPPY', 'ZEBRA', 'ZESTY',
  'ZONAL', 'ZONES',
];

final _validWordsSet = <String>{
  ..._targetWords,
  ..._extraValidWords,
};

// ─────────────────────────────────────────────────────────────────────────────
// Data types
// ─────────────────────────────────────────────────────────────────────────────

enum _LetterStatus { correct, present, absent, empty }

enum _GameStatus { playing, won, lost }

class _Guess {
  final String word;
  final List<_LetterStatus> statuses;
  const _Guess({required this.word, required this.statuses});
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class WordleScreen extends StatefulWidget {
  const WordleScreen({super.key});

  @override
  State<WordleScreen> createState() => _WordleScreenState();
}

class _WordleScreenState extends State<WordleScreen> with TickerProviderStateMixin {
  // ── Game state ──
  late String _targetWord;
  String _currentGuess = '';
  final List<_Guess> _guesses = [];
  _GameStatus _gameStatus = _GameStatus.playing;
  int _score = 0;
  int _level = 1;
  bool _invalidWord = false;

  // ── Animations ──
  late AnimationController _modalCtrl;
  late Animation<double> _modalAnim;
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  // Keyboard focus
  final FocusNode _keyboardFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _modalCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _modalAnim = CurvedAnimation(parent: _modalCtrl, curve: Curves.easeOut);

    _shakeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = TweenSequence([
      TweenSequenceItem(tween: Tween<double>(begin: 0, end: -8), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: -8, end: 8), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 8, end: -6), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: -6, end: 6), weight: 20),
      TweenSequenceItem(tween: Tween<double>(begin: 6, end: 0), weight: 20),
    ]).animate(CurvedAnimation(parent: _shakeCtrl, curve: Curves.easeInOut));

    _initGame();
  }

  @override
  void dispose() {
    _modalCtrl.dispose();
    _shakeCtrl.dispose();
    _keyboardFocus.dispose();
    super.dispose();
  }

  // ── Game logic ──

  void _initGame({bool nextLevel = false}) {
    final rng = Random();
    setState(() {
      _targetWord = _targetWords[rng.nextInt(_targetWords.length)];
      _currentGuess = '';
      _guesses.clear();
      _gameStatus = _GameStatus.playing;
      _invalidWord = false;
      if (nextLevel) _level++;
    });
    _modalCtrl.reset();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyboardFocus.requestFocus();
    });
  }

  List<_LetterStatus> _evaluateGuess(String word) {
    final statuses = List<_LetterStatus>.filled(5, _LetterStatus.absent);
    final targetChars = _targetWord.split('');
    final guessChars = word.split('');

    // First pass: correct positions
    for (var i = 0; i < 5; i++) {
      if (guessChars[i] == targetChars[i]) {
        statuses[i] = _LetterStatus.correct;
        targetChars[i] = '';
        guessChars[i] = '';
      }
    }

    // Second pass: present but wrong position
    for (var i = 0; i < 5; i++) {
      if (guessChars[i].isEmpty) continue;
      final idx = targetChars.indexOf(guessChars[i]);
      if (idx != -1) {
        statuses[i] = _LetterStatus.present;
        targetChars[idx] = '';
      }
    }

    return statuses;
  }

  void _submitGuess() {
    if (_gameStatus != _GameStatus.playing) return;
    if (_currentGuess.length != 5) return;

    if (!_validWordsSet.contains(_currentGuess)) {
      setState(() => _invalidWord = true);
      _shakeCtrl.forward(from: 0).then((_) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _invalidWord = false);
        });
      });
      return;
    }

    final statuses = _evaluateGuess(_currentGuess);
    final guess = _Guess(word: _currentGuess, statuses: statuses);

    setState(() {
      _guesses.add(guess);
      _invalidWord = false;

      if (_currentGuess == _targetWord) {
        _gameStatus = _GameStatus.won;
        final points = (6 - _guesses.length + 1) * 10;
        _score += points;
      } else if (_guesses.length == 6) {
        _gameStatus = _GameStatus.lost;
      }

      _currentGuess = '';
    });

    if (_gameStatus != _GameStatus.playing) {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) _modalCtrl.forward();
      });
    }
  }

  void _handleKeyPress(String key) {
    if (_gameStatus != _GameStatus.playing) return;
    if (key == 'ENTER') {
      _submitGuess();
    } else if (key == 'BACKSPACE') {
      if (_currentGuess.isNotEmpty) {
        setState(() {
          _currentGuess = _currentGuess.substring(0, _currentGuess.length - 1);
          _invalidWord = false;
        });
      }
    } else if (_currentGuess.length < 5 && RegExp(r'^[A-Z]$').hasMatch(key)) {
      setState(() => _currentGuess += key);
    }
  }

  Map<String, _LetterStatus> _getKeyboardLetterStatuses() {
    final map = <String, _LetterStatus>{};
    for (final guess in _guesses) {
      for (var i = 0; i < guess.word.length; i++) {
        final letter = guess.word[i];
        final status = guess.statuses[i];
        final current = map[letter];
        if (current == null ||
            (current != _LetterStatus.correct &&
                status == _LetterStatus.correct) ||
            (current == _LetterStatus.absent &&
                status == _LetterStatus.present)) {
          map[letter] = status;
        }
      }
    }
    return map;
  }

  // ── Colors ──

  Color _tileColor(_LetterStatus status) => switch (status) {
        _LetterStatus.correct => const Color(0xFF22C55E),
        _LetterStatus.present => const Color(0xFFEAB308),
        _LetterStatus.absent => const Color(0xFF9CA3AF),
        _LetterStatus.empty => Colors.white,
      };

  Color _keyColor(_LetterStatus? status) => switch (status) {
        _LetterStatus.correct => const Color(0xFF22C55E),
        _LetterStatus.present => const Color(0xFFEAB308),
        _LetterStatus.absent => const Color(0xFF9CA3AF),
        _LetterStatus.empty || null => const Color(0xFFE5E7EB),
      };

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _keyboardFocus,
      autofocus: true,
      onKeyEvent: (event) {
        if (event is! KeyDownEvent) return;
        final logical = event.logicalKey;
        if (logical == LogicalKeyboardKey.enter) {
          _handleKeyPress('ENTER');
        } else if (logical == LogicalKeyboardKey.backspace) {
          _handleKeyPress('BACKSPACE');
        } else {
          final label = logical.keyLabel.toUpperCase();
          if (label.length == 1 && RegExp(r'^[A-Z]$').hasMatch(label)) {
            _handleKeyPress(label);
          }
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFF0FDF4), Color(0xFFEFF6FF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    _buildAppBar(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          children: [
                            _buildTitleSection(),
                            const SizedBox(height: 12),
                            _buildStatsRow(),
                            const SizedBox(height: 16),
                            _buildGrid(),
                            if (_invalidWord) ...[
                              const SizedBox(height: 8),
                              _buildInvalidBanner(),
                            ],
                            const SizedBox(height: 16),
                            _buildKeyboard(),
                            const SizedBox(height: 16),
                            _buildLegend(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                // Modal overlay
                if (_gameStatus != _GameStatus.playing)
                  FadeTransition(
                    opacity: _modalAnim,
                    child: _buildModal(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          TextButton.icon(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF16A34A)),
            label: Text(
              'Games',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF16A34A),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Wordle',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF15803D),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: () => _initGame(),
            icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF16A34A)),
            label: Text(
              'New',
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF16A34A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      children: [
        Text(
          'Wordle',
          style: GoogleFonts.montserrat(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF15803D),
          ),
        ),
        Text(
          'Guess the 5-letter word in 6 tries!',
          style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _StatCard(label: 'Level', value: '$_level', color: const Color(0xFF22C55E)),
        const SizedBox(width: 8),
        _StatCard(label: 'Score', value: '$_score', color: const Color(0xFF3B82F6)),
        const SizedBox(width: 8),
        _StatCard(
          label: 'Guesses',
          value: '${_guesses.length}/6',
          color: const Color(0xFFF97316),
        ),
      ],
    );
  }

  Widget _buildGrid() {
    return AnimatedBuilder(
      animation: _shakeAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_invalidWord ? _shakeAnim.value : 0, 0),
          child: child,
        );
      },
      child: Column(
        children: List.generate(6, (row) {
          final isCurrentRow = row == _guesses.length && _gameStatus == _GameStatus.playing;
          final isSubmitted = row < _guesses.length;

          String word = '';
          List<_LetterStatus>? statuses;

          if (isSubmitted) {
            word = _guesses[row].word;
            statuses = _guesses[row].statuses;
          } else if (isCurrentRow) {
            word = _currentGuess;
          }

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (col) {
                final letter = col < word.length ? word[col] : '';
                final status = statuses != null ? statuses[col] : _LetterStatus.empty;
                final isActive = isCurrentRow;

                return _Tile(
                  letter: letter,
                  status: status,
                  isActive: isActive,
                  isInvalid: isActive && _invalidWord,
                  tileColor: _tileColor,
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInvalidBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF4444)),
      ),
      child: Text(
        'Not a valid word!',
        style: GoogleFonts.montserrat(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFDC2626),
        ),
      ),
    );
  }

  Widget _buildKeyboard() {
    final letterStatuses = _getKeyboardLetterStatuses();
    const rows = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', 'BACKSPACE'],
    ];

    return Column(
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: row.map((key) {
                  final isSpecial = key == 'ENTER' || key == 'BACKSPACE';
                  final status = isSpecial ? null : letterStatuses[key];
                  final bg = _keyColor(status);
                  final textColor =
                      status != null && status != _LetterStatus.empty ? Colors.white : Colors.black87;

                  return _KeyButton(
                    label: key,
                    background: bg,
                    textColor: textColor,
                    onTap: () => _handleKeyPress(key),
                  );
                }).toList(),
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to play:',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const SizedBox(height: 8),
          _legendRow(const Color(0xFF22C55E), 'Correct letter, correct position'),
          _legendRow(const Color(0xFFEAB308), 'Correct letter, wrong position'),
          _legendRow(const Color(0xFF9CA3AF), 'Letter not in word'),
        ],
      ),
    );
  }

  Widget _legendRow(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
          ),
          const SizedBox(width: 10),
          Text(text, style: GoogleFonts.montserrat(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  Widget _buildModal() {
    final won = _gameStatus == _GameStatus.won;
    final points = won ? (6 - _guesses.length + 1) * 10 : 0;

    return Container(
      color: Colors.black.withValues(alpha: 0.5),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 24, offset: const Offset(0, 8)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: won
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  won ? Icons.check_circle_rounded : Icons.cancel_rounded,
                  color: won ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  size: 44,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                won ? 'You Won! 🎉' : 'Game Over!',
                style: GoogleFonts.montserrat(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: won ? const Color(0xFF15803D) : const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 8),
              if (won) ...[
                Text(
                  'The word was:',
                  style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600]),
                ),
                Text(
                  _targetWord,
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF22C55E),
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Solved in ${_guesses.length} ${_guesses.length == 1 ? 'try' : 'tries'} · +$points pts',
                  style: GoogleFonts.montserrat(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
              ] else ...[
                Text(
                  'The word was:',
                  style: GoogleFonts.montserrat(fontSize: 13, color: Colors.grey[600]),
                ),
                Text(
                  _targetWord,
                  style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF22C55E),
                    letterSpacing: 4,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              if (won)
                _ModalButton(
                  label: 'Next Level →',
                  color: const Color(0xFF22C55E),
                  onTap: () => _initGame(nextLevel: true),
                )
              else
                _ModalButton(
                  label: 'Try Again',
                  color: const Color(0xFFEF4444),
                  onTap: () => _initGame(),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tile widget
// ─────────────────────────────────────────────────────────────────────────────

class _Tile extends StatefulWidget {
  final String letter;
  final _LetterStatus status;
  final bool isActive;
  final bool isInvalid;
  final Color Function(_LetterStatus) tileColor;

  const _Tile({
    required this.letter,
    required this.status,
    required this.isActive,
    required this.isInvalid,
    required this.tileColor,
  });

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> with SingleTickerProviderStateMixin {
  late AnimationController _flipCtrl;
  late Animation<double> _flipAnim;
  _LetterStatus _displayStatus = _LetterStatus.empty;

  @override
  void initState() {
    super.initState();
    _flipCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _flipAnim = CurvedAnimation(parent: _flipCtrl, curve: Curves.easeInOut);
    _displayStatus = widget.status;
  }

  @override
  void didUpdateWidget(_Tile old) {
    super.didUpdateWidget(old);
    if (old.status != widget.status && !widget.isActive) {
      _flipCtrl.forward(from: 0).then((_) {
        if (mounted) setState(() => _displayStatus = widget.status);
      });
    } else {
      _displayStatus = widget.status;
    }
  }

  @override
  void dispose() {
    _flipCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = widget.letter.isEmpty && !widget.isActive;
    final submitted = !widget.isActive && widget.status != _LetterStatus.empty;
    final bgColor = submitted ? widget.tileColor(_displayStatus) : Colors.white;
    final textColor = submitted ? Colors.white : Colors.black87;
    final borderColor = widget.isInvalid
        ? const Color(0xFFEF4444)
        : widget.letter.isNotEmpty && widget.isActive
            ? const Color(0xFF6B7280)
            : const Color(0xFFD1D5DB);

    return AnimatedBuilder(
      animation: _flipAnim,
      builder: (context, child) {
        return Container(
          width: 56,
          height: 56,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: submitted ? Colors.transparent : borderColor,
              width: 2,
            ),
            boxShadow: submitted
                ? [BoxShadow(color: bgColor.withValues(alpha: 0.4), blurRadius: 6, offset: const Offset(0, 2))]
                : null,
          ),
          child: Center(
            child: Text(
              widget.letter,
              style: GoogleFonts.montserrat(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Keyboard key button
// ─────────────────────────────────────────────────────────────────────────────

class _KeyButton extends StatefulWidget {
  final String label;
  final Color background;
  final Color textColor;
  final VoidCallback onTap;

  const _KeyButton({
    required this.label,
    required this.background,
    required this.textColor,
    required this.onTap,
  });

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 80));
    _scale = Tween<double>(begin: 1, end: 0.88).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isBackspace = widget.label == 'BACKSPACE';
    final isEnter = widget.label == 'ENTER';
    final isWide = isBackspace || isEnter;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: isWide ? 54 : 33,
          height: 44,
          margin: const EdgeInsets.symmetric(horizontal: 2.5),
          decoration: BoxDecoration(
            color: widget.background,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 3, offset: const Offset(0, 2)),
            ],
          ),
          child: Center(
            child: isBackspace
                ? Icon(Icons.backspace_outlined, size: 18, color: widget.textColor)
                : Text(
                    isEnter ? 'ENTER' : widget.label,
                    style: GoogleFonts.montserrat(
                      fontSize: isEnter ? 10 : 14,
                      fontWeight: FontWeight.w700,
                      color: widget.textColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stat card
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatCard({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)],
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.montserrat(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.montserrat(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Modal button
// ─────────────────────────────────────────────────────────────────────────────

class _ModalButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ModalButton({required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
