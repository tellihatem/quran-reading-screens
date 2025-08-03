import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart' as record;
import 'package:shared_preferences/shared_preferences.dart';

class SurahRecordingTestScreen extends StatefulWidget {
  final int surahNumber;
  final String surahName;

  const SurahRecordingTestScreen({
    Key? key,
    required this.surahNumber,
    required this.surahName,
  }) : super(key: key);

  @override
  _SurahRecordingTestScreenState createState() =>
      _SurahRecordingTestScreenState();
}

class _SurahRecordingTestScreenState extends State<SurahRecordingTestScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final record.AudioRecorder _audioRecorder = record.AudioRecorder();
  bool _isRecording = false;
  bool _isPlaying = false;
  String? _recordingPath;
  bool _hasRecording = false;

  @override
  void initState() {
    super.initState();
    _loadExistingRecording();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<String> _getRecordingPath() async {
    final appDir = await getApplicationDocumentsDirectory();
    final recordingsDir = Directory('${appDir.path}/recordings');
    if (!await recordingsDir.exists()) {
      await recordingsDir.create(recursive: true);
    }
    return '${recordingsDir.path}/surah_${widget.surahNumber}.m4a';
  }

  Future<void> _loadExistingRecording() async {
    try {
      final filePath = await _getRecordingPath();
      final file = File(filePath);
      if (await file.exists()) {
        setState(() {
          _recordingPath = filePath;
          _hasRecording = true;
        });
      }
    } catch (e) {
      debugPrint('Error loading recording: $e');
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final filePath = await _getRecordingPath();

        final config = record.RecordConfig(
          encoder: record.AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        );

        await _audioRecorder.start(config, path: filePath);

        setState(() {
          _isRecording = true;
          _recordingPath = filePath;
          _hasRecording = false;
        });

        // Save recording info
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'recording_surah_${widget.surahNumber}',
          filePath,
        );
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء بدء التسجيل')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    try {
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
        _hasRecording = true;
      });
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء إيقاف التسجيل')),
        );
      }
    }
  }

  Future<void> _playRecording() async {
    if (_recordingPath == null) return;

    try {
      if (_isPlaying) {
        await _audioPlayer.stop();
        setState(() => _isPlaying = false);
        return;
      }

      setState(() => _isPlaying = true);
      await _audioPlayer.setFilePath(_recordingPath!);
      await _audioPlayer.play();
      await _audioPlayer.playerStateStream.firstWhere(
        (state) => state.processingState == ProcessingState.completed,
      );
    } catch (e) {
      debugPrint('Error playing recording: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('حدث خطأ أثناء تشغيل التسجيل')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPlaying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('اختبار تسميع سورة ${widget.surahName}'),
        centerTitle: true,
        backgroundColor: const Color(0xFF2196F3),
        elevation: 0,
        leading: Container(), // Empty container to remove default back button
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Icon(Icons.mic, size: 48, color: theme.primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'سجل تلاوتك لسورة ${widget.surahName} من حفظك',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'تأكد من وجودك في مكان هادئ واضغط على زر التسجيل لبدء التلاوة',
                      style: theme.textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Recording status
            if (_isRecording)
              const Text(
                'جاري التسجيل...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              )
            else if (_hasRecording)
              const Text(
                'تم تسجيل التلاوة بنجاح',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),

            const Spacer(),

            // Recording controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Record/Stop button
                ElevatedButton.icon(
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isRecording ? Colors.red : Colors.grey[300],
                    foregroundColor: _isRecording ? Colors.white : Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  icon: Icon(_isRecording ? Icons.stop : Icons.mic, size: 24),
                  label: Text(_isRecording ? 'إيقاف' : 'تسجيل'),
                ),

                // Play button
                if (_hasRecording && !_isRecording)
                  IconButton(
                    onPressed: _playRecording,
                    icon: Icon(
                      _isPlaying ? Icons.stop : Icons.play_arrow,
                      size: 36,
                      color: _isPlaying ? Colors.red : theme.primaryColor,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor:
                          _isPlaying
                              ? Colors.red.withOpacity(0.1)
                              : Colors.grey[200],
                      padding: const EdgeInsets.all(16),
                      shape: const CircleBorder(),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
