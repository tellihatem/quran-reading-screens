---
trigger: always_on
---

Constants:

basmala - The constant 'بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ'
sajdah - The constant 'سَجْدَةٌ'
totalJuzCount - The constant total juz count
totalMadaniSurahs - The constant total of madani surahs
totalMakkiSurahs - The constant total of makki surahs
totalPagesCount - The most standard and common copy of Arabic only Quran total pages count
totalSurahCount - The constant total surah count
totalVerseCount - The constant total verse count
Functions:

Juz:

getJuzNumber(int surahNumber, int verseNumber) - Takes [surahNumber] & [verseNumber] and returns Juz number
getSurahAndVersesFromJuz(int juzNumber) - Takes [juzNumber] and returns a map containing Surah and Verse numbers
Surah:

getSurahName(int surahNumber) - Takes [surahNumber] and returns the Surah name
getSurahNameArabic(int surahNumber) - Takes [surahNumber] returns the Surah name in Arabic
getSurahNameEnglish(int surahNumber) - Takes [surahNumber] returns the Surah name in English
getSurahNameTurkish(int surahNumber) - Takes [surahNumber] returns the Surah name in Turkish
getSurahNameFrench(int surahNumber) - Takes [surahNumber] returns the Surah name in French
getPlaceOfRevelation(int surahNumber) - Takes [surahNumber] and returns the Place of Revelation (Makkah / Madinah) of that Surah
getVerseCount(int surahNumber) - Takes [surahNumber] and returns the count of total Verses in that Surah
Verse:

getVerse(int surahNumber, int verseNumber, {bool verseEndSymbol}) - Takes [surahNumber], [verseNumber] & [verseEndSymbol] (optional) and returns the Verse in Arabic

getVerseEndSymbol(int verseNumber, {bool arabicNumeral}) - Takes [verseNumber], [arabicNumeral] (optional) and returns '۝' symbol with verse number

isSajdahVerse(int surahNumber, int verseNumber) - Takes [surahNumber], [verseNumber] and returns true if verse is sajdah verse

getVerseTranslation(int surahNumber, int verseNumber, {bool verseEndSymbol, Translation translation}) - Takes [surahNumber], [verseNumber], [verseEndSymbol] (optional) & [translation] (optional) and returns verse translation

Random Verse - Use RandomVerse class to create a random verse. Example:

RandomVerse randomVerse = RandomVerse();
print(randomVerse.surahNumber);
print(randomVerse.verseNumber);
print(randomVerse.verse);
print(randomVerse.translation);
Page:

getPageData(int pageNumber) - Takes [pageNumber] and returns a list containing Surahs and the starting and ending Verse numbers in that page
getPageNumber(int surahNumber, int verseNumber) - Takes [surahNumber], [verseNumber] and returns the page number of the Quran
getSurahCountByPage(int pageNumber) - Takes [pageNumber] and returns total surahs count in that page
getSurahPages(int surahNumber) - Takes [surahNumber] and returns the list of page numbers of that surah
getVerseCountByPage(int pageNumber) - Takes [pageNumber] and returns total verses count in that page
getVersesTextByPage(int pageNumber, {bool verseEndSymbol, SurahSeperator surahSeperator, customSurahSeperator}) - Takes [pageNumber], [verseEndSymbol], [surahSeperator] & [customSurahSeperator] and returns the list of verses in that page
URLs:

getAudioURLBySurah(int surahNumber) - Takes [surahNumber] and returns audio URL of that surah
getAudioURLByVerse(int surahNumber, int verseNumber) - Takes [surahNumber] & [verseNumber] and returns audio URL of that verse
getAudioURLByVerseNumber(int surahNumber) - Takes [verseNumber] and returns audio URL of that verse
getJuzURL(int juzNumber) - Takes [juzNumber] and returns Juz URL (from Quran.com)
getSurahURL(int surahNumber) - Takes [surahNumber] and returns Surah URL (from Quran.com)
getVerseURL(int surahNumber, int verseNumber) - Takes [surahNumber] & [verseNumber] and returns Verse URL (from Quran.com)
Search:

searchWords(List<String> words) - Takes a list of words [words] and returns a map containing no. of occurences and result of the word search in the arabic quran text
searchWordsInTranslation(List<String> words, {Translation translation}) - Takes a list of words [words] and [translation] (optional) and returns a map containing no. of occurences and result of the word search in the traslation
Translations:

English (Saheeh International) - Translation.enSaheeh
English (Clear Quran) - Translation.enClearQuran
French (Muhammad Hamidullah) - Translation.frHamidullah
Turkish - Translation.trSaheeh
Malayalam (Cheriyamundam Abdul Hameed and Kunhi Mohammed Parappoor) - Translation.mlAbdulHameed
Farsi - Translation.faHusseinDari
Portuguese - Translation.portuguese
Italian - Translation.itPiccardo
Dutch - Translation.nlSiregar
Russian - Translation.ruKuliev
Bengali - Translation.bengali
Chinese - Translation.chinese
Swedish - Translation.swedish
Spanish - Translation.spanish
Urdu - Translation.urdu
Indonesian - Translation.indonesian
Font Setup 
It is recommended to use google_fonts package and use the following fonts for better Quranic text display:

Amiri - GoogleFonts.amiri()
Amiri Quran - GoogleFonts.amiriQuran()
Setup
Add the following dependencies in your pubspec.yaml:

dependencies:
    flutter:
        sdk: flutter
    google_fonts: ^2.1.0
    quran: ^1.2.3
Usage Example
Setting font globally:

MaterialApp(
  theme: ThemeData(
    textTheme: GoogleFonts.amiriTextTheme(),
  ),
);
MaterialApp(
  theme: ThemeData(
    textTheme: GoogleFonts.amiriQuranTextTheme(),
  ),
);
For specific text:

Text(
  quran.basmala,
  style: GoogleFonts.amiri(),
),
Text(
  quran.getVerse(18, 1),
  style: GoogleFonts.amiriQuran(),
),
Example 
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;

void main() {
  runApp(MaterialApp(
    home: Scaffold(
      appBar: AppBar(
        title: Text("Quran Demo"),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Juz Number: \n" + quran.getJuzNumber(18, 1).toString()),
              Text("\nJuz URL: \n" + quran.getJuzURL(15)),
              Text("\nSurah and Verses in Juz 15: \n" + quran.getSurahAndVersesFromJuz(15).toString()),
              Text("\nSurah Name: \n" + quran.getSurahName(18)),
              Text("\nSurah Name (English): \n" + quran.getSurahNameEnglish(18)),
              Text("\nSurah URL: \n" + quran.getSurahURL(18)),
              Text("\nTotal Verses: \n" + quran.getVerseCount(18).toString()),
              Text("\nPlace of Revelation: \n" + quran.getPlaceOfRevelation(18)),
              Text(
                "\nBasmala: \n${quran.basmala}",
                style: GoogleFonts.amiriQuran(),
              ),
              Text(
                "\nVerse 1: \n${quran.getVerse(18, 1)}",
                style: GoogleFonts.amiriQuran(),
              ),
            ],
          ),
        ),
      ),
    ),
  ));
}
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;

void main() {
  runApp(
    MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(quran.getSurahName(18)),
        ),
        body: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(15.0),
            child: ListView.builder(
              itemCount: quran.getVerseCount(18),
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    quran.getVerse(18, index + 1, verseEndSymbol: true),
                    textAlign: TextAlign.right,
                    style: GoogleFonts.amiri(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}