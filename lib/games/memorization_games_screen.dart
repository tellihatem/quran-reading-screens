import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'dart:developer' as developer;
import 'dart:ui' as ui;
import '../screens/surah_recording_test_screen.dart';
import '../widgets/background_widget.dart';

class MemorizationGamesScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;

  const MemorizationGamesScreen({
    super.key,
    required this.surahNumber,
    required this.surahName,
  });

  @override
  State<MemorizationGamesScreen> createState() =>
      _MemorizationGamesScreenState();
}

enum GameType { ayahOrdering, quiz }

class _MemorizationGamesScreenState extends State<MemorizationGamesScreen>
    with SingleTickerProviderStateMixin {
  int _currentGameIndex = 0;
  final List<Map<String, dynamic>> _games = [
    {
      'name': 'ترتيب الآيات',
      'description': 'رتب الآيات بالترتيب الصحيح',
      'icon': Icons.sort_by_alpha,
      'minScore': 0.7,
      'type': GameType.ayahOrdering,
    },
    {
      'name': 'اختبار الحفظ',
      'description': 'اختبار أسئلة عن السورة',
      'icon': Icons.quiz,
      'minScore': 0.7,
      'type': GameType.quiz,
    },
  ];

  // Ayah Ordering Game State
  List<Map<String, dynamic>> _verses = [];
  List<Map<String, dynamic>> _shuffledVerses = [];
  final Random _random = Random();
  int _mistakesCount = 0;
  bool _hasShownMistakeFeedback = false;

  // Quiz Game State
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _showFeedback = false;
  bool _isAnswerCorrect = false;
  int _score = 0;
  late List<double> _scores;
  bool _isGameInProgress = false;
  late AnimationController _starController;
  late Animation<double> _starAnimation;
  bool _showStar = false;

  @override
  void initState() {
    super.initState();
    _scores = List.filled(_games.length, 0.0);
    _isGameInProgress = true;
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _starAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _starController, curve: Curves.elasticOut),
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _starController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _starController.forward();
      }
    });
    _initializeCurrentGame();
  }

  @override
  void dispose() {
    _starController.dispose();
    super.dispose();
  }

  void _initializeCurrentGame() {
    if (_games[_currentGameIndex]['type'] == GameType.ayahOrdering) {
      _initializeAyahOrderingGame();
    } else {
      _initializeQuizGame();
    }
  }

  void _initializeAyahOrderingGame() {
    final surah = widget.surahNumber;
    final verseCount = quran.getVerseCount(surah);

    // Reset mistake tracking
    _mistakesCount = 0;
    _hasShownMistakeFeedback = false;

    // Get all verses for the surah
    _verses = List.generate(verseCount, (index) {
      final verseNumber = index + 1;
      return {
        'text': quran.getVerse(surah, verseNumber, verseEndSymbol: false),
        'number': verseNumber,
      };
    });

    _shuffledVerses = List.from(_verses)..shuffle(_random);
    setState(() {});
  }

  void _initializeQuizGame() {
    final surahName = quran.getSurahNameArabic(widget.surahNumber);
    final verseCount = quran.getVerseCount(widget.surahNumber);
    final isMakki = quran
        .getPlaceOfRevelation(widget.surahNumber)
        .toLowerCase()
        .contains('makkah');
    final surahOrder = widget.surahNumber;

    _questions = [];

    // Add question about surah type (Makkah/Madinah)
    final surahTypeAnswers = ['مكية', 'مدنية'];
    final correctSurahTypeIndex = isMakki ? 0 : 1;
    _questions.add({
      'type': 'surah_type',
      'question': 'هل سورة $surahName مكية أم مدنية؟',
      'answers': surahTypeAnswers,
      'correctIndex': correctSurahTypeIndex,
      'explanation': 'سورة $surahName ${isMakki ? 'مكية' : 'مدنية'}',
    });

    // Add question about number of verses
    final verseCountAnswers = _generateRandomNumbers(verseCount, 4, 1, 286);
    final correctVerseCountIndex = verseCountAnswers.indexOf(
      verseCount.toString(),
    );
    _questions.add({
      'type': 'verse_count',
      'question': 'كم عدد آيات سورة $surahName؟',
      'answers': verseCountAnswers,
      'correctIndex': correctVerseCountIndex,
      'explanation': 'عدد آيات سورة $surahName هو $verseCount آية',
    });

    // Add question about surah order in Quran
    final surahOrderAnswers = _generateRandomNumbers(surahOrder, 4, 1, 114);
    final correctSurahOrderIndex = surahOrderAnswers.indexOf(
      surahOrder.toString(),
    );
    _questions.add({
      'type': 'surah_order',
      'question': 'ما هو ترتيب سورة $surahName في القرآن الكريم؟',
      'answers': surahOrderAnswers,
      'correctIndex': correctSurahOrderIndex,
      'explanation': 'ترتيب سورة $surahName في القرآن الكريم هو $surahOrder',
    });

    // Add verse completion questions (2 questions)
    if (verseCount > 2) {
      for (int i = 0; i < 2 && i < verseCount - 1; i++) {
        final verseNum = _random.nextInt(verseCount - 1) + 1;
        final verseText = quran.getVerse(
          widget.surahNumber,
          verseNum,
          verseEndSymbol: false,
        );
        final words = verseText.split(' ');

        if (words.length > 3) {
          final splitPoint = _random.nextInt(words.length - 2) + 1;
          final questionText = words.take(splitPoint).join(' ') + ' ...';
          final correctAnswer = words.skip(splitPoint).take(3).join(' ');

          // Generate wrong answers
          Set<String> answerOptions = {correctAnswer};
          for (int j = 0; j < 3 && j < verseCount - 1; j++) {
            final wrongVerseNum = (verseNum + j + 1) % verseCount + 1;
            if (wrongVerseNum != verseNum) {
              final wrongVerse = quran.getVerse(
                widget.surahNumber,
                wrongVerseNum,
                verseEndSymbol: false,
              );
              answerOptions.add(wrongVerse);
            }
          }
          while (answerOptions.length < 4) {
            final randomVerse = _random.nextInt(verseCount) + 1;
            if (randomVerse != verseNum) {
              final otherVerse = quran.getVerse(
                widget.surahNumber,
                randomVerse,
                verseEndSymbol: false,
              );
              final otherWords = otherVerse.split(' ');
              if (otherWords.length > 3) {
                answerOptions.add(otherWords.take(3).join(' '));
              }
            }
          }

          _questions.add({
            'type': 'verse_completion',
            'question': 'أكمل الآية: $questionText',
            'answers': answerOptions.toList()..shuffle(_random),
            'correctAnswer': correctAnswer,
            'explanation': 'الآية الكاملة: $verseText',
          });
        }
      }
    }

    // Add next verse questions (2 questions)
    if (verseCount > 3) {
      for (int i = 0; i < 2 && i < verseCount - 2; i++) {
        final verseNum = _random.nextInt(verseCount - 2) + 1;
        final currentVerse = quran.getVerse(
          widget.surahNumber,
          verseNum,
          verseEndSymbol: false,
        );
        final nextVerse = quran.getVerse(
          widget.surahNumber,
          verseNum + 1,
          verseEndSymbol: false,
        );

        // Generate wrong answers
        Set<String> answerOptions = {nextVerse};
        while (answerOptions.length < 4) {
          final randomVerse = _random.nextInt(verseCount) + 1;
          if (randomVerse != verseNum + 1) {
            answerOptions.add(
              quran.getVerse(
                widget.surahNumber,
                randomVerse,
                verseEndSymbol: false,
              ),
            );
          }
        }

        _questions.add({
          'type': 'next_verse',
          'question': 'ما هي الآية التالية لـ: $currentVerse',
          'answers': answerOptions.toList()..shuffle(_random),
          'correctAnswer': nextVerse,
          'explanation': 'الآية التالية هي: $nextVerse',
        });
      }
    }

    // Shuffle questions but keep the first three (basic info) questions first
    if (_questions.length > 3) {
      final basicQuestions = _questions.sublist(0, 3);
      final otherQuestions = _questions.sublist(3)..shuffle(_random);
      _questions = [
        ...basicQuestions,
        ...otherQuestions.take(7),
      ]; // Total 10 questions max
    }

    _currentQuestionIndex = 0;
    _score = 0;
    setState(() {});
  }

  List<String> _generateRandomNumbers(
    int correctNumber,
    int count,
    int min,
    int max,
  ) {
    final numbers = {correctNumber};
    while (numbers.length < count) {
      numbers.add(min + _random.nextInt(max - min + 1));
    }
    final result = numbers.toList()..shuffle(_random);
    return result.map((n) => n.toString()).toList();
  }

  void _onGameCompleted(double score, int gameIndex) {
    setState(() {
      _scores[gameIndex] = score;
      _isGameInProgress = false;
    });

    // Show completion dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLargeScreen = constraints.maxWidth > 600;
                final isCorrect = score >= 0.7;
                final backgroundImage =
                    isCorrect
                        ? (isLargeScreen
                            ? 'assets/games/correct_background_big.png'
                            : 'assets/games/correct_background.png')
                        : (isLargeScreen
                            ? 'assets/games/wrong_background_big.png'
                            : 'assets/games/wrong_background.png');

                return Stack(
                  children: [
                    // Background image
                    Image.asset(backgroundImage, fit: BoxFit.contain),

                    // Content
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        40,
                        isLargeScreen ? 100 : 50,
                        isLargeScreen ? 200 : 40,
                        12,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isCorrect ? 'أحسنت! 🎉' : 'حاول مرة أخرى',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لقد أتممت ${_games[gameIndex]['name']} بنجاح',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'نقاطك: ${(score * 100).toInt()}%',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),

                          /// 👉 Remove inherited padding from this only
                          Padding(
                            padding: EdgeInsets.zero,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                if (gameIndex < _games.length - 1) {
                                  setState(() {
                                    _currentGameIndex++;
                                    _isGameInProgress = true;
                                    _initializeCurrentGame();
                                  });
                                } else {
                                  _showFinalResults();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                gameIndex < _games.length - 1
                                    ? 'اللعبة التالية'
                                    : 'إنهاء',
                                style: const TextStyle(
                                  color: Colors.blue,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
    );
  }

  Future<void> _unlockNextSurah() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get the current surah's position in the sequence
      int currentSurahNumber = widget.surahNumber;
      int nextSurahNumber;

      // Determine the next surah in the sequence: 1, 114, 113, ..., 2
      if (currentSurahNumber == 1) {
        nextSurahNumber = 114; // After 1, go to 114
      } else if (currentSurahNumber == 2) {
        return; // No surah after 2 in this sequence
      } else {
        nextSurahNumber =
            currentSurahNumber -
            1; // Go to previous number (114->113, 113->112, etc.)
      }

      // Only proceed if we have a valid next surah number
      if (nextSurahNumber >= 1 && nextSurahNumber <= 114) {
        final unlockedSurahs = prefs.getStringList('unlocked_surahs') ?? [];
        final surahKey = 'surah_$nextSurahNumber';

        if (!unlockedSurahs.contains(surahKey)) {
          unlockedSurahs.add(surahKey);
          await prefs.setStringList('unlocked_surahs', unlockedSurahs);
          developer.log('Unlocked next surah in sequence: $surahKey');
        }
      }
    } catch (e) {
      developer.log('Error unlocking next surah: $e');
    }
  }

  Future<void> _savePassedSurah() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final passedSurahs = prefs.getStringList('passed_surahs') ?? [];
      final surahKey = 'surah_${widget.surahNumber}';

      if (!passedSurahs.contains(surahKey)) {
        // Add to passed surahs
        passedSurahs.add(surahKey);
        await prefs.setStringList('passed_surahs', passedSurahs);

        // Increment global star count
        final currentStars = prefs.getInt('global_star_count') ?? 0;
        await prefs.setInt('global_star_count', currentStars + 1);

        developer.log('Successfully saved passed surah: $surahKey');
        developer.log('Updated global_star_count to: ${currentStars + 1}');

        // Unlock next surah when current one is passed (2 stars)
        await _unlockNextSurah();
      }
    } catch (e) {
      developer.log('Error saving passed surah: $e');
    }
  }

  void _showFinalResults() {
    bool allPassed = true;
    String resultMessage = '';
    double totalScore = 0;

    for (int i = 0; i < _games.length; i++) {
      final minScore = _games[i]['minScore'] as double;
      final passed = _scores[i] >= minScore;
      allPassed = allPassed && passed;
      resultMessage +=
          '${_games[i]['name']}: ${(_scores[i] * 100).toInt()}%${passed ? ' ✓' : ' ✗'}\n';
      totalScore += _scores[i];
    }

    // Calculate average score
    final averageScore = totalScore / _games.length;
    final passedOverall = averageScore >= 0.7; // 70% minimum passing score

    // Save to SharedPreferences if passed and start star animation
    if (passedOverall) {
      _savePassedSurah().then((_) {
        setState(() {
          _showStar = true;
        });
        _starController.forward(from: 0);
      });
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLargeScreen = constraints.maxWidth > 600;
                final backgroundImage =
                    passedOverall
                        ? (isLargeScreen
                            ? 'assets/games/win_result_big.png'
                            : 'assets/games/win_result.png')
                        : (isLargeScreen
                            ? 'assets/games/loss_result_big.png'
                            : 'assets/games/loss_result.png');

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Background image
                    Image.asset(backgroundImage, fit: BoxFit.contain),

                    // Content
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        40,
                        120, // More top padding on mobile
                        40,
                        0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            passedOverall ? 'تهانينا! 🎉' : 'انتهت الاختبارات',
                            style: TextStyle(
                              fontSize: isLargeScreen ? 24 : 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            passedOverall
                                ? 'أتممت جميع الاختبارات بنجاح!'
                                : 'انتهت جميع الاختبارات.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: isLargeScreen ? 18 : 16,
                              fontWeight: FontWeight.w600, // Bolder text
                              color: Colors.white,
                              height: 1.4, // Better line height
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'النتائج:',
                            style: TextStyle(
                              fontSize: isLargeScreen ? 20 : 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            resultMessage,
                            style: GoogleFonts.amiri(
                              fontSize: isLargeScreen ? 20 : 18,
                              fontWeight: FontWeight.w600, // Bolder text
                              height:
                                  0.8, // More line height for better readability
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'المعدل النهائي: ${(averageScore * 100).toInt()}%',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: isLargeScreen ? 22 : 18,
                              color:
                                  passedOverall
                                      ? const Color.fromARGB(255, 0, 94, 3)
                                      : const Color.fromARGB(255, 255, 3, 3),
                              height:
                                  isLargeScreen
                                      ? 1.4
                                      : 0.1, // Further reduced height for mobile
                            ),
                            textAlign: TextAlign.center,
                          ),
                          if (passedOverall && _showStar)
                            AnimatedBuilder(
                              animation: _starAnimation,
                              builder: (context, child) {
                                return Transform.scale(
                                  scale: _starAnimation.value,
                                  child: const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 60,
                                  ),
                                );
                              },
                            ),
                          const SizedBox(height: 30),
                          // Add bottom padding container for large screens
                          Container(
                            margin:
                                isLargeScreen
                                    ? const EdgeInsets.only(top: 60)
                                    : EdgeInsets.zero,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (!passedOverall) ...[
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      setState(() {
                                        _currentGameIndex = 0;
                                        _scores = List.filled(
                                          _games.length,
                                          0.0,
                                        );
                                        _isGameInProgress = true;
                                        _initializeCurrentGame();
                                      });
                                    },
                                    child: Image.asset(
                                      isLargeScreen
                                          ? 'assets/games/retry_big.png'
                                          : 'assets/games/retry.png',
                                      width: isLargeScreen ? 150 : 120,
                                      height: isLargeScreen ? 60 : 50,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).pop();
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                SurahRecordingTestScreen(
                                                  surahNumber:
                                                      widget.surahNumber,
                                                  surahName: widget.surahName,
                                                ),
                                      ),
                                    );
                                  },
                                  child: Image.asset(
                                    isLargeScreen
                                        ? 'assets/games/next_big.png'
                                        : 'assets/games/next.png',
                                    width: isLargeScreen ? 80 : 60,
                                    height: isLargeScreen ? 80 : 60,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
    );
  }

  void _onAyahReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final Map<String, dynamic> item = _shuffledVerses.removeAt(oldIndex);
      _shuffledVerses.insert(newIndex, item);
    });
  }

  void _checkAyahOrder() {
    bool isCorrect = true;
    for (int i = 0; i < _verses.length; i++) {
      if (_shuffledVerses[i]['number'] != _verses[i]['number']) {
        isCorrect = false;
        break;
      }
    }

    if (!isCorrect && !_hasShownMistakeFeedback) {
      if (_mistakesCount >= 1) {
        // Show feedback about the mistake and move to next game
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                title: const Text('حاول مرة أخرى'),
                content: const Text(
                  'لقد أخطأت في ترتيب الآيات. سيتم نقلك إلى اللعبة التالية.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _onGameCompleted(0.0, _currentGameIndex);
                    },
                    child: const Text('حسناً'),
                  ),
                ],
              ),
        );
        return;
      } else {
        _mistakesCount++;
        _hasShownMistakeFeedback = true;
        // Show feedback about the mistake
        showDialog(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('حاول مرة أخرى'),
                content: const Text(
                  'الترتيب غير صحيح. لديك محاولة واحدة أخرى.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('حسناً'),
                  ),
                ],
              ),
        );
        return;
      }
    }

    // If we reached here, either it's correct or we're allowing another attempt
    if (isCorrect) {
      // Calculate score based on number of correct positions
      int correctCount = 0;
      for (int i = 0; i < _verses.length; i++) {
        if (_shuffledVerses[i]['number'] == _verses[i]['number']) {
          correctCount++;
        }
      }

      double score = correctCount / _verses.length;
      _onGameCompleted(score, _currentGameIndex);
    } else {
      // If we get here, it means the order is still incorrect after one mistake
      // This should not happen as we handle the first mistake case above
      // But just in case, we'll show an error and move to next game
      _onGameCompleted(0.0, _currentGameIndex);
    }
  }

  Widget _buildAyahOrderingGame() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            'اسحب الآيات لترتيبها بالشكل الصحيح',
            style: GoogleFonts.notoKufiArabic(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ReorderableListView.builder(
              buildDefaultDragHandles: false, // Use custom drag handles
              itemCount: _shuffledVerses.length,
              onReorder: _onAyahReorder,
              itemBuilder: (context, index) {
                final verse = _shuffledVerses[index];
                return Card(
                  key: ValueKey(verse['number']),
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 8,
                  ),
                  child: InkWell(
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Drag handle with larger touch target
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 16.0,
                            ),
                            child: ReorderableDragStartListener(
                              index: index,
                              child: Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.drag_handle,
                                  color:
                                      Theme.of(context).brightness ==
                                              Brightness.dark
                                          ? Colors.grey[400]
                                          : Colors.grey[600],
                                  size: 28,
                                ),
                              ),
                            ),
                          ),
                          // Verse text
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                                vertical: 4.0,
                              ),
                              child: Directionality(
                                textDirection: ui.TextDirection.rtl,
                                child: Text(
                                  verse['text'],
                                  style: GoogleFonts.amiriQuran(
                                    fontSize: 20,
                                    height: 1.8,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isLargeScreen = constraints.maxWidth > 600;
                return GestureDetector(
                  onTap: _checkAyahOrder,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Image.asset(
                        isLargeScreen
                            ? 'assets/games/button_big.png'
                            : 'assets/games/button_small.png',
                        fit: BoxFit.contain,
                      ),
                      Directionality(
                        textDirection: ui.TextDirection.rtl,
                        child: Text(
                          'تحقق من الإجابة',
                          style: GoogleFonts.kufam(
                            fontSize: isLargeScreen ? 24 : 20,
                            fontWeight:
                                isLargeScreen
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Quiz Game Methods
  void _checkQuizAnswer(int selectedIndex) {
    setState(() {
      _selectedAnswerIndex = selectedIndex;
      _showFeedback = true;

      final currentQuestion = _questions[_currentQuestionIndex];
      if (currentQuestion['type'] == 'verse_completion' ||
          currentQuestion['type'] == 'next_verse') {
        _isAnswerCorrect =
            selectedIndex ==
            currentQuestion['answers'].indexOf(
              currentQuestion['correctAnswer'],
            );
      } else {
        _isAnswerCorrect = selectedIndex == currentQuestion['correctIndex'];
      }

      if (_isAnswerCorrect) {
        _score++;
      }
    });
  }

  void _nextQuestion() {
    setState(() {
      _showFeedback = false;
      _selectedAnswerIndex = null;

      if (_currentQuestionIndex < _questions.length - 1) {
        _currentQuestionIndex++;
      } else {
        // Quiz completed
        double score = _score / _questions.length;
        _onGameCompleted(score, _currentGameIndex);
      }
    });
  }

  Widget _buildQuizGame() {
    if (_questions.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 700;
        final questionBg =
            isLargeScreen
                ? 'assets/games/question_big.png'
                : 'assets/games/question_small_small.png';

        return Directionality(
          textDirection: TextDirection.rtl,
          child: Column(
            children: [
              // Question Container with Background
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(
                  vertical: 24,
                  horizontal: 16,
                ),
                height: 150, // Fixed height for consistency
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(questionBg),
                    fit: BoxFit.fill,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 16.0,
                    ),
                    child: Text(
                      currentQuestion['question'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.4,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

              // Answers List
              Expanded(
                child: ListView.builder(
                  itemCount: currentQuestion['answers'].length,
                  itemBuilder: (context, index) {
                    final answer = currentQuestion['answers'][index];
                    bool isSelected = _selectedAnswerIndex == index;
                    bool isCorrect =
                        _showFeedback &&
                        ((currentQuestion['type'] == 'verse_completion' ||
                                currentQuestion['type'] == 'next_verse')
                            ? answer == currentQuestion['correctAnswer']
                            : index == currentQuestion['correctIndex']);

                    final answerBg =
                        isLargeScreen
                            ? 'assets/games/answer_big.png'
                            : 'assets/games/answer_small_small.png';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap:
                              _showFeedback
                                  ? null
                                  : () => _checkQuizAnswer(index),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 60, // Fixed height for answer items
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(answerBg),
                                fit: BoxFit.fill,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Stack(
                              children: [
                                // Answer text
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    child: Text(
                                      answer,
                                      style: TextStyle(
                                        color: Color.fromARGB(
                                          255,
                                          255,
                                          255,
                                          255,
                                        ),
                                        fontWeight: FontWeight.bold,
                                        fontSize: isLargeScreen ? 24 : 20,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                                // Correct/Wrong icon (only shown when feedback is visible and answer is selected)
                                if (_showFeedback && isSelected)
                                  Positioned(
                                    right: 8,
                                    top: 0,
                                    bottom: 0,
                                    child: Center(
                                      child: Image.asset(
                                        isCorrect
                                            ? 'assets/games/correct_small.png'
                                            : 'assets/games/wrong_small.png',
                                        width: 24,
                                        height: 24,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Feedback Section
              if (_showFeedback)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isAnswerCorrect ? Colors.green[50] : Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color:
                          _isAnswerCorrect
                              ? Colors.green[200]!
                              : Colors.red[200]!,
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _isAnswerCorrect ? 'إجابة صحيحة! 🎉' : 'إجابة خاطئة',
                        style: TextStyle(
                          color:
                              _isAnswerCorrect
                                  ? Colors.green[800]
                                  : Colors.red[800],
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                      if (currentQuestion['explanation'] != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          currentQuestion['explanation'],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                _isAnswerCorrect ? Colors.green : Colors.red,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _nextQuestion,
                          child: Text(
                            isLastQuestion ? 'انتهى الاختبار' : 'السؤال التالي',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGameScreen() {
    if (!_isGameInProgress) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _games[_currentGameIndex]['icon'],
              size: 80,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 20),
            Text(
              _games[_currentGameIndex]['name'],
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              _games[_currentGameIndex]['description'],
              style: const TextStyle(fontSize: 20, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isGameInProgress = true;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 24,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                ),
                child: Text(
                  'ابدأ اللعبة',
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Return the actual game screen based on current game type
    switch (_games[_currentGameIndex]['type']) {
      case GameType.ayahOrdering:
        return _buildAyahOrderingGame();
      case GameType.quiz:
        return _buildQuizGame();
      default:
        return const Center(child: Text('لعبة غير متوفرة'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          _games[_currentGameIndex]['name'],
          style: GoogleFonts.tajawal(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        leading: const SizedBox(), // Remove default back button
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: BackgroundWidget(
        child: SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Stack(
              children: [
                _buildGameScreen(),
                if (!_isGameInProgress)
                  Positioned(
                    bottom: 20,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _games.length,
                        (index) => Container(
                          width: 30,
                          height: 30,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            color:
                                _scores[index] > 0
                                    ? (_scores[index] >=
                                            _games[index]['minScore']
                                        ? Colors.green
                                        : Colors.orange)
                                    : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                color:
                                    _scores[index] > 0
                                        ? Colors.white
                                        : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
