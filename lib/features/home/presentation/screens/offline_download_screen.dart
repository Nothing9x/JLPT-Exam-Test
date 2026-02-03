import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/offline_data_models.dart';
import '../../data/services/offline_download_service.dart';
import '../../data/services/offline_storage_service.dart';

class OfflineDownloadScreen extends StatefulWidget {
  final String? token;

  const OfflineDownloadScreen({
    super.key,
    this.token,
  });

  @override
  State<OfflineDownloadScreen> createState() => _OfflineDownloadScreenState();
}

class _OfflineDownloadScreenState extends State<OfflineDownloadScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late OfflineDownloadService _downloadService;
  late OfflineStorageService _storageService;
  
  bool _isLoading = true;
  DownloadCatalog? _catalog;
  Map<int, DownloadProgress> _examProgress = {};
  Map<String, DownloadProgress> _questionProgress = {};
  StreamSubscription<DownloadProgress>? _progressSubscription;

  // Estimated sizes for each level (in bytes) - placeholder values
  static const Map<int, int> _estimatedExamSizes = {
    1: 157286400, // ~150 MB
    2: 141557760, // ~135 MB
    3: 125829120, // ~120 MB
    4: 104857600, // ~100 MB
    5: 94371840,  // ~90 MB
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _storageService = OfflineStorageService();
    _downloadService = OfflineDownloadService(
      storage: _storageService,
      token: widget.token,
    );
    _loadData();
    _listenToProgress();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _progressSubscription?.cancel();
    _downloadService.dispose();
    super.dispose();
  }

  void _listenToProgress() {
    _progressSubscription = _downloadService.progressStream.listen((progress) {
      setState(() {
        if (progress.category == null) {
          _examProgress[progress.level] = progress;
        } else {
          _questionProgress['${progress.category}_${progress.level}'] = progress;
        }
      });
    });
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Load catalog
      _catalog = await _downloadService.fetchCatalog();

      // Load existing progress
      final allProgress = await _downloadService.getAllProgress();
      for (final progress in allProgress) {
        if (progress.category == null) {
          _examProgress[progress.level] = progress;
        } else {
          _questionProgress['${progress.category}_${progress.level}'] = progress;
        }
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    }

    setState(() => _isLoading = false);
  }

  DownloadProgress _getExamProgress(int level) {
    return _examProgress[level] ??
        DownloadProgress(level: level, status: DownloadStatus.notDownloaded);
  }

  DownloadProgress _getQuestionProgress(String category, int level) {
    return _questionProgress['${category}_$level'] ??
        DownloadProgress(
          level: level,
          category: category,
          status: DownloadStatus.notDownloaded,
        );
  }

  Future<void> _downloadExams(int level) async {
    try {
      await _downloadService.downloadExamsForLevel(level);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  Future<void> _downloadQuestions(String category, int level) async {
    try {
      await _downloadService.downloadQuestions(
        category: category,
        level: level,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Download failed: $e')),
        );
      }
    }
  }

  Future<void> _deleteExams(int level) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Offline Data'),
        content: Text('Delete all downloaded data for JLPT N$level?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _downloadService.deleteExamData(level);
      setState(() {
        _examProgress[level] = DownloadProgress(
          level: level,
          status: DownloadStatus.notDownloaded,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildTabBar(isDark),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildExamsTab(isDark),
                        _buildPracticeTab(isDark),
                      ],
                    ),
            ),
            _buildBottomInfo(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 12, 16, 12),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.backgroundDark.withValues(alpha: 0.9)
            : AppColors.backgroundLight.withValues(alpha: 0.9),
        border: Border(
          bottom: BorderSide(
            color: AppColors.primary.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : AppColors.textPrimaryLight,
              size: 22,
            ),
          ),
          Expanded(
            child: Text(
              'Offline Data Download',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
          ),
          const SizedBox(width: 48), // Balance the back button
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800]!.withValues(alpha: 0.5) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
          ),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[600],
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          tabs: const [
            Tab(text: 'Exams'),
            Tab(text: 'Practice'),
          ],
        ),
      ),
    );
  }

  Widget _buildExamsTab(bool isDark) {
    // Use catalog data if available, otherwise show default 5 levels
    final examPackCount = _catalog?.examPacks.length ?? 5;
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: examPackCount,
      itemBuilder: (context, index) {
        final level = index + 1;
        final progress = _getExamProgress(level);
        
        // Get size from catalog if available
        int estimatedSize = _estimatedExamSizes[level] ?? 100 * 1024 * 1024;
        if (_catalog != null && index < _catalog!.examPacks.length) {
          estimatedSize = _catalog!.examPacks[index].totalSize;
        }
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildDownloadCard(
            isDark: isDark,
            title: 'JLPT N$level',
            size: _formatSize(estimatedSize),
            progress: progress,
            onDownload: () => _downloadExams(level),
            onDelete: () => _deleteExams(level),
            onCancel: () => _downloadService.cancelExamDownload(level),
          ),
        );
      },
    );
  }

  Widget _buildPracticeTab(bool isDark) {
    final categories = ['VOCABULARY', 'GRAMMAR', 'READING', 'LISTENING'];
    final categoryIcons = {
      'VOCABULARY': Icons.text_fields,
      'GRAMMAR': Icons.edit_note,
      'READING': Icons.menu_book,
      'LISTENING': Icons.headphones,
    };
    final categorySizes = {
      'VOCABULARY': 50 * 1024 * 1024, // 50 MB
      'GRAMMAR': 40 * 1024 * 1024,    // 40 MB
      'READING': 60 * 1024 * 1024,    // 60 MB
      'LISTENING': 200 * 1024 * 1024, // 200 MB (has audio)
    };

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: categories.length * 5, // Each category for each level
      itemBuilder: (context, index) {
        final categoryIndex = index ~/ 5;
        final level = (index % 5) + 1;
        final category = categories[categoryIndex];
        final progress = _getQuestionProgress(category, level);
        
        // Show category header
        if (index % 5 == 0) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (index > 0) const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      categoryIcons[category],
                      size: 20,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              _buildPracticeCard(
                isDark: isDark,
                category: category,
                level: level,
                size: categorySizes[category] ?? 50 * 1024 * 1024,
                progress: progress,
              ),
            ],
          );
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildPracticeCard(
            isDark: isDark,
            category: category,
            level: level,
            size: categorySizes[category] ?? 50 * 1024 * 1024,
            progress: progress,
          ),
        );
      },
    );
  }

  Widget _buildPracticeCard({
    required bool isDark,
    required String category,
    required int level,
    required int size,
    required DownloadProgress progress,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _buildDownloadCard(
        isDark: isDark,
        title: '$category N$level',
        size: _formatSize(size),
        progress: progress,
        onDownload: () => _downloadQuestions(category, level),
        onDelete: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Offline Data'),
              content: Text('Delete all downloaded $category data for N$level?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
          if (confirm == true) {
            await _downloadService.deleteQuestionData(category, level);
            setState(() {
              _questionProgress['${category}_$level'] = DownloadProgress(
                level: level,
                category: category,
                status: DownloadStatus.notDownloaded,
              );
            });
          }
        },
        onCancel: () => _downloadService.cancelQuestionDownload(category, level),
      ),
    );
  }

  Widget _buildDownloadCard({
    required bool isDark,
    required String title,
    required String size,
    required DownloadProgress progress,
    required VoidCallback onDownload,
    required VoidCallback onDelete,
    required VoidCallback onCancel,
  }) {
    final isDownloading = progress.status == DownloadStatus.downloading;
    final isDownloaded = progress.status == DownloadStatus.downloaded;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDownloading
            ? Border.all(color: AppColors.primary.withValues(alpha: 0.4))
            : null,
        boxShadow: [
          BoxShadow(
            color: isDownloading
                ? AppColors.primary.withValues(alpha: 0.1)
                : (isDark ? Colors.transparent : AppColors.shadowPink),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDownloaded
                        ? AppColors.accentGreen.withValues(alpha: 0.1)
                        : (isDark ? Colors.grey[700] : Colors.grey[50]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDownloaded
                        ? Icons.menu_book
                        : (isDownloading ? Icons.downloading : Icons.school),
                    color: isDownloaded ? AppColors.accentGreen : AppColors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                // Title and status
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimaryLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildStatusText(isDark, progress, size),
                    ],
                  ),
                ),
                // Action button
                _buildActionButton(
                  isDark: isDark,
                  progress: progress,
                  onDownload: onDownload,
                  onDelete: onDelete,
                  onCancel: onCancel,
                ),
              ],
            ),
          ),
          // Progress bar for downloading
          if (isDownloading)
            Container(
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress.progress,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusText(bool isDark, DownloadProgress progress, String size) {
    switch (progress.status) {
      case DownloadStatus.downloading:
        return Text(
          'Downloading...',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        );
      case DownloadStatus.downloaded:
        return Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.accentGreen,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'Ready for offline use',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.accentGreen,
              ),
            ),
          ],
        );
      case DownloadStatus.error:
        return Text(
          'Download failed - Tap to retry',
          style: TextStyle(
            fontSize: 12,
            color: Colors.red[400],
          ),
        );
      default:
        return Text(
          size,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        );
    }
  }

  Widget _buildActionButton({
    required bool isDark,
    required DownloadProgress progress,
    required VoidCallback onDownload,
    required VoidCallback onDelete,
    required VoidCallback onCancel,
  }) {
    switch (progress.status) {
      case DownloadStatus.downloading:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${(progress.progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: progress.progress,
                strokeWidth: 2,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ],
        );

      case DownloadStatus.downloaded:
        return GestureDetector(
          onTap: onDelete,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accentGreen.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Downloaded',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentGreen,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: AppColors.accentGreen,
                ),
              ],
            ),
          ),
        );

      default:
        return GestureDetector(
          onTap: onDownload,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Download',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.download,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        );
    }
  }

  Widget _buildBottomInfo(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Downloaded exams are available for 30 days without internet connection.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.grey[500] : Colors.grey[600],
        ),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(0)} MB';
  }
}
