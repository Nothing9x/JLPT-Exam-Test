class ApiConstants {
  static const String baseUrl = 'http://localhost:8080/api';

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String oauth = '/auth/oauth';

  // User endpoints
  static const String profile = '/user/profile';
  static const String subscriptionStatus = '/user/subscription-status';
}
