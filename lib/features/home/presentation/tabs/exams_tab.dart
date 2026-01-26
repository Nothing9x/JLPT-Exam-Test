import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/services/exam_catalog_service.dart';
import 'test_detail_screen.dart';

class ExamsTab extends StatefulWidget {
  final String languageCode;
  final String? token;
  final VoidCallback? onNavigateToUpgrade;

  const ExamsTab({
    super.key,
    required this.languageCode,
    this.token,
    this.onNavigateToUpgrade,
  });

  @override
  State<ExamsTab> createState() => _ExamsTabState();
}

class _ExamsTabState extends State<ExamsTab> {
  int _selectedTabIndex = 0;
  Map<String, Map<int, int>> _examCounts = {}; // category -> {level -> count}
  bool _isLoading = true;

  final List<Map<String, dynamic>> examLevels = [
    {
      'level': 'N5',
      'levelNum': 5,
      'title': 'Basic Japanese',
      'subtitle': 'Fundamental Level',
      'passScore': '80/180',
    },
    {
      'level': 'N4',
      'levelNum': 4,
      'title': 'Elementary',
      'subtitle': 'Basic Application',
      'passScore': '90/180',
    },
    {
      'level': 'N3',
      'levelNum': 3,
      'title': 'Intermediate',
      'subtitle': 'Bridging Level',
      'passScore': '95/180',
    },
    {
      'level': 'N2',
      'levelNum': 2,
      'title': 'Pre-Advanced',
      'subtitle': 'Business Level',
      'passScore': '100/180',
    },
    {
      'level': 'N1',
      'levelNum': 1,
      'title': 'Advanced',
      'subtitle': 'Native Level',
      'passScore': '100/180',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadExamCounts();
  }

  Future<void> _loadExamCounts() async {
    setState(() => _isLoading = true);

    try {
      // Load exam counts for each category and level
      final counts = <String, Map<int, int>>{
        'JLPT': {},
        'NAT': {},
        'JFT': {},
      };

      for (var level in examLevels) {
        final levelNum = level['levelNum'] as int;

        // JLPT: Full Test (0) + Mini Test (1) + Skill Test (3)
        final jlptFullTests = await ExamCatalogService.getExamsByLevelAndType(
          level: levelNum,
          examType: 0,
        );
        final jlptMiniTests = await ExamCatalogService.getExamsByLevelAndType(
          level: levelNum,
          examType: 1,
        );
        final jlptSkillTests = await ExamCatalogService.getExamsByLevelAndType(
          level: levelNum,
          examType: 3,
        );
        counts['JLPT']![levelNum] = jlptFullTests.length + jlptMiniTests.length + jlptSkillTests.length;

        // NAT: NAT Test (2)
        final natTests = await ExamCatalogService.getExamsByLevelAndType(
          level: levelNum,
          examType: 2,
        );
        counts['NAT']![levelNum] = natTests.length;

        // JFT: For now, no specific exam type
        counts['JFT']![levelNum] = 0;
      }

      setState(() {
        _examCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading exam counts: $e');
      setState(() => _isLoading = false);
    }
  }

  String get _currentCategory {
    switch (_selectedTabIndex) {
      case 0:
        return 'JLPT';
      case 1:
        return 'NAT';
      case 2:
        return 'JFT';
      default:
        return 'JLPT';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Column(
        children: [
          // Header with Title and Filter
          Container(
            color: isDark ? AppColors.backgroundDark : Colors.white,
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Mock Test',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardBackgroundDark
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.tune,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tab Selector
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildTabButton(
                        label: 'JLPT',
                        isActive: _selectedTabIndex == 0,
                        isDark: isDark,
                        onTap: () => setState(() => _selectedTabIndex = 0),
                      ),
                      _buildTabButton(
                        label: 'NAT',
                        isActive: _selectedTabIndex == 1,
                        isDark: isDark,
                        onTap: () => setState(() => _selectedTabIndex = 1),
                      ),
                      _buildTabButton(
                        label: 'JFT',
                        isActive: _selectedTabIndex == 2,
                        isDark: isDark,
                        onTap: () => setState(() => _selectedTabIndex = 2),
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
            color: isDark
                ? AppColors.borderDark
                : AppColors.borderLight,
          ),
          // Exam List
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: List.generate(
                  examLevels.length,
                  (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildExamCard(
                      context,
                      level: examLevels[index]['level'],
                      levelNum: examLevels[index]['levelNum'],
                      title: examLevels[index]['title'],
                      subtitle: examLevels[index]['subtitle'],
                      passScore: examLevels[index]['passScore'],
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(right: 32),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
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
  }

  Widget _buildExamCard(
    BuildContext context, {
    required String level,
    required int levelNum,
    required String title,
    required String subtitle,
    required String passScore,
    required bool isDark,
  }) {
    // Get exam count for this level and category
    final examCount = _examCounts[_currentCategory]?[levelNum] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TestDetailScreen(
              level: level,
              category: _currentCategory,
              languageCode: widget.languageCode,
              token: widget.token,
              onNavigateToUpgrade: widget.onNavigateToUpgrade,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBackgroundDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Level and Arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Level Badge
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.tealAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          level,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.tealAccent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title and Subtitle
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
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
                  ],
                ),
                // Arrow Icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardBackgroundDark
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
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
            // Questions and Pass Score
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Questions
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.tealAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.quiz,
                        size: 18,
                        color: AppColors.tealAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '$examCount Exams',
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
                // Pass Score
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        size: 18,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Pass: $passScore',
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
          ],
        ),
      ),
    );
  }
}
