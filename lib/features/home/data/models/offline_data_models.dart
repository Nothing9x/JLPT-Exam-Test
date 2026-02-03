/// Models for offline data download and storage
/// Based on API documentation sections 10 and 11 (ZIP Download APIs)

/// Helper function to parse generatedAt which can be String or List
String _parseGeneratedAt(dynamic value) {
  if (value is String) {
    return value;
  } else if (value is List && value.isNotEmpty) {
    // Format: [year, month, day, hour, minute, second, microseconds]
    try {
      final year = value[0] as int;
      final month = value.length > 1 ? value[1] as int : 1;
      final day = value.length > 2 ? value[2] as int : 1;
      final hour = value.length > 3 ? value[3] as int : 0;
      final minute = value.length > 4 ? value[4] as int : 0;
      final second = value.length > 5 ? value[5] as int : 0;
      return DateTime(year, month, day, hour, minute, second).toIso8601String();
    } catch (_) {
      return value.toString();
    }
  }
  return '';
}

// ==================== ZIP Catalog Models ======================================

/// Download catalog containing available ZIP exam and question packs
class DownloadCatalog {
  final String version;
  final String generatedAt;
  final List<ExamPackInfo> examPacks;
  final List<QuestionPackInfo> questionPacks;

  DownloadCatalog({
    required this.version,
    required this.generatedAt,
    required this.examPacks,
    required this.questionPacks,
  });

