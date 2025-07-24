import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'dart:math';
import 'dart:async';
import 'dart:ui' as ui;
import '../widgets/background_widget.dart';
import '../widgets/surah_card.dart';

class MemoryGameScreen extends StatefulWidget {
  final List<int> selectedSurahs;
  final Function(double) onGameCompleted;

  const MemoryGameScreen({
    super.key, 
    required this.selectedSurahs,
    required this.onGameCompleted,
  });

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  late List<MemoryCard> _cards = [];
  int _pairsMatched = 0;
  int _attempts = 0;
  int? _firstCardIndex;
  int? _secondCardIndex;
  bool _canFlip = true;
  late int _selectedSurah;
  final Random _random = Random();
  late List<int> _availableSurahs = [];
  Timer? _flipBackTimer;


  @override
  void initState() {
    super.initState();
    _availableSurahs = List.from(widget.selectedSurahs)..shuffle(_random);
    _initializeGame();
  }

  @override
  void dispose() {
    _flipBackTimer?.cancel();
    super.dispose();
  }

  int _getNextSurah() {
    if (_availableSurahs.isEmpty) {
      _availableSurahs = List.from(widget.selectedSurahs)..shuffle(_random);
    }
    return _availableSurahs.removeAt(0);
  }

  void _initializeGame() {
    // If we've gone through all surahs, reset the queue
    if (_availableSurahs.isEmpty) {
      _availableSurahs = List.from(widget.selectedSurahs)..shuffle(_random);
    }
    
    _selectedSurah = _getNextSurah();
    final int verseCount = quran.getVerseCount(_selectedSurah);
    
    // For memory game, we'll use 5-10 unique verses (10-20 cards total)
    // But make sure we don't exceed the number of available verses
    final int maxPossiblePairs = min(10, (verseCount / 2).floor());
    final int minPossiblePairs = 5;
    
    int numPairs;
    if (maxPossiblePairs < minPossiblePairs) {
      // If surah has very few verses, use all available verses
      numPairs = max(1, verseCount);
    } else {
      // Otherwise, use between 5-10 pairs (or max available)
      numPairs = min(10, max(minPossiblePairs, _random.nextInt(maxPossiblePairs - minPossiblePairs + 1) + minPossiblePairs));
    }
    
    // Select a random starting point for the verses
    final int startVerse = _random.nextInt(verseCount - numPairs + 1) + 1;
    
    // Create pairs of verses
    List<MemoryCard> cards = [];
    for (int i = 0; i < numPairs; i++) {
      final verseNumber = startVerse + i;
      final verseText = quran.getVerse(_selectedSurah, verseNumber, verseEndSymbol: false);
      
      // Add two identical cards for each verse
      cards.add(MemoryCard(
        id: '${_selectedSurah}_$verseNumber-1',
        verseText: verseText,
        verseNumber: verseNumber,
        surahNumber: _selectedSurah,
        isFlipped: false,
        isMatched: false,
      ));
      
      cards.add(MemoryCard(
        id: '${_selectedSurah}_$verseNumber-2',
        verseText: verseText,
        verseNumber: verseNumber,
        surahNumber: _selectedSurah,
        isFlipped: false,
        isMatched: false,
      ));
    }
    
    // Shuffle the cards
    cards.shuffle(_random);
    
    setState(() {
      _cards = cards;
      _pairsMatched = 0;
      _attempts = 0;
      _firstCardIndex = null;
      _secondCardIndex = null;
      _canFlip = true;
    });
  }

  void _onCardTapped(int index) {
    if (!_canFlip || _cards[index].isFlipped || _cards[index].isMatched) {
      return;
    }

    setState(() {
      _cards[index] = _cards[index].copyWith(isFlipped: true);
      
      if (_firstCardIndex == null) {
        _firstCardIndex = index;
      } else if (_secondCardIndex == null) {
        _secondCardIndex = index;
        _attempts++;
        _checkForMatch();
      }
    });
  }

  void _checkForMatch() {
    if (_firstCardIndex == null || _secondCardIndex == null) return;
    
    final firstCard = _cards[_firstCardIndex!];
    final secondCard = _cards[_secondCardIndex!];
    
    if (firstCard.verseNumber == secondCard.verseNumber) {
      // Match found
      setState(() {
        _cards[_firstCardIndex!] = firstCard.copyWith(isMatched: true);
        _cards[_secondCardIndex!] = secondCard.copyWith(isMatched: true);
        _pairsMatched++;
        
        // Check if game is complete
        if (_pairsMatched * 2 == _cards.length) {
          _showGameCompleteDialog();
        }
        
        _firstCardIndex = null;
        _secondCardIndex = null;
      });
    } else {
      // No match, flip cards back after delay
      _canFlip = false;
      _flipBackTimer?.cancel();
      _flipBackTimer = Timer(const Duration(milliseconds: 1000), () {
        setState(() {
          _cards[_firstCardIndex!] = _cards[_firstCardIndex!].copyWith(isFlipped: false);
          _cards[_secondCardIndex!] = _cards[_secondCardIndex!].copyWith(isFlipped: false);
          _firstCardIndex = null;
          _secondCardIndex = null;
          _canFlip = true;
        });
      });
    }
  }

