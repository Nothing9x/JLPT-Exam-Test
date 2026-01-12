class JlptLevelModel {
  final String id;
  final String titleKey;
  final String descKey;
  final String emoji;
  final int colorValue;

  const JlptLevelModel({
    required this.id,
    required this.titleKey,
    required this.descKey,
    required this.emoji,
    required this.colorValue,
  });

  static const List<JlptLevelModel> levels = [
    JlptLevelModel(
      id: 'beginner',
      titleKey: 'beginner',
      descKey: 'beginner_desc',
      emoji: '🌰',
      colorValue: 0xFFFFE0B2, // Orange 100
    ),
    JlptLevelModel(
      id: 'n5',
      titleKey: 'JLPT N5',
      descKey: 'n5_desc',
      emoji: '🌱',
      colorValue: 0xFFC8E6C9, // Green 100
    ),
    JlptLevelModel(
      id: 'n4',
      titleKey: 'JLPT N4',
      descKey: 'n4_desc',
      emoji: '🪴',
      colorValue: 0xFFA5D6A7, // Green 200
    ),
    JlptLevelModel(
      id: 'n3',
      titleKey: 'JLPT N3',
      descKey: 'n3_desc',
      emoji: '🌻',
      colorValue: 0xFF80CBC4, // Teal 200
    ),
    JlptLevelModel(
      id: 'n2',
      titleKey: 'JLPT N2',
      descKey: 'n2_desc',
      emoji: '🌳',
      colorValue: 0xFF80DEEA, // Cyan 200
    ),
    JlptLevelModel(
      id: 'n1',
      titleKey: 'JLPT N1',
      descKey: 'n1_desc',
      emoji: '🌲',
      colorValue: 0xFF90CAF9, // Blue 200
    ),
  ];
}
