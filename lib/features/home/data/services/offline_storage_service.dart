import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/offline_data_models.dart';

/// Service for storing and retrieving offline data
class OfflineStorageService {
  static const String _downloadProgressKey = 'offline_download_progress';
  static const String _catalogKey = 'offline_catalog';

  // ==================== Directory Management ====================

  /// Get the base directory for offline data storage
  Future<Directory> get _offlineDataDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final offlineDir = Directory('${appDir.path}/offline_data');
    if (!await offlineDir.exists()) {
      await offlineDir.create(recursive: true);
    }
    return offlineDir;
  }

  /// Get directory for media files (audio/images)
  Future<Directory> get _mediaDir async {
    final baseDir = await _offlineDataDir;
    final mediaDir = Directory('${baseDir.path}/media');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    return mediaDir;
  }

  /// Get directory for exam data files
  Future<Directory> get _examDataDir async {
    final baseDir = await _offlineDataDir;
    final examDir = Directory('${baseDir.path}/exams');
    if (!await examDir.exists()) {
      await examDir.create(recursive: true);
    }
    return examDir;
  }

  /// Get directory for question data files
  Future<Directory> get _questionDataDir async {
    final baseDir = await _offlineDataDir;
    final questionDir = Directory('${baseDir.path}/questions');
    if (!await questionDir.exists()) {
      await questionDir.create(recursive: true);
    }
    return questionDir;
  }

  // ==================== Catalog Storage ====================

  /// Save download catalog
  Future<void> saveCatalog(DownloadCatalog catalog) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode({
      'version': catalog.version,
      'generatedAt': catalog.generatedAt,
      'examZips': catalog.examPacks.map((e) => {
            'level': e.level,
            'category': e.category,
            'filename': e.filename,
            'totalExams': e.totalExams,
            'totalQuestions': e.totalQuestions,
            'totalAudioFiles': e.totalAudioFiles,
            'totalImageFiles': e.totalImageFiles,
            'estimatedSizeBytes': e.estimatedSizeBytes,
            'estimatedSizeMB': e.estimatedSizeMB,
          }).toList(),
      'questionZips': catalog.questionPacks.map((e) => {
            'level': e.level,
            'category': e.category,
            'filename': e.filename,
            'totalQuestions': e.totalQuestions,
            'totalAudioFiles': e.totalAudioFiles,
            'totalImageFiles': e.totalImageFiles,
            'estimatedSizeBytes': e.estimatedSizeBytes,
            'estimatedSizeMB': e.estimatedSizeMB,
          }).toList(),
    });
    await prefs.setString(_catalogKey, json);
  }

  /// Get cached catalog
  Future<DownloadCatalog?> getCatalog() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_catalogKey);
    if (json == null) return null;
    try {
      return DownloadCatalog.fromJson(jsonDecode(json));
    } catch (e) {
      debugPrint('Error loading catalog: $e');
      return null;
    }
  }

  // ==================== Exam Data Storage ====================

  /// Save exam data for a level
  Future<void> saveExamData(int level, ExamDownloadData data) async {
    try {
      final dir = await _examDataDir;
      final file = File('${dir.path}/level_$level.json');
      await file.writeAsString(jsonEncode(data.toJson()));
      debugPrint('Saved exam data for level $level to ${file.path}');
    } catch (e) {
      debugPrint('Error saving exam data: $e');
      rethrow;
    }
  }

  /// Load exam data for a level
  Future<ExamDownloadData?> getExamData(int level) async {
    try {
      final dir = await _examDataDir;
      final file = File('${dir.path}/level_$level.json');
      if (!await file.exists()) return null;
      
      final json = await file.readAsString();
      return ExamDownloadData.fromJson(jsonDecode(json));
    } catch (e) {
      debugPrint('Error loading exam data for level $level: $e');
      return null;
    }
  }

  /// Check if exam data exists for a level
  Future<bool> hasExamData(int level) async {
    final dir = await _examDataDir;
    final file = File('${dir.path}/level_$level.json');
    return file.exists();
  }

  /// Delete exam data for a level
  Future<void> deleteExamData(int level) async {
    try {
      final dir = await _examDataDir;
      final file = File('${dir.path}/level_$level.json');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting exam data: $e');
    }
  }

  // ==================== Question Data Storage ====================

  /// Save question pack data
  Future<void> saveQuestionData(
    String category,
    int? level,
    QuestionPackDownloadData data,
  ) async {
    try {
      final dir = await _questionDataDir;
      final filename = level != null
          ? '${category.toLowerCase()}_level_$level.json'
          : '${category.toLowerCase()}_all.json';
      final file = File('${dir.path}/$filename');
      await file.writeAsString(jsonEncode(data.toJson()));
      debugPrint('Saved question data to ${file.path}');
    } catch (e) {
      debugPrint('Error saving question data: $e');
      rethrow;
    }
  }

  /// Load question pack data
  Future<QuestionPackDownloadData?> getQuestionData(
    String category,
    int? level,
  ) async {
    try {
      final dir = await _questionDataDir;
      final filename = level != null
          ? '${category.toLowerCase()}_level_$level.json'
          : '${category.toLowerCase()}_all.json';
      final file = File('${dir.path}/$filename');
      
      if (!await file.exists()) return null;
      
      final json = await file.readAsString();
      return QuestionPackDownloadData.fromJson(jsonDecode(json));
    } catch (e) {
      debugPrint('Error loading question data: $e');
      return null;
    }
  }

  /// Check if question data exists
  Future<bool> hasQuestionData(String category, int? level) async {
    final dir = await _questionDataDir;
    final filename = level != null
        ? '${category.toLowerCase()}_level_$level.json'
        : '${category.toLowerCase()}_all.json';
    final file = File('${dir.path}/$filename');
    return file.exists();
  }

  /// Delete question data
  Future<void> deleteQuestionData(String category, int? level) async {
    try {
      final dir = await _questionDataDir;
      final filename = level != null
          ? '${category.toLowerCase()}_level_$level.json'
          : '${category.toLowerCase()}_all.json';
      final file = File('${dir.path}/$filename');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting question data: $e');
    }
  }

  // ==================== Media File Storage ====================

  /// Save a media file (audio or image)
  Future<void> saveMediaFile(String relativePath, List<int> bytes) async {
    try {
      final dir = await _mediaDir;
      // Preserve directory structure from relative path
      final file = File('${dir.path}/$relativePath');
      final parentDir = file.parent;
      if (!await parentDir.exists()) {
        await parentDir.create(recursive: true);
      }
      await file.writeAsBytes(bytes);
    } catch (e) {
      debugPrint('Error saving media file $relativePath: $e');
      rethrow;
    }
  }

  /// Get local path for a media file
  Future<String?> getMediaFilePath(String relativePath) async {
    try {
      final dir = await _mediaDir;
      final file = File('${dir.path}/$relativePath');
      if (await file.exists()) {
        return file.path;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting media file path: $e');
      return null;
    }
  }

  /// Check if media file exists locally
  Future<bool> hasMediaFile(String relativePath) async {
    final dir = await _mediaDir;
    final file = File('${dir.path}/$relativePath');
    return file.exists();
  }

  /// Delete a media file
  Future<void> deleteMediaFile(String relativePath) async {
    try {
      final dir = await _mediaDir;
      final file = File('${dir.path}/$relativePath');
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('Error deleting media file: $e');
    }
  }

  /// Delete all media files for a level
  Future<void> deleteMediaFilesForLevel(int level) async {
    try {
      final dir = await _mediaDir;
      // Media files are typically stored in folders named by level
      final levelDir = Directory('${dir.path}/data/audio/$level');
      if (await levelDir.exists()) {
        await levelDir.delete(recursive: true);
      }
      final imageDir = Directory('${dir.path}/data/images/$level');
      if (await imageDir.exists()) {
        await imageDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('Error deleting media files for level $level: $e');
    }
  }

  // ==================== Download Progress Storage ====================

  /// Save download progress for all items
  Future<void> saveAllDownloadProgress(List<DownloadProgress> progressList) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(progressList.map((p) => p.toJson()).toList());
    await prefs.setString(_downloadProgressKey, json);
  }

  /// Load all download progress
  Future<List<DownloadProgress>> getAllDownloadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_downloadProgressKey);
    if (json == null) return [];
    
    try {
      final list = jsonDecode(json) as List;
      return list.map((e) => DownloadProgress.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error loading download progress: $e');
      return [];
    }
  }

  /// Update progress for a specific exam level
  Future<void> updateExamProgress(int level, DownloadProgress progress) async {
    final allProgress = await getAllDownloadProgress();
    final index = allProgress.indexWhere(
      (p) => p.level == level && p.category == null,
    );
    
    if (index >= 0) {
      allProgress[index] = progress;
    } else {
      allProgress.add(progress);
    }
    
    await saveAllDownloadProgress(allProgress);
  }

  /// Update progress for a specific question category
  Future<void> updateQuestionProgress(
    String category,
    int? level,
    DownloadProgress progress,
  ) async {
    final allProgress = await getAllDownloadProgress();
    final index = allProgress.indexWhere(
      (p) => p.category == category && p.level == (level ?? 0),
    );
    
    if (index >= 0) {
      allProgress[index] = progress;
    } else {
      allProgress.add(progress);
    }
    
    await saveAllDownloadProgress(allProgress);
  }

  /// Get progress for a specific exam level
  Future<DownloadProgress?> getExamProgress(int level) async {
    final allProgress = await getAllDownloadProgress();
    try {
      return allProgress.firstWhere(
        (p) => p.level == level && p.category == null,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get progress for a specific question category
  Future<DownloadProgress?> getQuestionProgress(String category, int? level) async {
    final allProgress = await getAllDownloadProgress();
    try {
      return allProgress.firstWhere(
        (p) => p.category == category && p.level == (level ?? 0),
      );
    } catch (_) {
      return null;
    }
  }

  // ==================== Storage Management ====================

  /// Get total storage used by offline data
  Future<int> getTotalStorageUsed() async {
    int totalSize = 0;
    
    try {
      final offlineDir = await _offlineDataDir;
      await for (final entity in offlineDir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } catch (e) {
      debugPrint('Error calculating storage: $e');
    }
    
    return totalSize;
  }

  /// Format storage size for display
  String formatStorageSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  /// Clear all offline data
  Future<void> clearAllOfflineData() async {
    try {
      // Clear file storage
      final offlineDir = await _offlineDataDir;
      if (await offlineDir.exists()) {
        await offlineDir.delete(recursive: true);
      }
      
      // Clear SharedPreferences data
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_downloadProgressKey);
      await prefs.remove(_catalogKey);
      
      debugPrint('All offline data cleared');
    } catch (e) {
      debugPrint('Error clearing offline data: $e');
      rethrow;
    }
  }

  /// Clear offline data for a specific level
  Future<void> clearLevelData(int level) async {
    await deleteExamData(level);
    await deleteMediaFilesForLevel(level);
    
    // Update progress to not downloaded
    await updateExamProgress(
      level,
      DownloadProgress(level: level, status: DownloadStatus.notDownloaded),
    );
  }
}
