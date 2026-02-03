import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/offline_data_models.dart';
import 'offline_storage_service.dart';

class PracticeQuestion {
  final int id;
  final String question;
  final List<String> answers;
  final String? audio;
  final String? image;
  final String? txtRead;
  final String? groupTitle;
  final String category;
  final int typeId;
  final String typeName;
  final int level;
  int? correctAnswer; // Only available after fetching answer
  String? explain;
  String? explainEn;
  String? explainVn;
  String? explainCn;

  PracticeQuestion({
    required this.id,
    required this.question,
    required this.answers,
    this.audio,
    this.image,
    this.txtRead,
    this.groupTitle,
    required this.category,
    required this.typeId,
    required this.typeName,
    required this.level,
    this.correctAnswer,
    this.explain,
    this.explainEn,
    this.explainVn,
    this.explainCn,
  });

  factory PracticeQuestion.fromJson(Map<String, dynamic> json) {
    final answersList = json['answers'] as List? ?? [];
    return PracticeQuestion(
      id: json['id'] ?? 0,
      question: json['question'] ?? '',
      answers: answersList.map((a) => a.toString()).toList(),
      audio: json['audio'],
      image: json['image'],
      txtRead: json['txtRead'],
      groupTitle: json['groupTitle'],
      category: json['category'] ?? '',
      typeId: json['typeId'] ?? 0,
      typeName: json['typeName'] ?? '',
      level: json['level'] ?? 0,
      correctAnswer: json['correctAnswer'],
      explain: json['explain'],
      explainEn: json['explainEn'],
      explainVn: json['explainVn'],
      explainCn: json['explainCn'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'answers': answers,
      'audio': audio,
      'image': image,
      'txtRead': txtRead,
      'groupTitle': groupTitle,
      'category': category,
      'typeId': typeId,
      'typeName': typeName,
      'level': level,
      'correctAnswer': correctAnswer,
      'explain': explain,
      'explainEn': explainEn,
      'explainVn': explainVn,
      'explainCn': explainCn,
    };
  }
}

class PracticeQuestionService {
  static const Duration _cacheExpiration = Duration(days: 30);
  final http.Client _client;
  final String? token;
  final OfflineStorageService _offlineStorage;

  PracticeQuestionService({http.Client? client, this.token, OfflineStorageService? offlineStorage})
      : _client = client ?? http.Client(),
        _offlineStorage = offlineStorage ?? OfflineStorageService() {
    debugPrint('=== PracticeQuestionService Created ===');
    debugPrint('Token Status: ${token != null ? "✓ Authenticated (${token!.length} chars)" : "✗ NO TOKEN - User not authenticated"}');
    if (token == null) {
      debugPrint('WARNING: Practice history, bookmarks, and question filtering will not work without authentication');
    }
  }

  String _getCacheKey(int level, String category, int typeId, int limit) {
    return 'practice_questions_${level}_${category}_${typeId}_$limit';
  }

  /// Fetch questions from API
  Future<List<PracticeQuestion>> fetchQuestions({
    required int level,
    required String category,
    required int typeId,
    int limit = 20,
  }) async {
    try {
      debugPrint('========== FETCH PRACTICE QUESTIONS ==========');
      debugPrint('Level: $level, Category: $category, TypeId: $typeId, Limit: $limit');

      final uri = Uri.parse(
        '${ApiConstants.baseUrl}/mytest/questions',
      ).replace(queryParameters: {
        'level': level.toString(),
        'category': category,
        'typeId': typeId.toString(),
        'limit': limit.toString(),
      });

      debugPrint('Request URL: $uri');

      final response = await _client.get(
        uri,
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        debugPrint('Fetched ${data.length} questions from API');

        final questions =
            data.map((item) => PracticeQuestion.fromJson(item)).toList();

        // Cache the questions
        await _cacheQuestions(level, category, typeId, limit, questions);

        return questions;
      } else {
        debugPrint('API error: ${response.body}');
        throw Exception('Failed to fetch questions: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching questions: $e');
      rethrow;
    }
  }

  /// Get questions with offline-first strategy
  Future<List<PracticeQuestion>> getQuestions({
    required int level,
    required String category,
    required int typeId,
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        // Try offline data first
        final offlineQuestions = await _getOfflineQuestions(level, category, typeId, limit);
        if (offlineQuestions.isNotEmpty) {
          debugPrint('Loaded ${offlineQuestions.length} questions from offline storage');
          return offlineQuestions;
        }

        // Try cache next
        final cached = await _getCachedQuestions(level, category, typeId, limit);
        if (cached.isNotEmpty) {
          debugPrint('Loaded ${cached.length} questions from cache');
          // Refresh in background
          _refreshInBackground(level, category, typeId, limit);
          return cached;
        }
      }

      // Fetch from API
      return await fetchQuestions(
        level: level,
        category: category,
        typeId: typeId,
        limit: limit,
      );
    } catch (e) {
      debugPrint('Error getting questions: $e');
      
      // Try offline as fallback first
      final offlineQuestions = await _getOfflineQuestions(level, category, typeId, limit);
      if (offlineQuestions.isNotEmpty) {
        debugPrint('Using offline questions as fallback');
        return offlineQuestions;
      }
      
      // Try cache as fallback
      final cached = await _getCachedQuestions(level, category, typeId, limit);
      if (cached.isNotEmpty) {
        debugPrint('Using cached questions as fallback');
        return cached;
      }
      rethrow;
    }
  }

