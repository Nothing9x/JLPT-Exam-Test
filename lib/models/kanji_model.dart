import 'dart:convert';

/// Model for Kanji data from the database
class KanjiModel {
  final int id;
  final String kanji;
  final String meaning;
  final int level;
  final String onReading;
  final String kunReading;
  final String? svg;
  final String? detail;
  final String? shortMeaning;
  final int? frequency;
  final String? components;
  final int? strokeCount;
  final String? componentDetail;
  final List<KanjiExample> examples;
  final bool favorite;
  final bool remember;

  const KanjiModel({
    required this.id,
    required this.kanji,
    required this.meaning,
    required this.level,
    required this.onReading,
    required this.kunReading,
    this.svg,
    this.detail,
    this.shortMeaning,
    this.frequency,
    this.components,
    this.strokeCount,
    this.componentDetail,
    this.examples = const [],
    this.favorite = false,
    this.remember = false,
  });

  factory KanjiModel.fromMap(Map<String, dynamic> map) {
    List<KanjiExample> parseExamples(dynamic examplesData) {
      if (examplesData == null) return [];
      if (examplesData is! String) return [];
      if (examplesData.isEmpty) return [];
      try {
        final List<dynamic> decoded = json.decode(examplesData);
        return decoded.map((e) => KanjiExample.fromMap(e)).toList();
      } catch (e) {
        return [];
      }
    }

    return KanjiModel(
      id: int.tryParse(map['id']?.toString() ?? '0') ?? 0,
      kanji: map['kanji']?.toString() ?? '',
      meaning: map['mean']?.toString() ?? '',
      level: int.tryParse(map['level']?.toString() ?? '5') ?? 5,
      onReading: map['on']?.toString() ?? '',
      kunReading: map['kun']?.toString() ?? '',
      svg: map['img']?.toString(),
      detail: map['detail']?.toString(),
      shortMeaning: map['short']?.toString(),
      frequency: int.tryParse(map['freq']?.toString() ?? ''),
      components: map['comp']?.toString(),
      strokeCount: int.tryParse(map['stroke_count']?.toString() ?? ''),
      componentDetail: map['compDetail']?.toString(),
      examples: parseExamples(map['examples']),
      favorite: (map['favorite'] is int) ? map['favorite'] == 1 : false,
      remember: (map['remember'] is int) ? map['remember'] == 1 : false,
    );
  }
}

class KanjiExample {
  final String word;
  final String? phonetic;
  final String? meaning;
  final String? hanViet;

  const KanjiExample({
    required this.word,
    this.phonetic,
    this.meaning,
    this.hanViet,
  });

  factory KanjiExample.fromMap(Map<String, dynamic> map) {
    return KanjiExample(
      word: map['w']?.toString() ?? '',
      phonetic: map['p']?.toString(),
      meaning: map['m']?.toString(),
      hanViet: map['h']?.toString(),
    );
  }
}
