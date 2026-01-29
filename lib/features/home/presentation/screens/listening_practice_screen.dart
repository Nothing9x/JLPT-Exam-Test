import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/vocabulary_stats_service.dart';
import '../../data/services/practice_question_service.dart';
import 'practice_setup_screen.dart';

class ListeningPracticeScreen extends StatefulWidget {
  final String languageCode;
  final String? token;
  final int userLevel; // 1-5 for N1-N5

  const ListeningPracticeScreen({
    super.key,
    required this.languageCode,
    this.token,
    required this.userLevel,
  });

  @override
  State<ListeningPracticeScreen> createState() =>
      _ListeningPracticeScreenState();
}

class _ListeningPracticeScreenState extends State<ListeningPracticeScreen> {
  late VocabularyStatsService _service;
  late PracticeQuestionService _practiceService;
  late Future<Map<String, CategoryWithTypes>> _dataFuture;
  Set<int> _practicedQuestionIds = {};
  bool _loadingProgress = true;

  @override
  void initState() {
    super.initState();
    _service = VocabularyStatsService();
    _practiceService = PracticeQuestionService(token: widget.token);
    _dataFuture = _service.getAllCategories();
    _loadPracticedQuestions();
  }

  Future<void> _loadPracticedQuestions() async {
    if (widget.token != null) {
      final practicedIds = await _practiceService.getPracticedQuestionIds();
      setState(() {
        _practicedQuestionIds = practicedIds;
        _loadingProgress = false;
      });
    } else {
      setState(() {
        _loadingProgress = false;
      });
    }
  }

  @override
  void dispose() {
    _service.dispose();
    _practiceService.dispose();
    super.dispose();
  }

  String get _levelName {
    switch (widget.userLevel) {
      case 1:
        return 'N1';
      case 2:
        return 'N2';
      case 3:
        return 'N3';
      case 4:
        return 'N4';
      case 5:
        return 'N5';
      default:
        return 'N3';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: isDark ? AppColors.backgroundDark : Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button and streak
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.cardBackgroundDark
                                : Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.arrow_back,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            size: 24,
                          ),
                        ),
                      ),
                      // Streak indicator
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department,
                              size: 18,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '12',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.orange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Title
                  Text(
                    'JLPT $_levelName PREPARATION',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Listening',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            // Divider
            Container(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            // Practice types list
            Expanded(
              child: FutureBuilder<Map<String, CategoryWithTypes>>(
                future: _dataFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: AppColors.tealAccent,
                      ),
                    );
                  }

                  final categories = snapshot.data ?? {};
                  final listeningCategory = categories['LISTENING'];

                  if (listeningCategory == null ||
                      listeningCategory.types.isEmpty) {
                    return Center(
                      child: Text(
                        'No listening types available',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    );
                  }

                  // Filter out types with zero questions for user's level
                  final types = listeningCategory.types.where((type) {
                    final questionCount = type.byLevel[widget.userLevel] ?? type.totalQuestions;
                    return questionCount > 0;
                  }).toList();

                  if (types.isEmpty) {
                    return Center(
                      child: Text(
                        'No listening types available for your level',
                        style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: types.length,
                    itemBuilder: (context, index) {
                      final type = types[index];
                      final questionCount =
                          type.byLevel[widget.userLevel] ?? type.totalQuestions;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPracticeTypeCard(
                          context,
                          type: type,
                          questionCount: questionCount,
                          isDark: isDark,
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPracticeTypeCard(
    BuildContext context, {
    required PracticeType type,
    required int questionCount,
    required bool isDark,
  }) {
    // Calculate real progress based on practiced questions
    final completedQuestions = _loadingProgress ? 0 : (_practicedQuestionIds.length * 0.1).round().clamp(0, questionCount);
    final progress = questionCount > 0 ? completedQuestions / questionCount : 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PracticeSetupScreen(
              practiceType: type,
              userLevel: widget.userLevel,
              languageCode: widget.languageCode,
              token: widget.token,
            ),
          ),
        );
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$questionCount Questions',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.tealAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 24,
                    color: AppColors.tealAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    Text(
                      '$completedQuestions/$questionCount',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.tealAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: isDark
                        ? AppColors.borderDark
                        : AppColors.borderLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.tealAccent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
