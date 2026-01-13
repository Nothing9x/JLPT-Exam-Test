import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_constants.dart';
import '../models/user_model.dart';

class AuthService {
  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? http.Client();

  Future<AuthResponse> register({
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String language = 'vi',
    int? level,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.register}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'fullName': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        'language': _mapLanguageCode(language),
        if (level != null) 'level': level,
      }),
    );

    if (response.statusCode == 200) {
      return AuthResponse.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw AuthException(error['error'] ?? 'Registration failed');
    }
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.login}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      return AuthResponse.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw AuthException(error['error'] ?? 'Login failed');
    }
  }

  Future<AuthResponse> oauthLogin({
    required String email,
    required String provider,
    required String oauthId,
    required String fullName,
    String? avatarUrl,
    String language = 'vi',
    int? level,
  }) async {
    final response = await _client.post(
      Uri.parse('${ApiConstants.baseUrl}${ApiConstants.oauth}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'provider': provider,
        'oauthId': oauthId,
        'fullName': fullName,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
        'language': _mapLanguageCode(language),
        if (level != null) 'level': level,
      }),
    );

    if (response.statusCode == 200) {
      return AuthResponse.fromJson(jsonDecode(response.body));
    } else {
      final error = jsonDecode(response.body);
      throw AuthException(error['error'] ?? 'OAuth login failed');
    }
  }

  // Map app language codes to API language codes
  String _mapLanguageCode(String appLanguageCode) {
    switch (appLanguageCode) {
      case 'ja':
        return 'ja';
      case 'en':
        return 'en';
      case 'vn':
        return 'vi';
      default:
        return 'en';
    }
  }

  void dispose() {
    _client.close();
  }
}

class AuthException implements Exception {
  final String message;

  AuthException(this.message);

  @override
  String toString() => message;
}
