import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran/quran.dart' as quran;
import 'widgets/background_widget.dart';

class Surah {
  final String name;
  final int number;

  Surah({required this.name, required this.number});

  factory Surah.fromJson(Map<String, dynamic> json) {
    return Surah(name: json['name'] as String, number: json['number'] as int);
  }
}

class ParentProgressScreen extends StatefulWidget {
  const ParentProgressScreen({Key? key}) : super(key: key);

  @override
  State<ParentProgressScreen> createState() => _ParentProgressScreenState();
}

class _ParentProgressScreenState extends State<ParentProgressScreen> {
  Future<int> _getGlobalStarCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('global_star_count') ?? 0;
  }

  Future<int> _getThreeStarSurahsCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('three_star_surahs_count') ?? 0;
  }

  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  int? _currentlyPlayingSurah;
  Duration? _duration;
  Duration? _position;
  List<Map<String, dynamic>> _recordedSurahs = [];

  @override
  void initState() {
    super.initState();
    // Add a small delay to ensure the widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecordedSurahs();
      _setupAudioPlayer();
    });
  }

  void _setupAudioPlayer() {
    _audioPlayer.positionStream.listen((position) {
      if (mounted) {
        setState(() => _position = position);
      }
    });

    _audioPlayer.durationStream.listen((duration) {
      if (mounted) {
        setState(() => _duration = duration);
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadRecordedSurahs() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final recordingsDir = Directory('${appDir.path}/recordings');
      final prefs = await SharedPreferences.getInstance();

      // Ensure the recordings directory exists
      if (!await recordingsDir.exists()) {
        await recordingsDir.create(recursive: true);
        if (mounted) setState(() => _recordedSurahs = []);
        return;
      }

      // List all .m4a files in the directory
      final files =
          await recordingsDir
              .list()
              .where((entity) => entity.path.endsWith('.m4a'))
              .toList();

      final List<Map<String, dynamic>> recordedSurahs = [];
      final surahPattern = RegExp(r'surah_(\d+)\.m4a$');

      for (var file in files) {
        final match = surahPattern.firstMatch(file.path);
        if (match != null) {
          try {
            final surahNumber = int.parse(match.group(1)!);
            // Verify both file exists and has a valid entry in SharedPreferences
            final prefKey = 'recording_surah_$surahNumber';
            if (await prefs.containsKey(prefKey)) {
              recordedSurahs.add({
                'number': surahNumber,
                'name': quran.getSurahNameArabic(surahNumber),
              });
            } else {
              // Clean up orphaned recording
              try {
                await File(file.path).delete();
              } catch (e) {}
            }
          } catch (e) {
            debugPrint('Error processing file ${file.path}: $e');
          }
        }
      }

      // Sort by surah number
      recordedSurahs.sort((a, b) => a['number'].compareTo(b['number']));

      if (mounted) {
        setState(() => _recordedSurahs = recordedSurahs);
      }
    } catch (e) {
      debugPrint('Error loading recorded surahs: $e');
      if (mounted) setState(() => _recordedSurahs = []);
    }
  }

  Future<void> _playSurahRecording(int surahNumber) async {
    try {
      if (_isPlaying && _currentlyPlayingSurah == surahNumber) {
        await _audioPlayer.pause();
        setState(() {
          _isPlaying = false;
        });
        return;
      }

      final appDir = await getApplicationDocumentsDirectory();
      final recordingPath = '${appDir.path}/recordings/surah_$surahNumber.m4a';
      final file = File(recordingPath);

      if (await file.exists()) {
        setState(() {
          _isPlaying = true;
          _currentlyPlayingSurah = surahNumber;
          _position = Duration.zero;
        });

        await _audioPlayer.stop();
        await _audioPlayer.setFilePath(recordingPath);
        await _audioPlayer.play();

        _audioPlayer.playerStateStream.listen(
          (state) {
            if (state.processingState == ProcessingState.completed) {
              if (mounted) {
                setState(() {
                  _isPlaying = false;
                  _currentlyPlayingSurah = null;
                  _position = _duration;
                });
              }
            }
          },
          onError: (e) {
            debugPrint('Error playing recording: $e');
            if (mounted) {
              setState(() {
                _isPlaying = false;
                _currentlyPlayingSurah = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('حدث خطأ أثناء تشغيل التسجيل')),
              );
            }
          },
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('لا يوجد تسجيل مسجل لهذه السورة')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error playing recording: $e');
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingSurah = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تشغيل التسجيل')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardColor = isDark ? Colors.grey[900]! : Colors.white;
    final Color textColor = isDark ? Colors.white : Colors.black87;
    final Color accentColor = isDark ? Colors.tealAccent : Color(0xFF2196F3);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: BackgroundWidget(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(
                    context,
                  ).copyWith(scrollbars: false, overscroll: false),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Back arrow on the left
                          Row(
                            children: [
                              const SizedBox(
                                width: 38,
                              ), // To balance the title on the right
                              Text(
                                'تقدم طفلك',
                                style: GoogleFonts.notoKufiArabic(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: const Color.fromARGB(
                                    255,
                                    230,
                                    223,
                                    223,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_forward_ios_rounded,
                                ),
                                color: const Color.fromARGB(255, 230, 223, 223),
                                onPressed: () => Navigator.of(context).pop(),
                                alignment: Alignment.centerLeft,
                                padding:
                                    EdgeInsets
                                        .zero, // Remove default padding for tightest alignment
                                constraints:
                                    const BoxConstraints(), // Remove extra constraints
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          // Advancement summary card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardColor.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.07),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    Column(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          color: Colors.amber[700],
                                          size: 36,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'عدد النجوم',
                                          style: GoogleFonts.notoKufiArabic(
                                            fontSize: 14,
                                            color: textColor,
                                          ),
                                        ),
                                        FutureBuilder<int>(
                                          future: _getGlobalStarCount(),
                                          builder: (context, snapshot) {
                                            final starCount =
                                                snapshot.data ?? 0;
                                            return Text(
                                              starCount.toString(),
                                              style: GoogleFonts.notoKufiArabic(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: accentColor,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                    Column(
                                      children: [
                                        Icon(
                                          Icons.menu_book_rounded,
                                          color: accentColor,
                                          size: 36,
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'السور المحفوظة',
                                          style: GoogleFonts.notoKufiArabic(
                                            fontSize: 14,
                                            color: textColor,
                                          ),
                                        ),
                                        FutureBuilder<int>(
                                          future: _getThreeStarSurahsCount(),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState ==
                                                ConnectionState.waiting) {
                                              return const CircularProgressIndicator();
                                            }
                                            return Text(
                                              '${snapshot.data ?? 0}',
                                              style: GoogleFonts.notoKufiArabic(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: accentColor,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Voice playback section for multiple surahs
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color:
                                  isDark ? Colors.grey[850] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'الاستماع لتسجيل طفلك لكل سورة',
                                  style: GoogleFonts.notoKufiArabic(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                                const SizedBox(height: 10),
                                ...[
                                  if (_recordedSurahs.isEmpty)
                                    Column(
                                      children: [
                                        const SizedBox(height: 20),
                                        Icon(
                                          Icons.mic_off_rounded,
                                          size: 48,
                                          color: textColor.withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'لا توجد تسجيلات متاحة',
                                          style: GoogleFonts.notoKufiArabic(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600,
                                            color: textColor,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16.0,
                                          ),
                                          child: Text(
                                            'سيظهر هنا السور التي سيسجلها طفلك بعد الانتهاء من الحفظ',
                                            style: GoogleFonts.notoKufiArabic(
                                              fontSize: 14,
                                              color: textColor.withOpacity(0.7),
                                              height: 1.5,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                      ],
                                    )
                                  else
                                    ..._recordedSurahs.map<Widget>((surahData) {
                                      final surah = Surah.fromJson(
                                        Map<String, dynamic>.from(surahData),
                                      );
                                      final surahNumber = surah.number;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 6.0,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isDark
                                                    ? Colors.grey[900]
                                                    : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.04,
                                                ),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ],
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                children: [
                                                  GestureDetector(
                                                    onTap:
                                                        () =>
                                                            _playSurahRecording(
                                                              surahNumber,
                                                            ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            _isPlaying &&
                                                                    _currentlyPlayingSurah ==
                                                                        surahNumber
                                                                ? Colors.red
                                                                    .withOpacity(
                                                                      0.1,
                                                                    )
                                                                : accentColor
                                                                    .withOpacity(
                                                                      0.1,
                                                                    ),
                                                        shape: BoxShape.circle,
                                                      ),
                                                      child: Icon(
                                                        _isPlaying &&
                                                                _currentlyPlayingSurah ==
                                                                    surahNumber
                                                            ? Icons
                                                                .pause_circle_filled
                                                            : Icons
                                                                .play_circle_fill_rounded,
                                                        color:
                                                            _isPlaying &&
                                                                    _currentlyPlayingSurah ==
                                                                        surahNumber
                                                                ? Colors.red
                                                                : accentColor,
                                                        size: 36,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          surah.name,
                                                          style:
                                                              GoogleFonts.notoKufiArabic(
                                                                fontSize: 16,
                                                                color:
                                                                    textColor,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                              ),
                                                        ),
                                                        if (_currentlyPlayingSurah ==
                                                                surahNumber &&
                                                            _duration != null)
                                                          Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .stretch,
                                                            children: [
                                                              const SizedBox(
                                                                height: 8,
                                                              ),
                                                              SliderTheme(
                                                                data: SliderTheme.of(
                                                                  context,
                                                                ).copyWith(
                                                                  activeTrackColor:
                                                                      accentColor,
                                                                  inactiveTrackColor:
                                                                      Colors
                                                                          .grey[300],
                                                                  trackHeight:
                                                                      2.0,
                                                                  thumbColor:
                                                                      accentColor,
                                                                  thumbShape:
                                                                      const RoundSliderThumbShape(
                                                                        enabledThumbRadius:
                                                                            6.0,
                                                                      ),
                                                                  overlayColor:
                                                                      accentColor
                                                                          .withOpacity(
                                                                            0.3,
                                                                          ),
                                                                  overlayShape:
                                                                      const RoundSliderOverlayShape(
                                                                        overlayRadius:
                                                                            10.0,
                                                                      ),
                                                                ),
                                                                child: Slider(
                                                                  value:
                                                                      _position
                                                                          ?.inMilliseconds
                                                                          .toDouble() ??
                                                                      0.0,
                                                                  min: 0.0,
                                                                  max:
                                                                      _duration!
                                                                          .inMilliseconds
                                                                          .toDouble(),
                                                                  onChanged: (
                                                                    value,
                                                                  ) {
                                                                    setState(() {
                                                                      _position = Duration(
                                                                        milliseconds:
                                                                            value.toInt(),
                                                                      );
                                                                    });
                                                                    _audioPlayer
                                                                        .seek(
                                                                          _position,
                                                                        );
                                                                  },
                                                                ),
                                                              ),
                                                              Padding(
                                                                padding:
                                                                    const EdgeInsets.symmetric(
                                                                      horizontal:
                                                                          8.0,
                                                                    ),
                                                                child: Row(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .spaceBetween,
                                                                  children: [
                                                                    Text(
                                                                      '${_position?.inMinutes.toString().padLeft(2, '0')}:${(_position?.inSeconds.remainder(60)).toString().padLeft(2, '0')}',
                                                                      style: GoogleFonts.notoKufiArabic(
                                                                        fontSize:
                                                                            12,
                                                                        color: textColor
                                                                            .withOpacity(
                                                                              0.7,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                    Text(
                                                                      '${_duration?.inMinutes.toString().padLeft(2, '0')}:${(_duration?.inSeconds.remainder(60)).toString().padLeft(2, '0')}',
                                                                      style: GoogleFonts.notoKufiArabic(
                                                                        fontSize:
                                                                            12,
                                                                        color: textColor
                                                                            .withOpacity(
                                                                              0.7,
                                                                            ),
                                                                      ),
                                                                    ),
                                                                  ],
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              // Progress indicator and buttons row
                                              const SizedBox(height: 12),
                                              Row(
                                                children: [
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      style: ButtonStyle(
                                                        backgroundColor:
                                                            MaterialStateProperty.resolveWith<
                                                              Color
                                                            >((
                                                              Set<MaterialState>
                                                              states,
                                                            ) {
                                                              if (states.contains(
                                                                MaterialState
                                                                    .hovered,
                                                              )) {
                                                                return Colors
                                                                    .green;
                                                              }
                                                              return const Color(
                                                                0xFF2196F3,
                                                              );
                                                            }),
                                                        padding:
                                                            MaterialStateProperty.all(
                                                              const EdgeInsets.symmetric(
                                                                vertical: 10,
                                                              ),
                                                            ),
                                                        shape: MaterialStateProperty.all(
                                                          RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                      icon: const Icon(
                                                        Icons
                                                            .check_circle_outline,
                                                        color: Colors.white,
                                                        size: 18,
                                                      ),
                                                      label: Text(
                                                        'قبول كمحفوظ',
                                                        style:
                                                            GoogleFonts.notoKufiArabic(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      ),
                                                      onPressed: () async {
                                                        final prefs =
                                                            await SharedPreferences.getInstance();
                                                        final surahNumber =
                                                            surah.number;

                                                        try {
                                                          // Delete the audio file and remove the surah from SharedPreferences and the UI list
                                                          final recordingKey = 'recording_surah_$surahNumber';
                                                          final filePath = prefs.getString(recordingKey);
                                                          if (filePath != null) {
                                                            final audioFile = File(filePath);
                                                            if (await audioFile.exists()) {
                                                              await audioFile.delete();
                                                            }
                                                            await prefs.remove(recordingKey);
                                                          }
                                                          setState(() {
                                                            _recordedSurahs.removeWhere((s) => s['number'] == surahNumber);
                                                          });

                                                          // Mark surah as record passed
                                                          await prefs.setBool(
                                                            'surah_${surahNumber}_record_passed',
                                                            true,
                                                          );

                                                          // Increment memorized surahs counter
                                                          final currentMemorized =
                                                              prefs.getInt(
                                                                'memorized_surahs_count',
                                                              ) ??
                                                              0;
                                                          await prefs.setInt(
                                                            'memorized_surahs_count',
                                                            currentMemorized +
                                                                1,
                                                          );

                                                          // Update global star count
                                                          final currentGlobalStars =
                                                              prefs.getInt(
                                                                'global_star_count',
                                                              ) ??
                                                              0;
                                                          await prefs.setInt(
                                                            'global_star_count',
                                                            currentGlobalStars +
                                                                1,
                                                          );

                                                          // Increment the three-star surahs counter by 1 every time the button is pressed
                                                          await prefs.setInt(
                                                            'three_star_surahs_count',
                                                            prefs.getInt(
                                                                  'three_star_surahs_count',
                                                                ) ??
                                                                0 + 1,
                                                          );

                                                          if (mounted) {
                                                            Navigator.of(
                                                              context,
                                                            ).pop();

                                                            // Show success message
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              const SnackBar(
                                                                content: Text(
                                                                  'تم حفظ السورة بنجاح!',
                                                                  textAlign:
                                                                      TextAlign
                                                                          .center,
                                                                ),
                                                                backgroundColor:
                                                                    Colors
                                                                        .green,
                                                              ),
                                                            );

                                                            // Update the UI
                                                            setState(() {
                                                              // Remove the surah from the list
                                                              _recordedSurahs
                                                                  .removeWhere(
                                                                    (s) =>
                                                                        s['number'] ==
                                                                        surahNumber,
                                                                  );
                                                            });
                                                          }
                                                        } catch (e) {
                                                          if (mounted) {
                                                            ScaffoldMessenger.of(
                                                              context,
                                                            ).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  'حدث خطأ: ${e.toString()}',
                                                                ),
                                                                backgroundColor:
                                                                    Colors.red,
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 10),
                                                  Expanded(
                                                    child: ElevatedButton.icon(
                                                      style: ButtonStyle(
                                                        backgroundColor:
                                                            MaterialStateProperty.resolveWith<
                                                              Color
                                                            >((
                                                              Set<MaterialState>
                                                              states,
                                                            ) {
                                                              if (states.contains(
                                                                MaterialState
                                                                    .hovered,
                                                              )) {
                                                                return Colors
                                                                    .red;
                                                              }
                                                              return const Color(
                                                                0xFF2196F3,
                                                              );
                                                            }),
                                                        padding:
                                                            MaterialStateProperty.all(
                                                              const EdgeInsets.symmetric(
                                                                vertical: 10,
                                                              ),
                                                            ),
                                                        shape: MaterialStateProperty.all(
                                                          RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  10,
                                                                ),
                                                          ),
                                                        ),
                                                      ),
                                                      icon: const Icon(
                                                        Icons.refresh_rounded,
                                                        color: Colors.white,
                                                        size: 18,
                                                      ),
                                                      label: Text(
                                                        'إعادة الاختبار',
                                                        style:
                                                            GoogleFonts.notoKufiArabic(
                                                              fontSize: 14,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                      ),
                                                      onPressed: () {},
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
