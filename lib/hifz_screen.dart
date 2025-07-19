import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haffiz/widgets/surah_card.dart';
import 'package:quran/quran.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'widgets/background_widget.dart';

class HifzScreen extends StatefulWidget {
  const HifzScreen({Key? key}) : super(key: key);

  @override
  _HifzScreenState createState() => _HifzScreenState();
}

class _HifzScreenState extends State<HifzScreen> {
  final Set<int> _memorizedSurahs = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMemorizedSurahs();
  }

  Future<void> _loadMemorizedSurahs() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isLoading = true;
    });

    final memorized = <int>{};
    for (int i = 1; i <= 114; i++) {
      if (prefs.getBool('surah_${i}_memorized') == true) {
        memorized.add(i);
      }
    }

    if (mounted) {
      setState(() {
        _memorizedSurahs.clear();
        _memorizedSurahs.addAll(memorized);
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0, // This will completely remove the app bar
      ),
      body: BackgroundWidget(
        child: Column(
          children: [
            // App Bar with Counters
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.7),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: const Color(0x22FFFFFF),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Star Counter
                        Row(
                          children: [
                            _buildCounter(
                              count: 5,
                              color: const Color(0xFFFFD700),
                              width: 60,
                            ),
                            const Icon(
                              Icons.star,
                              color: Color(0xFFFFD700),
                              size: 36,
                            ),
                          ],
                        ),
                        const SizedBox(width: 20),
                        // Trophy Counter
                        Row(
                          children: [
                            _buildCounter(
                              count: 2,
                              color: const Color(0xFFDAA520),
                              width: 60,
                            ),
                            const Icon(
                              Icons.emoji_events,
                              color: Color(0xFFDAA520),
                              size: 36,
                            ),
                          ],
                        ),
                      ],
                    ),
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
                      return _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : SurahCard(
                              key: ValueKey('surah_$surahNumber'),
                              surahNumber: surahNumber,
                              surahName: surahName,
                              isUnlocked: isUnlocked,
                              isFromHifzScreen: true,
                              isMemorized: _memorizedSurahs.contains(surahNumber),
                              onMemorized: _loadMemorizedSurahs,
                            );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter({
    required int count,
    required Color color,
    double? width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Center(
        child: Text(
          count.toString().padLeft(3, '0'),
          textAlign: TextAlign.center,
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
