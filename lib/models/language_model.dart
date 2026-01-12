import 'dart:ui';

class LanguageModel {
  final String code;
  final String name;
  final String nativeName;
  final String flagEmoji;
  final List<String> localeCodes;

  const LanguageModel({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flagEmoji,
    required this.localeCodes,
  });

  static const List<LanguageModel> supportedLanguages = [
    LanguageModel(
      code: 'ja',
      name: 'Japanese',
      nativeName: '日本語',
      flagEmoji: '🇯🇵',
      localeCodes: ['ja'],
    ),
    LanguageModel(
      code: 'en',
      name: 'English',
      nativeName: 'English',
      flagEmoji: '🇺🇸',
      localeCodes: ['en'],
    ),
    LanguageModel(
      code: 'vn',
      name: 'Vietnamese',
      nativeName: 'Tiếng Việt',
      flagEmoji: '🇻🇳',
      localeCodes: ['vi'],
    ),
    LanguageModel(
      code: 'es_auto',
      name: 'Spanish',
      nativeName: 'Español',
      flagEmoji: '🇪🇸',
      localeCodes: ['es'],
    ),
    LanguageModel(
      code: 'fr_auto',
      name: 'French',
      nativeName: 'Français',
      flagEmoji: '🇫🇷',
      localeCodes: ['fr'],
    ),
    LanguageModel(
      code: 'cn_auto',
      name: 'Chinese Simplified',
      nativeName: '简体中文',
      flagEmoji: '🇨🇳',
      localeCodes: ['zh', 'zh_Hans'],
    ),
    LanguageModel(
      code: 'tw_auto',
      name: 'Chinese Traditional',
      nativeName: '繁體中文',
      flagEmoji: '🇹🇼',
      localeCodes: ['zh_Hant', 'zh_TW', 'zh_HK'],
    ),
    LanguageModel(
      code: 'ru_auto',
      name: 'Russian',
      nativeName: 'Русский',
      flagEmoji: '🇷🇺',
      localeCodes: ['ru'],
    ),
    LanguageModel(
      code: 'id_auto',
      name: 'Indonesian',
      nativeName: 'Bahasa Indonesia',
      flagEmoji: '🇮🇩',
      localeCodes: ['id'],
    ),
    LanguageModel(
      code: 'ko_auto',
      name: 'Korean',
      nativeName: '한국어',
      flagEmoji: '🇰🇷',
      localeCodes: ['ko'],
    ),
    LanguageModel(
      code: 'my_auto',
      name: 'Malay',
      nativeName: 'Bahasa Melayu',
      flagEmoji: '🇲🇾',
      localeCodes: ['ms'],
    ),
    LanguageModel(
      code: 'pt_auto',
      name: 'Portuguese',
      nativeName: 'Português',
      flagEmoji: '🇵🇹',
      localeCodes: ['pt'],
    ),
    LanguageModel(
      code: 'cn',
      name: 'Chinese',
      nativeName: '中文',
      flagEmoji: '🇨🇳',
      localeCodes: [],
    ),
  ];

  /// Get sorted languages with device locale at position 2 (after Japanese)
  static List<LanguageModel> getSortedLanguages(Locale deviceLocale) {
    final languages = List<LanguageModel>.from(supportedLanguages);
    final deviceLangCode = deviceLocale.languageCode;
    final deviceScript = deviceLocale.scriptCode;
    final deviceCountry = deviceLocale.countryCode;

    // Find matching language for device locale (excluding Japanese at index 0)
    int matchIndex = -1;
    for (int i = 1; i < languages.length; i++) {
      final lang = languages[i];
      for (final localeCode in lang.localeCodes) {
        if (localeCode == deviceLangCode ||
            localeCode == '${deviceLangCode}_$deviceScript' ||
            localeCode == '${deviceLangCode}_$deviceCountry') {
          matchIndex = i;
          break;
        }
      }
      if (matchIndex != -1) break;
    }

    // If found a match and it's not already at position 1, move it there
    if (matchIndex > 1) {
      final matchedLang = languages.removeAt(matchIndex);
      languages.insert(1, matchedLang);
    }

    return languages;
  }
}
