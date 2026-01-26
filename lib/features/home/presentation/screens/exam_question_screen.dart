import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/api_constants.dart';
import '../../data/services/exam_service.dart';
import 'exam_overview_screen.dart';
import 'exam_result_screen.dart';

// Models for exam questions
class QuestionModel {
  final int id;
  final String question;
  final String answer1;
  final String answer2;
  final String answer3;
  final String answer4;
  final int correctAnswer;
  final String? image;
  final String? explain;

  QuestionModel({
    required this.id,
    required this.question,
    required this.answer1,
    required this.answer2,
    required this.answer3,
    required this.answer4,
    required this.correctAnswer,
    this.image,
    this.explain,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] ?? 0,
      question: json['question'] ?? '',
      answer1: json['answer1'] ?? '',
      answer2: json['answer2'] ?? '',
      answer3: json['answer3'] ?? '',
      answer4: json['answer4'] ?? '',
      correctAnswer: json['correctAnswer'] ?? 1,
      image: json['image'],
      explain: json['explain'],
    );
  }
}

class QuestionGroupModel {
  final int id;
  final int countQuestion;
  final String title;
  final String? audio;
  final String? image;
  final String? txtRead;
  final List<QuestionModel> questions;

  QuestionGroupModel({
    required this.id,
    required this.countQuestion,
    required this.title,
    this.audio,
    this.image,
    this.txtRead,
    required this.questions,
  });

  factory QuestionGroupModel.fromJson(Map<String, dynamic> json) {
    return QuestionGroupModel(
      id: json['id'] ?? 0,
      countQuestion: json['countQuestion'] ?? 0,
      title: json['title'] ?? '',
      audio: json['audio'],
      image: json['image'],
      txtRead: json['txtRead'],
      questions:
          (json['questions'] as List?)
              ?.map((q) => QuestionModel.fromJson(q))
              .toList() ??
          [],
    );
  }
}

class SectionModel {
  final int id;
  final String kind;
  final List<QuestionGroupModel> questionGroups;

  SectionModel({
    required this.id,
    required this.kind,
    required this.questionGroups,
  });

  factory SectionModel.fromJson(Map<String, dynamic> json) {
    return SectionModel(
      id: json['id'] ?? 0,
      kind: json['kind'] ?? '',
      questionGroups:
          (json['questionGroups'] as List?)
              ?.map((g) => QuestionGroupModel.fromJson(g))
              .toList() ??
          [],
    );
  }
}

class PartModel {
  final int id;
  final String name;
  final int time;
  final int minScore;
  final int maxScore;
  final List<SectionModel> sections;

  PartModel({
    required this.id,
    required this.name,
    required this.time,
    required this.minScore,
    required this.maxScore,
    required this.sections,
  });

  factory PartModel.fromJson(Map<String, dynamic> json) {
    return PartModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      time: json['time'] ?? 0,
      minScore: json['minScore'] ?? 0,
      maxScore: json['maxScore'] ?? 0,
      sections:
          (json['sections'] as List?)
              ?.map((s) => SectionModel.fromJson(s))
              .toList() ??
          [],
    );
  }
}

class ExamDetailModel {
  final int id;
  final String title;
  final int level;
  final int time;
  final int score;
  final int passScore;
  final List<PartModel> parts;

  ExamDetailModel({
    required this.id,
    required this.title,
    required this.level,
    required this.time,
    required this.score,
    required this.passScore,
    required this.parts,
  });

  factory ExamDetailModel.fromJson(Map<String, dynamic> json) {
    return ExamDetailModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      level: json['level'] ?? 0,
      time: json['time'] ?? 0,
      score: json['score'] ?? 180,
      passScore: json['passScore'] ?? 100,
      parts:
          (json['parts'] as List?)
              ?.map((p) => PartModel.fromJson(p))
              .toList() ??
          [],
    );
  }

  // Get all questions flattened
  List<FlatQuestion> getAllQuestions() {
    List<FlatQuestion> allQuestions = [];
    for (var part in parts) {
      for (var section in part.sections) {
        for (var group in section.questionGroups) {
          for (var question in group.questions) {
            allQuestions.add(
              FlatQuestion(
                question: question,
                groupTitle: group.title,
                sectionKind: section.kind,
                partName: part.name,
              ),
            );
          }
        }
      }
    }
    return allQuestions;
  }

  // Get total question count
  int getTotalQuestionCount() {
    int count = 0;
    for (var part in parts) {
      for (var section in part.sections) {
        for (var group in section.questionGroups) {
          count += group.questions.length;
        }
      }
    }
    return count;
  }
}

