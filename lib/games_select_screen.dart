import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/background_widget.dart';
import 'games/ayah_ordering_screen.dart';
import 'games/surah_selection_for_game_screen.dart';
import 'games/memory_game_screen.dart';
import 'games/quiz_game_screen.dart';

class GamesSelectScreen extends StatefulWidget {
  const GamesSelectScreen({super.key});

  @override
  State<GamesSelectScreen> createState() => _GamesSelectScreenState();
}

class _GamesSelectScreenState extends State<GamesSelectScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الألعاب',
          style: GoogleFonts.amiri(fontSize: 24, color: Colors.white),
        ),
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGameCard(
                context: context,
                title: 'لعبة الذاكرة',
                icon: Icons.memory,
                onTap: () async {
                  final surahs = await showSurahSelectionForGame(
                    context: context,
                    gameTitle: 'لعبة الذاكرة',
                  );
                  if (surahs != null && surahs.isNotEmpty) {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MemoryGameScreen(selectedSurahs: surahs),
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 20),
              _buildGameCard(
                context: context,
                title: 'ترتيب الآيات',
                icon: Icons.sort_by_alpha,
                onTap: () async {
                  final surahs = await showSurahSelectionForGame(
                    context: context,
                    gameTitle: 'ترتيب الآيات',
                  );
                  if (surahs != null && surahs.isNotEmpty) {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  AyahOrderingScreen(selectedSurahs: surahs),
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 20),
              _buildGameCard(
                context: context,
                title: 'اختر الإجابة الصحيحة',
                icon: Icons.quiz,
                onTap: () async {
                  final surahs = await showSurahSelectionForGame(
                    context: context,
                    gameTitle: 'اختر الإجابة الصحيحة',
                  );
                  if (surahs != null && surahs.isNotEmpty) {
                    if (mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuizGameScreen(selectedSurahs: surahs),
                        ),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('سيتم إضافة اللعبة قريباً'),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 300,
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.05),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.notoKufiArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
