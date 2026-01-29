import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../data/services/practice_question_service.dart';
import '../../data/services/vocabulary_stats_service.dart';
import 'dart:async';

class PracticeQuestionScreen extends StatefulWidget {
  final PracticeType practiceType;
  final int userLevel;
  final int questionCount;
  final bool isPracticeMode;
  final String languageCode;
  final String? token;

  const PracticeQuestionScreen({
    super.key,
    required this.practiceType,
    required this.userLevel,
    required this.questionCount,
    required this.isPracticeMode,
    required this.languageCode,
    this.token,
  });

  @override
  State<PracticeQuestionScreen> createState() => _PracticeQuestionScreenState();
}

class _PracticeQuestionScreenState extends State<PracticeQuestionScreen> {
  late PracticeQuestionService _service;
  List<PracticeQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  final Map<int, int> _userAnswers = {}; // questionId -> answerIndex
  final Set<int> _bookmarkedQuestions = {};
  bool _isLoading = true;
  bool _showingAnswer = false;
  bool _showExplanation = false;
  Timer? _timer;
  int _remainingSeconds = 0;
  AudioPlayer? _audioPlayer;
  bool _isPlayingAudio = false;
  bool _isLoadingAudio = false;
  bool _isInitializingAudio = false; // Guard to prevent multiple simultaneous inits
  Duration _audioDuration = Duration.zero;
  Duration _audioPosition = Duration.zero;
  String? _currentAudioPath;

  // Stream subscriptions for audio player
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _durationSubscription;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _completeSubscription;

  @override
  void initState() {
    super.initState();
    _service = PracticeQuestionService(token: widget.token);
    _loadQuestions();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _completeSubscription?.cancel();
    _audioPlayer?.dispose();
    _service.dispose();
    super.dispose();
  }

  /// Determine category from typeId based on API documentation
  /// TypeId 1-6: VOCABULARY
  /// TypeId 7-9: GRAMMAR
  /// TypeId 10-15: READING
  /// TypeId 16-21: LISTENING
  String _getCategoryFromTypeId(int typeId) {
    if (typeId >= 1 && typeId <= 6) {
      return 'VOCABULARY';
    } else if (typeId >= 7 && typeId <= 9) {
      return 'GRAMMAR';
    } else if (typeId >= 10 && typeId <= 15) {
      return 'READING';
    } else if (typeId >= 16 && typeId <= 21) {
      return 'LISTENING';
    } else {
      debugPrint('⚠️ Unknown typeId: $typeId, defaulting to VOCABULARY');
      return 'VOCABULARY';
    }
  }

  /// Validate if a media path (audio/image) is valid
  bool _isValidMediaPath(String? path) {
    if (path == null) return false;
    final trimmed = path.trim();
    if (trimmed.isEmpty) return false;
    // Check for common invalid values
    if (trimmed == 'null' || trimmed == 'undefined' || trimmed == 'N/A') {
      return false;
    }
    // Must have at least 5 characters (e.g., "/a.mp3")
    if (trimmed.length < 5) return false;
    return true;
  }

