import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import 'exam_question_screen.dart';

class ExamOverviewScreen extends StatefulWidget {
  final List<FlatQuestion> questions;
  final Map<int, int> answers;
  final Set<int> flaggedQuestions;
  final List<PartModel> parts;
  final Function(int) onQuestionSelected;

  const ExamOverviewScreen({
    super.key,
    required this.questions,
    required this.answers,
    required this.flaggedQuestions,
    required this.parts,
    required this.onQuestionSelected,
  });

  @override
  State<ExamOverviewScreen> createState() => _ExamOverviewScreenState();
}

class _ExamOverviewScreenState extends State<ExamOverviewScreen> {
  int _selectedPartIndex = 0;
  int _selectedFilterIndex = 0; // 0: All, 1: Answered, 2: Unanswered

  List<String> get _partNames {
    // Extract unique part names
    return widget.parts.map((p) => p.name).toList();
  }

  List<FlatQuestion> get _filteredQuestions {
    // First filter by part
    List<FlatQuestion> filtered = widget.questions;
    
    if (_partNames.isNotEmpty && _selectedPartIndex < _partNames.length) {
      final selectedPart = _partNames[_selectedPartIndex];
      filtered = filtered.where((q) => q.partName == selectedPart).toList();
    }

    // Then filter by answered/unanswered
    if (_selectedFilterIndex == 1) {
      // Answered only
      filtered = filtered.where((q) => widget.answers.containsKey(q.question.id)).toList();
    } else if (_selectedFilterIndex == 2) {
      // Unanswered only
      filtered = filtered.where((q) => !widget.answers.containsKey(q.question.id)).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          // Safe area
          SizedBox(height: MediaQuery.of(context).padding.top),
          // Header
          _buildHeader(isDark),
          // Divider
          Container(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          // Part Tabs
          _buildPartTabs(isDark),
          // Filter Chips
          _buildFilterChips(isDark),
          // Question List
          Expanded(
            child: _buildQuestionList(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Row(
              children: [
                Icon(
                  Icons.chevron_left,
                  color: AppColors.tealAccent,
                  size: 24,
                ),
                const SizedBox(width: 4),
                Text(
                  'Back to Test',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.tealAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartTabs(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: List.generate(_partNames.length, (index) {
            final isSelected = _selectedPartIndex == index;
            // Shorten part names for display
            String displayName = _partNames[index];
            if (displayName.contains('・')) {
              // Japanese name like "文字・語彙" -> "Vocabulary"
              displayName = _getEnglishPartName(displayName);
            }

            return Padding(
              padding: const EdgeInsets.only(right: 24),
              child: GestureDetector(
                onTap: () => setState(() => _selectedPartIndex = index),
                child: Column(
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected
                            ? AppColors.tealAccent
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isSelected)
                      Container(
                        height: 3,
                        width: 40,
                        decoration: BoxDecoration(
                          color: AppColors.tealAccent,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  String _getEnglishPartName(String japaneseName) {
    // Map Japanese part names to English
    if (japaneseName.contains('文字') || japaneseName.contains('語彙')) {
      return 'Vocabulary';
    } else if (japaneseName.contains('文法')) {
      return 'Grammar';
    } else if (japaneseName.contains('読解')) {
      return 'Reading';
    } else if (japaneseName.contains('聴解')) {
      return 'Listening';
    }
    return japaneseName;
  }

  Widget _buildFilterChips(bool isDark) {
    final filters = ['All', 'Answered', 'Unanswered'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(filters.length, (index) {
          final isSelected = _selectedFilterIndex == index;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilterIndex = index),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.tealAccent
                      : (isDark ? AppColors.cardBackgroundDark : Colors.white),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.tealAccent
                        : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  ),
                ),
                child: Text(
                  filters[index],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildQuestionList(bool isDark) {
    final filteredQuestions = _filteredQuestions;

    if (filteredQuestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 48,
              color: isDark ? Colors.grey[700] : Colors.grey[300],
            ),
            const SizedBox(height: 16),
            Text(
              'No questions found',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filteredQuestions.length,
      itemBuilder: (context, index) {
        final flatQuestion = filteredQuestions[index];
        final questionIndex = widget.questions.indexOf(flatQuestion);
        final isAnswered = widget.answers.containsKey(flatQuestion.question.id);
        final selectedAnswer = widget.answers[flatQuestion.question.id];

        return _buildQuestionItem(
          questionNumber: questionIndex + 1,
          isAnswered: isAnswered,
          selectedAnswer: selectedAnswer,
          questionIndex: questionIndex,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildQuestionItem({
    required int questionNumber,
    required bool isAnswered,
    required int? selectedAnswer,
    required int questionIndex,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        widget.onQuestionSelected(questionIndex);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBackgroundDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Row(
          children: [
            // Question number and status
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Q$questionNumber',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.tealAccent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isAnswered ? 'ANSWERED' : 'PENDING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: isAnswered
                          ? AppColors.tealAccent
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    ),
                  ),
                ],
              ),
            ),
            // Answer options A, B, C, D
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: List.generate(4, (index) {
                  final answerNumber = index + 1;
                  final isSelected = selectedAnswer == answerNumber;
                  final label = ['A', 'B', 'C', 'D'][index];

                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.tealAccent
                            : (isDark
                                ? AppColors.cardBackgroundDark
                                : Colors.grey[50]),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.tealAccent
                              : (isDark
                                  ? AppColors.borderDark
                                  : Colors.grey[300]!),
                          width: isSelected ? 0 : 1,
                        ),
                      ),
                      child: Center(
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                size: 18,
                                color: Colors.white,
                              )
                            : Text(
                                label,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
