import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/tts_service.dart';
import '../../../../models/vocabulary_model.dart';
import '../../../../models/kanji_model.dart';
import '../../../../models/grammar_model.dart';
import '../../../../models/lesson_model.dart';

/// Enum for lesson type
enum LessonType { kanji, vocabulary, grammar }

/// Generic Lesson Detail Screen - Shows lesson items with TTS
class LessonDetailScreen extends StatefulWidget {
  final LessonType type;
  final String levelTitle;
  final int lessonNumber;
  final List<dynamic> items;

  const LessonDetailScreen({
    super.key,
    required this.type,
    required this.levelTitle,
    required this.lessonNumber,
    required this.items,
  });

  /// Factory constructor for Kanji lessons
  factory LessonDetailScreen.kanji({
    Key? key,
    required LessonModel<KanjiModel> lesson,
    required String levelTitle,
  }) {
    return LessonDetailScreen(
      key: key,
      type: LessonType.kanji,
      levelTitle: levelTitle,
      lessonNumber: lesson.lessonNumber,
      items: lesson.items,
    );
  }

  /// Factory constructor for Vocabulary lessons
  factory LessonDetailScreen.vocabulary({
    Key? key,
    required LessonModel<VocabularyModel> lesson,
    required String levelTitle,
  }) {
    return LessonDetailScreen(
      key: key,
      type: LessonType.vocabulary,
      levelTitle: levelTitle,
      lessonNumber: lesson.lessonNumber,
      items: lesson.items,
    );
  }

  /// Factory constructor for Grammar lessons
  factory LessonDetailScreen.grammar({
    Key? key,
    required LessonModel<GrammarModel> lesson,
    required String levelTitle,
  }) {
    return LessonDetailScreen(
      key: key,
      type: LessonType.grammar,
      levelTitle: levelTitle,
      lessonNumber: lesson.lessonNumber,
      items: lesson.items,
    );
  }

  @override
  State<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends State<LessonDetailScreen> {
  final TtsService _ttsService = TtsService();
  final Set<int> _favoriteIds = {};
  String? _speakingWord;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    await _ttsService.initialize();
    _ttsService.onSpeakingStart = () {
      if (mounted) setState(() {});
    };
    _ttsService.onSpeakingComplete = () {
      if (mounted) {
        setState(() {
          _speakingWord = null;
        });
      }
    };
  }

  @override
  void dispose() {
    _ttsService.stop();
    super.dispose();
  }

  String get _typeLabel {
    switch (widget.type) {
      case LessonType.kanji:
        return 'Kanji';
      case LessonType.vocabulary:
        return 'Vocabulary';
      case LessonType.grammar:
        return 'Grammar';
    }
  }

  Future<void> _speakWord(String word) async {
    setState(() {
      _speakingWord = word;
    });
    await _ttsService.speak(word);
  }

  void _toggleFavorite(int id) {
    setState(() {
      if (_favoriteIds.contains(id)) {
        _favoriteIds.remove(id);
      } else {
        _favoriteIds.add(id);
      }
    });
  }

  String _getWordToSpeak(dynamic item) {
    if (item is VocabularyModel) {
      return item.word;
    } else if (item is KanjiModel) {
      return item.kanji;
    } else if (item is GrammarModel) {
      return item.structure;
    }
    return '';
  }

