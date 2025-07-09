import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui' as ui;

class GamesSelectScreen extends StatelessWidget {
  const GamesSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'الألعاب',
          style: GoogleFonts.amiri(fontSize: 24, color: Colors.white),
        ),
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
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/background/background.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildGameCard(
                context: context,
                title: 'لعبة الذاكرة',
                icon: Icons.memory,
                onTap: () {
                  // TODO: Navigate to Memory Game
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('سيتم إضافة اللعبة قريباً')),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildGameCard(
                context: context,
                title: 'ترتيب الآيات',
                icon: Icons.sort_by_alpha,
                onTap: () {
                  // TODO: Navigate to Verse Ordering Game
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('سيتم إضافة اللعبة قريباً')),
                  );
                },
              ),
              const SizedBox(height: 20),
              _buildGameCard(
                context: context,
                title: 'اختر الإجابة الصحيحة',
                icon: Icons.quiz,
                onTap: () {
                  // TODO: Navigate to Quiz Game
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('سيتم إضافة اللعبة قريباً')),
                  );
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? const Color(0xCC1E1E1E) : const Color(0xCCFFFFFF);
    final textColor = isDark ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 300,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 25),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          textDirection: ui.TextDirection.rtl,
          children: [
            Text(
              title,
              style: GoogleFonts.amiri(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
          ],
        ),
      ),
    );
  }
}
