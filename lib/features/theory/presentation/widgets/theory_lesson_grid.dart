import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/lesson_model.dart';

/// Grid of lesson cards
class TheoryLessonGrid<T> extends StatelessWidget {
  final List<LessonModel<T>> lessons;
  final String Function(T item) getDisplayCharacter;
  final void Function(LessonModel<T> lesson) onLessonTap;

  const TheoryLessonGrid({
    super.key,
    required this.lessons,
    required this.getDisplayCharacter,
    required this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: lessons.length,
      itemBuilder: (context, index) {
        final lesson = lessons[index];
        final displayChar = lesson.firstItem != null
            ? getDisplayCharacter(lesson.firstItem as T)
            : '';

        return _LessonCard(
          lessonNumber: lesson.lessonNumber,
          displayCharacter: displayChar,
          isLocked: lesson.isLocked,
          onTap: () => onLessonTap(lesson),
        );
      },
    );
  }
}

class _LessonCard extends StatelessWidget {
  final int lessonNumber;
  final String displayCharacter;
  final bool isLocked;
  final VoidCallback onTap;

  const _LessonCard({
    required this.lessonNumber,
    required this.displayCharacter,
    required this.isLocked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Column(
        children: [
          // Card
          Expanded(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Main card
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardBackgroundDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: isLocked
                        ? null
                        : Border.all(
                            color:
                                AppColors.accentIndigo.withValues(alpha: 0.3),
                            width: 1,
                          ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _buildCharacterBox(isDark),
                  ),
                ),
                // Lock badge
                if (isLocked)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: _buildLockBadge(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Lesson label
          Text(
            'Lesson $lessonNumber',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isLocked ? FontWeight.normal : FontWeight.w600,
              color: isLocked
                  ? (isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight)
                  : (isDark
                      ? AppColors.textPrimaryDark
                      : AppColors.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterBox(bool isDark) {
    final isActive = !isLocked;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF818CF8), // Indigo light
                  Color(0xFF4F46E5), // Indigo
                ],
              )
            : null,
        color: isActive ? null : Colors.grey[400],
        borderRadius: BorderRadius.circular(10),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.accentIndigo.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: Text(
          displayCharacter.isNotEmpty ? displayCharacter : '?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: isActive
                ? const [
                    Shadow(
                      color: Colors.black26,
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildLockBadge() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.lock,
          size: 10,
          color: Colors.white,
        ),
      ),
    );
  }
}
