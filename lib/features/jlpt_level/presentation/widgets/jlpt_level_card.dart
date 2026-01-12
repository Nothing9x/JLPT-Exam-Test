import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/jlpt_level_model.dart';

class JlptLevelCard extends StatelessWidget {
  final JlptLevelModel level;
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const JlptLevelCard({
    super.key,
    required this.level,
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark
                  ? AppColors.tealAccent.withValues(alpha: 0.15)
                  : const Color(0xFFE0F7F4))
              : (isDark ? AppColors.cardBackgroundDark : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.tealAccent : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Emoji container
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark
                    ? Color(level.colorValue).withValues(alpha: 0.2)
                    : Color(level.colorValue),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  level.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppColors.tealAccent : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? AppColors.tealAccent
                      : (isDark ? AppColors.borderDark : const Color(0xFFD1D5DB)),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
