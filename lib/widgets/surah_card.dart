import 'package:flutter/material.dart';

class SurahCard extends StatelessWidget {
  final int surahNumber;
  final String surahName;
  final bool isUnlocked;

  // Fixed dimensions to match the image sizes
  static const double cardWidth = 170.0;
  static const double cardHeight = 200.0;

  // Star dimensions
  static const double _starWidth = 40.0;
  static const double _starHeight = 40.0;
  static const double _centerStarWidth = 49.0;
  static const double _centerStarHeight = 43.0;

  // Star positioning
  static const double _starTop = 0.0;
  static const double _starSideTop = 15.0;
  static const double _starSpacing = 5.0; // Space between stars

  const SurahCard({
    Key? key,
    required this.surahNumber,
    required this.surahName,
    required this.isUnlocked,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String imagePath =
        isUnlocked ? 'assets/cards/unlocked.png' : 'assets/cards/locked.png';

    return SizedBox(
      width: cardWidth,
      height: cardHeight,
      child: Stack(
        clipBehavior: Clip.none, // Allow children to overflow
        children: [
          // Background image with offset for unlocked cards
          Positioned(
            top:
                isUnlocked
                    ? cardHeight * 0.08
                    : 0.0, // 8% of card height if unlocked
            child: Image.asset(
              imagePath,
              width: cardWidth,
              height: cardHeight,
              fit: BoxFit.contain,
            ),
          ),

          // Surah name - positioned at 45% from top
          Positioned(
            left: 0,
            right: 0,
            top: cardHeight * 0.45, // 45% from top
            child: Center(
              child: Text(
                surahName,
                style: TextStyle(
                  fontSize: cardHeight * 0.15, // 15% of card height
                  color:
                      isUnlocked ? Colors.white : Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Stars (only for unlocked cards)
          if (isUnlocked) ..._buildStars(),
        ],
      ),
    );
  }

  List<Widget> _buildStars() {
    // Calculate total width of all stars and spacing
    final totalWidth = _starWidth * 2 + _centerStarWidth + _starSpacing * 2;

    // Calculate starting position to center the stars
    final startX = (cardWidth - totalWidth) / 2;

    return [
      // Left star
      Positioned(
        left: startX,
        top: _starSideTop,
        child: Image.asset(
          'assets/cards/star_side.png',
          width: _starWidth,
          height: _starHeight,
        ),
      ),
      // Center star
      Positioned(
        left: startX + _starWidth + _starSpacing,
        top: _starTop,
        child: Image.asset(
          'assets/cards/star_mid.png',
          width: _centerStarWidth,
          height: _centerStarHeight,
        ),
      ),
      // Right star
      Positioned(
        left: startX + _starWidth + _centerStarWidth + _starSpacing * 2,
        top: _starSideTop,
        child: Image.asset(
          'assets/cards/star_side.png',
          width: _starWidth,
          height: _starHeight,
        ),
      ),
    ];
  }
}
