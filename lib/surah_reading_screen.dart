import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'dart:ui' as ui;
import 'package:haffiz/widgets/settings_menu.dart';

class SurahReadingScreen extends StatefulWidget {
  final int surahNumber;

  const SurahReadingScreen({Key? key, required this.surahNumber})
    : super(key: key);

  @override
  _SurahReadingScreenState createState() => _SurahReadingScreenState();
}

class _SurahReadingScreenState extends State<SurahReadingScreen> {
  List<Widget> pages = [];
  final PageController _pageController = PageController();
  double textSize = 28.0; // Add text size state

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildPages();
  }

  // Add method to update text size
  void _updateTextSize(double newSize) {
    setState(() {
      textSize = newSize;
      pages = []; // Clear pages to force rebuild
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _buildPages(); // Rebuild pages with new text size
      });
    });
  }

  void _buildPages() {
    final verseCount = quran.getVerseCount(widget.surahNumber);
    final shouldSkipBismillah =
        widget.surahNumber != 1 && widget.surahNumber != 9;
    final startVerse = shouldSkipBismillah ? 2 : 1;

    List<Widget> builtPages = [];
    List<TextSpan> currentSpans = [];

    final TextStyle textStyle = GoogleFonts.amiri(
      fontSize: textSize, // Use the state variable
      height: 2.0,
      color: Colors.grey[900],
    );

    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    for (int i = startVerse; i <= verseCount; i++) {
      String verse =
          quran.getVerse(widget.surahNumber, i, verseEndSymbol: true).trim();
      currentSpans.add(TextSpan(text: '$verse ', style: textStyle));

      final tp = TextPainter(
        text: TextSpan(children: currentSpans),
        textDirection: ui.TextDirection.rtl,
        textAlign: TextAlign.justify,
      );

      tp.layout(maxWidth: screenWidth - 64);

      if (tp.height > screenHeight * 0.55 || i == verseCount) {
        builtPages.add(_buildQuranPage(currentSpans));
        currentSpans = [];
      }
    }

    setState(() {
      pages = builtPages;
    });
  }



  Widget _buildQuranPage(List<TextSpan> spans) {
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.green.shade100),
          borderRadius: BorderRadius.circular(16),
        ),
        child: SelectableText.rich(
          TextSpan(children: spans),
          textAlign: TextAlign.justify,
        ),
      ),
    );
  }

  void _handlePageChange(int index) {
    if (index == pages.length - 1 && widget.surahNumber < 114) {
      Future.delayed(const Duration(milliseconds: 150), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => SurahReadingScreen(surahNumber: widget.surahNumber + 1),
          ),
        );
      });
    } else if (index == 0 && widget.surahNumber > 1) {
      Future.delayed(const Duration(milliseconds: 150), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => SurahReadingScreen(surahNumber: widget.surahNumber - 1),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final verseCount = quran.getVerseCount(widget.surahNumber);
    final surahNameAr = quran.getSurahNameArabic(widget.surahNumber);
    final isMakki = quran.getPlaceOfRevelation(widget.surahNumber) == 'Makkah';

    return Scaffold(
      backgroundColor: const Color(0xFFF7FDF3),
      appBar: AppBar(
        backgroundColor: Colors.green[800],
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              barrierColor: Colors.black54,
              builder: (BuildContext context) => SettingsMenu(
                initialTextSize: textSize,
                onTextSizeChanged: _updateTextSize,
              ),
            );
          },
        ),
        title: Column(
          children: [
            Text(
              surahNameAr,
              style: GoogleFonts.amiri(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${isMakki ? 'مكية' : 'مدنية'} • $verseCount آية',
              style: GoogleFonts.amiri(
                fontSize: 16,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body:
          pages.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                reverse: false, // RIGHT swipe = next page ✅
                physics: const ClampingScrollPhysics(),
                onPageChanged: _handlePageChange,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: pages[index],
                  );
                },
              ),
    );
  }
}
