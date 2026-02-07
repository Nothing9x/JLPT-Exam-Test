import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import '../../models/database_mapping.dart';
import '../../models/kanji_model.dart';
import '../../models/vocabulary_model.dart';
import '../../models/grammar_model.dart';
import '../../models/lesson_model.dart';

/// Service for loading data from SQLite database
class TheoryDatabaseService {
  static const int itemsPerLesson = 20;

  Database? _database;
  String? _currentDbName;

  /// Initialize database for a given language
  Future<void> initialize(String languageCode) async {
    final dbName = DatabaseMapping.getDatabaseName(languageCode);
    debugPrint('TheoryDatabaseService: Initializing database for language=$languageCode, dbName=$dbName');

    // If already initialized with same database, skip
    if (_database != null && _currentDbName == dbName) {
      debugPrint('TheoryDatabaseService: Database already initialized');
      return;
    }

    // Close existing database if different
    if (_database != null) {
      await _database!.close();
    }

    _database = await _openDatabase(dbName);
    _currentDbName = dbName;
    debugPrint('TheoryDatabaseService: Database opened successfully');
  }

  /// Open or copy database from assets
  Future<Database> _openDatabase(String dbName) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, dbName);
    debugPrint('TheoryDatabaseService: Database path=$path');

    // Check if database exists
    final exists = await databaseExists(path);
    debugPrint('TheoryDatabaseService: Database exists=$exists');

    if (!exists) {
      // Copy from assets
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copy database from assets
      debugPrint('TheoryDatabaseService: Copying database from assets/db/$dbName');
      final data = await rootBundle.load('assets/db/$dbName');
      final bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );
      await File(path).writeAsBytes(bytes, flush: true);
      debugPrint('TheoryDatabaseService: Database copied successfully');
    }

    // Open database
    return await openDatabase(path, readOnly: true);
  }

  /// Load all kanji for a specific level and organize into lessons
  Future<List<LessonModel<KanjiModel>>> loadKanjiLessons(String levelId) async {
    if (_database == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }

    final numericLevel = DatabaseMapping.getNumericLevel(levelId);
    final results = await _database!.query(
      'kanji',
      where: 'level = ?',
      whereArgs: [numericLevel],
      orderBy: 'id ASC',
    );

    final allKanji = results.map((row) => KanjiModel.fromMap(row)).toList();
    return _splitIntoLessons(allKanji);
  }

  /// Load all vocabulary for a specific level and organize into lessons
  Future<List<LessonModel<VocabularyModel>>> loadVocabularyLessons(
    String levelId,
  ) async {
    if (_database == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }

    final numericLevel = DatabaseMapping.getNumericLevel(levelId);
    final results = await _database!.query(
      'javi',
      where: 'level = ?',
      whereArgs: [numericLevel],
      orderBy: 'id ASC',
    );

    final allVocab =
        results.map((row) => VocabularyModel.fromMap(row)).toList();
    return _splitIntoLessons(allVocab);
  }

  /// Load all grammar for a specific level and organize into lessons
  Future<List<LessonModel<GrammarModel>>> loadGrammarLessons(
    String levelId,
  ) async {
    if (_database == null) {
      throw Exception('Database not initialized. Call initialize() first.');
    }

    final grammarLevel = DatabaseMapping.getGrammarLevel(levelId);
    final results = await _database!.query(
      'grammar',
      where: 'level = ?',
      whereArgs: [grammarLevel],
      orderBy: 'id ASC',
    );

    final allGrammar = results.map((row) => GrammarModel.fromMap(row)).toList();
    return _splitIntoLessons(allGrammar);
  }

  /// Split items into lessons of [itemsPerLesson] items each
  List<LessonModel<T>> _splitIntoLessons<T>(List<T> items) {
    final lessons = <LessonModel<T>>[];

    for (int i = 0; i < items.length; i += itemsPerLesson) {
      final end = (i + itemsPerLesson < items.length)
          ? i + itemsPerLesson
          : items.length;
      final lessonItems = items.sublist(i, end);

      lessons.add(LessonModel<T>(
        lessonNumber: (i ~/ itemsPerLesson) + 1,
        items: lessonItems,
        isLocked: lessons.isNotEmpty, // First lesson is unlocked
      ));
    }

    return lessons;
  }

  /// Get total count of items for a category and level
  Future<int> getKanjiCount(String levelId) async {
    if (_database == null) return 0;
    final numericLevel = DatabaseMapping.getNumericLevel(levelId);
    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM kanji WHERE level = ?',
      [numericLevel],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getVocabularyCount(String levelId) async {
    if (_database == null) return 0;
    final numericLevel = DatabaseMapping.getNumericLevel(levelId);
    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM javi WHERE level = ?',
      [numericLevel],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> getGrammarCount(String levelId) async {
    if (_database == null) return 0;
    final grammarLevel = DatabaseMapping.getGrammarLevel(levelId);
    final result = await _database!.rawQuery(
      'SELECT COUNT(*) as count FROM grammar WHERE level = ?',
      [grammarLevel],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  /// Close database connection
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      _currentDbName = null;
    }
  }
}
