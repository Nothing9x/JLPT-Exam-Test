import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../data/services/exam_service.dart';
import 'exam_question_screen.dart';

class ExamStartScreen extends StatefulWidget {
  final ExamModel exam;
  final String level;
  final int testNumber;
  final String? token;
  final String? userName;

  const ExamStartScreen({
    super.key,
    required this.exam,
    required this.level,
    required this.testNumber,
    this.token,
    this.userName,
  });

  @override
  State<ExamStartScreen> createState() => _ExamStartScreenState();
}

class _ExamStartScreenState extends State<ExamStartScreen> {
  ExamDetailModel? _preloadedExamDetail;
  bool _isPreloading = true;

  @override
  void initState() {
    super.initState();
    _preloadExamData();
  }

  Future<void> _preloadExamData() async {
    try {
      // Use externalId to query backend (server updated to use externalId)
      final examId = widget.exam.externalId ?? widget.exam.id;

      // Log exam information
      debugPrint('========== EXAM START SCREEN DEBUG ==========');
      debugPrint('Exam ID (from catalog): ${widget.exam.id}');
      debugPrint('Exam External ID: ${widget.exam.externalId}');
      debugPrint('Exam Title: ${widget.exam.title}');
      debugPrint('Exam Type: ${widget.exam.examType}');
      debugPrint('Exam Level: ${widget.exam.level}');
      debugPrint('Exam Time: ${widget.exam.time}');
      debugPrint('Exam Total Score: ${widget.exam.totalScore}');
      debugPrint('Exam Pass Score: ${widget.exam.passScore}');
      debugPrint('Exam Question Count (from catalog): ${widget.exam.questionCount}');
      debugPrint('Query ID to backend: $examId');
      debugPrint('Query URL: ${ApiConstants.baseUrl}/exams/$examId');
      debugPrint('=============================================');

      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/exams/$examId'),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      debugPrint('Backend Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        debugPrint('Backend Response Data: ${json.encode(data)}');

        if (mounted) {
          setState(() {
            _preloadedExamDetail = ExamDetailModel.fromJson(data);

            // Detailed logging about the exam
            debugPrint('========== EXAM DETAIL LOADED ==========');
            debugPrint('Total Questions: ${_preloadedExamDetail!.getTotalQuestionCount()}');
            debugPrint('Number of Parts: ${_preloadedExamDetail!.parts.length}');
            for (var i = 0; i < _preloadedExamDetail!.parts.length; i++) {
              final part = _preloadedExamDetail!.parts[i];
              debugPrint('Part ${i + 1}: ${part.name}');
              debugPrint('  - Sections: ${part.sections.length}');
              int partQuestions = 0;
              for (var section in part.sections) {
                for (var group in section.questionGroups) {
                  partQuestions += group.questions.length;
                }
              }
              debugPrint('  - Total Questions in Part: $partQuestions');
            }
            debugPrint('========================================');

            _isPreloading = false;
          });
        }
      } else {
        debugPrint('Backend Error Response: ${response.body}');
        // Failed to preload, but allow user to continue
        if (mounted) {
          setState(() {
            _isPreloading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Exception during preload: $e');
      // Error during preload, but allow user to continue
      if (mounted) {
        setState(() {
          _isPreloading = false;
        });
      }
    }
  }

  void _startExam() {
    // Allow starting exam even if preloading failed
    // The ExamQuestionScreen will load the data if not preloaded
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamQuestionScreen(
          exam: widget.exam,
          level: widget.level,
          token: widget.token,
          userName: widget.userName,
          preloadedExamDetail: _preloadedExamDetail,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pass score is now an integer from the model
    final passScoreValue = widget.exam.passScore;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Column(
        children: [
          // Header with Back Button
          Container(
            color: isDark ? AppColors.backgroundDark : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardBackgroundDark
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Test No. ${widget.testNumber}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                  ),
                ],
              ),
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
                children: [
                  const SizedBox(height: 16),
                  // Level Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.tealAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.tealAccent.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.school,
                          size: 16,
                          color: AppColors.tealAccent,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'JLPT ${widget.level} SIMULATION',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: AppColors.tealAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Test Title
                  Text(
                    widget.exam.title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  // Description
                  Text(
                    'Comprehensive assessment of Vocabulary, Grammar, and Reading.',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  // Stats Card - 4 items in 2x2 grid
                  Container(
                    padding: const EdgeInsets.all(24),
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
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 4),
                              ),
                            ],
                    ),
                    child: Column(
                      children: [
                        // First Row: Time and Questions
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.schedule,
                                iconColor: AppColors.tealAccent,
                                iconBgColor: AppColors.tealAccent.withValues(
                                  alpha: 0.1,
                                ),
                                value: _preloadedExamDetail != null
                                    ? '${_preloadedExamDetail!.time}'
                                    : '${widget.exam.time}',
                                label: 'MINUTES',
                                isDark: isDark,
                                isLoading: _isPreloading,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 80,
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.quiz_outlined,
                                iconColor: Colors.blue,
                                iconBgColor: Colors.blue.withValues(alpha: 0.1),
                                value: _preloadedExamDetail != null
                                    ? '${_preloadedExamDetail!.getTotalQuestionCount()}'
                                    : '${widget.exam.questionCount}',
                                label: 'QUESTIONS',
                                isDark: isDark,
                                isLoading: _isPreloading,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          height: 1,
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                        const SizedBox(height: 20),
                        // Second Row: Pass Score and Max Score
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.check_circle_outline,
                                iconColor: Colors.green,
                                iconBgColor: Colors.green.withValues(
                                  alpha: 0.1,
                                ),
                                value: _preloadedExamDetail != null
                                    ? '${_preloadedExamDetail!.passScore}'
                                    : '$passScoreValue',
                                label: 'PASS SCORE',
                                isDark: isDark,
                                isLoading: _isPreloading,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 80,
                              color: isDark
                                  ? AppColors.borderDark
                                  : AppColors.borderLight,
                            ),
                            Expanded(
                              child: _buildStatItem(
                                icon: Icons.emoji_events,
                                iconColor: Colors.amber[600]!,
                                iconBgColor: Colors.amber.withValues(
                                  alpha: 0.1,
                                ),
                                value: _preloadedExamDetail != null
                                    ? '${_preloadedExamDetail!.score}'
                                    : '${widget.exam.totalScore}',
                                label: 'MAX SCORE',
                                isDark: isDark,
                                isLoading: _isPreloading,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Test Rules
                  Container(
                    padding: const EdgeInsets.all(20),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: AppColors.tealAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Test Rules',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildRuleItem(
                          'The test consists of three sections: Vocabulary, Grammar, and Reading. Each section is timed.',
                          isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildRuleItem(
                          'You cannot pause the timer once the test begins. Ensure you have a stable internet connection.',
                          isDark,
                        ),
                        const SizedBox(height: 12),
                        _buildRuleItem(
                          'Results will be calculated immediately upon submission. Review answers is available afterwards.',
                          isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 120), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      // Start Now Button
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppColors.backgroundDark.withValues(alpha: 0),
                    AppColors.backgroundDark,
                  ]
                : [
                    AppColors.backgroundLight.withValues(alpha: 0),
                    AppColors.backgroundLight,
                  ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isPreloading ? null : _startExam,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tealAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppColors.tealAccent.withValues(alpha: 0.3),
                disabledBackgroundColor: AppColors.tealAccent.withValues(
                  alpha: 0.5,
                ),
              ),
              child: _isPreloading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Loading...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
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
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String value,
    required String label,
    required bool isDark,
    bool isLoading = false,
  }) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: iconBgColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, size: 28, color: iconColor),
        ),
        const SizedBox(height: 12),
        isLoading
            ? SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              )
            : Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight,
                ),
              ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
            color: isDark
                ? AppColors.textSecondaryDark.withValues(alpha: 0.7)
                : AppColors.textSecondaryLight.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildRuleItem(String text, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6),
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: AppColors.tealAccent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }
}