// Question type mapping based on kind/key
class QuestionTypeMapper {
  // Keys are lowercase to match API response (e.g., "cách đọc kanji")
  static const Map<String, String> _kindToCategory = {
    // VOCABULARY (1-6)
    'cách đọc kanji': 'VOCABULARY',
    'thay đổi cách nói': 'VOCABULARY',
    'điền từ theo văn cảnh': 'VOCABULARY',
    'ứng dụng từ': 'VOCABULARY',
    'cách viết từ': 'VOCABULARY',
    'hình thành từ': 'VOCABULARY',
    // GRAMMAR (7-9)
    'lựa chọn ngữ pháp': 'GRAMMAR',
    'lắp ghép câu': 'GRAMMAR',
    'ngữ pháp theo đoạn văn': 'GRAMMAR',
    // READING (10-15)
    'đoạn văn ngắn': 'READING',
    'đoạn văn vừa': 'READING',
    'đoạn văn dài': 'READING',
    'đọc hiểu tổng hợp': 'READING',
    'đọc hiểu chủ đề': 'READING',
    'tìm thông tin': 'READING',
    // LISTENING (16-21)
    'nghe hiểu chủ đề': 'LISTENING',
    'nghe hiểu điểm chính': 'LISTENING',
    'nghe hiểu khái quát': 'LISTENING',
    'trả lời nhanh': 'LISTENING',
    'nghe hiểu tổng hợp': 'LISTENING',
    'nghe hiểu diễn đạt': 'LISTENING',
  };

  static String getCategory(String kind) {
    // Normalize to lowercase for case-insensitive matching
    final normalizedKind = kind.toLowerCase().trim();
    return _kindToCategory[normalizedKind] ?? _getCategoryFromPartName(kind);
  }

  static String _getCategoryFromPartName(String partName) {
    // Fallback: try to detect from Japanese part names
    if (partName.contains('文字') || partName.contains('語彙')) {
      return 'VOCABULARY';
    } else if (partName.contains('文法')) {
      return 'GRAMMAR';
    } else if (partName.contains('読解') || partName.contains('読')) {
      return 'READING';
    } else if (partName.contains('聴解') || partName.contains('聴')) {
      return 'LISTENING';
    }
    return 'VOCABULARY'; // Default fallback
  }

  static String getCategoryDisplayName(String category) {
    switch (category) {
      case 'VOCABULARY':
        return 'Vocabulary';
      case 'GRAMMAR':
        return 'Grammar';
      case 'READING':
        return 'Reading';
      case 'LISTENING':
        return 'Listening';
      default:
        return category;
    }
  }
}

class FlatQuestion {
  final QuestionModel question;
  final String groupTitle;
  final String sectionKind;
  final String partName;

  FlatQuestion({
    required this.question,
    required this.groupTitle,
    required this.sectionKind,
    required this.partName,
  });

  // Get the category based on sectionKind
  String get category => QuestionTypeMapper.getCategory(sectionKind);

  // Get display name for the category
  String get categoryDisplayName =>
      QuestionTypeMapper.getCategoryDisplayName(category);
}

class ExamQuestionScreen extends StatefulWidget {
  final ExamModel exam;
  final String level;
  final String? token;
  final String? userName;
  final ExamDetailModel? preloadedExamDetail;

  const ExamQuestionScreen({
    super.key,
    required this.exam,
    required this.level,
    this.token,
    this.userName,
    this.preloadedExamDetail,
  });

  @override
  State<ExamQuestionScreen> createState() => _ExamQuestionScreenState();
}

class _ExamQuestionScreenState extends State<ExamQuestionScreen> {
  ExamDetailModel? _examDetail;
  List<FlatQuestion> _questions = [];
  int _currentQuestionIndex = 0;
  Map<int, int> _answers = {}; // questionId -> selectedAnswer
  Set<int> _flaggedQuestions = {}; // questionIds that are flagged
  Set<int> _starredQuestions = {}; // questionIds that are starred/bookmarked
  bool _isLoading = true;
  String? _error;

