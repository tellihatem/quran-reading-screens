import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/background_widget.dart';
import 'widgets/pin_input_dialog.dart';

const double _kVerticalPadding = 20.0;
const double _kMaxContentWidth = 500.0;

class ParentControlScreen extends StatefulWidget {
  const ParentControlScreen({Key? key}) : super(key: key);

  @override
  _ParentControlScreenState createState() => _ParentControlScreenState();
}

class _ParentControlScreenState extends State<ParentControlScreen> {
  // Reusable glass button widget
  Widget _buildMenuButton({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.2),
              Colors.white.withOpacity(0.05),
            ],
          ),
          border: Border.all(
            color: Colors.white.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    title,
                    style: GoogleFonts.notoKufiArabic(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          TextDirection.ltr, // This will make the back arrow appear on the left
      child: Scaffold(
        appBar: AppBar(
          title: const Text('وضع الوالدين'),
          centerTitle: true,
          backgroundColor: const Color(0xFF2196F3),
        ),
        body: BackgroundWidget(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                    maxWidth: _kMaxContentWidth,
                  ),
                  child: ScrollConfiguration(
                    behavior: ScrollConfiguration.of(context).copyWith(
                      scrollbars: false,
                    ),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      child: SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24.0,
                            vertical: _kVerticalPadding,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Lock Icon with Gradient
                              Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF66C2A3),
                                      Color(0xFF4EC8B4),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.lock_outline_rounded,
                                size: 70,
                                color: Colors.white,
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Title
                            Text(
                              'وضع الوالدين',
                              style: GoogleFonts.notoKufiArabic(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4B6A70),
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),

                            const SizedBox(height: 12),

                            // Subtitle
                            Text(
                              'للتحكم في وقت الاستخدام والمحتوى المناسب',
                              style: GoogleFonts.notoKufiArabic(
                                fontSize: 16,
                                fontWeight: FontWeight.w300,
                                color: const Color.fromARGB(255, 177, 193, 196),
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                              textDirection: TextDirection.rtl,
                            ),

                            const SizedBox(height: 40),

                            // Menu Buttons
                            _buildMenuButton(
                              title: 'تغيير الرمز السري',
                              icon: Icons.lock_reset_rounded,
                              onTap: () async {
                                final newPin = await showPinInputDialog(
                                  context: context,
                                  title: 'تغيير الرمز السري',
                                  description: 'أدخل الرمز السري الجديد',
                                  showForgotPin: false,
                                );
                                
                                if (newPin != null && newPin.length == 4) {
                                  // TODO: Implement password change logic here
                                  // For example: await _authService.changePin(newPin);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'تم تغيير الرمز السري بنجاح',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.notoKufiArabic(),
                                        ),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                }
                              },
                            ),
                            _buildMenuButton(
                              title: 'وقت الاستخدام اليومي',
                              icon: Icons.timer_outlined,
                              onTap: () {
                                // TODO: Implement daily usage time
                              },
                            ),
                            _buildMenuButton(
                              title: 'اعدادات الشاشة',
                              icon: Icons.settings_display_outlined,
                              onTap: () {
                                // TODO: Implement screen settings
                              },
                            ),
                            _buildMenuButton(
                              title: 'تتبع التقدم',
                              icon: Icons.timeline_outlined,
                              onTap: () {
                                // TODO: Implement progress tracking
                              },
                            ),
                          ],
                        ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
