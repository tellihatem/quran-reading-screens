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
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth > 800; // Threshold for large screens
    
    // Define the games list
    final games = [
      {
        'title': 'لعبة الذاكرة',
        'icon': Icons.memory,
        'onTap': () async {
          final surahs = await showSurahSelectionForGame(
            context: context,
            gameTitle: 'لعبة الذاكرة',
          );
          if (surahs != null && surahs.isNotEmpty && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => MemoryGameScreen(
                  selectedSurahs: surahs,
                  onGameCompleted: (score) {
                    // Handle game completion if needed
                    Navigator.pop(context);
                  },
                ),
              ),
            );
          }
        },
      },
      {
        'title': 'ترتيب الآيات',
        'icon': Icons.sort_by_alpha,
        'onTap': () async {
          final surahs = await showSurahSelectionForGame(
            context: context,
            gameTitle: 'ترتيب الآيات',
          );
          if (surahs != null && surahs.isNotEmpty && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AyahOrderingScreen(
                  selectedSurahs: surahs,
                  onGameCompleted: (score) {
                    // Handle game completion if needed
                    Navigator.pop(context);
                  },
                ),
              ),
            );
          }
        },
      },
      {
        'title': 'اختر الإجابة الصحيحة',
        'icon': Icons.quiz,
        'onTap': () async {
          final surahs = await showSurahSelectionForGame(
            context: context,
            gameTitle: 'اختر الإجابة الصحيحة',
          );
          if (surahs != null && surahs.isNotEmpty && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => QuizGameScreen(
                  selectedSurahs: surahs,
                  onGameCompleted: (score) {
                    // Handle game completion if needed
                    Navigator.pop(context);
                  },
                ),
              ),
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('سيتم إضافة اللعبة قريباً'),
              ),
            );
          }
        },
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الألعاب',
          style: GoogleFonts.amiri(fontSize: 24, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).brightness == Brightness.dark
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 24.0), // Add space below app bar
                child: Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: games.map((game) => _buildGameCard(
                      context: context,
                      title: game['title'] as String,
                      icon: game['icon'] as IconData,
                      onTap: game['onTap'] as VoidCallback,
                    )).toList(),
                  ),
                ),
              ),
            );
          },
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
    // Map game titles to their corresponding image assets
    String imageAsset;
    switch (title) {
      case 'لعبة الذاكرة':
        imageAsset = 'assets/games/memory_game.png';
        break;
      case 'ترتيب الآيات':
        imageAsset = 'assets/games/ayah_order.png';
        break;
      case 'اختر الإجابة الصحيحة':
        imageAsset = 'assets/games/correct_answer.png';
        break;
      default:
        imageAsset = 'assets/games/correct_answer.png';
    }
    
    return Container(
      width: 180, // Fixed width
      height: 170, // Fixed height
      margin: const EdgeInsets.all(4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              imageAsset,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
