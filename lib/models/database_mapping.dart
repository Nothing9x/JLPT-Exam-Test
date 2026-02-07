/// Maps language codes to their corresponding database file names
class DatabaseMapping {
  /// Map of language code to database file name
  static const Map<String, String> languageToDatabase = {
    'vn': 'javn_mytest.db',
    'en': 'jaen_mytest.db',
    'es': 'jaes_mytest.db',
    'es_auto': 'jaes_mytest.db',
    'fr': 'jafr_mytest.db',
    'fr_auto': 'jafr_mytest.db',
    'cn': 'jacn_mytest.db',
    'cn_auto': 'jacn_mytest.db',
    'tw': 'jatw_mytest.db',
    'tw_auto': 'jatw_mytest.db',
    'ru': 'jaru_mytest.db',
    'ru_auto': 'jaru_mytest.db',
    'ko': 'jako_mytest.db',
    'ko_auto': 'jako_mytest.db',
    'my': 'jamy_mytest.db',
    'my_auto': 'jamy_mytest.db',
    'pt': 'japt_mytest.db',
    'pt_auto': 'japt_mytest.db',
    'de': 'jade_mytest.db',
    'de_auto': 'jade_mytest.db',
  };

  /// Get database file name for a given language code
  /// Defaults to English if language not found
  static String getDatabaseName(String languageCode) {
    return languageToDatabase[languageCode] ?? 'jaen_mytest.db';
  }

  /// Map JLPT level ID to database level value for kanji/vocabulary
  /// kanji/javi tables use integer levels: 1=N1, 2=N2, 3=N3, 4=N4, 5=N5
  static int getNumericLevel(String levelId) {
    switch (levelId) {
      case 'n1':
        return 1;
      case 'n2':
        return 2;
      case 'n3':
        return 3;
      case 'n4':
        return 4;
      case 'n5':
        return 5;
      case 'beginner':
        return 5; // Map beginner to N5
      default:
        return 5;
    }
  }

  /// Map JLPT level ID to database level value for grammar
  /// grammar table uses string levels: 'N1', 'N2', 'N3', 'N4', 'N5', 'Basic'
  static String getGrammarLevel(String levelId) {
    switch (levelId) {
      case 'n1':
        return 'N1';
      case 'n2':
        return 'N2';
      case 'n3':
        return 'N3';
      case 'n4':
        return 'N4';
      case 'n5':
        return 'N5';
      case 'beginner':
        return 'Basic';
      default:
        return 'N5';
    }
  }
}
