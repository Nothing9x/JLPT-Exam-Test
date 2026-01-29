import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/vocabulary_stats_service.dart';
import 'practice_question_screen.dart';

class PracticeSetupScreen extends StatefulWidget {
  final PracticeType practiceType;
  final int userLevel;
  final String languageCode;
  final String? token;

  const PracticeSetupScreen({
    super.key,
    required this.practiceType,
    required this.userLevel,
    required this.languageCode,
    this.token,
  });

  @override
  State<PracticeSetupScreen> createState() => _PracticeSetupScreenState();
}

class _PracticeSetupScreenState extends State<PracticeSetupScreen> {
  int _selectedQuestionCount = 10;
  bool _isPracticeMode = true;

  final List<int> _questionOptions = [5, 10, 15, 20];

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
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
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
                  const Text(
                    'Practice Setup',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),
            // Divider
            Container(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Selected Topic Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardBackgroundDark
                            : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color:
                                  AppColors.tealAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.menu_book,
                              color: AppColors.tealAccent,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SELECTED TOPIC',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.2,
                                    color: AppColors.tealAccent,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.practiceType.name,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimaryLight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'JLPT $_levelName • Vocabulary',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Number of Questions
                    Text(
                      'NUMBER OF QUESTIONS',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: _questionOptions
                          .map(
                            (count) => Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: count != _questionOptions.last ? 12 : 0,
                                ),
                                child: _buildQuestionCountButton(
                                  count: count,
                                  isSelected: _selectedQuestionCount == count,
                                  isDark: isDark,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 32),
                    // Mode
                    Text(
                      'MODE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        _buildModeCard(
                          icon: Icons.school,
                          title: 'Practice Mode',
                          subtitle: 'Instant feedback & explanations',
                          isSelected: _isPracticeMode,
                          isDark: isDark,
                          onTap: () => setState(() => _isPracticeMode = true),
                        ),
                        const SizedBox(height: 16),
                        _buildModeCard(
                          icon: Icons.timer,
                          title: 'Exam Mode',
                          subtitle: 'Timer enabled, no instant answers',
                          isSelected: !_isPracticeMode,
                          isDark: isDark,
                          onTap: () => setState(() => _isPracticeMode = false),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Bottom Button
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    (isDark ? AppColors.backgroundDark : AppColors.backgroundLight)
                        .withValues(alpha: 0.0),
                    (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
                  ],
                ),
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PracticeQuestionScreen(
                        practiceType: widget.practiceType,
                        userLevel: widget.userLevel,
                        questionCount: _selectedQuestionCount,
                        isPracticeMode: _isPracticeMode,
                        languageCode: widget.languageCode,
                        token: widget.token,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tealAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                  shadowColor: AppColors.tealAccent.withValues(alpha: 0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      'Start Now',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionCountButton({
    required int count,
    required bool isSelected,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () => setState(() => _selectedQuestionCount = count),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.tealAccent
              : (isDark ? AppColors.cardBackgroundDark : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.tealAccent
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.tealAccent.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isSelected
                  ? Colors.white
                  : (isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBackgroundDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected
                ? AppColors.tealAccent
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.tealAccent.withValues(alpha: 0.15)
                    : (isDark
                        ? AppColors.borderDark
                        : Colors.grey[100]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? AppColors.tealAccent
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
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
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.tealAccent,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