  int _getItemId(dynamic item) {
    if (item is VocabularyModel) {
      return item.id;
    } else if (item is KanjiModel) {
      return item.id;
    } else if (item is GrammarModel) {
      return item.id;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(isDark),
              // Action Buttons
              _buildActionButtons(isDark),
              // Item List
              Expanded(
                child: _buildItemList(isDark),
              ),
            ],
          ),
        ),
        // Floating Play Button
        floatingActionButton: _buildPlayFab(),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        // Bottom Start Test Button
        bottomNavigationBar: _buildBottomBar(isDark),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
            style: IconButton.styleFrom(
              backgroundColor:
                  isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
              shape: const CircleBorder(),
            ),
          ),
          // Title
          Expanded(
            child: Text(
              'JLPT ${widget.levelTitle} $_typeLabel',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
          ),
          // Settings button
          IconButton(
            onPressed: () {
              // TODO: Open settings
            },
            icon: Icon(
              Icons.settings,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
            ),
            style: IconButton.styleFrom(
              backgroundColor:
                  isDark ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.style,
                  label: 'Flashcards',
                  isDark: isDark,
                  onTap: () {
                    // TODO: Open flashcards mode
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.mic,
                  label: 'Speaking',
                  isDark: isDark,
                  onTap: () {
                    // TODO: Open speaking mode
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.menu_book,
                  label: 'Definition',
                  isDark: isDark,
                  onTap: () {
                    // TODO: Open definition mode
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.check_circle_outline,
                  label: 'Select Word',
                  isDark: isDark,
                  onTap: () {
                    // TODO: Open select word mode
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
      itemCount: widget.items.length,
      itemBuilder: (context, index) {
        final item = widget.items[index];
        final itemId = _getItemId(item);
        final isFavorite = _favoriteIds.contains(itemId);
        final wordToSpeak = _getWordToSpeak(item);
        final isSpeaking = _speakingWord == wordToSpeak;

        return _ItemCard(
          item: item,
          type: widget.type,
          isFavorite: isFavorite,
          isSpeaking: isSpeaking,
          isDark: isDark,
          onSpeakPressed: () => _speakWord(wordToSpeak),
          onFavoritePressed: () => _toggleFavorite(itemId),
        );
      },
    );
  }

  Widget _buildPlayFab() {
    return Container(
      margin: const EdgeInsets.only(bottom: 80),
      child: FloatingActionButton(
        onPressed: () {
          _playAllWords();
        },
        backgroundColor: const Color(0xFF7ee08f), // accent-green
        elevation: 8,
        shape: const CircleBorder(),
        child: const Icon(
          Icons.play_arrow,
          color: Color(0xFF2b4254),
          size: 32,
        ),
      ),
    );
  }

  Future<void> _playAllWords() async {
    for (final item in widget.items) {
      if (!mounted) break;
      final word = _getWordToSpeak(item);
      await _speakWord(word);
      // Wait for speech to complete plus a short pause
      await Future.delayed(const Duration(milliseconds: 1500));
    }
  }

  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: isDark
              ? [
                  AppColors.backgroundDark,
                  AppColors.backgroundDark.withValues(alpha: 0.9),
                  AppColors.backgroundDark.withValues(alpha: 0),
                ]
              : [
                  AppColors.backgroundLight,
                  AppColors.backgroundLight.withValues(alpha: 0.9),
                  AppColors.backgroundLight.withValues(alpha: 0),
                ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Start test
            },
            icon: const Icon(Icons.quiz),
            label: const Text(
              'Start Test',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: isDark ? AppColors.backgroundDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 4,
            ),
          ),
        ),
      ),
    );
  }
}

/// Action button widget - 2x2 grid layout
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isDark
          ? const Color(0xFF2b4254) // surface-dark
          : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF4a6078) // border-dark
                  : Colors.grey.shade300,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item card widget - displays kanji, vocabulary, or grammar
class _ItemCard extends StatelessWidget {
  final dynamic item;
  final LessonType type;
  final bool isFavorite;
  final bool isSpeaking;
  final bool isDark;
  final VoidCallback onSpeakPressed;
  final VoidCallback onFavoritePressed;

  const _ItemCard({
    required this.item,
    required this.type,
    required this.isFavorite,
    required this.isSpeaking,
    required this.isDark,
    required this.onSpeakPressed,
    required this.onFavoritePressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2b4254) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF4a6078) : Colors.grey.shade200,
          width: isDark ? 1.0 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Item info
          Expanded(
            child: _buildItemContent(),
          ),
          // Action buttons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Speaker button
              IconButton(
                onPressed: onSpeakPressed,
                icon: Icon(
                  isSpeaking ? Icons.volume_up : Icons.volume_up_outlined,
                  color: isSpeaking
                      ? AppColors.primary
                      : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: isSpeaking
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : Colors.transparent,
                ),
              ),
              // Favorite button
              IconButton(
                onPressed: onFavoritePressed,
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite
                      ? const Color(0xFF7ee08f) // accent-green
                      : (isDark ? Colors.grey.shade500 : Colors.grey.shade400),
                ),
                style: IconButton.styleFrom(
                  backgroundColor: isFavorite
                      ? const Color(0xFF7ee08f).withValues(alpha: 0.1)
                      : Colors.transparent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemContent() {
    switch (type) {
      case LessonType.vocabulary:
        final vocab = item as VocabularyModel;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.ideographic,
              children: [
                Text(
                  vocab.word,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFFe0e0e0)
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  vocab.phonetic ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xFFe0a9bb)
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              vocab.shortMeaning,
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? const Color(0xFFa0a0a0)
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        );

      case LessonType.kanji:
        final kanji = item as KanjiModel;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.ideographic,
              children: [
                Text(
                  kanji.kanji,
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    color: isDark
                        ? const Color(0xFFe0e0e0)
                        : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (kanji.onReading.isNotEmpty)
                        Text(
                          kanji.onReading,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? const Color(0xFFe0a9bb)
                                : AppColors.primary,
                          ),
                        ),
                      if (kanji.kunReading.isNotEmpty)
                        Text(
                          kanji.kunReading,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              kanji.meaning,
              style: TextStyle(
                fontSize: 16,
                color: isDark
                    ? const Color(0xFFa0a0a0)
                    : AppColors.textSecondaryLight,
              ),
            ),
          ],
        );

      case LessonType.grammar:
        final grammar = item as GrammarModel;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              grammar.structure,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark
                    ? const Color(0xFFe0e0e0)
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              grammar.displayMeaning,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFFa0a0a0)
                    : AppColors.textSecondaryLight,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
    }
  }
}