  void _showGameCompleteDialog() {
    final bool hasMoreSurahs = _availableSurahs.isNotEmpty;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'تهانين! 🎉',
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
              'لقد أكملت سورة ${quran.getSurahNameArabic(_selectedSurah)} بنجاح!',
              style: GoogleFonts.notoKufiArabic(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'عدد المحاولات: $_attempts',
              style: GoogleFonts.notoKufiArabic(fontSize: 16),
            ),
            if (hasMoreSurahs) ...[
              const SizedBox(height: 16),
              Text(
                '${_availableSurahs.length} سورة متبقية',
                style: GoogleFonts.notoKufiArabic(
                  fontSize: 16,
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        actions: [
          // Play Again / Next Surah button
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (hasMoreSurahs) {
                _initializeGame(); // Load next surah
              } else {
                // Calculate score (higher is better, max 100%)
                final maxPossibleAttempts = _cards.length * 2; // Rough estimate
                final score = (1 - (_attempts / maxPossibleAttempts)) * 100;
                widget.onGameCompleted(score.clamp(0.0, 100.0));
                Navigator.of(context).pop(); // Close game screen
              }
            },
            child: Text(
              hasMoreSurahs ? 'السورة التالية' : 'إعادة اللعبة',
              style: GoogleFonts.notoKufiArabic(),
            ),
          ),
          
          // Restart / Exit button
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              if (hasMoreSurahs) {
                // Restart with first surah
                _availableSurahs = List.from(widget.selectedSurahs)..shuffle(_random);
                _initializeGame();
              } else {
                // Calculate score and exit
                final maxPossibleAttempts = _cards.length * 2;
                final score = (1 - (_attempts / maxPossibleAttempts)) * 100;
                widget.onGameCompleted(score.clamp(0.0, 100.0));
                Navigator.of(context).pop(); // Close game screen
              }
            },
            child: Text(
              hasMoreSurahs ? 'إعادة من البداية' : 'إنهاء',
              style: GoogleFonts.notoKufiArabic(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bool isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'لعبة الذاكرة - سورة ${quran.getSurahNameArabic(_selectedSurah)}',
          style: GoogleFonts.amiri(fontSize: isPortrait ? 20 : 16, color: Colors.white),
        ),
        backgroundColor: isDarkMode
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
        child: Column(
          children: [
            // Game stats
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    'الأزواج',
                    '$_pairsMatched / ${_cards.length ~/ 2}',
                    Icons.star,
                    Colors.amber,
                  ),
                  _buildStatCard(
                    'المحاولات',
                    '$_attempts',
                    Icons.repeat,
                    Colors.blue,
                  ),
                ],
              ),
            ),
            
            // Game grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: SurahCard.cardWidth + 24, // Card width + spacing
                  childAspectRatio: SurahCard.cardWidth / SurahCard.cardHeight,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  mainAxisExtent: SurahCard.cardHeight,
                ),
                itemCount: _cards.length,
                itemBuilder: (context, index) {
                  return _buildCard(_cards[index], index);
                },
              ),
            ),
            
            // Controls
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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

  Widget _buildCard(MemoryCard card, int index) {
    return GestureDetector(
      onTap: () => _onCardTapped(index),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final rotateAnim = Tween(begin: pi, end: 0.0).animate(animation);
          return AnimatedBuilder(
            animation: rotateAnim,
            child: child,
            builder: (context, child) {
              final isBack = card.isFlipped || card.isMatched;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.rotationY(isBack ? 0 : pi),
                child: isBack ? child : _buildCardBack(),
              );
            },
          );
        },
        child: card.isFlipped || card.isMatched
            ? _buildCardFront(card)
            : _buildCardBack(),
      ),
    );
  }

  Widget _buildCardFront(MemoryCard card) {
    return Container(
      width: SurahCard.cardWidth,
      height: SurahCard.cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background image
          Positioned(
            top: SurahCard.cardHeight * 0.08,
            child: Image.asset(
              'assets/cards/unlocked.png',
              width: SurahCard.cardWidth,
              height: SurahCard.cardHeight,
              fit: BoxFit.contain,
            ),
          ),
          
          // Verse text - centered
          Positioned(
            left: 8,
            right: 8,
            top: SurahCard.cardHeight * 0.3,
            bottom: SurahCard.cardHeight * 0.2,
            child: SingleChildScrollView(
              child: Text(
                card.verseText,
                style: GoogleFonts.amiri(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.5,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                textDirection: ui.TextDirection.rtl,
              ),
            ),
          ),
          
          // Verse number at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: SurahCard.cardHeight * 0.05,
            child: Center(
              child: Text(
                'آية ${card.verseNumber}',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: SurahCard.cardWidth,
      height: SurahCard.cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background image (same as front but with a different tint)
          Positioned(
            top: 0,
            child: Image.asset(
              'assets/cards/locked.png',
              width: SurahCard.cardWidth,
              height: SurahCard.cardHeight,
              fit: BoxFit.contain,
            ),
          ),
          
          // Book icon in the center
          Positioned(
            top: SurahCard.cardHeight * 0.3,
            left: 0,
            right: 0,
            child: const Center(
              child: Icon(
                Icons.menu_book,
                size: 50,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.notoKufiArabic(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.notoKufiArabic(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MemoryCard {
  final String id;
  final String verseText;
  final int verseNumber;
  final int surahNumber;
  final bool isFlipped;
  final bool isMatched;

  const MemoryCard({
    required this.id,
    required this.verseText,
    required this.verseNumber,
    required this.surahNumber,
    this.isFlipped = false,
    this.isMatched = false,
  });

  MemoryCard copyWith({
    String? id,
    String? verseText,
    int? verseNumber,
    int? surahNumber,
    bool? isFlipped,
    bool? isMatched,
  }) {
    return MemoryCard(
      id: id ?? this.id,
      verseText: verseText ?? this.verseText,
      verseNumber: verseNumber ?? this.verseNumber,
      surahNumber: surahNumber ?? this.surahNumber,
      isFlipped: isFlipped ?? this.isFlipped,
      isMatched: isMatched ?? this.isMatched,
    );
  }
}
