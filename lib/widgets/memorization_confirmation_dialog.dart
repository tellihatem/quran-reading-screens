import 'package:flutter/material.dart';

class MemorizationConfirmationDialog extends StatelessWidget {
  final int surahNumber;
  final String surahName;
  final Function() onConfirm;

  const MemorizationConfirmationDialog({
    Key? key,
    required this.surahNumber,
    required this.surahName,
    required this.onConfirm,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        backgroundColor: isDarkMode ? Colors.grey[850] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.0),
        ),
        title: Column(
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 48,
              color: isDarkMode ? Colors.blue[200] : Colors.blue[700],
            ),
            const SizedBox(height: 16),
            Text(
              'هل أنت متأكد من حفظك للسورة؟',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: Text(
          'سوف يتم اختبار حفظك لسورة $surahName من خلال ألعاب تفاعلية ممتعة. هل أنت مستعد للبدء؟',
          style: TextStyle(
            fontSize: 16,
            color: isDarkMode ? Colors.white70 : Colors.black54,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: isDarkMode ? Colors.grey[700] : Colors.grey[200],
                  ),
                  child: const Text(
                    'لاحقاً',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'نعم، ابدأ الاختبار',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        titlePadding: const EdgeInsets.only(top: 24, right: 24, left: 24, bottom: 8),
      ),
    );
  }

  static Future<bool?> show(
    BuildContext context, {
    required int surahNumber,
    required String surahName,
    required Function() onConfirm,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => MemorizationConfirmationDialog(
        surahNumber: surahNumber,
        surahName: surahName,
        onConfirm: onConfirm,
      ),
    );
  }
}
