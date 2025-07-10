import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:delayed_display/delayed_display.dart';
import 'surah_selection_screen.dart';
import 'games_select_screen.dart';
import 'parent_control_screen.dart';
import 'widgets/pin_input_dialog.dart';
import 'services/shared_prefs_service.dart';

class MainScreen extends StatelessWidget {
  final Function() toggleDarkMode;
  final bool isDarkMode;
  
  const MainScreen({
    Key? key,
    required this.toggleDarkMode,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          const Positioned.fill(
            child: Image(
              image: AssetImage('assets/background/background.png'),
              fit: BoxFit.cover,
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Title with shadow
                      Text(
                        'الحافظ الصغير',
                        style: GoogleFonts.notoKufiArabic(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: const [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 10,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),

                      // Animated buttons
                      _buildAnimatedButton(
                        delay: 0,
                        icon: Icons.menu_book,
                        text: 'احفظ السورة',
                        color: const Color(0xFF4CAF50),
                        onPressed: () {},
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedButton(
                        delay: 1000,
                        icon: Icons.headphones,
                        text: 'استمع وردد',
                        color: const Color(0xFF2196F3),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => SurahSelectionScreen(
                                    toggleDarkMode: toggleDarkMode,
                                    isDarkMode: isDarkMode,
                                  ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedButton(
                        delay: 1400,
                        icon: Icons.games,
                        text: 'العاب',
                        color: const Color(0xFFFF9800),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const GamesSelectScreen(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      _buildAnimatedButton(
                        delay: 1800,
                        icon: Icons.lock,
                        text: 'وضع الوالدين',
                        color: const Color(0xFF607D8B),
                        onPressed: () => _handleParentControlAccess(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Animated Button Wrapper
  Widget _buildAnimatedButton({
    required int delay,
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return DelayedDisplay(
      delay: Duration(milliseconds: delay),
      fadingDuration: const Duration(milliseconds: 600),
      slidingBeginOffset: const Offset(0.0, 0.3),
      child: _buildMainButton(
        icon: icon,
        text: text,
        color: color,
        onPressed: onPressed,
      ),
    );
  }

  // Main Button UI
  Widget _buildMainButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 300,
      height: 70,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.black, 0.2) ?? color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(35),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(35),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          textDirection: TextDirection.rtl,
          children: [
            Text(
              text,
              style: GoogleFonts.notoKufiArabic(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(width: 15),
            Icon(icon, size: 32, color: Colors.white),
          ],
        ),
      ),
    );
  }

  // Handle parent control access with PIN check
  Future<void> _handleParentControlAccess(BuildContext context) async {
    final hasPin = await PinStorage.hasPin();
    
    if (hasPin) {
      // Show PIN input dialog
      final enteredPin = await showPinInputDialog(
        context: context,
        title: 'أدخل الرمز السري',
        description: 'الرجاء إدخال الرمز السري للوصول إلى وضع الوالدين',
      );

      if (enteredPin != null) {
        final isCorrect = await PinStorage.getPin() == enteredPin;
        
        if (isCorrect && context.mounted) {
          // Correct PIN, navigate to parent control
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ParentControlScreen(),
            ),
          );
        } else if (context.mounted) {
          // Wrong PIN, show error
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('الرمز السري غير صحيح', textAlign: TextAlign.center),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      // No PIN set, navigate directly
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ParentControlScreen(),
          ),
        );
      }
    }
  }
}
