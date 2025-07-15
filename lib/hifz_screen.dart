import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'widgets/background_widget.dart';

class HifzScreen extends StatelessWidget {
  const HifzScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BackgroundWidget(
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                height: 80,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    bottomRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Row(
                      children: [
                        _buildCounter(
                          icon: const Icon(Icons.star, color: Color(0xFFFFD700)),
                          count: 5, // Replace with actual star count
                          color: const Color(0xFFFFD700),
                        ),
                        const SizedBox(width: 20),
                        _buildCounter(
                          icon: const Icon(Icons.favorite, color: Color(0xFFE91E63)),
                          count: 3, // Replace with actual heart count
                          color: const Color(0xFFE91E63),
                        ),
                        const SizedBox(width: 20),
                        _buildCounter(
                          icon: const Icon(Icons.menu_book, color: Color(0xFF967E5D)),
                          count: 2, // Replace with actual surah count
                          color: const Color(0xFF967E5D),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.arrow_forward_ios),
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? const Color(0xFF2196F3)
                          : Colors.white,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Expanded(
                child: Center(
                  child: Text(
                    ' coming soon',
                    style: TextStyle(fontSize: 24),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCounter({
    required Widget icon,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            '$count',
            style: GoogleFonts.notoKufiArabic(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
