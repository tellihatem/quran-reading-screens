import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'dart:ui' as ui;

class SurahSelectionForGameScreen extends StatefulWidget {
  final String gameTitle;
  final Function(List<int>) onSurahsSelected;

  const SurahSelectionForGameScreen({
    Key? key,
    required this.gameTitle,
    required this.onSurahsSelected,
  }) : super(key: key);

  @override
  State<SurahSelectionForGameScreen> createState() => _SurahSelectionForGameScreenState();
}

class _SurahSelectionForGameScreenState extends State<SurahSelectionForGameScreen> {
  final Set<int> _selectedSurahs = {};
  String _searchQuery = '';

  List<int> get filteredSurahNumbers {
    List<int> surahs = [];
    
    // Always include Surah 1 (Al-Fatiha) first
    if (_searchQuery.isEmpty || quran.getSurahNameArabic(1).contains(_searchQuery)) {
      surahs.add(1);
    }
    
    // Add surahs from 114 down to 2
    for (int i = 114; i >= 2; i--) {
      if (_searchQuery.isEmpty || quran.getSurahNameArabic(i).contains(_searchQuery)) {
        surahs.add(i);
      }
    }
    
    return surahs;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? Colors.white10 : Colors.grey[300]!;
    final selectedColor = Theme.of(context).primaryColor.withOpacity(0.2);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'اختر السور للعبة ${widget.gameTitle}',
          style: GoogleFonts.notoKufiArabic(),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'رجوع',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
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
          ),
          
          // Selection Info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_selectedSurahs.length} سورة مختارة',
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                if (_selectedSurahs.isNotEmpty)
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _selectedSurahs.clear();
                      });
                    },
                    child: Text(
                      'إلغاء الكل',
                      style: GoogleFonts.notoKufiArabic(
                        color: Colors.red,
                        fontSize: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Surah List
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredSurahNumbers.length,
              itemBuilder: (context, idx) {
                final surahNumber = filteredSurahNumbers[idx];
                final isSelected = _selectedSurahs.contains(surahNumber);
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedSurahs.remove(surahNumber);
                      } else {
                        _selectedSurahs.add(surahNumber);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? selectedColor : cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? Theme.of(context).primaryColor 
                            : borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Checkbox in top-right corner
                        if (isSelected)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        
                        // Surah content
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                quran.getSurahNameArabic(surahNumber),
                                style: GoogleFonts.amiri(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${quran.getVerseCount(surahNumber)} آية',
                                style: GoogleFonts.notoKufiArabic(
                                  fontSize: 14,
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Start Button
          if (_selectedSurahs.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () {
                  if (_selectedSurahs.isNotEmpty) {
                    widget.onSurahsSelected(_selectedSurahs.toList());
                    Navigator.of(context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'ابدأ اللعبة (${_selectedSurahs.length})\nابدأ اللعبة',
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Helper function to show the surah selection dialog
Future<List<int>?> showSurahSelectionForGame({
  required BuildContext context,
  required String gameTitle,
}) async {
  List<int>? selectedSurahs;
  
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (_, controller) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Draggable handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'اختر السور للعبة $gameTitle',
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: SurahSelectionForGameScreen(
                  gameTitle: gameTitle,
                  onSurahsSelected: (surahs) {
                    selectedSurahs = surahs;
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  
  return selectedSurahs;
}
