---
trigger: manual
---

🔧 1. Add Dependencies in pubspec.yaml
dependencies:
  just_audio: ^0.10.4
  just_audio_background: ^0.0.1-beta.17
🏁 2. Initialize Background Audio in main()
In your main.dart, before runApp(), call:
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.quran.channel.audio',
    androidNotificationChannelName: 'Quran Playback',
    androidNotificationOngoing: true,
  );

  runApp(MyApp());
}
▶️ 3. Create AudioPlayer and Attach MediaItem Metadata
final player = AudioPlayer();

await player.setAudioSource(
  AudioSource.uri(
    Uri.parse('https://example.com/audio/ayah1.mp3'),
    tag: MediaItem(
      id: 'ayah-1',
      title: 'Ayah 1',
      album: 'Surah Al-Baqarah',
      artUri: Uri.parse('https://example.com/surah_art.jpg'), // optional
    ),
  ),
);

await player.play();
✅ MediaItem is required for just_audio_background to show the notification & lock screen info.

📱 4. Android Setup (Android 12+ Compatible)
In AndroidManifest.xml:
Add inside <manifest>:
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE"/>
<uses-permission android:name="android.permission.FOREGROUND_SERVICE_MEDIA_PLAYBACK"/>
Inside <application> tag:
<activity android:name="com.ryanheise.audioservice.AudioServiceActivity" ... />

<service
  android:name="com.ryanheise.audioservice.AudioService"
  android:foregroundServiceType="mediaPlayback"
  android:exported="true"
  tools:ignore="Instantiatable">
  <intent-filter>
    <action android:name="android.media.browse.MediaBrowserService" />
  </intent-filter>
</service>

<receiver
  android:name="com.ryanheise.audioservice.MediaButtonReceiver"
  android:exported="true"
  tools:ignore="Instantiatable">
  <intent-filter>
    <action android:name="android.intent.action.MEDIA_BUTTON" />
  </intent-filter>
</receiver>
🔔 This ensures proper notification, lock screen controls, and background media playback.

🍏 5. iOS Setup (For background audio)
In ios/Runner/Info.plist, add:
<key>UIBackgroundModes</key>
<array>
  <string>audio</string>
</array>
🎵 6. For Quran Playback (Recommended Flow)
Create a ConcatenatingAudioSource of verses in a surah

Assign MediaItem to each verse with correct ID and metadata (surah, verse number, optional image)

Use player.seekToNext() or player.seekToPrevious() for verse navigation

just_audio_background will show currently playing ayah on the lock screen and notification