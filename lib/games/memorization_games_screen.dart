import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
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

class _MemorizationGamesScreenState extends State<MemorizationGamesScreen> {
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

  // Quiz Game State
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  int? _selectedAnswerIndex;
  bool _showFeedback = false;
  bool _isAnswerCorrect = false;
  int _score = 0;

  List<double> _scores = [0, 0];
  bool _isGameInProgress = false;

  @override
  void initState() {
    super.initState();
    _isGameInProgress = true;
    _initializeCurrentGame();
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
          (context) => AlertDialog(
            title: Text(score >= 0.7 ? 'أحسنت! 🎉' : 'حاول مرة أخرى'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'لقد أتممت ${_games[gameIndex]['name']} بنجاح',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'نقاطك: ${(score * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();

                  // Move to next game or show final results
                  if (_currentGameIndex < _games.length - 1) {
                    setState(() {
                      _currentGameIndex++;
                      _isGameInProgress = true;
                      _initializeCurrentGame();
                    });
                  } else {
                    _showFinalResults();
                  }
                },
                child: Text(
                  _currentGameIndex < _games.length - 1
                      ? 'اللعبة التالية'
                      : 'إنهاء',
                ),
              ),
            ],
          ),
    );
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(passedOverall ? 'تهانينا! 🎉' : 'انتهت الاختبارات'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  passedOverall
                      ? 'لقد أتممت جميع الاختبارات بنجاح!'
                      : 'انتهت جميع الاختبارات.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(height: 16),
                Text(
                  'النتائج:',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  resultMessage,
                  style: GoogleFonts.amiri(fontSize: 20, height: 1.8),
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: 16),
                Text(
                  'المعدل النهائي: ${(averageScore * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: passedOverall ? Colors.green : Colors.orange,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(); // Go back to previous screen
                },
                child: const Text('إنهاء'),
              ),
              if (!passedOverall) ...[
                TextButton(
                  onPressed: () {
                    // Reset and retry
                    Navigator.of(context).pop();
                    setState(() {
                      _currentGameIndex = 0;
                      _scores = List.filled(_games.length, 0.0);
                      _isGameInProgress = true;
                      _initializeCurrentGame();
                    });
                  },
                  child: const Text('إعادة المحاولة'),
                ),
              ],
            ],
          ),
    );
  }

  // Ayah Ordering Game Methods
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

    // Calculate score based on number of correct positions
    int correctCount = 0;
    for (int i = 0; i < _verses.length; i++) {
      if (_shuffledVerses[i]['number'] == _verses[i]['number']) {
        correctCount++;
      }
    }
    double score = correctCount / _verses.length;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(isCorrect ? 'إجابة صحيحة! 🎉' : 'إجابة غير صحيحة'),
            content: Text(
              isCorrect
                  ? 'أحسنت! لقد رتبت الآيات بشكل صحيح.'
                  : 'حاول مرة أخرى. بعض الآيات ليست في مكانها الصحيح.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (isCorrect) {
                    _onGameCompleted(score, _currentGameIndex);
                  }
                },
                child: const Text('حسناً'),
              ),
            ],
          ),
    );
  }

  Widget _buildAyahOrderingGame() {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Column(
        children: [
          Expanded(
            child: ReorderableListView.builder(
              itemCount: _shuffledVerses.length,
              onReorder: _onAyahReorder,
              itemBuilder: (context, index) {
                final verse = _shuffledVerses[index];
                return Card(
                  key: ValueKey(verse['number']),
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 8,
                  ),
                  child: ListTile(
                    leading: CircleAvatar(child: Text('${verse['number']}')),
                    title: Text(
                      verse['text'],
                      style: GoogleFonts.amiriQuran(
                        fontSize: 20,
                        textStyle: const TextStyle(height: 1.8),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _checkAyahOrder,
              child: const Text('تحقق من الإجابة'),
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
                            // Background and tap target
                            Material(
                              color: Colors.white,
                              child: InkWell(
                                onTap: _showFeedback ? null : () => _checkQuizAnswer(index),
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12,
                                  ),
                                  child: Center(
                                    child: Text(
                                      answer,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                        fontSize: 20,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
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
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isGameInProgress = true;
                });
              },
              child: const Text('ابدأ اللعبة'),
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
