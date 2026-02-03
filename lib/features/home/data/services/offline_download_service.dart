import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/offline_data_models.dart';
import 'offline_storage_service.dart';

/// Service for downloading offline data from the API using ZIP files
/// Based on API documentation section 11 (ZIP Download APIs)
class OfflineDownloadService {
  final http.Client _client;
  final OfflineStorageService _storage;
  final String? token;

  // Stream controllers for progress updates
  final _progressController = StreamController<DownloadProgress>.broadcast();
  Stream<DownloadProgress> get progressStream => _progressController.stream;

  // Track active downloads
  final Map<String, bool> _activeDownloads = {};

  OfflineDownloadService({
    http.Client? client,
    OfflineStorageService? storage,
    this.token,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? OfflineStorageService();

  void dispose() {
    _progressController.close();
    _client.close();
  }

  /// Common headers for all requests (includes ngrok bypass)
  Map<String, String> get _headers => {
        if (token != null) 'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'ngrok-skip-browser-warning': 'true',
        'User-Agent': 'JLPT-Exam-App',
      };

  // ==================== Catalog ====================

  /// Fetch ZIP download catalog from API
  Future<DownloadCatalog> fetchCatalog() async {
    final url = '${ApiConstants.baseUrl}/download/zip/catalog';
    final stopwatch = Stopwatch()..start();

    try {
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('📥 FETCH ZIP CATALOG');
      debugPrint('═══════════════════════════════════════════════════════════');
      debugPrint('🌐 URL: $url');
      debugPrint('⏱️  Starting request...');

      final response = await _client
          .get(Uri.parse(url), headers: _headers)
          .timeout(const Duration(seconds: 30));

      stopwatch.stop();
      debugPrint('⏱️  Response received in ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('📊 Status Code: ${response.statusCode}');
      debugPrint('📦 Response Size: ${response.bodyBytes.length} bytes');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final catalog = DownloadCatalog.fromJson(data);
        await _storage.saveCatalog(catalog);
        debugPrint('✅ ZIP Catalog fetched successfully!');
        debugPrint('   📚 Exam ZIPs: ${catalog.examPacks.length}');
        debugPrint('   📝 Question ZIPs: ${catalog.questionPacks.length}');
        debugPrint('═══════════════════════════════════════════════════════════');
        return catalog;
      } else {
        debugPrint('❌ Server returned error status: ${response.statusCode}');
        debugPrint(
            '📄 Response Body: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
        throw Exception(
            'Failed to fetch catalog: ${response.statusCode} - ${response.reasonPhrase}');
      }
    } catch (e, stackTrace) {
      stopwatch.stop();
      debugPrint(
          '❌ ERROR fetching catalog after ${stopwatch.elapsedMilliseconds}ms');
      debugPrint('💥 Error Type: ${e.runtimeType}');
      debugPrint('💥 Error: $e');
      debugPrint('📍 Stack Trace: $stackTrace');

      // Try to return cached catalog
      final cached = await _storage.getCatalog();
      if (cached != null) {
        debugPrint('📦 Using cached catalog as fallback');
        return cached;
      }
      debugPrint('❌ No cached catalog available');
      rethrow;
    }
  }

  // ==================== Exam ZIP Download ====================

  /// Download and extract exam ZIP for a specific level
  Future<void> downloadExamsForLevel(int level) async {
    final downloadKey = 'exam_$level';
    if (_activeDownloads[downloadKey] == true) {
      debugPrint('⚠️ Download already in progress for level $level');
      return;
    }
    _activeDownloads[downloadKey] = true;
    final totalStopwatch = Stopwatch()..start();

    try {
      debugPrint('');
      debugPrint('╔═══════════════════════════════════════════════════════════');
      debugPrint('║ 📥 DOWNLOAD EXAM ZIP FOR LEVEL N$level');
      debugPrint('╠═══════════════════════════════════════════════════════════');
      debugPrint('║ ⏰ Started at: ${DateTime.now()}');
      debugPrint('╚═══════════════════════════════════════════════════════════');

      // Emit initial progress
      _emitProgress(level, null, DownloadStatus.downloading, 0.0, 0, 0);

      // Step 1: Get ZIP info first
      final infoUrl = '${ApiConstants.baseUrl}/download/zip/exams/level/$level/info';
      debugPrint('');
      debugPrint('📌 STEP 1: Get ZIP Info');
      debugPrint('🌐 URL: $infoUrl');

      final step1Stopwatch = Stopwatch()..start();
      late http.Response infoResponse;
      try {
        infoResponse = await _client
            .get(Uri.parse(infoUrl), headers: _headers)
            .timeout(const Duration(seconds: 60));
      } catch (e) {
        step1Stopwatch.stop();
        debugPrint('❌ STEP 1 FAILED after ${step1Stopwatch.elapsedMilliseconds}ms');
        debugPrint('💥 Error getting ZIP info: $e');
        rethrow;
      }
      step1Stopwatch.stop();
      debugPrint('⏱️  ZIP Info response in ${step1Stopwatch.elapsedMilliseconds}ms');

      if (infoResponse.statusCode != 200) {
        debugPrint('═══════════════════════════════════════════════════════════');
        debugPrint('🔥 SERVER ERROR - ZIP INFO');
        debugPrint('═══════════════════════════════════════════════════════════');
        debugPrint('📊 Status Code: ${infoResponse.statusCode}');
        debugPrint('📋 Status: ${infoResponse.reasonPhrase}');
        debugPrint('📋 Headers: ${infoResponse.headers}');
        debugPrint('📄 Response Body:');
        debugPrint(infoResponse.body);
        debugPrint('═══════════════════════════════════════════════════════════');
        throw Exception('Server error getting ZIP info: ${infoResponse.statusCode} - ${infoResponse.body}');
      }

      final zipInfo = jsonDecode(infoResponse.body);
      final estimatedSize = zipInfo['estimatedSizeBytes'] as int? ?? 0;
      debugPrint('✅ ZIP Info received:');
      debugPrint('   📦 Estimated size: ${(estimatedSize / 1024 / 1024).toStringAsFixed(2)} MB');
      debugPrint('   📚 Total exams: ${zipInfo['totalExams']}');
      debugPrint('   🎵 Audio files: ${zipInfo['totalAudioFiles']}');
      debugPrint('   🖼️  Image files: ${zipInfo['totalImageFiles']}');

      // Step 2: Download ZIP file with progress tracking
      final zipUrl = '${ApiConstants.baseUrl}/download/zip/exams/level/$level';
      debugPrint('');
      debugPrint('📌 STEP 2: Download ZIP File');
      debugPrint('🌐 URL: $zipUrl');

      final step2Stopwatch = Stopwatch()..start();

      // Use streaming to track progress
      final request = http.Request('GET', Uri.parse(zipUrl));
      request.headers.addAll(_headers);

      late http.StreamedResponse streamedResponse;
      try {
        streamedResponse = await _client.send(request).timeout(const Duration(minutes: 30));
      } catch (e) {
        step2Stopwatch.stop();
        debugPrint('❌ STEP 2 FAILED - Connection error after ${step2Stopwatch.elapsedMilliseconds}ms');
        debugPrint('💥 Error: $e');
        rethrow;
      }

      if (streamedResponse.statusCode != 200) {
        // Read response body for error details
        final errorBody = await streamedResponse.stream.bytesToString();
        debugPrint('═══════════════════════════════════════════════════════════');
        debugPrint('🔥 SERVER ERROR - ZIP DOWNLOAD');
        debugPrint('═══════════════════════════════════════════════════════════');
        debugPrint('📊 Status Code: ${streamedResponse.statusCode}');
        debugPrint('📋 Status: ${streamedResponse.reasonPhrase}');
        debugPrint('📋 Headers: ${streamedResponse.headers}');
        debugPrint('📄 Response Body:');
        debugPrint(errorBody);
        debugPrint('═══════════════════════════════════════════════════════════');
        throw Exception('Server error downloading ZIP: ${streamedResponse.statusCode} - $errorBody');
      }

      // Get temp directory and create ZIP file
      final tempDir = await getTemporaryDirectory();
      final zipFile = File('${tempDir.path}/exams_n$level.zip');
      final sink = zipFile.openWrite();

      int downloadedBytes = 0;
      final totalBytes = streamedResponse.contentLength ?? estimatedSize;

      await for (final chunk in streamedResponse.stream) {
        if (_activeDownloads[downloadKey] != true) {
          await sink.close();
          await zipFile.delete();
          debugPrint('⚠️ Download cancelled by user');
          return;
        }

        sink.add(chunk);
        downloadedBytes += chunk.length;

        // Update progress
        final progress = totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;
        _emitProgress(level, null, DownloadStatus.downloading, progress * 0.5, downloadedBytes, totalBytes);

        // Log progress every 10%
        if (totalBytes > 0 && (downloadedBytes * 10 ~/ totalBytes) != ((downloadedBytes - chunk.length) * 10 ~/ totalBytes)) {
          debugPrint('📥 Downloading: ${(progress * 100).toStringAsFixed(1)}% (${(downloadedBytes / 1024 / 1024).toStringAsFixed(2)} MB)');
        }
      }
      await sink.close();

      step2Stopwatch.stop();
      debugPrint('✅ ZIP downloaded in ${(step2Stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s');
      debugPrint('   📦 File size: ${(await zipFile.length()) / 1024 / 1024} MB');

      // Step 3: Extract ZIP file
      debugPrint('');
      debugPrint('📌 STEP 3: Extract ZIP File');
      final step3Stopwatch = Stopwatch()..start();

      _emitProgress(level, null, DownloadStatus.downloading, 0.5, 0, 0);

      final extractDir = await _getExamExtractDir(level);
      await _extractZipFile(zipFile, extractDir, level, null);

      step3Stopwatch.stop();
      debugPrint('✅ ZIP extracted in ${(step3Stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s');

      // Step 4: Parse and save exam data from JSON
      debugPrint('');
      debugPrint('📌 STEP 4: Parse Exam Data');

      final jsonFile = File('${extractDir.path}/exams_n$level.json');
      if (!await jsonFile.exists()) {
        throw Exception('Exam JSON file not found in ZIP');
      }

      final jsonContent = await jsonFile.readAsString();
      final examData = ExamDownloadData.fromJson(jsonDecode(jsonContent));
      await _storage.saveExamData(level, examData);
      debugPrint('✅ Saved ${examData.totalExams} exams, ${examData.totalQuestions} questions');

      // Step 5: Clean up temp ZIP file
      await zipFile.delete();
      debugPrint('🗑️ Cleaned up temp ZIP file');

      // Step 6: Mark as complete
      totalStopwatch.stop();

      final progress = DownloadProgress(
        level: level,
        status: DownloadStatus.downloaded,
        progress: 1.0,
        downloadedFiles: (zipInfo['totalAudioFiles'] ?? 0) + (zipInfo['totalImageFiles'] ?? 0),
        totalFiles: (zipInfo['totalAudioFiles'] ?? 0) + (zipInfo['totalImageFiles'] ?? 0),
        downloadedAt: DateTime.now(),
        version: examData.version,
      );
      await _storage.updateExamProgress(level, progress);
      _progressController.add(progress);

      debugPrint('');
      debugPrint('╔═══════════════════════════════════════════════════════════');
      debugPrint('║ ✅ DOWNLOAD & EXTRACT COMPLETE FOR LEVEL N$level');
      debugPrint('╠═══════════════════════════════════════════════════════════');
      debugPrint('║ ⏱️  Total time: ${(totalStopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s');
      debugPrint('║ 📚 Exams: ${examData.totalExams}');
      debugPrint('║ 📝 Questions: ${examData.totalQuestions}');
      debugPrint('╚═══════════════════════════════════════════════════════════');
      debugPrint('');
    } catch (e, stackTrace) {
      totalStopwatch.stop();
      debugPrint('');
      debugPrint('╔═══════════════════════════════════════════════════════════');
      debugPrint('║ ❌ DOWNLOAD FAILED FOR LEVEL N$level');
      debugPrint('╠═══════════════════════════════════════════════════════════');
      debugPrint('║ ⏱️  Failed after: ${(totalStopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s');
      debugPrint('║ 💥 Error Type: ${e.runtimeType}');
      debugPrint('║ 💥 Error: $e');
      debugPrint('╚═══════════════════════════════════════════════════════════');
      debugPrint('📍 Stack Trace: $stackTrace');

      _emitProgress(
        level,
        null,
        DownloadStatus.error,
        0.0,
        0,
        0,
        errorMessage: e.toString(),
      );
      rethrow;
    } finally {
      _activeDownloads.remove(downloadKey);
    }
  }

  /// Cancel download for a level
  void cancelExamDownload(int level) {
    _activeDownloads['exam_$level'] = false;
  }

  // ==================== Question Pack ZIP Download ====================

  /// Download and extract questions ZIP for a specific category and optional level
  Future<void> downloadQuestions({
    required String category,
    int? level,
  }) async {
    final downloadKey = 'question_${category}_${level ?? 'all'}';
    if (_activeDownloads[downloadKey] == true) {
      debugPrint('⚠️ Download already in progress for $category level $level');
      return;
    }
    _activeDownloads[downloadKey] = true;
    final totalStopwatch = Stopwatch()..start();

    try {
      debugPrint('');
      debugPrint('╔═══════════════════════════════════════════════════════════');
      debugPrint('║ 📥 DOWNLOAD QUESTION ZIP: $category ${level != null ? "N$level" : "(All)"}');
      debugPrint('╠═══════════════════════════════════════════════════════════');
      debugPrint('║ ⏰ Started at: ${DateTime.now()}');
      debugPrint('╚═══════════════════════════════════════════════════════════');

      // Emit initial progress
      _emitProgress(level ?? 0, category, DownloadStatus.downloading, 0.0, 0, 0);

      // Step 1: Get ZIP info first
      String infoUrl = '${ApiConstants.baseUrl}/download/zip/questions/category/$category/info';
      if (level != null) {
        infoUrl += '?level=$level';
      }
      debugPrint('');
      debugPrint('📌 STEP 1: Get ZIP Info');
      debugPrint('🌐 URL: $infoUrl');

      final step1Stopwatch = Stopwatch()..start();
      late http.Response infoResponse;
      try {
        infoResponse = await _client
            .get(Uri.parse(infoUrl), headers: _headers)
            .timeout(const Duration(seconds: 60));
      } catch (e) {
        step1Stopwatch.stop();
        debugPrint('❌ STEP 1 FAILED after ${step1Stopwatch.elapsedMilliseconds}ms');
        debugPrint('💥 Error getting ZIP info: $e');
        rethrow;
      }
      step1Stopwatch.stop();
      debugPrint('⏱️  ZIP Info response in ${step1Stopwatch.elapsedMilliseconds}ms');

      if (infoResponse.statusCode != 200) {
        debugPrint('═══════════════════════════════════════════════════════════');
        debugPrint('🔥 SERVER ERROR - ZIP INFO (QUESTIONS)');
        debugPrint('═══════════════════════════════════════════════════════════');
        debugPrint('📊 Status Code: ${infoResponse.statusCode}');
        debugPrint('📋 Status: ${infoResponse.reasonPhrase}');
        debugPrint('📋 Headers: ${infoResponse.headers}');
        debugPrint('📄 Response Body:');
        debugPrint(infoResponse.body);
        debugPrint('═══════════════════════════════════════════════════════════');
        throw Exception('Server error getting ZIP info: ${infoResponse.statusCode} - ${infoResponse.body}');
      }

      final zipInfo = jsonDecode(infoResponse.body);
      final estimatedSize = zipInfo['estimatedSizeBytes'] as int? ?? 0;
      debugPrint('✅ ZIP Info received:');
      debugPrint('   📦 Estimated size: ${(estimatedSize / 1024 / 1024).toStringAsFixed(2)} MB');
      debugPrint('   📝 Total questions: ${zipInfo['totalQuestions']}');
      debugPrint('   🎵 Audio files: ${zipInfo['totalAudioFiles']}');
      debugPrint('   🖼️  Image files: ${zipInfo['totalImageFiles']}');

      // Step 2: Download ZIP file with progress tracking
      String zipUrl = '${ApiConstants.baseUrl}/download/zip/questions/category/$category';
      if (level != null) {
        zipUrl += '?level=$level';
      }
      debugPrint('');
      debugPrint('📌 STEP 2: Download ZIP File');
      debugPrint('🌐 URL: $zipUrl');

      final step2Stopwatch = Stopwatch()..start();

      final request = http.Request('GET', Uri.parse(zipUrl));
      request.headers.addAll(_headers);

      late http.StreamedResponse streamedResponse;
      try {
        streamedResponse = await _client.send(request).timeout(const Duration(minutes: 30));
      } catch (e) {
        step2Stopwatch.stop();
        debugPrint('❌ STEP 2 FAILED - Connection error after ${step2Stopwatch.elapsedMilliseconds}ms');
        debugPrint('💥 Error: $e');
        rethrow;
      }

      if (streamedResponse.statusCode != 200) {
        // Read response body for error details
        final errorBody = await streamedResponse.stream.bytesToString();
        debugPrint('═══════════════════════════════════════════════════════════');
        debugPrint('🔥 SERVER ERROR - ZIP DOWNLOAD (QUESTIONS)');
        debugPrint('═══════════════════════════════════════════════════════════');
        debugPrint('📊 Status Code: ${streamedResponse.statusCode}');
        debugPrint('📋 Status: ${streamedResponse.reasonPhrase}');
        debugPrint('📋 Headers: ${streamedResponse.headers}');
        debugPrint('📄 Response Body:');
        debugPrint(errorBody);
        debugPrint('═══════════════════════════════════════════════════════════');
        throw Exception('Server error downloading ZIP: ${streamedResponse.statusCode} - $errorBody');
      }

      final tempDir = await getTemporaryDirectory();
      final filename = 'questions_${category.toLowerCase()}_${level != null ? "n$level" : "all"}.zip';
      final zipFile = File('${tempDir.path}/$filename');
      final sink = zipFile.openWrite();

      int downloadedBytes = 0;
      final totalBytes = streamedResponse.contentLength ?? estimatedSize;

      await for (final chunk in streamedResponse.stream) {
        if (_activeDownloads[downloadKey] != true) {
          await sink.close();
          await zipFile.delete();
          debugPrint('⚠️ Download cancelled by user');
          return;
        }

        sink.add(chunk);
        downloadedBytes += chunk.length;

        final progress = totalBytes > 0 ? downloadedBytes / totalBytes : 0.0;
        _emitProgress(level ?? 0, category, DownloadStatus.downloading, progress * 0.5, downloadedBytes, totalBytes);

        if (totalBytes > 0 && (downloadedBytes * 10 ~/ totalBytes) != ((downloadedBytes - chunk.length) * 10 ~/ totalBytes)) {
          debugPrint('📥 Downloading: ${(progress * 100).toStringAsFixed(1)}%');
        }
      }
      await sink.close();

      step2Stopwatch.stop();
      debugPrint('✅ ZIP downloaded in ${(step2Stopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s');

      // Step 3: Extract ZIP file
      debugPrint('');
      debugPrint('📌 STEP 3: Extract ZIP File');

      _emitProgress(level ?? 0, category, DownloadStatus.downloading, 0.5, 0, 0);

      final extractDir = await _getQuestionExtractDir(category, level);
      await _extractZipFile(zipFile, extractDir, level, category);

      debugPrint('✅ ZIP extracted');

      // Step 4: Parse and save question data from JSON
      debugPrint('');
      debugPrint('📌 STEP 4: Parse Question Data');

      final jsonFilename = 'questions_${category.toLowerCase()}_${level != null ? "n$level" : "all"}.json';
      final jsonFile = File('${extractDir.path}/$jsonFilename');
      String jsonContent;
      if (!await jsonFile.exists()) {
        // Try alternative names
        final altJsonFile = await _findJsonFile(extractDir);
        if (altJsonFile == null) {
          throw Exception('Question JSON file not found in ZIP');
        }
        jsonContent = await altJsonFile.readAsString();
        debugPrint('📄 Using alt JSON file: ${altJsonFile.path}');
      } else {
        jsonContent = await jsonFile.readAsString();
        debugPrint('📄 Using JSON file: ${jsonFile.path}');
      }

      // Debug: Print first 2000 chars of JSON to understand structure
      debugPrint('📋 JSON Preview (first 2000 chars):');
      debugPrint(jsonContent.length > 2000 ? jsonContent.substring(0, 2000) : jsonContent);

      final jsonData = jsonDecode(jsonContent);
      debugPrint('📋 JSON Root Type: ${jsonData.runtimeType}');
      if (jsonData is Map) {
        debugPrint('📋 JSON Root Keys: ${jsonData.keys.toList()}');
      } else if (jsonData is List) {
        debugPrint('📋 JSON is a List with ${jsonData.length} items');
        if (jsonData.isNotEmpty) {
          debugPrint('📋 First item type: ${jsonData.first.runtimeType}');
          if (jsonData.first is Map) {
            debugPrint('📋 First item keys: ${(jsonData.first as Map).keys.toList()}');
          }
        }
      }

      final questionData = QuestionPackDownloadData.fromJson(jsonData);
      await _storage.saveQuestionData(category, level, questionData);
      debugPrint('✅ Saved ${questionData.totalQuestions} questions');

      // Step 5: Clean up temp ZIP file
      await zipFile.delete();

      // Step 6: Mark as complete
      totalStopwatch.stop();

      final progress = DownloadProgress(
        level: level ?? 0,
        category: category,
        status: DownloadStatus.downloaded,
        progress: 1.0,
        downloadedFiles: (zipInfo['totalAudioFiles'] ?? 0) + (zipInfo['totalImageFiles'] ?? 0),
        totalFiles: (zipInfo['totalAudioFiles'] ?? 0) + (zipInfo['totalImageFiles'] ?? 0),
        downloadedAt: DateTime.now(),
        version: '1.0',
      );
      await _storage.updateQuestionProgress(category, level, progress);
      _progressController.add(progress);

      debugPrint('');
      debugPrint('╔═══════════════════════════════════════════════════════════');
      debugPrint('║ ✅ DOWNLOAD & EXTRACT COMPLETE: $category');
      debugPrint('╠═══════════════════════════════════════════════════════════');
      debugPrint('║ ⏱️  Total time: ${(totalStopwatch.elapsedMilliseconds / 1000).toStringAsFixed(2)}s');
      debugPrint('╚═══════════════════════════════════════════════════════════');
    } catch (e, stackTrace) {
      totalStopwatch.stop();
      debugPrint('');
      debugPrint('❌ DOWNLOAD FAILED: $category');
      debugPrint('💥 Error: $e');
      debugPrint('📍 Stack Trace: $stackTrace');

      _emitProgress(
        level ?? 0,
        category,
        DownloadStatus.error,
        0.0,
        0,
        0,
        errorMessage: e.toString(),
      );
      rethrow;
    } finally {
      _activeDownloads.remove(downloadKey);
    }
  }

  /// Cancel question download
  void cancelQuestionDownload(String category, int? level) {
    _activeDownloads['question_${category}_${level ?? 'all'}'] = false;
  }

  // ==================== ZIP Extraction ====================

  /// Get extraction directory for exam ZIP
  Future<Directory> _getExamExtractDir(int level) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final extractDir = Directory('${documentsDir.path}/offline_data/exams/n$level');
    if (!await extractDir.exists()) {
      await extractDir.create(recursive: true);
    }
    return extractDir;
  }

  /// Get extraction directory for question ZIP
  Future<Directory> _getQuestionExtractDir(String category, int? level) async {
    final documentsDir = await getApplicationDocumentsDirectory();
    final subDir = level != null ? '${category.toLowerCase()}_n$level' : category.toLowerCase();
    final extractDir = Directory('${documentsDir.path}/offline_data/questions/$subDir');
    if (!await extractDir.exists()) {
      await extractDir.create(recursive: true);
    }
    return extractDir;
  }

  /// Extract ZIP file to directory
  Future<void> _extractZipFile(File zipFile, Directory extractDir, int? level, String? category) async {
    debugPrint('📦 Reading ZIP file...');
    final bytes = await zipFile.readAsBytes();
    
    debugPrint('📦 Decoding ZIP archive...');
    final archive = ZipDecoder().decodeBytes(bytes);
    
    debugPrint('📦 Extracting ${archive.length} files...');
    
    int extractedCount = 0;
    final totalFiles = archive.length;
    
    for (final file in archive) {
      final filename = file.name;
      
      if (file.isFile) {
        final outputFile = File('${extractDir.path}/$filename');
        await outputFile.create(recursive: true);
        await outputFile.writeAsBytes(file.content as List<int>);
        extractedCount++;
        
        // Update progress during extraction (50% to 100%)
        if (extractedCount % 50 == 0 || extractedCount == totalFiles) {
          final extractProgress = 0.5 + (extractedCount / totalFiles) * 0.5;
          _emitProgress(
            level ?? 0,
            category,
            DownloadStatus.downloading,
            extractProgress,
            extractedCount,
            totalFiles,
          );
          debugPrint('📦 Extracted: $extractedCount/$totalFiles files');
        }
      } else {
        await Directory('${extractDir.path}/$filename').create(recursive: true);
      }
    }
    
    debugPrint('✅ Extracted $extractedCount files to ${extractDir.path}');
  }

  /// Find JSON file in directory (fallback)
  Future<File?> _findJsonFile(Directory dir) async {
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.endsWith('.json') && !entity.path.contains('manifest')) {
        return entity;
      }
    }
    return null;
  }

