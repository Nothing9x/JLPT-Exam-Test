import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/exam_service.dart';
import '../../data/services/exam_catalog_service.dart';
import '../screens/exam_start_screen.dart';

class TestDetailScreen extends StatefulWidget {
  final String level;
  final String category; // JLPT, NAT, or JFT
  final String languageCode;
  final String? token;
  final VoidCallback? onNavigateToUpgrade;

  const TestDetailScreen({
    super.key,
    required this.level,
    required this.category,
    required this.languageCode,
    this.token,
    this.onNavigateToUpgrade,
  });

  @override
  State<TestDetailScreen> createState() => _TestDetailScreenState();
}

class _TestDetailScreenState extends State<TestDetailScreen> {
  int _selectedTabIndex = 0;
  late ExamService _examService;
  late Future<Map<String, dynamic>> _dataFuture;

  @override
  void initState() {
    super.initState();
    _examService = ExamService(token: widget.token ?? '');
    _dataFuture = _loadData();
  }

  Future<Map<String, dynamic>> _loadData() async {
    final levelMap = {'N5': 5, 'N4': 4, 'N3': 3, 'N2': 2, 'N1': 1};
    final level = levelMap[widget.level] ?? 1;

    final userProfile = await _examService.getUserProfile();

    // Load exams from the external catalog based on category and selected tab
    int examType;

    if (widget.category == 'JLPT') {
      // JLPT: Full Test (0), Mini Test (1), Skill Test (3)
      switch (_selectedTabIndex) {
        case 0:
          examType = 0; // Full Test
          break;
        case 1:
          examType = 1; // Mini Test
          break;
        case 2:
          examType = 3; // Skill Test
          break;
        default:
          examType = 0;
      }
    } else if (widget.category == 'NAT') {
      // NAT: Only NAT Test (2)
      examType = 2;
    } else if (widget.category == 'OFFICIAL') {
      // Official Exam (4) - Used for Practice Test feature
      switch (_selectedTabIndex) {
        case 0:
          examType = 4; // Official Exam
          break;
        case 1:
          examType = 5; // Official Skill Exam
          break;
        default:
          examType = 4;
      }
    } else {
      // JFT or other categories
      examType = 0;
    }

    debugPrint('========== TEST DETAIL SCREEN DEBUG ==========');
    debugPrint('Category: ${widget.category}');
    debugPrint('Loading exams for Level: ${widget.level} (numeric: $level)');
    debugPrint('Selected Tab Index: $_selectedTabIndex');
    debugPrint('Selected Exam Type: $examType');
    debugPrint('=============================================');

    final exams = await ExamCatalogService.getExamsByLevelAndType(
      level: level,
      examType: examType,
    );

    debugPrint('Loaded ${exams.length} exams from catalog');
    for (var i = 0; i < exams.length && i < 5; i++) {
      debugPrint('Exam ${i + 1}: ID=${exams[i].id}, ExternalID=${exams[i].externalId}, Title=${exams[i].title}, Questions=${exams[i].questionCount}');
    }
    if (exams.length > 5) {
      debugPrint('... and ${exams.length - 5} more exams');
    }

    final examHistory = await _examService.getExamHistory();

    return {
      'userProfile': userProfile,
      'exams': exams,
      'examHistory': examHistory,
    };
  }

