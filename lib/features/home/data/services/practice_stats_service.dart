import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';

class PracticeCategory {
  final String category;
  final int totalQuestions;
  final Map<int, int> questionsByLevel; // level -> count

  PracticeCategory({
    required this.category,
    required this.totalQuestions,
    required this.questionsByLevel,
  });

  factory PracticeCategory.fromJson(Map<String, dynamic> json) {
    final byLevel = <int, int>{};

    // Sum up all types for this category by level
    if (json['types'] != null) {
      for (var type in json['types']) {
        final typeLevels = type['byLevel'] as Map<String, dynamic>?;
        if (typeLevels != null) {
          typeLevels.forEach((levelStr, count) {
            final level = int.tryParse(levelStr) ?? 0;
            byLevel[level] = (byLevel[level] ?? 0) + (count as int);
          });
        }
      }
    }

    return PracticeCategory(
      category: json['category'] ?? '',
      totalQuestions: json['totalQuestions'] ?? 0,
      questionsByLevel: byLevel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'totalQuestions': totalQuestions,
      'questionsByLevel': questionsByLevel.map((k, v) => MapEntry(k.toString(), v)),
    };
  }
}

class PracticeStatsService {
  static const String _cacheKey = 'practice_stats_cache';
  static const Duration _cacheExpiration = Duration(days: 7); // Cache for 7 days

  final http.Client _client;

  PracticeStatsService({http.Client? client})
      : _client = client ?? http.Client();

  /// Get practice statistics from API or cache
  Future<Map<String, PracticeCategory>> getPracticeStats() async {
    try {
      // Try to fetch from API first
      debugPrint('Fetching practice stats from API...');
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/mytest/types'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Practice stats fetched successfully from API');

        // Parse the data
        final stats = _parseStats(data);

        // Cache the data
        await _cacheStats(data);

        return stats;
      } else {
        debugPrint('API returned status ${response.statusCode}, loading from cache...');
        return await _getCachedStats();
      }
    } catch (e) {
      debugPrint('Error fetching practice stats: $e');
      debugPrint('Loading from cache...');
      return await _getCachedStats();
    }
  }

  /// Parse stats from API response
  Map<String, PracticeCategory> _parseStats(Map<String, dynamic> data) {
    final categories = <String, PracticeCategory>{};

    if (data['categories'] != null) {
      for (var categoryJson in data['categories']) {
        final category = PracticeCategory.fromJson(categoryJson);
        categories[category.category] = category;
      }
    }

    return categories;
  }

  /// Cache stats to shared preferences
  Future<void> _cacheStats(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_cacheKey, json.encode(cacheData));
      debugPrint('Practice stats cached successfully');
    } catch (e) {
      debugPrint('Error caching practice stats: $e');
    }
  }

  /// Get cached stats from shared preferences
  Future<Map<String, PracticeCategory>> _getCachedStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString(_cacheKey);

      if (cachedString == null) {
        debugPrint('No cached practice stats found');
        return {};
      }

      final cacheData = json.decode(cachedString);
      final timestamp = DateTime.parse(cacheData['timestamp']);
      final data = cacheData['data'] as Map<String, dynamic>;

      // Check if cache is expired
      if (DateTime.now().difference(timestamp) > _cacheExpiration) {
        debugPrint('Cached practice stats expired');
        // Don't delete, still return it as fallback
      } else {
        debugPrint('Loaded practice stats from cache (age: ${DateTime.now().difference(timestamp).inDays} days)');
      }

      return _parseStats(data);
    } catch (e) {
      debugPrint('Error loading cached practice stats: $e');
      return {};
    }
  }

  /// Clear cached stats
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      debugPrint('Practice stats cache cleared');
    } catch (e) {
      debugPrint('Error clearing practice stats cache: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
