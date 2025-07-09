import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'surah_reading_screen.dart';
import 'dart:ui' as ui;
import 'widgets/background_widget.dart';

class SurahSelectionScreen extends StatefulWidget {
  final Function() toggleDarkMode;
  final bool isDarkMode;

  const SurahSelectionScreen({
    Key? key,
    required this.toggleDarkMode,
    required this.isDarkMode,
  }) : super(key: key);

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
        title: Text(
          'اختر السورة',
          style: GoogleFonts.amiri(fontSize: 24, color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(
            isDark ? Icons.light_mode : Icons.dark_mode,
            color: Colors.white,
          ),
          onPressed: widget.toggleDarkMode,
          tooltip: isDark ? 'الوضع الفاتح' : 'الوضع المظلم',
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
                  fillColor: isDark ? const Color(0xFF2A2A2A) : Colors.grey[50],
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
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 600;
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isWide ? 3 : 1,
                        childAspectRatio: isWide ? 3.5 : 6,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                      ),
                      itemCount: filteredSurahNumbers.length,
                      itemBuilder: (context, idx) {
                        final surahNumber = filteredSurahNumbers[idx];
                        return Card(
                          elevation: 2,
                          color: cardColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(color: borderColor, width: 0.5),
                          ),
                          child: ListTile(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => SurahReadingScreen(
                                        surahNumber: surahNumber,
                                        toggleDarkMode: widget.toggleDarkMode,
                                        isDarkMode: widget.isDarkMode,
                                      ),
                                ),
                              );
                            },
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                // Number of Ayat on the left
                                Text(
                                  '${quran.getVerseCount(surahNumber)} آية',
                                  style: GoogleFonts.amiri(
                                    fontSize: 16,
                                    color:
                                        isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                  ),
                                  textDirection: ui.TextDirection.rtl,
                                ),
                                // Surah name in the center
                                Expanded(
                                  child: Text(
                                    quran.getSurahNameArabic(surahNumber),
                                    style: GoogleFonts.amiri(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: textColor,
                                    ),
                                    textDirection: ui.TextDirection.rtl,
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            // Surah number in a circle
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color:
                                    isDark
                                        ? Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.2)
                                        : Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.1),
                                border: Border.all(
                                  color: Theme.of(context).primaryColor,
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  surahNumber.toString(),
                                  style: GoogleFonts.amiri(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
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
}