  /// Get questions from offline storage
  Future<List<PracticeQuestion>> _getOfflineQuestions(
    int level,
    String category,
    int typeId,
    int limit,
  ) async {
    try {
      final questionData = await _offlineStorage.getQuestionData(category, level);
      if (questionData == null) return [];

      // Find questions matching typeId
      final List<PracticeQuestion> matchingQuestions = [];
      for (final typeGroup in questionData.types) {
        if (typeGroup.typeId == typeId) {
          for (final q in typeGroup.questions) {
            matchingQuestions.add(PracticeQuestion(
              id: q.id,
              question: q.question,
              answers: q.answers,
              audio: q.audio,
              image: q.image,
              txtRead: q.txtRead,
              groupTitle: q.groupTitle,
              category: category,
              typeId: typeId,
              typeName: typeGroup.typeName,
              level: level,
              correctAnswer: q.correctAnswer,
              explain: q.explain,
              explainEn: q.explainEn,
              explainVn: q.explainVn,
              explainCn: q.explainCn,
            ));
          }
          break;
        }
      }

      // Shuffle and limit
      if (matchingQuestions.isNotEmpty) {
        matchingQuestions.shuffle(Random());
        return matchingQuestions.take(limit).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error getting offline questions: $e');
      return [];
    }
  }

  /// Fetch answer for a specific question
  Future<PracticeQuestion> fetchQuestionAnswer(int questionId) async {
    try {
      debugPrint('Fetching answer for question $questionId');

      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/mytest/questions/$questionId/answer'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('Answer response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return PracticeQuestion.fromJson(data);
      } else {
        throw Exception('Failed to fetch answer: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching answer: $e');
      rethrow;
    }
  }

  /// Cache questions
  Future<void> _cacheQuestions(
    int level,
    String category,
    int typeId,
    int limit,
    List<PracticeQuestion> questions,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(level, category, typeId, limit);

      final cacheData = {
        'questions': questions.map((q) => q.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await prefs.setString(cacheKey, json.encode(cacheData));
      debugPrint('Questions cached successfully');
    } catch (e) {
      debugPrint('Error caching questions: $e');
    }
  }

  /// Get cached questions
  Future<List<PracticeQuestion>> _getCachedQuestions(
    int level,
    String category,
    int typeId,
    int limit,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(level, category, typeId, limit);
      final cachedString = prefs.getString(cacheKey);

      if (cachedString == null) {
        return [];
      }

      final cacheData = json.decode(cachedString);
      final timestamp = DateTime.parse(cacheData['timestamp']);
      final age = DateTime.now().difference(timestamp);

      if (age > _cacheExpiration) {
        debugPrint('Cache expired (${age.inDays} days old)');
        // Don't delete, still return as fallback
      } else {
        debugPrint('Using cached questions (${age.inHours} hours old)');
      }

      final List<dynamic> questionsData = cacheData['questions'];
      return questionsData
          .map((item) => PracticeQuestion.fromJson(item))
          .toList();
    } catch (e) {
      debugPrint('Error loading cached questions: $e');
      return [];
    }
  }

  /// Refresh questions in background
  void _refreshInBackground(
    int level,
    String category,
    int typeId,
    int limit,
  ) {
    fetchQuestions(
      level: level,
      category: category,
      typeId: typeId,
      limit: limit,
    ).catchError((e) {
      debugPrint('Background refresh failed: $e');
      return <PracticeQuestion>[];
    });
  }

  /// Save practice history to backend
  Future<void> savePracticeHistory({
    required int questionId,
    required int userAnswer,
    required bool isCorrect,
    required String practiceType,
    required int level,
  }) async {
    try {
      debugPrint('=== Save Practice History Request ===');
      debugPrint('Question ID: $questionId');
      debugPrint('User Answer: $userAnswer');
      debugPrint('Is Correct: $isCorrect');
      debugPrint('Practice Type: $practiceType');
      debugPrint('Level: $level');
      debugPrint('Token: ${token != null ? "Present (${token!.length} chars)" : "NULL - NOT AUTHENTICATED"}');
      debugPrint('URL: ${ApiConstants.baseUrl}/history/practice');

      final requestBody = {
        'questionId': questionId,
        'userAnswer': userAnswer,
        'isCorrect': isCorrect,
        'practiceType': practiceType,
        'level': level,
      };
      debugPrint('Request Body: ${json.encode(requestBody)}');

      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/history/practice'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10));

      debugPrint('=== Save Practice History Response ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');
      debugPrint('Response Headers: ${response.headers}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✓ Practice history saved successfully');
      } else if (response.statusCode == 401) {
        debugPrint('✗ AUTHENTICATION ERROR: Token is invalid or expired');
        debugPrint('  Please check:');
        debugPrint('  1. User is logged in');
        debugPrint('  2. Token is being passed correctly from login');
        debugPrint('  3. Token has not expired on server');
      } else {
        debugPrint('✗ Failed to save practice history');
        debugPrint('  Status: ${response.statusCode}');
        debugPrint('  Error: ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('✗ Exception saving practice history: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  /// Get list of practiced question IDs
  Future<Set<int>> getPracticedQuestionIds() async {
    try {
      debugPrint('=== Get Practiced Questions Request ===');
      debugPrint('Token: ${token != null ? "Present (${token!.length} chars)" : "NULL - NOT AUTHENTICATED"}');
      debugPrint('URL: ${ApiConstants.baseUrl}/history/practice');
      debugPrint('Method: GET');
      debugPrint('Headers: {Authorization: Bearer [TOKEN], Content-Type: application/json}');

      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/history/practice'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      debugPrint('=== Get Practiced Questions Response ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Headers: ${response.headers}');
      debugPrint('Response Body Length: ${response.body.length} characters');
      debugPrint('Response Body: ${response.body.isEmpty ? "[EMPTY]" : response.body}');

      if (response.statusCode == 200) {
        try {
          final List<dynamic> data = json.decode(response.body);
          final questionIds = data.map((item) => item['questionId'] as int).toSet();
          debugPrint('✓ Found ${questionIds.length} practiced questions');
          debugPrint('Question IDs: ${questionIds.take(10).join(", ")}${questionIds.length > 10 ? "..." : ""}');
          return questionIds;
        } catch (parseError) {
          debugPrint('✗ ERROR: Failed to parse response body as JSON');
          debugPrint('Parse Error: $parseError');
          debugPrint('Raw Body: ${response.body}');
          return {};
        }
      } else if (response.statusCode == 401) {
        debugPrint('✗ AUTHENTICATION ERROR: Token is invalid or expired');
        debugPrint('Response: ${response.body.isEmpty ? "[NO ERROR MESSAGE FROM SERVER]" : response.body}');
        return {};
      } else if (response.statusCode == 400) {
        debugPrint('✗ BAD REQUEST ERROR (400)');
        debugPrint('This is a SERVER-SIDE error from: ${ApiConstants.baseUrl}/history/practice');
        debugPrint('Response Body: ${response.body.isEmpty ? "[SERVER SENT EMPTY ERROR MESSAGE]" : response.body}');
        debugPrint('Possible causes:');
        debugPrint('  1. Backend expects different request format');
        debugPrint('  2. Backend missing query parameters');
        debugPrint('  3. Backend endpoint not properly configured');
        debugPrint('  4. Database/ORM error on server');
        debugPrint('ACTION REQUIRED: Check your backend logs for /api/history/practice GET endpoint');
        return {};
      } else {
        debugPrint('✗ Failed to fetch practiced questions');
        debugPrint('Status: ${response.statusCode}');
        debugPrint('Response: ${response.body.isEmpty ? "[EMPTY RESPONSE]" : response.body}');
        return {};
      }
    } catch (e, stackTrace) {
      debugPrint('✗ CLIENT-SIDE EXCEPTION fetching practiced questions');
      debugPrint('Exception Type: ${e.runtimeType}');
      debugPrint('Exception Message: $e');
      debugPrint('Stack trace: $stackTrace');
      return {};
    }
  }

  /// Bookmark a question
  Future<bool> bookmarkQuestion({
    required int questionId,
    String? note,
  }) async {
    try {
      debugPrint('=== Bookmark Question Request ===');
      debugPrint('Question ID: $questionId');
      debugPrint('Note: ${note ?? "None"}');
      debugPrint('Token: ${token != null ? "Present (${token!.length} chars)" : "NULL - NOT AUTHENTICATED"}');
      debugPrint('URL: ${ApiConstants.baseUrl}/bookmarks/questions');

      final requestBody = {
        'questionId': questionId,
        if (note != null) 'note': note,
      };
      debugPrint('Request Body: ${json.encode(requestBody)}');

      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/bookmarks/questions'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      ).timeout(const Duration(seconds: 10));

      debugPrint('=== Bookmark Question Response ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✓ Question bookmarked successfully');
        return true;
      } else if (response.statusCode == 401) {
        debugPrint('✗ AUTHENTICATION ERROR: Token is invalid or expired');
        return false;
      } else {
        debugPrint('✗ Failed to bookmark question');
        debugPrint('Status: ${response.statusCode}');
        debugPrint('Error: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('✗ Exception bookmarking question: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Clear all cached questions
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final practiceKeys =
          keys.where((key) => key.startsWith('practice_questions_'));

      for (var key in practiceKeys) {
        await prefs.remove(key);
      }

      debugPrint('All practice question cache cleared');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  /// Report a question
  /// POST /reports/questions
  /// reportType: wrong_answer, audio_quality, typo, technical, confusing, other
  Future<bool> reportQuestion({
    required int questionId,
    required String reportType,
    String? description,
  }) async {
    try {
      debugPrint('=== Report Question Request ===');
      debugPrint('Question ID: $questionId');
      debugPrint('Report Type: $reportType');
      debugPrint('Description: ${description ?? "[NONE]"}');
      debugPrint('Token: ${token != null ? "Present (${token!.length} chars)" : "NULL"}');
      debugPrint('URL: ${ApiConstants.baseUrl}/reports/questions');

      if (token == null) {
        debugPrint('✗ Cannot report: No authentication token');
        return false;
      }

      final response = await _client.post(
        Uri.parse('${ApiConstants.baseUrl}/reports/questions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'questionId': questionId,
          'reportType': reportType,
          if (description != null && description.isNotEmpty)
            'description': description,
        }),
      );

      debugPrint('=== Report Question Response ===');
      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 201) {
        debugPrint('✓ Question reported successfully');
        return true;
      } else if (response.statusCode == 400) {
        debugPrint('✗ BAD REQUEST (400)');
        debugPrint('Error: ${response.body}');
        debugPrint('Possible causes:');
        debugPrint('  1. Invalid report type: $reportType');
        debugPrint('  2. Question ID $questionId not found');
        debugPrint('  3. Missing required fields');
        return false;
      } else if (response.statusCode == 401) {
        debugPrint('✗ AUTHENTICATION ERROR (401)');
        debugPrint('Token is invalid or expired');
        return false;
      } else {
        debugPrint('✗ Failed to report question');
        debugPrint('Status: ${response.statusCode}');
        debugPrint('Error: ${response.body}');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('✗ CLIENT-SIDE EXCEPTION reporting question');
      debugPrint('Exception Type: ${e.runtimeType}');
      debugPrint('Exception Message: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}
