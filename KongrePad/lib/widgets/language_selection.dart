import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageSelectionWidget extends StatelessWidget {
  final Function(Locale) onLanguageChanged;

  const LanguageSelectionWidget({Key? key, required this.onLanguageChanged})
      : super(key: key);

  Future<void> _changeLanguage(Locale locale) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('languageCode', locale.languageCode);
    onLanguageChanged(locale);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton(
          onPressed: () => _changeLanguage(const Locale('en')),
          child: const Text('English'),
        ),
        const SizedBox(width: 20),
        ElevatedButton(
          onPressed: () => _changeLanguage(const Locale('tr')),
          child: const Text('Türkçe'),
        ),
      ],
    );
  }
}
