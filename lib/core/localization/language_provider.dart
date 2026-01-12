import 'package:flutter/material.dart';

class LanguageProvider extends ChangeNotifier {
  String _languageCode = 'ja';

  String get languageCode => _languageCode;

  void setLanguage(String code) {
    _languageCode = code;
    notifyListeners();
  }
}
