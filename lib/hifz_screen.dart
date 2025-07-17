import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haffiz/widgets/surah_card.dart';
import 'package:quran/quran.dart';
import 'widgets/background_widget.dart';

class HifzScreen extends StatelessWidget {
  const HifzScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundWidget(
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Row(
                      children: [
                        _buildCounter(
                          icon: const Icon(
                            Icons.star,
                            color: Color(0xFFFFD700),
                          ),
                          count: 5, // Replace with actual star count
                          color: const Color(0xFFFFD700),
                        ),
                        const SizedBox(width: 20),
                        _buildCounter(
                          icon: const Icon(
                            Icons.favorite,
                            color: Color(0xFFE91E63),
                          ),
                          count: 3, // Replace with actual heart count
                          color: const Color(0xFFE91E63),
                        ),
                        const SizedBox(width: 20),
                        _buildCounter(
                          icon: const Icon(
                            Icons.menu_book,
                            color: Color(0xFF967E5D),
                          ),
                          count: 2, // Replace with actual surah count
                          color: const Color(0xFF967E5D),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xFF2196F3)
                              : Colors.white,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: LayoutBuilder(
                builder: (context, constraints) {
                  // Calculate the number of columns based on screen width
                  final double screenWidth = constraints.maxWidth;
                  int crossAxisCount = 2; // Default for small screens
                  
                  if (screenWidth > 600) {
                    crossAxisCount = 3; // For medium screens
                  }
                  if (screenWidth > 900) {
                    crossAxisCount = 4; // For large screens
                  }
                  if (screenWidth > 1200) {
                    crossAxisCount = 5; // For extra large screens
                  }
                  
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                  itemCount: 114, // Total number of surahs in the Quran
                  itemBuilder: (context, index) {
                    // Generate surah numbers in order: 1, 114, 113, ..., 2
                    final surahNumber = index == 0 ? 1 : 115 - index;
                    final surahName = getSurahNameArabic(surahNumber);

                    // Only Surah 1 (Al-Fatiha) is unlocked by default
                    final isUnlocked = surahNumber == 1;
                    return SurahCard(
                      surahNumber: surahNumber,
                      surahName: surahName,
                      isUnlocked: isUnlocked,
                    );
                  },
                  );
                },
              ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounter({
    required Widget icon,
    required int count,
    required Color color, // color for the icon, not the badge
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF7C4F19), // rich brown
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFFFD700),
          width: 3,
        ), // yellow border
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.5),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: icon,
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              '$count',
              style: GoogleFonts.notoKufiArabic(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
