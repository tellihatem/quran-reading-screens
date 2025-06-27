import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:record/record.dart';
import 'package:haffiz/widgets/settings_menu.dart';

class SurahReadingScreen extends StatefulWidget {
  final int surahNumber;
  final Function() toggleDarkMode;
  final bool isDarkMode;

  const SurahReadingScreen({
    Key? key,
    required this.surahNumber,
    required this.toggleDarkMode,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  _SurahReadingScreenState createState() => _SurahReadingScreenState();
}

// Helper method to create consistent kid-friendly buttons
class _KidFriendlyButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color iconColor;
  final bool isHighlighted;
  final Color? highlightColor;
  final bool showCounter;
  final String? counter;
  final bool isEnabled;

  const _KidFriendlyButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.iconColor = Colors.blue,
    this.isHighlighted = false,
    this.highlightColor,
    this.showCounter = false,
    this.counter,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:
                    isHighlighted
                        ? (highlightColor ?? Theme.of(context).primaryColor)
                            .withOpacity(0.2)
                        : Colors.grey[100]?.withOpacity(0.5),
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isHighlighted
                          ? (highlightColor ?? Theme.of(context).primaryColor)
                          : Colors.grey[300]!,
                  width: 2,
                ),
                boxShadow: [
                  if (isHighlighted)
                    BoxShadow(
                      color: (highlightColor ?? Theme.of(context).primaryColor)
                          .withOpacity(0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                ],
              ),
              child: Icon(
                icon,
                size: 32,
                color:
                    isHighlighted
                        ? (highlightColor ?? Theme.of(context).primaryColor)
                        : isEnabled
                        ? iconColor
                        : Colors.grey[400],
              ),
            ),
            if (showCounter && counter != null)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    counter!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodyMedium?.color,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SurahReadingScreenState extends State<SurahReadingScreen> {
  List<Widget> pages = [];
  final PageController _pageController = PageController();
  double textSize = 28.0; // Add text size state
  bool _isRecording = false; // Track recording state

  // Audio recording
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecordingInitialized = false;

  @override
  void initState() {
    super.initState();
    _initRecording();
  }

  @override
  void dispose() {
    _pageController.dispose();
    if (_isRecording) {
      _audioRecorder.stop();
    }
    super.dispose();
  }

  // Initialize voice recording
  Future<void> _initRecording() async {
    try {
      final status = await Permission.microphone.request();
      final hasPermission = status.isGranted;

      setState(() {
        _isRecordingInitialized = hasPermission;
      });

      if (!hasPermission && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Microphone permission is required for recording'),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error initializing recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error initializing recording')),
        );
      }
    }
  }

  // Start or stop recording
  Future<void> _toggleRecording() async {
    if (!_isRecordingInitialized) {
      await _initRecording();
      if (!_isRecordingInitialized) return;
    }

    if (_isRecording) {
      // Stop recording
      try {
        final path = await _audioRecorder.stop();
        if (path != null) {
          // Generate a unique filename with timestamp
          final directory = await getApplicationDocumentsDirectory();
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          final newPath =
              '${directory.path}/surah_${widget.surahNumber}_$timestamp.m4a';

          // Rename the file to include surah number and timestamp
          final file = File(path);
          await file.rename(newPath);

          debugPrint('Recording saved to: $newPath');
          if (mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Recording saved')));
          }
        }
      } catch (e) {
        debugPrint('Error stopping recording: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error saving recording')),
          );
        }
      }
    } else {
      // Start recording
      try {
        final tempDir = await getTemporaryDirectory();
        final tempPath = '${tempDir.path}/temp_recording.m4a';
        await _audioRecorder.start(
          const RecordConfig(
            encoder: AudioEncoder.aacLc,
            bitRate: 128000,
            sampleRate: 44100,
          ),
          path: tempPath,
        );
      } catch (e) {
        debugPrint('Error starting recording: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error starting recording')),
          );
          return;
        }
      }
    }

    if (mounted) {
      setState(() {
        _isRecording = !_isRecording;
      });
    }
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

  // Height constants for layout calculations
  static const double bottomBarHeight =
      120.0; // Increased height for kid-friendly design
  static const double verticalPadding =
      24.0 * 2; // Top and bottom padding of the page
  static const double bottomBarSpacing =
      16.0; // Space between content and bottom bar

  // Build a kid-friendly button with icon and label
  Widget _buildKidFriendlyButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color? iconColor,
    bool isHighlighted = false,
    Color? highlightColor,
    bool showCounter = false,
    String? counter,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: _KidFriendlyButton(
        icon: icon,
        label: label,
        onPressed: onPressed,
        iconColor: iconColor ?? Theme.of(context).primaryColor,
        isHighlighted: isHighlighted,
        highlightColor: highlightColor,
        showCounter: showCounter,
        counter: counter,
      ),
    );
  }

  void _buildPages() {
    final verseCount = quran.getVerseCount(widget.surahNumber);
    final shouldSkipBismillah =
        widget.surahNumber != 1 && widget.surahNumber != 9;
    final startVerse = shouldSkipBismillah ? 2 : 1;

    List<Widget> builtPages = [];
    List<TextSpan> currentSpans = [];

    final TextStyle textStyle = GoogleFonts.amiri(
      fontSize: textSize,
      height: 2.0,
      color:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[100]
              : Colors.grey[900],
    );

    final screenSize = MediaQuery.of(context).size;
    final screenWidth =
        screenSize.width -
        48.0; // Account for horizontal padding (24px each side)

    // Calculate available height by subtracting:
    // - Bottom bar height
    // - Bottom bar spacing
    // - Vertical padding (top + bottom)
    // - App bar height
    // - Status bar height
    final availableHeight =
        screenSize.height -
        bottomBarHeight -
        bottomBarSpacing -
        verticalPadding -
        kToolbarHeight -
        MediaQuery.of(context).padding.top;

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

      // Check if current spans exceed available height or if it's the last verse
      if (tp.height > availableHeight || i == verseCount) {
        if (currentSpans.isNotEmpty) {
          builtPages.add(_buildQuranPage(currentSpans));
          // Start a new page with the current verse if it caused overflow
          currentSpans = [TextSpan(text: '$verse ', style: textStyle)];
        }
      }
    }

    setState(() {
      pages = builtPages;
    });
  }

  Widget _buildQuranPage(List<TextSpan> spans) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.green.shade100,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            if (isDark)
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 1,
              ),
          ],
        ),
        child: SelectableText.rich(
          TextSpan(children: spans),
          textAlign: TextAlign.justify,
          style: TextStyle(color: isDark ? Colors.grey[100] : Colors.grey[900]),
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
                (_) => SurahReadingScreen(
                  surahNumber: widget.surahNumber + 1,
                  toggleDarkMode: widget.toggleDarkMode,
                  isDarkMode: widget.isDarkMode,
                ),
          ),
        );
      });
    } else if (index == 0 && widget.surahNumber > 1) {
      Future.delayed(const Duration(milliseconds: 150), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (_) => SurahReadingScreen(
                  surahNumber: widget.surahNumber - 1,
                  toggleDarkMode: widget.toggleDarkMode,
                  isDarkMode: widget.isDarkMode,
                ),
          ),
        );
      });
    }
  }

  // Get dark mode state from widget
  bool get isDarkMode => widget.isDarkMode;

  @override
  Widget build(BuildContext context) {
    final verseCount = quran.getVerseCount(widget.surahNumber);
    final surahNameAr = quran.getSurahNameArabic(widget.surahNumber);
    final isMakki = quran.getPlaceOfRevelation(widget.surahNumber) == 'Makkah';

    // Define colors based on theme
    final backgroundColor =
        isDarkMode ? const Color(0xFF121212) : const Color(0xFFF7FDF3);
    final appBarColor = isDarkMode ? Colors.grey[900] : Colors.green[800];
    // Theme colors - used in _buildQuranPage

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () {
            showDialog(
              context: context,
              barrierColor: Colors.black54,
              builder:
                  (BuildContext context) => SettingsMenu(
                    initialTextSize: textSize,
                    onTextSizeChanged: _updateTextSize,
                    onDarkModeToggle: widget.toggleDarkMode,
                    isDarkMode: widget.isDarkMode,
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
      body: Stack(
        children: [
          // Main content
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
                    padding: const EdgeInsets.fromLTRB(
                      16.0,
                      16.0,
                      16.0,
                      100.0,
                    ), // Add bottom padding for the control bar
                    child: pages[index],
                  );
                },
              ),

          // Bottom Control Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Repeat Button with Counter (left)
                    _buildKidFriendlyButton(
                      icon: Icons.repeat,
                      label: 'كرر',
                      onPressed: () {},
                      iconColor: const Color(0xFF6C63FF), // Purple
                      showCounter: true,
                      counter: '0',
                    ),

                    // Record Button (center)
                    _buildKidFriendlyButton(
                      icon: _isRecording ? Icons.stop : Icons.mic,
                      label: _isRecording ? 'تسجيل' : 'سجل',
                      onPressed: _toggleRecording,
                      isHighlighted: _isRecording,
                      highlightColor: Colors.red,
                    ),

                    // Play Button (right)
                    _buildKidFriendlyButton(
                      icon: Icons.play_arrow,
                      label: 'استمع',
                      onPressed: () {},
                      iconColor: const Color(0xFF4CAF50), // Green
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
