---
trigger: always_on
---

1. Initialize the Player
final player = AudioPlayer();
Use this once per session or per track.

2. Play a Single Audio File (from asset, URL, or local file)
await player.setUrl('https://example.com/ayah.mp3');
player.play();
Use .play() to start

Use .pause() to pause

Use .stop() to release resources

3. Seek, Speed & Volume
await player.seek(Duration(seconds: 10)); // jump to position
await player.setSpeed(1.0);               // normal speed
await player.setVolume(1.0);              // full volume
4. Play a Range (Clip)
To play specific verse segments (e.g. ayah start to end):
await player.setClip(start: Duration(seconds: 3), end: Duration(seconds: 7));
await player.play();
5. Play a Playlist (e.g. all verses in a Surah)
await player.setAudioSources([
  AudioSource.uri(Uri.parse('url1')),
  AudioSource.uri(Uri.parse('url2')),
]);
Control playlist:
await player.seekToNext();
await player.seekToPrevious();
await player.setLoopMode(LoopMode.all);
6. Detect Completion
player.playerStateStream.listen((state) {
  if (state.processingState == ProcessingState.completed) {
    // move to next ayah or show replay button
  }
});
7. Error Handling
player.errorStream.listen((error) {
  print('Audio error: ${error.message}');
});
8. Optimize Caching (Optional)
Use caching to store audio locally if performance is needed:
final cachedSource = LockCachingAudioSource('https://url.com/audio.mp3');
await player.setAudioSource(cachedSource);
9. Cross-platform Configuration
Make sure the following is set in AndroidManifest.xml:
<uses-permission android:name="android.permission.INTERNET"/>
<application android:usesCleartextTraffic="true">
And this in Info.plist for iOS/macOS:
<key>NSAppTransportSecurity</key>
<dict><key>NSAllowsArbitraryLoads</key><true/></dict>
10. Stop and Dispose
Always stop player when done:
await player.stop();
await player.dispose();