  Future<void> _initAudioPlayer(String audioPath) async {
    // Prevent multiple simultaneous initializations
    if (_isInitializingAudio) {
      debugPrint('⚠️ Audio initialization already in progress, skipping');
      return;
    }

    // Check if this is the same audio that's already loaded
    if (_currentAudioPath == audioPath && _audioPlayer != null) {
      debugPrint('ℹ️ Audio already loaded for this path');
      return;
    }

    _isInitializingAudio = true;
    setState(() => _isLoadingAudio = true);

    try {
      // Cancel existing subscriptions
      await _playerStateSubscription?.cancel();
      await _durationSubscription?.cancel();
      await _positionSubscription?.cancel();
      await _completeSubscription?.cancel();

      // Stop and release old player if exists (don't await to avoid blocking)
      if (_audioPlayer != null) {
        _audioPlayer!.stop();
        _audioPlayer!.release();
      }

      // Create new player
      _audioPlayer = AudioPlayer();

      // Get base URL without /api
      final baseUrl = ApiConstants.baseUrl.replaceAll('/api', '');
      // Ensure audioPath starts with / for proper URL construction
      final normalizedPath = audioPath.startsWith('/') ? audioPath : '/$audioPath';
      final fullAudioUrl = '$baseUrl$normalizedPath';

      debugPrint('=== Loading Audio ===');
      debugPrint('Audio Path: $audioPath');
      debugPrint('Full URL: $fullAudioUrl');

      // Set up listeners BEFORE setting the source and store subscriptions
      _playerStateSubscription = _audioPlayer!.onPlayerStateChanged.listen((state) {
        if (mounted) {
          setState(() {
            _isPlayingAudio = state == PlayerState.playing;
          });
        }
      });

      _durationSubscription = _audioPlayer!.onDurationChanged.listen((duration) {
        if (mounted) {
          setState(() {
            _audioDuration = duration;
          });
        }
      });

      _positionSubscription = _audioPlayer!.onPositionChanged.listen((position) {
        if (mounted) {
          setState(() {
            _audioPosition = position;
          });
        }
      });

      _completeSubscription = _audioPlayer!.onPlayerComplete.listen((event) {
        if (mounted) {
          setState(() {
            _isPlayingAudio = false;
            _audioPosition = Duration.zero;
          });
        }
      });

      // Set the audio source - catch timeout exceptions which are normal for large files
      try {
        await _audioPlayer!.setSource(UrlSource(fullAudioUrl));
        debugPrint('✓ Audio source set successfully');
      } on TimeoutException catch (e) {
        // Timeout is expected for large audio files - audio continues preparing in background
        debugPrint('⏱️ Audio preparation timeout (audio will continue loading): $e');
        // Don't return - continue with setup
      }

      // Track current audio path
      _currentAudioPath = audioPath;

      setState(() => _isLoadingAudio = false);

    } catch (e, stackTrace) {
      debugPrint('✗ Error initializing audio player: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() => _isLoadingAudio = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _isInitializingAudio = false;
    }
  }

  Future<void> _toggleAudioPlayback() async {
    if (_audioPlayer == null) {
      debugPrint('⚠️ Audio player is null');
      return;
    }

    try {
      if (_isPlayingAudio) {
        debugPrint('⏸️ Pausing audio');
        await _audioPlayer!.pause();
      } else {
        debugPrint('▶️ Playing audio');
        await _audioPlayer!.resume();
      }
    } catch (e, stackTrace) {
      debugPrint('✗ Error toggling audio playback: $e');
      debugPrint('Stack trace: $stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _stopAudio() {
    _audioPlayer?.stop();
    setState(() {
      _isPlayingAudio = false;
      _isLoadingAudio = false;
      _audioPosition = Duration.zero;
      _currentAudioPath = null;
    });
  }

  Future<void> _loadQuestions() async {
    setState(() => _isLoading = true);

    try {
      // Get practiced question IDs
      final practicedIds = await _service.getPracticedQuestionIds();

      // Fetch more questions than needed to filter out practiced ones
      final fetchLimit = widget.questionCount * 3;
      final category = _getCategoryFromTypeId(widget.practiceType.typeId);
      debugPrint('🔍 Determined category: $category for typeId: ${widget.practiceType.typeId}');

      final allQuestions = await _service.getQuestions(
        level: widget.userLevel,
        category: category,
        typeId: widget.practiceType.typeId,
        limit: fetchLimit,
      );

      // Filter out already practiced questions
      final newQuestions = allQuestions
          .where((q) => !practicedIds.contains(q.id))
          .take(widget.questionCount)
          .toList();

      setState(() {
        _questions = newQuestions;
        _isLoading = false;
      });

      // Start timer for exam mode
      if (!widget.isPracticeMode) {
        _startTimer();
      }
    } catch (e) {
      debugPrint('Error loading questions: $e');
      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load questions: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startTimer() {
    // Estimate 1 minute per question
    _remainingSeconds = widget.questionCount * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        timer.cancel();
        _finishPractice();
      }
    });
  }

  String get _timerText {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _selectAnswer(int answerIndex) async {
    final currentQuestion = _questions[_currentQuestionIndex];

    setState(() {
      _userAnswers[currentQuestion.id] = answerIndex;
    });

    if (widget.isPracticeMode) {
      // In practice mode, show answer immediately and save history
      await _fetchAndShowAnswer();
      await _savePracticeHistory(answerIndex);
    }
  }

  Future<void> _fetchAndShowAnswer() async {
    try {
      final currentQuestion = _questions[_currentQuestionIndex];
      final questionWithAnswer =
          await _service.fetchQuestionAnswer(currentQuestion.id);

      setState(() {
        _questions[_currentQuestionIndex] = questionWithAnswer;
        _showingAnswer = true;
        _showExplanation = false; // Reset explanation visibility
      });
    } catch (e) {
      debugPrint('Error fetching answer: $e');
    }
  }

  Future<void> _savePracticeHistory(int answerIndex) async {
    final currentQuestion = _questions[_currentQuestionIndex];
    final isCorrect = currentQuestion.correctAnswer == answerIndex;

    await _service.savePracticeHistory(
      questionId: currentQuestion.id,
      userAnswer: answerIndex,
      isCorrect: isCorrect,
      practiceType: 'vocabulary',
      level: widget.userLevel,
    );
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      _stopAudio(); // Stop audio when moving to next question
      setState(() {
        _currentQuestionIndex++;
        _showingAnswer = false;
        _showExplanation = false;
      });
    } else {
      _finishPractice();
    }
  }

  void _showQuestionOverview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _QuestionOverviewScreen(
          questions: _questions,
          userAnswers: _userAnswers,
          currentIndex: _currentQuestionIndex,
          onQuestionTap: (index) {
            _stopAudio(); // Stop audio when jumping to another question
            setState(() {
              _currentQuestionIndex = index;
              _showingAnswer = false;
              _showExplanation = false;
            });
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Future<void> _finishPractice() async {
    _timer?.cancel();

    if (widget.isPracticeMode) {
      // For practice mode, just go back
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Practice completed! Answered ${_userAnswers.length}/${_questions.length} questions'),
          backgroundColor: AppColors.tealAccent,
        ),
      );
    } else {
      // For exam mode, save all answers and show results
      await _saveExamAnswers();
      _showResults();
    }
  }

  Future<void> _saveExamAnswers() async {
    // Fetch all correct answers in parallel
    final answeredQuestions =
        _questions.where((q) => _userAnswers.containsKey(q.id)).toList();

    debugPrint('Fetching answers for ${answeredQuestions.length} questions in parallel...');

    // Fetch all answers in parallel
    await Future.wait(
      answeredQuestions.map((question) async {
        if (question.correctAnswer == null) {
          try {
            final questionWithAnswer =
                await _service.fetchQuestionAnswer(question.id);
            question.correctAnswer = questionWithAnswer.correctAnswer;
          } catch (e) {
            debugPrint(
                'Error fetching answer for question ${question.id}: $e');
          }
        }
      }),
    );

    debugPrint('All answers fetched, saving history in parallel...');

    // Save all practice history in parallel
    await Future.wait(
      answeredQuestions.map((question) async {
        final answerIndex = _userAnswers[question.id]!;
        final isCorrect = question.correctAnswer == answerIndex;
        await _service.savePracticeHistory(
          questionId: question.id,
          userAnswer: answerIndex,
          isCorrect: isCorrect,
          practiceType: 'vocabulary',
          level: widget.userLevel,
        );
      }),
    );

    debugPrint('All history saved successfully');
  }

  void _showResults() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => _PracticeResultScreen(
          questions: _questions,
          userAnswers: _userAnswers,
          practiceType: widget.practiceType,
        ),
      ),
    );
  }

  Future<void> _bookmarkQuestion() async {
    final currentQuestion = _questions[_currentQuestionIndex];

    final success = await _service.bookmarkQuestion(
      questionId: currentQuestion.id,
      note: 'Saved from ${widget.practiceType.name}',
    );

    if (success) {
      setState(() {
        _bookmarkedQuestions.add(currentQuestion.id);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Question saved to favorites'),
            backgroundColor: AppColors.tealAccent,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _reportQuestion() async {
    await showDialog(
      context: context,
      builder: (context) => ReportQuestionDialog(
        questionId: _questions[_currentQuestionIndex].id,
        service: _service,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: widget.isPracticeMode,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && !widget.isPracticeMode) {
          final result = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Exit Exam?'),
              content: const Text(
                'Are you sure you want to exit? Your progress will not be saved.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Exit'),
                ),
              ],
            ),
          );
          if (result == true && context.mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: isDark ? AppColors.backgroundDark : Colors.white,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Exit Practice?'),
                              content: const Text(
                                  'Your progress will be lost if you exit now.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Exit'),
                                ),
                              ],
                            ),
                          );
                        },
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
                            Icons.close,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                            size: 24,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          // Overview button for exam mode
                          if (!widget.isPracticeMode && _questions.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: _showQuestionOverview,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.tealAccent
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.grid_view,
                                        size: 18,
                                        color: AppColors.tealAccent,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Overview',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.tealAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          // Timer
                          if (!widget.isPracticeMode && _remainingSeconds > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _remainingSeconds < 60
                                    ? Colors.red.withValues(alpha: 0.15)
                                    : AppColors.tealAccent
                                        .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.timer,
                                    size: 18,
                                    color: _remainingSeconds < 60
                                        ? Colors.red
                                        : AppColors.tealAccent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _timerText,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: _remainingSeconds < 60
                                          ? Colors.red
                                          : AppColors.tealAccent,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress bar
                  if (_questions.isNotEmpty)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                            ),
                            Text(
                              widget.practiceType.name,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.tealAccent,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: (_currentQuestionIndex + 1) /
                                _questions.length,
                            minHeight: 8,
                            backgroundColor: isDark
                                ? AppColors.borderDark
                                : AppColors.borderLight,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              AppColors.tealAccent,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // Divider
            Container(
              height: 1,
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            // Content
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            color: AppColors.tealAccent,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading questions...',
                            style: TextStyle(
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _questions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondaryLight,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No new questions available',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'You\'ve practiced all available questions!',
                                style: TextStyle(
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                          ),
                        )
                      : _buildQuestionContent(isDark),
            ),
            // Bottom Navigation Buttons
            if (_questions.isNotEmpty) _buildBottomNavigationBar(isDark),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildQuestionContent(bool isDark) {
    final currentQuestion = _questions[_currentQuestionIndex];
    final userAnswer = _userAnswers[currentQuestion.id];
    final isBookmarked = _bookmarkedQuestions.contains(currentQuestion.id);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Action buttons (save and report)
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Bookmark button
              IconButton(
                onPressed: isBookmarked ? null : _bookmarkQuestion,
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked ? AppColors.tealAccent : null,
                ),
                tooltip: 'Save to favorites',
              ),
              // Report button
              IconButton(
                onPressed: _reportQuestion,
                icon: const Icon(Icons.flag_outlined),
                tooltip: 'Report incorrect answer',
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Question text
          if (currentQuestion.groupTitle != null &&
              currentQuestion.groupTitle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                currentQuestion.groupTitle!,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          // Audio player
          if (_isValidMediaPath(currentQuestion.audio))
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildAudioPlayer(currentQuestion.audio!, isDark),
            ),
          // Image display
          if (_isValidMediaPath(currentQuestion.image))
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildImageDisplay(currentQuestion.image!, isDark),
            ),
          // Question container - only render if question text is not empty
          if (currentQuestion.question.trim().isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardBackgroundDark : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.borderLight,
                ),
              ),
              child: Html(
                data: currentQuestion.question,
                style: {
                  "body": Style(
                    fontSize: FontSize(20),
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimaryLight,
                    lineHeight: LineHeight.number(1.6),
                    margin: Margins.zero,
                    padding: HtmlPaddings.zero,
                  ),
                  "u": Style(
                    textDecoration: TextDecoration.underline,
                  ),
                },
              ),
            ),
          const SizedBox(height: 24),
          // Answers
          ...List.generate(
            currentQuestion.answers.length,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildAnswerCard(
                index: index,
                answer: currentQuestion.answers[index],
                isSelected: userAnswer == index,
                isCorrect: _showingAnswer &&
                    currentQuestion.correctAnswer == index,
                isWrong: _showingAnswer &&
                    userAnswer == index &&
                    currentQuestion.correctAnswer != index,
                isDark: isDark,
              ),
            ),
          ),
          // Explanation section (only in practice mode)
          if (widget.isPracticeMode &&
              _showingAnswer &&
              currentQuestion.explainVn != null &&
              currentQuestion.explainVn!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: [
                  // Show/Hide explanation button
                  if (!_showExplanation)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _showExplanation = true);
                        },
                        icon: const Icon(Icons.lightbulb_outline, size: 20),
                        label: const Text('Show Explanation'),
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
                      ),
                    ),
                  // Explanation content
                  if (_showExplanation)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.tealAccent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.tealAccent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.lightbulb,
                                    size: 20,
                                    color: AppColors.tealAccent,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Explanation',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.tealAccent,
                                    ),
                                  ),
                                ],
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() => _showExplanation = false);
                                },
                                icon: Icon(
                                  Icons.close,
                                  size: 20,
                                  color: AppColors.tealAccent,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Html(
                            data: currentQuestion.explainVn ?? '',
                            style: {
                              "body": Style(
                                fontSize: FontSize(14),
                                lineHeight: LineHeight.number(1.6),
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimaryLight,
                                margin: Margins.zero,
                                padding: HtmlPaddings.zero,
                              ),
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: widget.isPracticeMode
            ? _buildPracticeModeButtons()
            : _buildExamModeButtons(),
      ),
    );
  }

  Widget _buildPracticeModeButtons() {
    // In practice mode, show Next button only after answering
    if (!_showingAnswer) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _nextQuestion,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.tealAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _currentQuestionIndex < _questions.length - 1
                  ? 'Next Question'
                  : 'Finish',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildExamModeButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Submit button (show on last question only)
        if (_currentQuestionIndex == _questions.length - 1 &&
            _userAnswers.length == _questions.length)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _finishPractice,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Submit Exam',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        // Next button (always show if not on last question)
        if (_currentQuestionIndex < _questions.length - 1)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                _stopAudio(); // Stop audio when moving to next question
                setState(() {
                  _currentQuestionIndex++;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tealAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Next Question',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward, size: 20),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnswerCard({
    required int index,
    required String answer,
    required bool isSelected,
    required bool isCorrect,
    required bool isWrong,
    required bool isDark,
  }) {
    Color? backgroundColor;
    Color? borderColor;
    Color? textColor;

    if (isCorrect) {
      backgroundColor = Colors.green.withValues(alpha: 0.15);
      borderColor = Colors.green;
      textColor = Colors.green;
    } else if (isWrong) {
      backgroundColor = Colors.red.withValues(alpha: 0.15);
      borderColor = Colors.red;
      textColor = Colors.red;
    } else if (isSelected) {
      backgroundColor = AppColors.tealAccent.withValues(alpha: 0.15);
      borderColor = AppColors.tealAccent;
      textColor = AppColors.tealAccent;
    } else {
      backgroundColor = isDark ? AppColors.cardBackgroundDark : Colors.white;
      borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
      textColor =
          isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    }

    return GestureDetector(
      onTap: _showingAnswer ? null : () => _selectAnswer(index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: isSelected || isCorrect || isWrong ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isCorrect || isWrong || isSelected
                    ? textColor.withValues(alpha: 0.2)
                    : (isDark ? AppColors.borderDark : Colors.grey[200]),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                answer,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            if (isCorrect || isWrong)
              Icon(
                isCorrect ? Icons.check_circle : Icons.cancel,
                color: textColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayer(String audioPath, bool isDark) {
    // Initialize audio player only if audio path has changed and not already initializing
    if (_currentAudioPath != audioPath && !_isInitializingAudio) {
      // Use Future.microtask to avoid calling setState during build
      Future.microtask(() => _initAudioPlayer(audioPath));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.cardBackgroundDark
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Play/Pause button or loading indicator
              _isLoadingAudio
                  ? Container(
                      width: 48,
                      height: 48,
                      margin: const EdgeInsets.all(8),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.tealAccent,
                        ),
                      ),
                    )
                  : IconButton(
                      onPressed: _audioPlayer != null ? _toggleAudioPlayback : null,
                      icon: Icon(
                        _isPlayingAudio ? Icons.pause_circle : Icons.play_circle,
                        size: 48,
                        color: _audioPlayer != null
                            ? AppColors.tealAccent
                            : Colors.grey,
                      ),
                    ),
              const SizedBox(width: 12),
              // Progress and time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Audio',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        Text(
                          '${_formatDuration(_audioPosition)} / ${_formatDuration(_audioDuration)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _audioDuration.inMilliseconds > 0
                            ? _audioPosition.inMilliseconds /
                                _audioDuration.inMilliseconds
                            : 0.0,
                        minHeight: 4,
                        backgroundColor: isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.tealAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageDisplay(String imagePath, bool isDark) {
    debugPrint('=== Building Image Display ===');
    debugPrint('Image Path: "$imagePath"');
    debugPrint('Image Path Length: ${imagePath.length}');

    // Get base URL without /api
    final baseUrl = ApiConstants.baseUrl.replaceAll('/api', '');
    // Ensure imagePath starts with / for proper URL construction
    final normalizedPath = imagePath.startsWith('/') ? imagePath : '/$imagePath';
    final fullImageUrl = '$baseUrl$normalizedPath';
    debugPrint('Full Image URL: $fullImageUrl');

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        fullImageUrl,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('✗ Error loading image: $error - hiding image widget');
          // Hide the image completely if it fails to load
          return const SizedBox.shrink();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          // Show loading indicator
          return Container(
            height: 200,
            alignment: Alignment.center,
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: AppColors.tealAccent,
            ),
          );
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}

// Question Overview Dialog
class _QuestionOverviewScreen extends StatelessWidget {
  final List<PracticeQuestion> questions;
  final Map<int, int> userAnswers;
  final int currentIndex;
  final Function(int) onQuestionTap;

  const _QuestionOverviewScreen({
    required this.questions,
    required this.userAnswers,
    required this.currentIndex,
    required this.onQuestionTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final answeredCount = userAnswers.length;
    final unansweredCount = questions.length - answeredCount;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: isDark ? AppColors.backgroundDark : Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
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
                  const Text(
                    'Question Overview',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
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
                    // Stats
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.tealAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: AppColors.tealAccent,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$answeredCount',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.tealAccent,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Answered',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.tealAccent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.pending,
                                  color: Colors.orange,
                                  size: 32,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '$unansweredCount',
                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.orange,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Remaining',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    // Legend
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardBackgroundDark
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.borderLight,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildLegendItem(
                            'Current',
                            AppColors.tealAccent,
                            isBorder: true,
                          ),
                          _buildLegendItem(
                            'Answered',
                            AppColors.tealAccent.withValues(alpha: 0.3),
                          ),
                          _buildLegendItem(
                            'Unanswered',
                            isDark ? AppColors.borderDark : Colors.grey[300]!,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Questions Grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: questions.length,
                      itemBuilder: (context, index) {
                        final question = questions[index];
                        final userAnswer = userAnswers[question.id];
                        final isAnswered = userAnswer != null;
                        final isCurrent = index == currentIndex;

                        return GestureDetector(
                          onTap: () {
                            onQuestionTap(index);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: isCurrent
                                  ? AppColors.tealAccent
                                  : (isAnswered
                                      ? AppColors.tealAccent
                                          .withValues(alpha: 0.3)
                                      : (isDark
                                          ? AppColors.cardBackgroundDark
                                          : Colors.white)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isCurrent
                                    ? AppColors.tealAccent
                                    : (isDark
                                        ? AppColors.borderDark
                                        : AppColors.borderLight),
                                width: isCurrent ? 3 : 1,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: isCurrent
                                        ? Colors.white
                                        : (isAnswered
                                            ? Colors.white
                                            : (isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimaryLight)),
                                  ),
                                ),
                                if (isAnswered) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isCurrent
                                          ? Colors.white
                                          : AppColors.tealAccent,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      String.fromCharCode(65 + userAnswer),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                        color: isCurrent
                                            ? AppColors.tealAccent
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, {bool isBorder = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isBorder ? Colors.transparent : color,
            borderRadius: BorderRadius.circular(6),
            border: isBorder ? Border.all(color: color, width: 2.5) : null,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

// Practice Result Screen
class _PracticeResultScreen extends StatelessWidget {
  final List<PracticeQuestion> questions;
  final Map<int, int> userAnswers;
  final PracticeType practiceType;

  const _PracticeResultScreen({
    required this.questions,
    required this.userAnswers,
    required this.practiceType,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    int correctCount = 0;
    for (var question in questions) {
      if (userAnswers.containsKey(question.id)) {
        final userAnswer = userAnswers[question.id];
        if (userAnswer == question.correctAnswer) {
          correctCount++;
        }
      }
    }

    final score = (correctCount / questions.length * 100).round();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: isDark ? AppColors.backgroundDark : Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Results',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
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
                        Icons.close,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                    // Score card
                    Container(
                      padding: const EdgeInsets.all(32),
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
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: score >= 70
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.orange.withValues(alpha: 0.15),
                            ),
                            child: Center(
                              child: Text(
                                '$score%',
                                style: TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  color: score >= 70
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            score >= 70
                                ? 'Great Job!'
                                : 'Keep Practicing!',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimaryLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$correctCount out of ${questions.length} correct',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Action buttons
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tealAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Report Question Dialog Widget
/// Shows a modal dialog for users to report issues with questions
class ReportQuestionDialog extends StatefulWidget {
  final int questionId;
  final PracticeQuestionService service;

  const ReportQuestionDialog({
    super.key,
    required this.questionId,
    required this.service,
  });

  @override
  State<ReportQuestionDialog> createState() => _ReportQuestionDialogState();
}

class _ReportQuestionDialogState extends State<ReportQuestionDialog> {
  String? _selectedType;
  final TextEditingController _detailsController = TextEditingController();
  bool _isSubmitting = false;

  final Map<String, String> _reportTypes = {
    'wrong_answer': 'Wrong Answer',
    'audio_quality': 'Audio Quality',
    'typo': 'Typo',
    'technical': 'Technical',
    'confusing': 'Confusing',
    'other': 'Other',
  };

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a problem type'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await widget.service.reportQuestion(
      questionId: widget.questionId,
      reportType: _selectedType!,
      description: _detailsController.text.trim().isEmpty
          ? null
          : _detailsController.text.trim(),
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Report submitted successfully. Thank you!'
                : 'Failed to submit report. Please try again.',
          ),
          backgroundColor: success ? AppColors.tealAccent : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2a2d33) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      color: Colors.transparent,
                    ),
                    child: Icon(
                      Icons.close,
                      size: 20,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ),
            ),
            // Header section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                children: [
                  // Icon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.tealAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.flag,
                      color: AppColors.tealAccent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  const Text(
                    'Report an Issue',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtitle
                  Text(
                    'Help us improve the lesson quality.',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Problem type label
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'PROBLEM TYPE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                      ),
                    ),
                    // Problem type chips
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _reportTypes.entries.map((entry) {
                        final isSelected = _selectedType == entry.key;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedType = entry.key),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.tealAccent
                                  : isDark
                                      ? Colors.white.withValues(alpha: 0.05)
                                      : const Color(0xFFf2f3f1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.tealAccent
                                    : Colors.transparent,
                                width: 1,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppColors.tealAccent
                                            .withValues(alpha: 0.25),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isSelected) ...[
                                  const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Text(
                                  entry.value,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected
                                        ? Colors.white
                                        : isDark
                                            ? Colors.grey[200]
                                            : const Color(0xFF141613),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    // Details label
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'DETAILS (OPTIONAL)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                      ),
                    ),
                    // Details text area
                    Container(
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.2)
                            : Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _detailsController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'The audio cut out halfway through...',
                          hintStyle: TextStyle(
                            color: isDark ? Colors.grey[600] : Colors.grey[400],
                            fontSize: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                          filled: true,
                          fillColor: Colors.transparent,
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Action buttons
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  // Skip button
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 48,
                      child: TextButton(
                        onPressed:
                            _isSubmitting ? null : () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor:
                              isDark ? Colors.grey[500] : Colors.grey[400],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Submit button
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitReport,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.tealAccent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shadowColor:
                              AppColors.tealAccent.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  Text(
                                    'Submit Report',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.send, size: 18),
                                ],
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
