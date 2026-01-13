class ApiConstants {
  static const String baseUrl = 'https://8e23deb9e9e2.ngrok-free.app/api';

  // Auth endpoints
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String oauth = '/auth/oauth';

  // User endpoints
  static const String profile = '/user/profile';
  static const String subscriptionStatus = '/user/subscription-status';

  // History endpoints
  static const String historyExams = '/history/exams';
  static const String historySummary = '/history/summary';
  static const String historyPractice = '/history/practice';

  // Bookmarks endpoints
  static const String bookmarksQuestions = '/bookmarks/questions';
  static const String bookmarksVocabulary = '/bookmarks/vocabulary';
  static const String bookmarksGrammar = '/bookmarks/grammar';

  // Practice endpoints
  static const String practiceCategories = '/practice/categories';
  static const String practiceQuestions = '/practice/questions';

  // Exams endpoints
  static const String examsList = '/exams';
  static const String examsDetail = '/exams/{id}';
  static const String examsSubmit = '/exams/{id}/submit';

  // Billing endpoints
  static const String billingPackages = '/billing/packages';
  static const String billingSubscription = '/billing/subscription';
}
