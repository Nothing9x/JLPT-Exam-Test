class UserModel {
  final int id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String language;
  final int? level;
  final String? oauthProvider;
  final bool isPremium;
  final DateTime? premiumExpireDate;
  final String? subscriptionPackage;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.language,
    this.level,
    this.oauthProvider,
    required this.isPremium,
    this.premiumExpireDate,
    this.subscriptionPackage,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      fullName: json['fullName'],
      avatarUrl: json['avatarUrl'],
      language: json['language'] ?? 'vi',
      level: json['level'],
      oauthProvider: json['oauthProvider'],
      isPremium: json['isPremium'] ?? false,
      premiumExpireDate: json['premiumExpireDate'] != null
          ? DateTime.parse(json['premiumExpireDate'])
          : null,
      subscriptionPackage: json['subscriptionPackage'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'language': language,
      'level': level,
      'oauthProvider': oauthProvider,
      'isPremium': isPremium,
      'premiumExpireDate': premiumExpireDate?.toIso8601String(),
      'subscriptionPackage': subscriptionPackage,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class AuthResponse {
  final String token;
  final UserModel user;

  AuthResponse({
    required this.token,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'],
      user: UserModel.fromJson(json['user']),
    );
  }
}
