import 'dart:convert';
import 'package:flutter/services.dart';
import 'exam_service.dart';

class ExamTypeInfo {
  final int type;
  final String name;
  final String nameVn;

  ExamTypeInfo({
    required this.type,
    required this.name,
    required this.nameVn,
  });

  factory ExamTypeInfo.fromJson(Map<String, dynamic> json) {
    return ExamTypeInfo(
      type: json['type'] ?? 0,
      name: json['name'] ?? '',
      nameVn: json['nameVn'] ?? '',
    );
  }
}

class ExamCatalogService {
  static const String _catalogPath = 'assets/external_exam_catalog.json';

  // Cache for the loaded catalog
  static Map<String, dynamic>? _cachedCatalog;
  static List<ExamTypeInfo>? _cachedExamTypes;

  // Exam type mappings
  static const Map<int, String> examTypeNames = {
    0: 'Full Test',
    1: 'Mini Test',
    2: 'NAT Test',
    3: 'Skill Test',
    4: 'Official Exam',
    5: 'Official Skill Exam',
    6: 'Prediction Test',
  };

  /// Load the exam catalog from assets
  static Future<void> loadCatalog() async {
    if (_cachedCatalog != null) return;

    final String jsonString = await rootBundle.loadString(_catalogPath);
    _cachedCatalog = json.decode(jsonString);

    // Load exam types info
    if (_cachedCatalog!['types'] != null) {
      final List<dynamic> typesJson = _cachedCatalog!['types'];
      _cachedExamTypes = typesJson.map((t) => ExamTypeInfo.fromJson(t)).toList();
    }
  }

  /// Get all exams for a specific level and exam type
  static Future<List<ExamModel>> getExamsByLevelAndType({
    required int level,
    int? examType,
  }) async {
    await loadCatalog();

    if (_cachedCatalog == null || _cachedCatalog!['exams'] == null) {
      return [];
    }

    final List<dynamic> examsJson = _cachedCatalog!['exams'];
    final List<ExamModel> allExams = examsJson
        .map((examJson) => ExamModel.fromJson(examJson))
        .toList();

    // Filter by level
    List<ExamModel> filtered = allExams
        .where((exam) => exam.level == level)
        .toList();

    // Filter by exam type if specified
    if (examType != null) {
      filtered = filtered
          .where((exam) => exam.examType == examType)
          .toList();
    }

    return filtered;
  }

  /// Get exam types available for a specific level
  static Future<List<int>> getExamTypesForLevel(int level) async {
    await loadCatalog();

    if (_cachedCatalog == null || _cachedCatalog!['levels'] == null) {
      return [];
    }

    final List<dynamic> levelsJson = _cachedCatalog!['levels'];
    final levelData = levelsJson.firstWhere(
      (l) => l['level'] == level,
      orElse: () => null,
    );

    if (levelData == null || levelData['types'] == null) {
      return [];
    }

    final List<dynamic> typesJson = levelData['types'];
    return typesJson.map<int>((t) => t['type'] as int).toList();
  }

  /// Get exam type display name
  static String getExamTypeName(int examType) {
    return examTypeNames[examType] ?? 'Unknown';
  }

  /// Get all exam type info
  static Future<List<ExamTypeInfo>> getExamTypesInfo() async {
    await loadCatalog();
    return _cachedExamTypes ?? [];
  }

  /// Clear cache (useful for testing or refreshing)
  static void clearCache() {
    _cachedCatalog = null;
    _cachedExamTypes = null;
  }
}
