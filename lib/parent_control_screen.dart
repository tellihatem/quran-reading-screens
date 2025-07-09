import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/background_widget.dart';

class ParentControlScreen extends StatefulWidget {
  const ParentControlScreen({Key? key}) : super(key: key);

  @override
  _ParentControlScreenState createState() => _ParentControlScreenState();
}

class _ParentControlScreenState extends State<ParentControlScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('وضع الوالدين'),
        centerTitle: true,
        backgroundColor: const Color(0xFF607D8B),
      ),
      body: BackgroundWidget(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'شاشة إعدادات الوالدين',
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                // Add your parental control widgets here
              ],
            ),
          ),
        ),
      ),
    );
  }
}
