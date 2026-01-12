import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/language_model.dart';

class LanguageItemCard extends StatelessWidget {
  final LanguageModel language;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguageItemCard({
    super.key,
    required this.language,
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
          color: isDark ? AppColors.cardBackgroundDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (isDark ? AppColors.matchaDark : AppColors.matchaGreen)
                : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            // Flag container
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark
                        ? AppColors.primaryDark.withValues(alpha: 0.3)
                        : const Color(0xFFEEF2FF))
                    : (isDark ? AppColors.borderDark : const Color(0xFFF9FAFB)),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? (isDark ? AppColors.primaryDark : const Color(0xFFE0E7FF))
                      : (isDark ? AppColors.borderDark : const Color(0xFFF3F4F6)),
                  width: 1,
                ),
              ),
              child: Center(
                child: Text(
                  language.flagEmoji,
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Language info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? (isDark
                              ? Colors.white
                              : AppColors.textPrimaryLight)
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : const Color(0xFF334155)),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    language.nativeName,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            // Check icon for selected item
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.matchaDark : AppColors.matchaGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
