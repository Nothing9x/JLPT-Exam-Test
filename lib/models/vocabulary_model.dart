import 'dart:convert';

/// Model for Vocabulary (javi) data from the database
class VocabularyModel {
  final int id;
  final String word;
  final String? phonetic;
  final String shortMeaning;
  final String? meaning;
  final String? oppositeWord;
  final String? synsets;
  final List<String> relatedWords;
  final String? hanViet;
  final String? grid;
  final int level;
  final bool remember;

  const VocabularyModel({
    required this.id,
    required this.word,
    this.phonetic,
    required this.shortMeaning,
    this.meaning,
    this.oppositeWord,
    this.synsets,
    this.relatedWords = const [],
    this.hanViet,
    this.grid,
    required this.level,
    this.remember = false,
  });

  factory VocabularyModel.fromMap(Map<String, dynamic> map) {
    List<String> parseRelatedWords(dynamic relatedData) {
      if (relatedData == null) return [];
      // If it's an int or other non-string type, return empty
      if (relatedData is! String) return [];
      if (relatedData.isEmpty) return [];
      try {
        final decoded = json.decode(relatedData);
        if (decoded is Map && decoded.containsKey('word')) {
          return List<String>.from(decoded['word'] as List);
        }
        return [];
      } catch (e) {
        return [];
      }
    }

    return VocabularyModel(
      id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      word: map['word']?.toString() ?? '',
      phonetic: map['phonetic']?.toString(),
      shortMeaning: map['short_mean']?.toString() ?? '',
      meaning: map['mean']?.toString(),
      oppositeWord: map['opposite_word']?.toString(),
      synsets: map['synsets']?.toString(),
      relatedWords: parseRelatedWords(map['related_words']),
      hanViet: map['han']?.toString(),
      grid: map['grid']?.toString(),
      level: int.tryParse(map['level']?.toString() ?? '5') ?? 5,
      remember: (map['remember'] is int) ? map['remember'] == 1 : false,
    );
  }
}
