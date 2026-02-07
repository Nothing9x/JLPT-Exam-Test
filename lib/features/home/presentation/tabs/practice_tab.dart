import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/history_service.dart';
import '../../data/services/practice_stats_service.dart';
import '../screens/vocabulary_practice_screen.dart';
import '../screens/grammar_practice_screen.dart';
import '../screens/reading_practice_screen.dart';
import '../screens/listening_practice_screen.dart';
import '../../../theory/presentation/screens/theory_screen.dart';
import 'test_detail_screen.dart';

class PracticeTab extends StatefulWidget {
  final String languageCode;
  final String? token;
  final VoidCallback? onMockExamsPressed;

  const PracticeTab({
    super.key,
    required this.languageCode,
    this.token,
    this.onMockExamsPressed,
  });

  @override
  State<PracticeTab> createState() => _PracticeTabState();
}

class _PracticeTabState extends State<PracticeTab> {
  late HistoryService _historyService;
  late PracticeStatsService _practiceStatsService;
  late Future<(HistoryModel?, List<SavedItem>, Map<String, PracticeCategory>)>
      _dataFuture;

  // TODO: Get from user profile
  static const int _userLevel = 3;

  @override
  void initState() {
    super.initState();
    _historyService = HistoryService(token: widget.token ?? '');
    _practiceStatsService = PracticeStatsService();
    _dataFuture = _fetchData();
  }

  Future<(HistoryModel?, List<SavedItem>, Map<String, PracticeCategory>)>
      _fetchData() async {
    final history = await _historyService.getRecentHistory();
    final saved = await _historyService.getSavedItems();
    final practiceStats = await _practiceStatsService.getPracticeStats();
    return (history, saved, practiceStats);
  }

  @override
  void dispose() {
    _historyService.dispose();
    _practiceStatsService.dispose();
    super.dispose();
  }

  void _navigateToMockExams() {
    if (widget.onMockExamsPressed != null) {
      widget.onMockExamsPressed!();
    }
  }