  // ==================== Status Helpers ====================

  /// Get current download progress for all items
  Future<List<DownloadProgress>> getAllProgress() async {
    return await _storage.getAllDownloadProgress();
  }

  /// Get exam download progress for a level
  Future<DownloadProgress?> getExamProgress(int level) async {
    return await _storage.getExamProgress(level);
  }

  /// Get question download progress
  Future<DownloadProgress?> getQuestionProgress(String category, int? level) async {
    return await _storage.getQuestionProgress(category, level);
  }

  /// Check if exams are available offline for a level
  Future<bool> hasOfflineExams(int level) async {
    final progress = await _storage.getExamProgress(level);
    return progress?.isReadyForOffline ?? false;
  }

  /// Check if questions are available offline
  Future<bool> hasOfflineQuestions(String category, int? level) async {
    final progress = await _storage.getQuestionProgress(category, level);
    return progress?.isReadyForOffline ?? false;
  }

  /// Delete offline data for a level
  Future<void> deleteExamData(int level) async {
    // Delete extracted files
    final extractDir = await _getExamExtractDir(level);
    if (await extractDir.exists()) {
      await extractDir.delete(recursive: true);
    }
    
    await _storage.clearLevelData(level);
    _emitProgress(level, null, DownloadStatus.notDownloaded, 0.0, 0, 0);
  }

