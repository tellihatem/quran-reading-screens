---
trigger: always_on
---

1. Add Dependencies
Update pubspec.yaml with:

dependencies:
  record: ^6.0.0
  permission_handler: ^11.3.1
2. Request Microphone Permission
Before starting a recording:

final status = await Permission.microphone.request();
if (!status.isGranted) return;
3. Initialize and Start Recording
Use the record package to begin recording:

final _recorder = Record();

if (await _recorder.hasPermission()) {
  await _recorder.start(
    path: 'path_to_file.m4a', // optional, auto-generated if null
    encoder: AudioEncoder.aacLc, // default
    bitRate: 128000,
    samplingRate: 44100,
  );
}
4. Stop Recording

final path = await _recorder.stop();
print('Audio saved at: $path');
5. UI Integration
Implement a toggle icon:

IconButton(
  icon: Icon(isRecording ? Icons.stop : Icons.mic),
  onPressed: () async {
    if (!isRecording) {
      await startRecording(); // custom method
    } else {
      await stopRecording();
    }
    setState(() => isRecording = !isRecording);
  },
)
6. Optional: File Naming
Generate unique filenames with timestamps:

final timestamp = DateTime.now().millisecondsSinceEpoch;
final path = '/your_dir/rec_$timestamp.m4a';
7. Platform Configuration
Android: Add permission to AndroidManifest.xml:

<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"/>
iOS: Add to Info.plist:

<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access to record your recitation.</string>