  factory DownloadCatalog.fromJson(Map<String, dynamic> json) {
    return DownloadCatalog(
      version: json['version'] ?? '1.0',
      generatedAt: _parseGeneratedAt(json['generatedAt']),
      // Support both old 'examPacks' and new 'examZips' keys
      examPacks: (json['examZips'] as List?)
              ?.map((e) => ExamPackInfo.fromJson(e))
              .toList() ??
          (json['examPacks'] as List?)
              ?.map((e) => ExamPackInfo.fromJson(e))
              .toList() ??
          [],
      // Support both old 'questionPacks' and new 'questionZips' keys
      questionPacks: (json['questionZips'] as List?)
              ?.map((e) => QuestionPackInfo.fromJson(e))
              .toList() ??
          (json['questionPacks'] as List?)
              ?.map((e) => QuestionPackInfo.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Info about an exam ZIP pack available for download
class ExamPackInfo {
  final int level;
  final String? category;
  final String filename;
  final int totalExams;
  final int totalQuestions;
  final int totalAudioFiles;
  final int totalImageFiles;
  final int estimatedSizeBytes;
  final String estimatedSizeMB;

  ExamPackInfo({
    required this.level,
    this.category,
    required this.filename,
    required this.totalExams,
    required this.totalQuestions,
    required this.totalAudioFiles,
    required this.totalImageFiles,
    required this.estimatedSizeBytes,
    required this.estimatedSizeMB,
  });

  factory ExamPackInfo.fromJson(Map<String, dynamic> json) {
    return ExamPackInfo(
      level: json['level'] ?? 0,
      category: json['category'],
      filename: json['filename'] ?? '',
      totalExams: json['totalExams'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      totalAudioFiles: json['totalAudioFiles'] ?? 0,
      totalImageFiles: json['totalImageFiles'] ?? 0,
      estimatedSizeBytes: json['estimatedSizeBytes'] ?? 0,
      estimatedSizeMB: json['estimatedSizeMB'] ?? '0',
    );
  }

  String get levelName => 'N$level';

  String get formattedSize => '$estimatedSizeMB MB';

  // For backward compatibility
  int get examCount => totalExams;
  int get totalSize => estimatedSizeBytes;
}

/// Info about a question ZIP pack available for download
class QuestionPackInfo {
  final int? level;
  final String category;
  final String filename;
  final int totalQuestions;
  final int totalAudioFiles;
  final int totalImageFiles;
  final int estimatedSizeBytes;
  final String estimatedSizeMB;

  QuestionPackInfo({
    this.level,
    required this.category,
    required this.filename,
    required this.totalQuestions,
    required this.totalAudioFiles,
    required this.totalImageFiles,
    required this.estimatedSizeBytes,
    required this.estimatedSizeMB,
  });

  factory QuestionPackInfo.fromJson(Map<String, dynamic> json) {
    return QuestionPackInfo(
      level: json['level'],
      category: json['category'] ?? '',
      filename: json['filename'] ?? '',
      totalQuestions: json['totalQuestions'] ?? 0,
      totalAudioFiles: json['totalAudioFiles'] ?? 0,
      totalImageFiles: json['totalImageFiles'] ?? 0,
      estimatedSizeBytes: json['estimatedSizeBytes'] ?? 0,
      estimatedSizeMB: json['estimatedSizeMB'] ?? '0',
    );
  }

  String? get levelName => level != null ? 'N$level' : null;

  String get formattedSize => '$estimatedSizeMB MB';

  // For backward compatibility
  int get questionCount => totalQuestions;
  int get totalSize => estimatedSizeBytes;

  String get displayName {
    if (level != null) {
      return '$category - N$level';
    }
    return '$category (All Levels)';
  }
}

/// Manifest file inside ZIP
class ZipManifest {
  final String version;
  final String type; // "exam_pack" or "question_pack"
  final int? level;
  final String? category;
  final int? totalExams;
  final int totalQuestions;
  final int totalAudioFiles;
  final int totalImageFiles;
  final int includedAudioFiles;
  final int includedImageFiles;

  ZipManifest({
    required this.version,
    required this.type,
    this.level,
    this.category,
    this.totalExams,
    required this.totalQuestions,
    required this.totalAudioFiles,
    required this.totalImageFiles,
    required this.includedAudioFiles,
    required this.includedImageFiles,
  });

  factory ZipManifest.fromJson(Map<String, dynamic> json) {
    return ZipManifest(
      version: json['version'] ?? '1.0',
      type: json['type'] ?? '',
      level: json['level'],
      category: json['category'],
      totalExams: json['totalExams'],
      totalQuestions: json['totalQuestions'] ?? 0,
      totalAudioFiles: json['totalAudioFiles'] ?? 0,
      totalImageFiles: json['totalImageFiles'] ?? 0,
      includedAudioFiles: json['includedAudioFiles'] ?? 0,
      includedImageFiles: json['includedImageFiles'] ?? 0,
    );
  }
}

// ==================== Exam Download Models ====================

/// Full exam data download response
class ExamDownloadData {
  final String version;
  final String generatedAt;
  final int level;
  final String levelName;
  final int totalExams;
  final int totalQuestions;
  final List<OfflineExam> exams;

  ExamDownloadData({
    required this.version,
    required this.generatedAt,
    required this.level,
    required this.levelName,
    required this.totalExams,
    required this.totalQuestions,
    required this.exams,
  });

  factory ExamDownloadData.fromJson(Map<String, dynamic> json) {
    return ExamDownloadData(
      version: json['version'] ?? '1.0',
      generatedAt: _parseGeneratedAt(json['generatedAt']),
      level: json['level'] ?? 0,
      levelName: json['levelName'] ?? '',
      totalExams: json['totalExams'] ?? 0,
      totalQuestions: json['totalQuestions'] ?? 0,
      exams: (json['exams'] as List?)
              ?.map((e) => OfflineExam.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'generatedAt': generatedAt,
        'level': level,
        'levelName': levelName,
        'totalExams': totalExams,
        'totalQuestions': totalQuestions,
        'exams': exams.map((e) => e.toJson()).toList(),
      };
}

/// Offline exam with full data
class OfflineExam {
  final int id;
  final String title;
  final int time;
  final int score;
  final int passScore;
  final List<OfflineExamPart> parts;

  OfflineExam({
    required this.id,
    required this.title,
    required this.time,
    required this.score,
    required this.passScore,
    required this.parts,
  });

  factory OfflineExam.fromJson(Map<String, dynamic> json) {
    return OfflineExam(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      time: json['time'] ?? 0,
      score: json['score'] ?? 180,
      passScore: json['passScore'] ?? 100,
      parts: (json['parts'] as List?)
              ?.map((e) => OfflineExamPart.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'time': time,
        'score': score,
        'passScore': passScore,
        'parts': parts.map((e) => e.toJson()).toList(),
      };

  int get questionCount {
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

/// Exam part (e.g., 言語知識・読解, 聴解)
class OfflineExamPart {
  final int id;
  final String name;
  final int time;
  final int minScore;
  final int maxScore;
  final List<OfflineExamSection> sections;

  OfflineExamPart({
    required this.id,
    required this.name,
    required this.time,
    required this.minScore,
    required this.maxScore,
    required this.sections,
  });

  factory OfflineExamPart.fromJson(Map<String, dynamic> json) {
    return OfflineExamPart(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      time: json['time'] ?? 0,
      minScore: json['minScore'] ?? 0,
      maxScore: json['maxScore'] ?? 60,
      sections: (json['sections'] as List?)
              ?.map((e) => OfflineExamSection.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'time': time,
        'minScore': minScore,
        'maxScore': maxScore,
        'sections': sections.map((e) => e.toJson()).toList(),
      };
}

/// Exam section (e.g., 文字・語彙, 文法, 読解, 聴解)
class OfflineExamSection {
  final int id;
  final String kind;
  final List<OfflineQuestionGroup> questionGroups;

  OfflineExamSection({
    required this.id,
    required this.kind,
    required this.questionGroups,
  });

  factory OfflineExamSection.fromJson(Map<String, dynamic> json) {
    return OfflineExamSection(
      id: json['id'] ?? 0,
      kind: json['kind'] ?? '',
      questionGroups: (json['questionGroups'] as List?)
              ?.map((e) => OfflineQuestionGroup.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind,
        'questionGroups': questionGroups.map((e) => e.toJson()).toList(),
      };
}

/// Group of questions with shared context (passage, audio, etc.)
class OfflineQuestionGroup {
  final int id;
  final String? title;
  final String? audio;
  final String? image;
  final String? txtRead;
  final List<OfflineQuestion> questions;

  OfflineQuestionGroup({
    required this.id,
    this.title,
    this.audio,
    this.image,
    this.txtRead,
    required this.questions,
  });

  factory OfflineQuestionGroup.fromJson(Map<String, dynamic> json) {
    return OfflineQuestionGroup(
      id: json['id'] ?? 0,
      title: json['title'],
      audio: json['audio'],
      image: json['image'],
      txtRead: json['txtRead'],
      questions: (json['questions'] as List?)
              ?.map((e) => OfflineQuestion.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'audio': audio,
        'image': image,
        'txtRead': txtRead,
        'questions': questions.map((e) => e.toJson()).toList(),
      };
}

/// Individual question with answer
class OfflineQuestion {
  final int id;
  final String question;
  final List<String> answers;
  final int correctAnswer;
  final String? image;
  final String? audio;
  final String? txtRead;
  final String? groupTitle;
  final String? explain;
  final String? explainEn;
  final String? explainVn;
  final String? explainCn;

  OfflineQuestion({
    required this.id,
    required this.question,
    required this.answers,
    required this.correctAnswer,
    this.image,
    this.audio,
    this.txtRead,
    this.groupTitle,
    this.explain,
    this.explainEn,
    this.explainVn,
    this.explainCn,
  });

  factory OfflineQuestion.fromJson(Map<String, dynamic> json) {
    final answersList = json['answers'] as List? ?? [];
    return OfflineQuestion(
      id: json['id'] ?? 0,
      question: json['question'] ?? '',
      answers: answersList.map((a) => a.toString()).toList(),
      correctAnswer: json['correctAnswer'] ?? 0,
      image: json['image'],
      audio: json['audio'],
      txtRead: json['txtRead'],
      groupTitle: json['groupTitle'],
      explain: json['explain'],
      explainEn: json['explainEn'],
      explainVn: json['explainVn'],
      explainCn: json['explainCn'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'answers': answers,
        'correctAnswer': correctAnswer,
        'image': image,
        'audio': audio,
        'txtRead': txtRead,
        'groupTitle': groupTitle,
        'explain': explain,
        'explainEn': explainEn,
        'explainVn': explainVn,
        'explainCn': explainCn,
      };
}

// ==================== Question Pack Models ====================

/// Question pack download response
class QuestionPackDownloadData {
  final String version;
  final String generatedAt;
  final int? level;
  final String? levelName;
  final String category;
  final int totalQuestions;
  final List<QuestionTypeGroup> types;

  QuestionPackDownloadData({
    required this.version,
    required this.generatedAt,
    this.level,
    this.levelName,
    required this.category,
    required this.totalQuestions,
    required this.types,
  });

  factory QuestionPackDownloadData.fromJson(Map<String, dynamic> json) {
    return QuestionPackDownloadData(
      version: json['version'] ?? '1.0',
      generatedAt: _parseGeneratedAt(json['generatedAt']),
      level: json['level'],
      levelName: json['levelName'],
      category: json['category'] ?? '',
      totalQuestions: json['totalQuestions'] ?? 0,
      types: (json['types'] as List?)
              ?.map((e) => QuestionTypeGroup.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'generatedAt': generatedAt,
        'level': level,
        'levelName': levelName,
        'category': category,
        'totalQuestions': totalQuestions,
        'types': types.map((e) => e.toJson()).toList(),
      };
}

/// Group of questions by type
class QuestionTypeGroup {
  final int typeId;
  final String typeKey;
  final String typeName;
  final int typeLevel;
  final int count;
  final List<OfflineQuestion> questions;

  QuestionTypeGroup({
    required this.typeId,
    required this.typeKey,
    required this.typeName,
    required this.typeLevel,
    required this.count,
    required this.questions,
  });

  factory QuestionTypeGroup.fromJson(Map<String, dynamic> json) {
    return QuestionTypeGroup(
      typeId: json['typeId'] ?? 0,
      typeKey: json['typeKey'] ?? '',
      typeName: json['typeName'] ?? '',
      typeLevel: json['typeLevel'] ?? 0,
      count: json['count'] ?? 0,
      questions: (json['questions'] as List?)
              ?.map((e) => OfflineQuestion.fromJson(e))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'typeId': typeId,
        'typeKey': typeKey,
        'typeName': typeName,
        'typeLevel': typeLevel,
        'count': count,
        'questions': questions.map((e) => e.toJson()).toList(),
      };
}

// ==================== Media Files Models ====================

/// Media files list for offline download
class MediaFilesList {
  final String version;
  final String generatedAt;
  final int level;
  final String? category;
  final int totalFiles;
  final int totalAudioFiles;
  final int totalImageFiles;
  final List<String> audioFiles;
  final List<String> imageFiles;

  MediaFilesList({
    required this.version,
    required this.generatedAt,
    required this.level,
    this.category,
    required this.totalFiles,
    required this.totalAudioFiles,
    required this.totalImageFiles,
    required this.audioFiles,
    required this.imageFiles,
  });

  factory MediaFilesList.fromJson(Map<String, dynamic> json) {
    return MediaFilesList(
      version: json['version'] ?? '1.0',
      generatedAt: _parseGeneratedAt(json['generatedAt']),
      level: json['level'] ?? 0,
      category: json['category'],
      totalFiles: json['totalFiles'] ?? 0,
      totalAudioFiles: json['totalAudioFiles'] ?? 0,
      totalImageFiles: json['totalImageFiles'] ?? 0,
      audioFiles: (json['audioFiles'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      imageFiles: (json['imageFiles'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  List<String> get allFiles => [...audioFiles, ...imageFiles];
}

// ==================== Download Status Models ====================

enum DownloadStatus {
  notDownloaded,
  downloading,
  downloaded,
  updateAvailable,
  error,
}

/// Track download status and progress for each pack
class DownloadProgress {
  final int level;
  final String? category;
  final DownloadStatus status;
  final double progress; // 0.0 to 1.0
  final int downloadedFiles;
  final int totalFiles;
  final String? errorMessage;
  final DateTime? downloadedAt;
  final String? version;

  DownloadProgress({
    required this.level,
    this.category,
    this.status = DownloadStatus.notDownloaded,
    this.progress = 0.0,
    this.downloadedFiles = 0,
    this.totalFiles = 0,
    this.errorMessage,
    this.downloadedAt,
    this.version,
  });

  DownloadProgress copyWith({
    int? level,
    String? category,
    DownloadStatus? status,
    double? progress,
    int? downloadedFiles,
    int? totalFiles,
    String? errorMessage,
    DateTime? downloadedAt,
    String? version,
  }) {
    return DownloadProgress(
      level: level ?? this.level,
      category: category ?? this.category,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      downloadedFiles: downloadedFiles ?? this.downloadedFiles,
      totalFiles: totalFiles ?? this.totalFiles,
      errorMessage: errorMessage ?? this.errorMessage,
      downloadedAt: downloadedAt ?? this.downloadedAt,
      version: version ?? this.version,
    );
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'category': category,
        'status': status.name,
        'progress': progress,
        'downloadedFiles': downloadedFiles,
        'totalFiles': totalFiles,
        'errorMessage': errorMessage,
        'downloadedAt': downloadedAt?.toIso8601String(),
        'version': version,
      };

  factory DownloadProgress.fromJson(Map<String, dynamic> json) {
    return DownloadProgress(
      level: json['level'] ?? 0,
      category: json['category'],
      status: DownloadStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => DownloadStatus.notDownloaded,
      ),
      progress: (json['progress'] ?? 0.0).toDouble(),
      downloadedFiles: json['downloadedFiles'] ?? 0,
      totalFiles: json['totalFiles'] ?? 0,
      errorMessage: json['errorMessage'],
      downloadedAt: json['downloadedAt'] != null
          ? DateTime.tryParse(json['downloadedAt'])
          : null,
      version: json['version'],
    );
  }

  bool get isReadyForOffline =>
      status == DownloadStatus.downloaded && downloadedAt != null;

  /// Check if download is still valid (within 30 days)
  bool get isValid {
    if (downloadedAt == null) return false;
    final expiryDate = downloadedAt!.add(const Duration(days: 30));
    return DateTime.now().isBefore(expiryDate);
  }

  int get daysRemaining {
    if (downloadedAt == null) return 0;
    final expiryDate = downloadedAt!.add(const Duration(days: 30));
    return expiryDate.difference(DateTime.now()).inDays;
  }
}
