import 'dart:io';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:haffiz/widgets/settings_menu.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/foundation.dart' show kIsWeb;

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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
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
                          : isDarkMode
                          ? Colors.grey[800]?.withOpacity(0.5)
                          : Colors.grey[100]?.withOpacity(0.5),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        isHighlighted
                            ? (highlightColor ?? Theme.of(context).primaryColor)
                            : isDarkMode
                            ? Colors.grey[600]!
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
                          ? isDarkMode
                              ? Colors.white
                              : iconColor
                          : isDarkMode
                          ? Colors.grey[600]
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
            color: isDarkMode ? Colors.grey[100] : Colors.grey[900],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class WavyPainter extends CustomPainter {
  final bool isDarkMode;

  WavyPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = isDarkMode ? Colors.black : Colors.white
          ..style = PaintingStyle.fill;

    final path = Path();

    // Start from the left edge
    path.moveTo(0, 20);

    // First wave (left to middle)
    path.quadraticBezierTo(size.width * 0.2, 0, size.width * 0.3, 20);

    // Second wave (middle dip)
    path.quadraticBezierTo(size.width * 0.4, 0, size.width * 0.5, 20);

    // Third wave (right dip)
    path.quadraticBezierTo(size.width * 0.6, 0, size.width * 0.7, 20);

    // End at the right edge
    path.quadraticBezierTo(size.width * 0.8, 0, size.width, 20);

    // Close the path
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _SurahReadingScreenState extends State<SurahReadingScreen> {
  Map<String, List<dynamic>> _allSurahTimings = {};
  bool _isVersePlaying = false;
  List<Widget> pages = [];
  final PageController _pageController = PageController();
  double textSize = 24.0; // Reduced default font size
  double lineHeight = 1.8; // Reduced default line height
  bool _isRecording = false; // Track recording state

  // Audio recording and playback
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isRecordingInitialized = false;
  bool _versesVisible =
      true; // Track if verses should be visible during recording
  String? _savedRecordingPath; // Path to the saved recording file

  // Audio playback state
  Duration _audioDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  StreamSubscription<Duration>? _positionSub;
  bool _isPlaying = false;
  bool _isRepeatEnabled = false;
  int _repeatCount = 0;
  int? _currentlyPlayingVerse;
  Map<int, Map<String, dynamic>> _verseTimings = {};
  StreamSubscription<Duration>? _positionSubscription;
  bool _isLoadingTimings = false;
  bool _showPlaybackBar = false; // Controls visibility of the playback bar

  // Track verse ranges for each page in our app's pagination
  List<Map<String, int>> _pageVerseRanges = [];

  // Load verse timings from storage or initialize empty timings
  Future<void> _loadTimings() async {
    if (_isLoadingTimings) return;

    setState(() {
      _isLoadingTimings = true;
    });

    try {
      final jsonString = await rootBundle.loadString(
        'assets/audio/timings.json',
      );
      final data = json.decode(jsonString);
      _allSurahTimings = Map<String, List<dynamic>>.from(data);
    } catch (e) {
      print('Error loading timings: $e');
      // Initialize with empty timings on error
      _verseTimings = {};
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingTimings = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _initRecording();
    _loadTimings();
    _showPlaybackBar = false; // Initialize playback bar visibility

    // Schedule page building after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _buildPages();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _pageController.dispose();
    _positionSubscription?.cancel();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        if (file.existsSync()) {
          file.deleteSync();
        }
        _savedRecordingPath = null;
      } catch (e) {
        debugPrint('Error deleting audio file: $e');
      }
    }
    _audioPlayer.stop();
    _audioPlayer.setLoopMode(LoopMode.off);
    setState(() {
      _savedRecordingPath = null;
      _showPlaybackBar = false;
      _isPlaying = false;
      _currentPosition = Duration.zero;
      _isRepeatEnabled = false;
      _repeatCount = 0; // Reset the repeat counter
    });
  }

  // Toggle play/pause
  Future<void> _togglePlayback() async {
    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
      } else {
        // If we have a current page, play its verses
        int? currentPageIndex = _pageController.page?.round();
        if (currentPageIndex != null &&
            currentPageIndex >= 0 &&
            currentPageIndex < _pageVerseRanges.length) {
          final range = _pageVerseRanges[currentPageIndex];
          if (range['surah'] != null &&
              range['firstVerse'] != null &&
              range['lastVerse'] != null) {
            await _playPageVerses(
              range['surah']!,
              range['firstVerse']!,
              range['lastVerse']!,
            );
            return;
          }
        }

        // If no current page or error, just resume playback
        await _audioPlayer.play();
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      debugPrint('Error toggling playback: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ في التحكم في التشغيل')),
        );
      }
    }
  }

  // Toggle repeat mode
  void _toggleRepeat() {
    setState(() {
      _isRepeatEnabled = !_isRepeatEnabled;
      _audioPlayer.setLoopMode(_isRepeatEnabled ? LoopMode.all : LoopMode.off);
      if (!_isRepeatEnabled) {
        _repeatCount = 0; // Reset counter when repeat is turned off
      }
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
    if (kIsWeb) {
      // Inform user that recording is not configured for web
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Recording is not configured for web yet.'),
          ),
        );
      }
      return;
    }

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
  void _onVerseTap(int surahNumber, int verseNumber) async {
    final paddedSurah = surahNumber.toString().padLeft(3, '0');
    final audioUrl =
        'https://download.quranicaudio.com/quran/mahmood_khaleel_al-husaree/$paddedSurah.mp3';

    await _audioPlayer.stop();
    _positionSubscription?.cancel();

    final timings = _allSurahTimings['$surahNumber'];
    if (timings == null) return;

    final verseData = timings.firstWhere(
      (v) => v['verse'] == verseNumber,
      orElse: () => null,
    );

    if (verseData == null) return;

    final int startMs = verseData['start'];
    final int endMs = verseData['end'];

    try {
      final clipSource = ClippingAudioSource(
        start: Duration(milliseconds: startMs),
        end: Duration(milliseconds: endMs),
        child: AudioSource.uri(Uri.parse(audioUrl)),
      );

      await _audioPlayer.setAudioSource(clipSource);
      await _audioPlayer.play();

      setState(() {
        _currentlyPlayingVerse = verseNumber;
      });

      // Handle when playback ends
      _audioPlayer.playerStateStream.listen((state) {
        if (mounted && state.processingState == ProcessingState.completed) {
          setState(() {
            _currentlyPlayingVerse = null;
          });
        }
      });
    } catch (e) {
      debugPrint('Audio playback error: $e');
    }
  }

  // Handle playing all verses on the current page
  Future<void> _playPageVerses(
    int surahNumber,
    int firstVerse,
    int lastVerse,
  ) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Verse Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Surah Number: $surahNumber'),
              Text('First Verse: $firstVerse'),
              Text('Last Verse: $lastVerse'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );

    final paddedSurah = surahNumber.toString().padLeft(3, '0');
    final audioUrl =
        'https://download.quranicaudio.com/quran/mahmood_khaleel_al-husaree/$paddedSurah.mp3';

    await _audioPlayer.stop();
    _positionSubscription?.cancel();

    final timings = _allSurahTimings['$surahNumber'];
    if (timings == null) return;

    try {
      // Create a list to hold all verse audio sources
      final List<AudioSource> audioSources = [];

      // Add each verse's audio to the playlist
      for (int verse = firstVerse; verse <= lastVerse; verse++) {
        final verseData = timings.firstWhere(
          (v) => v['verse'] == verse,
          orElse: () => null,
        );

        if (verseData != null) {
          final int startMs =
              verse == 1
                  ? 0
                  : verseData['start']; // Start from 0 for first verse
          final int endMs = verseData['end'];

          audioSources.add(
            ClippingAudioSource(
              start: Duration(milliseconds: startMs),
              end: Duration(milliseconds: endMs),
              child: AudioSource.uri(Uri.parse(audioUrl)),
              tag: verse, // Use verse number as tag to track current verse
            ),
          );
        }
      }

      if (audioSources.isNotEmpty) {
        // Create a concatenating audio source to play all verses in sequence
        final playlist = ConcatenatingAudioSource(
          useLazyPreparation: true,
          children: audioSources,
        );

        await _audioPlayer.setAudioSource(playlist, preload: true);

        // Set the initial loop mode
        _audioPlayer.setLoopMode(
          _isRepeatEnabled ? LoopMode.one : LoopMode.off,
        );

        // Track the current verse being played and detect loops
        int? lastIndex;
        _audioPlayer.currentIndexStream.listen((index) {
          if (index != null && index < audioSources.length) {
            // If we detect a loop back to the first verse, increment counter
            if (_isRepeatEnabled &&
                lastIndex != null &&
                index == 0 &&
                lastIndex == audioSources.length - 1) {
              setState(() {
                _repeatCount++;
              });
            }
            lastIndex = index;

            final source = audioSources[index];
            if (source is ClippingAudioSource) {
              setState(() {
                _currentlyPlayingVerse = source.tag as int?;
              });
            }
          }
        });

        // Handle playback completion when not in repeat mode
        _audioPlayer.playerStateStream.listen((state) {
          if (mounted && state.processingState == ProcessingState.completed) {
            setState(() {
              _currentlyPlayingVerse = null;
              if (!_isRepeatEnabled) {
                _isPlaying = false;
              }
            });
          }
        });

        await _audioPlayer.play();
        setState(() {
          _isPlaying = true;
        });
      }
    } catch (e) {
      debugPrint('Error playing page verses: $e');
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ في تشغيل الآيات')),
        );
      }
    }
  }

  void _buildPages() {
    final isSurah1 = widget.surahNumber == 1;
    final isSurah9 = widget.surahNumber == 9;

    List<Widget> builtPages = [];
    _pageVerseRanges = []; // Reset verse ranges

    final TextStyle textStyle = GoogleFonts.amiri(
      fontSize: textSize,
      height: lineHeight,
      color:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.grey[100]
              : Colors.grey[900],
    );

    final surahPages = quran.getSurahPages(widget.surahNumber);

    for (int pageIndex = 0; pageIndex < surahPages.length; pageIndex++) {
      final pageNum = surahPages[pageIndex];
      final pageData = quran.getPageData(pageNum);
      final pageSpans = <TextSpan>[];
      final pageEntries = pageData.where(
        (entry) => entry['surah'] == widget.surahNumber,
      );

      // Track verse range for this page
      int? firstVerse;
      int? lastVerse;

      for (var entry in pageEntries) {
        final start = entry['start'];
        final end = entry['end'];

        // Update first and last verse for this page
        firstVerse ??= start;
        lastVerse = end;

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

          // For the first verse of surahs other than 1 and 9, we'll show the Bismillah at the top of the page
          // and remove it from the verse text if it exists
          if (i == 1 && !isSurah1 && !isSurah9) {
            // Remove Bismillah from the beginning of the first verse if it exists
            if (verse.startsWith(quran.basmala)) {
              verse = verse.substring(quran.basmala.length).trim();
            }
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

      // Add the verse range for this page
      if (firstVerse != null && lastVerse != null) {
        _pageVerseRanges.add({
          'surah': widget.surahNumber,
          'firstVerse': firstVerse,
          'lastVerse': lastVerse,
        });
      } else {
        // If no verses found for this surah on this page, add a placeholder
        _pageVerseRanges.add({
          'surah': widget.surahNumber,
          'firstVerse': 1,
          'lastVerse': 1,
        });
      }

      builtPages.add(_buildQuranPage(pageSpans, pageData));
    }

    setState(() {
      pages = builtPages;
    });
  }

  Widget _buildQuranPage(List<TextSpan> spans, dynamic pageData) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Directionality(
      textDirection: ui.TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color:
              isDarkMode
                  ? Colors.black.withOpacity(0.6)
                  : Colors.white.withOpacity(0.6),
          border: Border.all(
            color: isDarkMode ? Colors.white10 : Colors.green.shade100,
            width: 1.0,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode ? Colors.black54 : Colors.grey.withOpacity(0.2),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Show Basmala at the beginning of each surah (except surah 1 and 9)
            if (spans.isNotEmpty &&
                widget.surahNumber != 1 &&
                widget.surahNumber != 9 &&
                (pageData as List).any(
                  (entry) =>
                      entry['surah'] == widget.surahNumber &&
                      entry['start'] == 1,
                ))
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
                child: Text(
                  quran.basmala,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.amiri(
                    fontSize: textSize,
                    height: lineHeight,
                    color: isDarkMode ? Colors.green[300] : Colors.green[700],
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
                          1.5, // Reduced line height for better fit
                      color: isDarkMode ? Colors.grey[100] : Colors.grey[900],
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
    // This method now only handles page changes within the current surah
    // Navigation between surahs is disabled
    // You can add any additional page change logic here if needed
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Rebuild Quran pages when theme changes (e.g., dark/light mode)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _buildPages();
      }
    });
  }

  // Build the playback control bar
  Widget _buildPlaybackBar() {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.transparent, // Fully transparent background
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 80),
            painter: WavyPainter(isDarkMode: isDarkMode),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.transparent, // Fully transparent background
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildKidFriendlyButton(
                  icon: Icons.repeat,
                  label: 'كرر',
                  onPressed: _toggleRepeat,
                  iconColor:
                      isDarkMode ? Colors.blue[300] : const Color(0xFF6C63FF),
                  isHighlighted: _isRepeatEnabled,
                  highlightColor:
                      isDarkMode ? Colors.blue[800] : Colors.blue[100],
                  showCounter: true,
                  counter: '$_repeatCount',
                ),
                _buildKidFriendlyButton(
                  icon: _isRecording ? Icons.stop : Icons.mic,
                  label: _isRecording ? 'تسجيل' : 'سجل',
                  onPressed: _toggleRecording,
                  isHighlighted: _isRecording,
                  highlightColor:
                      isDarkMode ? const Color(0xFF81C784) : Colors.red,
                  iconColor: isDarkMode ? Colors.green[300] : Colors.red,
                ),
                _buildKidFriendlyButton(
                  icon: _isPlaying ? Icons.stop : Icons.play_arrow,
                  label: _isPlaying ? 'توقف' : 'استمع',
                  onPressed: () async {
                    try {
                      if (_isPlaying) {
                        await _audioPlayer.stop();
                        setState(() {
                          _isPlaying = false;
                        });
                        return;
                      }

                      int? currentPageIndex = _pageController.page?.round();
                      if (currentPageIndex != null &&
                          currentPageIndex >= 0 &&
                          currentPageIndex < _pageVerseRanges.length) {
                        final range = _pageVerseRanges[currentPageIndex];
                        if (range['surah'] != null &&
                            range['firstVerse'] != null &&
                            range['lastVerse'] != null) {
                          await _playPageVerses(
                            range['surah']!,
                            range['firstVerse']!,
                            range['lastVerse']!,
                          );

                          setState(() {
                            _isPlaying = true;
                          });
                        } else {
                          throw Exception('بيانات الآيات غير متوفرة');
                        }
                      }
                    } catch (e) {
                      if (mounted) {
                        setState(() {
                          _isPlaying = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('حدث خطأ أثناء تشغيل الصوت: $e'),
                          ),
                        );
                      }
                    }
                  },
                  iconColor:
                      _isPlaying
                          ? (isDarkMode ? Colors.red[300] : Colors.red[700])
                          : (isDarkMode
                              ? Colors.white70
                              : const Color(0xFF4CAF50)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(
            isDarkMode
                ? 'assets/background/background_dark.png'
                : 'assets/background/background.png',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor:
            Colors.transparent, // Ensure transparency to show background
        appBar: AppBar(
          backgroundColor:
              isDarkMode ? Colors.grey[900] : const Color(0xFF2196F3),
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
                quran.getSurahNameArabic(widget.surahNumber),
                style: GoogleFonts.amiri(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${quran.getPlaceOfRevelation(widget.surahNumber) == 'Makkah' ? 'مكية' : 'مدنية'} • ${quran.getVerseCount(widget.surahNumber)} آية',
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
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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
      ),
    );
  }
}
