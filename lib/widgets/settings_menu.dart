import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class SettingsMenu extends StatefulWidget {
  final double initialTextSize;
  final ValueChanged<double> onTextSizeChanged;
  final double initialLineHeight;
  final ValueChanged<double>? onLineHeightChanged;
  final VoidCallback? onDarkModeToggle;
  final bool isDarkMode;

  const SettingsMenu({
    Key? key,
    required this.initialTextSize,
    required this.onTextSizeChanged,
    this.initialLineHeight = 1.2,
    this.onLineHeightChanged,
    this.onDarkModeToggle,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  _SettingsMenuState createState() => _SettingsMenuState();
}

class _SettingsMenuState extends State<SettingsMenu> {
  late double _currentTextSize;

  @override
  void initState() {
    super.initState();
    _currentTextSize = widget.initialTextSize;
  }

  // Dark mode state is now managed by the parent widget

  // Calculate line height based on font size (smaller font = smaller line height)
  double _calculateLineHeight(double fontSize) {
    // Base line height is 1.0 for default font size (24)
    // Line height decreases as font size decreases
    final baseFontSize = 24.0;
    final minLineHeight = 0.8;
    final maxLineHeight = 1.2;

    // Calculate proportional line height
    double lineHeight = 1.0 * (fontSize / baseFontSize);

    // Ensure line height stays within reasonable bounds
    return lineHeight.clamp(minLineHeight, maxLineHeight);
  }

  void _showTextSizeDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('تغيير حجم الخط'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMenuItem(
                    'حجم الخط',
                    Icons.text_fields,
                    _showTextSizeDialog,
                  ),
                  const Divider(height: 1),
                  Slider(
                    value: _currentTextSize,
                    min: 16,
                    max: 32,
                    divisions: 20,
                    label: _currentTextSize.round().toString(),
                    onChanged: (value) {
                      final newLineHeight = _calculateLineHeight(value);
                      setState(() {
                        _currentTextSize = value;
                      });
                      widget.onTextSizeChanged(value);
                      widget.onLineHeightChanged?.call(newLineHeight);
                    },
                  ),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [Text('صغير'), Text('كبير')],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('تم'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildMenuItem(String title, IconData icon, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Icon(
                icon,
                color:
                    isDark
                        ? Colors.tealAccent[200]
                        : Theme.of(context).primaryColor,
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.grey[900],
                  fontFamily: 'Amiri',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.6 : 0.2),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 40), // For balance
                  Text(
                    'الإعدادات',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 24),
                    onPressed: () => Navigator.of(context).pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              Divider(
                height: 24,
                thickness: 1,
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                indent: 16,
                endIndent: 16,
              ),
              _buildMenuItem(
                'حجم الخط',
                Icons.text_fields,
                _showTextSizeDialog,
              ),
              const SizedBox(height: 16),
              // Dark mode toggle
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  onTap: () {
                    widget.onDarkModeToggle?.call();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          widget.isDarkMode
                              ? Icons.light_mode
                              : Icons.dark_mode,
                          color:
                              isDark
                                  ? Colors.tealAccent[200]
                                  : Theme.of(context).primaryColor,
                          size: 22,
                        ),
                        const SizedBox(width: 16),
                        Text(
                          widget.isDarkMode ? 'الوضع النهاري' : 'الوضع الليلي',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.grey[900],
                            fontFamily: 'Amiri',
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: widget.isDarkMode,
                          onChanged: (_) {
                            widget.onDarkModeToggle?.call();
                          },
                          activeColor:
                              isDark
                                  ? Colors.tealAccent[200]
                                  : Theme.of(context).primaryColor,
                          activeTrackColor:
                              isDark
                                  ? Colors.tealAccent.withOpacity(0.5)
                                  : Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildMenuItem('تغيير القارئ', Icons.volume_up, () {
                // TODO: Implement reciter change
                Navigator.pop(context);
              }),
            ],
          ),
        ),
      ),
    );
  }
}
