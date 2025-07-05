import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
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
        GestureDetector(
          onTap: isEnabled ? onPressed : null,
          child: Stack(
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
                        color: (highlightColor ??
                                Theme.of(context).primaryColor)
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
  double textSize = 24.0; // Reduced default font size
  double lineHeight = 1.8; // Reduced default line height
  bool _isRecording = false; // Track recording state

  // Audio recording and playback
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecordingInitialized = false;
  bool _versesVisible =
      true; // Track if verses should be visible during recording

  // Playback state
  String? _savedRecordingPath;
  bool _showPlaybackBar = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _audioDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  StreamSubscription<Duration>? _positionSub;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initRecording();

    // Schedule page building after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _buildPages();
      }
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _pageController.dispose();
    _positionSub?.cancel();
    _audioPlayer.dispose();
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

  // Show dialog to ask about hiding verses during recording
  Future<bool?> _showHideVersesDialog() async {
    final isDark = widget.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black87;
    final buttonTextColor = isDark ? Colors.white : Colors.white;

    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                'هل تريد إخفاء الآيات أثناء التسجيل؟',
                style: GoogleFonts.amiri(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // No button - keep verses visible
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(
                        Icons.visibility,
                        color: isDark ? Colors.green[300] : Colors.green[700],
                      ),
                      label: Text(
                        'لا، إبقِ الآيات ظاهرة',
                        style: GoogleFonts.amiri(
                          fontSize: 16,
                          color: isDark ? Colors.green[300] : Colors.green[700],
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        side: BorderSide(
                          color:
                              isDark ? Colors.green[300]! : Colors.green[700]!,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        backgroundColor:
                            isDark
                                ? Colors.green[900]!.withOpacity(0.2)
                                : Colors.green[50]!,
                      ),
                      onPressed: () => Navigator.pop(context, false),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Yes button - hide verses
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.visibility_off, size: 20),
                      label: Text(
                        'نعم، إخفاء الآيات',
                        style: GoogleFonts.amiri(
                          fontSize: 16,
                          color: buttonTextColor,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? Colors.green[700] : Colors.green,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  // Format duration as MM:SS
  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // Reset playback bar and clean up resources
  void _resetPlaybackBar() {
    if (_savedRecordingPath != null) {
      try {
        final file = File(_savedRecordingPath!);
        if (file.existsSync()) file.deleteSync();
      } catch (e) {
        debugPrint('Error deleting audio file: $e');
      }
    }
    _audioPlayer.stop();
    setState(() {
      _savedRecordingPath = null;
      _showPlaybackBar = false;
      _isPlaying = false;
      _currentPosition = Duration.zero;
    });
  }

  // Toggle play/pause
  Future<void> _togglePlayback() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play();
    }
    setState(() {
      _isPlaying = !_isPlaying;
    });
  }

  // Initialize audio player with saved recording
  Future<void> _initAudioPlayer(String path) async {
    try {
      await _audioPlayer.setFilePath(path);
      _audioDuration = _audioPlayer.duration ?? Duration.zero;

      _positionSub?.cancel();
      _positionSub = _audioPlayer.positionStream.listen((pos) {
        if (mounted) {
          setState(() {
            _currentPosition = pos;
          });
        }
      });

      _audioPlayer.playerStateStream.listen((state) {
        if (mounted && state.processingState == ProcessingState.completed) {
          setState(() {
            _isPlaying = false;
            _currentPosition = Duration.zero;
          });
          _audioPlayer.seek(Duration.zero);
        }
      });
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error initializing audio playback')),
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
      // Stop recording and show verses again
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

          // Save path and initialize playback
          setState(() {
            _savedRecordingPath = newPath;
            _showPlaybackBar = true;
          });

          // Initialize audio player
          await _initAudioPlayer(newPath);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('تم حفظ التسجيل بنجاح'),
                duration: const Duration(seconds: 2),
                action: SnackBarAction(
                  label: 'إغلاق',
                  onPressed: () {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  },
                ),
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error stopping recording: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error stopping recording')),
          );
        }
      }

      // Make sure verses are visible after stopping recording
      if (mounted) {
        setState(() {
          _versesVisible = true;
          _isRecording = false;
        });
      }
    } else {
      // Show dialog before starting recording
      final shouldHideVerses = await _showHideVersesDialog();
      if (shouldHideVerses == null) return; // User dismissed the dialog

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

        // Update state after successful recording start
        if (mounted) {
          setState(() {
            _versesVisible = !shouldHideVerses;
            _isRecording = true;
          });
        }
      } catch (e) {
        debugPrint('Error starting recording: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error starting recording')),
          );
        }
      }
    }
  }

  // Add method to update text size
  void _updateTextSize(double newSize) {
    setState(() {
      textSize = newSize;
      pages = []; // Clear pages to force rebuild
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildPages(); // Rebuild pages with new text size
    });
  }

  void _updateLineHeight(double newLineHeight) {
    setState(() {
      lineHeight = 2 * newLineHeight;
      pages = []; // Clear pages to force rebuild
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _buildPages(); // Rebuild pages with new line height
    });
  }

  Widget _buildSettingsMenu() {
    return SettingsMenu(
      initialTextSize: textSize,
      initialLineHeight: lineHeight,
      onTextSizeChanged: _updateTextSize,
      onLineHeightChanged: _updateLineHeight,
      onDarkModeToggle: widget.toggleDarkMode,
      isDarkMode: widget.isDarkMode,
    );
  }

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

  // Handle verse tap
  void _onVerseTap(int surahNumber, int verseNumber) {
    // Show an alert dialog with the surah and verse numbers
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Verse Tapped'),
          content: Text('Surah: $surahNumber\nVerse: $verseNumber'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );

    // Also print to console for debugging
    print('Tapped on Surah $surahNumber, Verse $verseNumber');
  }

  void _buildPages() {
    final isSurah1 = widget.surahNumber == 1;
    final isSurah9 = widget.surahNumber == 9;

    List<Widget> builtPages = [];
    final TextStyle textStyle = GoogleFonts.amiri(
      fontSize: textSize,
      height: lineHeight,
      color:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[100]
              : Colors.grey[900],
    );

    final surahPages = quran.getSurahPages(widget.surahNumber);

    for (int pageNum in surahPages) {
      final pageData = quran.getPageData(pageNum);
      final pageSpans = <TextSpan>[];
      final pageEntries = pageData.where(
        (entry) => entry['surah'] == widget.surahNumber,
      );

      for (var entry in pageEntries) {
        final start = entry['start'];
        final end = entry['end'];

        for (int i = start; i <= end; i++) {
          String verse =
              quran
                  .getVerse(widget.surahNumber, i, verseEndSymbol: true)
                  .replaceAll(
                    RegExp(r'\s+'),
                    ' ',
                  ) // Normalize internal whitespace
                  .replaceAll('\u200f', '') // Remove RTL marks
                  .trim();

          if (i == 1 && !isSurah1 && !isSurah9) {
            pageSpans.add(
              TextSpan(text: '${quran.basmala} ', style: textStyle),
            );
          }

          // Create a tappable span for each verse
          final verseRecognizer =
              TapGestureRecognizer()
                ..onTap = () => _onVerseTap(widget.surahNumber, i);

          pageSpans.add(
            TextSpan(
              text: '$verse ',
              style: textStyle,
              recognizer: verseRecognizer,
            ),
          );
        }
      }

      builtPages.add(_buildQuranPage(pageSpans));
    }

    setState(() {
      pages = builtPages;
    });
  }

  Widget _buildQuranPage(List<TextSpan> spans) {
    final isDark = widget.isDarkMode;
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.green.shade100,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : Colors.grey.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (spans.isNotEmpty &&
                spans.first.text?.contains(quran.basmala) == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                child: Text(
                  quran.basmala,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    fontSize: textSize,
                    height: lineHeight,
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Expanded(
              child: SingleChildScrollView(
                child: RichText(
                  text: TextSpan(
                    style: GoogleFonts.amiri(
                      fontSize: textSize,
                      height:
                          lineHeight *
                          2.0, // Increase line height for better readability
                      color: isDark ? Colors.grey[100] : Colors.grey[900],
                    ),
                    children:
                        spans
                            .where((span) => span.text?.isNotEmpty == true)
                            .toList(),
                  ),
                  textAlign: TextAlign.justify,
                  textDirection: ui.TextDirection.rtl,
                ),
              ),
            ),
          ],
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
  void didUpdateWidget(SurahReadingScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Rebuild pages when theme changes
    if (oldWidget.isDarkMode != widget.isDarkMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _buildPages();
        }
      });
    }
  }

  // Build the playback control bar
  Widget _buildPlaybackBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDarkMode ? Colors.white10 : Colors.grey[300]!,
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
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor:
                  isDarkMode ? Colors.green[300] : Colors.green[700],
              inactiveTrackColor:
                  isDarkMode ? Colors.grey[800] : Colors.grey[300],
              thumbColor: isDarkMode ? Colors.green[300] : Colors.green[700],
              overlayColor: (isDarkMode
                      ? Colors.green[300]
                      : Colors.green[700])!
                  .withOpacity(0.3),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: _currentPosition.inMilliseconds.toDouble(),
              max: _audioDuration.inMilliseconds.toDouble().clamp(
                1,
                double.infinity,
              ),
              onChanged: (value) {
                setState(() {
                  _currentPosition = Duration(milliseconds: value.toInt());
                });
                _audioPlayer.seek(_currentPosition);
              },
            ),
          ),

          // Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Current position
              Text(
                _formatDuration(_currentPosition),
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),

              // Play/Pause button
              IconButton(
                icon: Icon(
                  _isPlaying
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled,
                  size: 36,
                  color: isDarkMode ? Colors.green[300] : Colors.green[700],
                ),
                onPressed: _togglePlayback,
              ),

              // Duration
              Text(
                _formatDuration(_audioDuration),
                style: TextStyle(
                  fontSize: 12,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),

              // Close button
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                onPressed: _resetPlaybackBar,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build the bottom control bar
  Widget _buildBottomBar() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDarkMode ? Colors.white10 : Colors.grey[300]!,
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
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_showPlaybackBar) _buildPlaybackBar(),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.1),
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
                    iconColor:
                        isDarkMode ? Colors.white70 : const Color(0xFF6C63FF),
                    showCounter: true,
                    counter: '0',
                  ),

                  // Record Button (center)
                  _buildKidFriendlyButton(
                    icon: _isRecording ? Icons.stop : Icons.mic,
                    label: _isRecording ? 'تسجيل' : 'سجل',
                    onPressed: _toggleRecording,
                    isHighlighted: _isRecording,
                    highlightColor:
                        isDarkMode ? const Color(0xFF81C784) : Colors.red,
                  ),

                  // Play Button (right)
                  _buildKidFriendlyButton(
                    icon: Icons.play_arrow,
                    label: 'استمع',
                    onPressed: () {},
                    iconColor:
                        isDarkMode ? Colors.white70 : const Color(0xFF4CAF50),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
              builder: (BuildContext context) => _buildSettingsMenu(),
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
          // Loading state - only show when pages are empty
          if (pages.isEmpty) ...[
            const Center(child: CircularProgressIndicator()),
          ] else if (!_isRecording || _versesVisible) ...[
            // Show verses when not recording or when user chose to keep them visible during recording
            PageView.builder(
              controller: _pageController,
              itemCount: pages.length,
              reverse: false, // RIGHT swipe = next page
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
          ],

          // Show recording indicator only when recording and user chose to hide verses
          if (_isRecording && !_versesVisible)
            const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.mic, size: 48, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'جاري التسجيل...',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'اضغط على زر الإيقاف لإنهاء التسجيل',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),

          _buildBottomBar(),
        ],
      ),
    );
  }
}