  void _navigateToPracticeTest(BuildContext context) {
    // Navigate to Practice Test using Official Exam type (4)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestDetailScreen(
          level: 'N$_userLevel',
          category: 'OFFICIAL',
          languageCode: widget.languageCode,
          token: widget.token,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Welcome and Profile
            _buildHeader(isDark),

            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Promotional Banner
                  _buildPromoBanner(isDark),

                  const SizedBox(height: 24),

                  // Practice Section
                  _buildPracticeSection(isDark),

                  const SizedBox(height: 24),

                  // Exam Prep Section
                  _buildExamPrepSection(isDark),

                  const SizedBox(height: 24),

                  // History Section
                  _buildHistorySection(isDark),

                  const SizedBox(height: 24),

                  // Saved Section
                  _buildSavedSection(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 48, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () {
                  // TODO: Show level picker dropdown
                },
                child: Row(
                  children: [
                    Text(
                      'JLPT N$_userLevel',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 30,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.2),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowPink,
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              image: const DecorationImage(
                image: NetworkImage(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuBZ4ByL1eYP9Sw1FKYrlKVKL2ORO2GiisXn6vXLTIKgQ4FHdrSrUnIMkcxFvat7ScAiDCpYcanECbhN37fXyWaMWQIEeka3HLQVQjl-3N2PsC8w_OZi7LbjbUvId-PxOsuMO_5iUPf-QbEjdQ9cQfvuiKhFv_Nj5omHcJXgOi9e_As8gkL6Pk6FjunoU2dFKfgdGoDSdg6AMzcJMbUUXOYpeW7gNO-bpLPeZs9okQ1WRu0kIv1hSYpgakKQkZVfeWJwGgskHSugjg',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.gradientStart,
            AppColors.gradientEnd,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background decoration
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'LIMITED TIME',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                '50% OFF Premium',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Master N$_userLevel grammar with unlimited mock exams.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // TODO: Navigate to upgrade
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  elevation: 0,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      'Upgrade Now',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Practice',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildPracticeItem(
                context,
                icon: Icons.menu_book,
                title: 'Vocabulary',
                isDark: isDark,
                onTap: () => _navigateToPracticeScreen(context, 'vocabulary'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPracticeItem(
                context,
                icon: Icons.edit,
                title: 'Grammar',
                isDark: isDark,
                onTap: () => _navigateToPracticeScreen(context, 'grammar'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPracticeItem(
                context,
                icon: Icons.headphones,
                title: 'Listening',
                isDark: isDark,
                onTap: () => _navigateToPracticeScreen(context, 'listening'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildPracticeItem(
                context,
                icon: Icons.article,
                title: 'Reading',
                isDark: isDark,
                onTap: () => _navigateToPracticeScreen(context, 'reading'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _navigateToTheory(String levelId) {
    final levelTitle = levelId.toUpperCase().replaceFirst('N', 'N');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TheoryScreen(
          languageCode: widget.languageCode,
          levelId: levelId,
          levelTitle: levelTitle,
        ),
      ),
    );
  }

  Widget _buildPracticeItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: AppColors.shadowPink,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.iconBackgroundLight,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPracticeScreen(BuildContext context, String type) {
    Widget screen;
    switch (type) {
      case 'vocabulary':
        screen = VocabularyPracticeScreen(
          languageCode: widget.languageCode,
          token: widget.token,
          userLevel: _userLevel,
        );
        break;
      case 'grammar':
        screen = GrammarPracticeScreen(
          languageCode: widget.languageCode,
          token: widget.token,
          userLevel: _userLevel,
        );
        break;
      case 'listening':
        screen = ListeningPracticeScreen(
          languageCode: widget.languageCode,
          token: widget.token,
          userLevel: _userLevel,
        );
        break;
      case 'reading':
        screen = ReadingPracticeScreen(
          languageCode: widget.languageCode,
          token: widget.token,
          userLevel: _userLevel,
        );
        break;
      default:
        return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildExamPrepSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exam Prep',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color:
                isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildExamPrepItem(
                context,
                icon: Icons.school_outlined,
                title: 'Theory',
                isDark: isDark,
                badge: 'Free',
                badgeColor: AppColors.accentGreen,
                onTap: () => _navigateToTheory('n$_userLevel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildExamPrepItem(
                context,
                icon: Icons.quiz_outlined,
                title: 'Mock\nExams',
                isDark: isDark,
                onTap: _navigateToMockExams,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildExamPrepItem(
                context,
                icon: Icons.assignment_turned_in,
                title: 'Practice\nTest',
                isDark: isDark,
                badge: 'Hot',
                badgeColor: AppColors.accentRed,
                iconFilled: true,
                onTap: () => _navigateToPracticeTest(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildExamPrepItem(
                context,
                icon: Icons.tips_and_updates,
                title: 'Exam\nTips',
                isDark: isDark,
                iconFilled: true,
                onTap: () {
                  // TODO: Navigate to exam tips
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExamPrepItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isDark,
    String? badge,
    Color? badgeColor,
    bool iconFilled = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cardBackgroundDark
                  : AppColors.surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? AppColors.borderDark : AppColors.borderLight,
              ),
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: AppColors.shadowPink,
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.iconBackgroundLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: -8,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor ?? AppColors.accentGreen,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistorySection(bool isDark) {
    return FutureBuilder<
        (HistoryModel?, List<SavedItem>, Map<String, PracticeCategory>)>(
      future: _dataFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data?.$1 == null) {
          return const SizedBox.shrink();
        }

        final history = snapshot.data!.$1!;
        final scorePercent =
            (history.yourScore / history.totalScore * 100).toStringAsFixed(0);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.cardBackgroundDark
                    : AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(24),
                boxShadow: isDark
                    ? []
                    : [
                        BoxShadow(
                          color: AppColors.shadowPink,
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.iconBackgroundLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.history,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recent Test',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            history.examTitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$scorePercent%',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'SCORE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSavedSection(bool isDark) {
    return FutureBuilder<
        (HistoryModel?, List<SavedItem>, Map<String, PracticeCategory>)>(
      future: _dataFuture,
      builder: (context, snapshot) {
        // Always show the saved section with default items
        final savedItems = snapshot.data?.$2 ?? [];

        // Default saved items to show
        final defaultItems = [
          SavedItem(id: 1, title: 'Saved Vocabulary', type: 'vocabulary'),
          SavedItem(id: 2, title: 'Saved Questions', type: 'questions'),
        ];

        final itemsToShow = savedItems.isNotEmpty ? savedItems : defaultItems;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 12),
            ...itemsToShow.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildSavedItem(
                    context,
                    icon: item.type == 'vocabulary'
                        ? Icons.bookmark
                        : Icons.help_outline,
                    title: item.title,
                    isDark: isDark,
                    onTap: () {
                      // TODO: Navigate to saved items
                    },
                  ),
                )),
          ],
        );
      },
    );
  }

  Widget _buildSavedItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: AppColors.shadowPink,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                  ),
                ),
              ],
            ),
            Icon(
              Icons.chevron_right,
              color: isDark
                  ? AppColors.textSecondaryDark.withValues(alpha: 0.5)
                  : AppColors.textSecondaryLight.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
