import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;
import 'package:quran/quran.dart' as quran;
import 'dart:math';
import '../widgets/background_widget.dart';

class AyahOrderingScreen extends StatefulWidget {
  final List<int> selectedSurahs;
  final Function(double) onGameCompleted;

  const AyahOrderingScreen({
    super.key,
    required this.selectedSurahs,
    required this.onGameCompleted,
  });

  @override
  State<AyahOrderingScreen> createState() => _AyahOrderingScreenState();
}

class _AyahOrderingScreenState extends State<AyahOrderingScreen> {
  late List<int> _availableSurahs = [];
  late int _selectedSurah;
  late List<Map<String, dynamic>> _verses =
      []; // Stores {text: verseText, number: verseNumber}
  late List<Map<String, dynamic>> _shuffledVerses = [];
  final Random _random = Random();

  // Get the next random surah from available surahs
  int _getNextSurah() {
    if (_availableSurahs.isEmpty) {
      // If we've used all surahs, reset the available list
      _availableSurahs = List.from(widget.selectedSurahs)..shuffle(_random);
    }

    // Remove and return the first surah in the shuffled list
    return _availableSurahs.removeAt(0);
  }

  @override
  void initState() {
    super.initState();
    // Initialize available surahs with a shuffled copy of the selected surahs
    _availableSurahs = List.from(widget.selectedSurahs)..shuffle(_random);
    _initializeGame();
  }

  void _initializeGame() {
    // Get the next surah from our queue
    _selectedSurah = _getNextSurah();

    // Get the total number of verses in the selected surah
    final int verseCount = quran.getVerseCount(_selectedSurah);

    // Make sure the surah has at least 5 verses
    if (verseCount < 5) {
      // If not enough verses, just use all available verses
      _verses = List.generate(verseCount, (index) {
        final verseNumber = index + 1;
        return {
          'text': quran.getVerse(
            _selectedSurah,
            verseNumber,
            verseEndSymbol: false,
          ),
          'number': verseNumber,
        };
      });
    } else {
      // Select a random starting point for 5 continuous verses
      final int startVerse =
          _random.nextInt(verseCount - 4) + 1; // +1 because verses start from 1

      // Get 5 continuous verses
      _verses = List.generate(5, (index) {
        final verseNumber = startVerse + index;
        return {
          'text': quran.getVerse(
            _selectedSurah,
            verseNumber,
            verseEndSymbol: false,
          ),
          'number': verseNumber,
        };
      });
    }

    // Create a shuffled copy of the verses
    _shuffledVerses = List.from(_verses)..shuffle(_random);

    if (mounted) setState(() {});
  }

  // Function to check the answer
  void _checkAnswer() {
    bool isCorrect = true;
    for (int i = 0; i < _verses.length; i++) {
      if (_shuffledVerses[i]['number'] != _verses[i]['number']) {
        isCorrect = false;
        break;
      }
    }

    // Show result
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              isCorrect ? 'إجابة صحيحة! 🎉' : 'إجابة خاطئة',
              style: GoogleFonts.notoKufiArabic(),
              textAlign: TextAlign.center,
            ),
            content: Text(
              isCorrect
                  ? 'أحسنت! لقد رتبت الآيات بشكل صحيح.'
                  : 'حاول مرة أخرى. تأكد من ترتيب الآيات بشكل صحيح.',
              style: GoogleFonts.notoKufiArabic(),
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (isCorrect) {
                    // Load new verses only if the answer was correct
                    _initializeGame();
                  }
                },
                child: Text('حسناً', style: GoogleFonts.notoKufiArabic()),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'ترتيب الآيات - سورة ${_verses.isNotEmpty ? quran.getSurahNameArabic(_selectedSurah) : ''}',
          style: GoogleFonts.amiri(
            fontSize: isPortrait ? 20 : 16,
            color: Colors.white,
          ),
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Game instructions and controls
              Card(
                color: isDarkMode ? Colors.blueGrey[800] : Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        'رتب الآيات بالترتيب الصحيح',
                        style: GoogleFonts.notoKufiArabic(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _checkAnswer,
                            icon: const Icon(Icons.check_circle_outline),
                            label: Text(
                              'تحقق',
                              style: GoogleFonts.notoKufiArabic(),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _initializeGame,
                            icon: const Icon(Icons.refresh),
                            label: Text(
                              'جديد',
                              style: GoogleFonts.notoKufiArabic(),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Draggable verses list
              Expanded(
                child: ReorderableListView.builder(
                  buildDefaultDragHandles: false, // We'll use custom drag handles
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (oldIndex < newIndex) {
                        newIndex--;
                      }
                      final Map<String, dynamic> item = _shuffledVerses.removeAt(oldIndex);
                      _shuffledVerses.insert(newIndex, item);
                    });
                  },
                  itemCount: _shuffledVerses.length,
                  itemBuilder: (context, index) {
                    final verse = _shuffledVerses[index];
                    return Card(
                      key: Key('verse_${verse['number']}'),
                      color: isDarkMode ? Colors.blueGrey[900] : Colors.grey[100],
                      margin: const EdgeInsets.symmetric(
                        vertical: 6.0,
                        horizontal: 8.0,
                      ),
                      elevation: 2,
                      child: InkWell(
                        onTap: () {},
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Drag handle with larger touch target
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                                child: ReorderableDragStartListener(
                                  index: index,
                                  child: Container(
                                    width: 40,
                                    height: 40,
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.drag_handle,
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                              // Vertical divider
                              Container(
                                width: 1,
                                height: 40,
                                color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                                margin: const EdgeInsets.symmetric(horizontal: 4.0),
                              ),
                              // Verse text
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                                  child: Text(
                                    verse['text'],
                                    style: GoogleFonts.amiri(
                                      fontSize: 20,
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                      height: 1.5,
                                    ),
                                    textAlign: TextAlign.right,
                                    textDirection: ui.TextDirection.rtl,
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

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
