import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/vocabulary_model.dart';
import '../../../../models/kanji_model.dart';
import '../../../../models/grammar_model.dart';
import '../screens/lesson_detail_screen.dart';

/// Match Words - Definitions Game Screen
class MatchDefinitionScreen extends StatefulWidget {
  final LessonType type;
  final String levelTitle;
  final List<dynamic> items;

  const MatchDefinitionScreen({
    super.key,
    required this.type,
    required this.levelTitle,
    required this.items,
  });

  @override
  State<MatchDefinitionScreen> createState() => _MatchDefinitionScreenState();
}

class _MatchDefinitionScreenState extends State<MatchDefinitionScreen>
    with TickerProviderStateMixin {
  // Game state
  int _currentPage = 0;
  int _totalPages = 0;
  
  // Current page items (4 items per page)
  List<_MatchItem> _currentItems = [];
  List<_MatchItem> _shuffledDefinitions = [];
  
  // Selection state
  int? _selectedWordIndex;
  int? _selectedDefinitionIndex;
  
  // Matched pairs (word index -> definition index)
  final Set<int> _matchedWordIndices = {};
  final Set<int> _matchedDefinitionIndices = {};
  
  // Animation controllers
  late AnimationController _correctAnimationController;
  late AnimationController _wrongAnimationController;
  late Animation<double> _correctScaleAnimation;
  late Animation<double> _wrongShakeAnimation;
  
  // Track which items are animating
  int? _animatingWordIndex;
  int? _animatingDefinitionIndex;
  bool _isCorrectAnimation = false;
  
  // Colors from design
  static const Color _primaryColor = Color(0xFF393663);
  static const Color _secondaryColor = Color(0xFFFFF7FB); // Pale Sakura
  static const Color _accentColor = Color(0xFFFFDDEE); // Sakura Pink
  static const Color _highlightColor = Color(0xFFFFFEE8); // Pale Yellow
  static const Color _backgroundColor = Color(0xFFFDFCF8); // Soft Off-White
  static const Color _successColor = Color(0xFF4CAF50); // Green for correct

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeGame();
  }

  void _setupAnimations() {
    // Correct answer animation (scale bounce)
    _correctAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _correctScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.15), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.15, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 40),
    ]).animate(CurvedAnimation(
      parent: _correctAnimationController,
      curve: Curves.easeInOut,
    ));

    // Wrong answer animation (shake)
    _wrongAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _wrongShakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 10), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 10, end: -10), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -10, end: 10), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 10, end: -5), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -5, end: 0), weight: 20),
    ]).animate(CurvedAnimation(
      parent: _wrongAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _initializeGame() {
    // Calculate total pages (4 items per page)
    _totalPages = (widget.items.length / 4).ceil();
    _loadCurrentPage();
  }

  void _loadCurrentPage() {
    final startIndex = _currentPage * 4;
    final endIndex = (startIndex + 4).clamp(0, widget.items.length);
    
    _currentItems = [];
    for (int i = startIndex; i < endIndex; i++) {
      final item = widget.items[i];
      _currentItems.add(_MatchItem(
        index: i - startIndex,
        word: _getWord(item),
        definition: _getDefinition(item),
      ));
    }
    
    // Shuffle definitions
    _shuffledDefinitions = List.from(_currentItems)..shuffle();
    
    // Reset selection state
    _selectedWordIndex = null;
    _selectedDefinitionIndex = null;
    _matchedWordIndices.clear();
    _matchedDefinitionIndices.clear();
  }

  String _getWord(dynamic item) {
    if (item is VocabularyModel) return item.word;
    if (item is KanjiModel) return item.kanji;
    if (item is GrammarModel) return item.structure;
    return '';
  }

  String _getDefinition(dynamic item) {
    if (item is VocabularyModel) return item.shortMeaning;
    if (item is KanjiModel) return item.meaning;
    if (item is GrammarModel) return item.displayMeaning;
    return '';
  }

  @override
  void dispose() {
    _correctAnimationController.dispose();
    _wrongAnimationController.dispose();
    super.dispose();
  }

  void _onWordTap(int index) {
    if (_matchedWordIndices.contains(index)) return;
    
    setState(() {
      if (_selectedWordIndex == index) {
        _selectedWordIndex = null;
      } else {
        _selectedWordIndex = index;
        _checkMatch();
      }
    });
  }

  void _onDefinitionTap(int index) {
    if (_matchedDefinitionIndices.contains(index)) return;
    
    setState(() {
      if (_selectedDefinitionIndex == index) {
        _selectedDefinitionIndex = null;
      } else {
        _selectedDefinitionIndex = index;
        _checkMatch();
      }
    });
  }

  void _checkMatch() {
    if (_selectedWordIndex == null || _selectedDefinitionIndex == null) return;
    
    final selectedWord = _currentItems[_selectedWordIndex!];
    final selectedDefinition = _shuffledDefinitions[_selectedDefinitionIndex!];
    
    if (selectedWord.definition == selectedDefinition.definition) {
      // Correct match!
      _animatingWordIndex = _selectedWordIndex;
      _animatingDefinitionIndex = _selectedDefinitionIndex;
      _isCorrectAnimation = true;
      
      _correctAnimationController.forward(from: 0).then((_) {
        setState(() {
          _matchedWordIndices.add(_selectedWordIndex!);
          _matchedDefinitionIndices.add(_selectedDefinitionIndex!);
          _selectedWordIndex = null;
          _selectedDefinitionIndex = null;
          _animatingWordIndex = null;
          _animatingDefinitionIndex = null;
        });
      });
    } else {
      // Wrong match!
      _animatingWordIndex = _selectedWordIndex;
      _animatingDefinitionIndex = _selectedDefinitionIndex;
      _isCorrectAnimation = false;
      
      _wrongAnimationController.forward(from: 0).then((_) {
        setState(() {
          _selectedWordIndex = null;
          _selectedDefinitionIndex = null;
          _animatingWordIndex = null;
          _animatingDefinitionIndex = null;
        });
      });
    }
  }

  bool get _allMatched => _matchedWordIndices.length == _currentItems.length;

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      setState(() {
        _currentPage++;
        _loadCurrentPage();
      });
    } else {
      // Game completed
      _showCompletionDialog();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.celebration, color: Color(0xFF4CAF50), size: 28),
            SizedBox(width: 8),
            Text('Congratulations!'),
          ],
        ),
        content: const Text('You have completed all the word-definition matches!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Back to Lesson'),
          ),
        ],
      ),
    );
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
        backgroundColor: isDark ? AppColors.backgroundDark : _backgroundColor,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(isDark),
              // Progress bar
              _buildProgressBar(isDark),
              // Main content
              Expanded(
                child: _buildContent(isDark),
              ),
              // Bottom button
              _buildBottomButton(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark.withValues(alpha: 0.95)
            : _backgroundColor.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(
            color: _primaryColor.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Close button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.close,
              color: isDark ? Colors.white : _primaryColor,
              size: 28,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : _primaryColor.withValues(alpha: 0.05),
              shape: const CircleBorder(),
            ),
          ),
          // Progress text
          Column(
            children: [
              Text(
                '${_currentPage + 1} / $_totalPages',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : _primaryColor,
                ),
              ),
            ],
          ),
          // Pause button
          IconButton(
            onPressed: () {
              // TODO: Pause game
            },
            icon: Icon(
              Icons.pause,
              color: isDark ? Colors.white : _primaryColor,
              size: 28,
            ),
            style: IconButton.styleFrom(
              backgroundColor: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : _primaryColor.withValues(alpha: 0.05),
              shape: const CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(bool isDark) {
    final progress = (_currentPage + 1) / _totalPages;
    return Container(
      height: 6,
      color: isDark
          ? Colors.white.withValues(alpha: 0.1)
          : _primaryColor.withValues(alpha: 0.1),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          width: MediaQuery.of(context).size.width * progress,
          height: 6,
          decoration: BoxDecoration(
            color: isDark ? AppColors.primary : _primaryColor,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(3),
              bottomRight: Radius.circular(3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Title
          Text(
            'Match Words – Definitions',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : _primaryColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Connect the ${_getTypeLabel()} to its meaning',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.6)
                  : _primaryColor.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          // Game grid
          _buildGameGrid(isDark),
        ],
      ),
    );
  }

  String _getTypeLabel() {
    switch (widget.type) {
      case LessonType.kanji:
        return 'Kanji';
      case LessonType.vocabulary:
        return 'word';
      case LessonType.grammar:
        return 'grammar';
    }
  }

  Widget _buildGameGrid(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column: Words
        Expanded(
          child: Column(
            children: List.generate(_currentItems.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildWordCard(index, isDark),
              );
            }),
          ),
        ),
        const SizedBox(width: 16),
        // Right column: Definitions
        Expanded(
          child: Column(
            children: List.generate(_shuffledDefinitions.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildDefinitionCard(index, isDark),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildWordCard(int index, bool isDark) {
    final item = _currentItems[index];
    final isSelected = _selectedWordIndex == index;
    final isMatched = _matchedWordIndices.contains(index);
    final isAnimating = _animatingWordIndex == index;

    Widget card = _buildCard(
      child: Text(
        item.word,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: isMatched
              ? (isDark ? Colors.white.withValues(alpha: 0.6) : _primaryColor.withValues(alpha: 0.6))
              : (isDark ? Colors.white : _primaryColor),
        ),
        textAlign: TextAlign.center,
      ),
      isSelected: isSelected,
      isMatched: isMatched,
      isDark: isDark,
      showCheckBadge: isSelected && !isMatched,
      onTap: () => _onWordTap(index),
    );

    if (isAnimating) {
      if (_isCorrectAnimation) {
        return AnimatedBuilder(
          animation: _correctScaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _correctScaleAnimation.value,
              child: card,
            );
          },
        );
      } else {
        return AnimatedBuilder(
          animation: _wrongShakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_wrongShakeAnimation.value, 0),
              child: card,
            );
          },
        );
      }
    }

    return card;
  }

  Widget _buildDefinitionCard(int index, bool isDark) {
    final item = _shuffledDefinitions[index];
    final isSelected = _selectedDefinitionIndex == index;
    final isMatched = _matchedDefinitionIndices.contains(index);
    final isAnimating = _animatingDefinitionIndex == index;

    Widget card = _buildCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            item.definition,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isMatched
                  ? (isDark ? Colors.white.withValues(alpha: 0.6) : _primaryColor.withValues(alpha: 0.6))
                  : (isDark ? Colors.white : _primaryColor),
            ),
            textAlign: TextAlign.center,
          ),
          if (isMatched) ...[
            const SizedBox(height: 4),
            Icon(
              Icons.check_circle,
              size: 18,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.5)
                  : _primaryColor.withValues(alpha: 0.5),
            ),
          ],
        ],
      ),
      isSelected: isSelected,
      isMatched: isMatched,
      isDark: isDark,
      showCheckBadge: false,
      onTap: () => _onDefinitionTap(index),
    );

    if (isAnimating) {
      if (_isCorrectAnimation) {
        return AnimatedBuilder(
          animation: _correctScaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _correctScaleAnimation.value,
              child: card,
            );
          },
        );
      } else {
        return AnimatedBuilder(
          animation: _wrongShakeAnimation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(_wrongShakeAnimation.value, 0),
              child: card,
            );
          },
        );
      }
    }

    return card;
  }

  Widget _buildCard({
    required Widget child,
    required bool isSelected,
    required bool isMatched,
    required bool isDark,
    required bool showCheckBadge,
    required VoidCallback onTap,
  }) {
    Color backgroundColor;
    Color borderColor;
    double borderWidth;
    List<BoxShadow> shadows;
    double opacity = 1.0;

    if (isMatched) {
      // Matched state - pink/accent with green border
      backgroundColor = isDark ? _successColor.withValues(alpha: 0.2) : _accentColor;
      borderColor = _successColor;
      borderWidth = 2;
      shadows = [];
      opacity = 0.7;
    } else if (isSelected) {
      // Selected state - yellow highlight
      backgroundColor = isDark ? _highlightColor.withValues(alpha: 0.3) : _highlightColor;
      borderColor = isDark ? AppColors.primary : _primaryColor;
      borderWidth = 2;
      shadows = [
        BoxShadow(
          color: _primaryColor.withValues(alpha: 0.12),
          blurRadius: 25,
          offset: const Offset(0, 10),
        ),
      ];
    } else {
      // Default state
      backgroundColor = isDark ? const Color(0xFF2b4254) : _secondaryColor;
      borderColor = Colors.transparent;
      borderWidth = 1;
      shadows = [
        BoxShadow(
          color: _primaryColor.withValues(alpha: 0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: opacity,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          transform: isSelected
              ? (Matrix4.identity()..scale(1.02))
              : Matrix4.identity(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 100),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: borderColor,
                    width: borderWidth,
                  ),
                  boxShadow: shadows,
                ),
                child: Center(child: child),
              ),
              // Check badge for selected state
              if (showCheckBadge)
                Positioned(
                  top: -8,
                  right: -8,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.primary : _primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark.withValues(alpha: 0.9)
            : _backgroundColor.withValues(alpha: 0.9),
        border: Border(
          top: BorderSide(
            color: _primaryColor.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _allMatched ? _nextPage : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _allMatched
                  ? (isDark ? AppColors.primary : _primaryColor)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : _primaryColor.withValues(alpha: 0.2)),
              foregroundColor: _allMatched
                  ? Colors.white
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.4)
                      : _primaryColor.withValues(alpha: 0.4)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              _currentPage < _totalPages - 1 ? 'Next' : 'Finish',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper class for match items
class _MatchItem {
  final int index;
  final String word;
  final String definition;

  _MatchItem({
    required this.index,
    required this.word,
    required this.definition,
  });
}
