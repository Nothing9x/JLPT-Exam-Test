/// Represents a lesson containing a subset of items
class LessonModel<T> {
  final int lessonNumber;
  final List<T> items;
  final bool isLocked;

  const LessonModel({
    required this.lessonNumber,
    required this.items,
    this.isLocked = true,
  });

  /// Get the first item for display (e.g., showing preview kanji)
  T? get firstItem => items.isNotEmpty ? items.first : null;

  /// Get the count of items in this lesson
  int get itemCount => items.length;
}

