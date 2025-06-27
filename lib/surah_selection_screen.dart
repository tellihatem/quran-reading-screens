import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'surah_reading_screen.dart';
import 'dart:ui' as ui;

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
    return List.generate(quran.totalSurahCount, (index) => index + 1).where((number) {
      final nameAr = quran.getSurahNameArabic(number);
      return nameAr.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اختر السورة', style: TextStyle(fontFamily: 'Amiri', fontSize: 24)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              textAlign: TextAlign.right,
              textDirection: ui.TextDirection.rtl,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, textDirection: ui.TextDirection.rtl),
                hintText: 'ابحث عن السورة',
                hintTextDirection: ui.TextDirection.rtl,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green[700]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.green[700]!, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => SurahReadingScreen(
                                      surahNumber: surahNumber,
                                    ),
                              ),
                            );
                          },
                          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Number of Ayat on the left
                              Text(
                                '${quran.getVerseCount(surahNumber)} آية',
                                style: GoogleFonts.amiri(
                                  fontSize: 16,
                                  color: Colors.grey[600],
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
                                    color: Colors.black87,
                                  ),
                                  textDirection: ui.TextDirection.rtl,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                              // Empty container to balance the row
                              const SizedBox(width: 40),
                            ],
                          ),
                          // Surah number in a circle
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
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
    );
  }
}
