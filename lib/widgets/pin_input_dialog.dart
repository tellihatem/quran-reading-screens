import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  widget.title,
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF4B6A70),
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 16),
                
                // Description
                Text(
                  widget.description,
                  style: GoogleFonts.notoKufiArabic(
                    fontSize: 16,
                    color: const Color(0xFF6D8C91),
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  textDirection: TextDirection.rtl,
                ),
                
                const SizedBox(height: 32),
                
                // PIN Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    widget.pinLength,
                    (index) => Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < _enteredPin.length
                            ? const Color(0xFF4EC8B4)
                            : const Color(0xFFE0E0E0),
                        boxShadow: [
                          if (index == _enteredPin.length)
                            BoxShadow(
                              color: const Color(0xFF4EC8B4).withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Numeric Keypad
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.2,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                
                if (widget.showForgotPin && widget.onForgotPin != null) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: widget.onForgotPin,
                    child: Text(
                      'نسيت الرمز السري؟',
                      style: GoogleFonts.notoKufiArabic(
                        fontSize: 14,
                        color: const Color(0xFF4EC8B4),
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
            top: -10,
            right: -10,
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
    );
  }

  Widget _buildKeypadButton({
    String? text,
    IconData? icon,
    required VoidCallback onPressed,
  }) {
    return Material(
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
                    color: const Color(0xFF4B6A70),
                    size: 28,
                  )
                : Text(
                    text!,
                    style: GoogleFonts.notoKufiArabic(
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF4B6A70),
                      height: 1.2,
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
      onPinEntered: (pin) {
        result = pin;
        Navigator.of(context).pop();
      },
    ),
  );
  
  return result;
}
