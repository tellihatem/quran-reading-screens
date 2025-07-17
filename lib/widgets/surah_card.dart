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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the minimum of width and height to maintain aspect ratio
        final cardWidth = constraints.maxWidth;
        final cardHeight = constraints.maxHeight;
        
        return Stack(
          clipBehavior: Clip.none, // Allow children to overflow
          children: [
            // Background image with offset for unlocked cards
            Positioned(
              top: isUnlocked ? cardHeight * 0.08 : 0.0, // 8% of card height if unlocked
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
                    color: isUnlocked ? Colors.white : Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Stars (only for unlocked cards)
            if (isUnlocked) ..._buildStars(cardWidth, cardHeight),
          ],
        );
      },
    );
  }

  List<Widget> _buildStars(double cardWidth, double cardHeight) {
    // Calculate dimensions as ratios of card size
    final starWidth = cardWidth * (_starWidth / 170.0);
    final starHeight = cardHeight * (_starHeight / 200.0);
    final centerStarWidth = cardWidth * (_centerStarWidth / 170.0);
    final centerStarHeight = cardHeight * (_centerStarHeight / 200.0);
    final starSpacing = cardWidth * (_starSpacing / 170.0);
    
    // Calculate total width of all stars and spacing
    final totalWidth = starWidth * 2 + centerStarWidth + starSpacing * 2;
    
    // Calculate starting position to center the stars
    final startX = (cardWidth - totalWidth) / 2;
    final starTop = cardHeight * (_starTop / 200.0);
    final starSideTop = cardHeight * (_starSideTop / 200.0);

    return [
      // Left star
      Positioned(
        left: startX,
        top: starSideTop,
        child: Image.asset(
          'assets/cards/star_side.png',
          width: starWidth,
          height: starHeight,
        ),
      ),
      // Center star
      Positioned(
        left: startX + starWidth + starSpacing,
        top: starTop,
        child: Image.asset(
          'assets/cards/star_mid.png',
          width: centerStarWidth,
          height: centerStarHeight,
        ),
      ),
      // Right star
      Positioned(
        left: startX + starWidth + centerStarWidth + starSpacing * 2,
        top: starSideTop,
        child: Image.asset(
          'assets/cards/star_side.png',
          width: starWidth,
          height: starHeight,
        ),
      ),
    ];
  }
}
