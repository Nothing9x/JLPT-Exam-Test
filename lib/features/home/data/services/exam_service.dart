import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';

class ExamModel {
  final int id;
  final int? externalId;
  final String title;
  final int level;
  final int? examType;
  final int time;
  final int totalScore;
  final int passScore;
  final int questionCount;

  ExamModel({
    required this.id,
    this.externalId,
    required this.title,
    required this.level,
    this.examType,
    required this.time,
    required this.totalScore,
    required this.passScore,
    required this.questionCount,
  });

  factory ExamModel.fromJson(Map<String, dynamic> json) {
    return ExamModel(
      id: json['id'] ?? 0,
      externalId: json['externalId'],
      title: json['title'] ?? 'Unknown',
      level: json['level'] ?? 0,
      examType: json['examType'],
      time: json['time'] ?? 0,
      totalScore: json['score'] ?? json['totalScore'] ?? 180,
      passScore: json['passScore'] ?? 100,
      questionCount: json['questionCount'] ?? 45,
    );
  }
}

class UserProfile {
  final int id;
  final String email;
  final String fullName;
  final bool isPremium;
  final String? premiumExpireDate;

  UserProfile({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isPremium,
    this.premiumExpireDate,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      isPremium: json['isPremium'] ?? false,
      premiumExpireDate: json['premiumExpireDate'],
    );
  }
}

class ExamHistoryModel {
  final int id;
  final int examId;
  final String examTitle;
  final int yourScore;
  final int totalScore;
  final bool isPassed;
  final String submittedAt;

  ExamHistoryModel({
    required this.id,
    required this.examId,
    required this.examTitle,
    required this.yourScore,
    required this.totalScore,
    required this.isPassed,
    required this.submittedAt,
  });

  factory ExamHistoryModel.fromJson(Map<String, dynamic> json) {
    return ExamHistoryModel(
      id: json['id'] ?? 0,
      examId: json['examId'] ?? 0,
      examTitle: json['examTitle'] ?? 'Unknown',
      yourScore: json['yourScore'] ?? 0,
      totalScore: json['totalScore'] ?? 180,
      isPassed: json['isPassed'] ?? false,
      submittedAt: json['submittedAt'] ?? '',
    );
  }
}

class ExamService {
  final http.Client _client;
  final String token;

  ExamService({http.Client? client, required this.token})
      : _client = client ?? http.Client();

  Future<UserProfile?> getUserProfile() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.profile}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('User Profile Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return UserProfile.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (e) {
      debugPrint('User Profile Error: $e');
      return null;
    }
  }

  Future<List<ExamModel>> getExamsByLevel(int level) async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/exams?level=$level'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Exams Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => ExamModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Exams Error: $e');
      return [];
    }
  }

  Future<List<ExamHistoryModel>> getExamHistory() async {
    try {
      debugPrint('========== EXAM HISTORY DEBUG ==========');
      debugPrint('Token (first 50 chars): ${token.length > 50 ? token.substring(0, 50) : token}...');
      debugPrint('Token length: ${token.length}');
      debugPrint('Request URL: ${ApiConstants.baseUrl}${ApiConstants.historyExams}');
      debugPrint('========================================');

      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.historyExams}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('Exam History Response: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('Exam History Error Response: ${response.body}');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        debugPrint('Loaded ${data.length} exam history records');
        return data.map((item) => ExamHistoryModel.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Exam History Error: $e');
      return [];
    }
  }

  void dispose() {
    _client.close();
  }
}
