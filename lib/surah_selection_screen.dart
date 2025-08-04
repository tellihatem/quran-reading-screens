import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:quran/quran.dart' as quran;
import '../providers/theme_provider.dart';
import 'surah_reading_screen.dart';
import 'dart:ui' as ui;
import 'widgets/background_widget.dart';

class SurahSelectionScreen extends StatefulWidget {
  const SurahSelectionScreen({Key? key}) : super(key: key);

  @override
  State<SurahSelectionScreen> createState() => _SurahSelectionScreenState();
}

class _SurahSelectionScreenState extends State<SurahSelectionScreen> {
  String _searchQuery = '';

  List<int> get filteredSurahNumbers {
    if (_searchQuery.isEmpty) {
      return List.generate(quran.totalSurahCount, (index) => index + 1);
    }
    return List.generate(quran.totalSurahCount, (index) => index + 1).where((
      number,
    ) {
      final nameAr = quran.getSurahNameArabic(number);
      return nameAr.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey[300]!;

    return Scaffold(
      appBar: AppBar(
        title: Text('اختر السورة', style: GoogleFonts.notoKufiArabic()),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        automaticallyImplyLeading: false,
        leading: Consumer<ThemeProvider>(
          builder:
              (context, themeProvider, _) => IconButton(
                icon: Icon(
                  themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                  color: Colors.white,
                ),
                onPressed: themeProvider.toggleTheme,
                tooltip:
                    themeProvider.isDarkMode ? 'الوضع الفاتح' : 'الوضع المظلم',
              ),
        ),
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
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  textAlign: TextAlign.right,
                  textDirection: ui.TextDirection.rtl,
                  decoration: InputDecoration(
                    prefixIcon: Icon(
                      Icons.search,
                      textDirection: ui.TextDirection.rtl,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                    hintText: 'ابحث عن السورة',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontFamily: 'Amiri',
                    ),
                    hintTextDirection: ui.TextDirection.rtl,
                    filled: true,
                    fillColor:
                        isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Theme.of(context).primaryColor,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 16,
                      horizontal: 16,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    final isPhone = constraints.maxWidth <= 600;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 3 : (isPhone ? 2 : 1),
                        childAspectRatio: () {
                          final width =
                              constraints.maxWidth /
                              (isWide ? 3 : (isPhone ? 2 : 1));
                          final height =
                              constraints.maxHeight /
                              ((filteredSurahNumbers.length /
                                      (isWide ? 3 : (isPhone ? 2 : 1)))
                                  .ceil());
                          // Clamp aspect ratio to reasonable range
                          final minAspect = isPhone ? 2.1 : 1.8;
                          final aspect = (width / height).clamp(minAspect, 3.5);
                          return aspect;
                        }(),
                        mainAxisSpacing: 24,
                        crossAxisSpacing: isPhone ? 12 : 16,
                      ),
                      itemCount: filteredSurahNumbers.length,
                      itemBuilder: (context, idx) {
                        final surahNumber = filteredSurahNumbers[idx];

                        // Cycle through user gradients for kids
                        final gradients = [
                          [
                            Color(0xFFfdc830),
                            Color(0xFFf37335),
                          ], // yellow to orange
                          [
                            Color(0xFF11998e),
                            Color(0xFF38ef7d),
                          ], // green teal to light green
                          [
                            Color(0xFF2193b0),
                            Color(0xFF6dd5ed),
                          ], // blue to light blue
                          [
                            Color(0xFF654ea3),
                            Color(0xFFeaafc8),
                          ], // purple to pink
                        ];
                        final gradient = gradients[idx % gradients.length];

                        return InkWell(
                          borderRadius: BorderRadius.circular(18),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => SurahReadingScreen(
                                      surahNumber: surahNumber,
                                    ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.85),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: gradient[0].withOpacity(0.18),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 18,
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Surah number in a circle
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withOpacity(0.9),
                                      border: Border.all(
                                        color: gradient[0].withOpacity(0.8),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: gradient[0].withOpacity(0.13),
                                          blurRadius: 6,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        surahNumber.toString(),
                                        style: GoogleFonts.amiri(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: gradient[0],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 18),
                                  // Surah name and ayah count
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            quran.getSurahNameArabic(
                                              surahNumber,
                                            ),
                                            style: GoogleFonts.amiri(
                                              fontSize: (constraints.maxWidth <= 390)
                                                  ? 18
                                                  : (isWide
                                                      ? 26
                                                      : (isPhone ? 20 : 22)), 
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey[900],
                                              shadows: [
                                                Shadow(
                                                  color: Colors.white
                                                      .withOpacity(0.6),
                                                  blurRadius: 4,
                                                ),
                                              ],
                                            ),
                                            textDirection: ui.TextDirection.rtl,
                                            textAlign: TextAlign.start,
                                            softWrap: true,
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 2,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          '${quran.getVerseCount(surahNumber)} آية',
                                          style: GoogleFonts.amiri(
                                            fontSize:
                                                isWide
                                                    ? 18
                                                    : (isPhone ? 13 : 15),
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textDirection: ui.TextDirection.rtl,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