  @override
  void dispose() {
    _examService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: AppColors.tealAccent,
              ),
            );
          }

          final userProfile = snapshot.data?['userProfile'] as UserProfile?;
          final exams = snapshot.data?['exams'] as List<ExamModel>? ?? [];
          final examHistory = snapshot.data?['examHistory'] as List<ExamHistoryModel>? ?? [];

          return Column(
            children: [
              // Header with Back Button
              Container(
                color: isDark ? AppColors.backgroundDark : Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 16, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
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
                        Text(
                          '${widget.category} ${widget.level}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 40),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Tab Selector - Different tabs based on category
                    if (widget.category == 'JLPT')
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTestTypeTab(
                              label: 'Full Test',
                              isActive: _selectedTabIndex == 0,
                              isDark: isDark,
                              onTap: () => setState(() {
                                _selectedTabIndex = 0;
                                _dataFuture = _loadData();
                              }),
                            ),
                            const SizedBox(width: 24),
                            _buildTestTypeTab(
                              label: 'Mini Test',
                              isActive: _selectedTabIndex == 1,
                              isDark: isDark,
                              onTap: () => setState(() {
                                _selectedTabIndex = 1;
                                _dataFuture = _loadData();
                              }),
                            ),
                            const SizedBox(width: 24),
                            _buildTestTypeTab(
                              label: 'Skill Test',
                              isActive: _selectedTabIndex == 2,
                              isDark: isDark,
                              onTap: () => setState(() {
                                _selectedTabIndex = 2;
                                _dataFuture = _loadData();
                              }),
                            ),
                          ],
                        ),
                      )
                    else if (widget.category == 'NAT')
                      // NAT has only one type, show no tabs or a single "NAT Test" label
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'NAT Test',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.tealAccent,
                          ),
                        ),
                      )
                    else if (widget.category == 'OFFICIAL')
                      // Official has two types: Official Exam (4) and Official Skill Exam (5)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildTestTypeTab(
                              label: 'Official Exam',
                              isActive: _selectedTabIndex == 0,
                              isDark: isDark,
                              onTap: () => setState(() {
                                _selectedTabIndex = 0;
                                _dataFuture = _loadData();
                              }),
                            ),
                            const SizedBox(width: 24),
                            _buildTestTypeTab(
                              label: 'Skill Exam',
                              isActive: _selectedTabIndex == 1,
                              isDark: isDark,
                              onTap: () => setState(() {
                                _selectedTabIndex = 1;
                                _dataFuture = _loadData();
                              }),
                            ),
                          ],
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
              // Test List
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: List.generate(
                      exams.length,
                      (index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildTestCard(
                          context,
                          exam: exams[index],
                          testNumber: index + 1,
                          userProfile: userProfile,
                          examHistory: examHistory,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTestTypeTab({
    required String label,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
              color: isActive
                  ? AppColors.tealAccent
                  : (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight),
            ),
          ),
          const SizedBox(height: 8),
          if (isActive)
            Container(
              height: 3,
              width: 60,
              decoration: BoxDecoration(
                color: AppColors.tealAccent,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTestCard(
    BuildContext context, {
    required ExamModel exam,
    required int testNumber,
    required UserProfile? userProfile,
    required List<ExamHistoryModel> examHistory,
    required bool isDark,
  }) {
    // Check if user has taken this test
    final testResult = examHistory.firstWhere(
      (history) => history.examId == exam.id,
      orElse: () => ExamHistoryModel(
        id: 0,
        examId: 0,
        examTitle: '',
        yourScore: 0,
        totalScore: 0,
        isPassed: false,
        submittedAt: '',
      ),
    );

    final isCompleted = testResult.examId == exam.id;
    final userIsPremium = userProfile?.isPremium ?? false;
    
    // Free users can only access first 2 tests
    final isLocked = !userIsPremium && testNumber > 2;

    return Container(
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
          // Header with Title and Score Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Test No. $testNumber',
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
                    'Standard Mock Exam',
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
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${testResult.yourScore}/${testResult.totalScore}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                )
              else if (isLocked)
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardBackgroundDark
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.lock,
                    size: 16,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                )
              else
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.tealAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.play_arrow,
                    size: 16,
                    color: AppColors.tealAccent,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Divider
          Container(
            height: 1,
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
          const SizedBox(height: 12),
          // Duration and Points
          Row(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 18,
                    color: isDark
                        ? AppColors.textSecondaryDark.withValues(alpha: 0.6)
                        : AppColors.textSecondaryLight.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${exam.time} mins',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 18,
                    color: isDark
                        ? AppColors.textSecondaryDark.withValues(alpha: 0.6)
                        : AppColors.textSecondaryLight.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${exam.totalScore} pts',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action Button
          SizedBox(
            width: double.infinity,
            child: isCompleted
                ? OutlinedButton.icon(
                    onPressed: () {
                      // TODO: Retry exam
                    },
                    icon: const Icon(Icons.replay, size: 18),
                    label: const Text('Retry Test'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: BorderSide(
                        color: AppColors.tealAccent.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  )
                : isLocked
                    ? OutlinedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          Future.delayed(const Duration(milliseconds: 100), () {
                            widget.onNavigateToUpgrade?.call();
                          });
                        },
                        icon: const Icon(Icons.lock, size: 18),
                        label: const Text('Unlock'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: isDark
                              ? AppColors.cardBackgroundDark
                              : Colors.grey[50],
                          side: BorderSide(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    : ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ExamStartScreen(
                                exam: exam,
                                level: widget.level,
                                testNumber: testNumber,
                                token: widget.token,
                                userName: userProfile?.fullName,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow, size: 18),
                        label: const Text('Start Exam'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tealAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: AppColors.tealAccent.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
