import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';

class HistoryModel {
  final String examId;
  final String examTitle;
  final int level;
  final int totalScore;
  final int yourScore;
  final bool isPassed;
  final DateTime submittedAt;

  HistoryModel({
    required this.examId,
    required this.examTitle,
    required this.level,
    required this.totalScore,
    required this.yourScore,
    required this.isPassed,
    required this.submittedAt,
  });

  factory HistoryModel.fromJson(Map<String, dynamic> json) {
    return HistoryModel(
      examId: json['examId'].toString(),
      examTitle: json['examTitle'] ?? 'Unknown Exam',
      level: json['level'] ?? 0,
      totalScore: json['totalScore'] ?? 0,
      yourScore: json['yourScore'] ?? 0,
      isPassed: json['isPassed'] ?? false,
      submittedAt: DateTime.parse(json['submittedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class SavedItem {
  final int id;
  final String title;
  final String? subtitle;
  final String type; // 'vocabulary', 'questions', 'grammar'

  SavedItem({
    required this.id,
    required this.title,
    this.subtitle,
    required this.type,
  });
}

class HistoryService {
  final http.Client _client;
  final String token;

  HistoryService({http.Client? client, required this.token})
      : _client = client ?? http.Client();

  Future<HistoryModel?> getRecentHistory() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.historyExams}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('History Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return HistoryModel.fromJson(data[0]);
        }
      }
      return null;
    } catch (e) {
      debugPrint('History Service Error: $e');
      return null;
    }
  }

  Future<List<SavedItem>> getSavedItems() async {
    final items = <SavedItem>[];
    
    try {
      // Get saved vocabulary
      final vocabResponse = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.bookmarksVocabulary}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (vocabResponse.statusCode == 200) {
        final List<dynamic> data = jsonDecode(vocabResponse.body);
        if (data.isNotEmpty) {
          items.add(SavedItem(
            id: 1,
            title: 'Saved Vocabulary',
            subtitle: '${data.length} items',
            type: 'vocabulary',
          ));
        }
      }

      // Get saved questions
      final questionsResponse = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.bookmarksQuestions}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (questionsResponse.statusCode == 200) {
        final List<dynamic> data = jsonDecode(questionsResponse.body);
        if (data.isNotEmpty) {
          items.add(SavedItem(
            id: 2,
            title: 'Saved Questions',
            subtitle: '${data.length} items',
            type: 'questions',
          ));
        }
      }

      debugPrint('Saved items count: ${items.length}');
      return items;
    } catch (e) {
      debugPrint('Saved Items Service Error: $e');
      return [];
    }
  }

  void dispose() {
    _client.close();
  }
}
