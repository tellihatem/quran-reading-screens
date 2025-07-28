import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/surah_card.dart';
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
  final Set<int> _passedSurahs = {};
  bool _isLoading = true;
  int _threeStarSurahs = 0; // Counter for surahs with 3 stars
  int _totalStars = 0; // Counter for total stars across all surahs

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
    // Get the global star count
    final totalStars = prefs.getInt('global_star_count') ?? 0;

    // Count memorized surahs, surahs with 3 stars, and load passed surahs
    int threeStarCount = 0;
    final passedSurahs = prefs.getStringList('passed_surahs') ?? [];
    
    for (int i = 1; i <= 114; i++) {
      final isMemorized = prefs.getBool('surah_${i}_memorized') ?? false;
      if (isMemorized) {
        memorized.add(i);
      }

      // Count surahs with 3 stars
      final surahStars = prefs.getInt('surah_${i}_stars') ?? 0;
      if (surahStars >= 3) {
        threeStarCount++;
      }
      
      // Check if surah is passed
      if (passedSurahs.contains('surah_$i')) {
        _passedSurahs.add(i);
      }
    }

    if (mounted) {
      setState(() {
        _memorizedSurahs.clear();
        _memorizedSurahs.addAll(memorized);
        _totalStars = totalStars;
        _threeStarSurahs = threeStarCount;
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
                  SizedBox(
                    width: 250,
                    height: 58,
                    child: Stack(
                      children: [
                        SvgPicture.asset(
                          'assets/hafiz/score.svg',
                          fit: BoxFit.contain,
                        ),
                        // Left counter (stars)
                        Positioned(
                          left: 60,
                          top: 16,
                          child: Text(
                            '${_threeStarSurahs.toString().padLeft(3, '0')}',
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  offset: const Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Right counter (trophies)
                        Positioned(
                          right: 35,
                          top: 16,
                          child: Text(
                            '${_totalStars.toString().padLeft(3, '0')}',
                            style: GoogleFonts.roboto(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  offset: const Offset(1, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                          ),
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
                            isPassed: _passedSurahs.contains(surahNumber),
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
}
