import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'dart:math';
import 'dart:async';
import 'dart:ui' as ui;
import '../widgets/background_widget.dart';
import 'package:confetti/confetti.dart';

enum QuestionType { textCompletion, nextAyah, surahName }

class Question {
  final String text;
  final List<String> answers;
  final int correctAnswerIndex;
  final String explanation;
  final QuestionType type;

  Question({
    required this.text,
    required this.answers,
    required this.correctAnswerIndex,
    required this.explanation,
    required this.type,
  });
}

class QuizGameScreen extends StatefulWidget {
  final List<int> selectedSurahs;
  final Function(double) onGameCompleted;

  const QuizGameScreen({
    super.key, 
    required this.selectedSurahs,
    required this.onGameCompleted,
  });

  @override
  State<QuizGameScreen> createState() => _QuizGameScreenState();
}

class _QuizGameScreenState extends State<QuizGameScreen>
    with SingleTickerProviderStateMixin {
  late List<Question> _questions = [];
  int _currentQuestionIndex = 0;
  int _score = 0;
  int? _selectedAnswerIndex;
  bool _showFeedback = false;
  bool _isAnswerCorrect = false;
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  final Random _random = Random();
  late List<int> _availableSurahs = [];
  late int _totalQuestions; // Will be set based on selected surahs

  // Get neighboring surahs (n-2, n-1, n+1, n+2, 1) for answer options
  List<int> _getNeighboringSurahs(int surah) {
    final neighbors = <int>{};

    // Add the current surah
    neighbors.add(surah);

    // Add neighboring surahs
    if (surah > 1) neighbors.add(surah - 1);
    if (surah > 2) neighbors.add(surah - 2);
    if (surah < 114) neighbors.add(surah + 1);
    if (surah < 113) neighbors.add(surah + 2);

    // Always include Surah Al-Fatiha (1) if not already included
    if (!neighbors.contains(1)) {
      neighbors.add(1);
    }

    // Convert to list and ensure all values are valid surah numbers (1-114)
    return neighbors.where((s) => s >= 1 && s <= 114).toList()
      ..shuffle(_random);
  }

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _availableSurahs = List.from(widget.selectedSurahs)..shuffle(_random);
    _loadQuestions();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  int _getNextSurah() {
    if (_availableSurahs.isEmpty) {
      _availableSurahs = List.from(widget.selectedSurahs)..shuffle(_random);
    }
    return _availableSurahs.removeAt(0);
  }

  // Calculate the maximum number of questions we can generate based on surah lengths
  int _calculateMaxQuestions() {
    if (widget.selectedSurahs.isEmpty) return 0;

    // For multiple surahs, use the default number of questions (10)
    if (widget.selectedSurahs.length > 1) {
      return 10;
    }

    // For a single surah, calculate based on verse count
    final surah = widget.selectedSurahs.first;
    final verseCount = quran.getVerseCount(surah);

    // We need at least 2 verses per question (current and next verse)
    final maxPossibleQuestions = (verseCount / 2).floor();

    // Limit based on verse count but don't exceed the maximum possible
    if (verseCount <= 10) return min(3, maxPossibleQuestions);
    if (verseCount <= 20) return min(5, maxPossibleQuestions);
    if (verseCount <= 50) return min(7, maxPossibleQuestions);

    return min(10, maxPossibleQuestions);
  }

  // Track used verses to prevent duplicates
  final Map<int, Set<int>> _usedVerses = {};

  // Check if a verse has already been used in a question
  bool _isVerseUsed(int surah, int verse) {
    return _usedVerses[surah]?.contains(verse) ?? false;
  }

  // Mark a verse as used
  void _markVerseAsUsed(int surah, int verse) {
    _usedVerses.putIfAbsent(surah, () => {}).add(verse);
  }

  // Reset used verses
  void _resetUsedVerses() {
    _usedVerses.clear();
  }

  Future<void> _loadQuestions() async {
    final questions = <Question>[];
    _resetUsedVerses();

    // Make sure we have enough verses to create questions
    if (widget.selectedSurahs.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الرجاء اختيار سور صالحة للعبة')),
        );
        Navigator.pop(context);
      }
      return;
    }

    // Check if only one surah is selected
    final bool isSingleSurah = widget.selectedSurahs.length == 1;

    // Calculate the appropriate number of questions
    _totalQuestions = _calculateMaxQuestions();

    // If we can't generate any questions, show an error
    if (_totalQuestions == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا توجد آيات كافية لإنشاء الأسئلة')),
        );
        Navigator.pop(context);
      }
      return;
    }

    // Track how many questions we've successfully generated
    int questionsGenerated = 0;
    int totalAttempts = 0;
    const int maxTotalAttempts = 50; // Prevent infinite loops

    while (questionsGenerated < _totalQuestions &&
        totalAttempts < maxTotalAttempts &&
        mounted) {
      totalAttempts++;

      final surah = _getNextSurah();
      final verseCount = quran.getVerseCount(surah);

      // Skip if surah doesn't have enough verses
      if (verseCount < 2) continue;

      // Find a verse that hasn't been used yet
      int verseNumber;
      int verseAttempts = 0;
      final maxVerseAttempts = verseCount * 2;

      // Removed unused variable

      do {
        // Randomly select a verse that's not the last one (so we can get the next verse)
        verseNumber = _random.nextInt(verseCount - 1) + 1;
        verseAttempts++;

        // If we've tried too many times, give up on this surah
        if (verseAttempts >= maxVerseAttempts) {
          break;
        }
      } while (_isVerseUsed(surah, verseNumber) ||
          _isVerseUsed(surah, verseNumber + 1));

      // If we couldn't find a valid verse pair, try the next surah
      if (verseAttempts >= maxVerseAttempts) continue;

      // Mark these verses as used
      _markVerseAsUsed(surah, verseNumber);
      _markVerseAsUsed(surah, verseNumber + 1);

      // Get the current verse and the next one
      final currentVerse = quran.getVerse(
        surah,
        verseNumber,
        verseEndSymbol: false,
      );
      final nextVerse = quran.getVerse(
        surah,
        verseNumber + 1,
        verseEndSymbol: false,
      );

      // Skip if we couldn't get the verses
      if (currentVerse.isEmpty || nextVerse.isEmpty) continue;

      // Create different types of questions
      // If only one surah is selected, only generate text completion or next ayah questions
      final questionType =
          isSingleSurah
              ? _random.nextInt(2) // 0 or 1 (text completion or next ayah)
              : _random.nextInt(3); // 0, 1, or 2 (all question types)

      // Generate the question based on type
      switch (questionType) {
        case 0: // Text completion
          final words = currentVerse.split(' ');
          if (words.length > 2) {
            final missingWordIndex = _random.nextInt(words.length - 1) + 1;
            final correctAnswer = words[missingWordIndex];

            // Skip if the correct answer is too short or contains special characters
            if (correctAnswer.length < 2 || correctAnswer.trim().isEmpty) break;

            // Generate wrong answers (similar words from other verses)
            final wrongAnswers = <String>{};
            final sourceSurahs =
                isSingleSurah
                    ? _getNeighboringSurahs(surah)
                    : widget.selectedSurahs;

            int wordAttempts = 0;
            const int maxWordAttempts = 20;

            while (wrongAnswers.length < 3 && wordAttempts < maxWordAttempts) {
              wordAttempts++;
              final randomSurah =
                  sourceSurahs[_random.nextInt(sourceSurahs.length)];
              final randomVerse =
                  _random.nextInt(quran.getVerseCount(randomSurah)) + 1;
              final verse = quran.getVerse(
                randomSurah,
                randomVerse,
                verseEndSymbol: false,
              );
              final verseWords = verse.split(' ');

              if (verseWords.length > 2) {
                final word =
                    verseWords[_random.nextInt(verseWords.length)].trim();
                if (word.length > 1 &&
                    word != correctAnswer &&
                    !wrongAnswers.contains(word)) {
                  wrongAnswers.add(word);
                }
              }
            }

            // If we don't have enough wrong answers, add some placeholders
            while (wrongAnswers.length < 3) {
              wrongAnswers.add('كلمة${wrongAnswers.length + 1}');
            }

            // Create question with missing word
            final questionText = currentVerse.replaceFirst(
              correctAnswer,
              '______',
            );
            final answers = [correctAnswer, ...wrongAnswers.take(3)]
              ..shuffle(_random);
            final correctIndex = answers.indexOf(correctAnswer);

            if (correctIndex >= 0) {
              // Make sure correct answer is in the list
              questions.add(
                Question(
                  text: 'أكمل الآية: $questionText',
                  answers: answers,
                  correctAnswerIndex: correctIndex,
                  explanation: currentVerse,
                  type: QuestionType.textCompletion,
                ),
              );
              questionsGenerated++;
            }
          }
          break;

        case 1: // Next ayah
          List<int> sourceSurahs;
          if (isSingleSurah) {
            // For single surah, use the current surah for both question and answer
            sourceSurahs = [surah];
          } else {
            sourceSurahs = List<int>.from(widget.selectedSurahs)..remove(surah);
          }

          final wrongAnswers = <String>{};

          // Get wrong answers from other verses in the same surah or neighboring surahs
          for (int j = 0; j < 10 && wrongAnswers.length < 3; j++) {
            final sourceSurah =
                sourceSurahs[_random.nextInt(sourceSurahs.length)];
            final verseCount = quran.getVerseCount(sourceSurah);

            // Make sure we don't select the same verse
            int wrongVerseNumber;
            do {
              wrongVerseNumber = _random.nextInt(verseCount) + 1;
            } while (sourceSurah == surah &&
                (wrongVerseNumber == verseNumber ||
                    wrongVerseNumber == verseNumber + 1));

            final wrongVerse = quran.getVerse(
              sourceSurah,
              wrongVerseNumber,
              verseEndSymbol: false,
            );
            if (wrongVerse != nextVerse) {
              wrongAnswers.add(wrongVerse);
            }
          }

          final answers = [nextVerse, ...wrongAnswers.take(3)]
            ..shuffle(_random);
          final correctIndex = answers.indexOf(nextVerse);

          questions.add(
            Question(
              text: 'ما الآية التالية بعد: "$currentVerse"؟',
              answers: answers,
              correctAnswerIndex: correctIndex,
              explanation: 'الآية التالية هي: $nextVerse',
              type: QuestionType.nextAyah,
            ),
          );
          break;

        case 2: // Surah name
          final surahName = quran.getSurahNameArabic(surah);
          final sourceSurahs =
              isSingleSurah
                    ? _getNeighboringSurahs(surah)
                    : List<int>.from(widget.selectedSurahs)
                ..remove(surah);

          final wrongAnswers = <String>{};

          // Get wrong answers from neighboring surahs or selected surahs
          for (
            int j = 0;
            j < sourceSurahs.length && wrongAnswers.length < 3;
            j++
          ) {
            final wrongSurah = sourceSurahs[j];
            if (wrongSurah != surah) {
              wrongAnswers.add(quran.getSurahNameArabic(wrongSurah));
            }
          }

          // If we don't have enough wrong answers, add some from the beginning
          int nextSurah = 1;
          while (wrongAnswers.length < 3 && nextSurah <= 114) {
            if (nextSurah != surah && !sourceSurahs.contains(nextSurah)) {
              wrongAnswers.add(quran.getSurahNameArabic(nextSurah));
            }
            nextSurah++;
          }

          final answers = [surahName, ...wrongAnswers.take(3)]
            ..shuffle(_random);
          final correctIndex = answers.indexOf(surahName);

          questions.add(
            Question(
              text: 'في أي سورة توجد هذه الآية؟ "$currentVerse"',
              answers: answers,
              correctAnswerIndex: correctIndex,
              explanation: 'الآية من سورة $surahName',
              type: QuestionType.surahName,
            ),
          );
          break;
      }
    }

    setState(() {
      _questions = questions;
    });
  }

  void _checkAnswer(int selectedIndex) {
    if (_showFeedback || !mounted)
      return; // Prevent multiple taps and handle widget disposal

    setState(() {
      _selectedAnswerIndex = selectedIndex;
      _isAnswerCorrect =
          selectedIndex == _questions[_currentQuestionIndex].correctAnswerIndex;
      _showFeedback = true;

      if (_isAnswerCorrect) {
        _score++;
        _confettiController.play();
      } else {
        _animationController.reset();
        _animationController.forward();
      }
    });

    // Move to next question after delay
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showFeedback = false;
          _selectedAnswerIndex = null;

          if (_currentQuestionIndex < _questions.length - 1) {
            _currentQuestionIndex++;
          } else {
            // Game over
            _showResults();
          }
        });
      }
    });
  }

  void _showResults() {
    final percentage = (_score / _totalQuestions * 100).round();
    String resultMessage;

    if (percentage >= 80) {
      resultMessage = 'ممتاز! لقد حصلت على $percentage%';
    } else if (percentage >= 60) {
      resultMessage = 'جيد جداً! لقد حصلت على $percentage%';
    } else if (percentage >= 40) {
      resultMessage = 'حسناً! لقد حصلت على $percentage%';
    } else {
      resultMessage = 'حاول مرة أخرى! لقد حصلت على $percentage%';
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text(
              'انتهت الأسئلة!',
              style: GoogleFonts.notoKufiArabic(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  resultMessage,
                  style: GoogleFonts.notoKufiArabic(fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'الإجابات الصحيحة: $_score من $_totalQuestions',
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentQuestionIndex = 0;
                    _score = 0;
                    _loadQuestions();
                  });
                },
                child: Text(
                  'إعادة المحاولة',
                  style: GoogleFonts.notoKufiArabic(),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: Text('إنهاء', style: GoogleFonts.notoKufiArabic()),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) return const SizedBox.shrink();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'اختر الإجابة الصحيحة',
          style: GoogleFonts.amiri(fontSize: 24, color: Colors.white),
        ),
        backgroundColor:
            isDarkMode
                ? const Color(0xFF2196F3)
                : Theme.of(context).appBarTheme.backgroundColor,
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'رجوع',
          ),
        ],
      ),
      body: BackgroundWidget(
        child: Stack(
          children: [
            if (_questions.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Progress bar
                    LinearProgressIndicator(
                      value: (_currentQuestionIndex + 1) / _totalQuestions,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Question counter
                    Text(
                      'سؤال ${_currentQuestionIndex + 1} من $_totalQuestions',
                      style: GoogleFonts.notoKufiArabic(
                        fontSize: 16,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    // Question card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _questions[_currentQuestionIndex].text,
                          style: GoogleFonts.amiri(fontSize: 22, height: 1.6),
                          textAlign: TextAlign.center,
                          textDirection: ui.TextDirection.rtl,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Answer options
                    Expanded(
                      child: ListView.builder(
                        itemCount:
                            _questions[_currentQuestionIndex].answers.length,
                        itemBuilder: (context, index) {
                          final isSelected = _selectedAnswerIndex == index;
                          final isCorrect =
                              _questions[_currentQuestionIndex]
                                  .correctAnswerIndex ==
                              index;

                          Color backgroundColor =
                              isDarkMode ? Colors.grey[800]! : Colors.white;
                          Color borderColor = Colors.grey[300]!;

                          if (_showFeedback) {
                            if (isSelected) {
                              backgroundColor =
                                  isCorrect
                                      ? Colors.green.withOpacity(0.2)
                                      : Colors.red.withOpacity(0.2);
                              borderColor =
                                  isCorrect ? Colors.green : Colors.red;
                            } else if (isCorrect) {
                              backgroundColor = Colors.green.withOpacity(0.2);
                              borderColor = Colors.green;
                            }
                          }

                          return AnimatedBuilder(
                            animation: _animationController,
                            builder: (context, child) {
                              return Transform.translate(
                                offset:
                                    isSelected &&
                                            !_isAnswerCorrect &&
                                            _showFeedback
                                        ? Offset(
                                          sin(_animationController.value * 10) *
                                              10,
                                          0,
                                        )
                                        : Offset.zero,
                                child: child,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8.0,
                                horizontal: 16.0,
                              ),
                              child: Material(
                                borderRadius: BorderRadius.circular(12),
                                color: backgroundColor,
                                elevation: 2,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () => _checkAnswer(index),
                                  child: Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: borderColor,
                                        width: 2,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? (isCorrect
                                                        ? Colors.green
                                                        : Colors.red)
                                                    : Theme.of(
                                                      context,
                                                    ).primaryColor,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Text(
                                            _questions[_currentQuestionIndex]
                                                .answers[index],
                                            style: GoogleFonts.amiri(
                                              fontSize: 18,
                                              height: 1.6,
                                            ),
                                            textAlign: TextAlign.right,
                                            textDirection: ui.TextDirection.rtl,
                                          ),
                                        ),
                                        if (_showFeedback && isSelected)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                              right: 8.0,
                                            ),
                                            child: Icon(
                                              isCorrect
                                                  ? Icons.check_circle
                                                  : Icons.cancel,
                                              color:
                                                  isCorrect
                                                      ? Colors.green
                                                      : Colors.red,
                                              size: 24,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Feedback message
                    if (_showFeedback)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  _isAnswerCorrect
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    _isAnswerCorrect
                                        ? Colors.green
                                        : Colors.red,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isAnswerCorrect
                                      ? Icons.check_circle
                                      : Icons.info_outline,
                                  color:
                                      _isAnswerCorrect
                                          ? Colors.green
                                          : Colors.red,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _isAnswerCorrect
                                        ? 'إجابة صحيحة! أحسنت!'
                                        : 'الجواب الصحيح: ${_questions[_currentQuestionIndex].answers[_questions[_currentQuestionIndex].correctAnswerIndex]}',
                                    style: GoogleFonts.notoKufiArabic(
                                      color:
                                          _isAnswerCorrect
                                              ? Colors.green
                                              : Colors.red,
                                      fontSize: 16,
                                    ),
                                    textDirection: ui.TextDirection.rtl,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
