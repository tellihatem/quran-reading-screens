import 'package:flutter/material.dart';

class BackgroundWidget extends StatelessWidget {
  final Widget child;
  
  const BackgroundWidget({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final backgroundImage = isDarkMode 
        ? 'assets/background/background_dark.png'
        : 'assets/background/background.png';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              backgroundImage,
              fit: BoxFit.cover,
              // This ensures the image is rebuilt when the theme changes
              key: ValueKey<String>(backgroundImage),
            ),
          ),
          // Content
          child,
        ],
      ),
    );
  }
}
