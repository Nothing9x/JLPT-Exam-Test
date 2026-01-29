import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/history_service.dart';
import '../../data/services/practice_stats_service.dart';
import '../screens/vocabulary_practice_screen.dart';
import '../screens/grammar_practice_screen.dart';
import '../screens/reading_practice_screen.dart';
import '../screens/listening_practice_screen.dart';

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
  late Future<(HistoryModel?, List<SavedItem>, Map<String, PracticeCategory>)> _dataFuture;

  @override
  void initState() {
    super.initState();
    _historyService = HistoryService(token: widget.token ?? '');
    _practiceStatsService = PracticeStatsService();
    _dataFuture = _fetchData();
  }

  Future<(HistoryModel?, List<SavedItem>, Map<String, PracticeCategory>)> _fetchData() async {
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
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Bar with Welcome and Profile
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'JLPT N3',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
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
                            color: AppColors.tealAccent.withValues(alpha: 0.2),
                            width: 2,
                          ),
                          image: const DecorationImage(
                            image: NetworkImage(
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuBZ4ByL1eYP9Sw1FKYrlKVKL2ORO2GiisXn6vXLTIKgQ4FHdrSrUnIMkcxFvat7ScAiDCpYcanECbhN37fXyWaMWQIEeka3HLQVQjl-3N2PsC8w_OZi7LbjbUvId-PxOsuMO_5iUPf-QbEjdQ9cQfvuiKhFv_Nj5omHcJXgOi9e_As8gkL6Pk6FjunoU2dFKfgdGoDSdg6AMzcJMbUUXOYpeW7gNO-bpLPeZs9okQ1WRu0kIv1hSYpgakKQkZVfeWJwGgskHSugjg',
                            ),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Promotional Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.cardBackgroundDark
                          : AppColors.cardBackgroundLight,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.tealAccent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'LIMITED TIME',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: AppColors.tealAccent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          '50% OFF Premium',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Master N3 grammar with unlimited mock exams.',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Navigate to upgrade
                          },
                          icon: const Icon(Icons.arrow_forward, size: 18),
                          label: const Text('Upgrade Now'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.tealAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Practice Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: const Text(
                    'Practice',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Practice Stats Grid
                FutureBuilder<(HistoryModel?, List<SavedItem>, Map<String, PracticeCategory>)>(
                  future: _dataFuture,
                  builder: (context, snapshot) {
                    final practiceStats = snapshot.data?.$3 ?? {};

                    // Assume user level is N3 (level 3) for now
                    // TODO: Get actual user level from profile
                    const userLevel = 3;

                    final vocabularyCount = practiceStats['VOCABULARY']?.questionsByLevel[userLevel] ?? 0;
                    final grammarCount = practiceStats['GRAMMAR']?.questionsByLevel[userLevel] ?? 0;
                    final listeningCount = practiceStats['LISTENING']?.questionsByLevel[userLevel] ?? 0;
                    final readingCount = practiceStats['READING']?.questionsByLevel[userLevel] ?? 0;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1,
                        children: [
                          _buildPracticeCard(
                            context,
                            icon: Icons.menu_book,
                            title: 'Vocabulary',
                            subtitle: vocabularyCount > 0
                              ? '$vocabularyCount Questions'
                              : 'Loading...',
                            isDark: isDark,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => VocabularyPracticeScreen(
                                    languageCode: widget.languageCode,
                                    token: widget.token,
                                    userLevel: userLevel,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildPracticeCard(
                            context,
                            icon: Icons.edit,
                            title: 'Grammar',
                            subtitle: grammarCount > 0
                              ? '$grammarCount Questions'
                              : 'Loading...',
                            isDark: isDark,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => GrammarPracticeScreen(
                                    languageCode: widget.languageCode,
                                    token: widget.token,
                                    userLevel: userLevel,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildPracticeCard(
                            context,
                            icon: Icons.headphones,
                            title: 'Listening',
                            subtitle: listeningCount > 0
                              ? '$listeningCount Questions'
                              : 'Loading...',
                            isDark: isDark,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ListeningPracticeScreen(
                                    languageCode: widget.languageCode,
                                    token: widget.token,
                                    userLevel: userLevel,
                                  ),
                                ),
                              );
                            },
                          ),
                          _buildPracticeCard(
                            context,
                            icon: Icons.article,
                            title: 'Reading',
                            subtitle: readingCount > 0
                              ? '$readingCount Questions'
                              : 'Loading...',
                            isDark: isDark,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ReadingPracticeScreen(
                                    languageCode: widget.languageCode,
                                    token: widget.token,
                                    userLevel: userLevel,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                // Exam Prep Section
                Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 12),
                  child: const Text(
                    'Exam Prep',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                SizedBox(
                  height: 160,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    children: [
                      _buildExamPrepCard(
                        context,
                        icon: Icons.school,
                        title: 'Theory',
                        subtitle: 'Core Concepts',
                        isDark: isDark,
                      ),
                      _buildExamPrepCard(
                        context,
                        icon: Icons.quiz,
                        title: 'Mock Exams',
                        subtitle: 'Full Tests',
                        isDark: isDark,
                        onTap: widget.onMockExamsPressed,
                      ),
                      _buildExamPrepCard(
                        context,
                        icon: Icons.lightbulb,
                        title: 'Tips',
                        subtitle: 'Strategy',
                        isDark: isDark,
                      ),
                      _buildExamPrepCard(
                        context,
                        icon: Icons.notifications_active,
                        title: 'Reminders',
                        subtitle: 'Schedule',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // History Section
                FutureBuilder<(HistoryModel?, List<SavedItem>, Map<String, PracticeCategory>)>(
                  future: _dataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.$1 != null) {
                      final history = snapshot.data!.$1!;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'History',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.cardBackgroundDark
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isDark
                                      ? AppColors.borderDark
                                      : AppColors.borderLight,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: AppColors.tealAccent
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.history,
                                          color: AppColors.tealAccent,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Recent Test',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            history.examTitle,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? AppColors
                                                      .textSecondaryDark
                                                  : AppColors
                                                      .textSecondaryLight,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        '${(history.yourScore / history.totalScore * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.tealAccent,
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
                                              ? AppColors
                                                  .textSecondaryDark
                                              : AppColors
                                                  .textSecondaryLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                // Saved Section
                FutureBuilder<(HistoryModel?, List<SavedItem>, Map<String, PracticeCategory>)>(
                  future: _dataFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.$2.isNotEmpty) {
                      final savedItems = snapshot.data!.$2;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Saved',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ...List.generate(
                              savedItems.length,
                              (index) => Column(
                                children: [
                                  _buildSavedItem(
                                    context,
                                    icon: savedItems[index].type ==
                                            'vocabulary'
                                        ? Icons.bookmark
                                        : Icons.help,
                                    title: savedItems[index].title,
                                    subtitle: savedItems[index].subtitle,
                                    isDark: isDark,
                                  ),
                                  if (index < savedItems.length - 1)
                                    const SizedBox(height: 12),
                                ],
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPracticeCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {
        // TODO: Navigate to practice questions
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBackgroundDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.tealAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: AppColors.tealAccent,
                size: 24,
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
      ),
    );
  }

  Widget _buildExamPrepCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () {},
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBackgroundDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: AppColors.tealAccent,
              size: 32,
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
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
      ),
    );
  }

  Widget _buildSavedItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to saved items
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBackgroundDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  size: 24,
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ),
                  ],
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
