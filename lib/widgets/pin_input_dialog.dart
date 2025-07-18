import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:haffiz/services/shared_prefs_service.dart';

class PinStorage {
  // Save PIN to SharedPreferences
  static Future<void> savePin(String pin) async {
    await sharedPrefsService.savePin(pin);
  }

  // Get PIN from SharedPreferences
  static Future<String?> getPin() async {
    return await sharedPrefsService.getPin();
  }

  // Check if PIN exists
  static Future<bool> hasPin() async {
    return await sharedPrefsService.hasPin();
  }

  // Clear PIN from SharedPreferences
  static Future<void> clearPin() async {
    await sharedPrefsService.clearPin();
  }
}

class PinInputDialog extends StatefulWidget {
  final String title;
  final String description;
  final int pinLength;
  final Function(String) onPinEntered;
  final bool showForgotPin;
  final VoidCallback? onForgotPin;

  const PinInputDialog({
    Key? key,
    required this.title,
    required this.description,
    this.pinLength = 4,
    required this.onPinEntered,
    this.showForgotPin = false,
    this.onForgotPin,
  }) : super(key: key);

  @override
  _PinInputDialogState createState() => _PinInputDialogState();
}

class _PinInputDialogState extends State<PinInputDialog> {
  String _enteredPin = '';
  final FocusNode _focusNode = FocusNode();

  void _onKeyPressed(String value) {
    if (value == 'clear') {
      setState(() => _enteredPin = '');
    } else if (value == 'backspace') {
      if (_enteredPin.isNotEmpty) {
        setState(() => _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1));
      }
    } else if (_enteredPin.length < widget.pinLength) {
      setState(() => _enteredPin += value);
      
      if (_enteredPin.length == widget.pinLength) {
        // Small delay to show the last digit before processing
        Future.delayed(const Duration(milliseconds: 100), () {
          widget.onPinEntered(_enteredPin);
        });
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // Calculate responsive sizes based on screen size
  double _getDialogWidth(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    
    if (isLandscape) {
      return height * 0.8; // Use height as reference in landscape
    }
    return width > 600 ? 500.0 : width * 0.9;
  }

  double _getButtonSize(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final height = mediaQuery.size.height;
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    
    if (isLandscape) {
      return height * 0.1; // Smaller buttons in landscape
    }
    return width > 600 ? 72.0 : 60.0;
  }
  
  double _getVerticalPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    if (mediaQuery.orientation == Orientation.landscape) {
      return 8.0;
    }
    return 16.0;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;
    final dialogWidth = _getDialogWidth(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: mediaQuery.size.height * 0.9,
        ),
        child: SingleChildScrollView(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isLandscape ? 16.0 : 24.0,
                  vertical: _getVerticalPadding(context),
                ),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).shadowColor.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title with responsive font size
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      widget.title,
                      style: GoogleFonts.notoKufiArabic(
                        fontSize: isLandscape ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF2196F3),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Description with responsive font size
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      widget.description,
                      style: GoogleFonts.notoKufiArabic(
                        fontSize: isLandscape ? 14 : 16,
                        color: Theme.of(context).textTheme.bodyLarge?.color?.withOpacity(0.7),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // PIN Dots with responsive sizing
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.pinLength,
                        (index) => Container(
                          width: isLandscape ? 20 : 24,
                          height: isLandscape ? 20 : 24,
                          margin: EdgeInsets.symmetric(horizontal: isLandscape ? 8 : 12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index < _enteredPin.length
                                ? const Color(0xFF2196F3)
                                : Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white10
                                    : Theme.of(context).dividerColor,
                            boxShadow: [
                              if (index == _enteredPin.length)
                                BoxShadow(
                                  color: const Color(0xFF2196F3).withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Numeric Keypad with responsive sizing
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLandscape ? 8.0 : 16.0,
                      vertical: 8.0,
                    ),
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 1.2,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // 1-9
                        for (int i = 1; i <= 9; i++)
                          _buildKeypadButton(
                            text: i.toString(),
                            onPressed: () => _onKeyPressed(i.toString()),
                          ),
                        
                        // Clear button
                        _buildKeypadButton(
                          icon: Icons.cleaning_services_outlined,
                          onPressed: () => _onKeyPressed('clear'),
                        ),
                        
                        // 0
                        _buildKeypadButton(
                          text: '0',
                          onPressed: () => _onKeyPressed('0'),
                        ),
                        
                        // Backspace
                        _buildKeypadButton(
                          icon: Icons.backspace_outlined,
                          onPressed: () => _onKeyPressed('backspace'),
                        ),
                      ],
                    ),
                  ),
                  if (widget.showForgotPin && widget.onForgotPin != null) ...[
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: widget.onForgotPin,
                      child: Text(
                        'نسيت الرمز السري؟',
                        style: GoogleFonts.notoKufiArabic(
                          fontSize: 14,
                          color: const Color(0xFF2196F3),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Exit button (X) in top-right corner
            Positioned(
              top: 8,
              right: 8,
              child: InkResponse(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Color(0xFF6D8C91),
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    )
    );
  }

  Widget _buildKeypadButton({
    String? text,
    IconData? icon,
    required VoidCallback onPressed,
  }) {
    final buttonSize = _getButtonSize(context);
    final iconSize = buttonSize * 0.35;
    final fontSize = buttonSize * 0.4;
    
    return AspectRatio(
      aspectRatio: 1.0,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFD1EDE7),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: icon != null
                    ? Icon(
                        icon,
                        color: const Color(0xFF2196F3),
                        size: iconSize,
                      )
                    : Text(
                        text!,
                        style: GoogleFonts.notoKufiArabic(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF2196F3),
                          height: 1.2,
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

Future<String?> showPinInputDialog({
  required BuildContext context,
  required String title,
  required String description,
  int pinLength = 4,
  bool showForgotPin = false,
  VoidCallback? onForgotPin,
  bool shouldSavePin = false, // New parameter to control if PIN should be saved
}) async {
  String? result;
  
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => PinInputDialog(
      title: title,
      description: description,
      pinLength: pinLength,
      showForgotPin: showForgotPin,
      onForgotPin: onForgotPin,
      onPinEntered: (pin) async {
        result = pin;
        if (shouldSavePin) {
          await PinStorage.savePin(pin);
        }
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
    ),
  );
  
  return result;
}

// New function to verify PIN
Future<bool> verifyStoredPin(String enteredPin) async {
  final storedPin = await PinStorage.getPin();
  return storedPin == enteredPin;
}

// New function to check if PIN is set
Future<bool> isPinSet() async {
  return await PinStorage.hasPin();
}

// New function to clear stored PIN
Future<void> clearStoredPin() async {
  await PinStorage.clearPin();
}
