import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_constants.dart';

class PracticeType {
  final int typeId;
  final String key;
  final String name;
  final int totalQuestions;
  final Map<int, int> byLevel;

  PracticeType({
    required this.typeId,
    required this.key,
    required this.name,
    required this.totalQuestions,
    required this.byLevel,
  });

  factory PracticeType.fromJson(Map<String, dynamic> json) {
    final byLevelMap = <int, int>{};
    if (json['byLevel'] != null) {
      (json['byLevel'] as Map<String, dynamic>).forEach((key, value) {
        byLevelMap[int.parse(key)] = value as int;
      });
    }

    return PracticeType(
      typeId: json['typeId'] ?? 0,
      key: json['key'] ?? '',
      name: json['name'] ?? '',
      totalQuestions: json['totalQuestions'] ?? 0,
      byLevel: byLevelMap,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'typeId': typeId,
      'key': key,
      'name': name,
      'totalQuestions': totalQuestions,
      'byLevel': byLevel.map((k, v) => MapEntry(k.toString(), v)),
    };
  }
}

class CategoryWithTypes {
  final String category;
  final int totalQuestions;
  final List<PracticeType> types;

  CategoryWithTypes({
    required this.category,
    required this.totalQuestions,
    required this.types,
  });

  factory CategoryWithTypes.fromJson(Map<String, dynamic> json) {
    final typesList = <PracticeType>[];
    if (json['types'] != null) {
      for (var typeJson in json['types']) {
        typesList.add(PracticeType.fromJson(typeJson));
      }
    }

    return CategoryWithTypes(
      category: json['category'] ?? '',
      totalQuestions: json['totalQuestions'] ?? 0,
      types: typesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'totalQuestions': totalQuestions,
      'types': types.map((t) => t.toJson()).toList(),
    };
  }
}

class VocabularyStatsService {
  static const String _cacheKey = 'vocabulary_stats_cache';
  static const Duration _cacheExpiration = Duration(days: 7);

  final http.Client _client;

  VocabularyStatsService({http.Client? client})
      : _client = client ?? http.Client();

  /// Get all practice categories with types
  Future<Map<String, CategoryWithTypes>> getAllCategories() async {
    try {
      debugPrint('Fetching practice categories from API...');

      // Try cache first for faster loading
      final cached = await _getCached();
      if (cached.isNotEmpty) {
        debugPrint('Loaded categories from cache, will refresh in background');

        // Return cached data immediately, refresh in background
        _refreshInBackground();
        return cached;
      }

      // If no cache, fetch from API
      return await _fetchFromApi();
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      // Try to return cached data as fallback
      return await _getCached();
    }
  }

  /// Fetch from API
  Future<Map<String, CategoryWithTypes>> _fetchFromApi() async {
    try {
      final response = await _client.get(
        Uri.parse('${ApiConstants.baseUrl}/mytest/types'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Categories fetched successfully from API');

        final categories = _parseCategories(data);
        await _cacheData(data);
        return categories;
      } else {
        throw Exception('API returned ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching from API: $e');
      rethrow;
    }
  }

  /// Refresh in background without blocking
  void _refreshInBackground() {
    _fetchFromApi().catchError((e) {
      debugPrint('Background refresh failed: $e');
      return <String, CategoryWithTypes>{};
    });
  }

  /// Parse categories from API response
  Map<String, CategoryWithTypes> _parseCategories(Map<String, dynamic> data) {
    final categories = <String, CategoryWithTypes>{};

    if (data['categories'] != null) {
      for (var categoryJson in data['categories']) {
        final category = CategoryWithTypes.fromJson(categoryJson);
        categories[category.category] = category;
      }
    }

    return categories;
  }

  /// Cache data
  Future<void> _cacheData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_cacheKey, json.encode(cacheData));
      debugPrint('Categories cached successfully');
    } catch (e) {
      debugPrint('Error caching categories: $e');
    }
  }

  /// Get cached data
  Future<Map<String, CategoryWithTypes>> _getCached() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString(_cacheKey);

      if (cachedString == null) {
        return {};
      }

      final cacheData = json.decode(cachedString);
      final timestamp = DateTime.parse(cacheData['timestamp']);
      final data = cacheData['data'] as Map<String, dynamic>;

      final age = DateTime.now().difference(timestamp);
      if (age > _cacheExpiration) {
        debugPrint('Cache expired (${age.inDays} days old)');
      } else {
        debugPrint('Using cached categories (${age.inHours} hours old)');
      }

      return _parseCategories(data);
    } catch (e) {
      debugPrint('Error loading cached categories: $e');
      return {};
    }
  }

  /// Clear cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      debugPrint('Categories cache cleared');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}