  /// Delete offline questions
  Future<void> deleteQuestionData(String category, int? level) async {
    // Delete extracted files
    final extractDir = await _getQuestionExtractDir(category, level);
    if (await extractDir.exists()) {
      await extractDir.delete(recursive: true);
    }
    
    await _storage.deleteQuestionData(category, level);
    final progress = DownloadProgress(
      level: level ?? 0,
      category: category,
      status: DownloadStatus.notDownloaded,
    );
    await _storage.updateQuestionProgress(category, level, progress);
    _progressController.add(progress);
  }

  // ==================== Helper Methods ====================

  void _emitProgress(
    int level,
    String? category,
    DownloadStatus status,
    double progress,
    int downloadedFiles,
    int totalFiles, {
    String? errorMessage,
  }) {
    final progressUpdate = DownloadProgress(
      level: level,
      category: category,
      status: status,
      progress: progress,
      downloadedFiles: downloadedFiles,
      totalFiles: totalFiles,
      errorMessage: errorMessage,
    );
    _progressController.add(progressUpdate);
  }

  /// Build full URL for a media file path
  String buildMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    final baseUrl = ApiConstants.baseUrl.replaceAll('/api', '');
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '$baseUrl$normalizedPath';
  }

  /// Get local path for a media file (from extracted ZIP)
  Future<String?> getLocalMediaPath(String? relativePath, {int? level, String? category}) async {
    if (relativePath == null || relativePath.isEmpty) return null;

    // Determine the extract directory based on level or category
    Directory? extractDir;
    
    if (level != null) {
      extractDir = await _getExamExtractDir(level);
    } else if (category != null) {
      extractDir = await _getQuestionExtractDir(category, null);
    }
    
    if (extractDir == null) return null;
    
    // The media files are extracted relative to the ZIP structure
    // e.g., audio/filename.mp3 or images/filename.png
    final localPath = '${extractDir.path}/$relativePath';
    final file = File(localPath);
    
    if (await file.exists()) {
      return localPath;
    }
    
    // Try with just the filename in audio/images subdirectory
    final filename = relativePath.split('/').last;
    final audioPath = '${extractDir.path}/audio/$filename';
    final imagePath = '${extractDir.path}/images/$filename';
    
    if (await File(audioPath).exists()) {
      return audioPath;
    }
    if (await File(imagePath).exists()) {
      return imagePath;
    }
    
    return null;
  }

  /// Get media path - local if available, otherwise remote URL
  Future<String> getMediaPath(String? relativePath, {int? level, String? category}) async {
    if (relativePath == null || relativePath.isEmpty) return '';

    // Try local first
    final localPath = await getLocalMediaPath(relativePath, level: level, category: category);
    if (localPath != null) {
      return localPath;
    }

    // Fall back to remote URL
    return buildMediaUrl(relativePath);
  }
}
