# Little Hafiz

A comprehensive Quran memorization experience for kids and adults. This Flutter-based project offers verse-by-verse listening, interactive memorization methods, progress tracking, and more. It’s optimized for Flutter Web but can also be wrapped for mobile platforms.

## ✨ Features

* Display of Quranic text with surah and ayah selection.
* Various memorization methods implemented for flexible learning.
* Interactive exercises and gamified memorization techniques.
* Progress tracking for learners and parental oversight.
* Offline-capable PWA experience via `flutter_service_worker.js`.

## 🛠️ Tech Stack

* **Framework:** Flutter (Dart)
* **Target:** Flutter Web (Android/iOS support available)
* **Rendering:** CanvasKit for high-quality typography and smooth animations
* **PWA:** Manifest + service worker for offline usage and installability

## 🚀 Getting Started

1. Clone the repository:

   ```bash
   git clone https://github.com/tellihatem/Little_Haffiz.git
   ```
2. Navigate to the project folder:

   ```bash
   cd Little_Haffiz
   ```
3. Install dependencies:

   ```bash
   flutter pub get
   ```
4. Run the app in web mode:

   ```bash
   flutter run -d chrome
   ```

## 📂 Project Structure

* `lib/` – Main Flutter code and screens
* `assets/` – Images, audio, and other static resources
* `web/` – Web-specific build assets and PWA configuration
* `android/`, `ios/`, `windows/`, `macos/`, `linux/` – Platform-specific files

## 🤝 Contributing

Contributions, issues, and feature requests are welcome.
Please follow standard Flutter/Dart guidelines when submitting changes.

## 📜 License

This project is open source. Check the repository for the license file.