  // Timer
  late int _remainingSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.exam.time * 60; // Convert minutes to seconds

    // Use preloaded data if available, otherwise load from API
    if (widget.preloadedExamDetail != null) {
      _examDetail = widget.preloadedExamDetail;
      _questions = _examDetail!.getAllQuestions();
      _isLoading = false;
      // Start timer after frame is built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTimer();
      });
    } else {
      _loadExamDetails();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        _timer?.cancel();
        _submitExam();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Future<void> _loadExamDetails() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/exams/${widget.exam.id}'),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _examDetail = ExamDetailModel.fromJson(data);
          _questions = _examDetail!.getAllQuestions();
          _isLoading = false;
        });
        _startTimer();
      } else {
        setState(() {
          _error = 'Failed to load exam';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _selectAnswer(int answerId) {
    setState(() {
      _answers[_questions[_currentQuestionIndex].question.id] = answerId;
    });
  }

  void _toggleFlag() {
    final questionId = _questions[_currentQuestionIndex].question.id;
    setState(() {
      if (_flaggedQuestions.contains(questionId)) {
        _flaggedQuestions.remove(questionId);
      } else {
        _flaggedQuestions.add(questionId);
      }
    });
  }

  void _toggleStar() {
    final questionId = _questions[_currentQuestionIndex].question.id;
    setState(() {
      if (_starredQuestions.contains(questionId)) {
        _starredQuestions.remove(questionId);
      } else {
        _starredQuestions.add(questionId);
      }
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _goToQuestion(int index) {
    setState(() {
      _currentQuestionIndex = index;
    });
  }

  void _showOverview() {
    if (_examDetail == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ExamOverviewScreen(
          questions: _questions,
          answers: _answers,
          flaggedQuestions: _flaggedQuestions,
          parts: _examDetail!.parts,
          onQuestionSelected: (index) {
            setState(() {
              _currentQuestionIndex = index;
            });
          },
        ),
      ),
    );
  }

  void _showPauseDialog() {
    _timer?.cancel();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Exam Paused'),
        content: const Text(
          'Your exam is paused. Do you want to continue or exit?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // Exit exam
            },
            child: const Text('Exit Exam'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _startTimer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tealAccent,
            ),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitExam() async {
    _timer?.cancel();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      // Use externalId if available, otherwise fall back to id
      final examId = widget.exam.externalId ?? widget.exam.id;

      final requestBody = {
        'examId': examId,
        'answers': _answers.map(
          (key, value) => MapEntry(key.toString(), value),
        ),
      };

      debugPrint('========== EXAM SUBMISSION DEBUG ==========');
      debugPrint('Exam ID (catalog): ${widget.exam.id}');
      debugPrint('Exam External ID: ${widget.exam.externalId}');
      debugPrint('Submitting with examId: $examId');
      debugPrint('Total answers: ${_answers.length}');
      debugPrint('Submit URL: ${ApiConstants.baseUrl}/exams/submit');
      debugPrint('Request body: ${json.encode(requestBody)}');
      debugPrint('Token present: ${widget.token != null}');
      debugPrint('Token length: ${widget.token?.length ?? 0}');
      debugPrint('==========================================');

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/exams/submit'),
        headers: {
          'Content-Type': 'application/json',
          if (widget.token != null) 'Authorization': 'Bearer ${widget.token}',
        },
        body: json.encode(requestBody),
      );

      debugPrint('Submit Response Status: ${response.statusCode}');
      debugPrint('Submit Response Body: ${response.body}');

      Navigator.pop(context); // Close loading

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        debugPrint('Exam submitted successfully!');
        _navigateToResult(result);
      } else {
        debugPrint('Submit failed with status: ${response.statusCode}');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
          content: Text('Failed to submit exam (${response.statusCode})'),
        ));
      }
    } catch (e) {
      debugPrint('Submit Exception: $e');
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _navigateToResult(Map<String, dynamic> result) {
    debugPrint('========== RESULT CALCULATION DEBUG ==========');
    debugPrint('Result data: ${json.encode(result)}');

    // Calculate part scores from the result
    final Map<String, int> partScores = {};
    // Backend returns answers in 'details' field, not 'answers'
    final answersData = result['details'] as List? ?? result['answers'] as List? ?? [];

    debugPrint('Total answers in result: ${answersData.length}');

    // Map question IDs to their parts
    final Map<int, String> questionToPart = {};
    for (var part in _examDetail!.parts) {
      debugPrint('Processing part: ${part.name}');
      for (var section in part.sections) {
        for (var group in section.questionGroups) {
          for (var question in group.questions) {
            questionToPart[question.id] = part.name;
            debugPrint('  - Question ID ${question.id} -> ${part.name}');
          }
        }
      }
    }

    debugPrint('Total question mappings: ${questionToPart.length}');
    debugPrint('Question IDs mapped: ${questionToPart.keys.toList()}');

    // Calculate scores per part
    int unmappedCount = 0;

    // Log first answer structure to see available fields
    if (answersData.isNotEmpty) {
      debugPrint('Sample answer structure: ${json.encode(answersData[0])}');
    }

    for (var answer in answersData) {
      final questionId = answer['questionId'] as int? ?? 0;
      final isCorrect = answer['isCorrect'] as bool? ?? false;
      final score = answer['score'] as num? ?? answer['points'] as num? ?? 0;
      final partName = questionToPart[questionId];

      debugPrint('Answer - QuestionID: $questionId, IsCorrect: $isCorrect, Score: $score, MappedPart: $partName');

      if (partName != null) {
        // If backend provides score/points per question, use that; otherwise count correct answers
        if (score > 0 && isCorrect) {
          partScores[partName] = (partScores[partName] ?? 0) + score.toInt();
        } else {
          partScores[partName] = (partScores[partName] ?? 0) + (isCorrect ? 1 : 0);
        }
      } else {
        unmappedCount++;
        debugPrint('  WARNING: Question ID $questionId not found in exam detail!');
      }
    }

    debugPrint('Part correct counts: $partScores');
    debugPrint('Unmapped questions: $unmappedCount');

    // Since backend doesn't provide per-question scores, calculate proportionally
    // based on the total score and distribution of correct answers
    final totalCorrect = partScores.values.fold(0, (sum, count) => sum + count);
    final yourScore = result['yourScore'] as int? ?? 0;

    debugPrint('Total correct answers: $totalCorrect');
    debugPrint('Your total score: $yourScore');

    // Calculate proportional scores for each part
    final Map<String, int> calculatedPartScores = {};
    if (totalCorrect > 0) {
      for (var entry in partScores.entries) {
        final partName = entry.key;
        final correctCount = entry.value;
        // Distribute the total score proportionally based on correct answers
        final partScore = ((correctCount / totalCorrect) * yourScore).round();
        calculatedPartScores[partName] = partScore;
        debugPrint('$partName: $correctCount correct → $partScore points');
      }
    }

    debugPrint('Final calculated part scores: $calculatedPartScores');
    debugPrint('============================================');

    // Get level string from exam level
    final levelMap = {5: 'N5', 4: 'N4', 3: 'N3', 2: 'N2', 1: 'N1'};
    final level = levelMap[widget.exam.level] ?? 'N5';

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => ExamResultScreen(
          exam: widget.exam,
          level: level,
          yourScore: result['yourScore'] as int? ?? 0,
          totalScore: result['totalScore'] as int? ?? widget.exam.totalScore,
          isPassed: result['isPassed'] as bool? ?? false,
          candidateName: widget.userName ?? 'Test Candidate',
          parts: _examDetail!.parts,
          partScores: calculatedPartScores,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: AppColors.tealAccent),
              const SizedBox(height: 16),
              Text(
                'Loading exam...',
                style: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.backgroundLight,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(_error!, style: TextStyle(color: Colors.red[300])),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final selectedAnswer = _answers[currentQuestion.question.id];
    final isFlagged = _flaggedQuestions.contains(currentQuestion.question.id);
    final isStarred = _starredQuestions.contains(currentQuestion.question.id);

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Column(
        children: [
          // Status bar safe area
          SizedBox(height: MediaQuery.of(context).padding.top + 12),
          // Header
          _buildHeader(isDark),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Question Card
                  _buildQuestionCard(currentQuestion, isFlagged, isDark),
                  const SizedBox(height: 20),
                  // Options
                  _buildOptions(
                    currentQuestion.question,
                    selectedAnswer,
                    isDark,
                  ),
                  const SizedBox(height: 100), // Space for bottom bar
                ],
              ),
            ),
          ),
        ],
      ),
      // Bottom Action Bar
      bottomSheet: _buildBottomBar(isStarred, isDark),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        children: [
          // Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PROGRESS',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '${(_currentQuestionIndex + 1).toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                    Text(
                      ' / ${_questions.length}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (_currentQuestionIndex + 1) / _questions.length,
                    backgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation(AppColors.tealAccent),
                    minHeight: 4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // Timer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.tealAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 18,
                  color: AppColors.tealAccent,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatTime(_remainingSeconds),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.tealAccent,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Pause Button
          IconButton(
            onPressed: _showPauseDialog,
            icon: Icon(
              Icons.pause_circle_outline,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          // Overview Button
          IconButton(
            onPressed: _showOverview,
            icon: Icon(
              Icons.grid_view_rounded,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(
    FlatQuestion flatQuestion,
    bool isFlagged,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Badge and Flag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  flatQuestion.sectionKind.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight,
                  ),
                ),
              ),
              IconButton(
                onPressed: _toggleFlag,
                icon: Icon(
                  isFlagged ? Icons.flag : Icons.flag_outlined,
                  size: 20,
                  color: isFlagged
                      ? Colors.orange
                      : (isDark ? Colors.grey[600] : Colors.grey[400]),
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Instruction
          Text(
            flatQuestion.groupTitle,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 16),
          // Question
          Text(
            flatQuestion.question.question,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              height: 1.5,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptions(
    QuestionModel question,
    int? selectedAnswer,
    bool isDark,
  ) {
    final allAnswers = [
      question.answer1,
      question.answer2,
      question.answer3,
      question.answer4,
    ];

    // Filter out empty answers
    final validAnswers = <MapEntry<int, String>>[];
    for (int i = 0; i < allAnswers.length; i++) {
      if (allAnswers[i].trim().isNotEmpty) {
        validAnswers.add(MapEntry(i + 1, allAnswers[i]));
      }
    }

    return Column(
      children: validAnswers.map((entry) {
        final answerNumber = entry.key;
        final answerText = entry.value;
        final isSelected = selectedAnswer == answerNumber;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTap: () => _selectAnswer(answerNumber),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.tealAccent.withValues(alpha: 0.1)
                    : (isDark ? AppColors.cardBackgroundDark : Colors.white),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected
                      ? AppColors.tealAccent
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Number Circle
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.tealAccent
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.tealAccent
                            : (isDark ? Colors.grey[600]! : Colors.grey[300]!),
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$answerNumber',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.grey[400] : Colors.grey[500]),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Answer Text
                  Expanded(
                    child: Text(
                      answerText,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                  // Check Icon
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: AppColors.tealAccent,
                      size: 24,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildBottomBar(bool isStarred, bool isDark) {
    final isLastQuestion = _currentQuestionIndex == _questions.length - 1;

    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          // Star/Bookmark Button
          GestureDetector(
            onTap: _toggleStar,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isStarred
                      ? Colors.amber
                      : (isDark ? AppColors.borderDark : AppColors.borderLight),
                ),
                color: isStarred
                    ? Colors.amber.withValues(alpha: 0.1)
                    : Colors.transparent,
              ),
              child: Icon(
                isStarred ? Icons.star : Icons.star_border,
                color: isStarred
                    ? Colors.amber
                    : (isDark ? Colors.grey[600] : Colors.grey[400]),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Next/Submit Button
          Expanded(
            child: ElevatedButton(
              onPressed: isLastQuestion ? _submitExam : _nextQuestion,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.tealAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: AppColors.tealAccent.withValues(alpha: 0.3),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLastQuestion ? 'Submit Exam' : 'Next Question',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isLastQuestion ? Icons.check : Icons.arrow_forward,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
