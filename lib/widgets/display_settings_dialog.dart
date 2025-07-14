import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class DisplaySettingsDialog extends StatefulWidget {
  final Function(bool)? onThemeChanged;

  const DisplaySettingsDialog({
    Key? key,
    this.onThemeChanged,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    Function(bool)? onThemeChanged,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => DisplaySettingsDialog(
        onThemeChanged: onThemeChanged,
      ),
    );
  }

  @override
  _DisplaySettingsDialogState createState() => _DisplaySettingsDialogState();
}

class _DisplaySettingsDialogState extends State<DisplaySettingsDialog> {
  static const String _animationsKey = 'animationsEnabled';
  static const String _reciterKey = 'selectedReciter';

  late bool _animationsEnabled;
  late String _selectedReciter;

  final List<Map<String, dynamic>> _availableReciters = [
    {'name': 'محمود خليل الحصري', 'enabled': true},
    {'name': 'عبد الباسط عبد الصمد', 'enabled': false},
    {'name': 'مشاري راشد العفاسي', 'enabled': false},
    {'name': 'سعد الغامدي', 'enabled': false},
    {'name': 'ماهر المعيقلي', 'enabled': false},
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _animationsEnabled = prefs.getBool(_animationsKey) ?? false; // Default to false
      _selectedReciter = prefs.getString(_reciterKey) ?? 'محمود خليل الحصري';
    });
  }

  Future<void> _saveSetting<T>(String key, T value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _updateTheme(bool isDark) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    await themeProvider.toggleTheme();
    if (widget.onThemeChanged != null) {
      widget.onThemeChanged!(isDark);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return AlertDialog(
          title: Text(
            'إعدادات الشاشة',
            style: GoogleFonts.notoKufiArabic(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dark Mode Toggle
            _buildSettingItem(
              title: 'الوضع المظلم',
              icon: themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              trailing: Switch(
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  _updateTheme(value);
                },
              ),
            ),

            const Divider(),

            // Reciter Selection
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'القارئ',
                style: GoogleFonts.notoKufiArabic(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                isExpanded: true,
                value: _selectedReciter,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down),
                items: _availableReciters.map((reciter) {
                  return DropdownMenuItem<String>(
                    value: reciter['name'],
                    enabled: reciter['enabled'] == true,
                    child: Text(
                      reciter['name'],
                      style: GoogleFonts.notoKufiArabic(
                        color: reciter['enabled'] == true 
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Colors.grey,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedReciter = newValue;
                    });
                    _saveSetting(_reciterKey, newValue);
                  }
                },
              ),
            ),

            const SizedBox(height: 16),

            // Animations Toggle (disabled)
            _buildSettingItem(
              title: 'الرسوم المتحركة',
              icon: Icons.animation,
              trailing: Switch(
                value: _animationsEnabled,
                onChanged: null, // Disabled
              ),
            ),
          ],
        ),
      ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'تم',
                style: GoogleFonts.notoKufiArabic(),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSettingItem({
    required String title,
    required Widget trailing,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.notoKufiArabic(
                fontSize: 15,
              ),
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
