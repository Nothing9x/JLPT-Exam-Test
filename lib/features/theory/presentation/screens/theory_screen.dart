import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/theory_database_service.dart';
import '../../../../models/kanji_model.dart';
import '../../../../models/vocabulary_model.dart';
import '../../../../models/grammar_model.dart';
import '../../../../models/lesson_model.dart';
import '../widgets/theory_header.dart';
import '../widgets/theory_featured_card.dart';
import '../widgets/theory_lesson_grid.dart';
import '../widgets/theory_tab_bar.dart';
import 'lesson_detail_screen.dart';

/// Theory screen showing Kanji, Vocabulary, and Grammar lessons
class TheoryScreen extends StatefulWidget {
  final String languageCode;
  final String levelId;
  final String levelTitle;

  const TheoryScreen({
    super.key,
    required this.languageCode,
    required this.levelId,
    required this.levelTitle,
  });

  @override
  State<TheoryScreen> createState() => _TheoryScreenState();
}

class _TheoryScreenState extends State<TheoryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TheoryDatabaseService _databaseService = TheoryDatabaseService();

  bool _isLoading = true;
  String? _error;

  // Data for each tab
  List<LessonModel<KanjiModel>> _kanjiLessons = [];
  List<LessonModel<VocabularyModel>> _vocabularyLessons = [];
  List<LessonModel<GrammarModel>> _grammarLessons = [];

  // Total counts
  int _totalKanji = 0;
  int _totalVocabulary = 0;
  int _totalGrammar = 0;

  // Search query
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _databaseService.close();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      debugPrint('TheoryScreen: Loading data for language=${widget.languageCode}, level=${widget.levelId}');
      await _databaseService.initialize(widget.languageCode);
      debugPrint('TheoryScreen: Database initialized');

      // Load all data in parallel
      final results = await Future.wait([
        _databaseService.loadKanjiLessons(widget.levelId),
        _databaseService.loadVocabularyLessons(widget.levelId),
        _databaseService.loadGrammarLessons(widget.levelId),
        _databaseService.getKanjiCount(widget.levelId),
        _databaseService.getVocabularyCount(widget.levelId),
        _databaseService.getGrammarCount(widget.levelId),
      ]);

      debugPrint('TheoryScreen: Data loaded successfully');

      setState(() {
        _kanjiLessons = results[0] as List<LessonModel<KanjiModel>>;
        _vocabularyLessons = results[1] as List<LessonModel<VocabularyModel>>;
        _grammarLessons = results[2] as List<LessonModel<GrammarModel>>;
        _totalKanji = results[3] as int;
        _totalVocabulary = results[4] as int;
        _totalGrammar = results[5] as int;
        _isLoading = false;
      });
      debugPrint('TheoryScreen: Kanji=${_totalKanji}, Vocab=${_totalVocabulary}, Grammar=${_totalGrammar}');
    } catch (e, stackTrace) {
      debugPrint('TheoryScreen: Error loading data: $e');
      debugPrint('TheoryScreen: StackTrace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        body: Column(
          children: [
            // Header with search and tabs
            TheoryHeader(
              title: '${widget.levelTitle} Theory',
              searchQuery: _searchQuery,
              onSearchChanged: (query) {
                setState(() {
                  _searchQuery = query;
                });
              },
              onBackPressed: () => Navigator.of(context).pop(),
              tabBar: TheoryTabBar(
                controller: _tabController,
                tabs: const ['Kanji', 'Vocabulary', 'Grammar'],
              ),
            ),
            // Content
            Expanded(
              child: _buildContent(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: isDark ? Colors.white54 : Colors.black38,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        // Kanji Tab
        _buildKanjiTab(isDark),
        // Vocabulary Tab
        _buildVocabularyTab(isDark),
        // Grammar Tab
        _buildGrammarTab(isDark),
      ],
    );
  }

  Widget _buildKanjiTab(bool isDark) {
    final firstKanji = _kanjiLessons.isNotEmpty
        ? _kanjiLessons.first.firstItem?.kanji ?? '学'
        : '学';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TheoryFeaturedCard(
            title: 'New Kanji - Level ${widget.levelTitle}',
            displayCharacter: firstKanji,
            progress: 0,
            total: _totalKanji,
            onDownloadPressed: () {
              // TODO: Implement download
            },
          ),
          const SizedBox(height: 24),
          TheoryLessonGrid<KanjiModel>(
            lessons: _kanjiLessons,
            getDisplayCharacter: (item) => item.kanji,
            onLessonTap: (lesson) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LessonDetailScreen.kanji(
                    lesson: lesson,
                    levelTitle: widget.levelTitle,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVocabularyTab(bool isDark) {
    final firstWord = _vocabularyLessons.isNotEmpty
        ? _vocabularyLessons.first.firstItem?.word ?? '言'
        : '言';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TheoryFeaturedCard(
            title: 'New Vocabulary - Level ${widget.levelTitle}',
            displayCharacter: firstWord.isNotEmpty ? firstWord[0] : '言',
            progress: 0,
            total: _totalVocabulary,
            onDownloadPressed: () {
              // TODO: Implement download
            },
          ),
          const SizedBox(height: 24),
          TheoryLessonGrid<VocabularyModel>(
            lessons: _vocabularyLessons,
            getDisplayCharacter: (item) =>
                item.word.isNotEmpty ? item.word[0] : '',
            onLessonTap: (lesson) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LessonDetailScreen.vocabulary(
                    lesson: lesson,
                    levelTitle: widget.levelTitle,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGrammarTab(bool isDark) {
    final firstGrammar = _grammarLessons.isNotEmpty
        ? _grammarLessons.first.firstItem?.structure ?? '文'
        : '文';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TheoryFeaturedCard(
            title: 'New Grammar - Level ${widget.levelTitle}',
            displayCharacter: firstGrammar.isNotEmpty ? firstGrammar[0] : '文',
            progress: 0,
            total: _totalGrammar,
            onDownloadPressed: () {
              // TODO: Implement download
            },
          ),
          const SizedBox(height: 24),
          TheoryLessonGrid<GrammarModel>(
            lessons: _grammarLessons,
            getDisplayCharacter: (item) =>
                item.structure.isNotEmpty ? item.structure[0] : '',
            onLessonTap: (lesson) {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LessonDetailScreen.grammar(
                    lesson: lesson,
                    levelTitle: widget.levelTitle,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
