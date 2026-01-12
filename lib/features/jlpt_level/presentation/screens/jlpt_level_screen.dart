import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/jlpt_level_model.dart';
import '../../../auth/presentation/screens/sign_up_screen.dart';
import '../widgets/jlpt_level_card.dart';

class JlptLevelScreen extends StatefulWidget {
  final String languageCode;

  const JlptLevelScreen({
    super.key,
    required this.languageCode,
  });

  @override
  State<JlptLevelScreen> createState() => _JlptLevelScreenState();
}

class _JlptLevelScreenState extends State<JlptLevelScreen> {
  String _selectedLevel = 'n5';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          width: screenSize.width,
          height: screenSize.height,
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : AppColors.mintLight,
          ),
          child: Stack(
            children: [
              // Top gradient
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 200,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isDark
                          ? [
                              AppColors.tealAccent.withValues(alpha: 0.1),
                              Colors.transparent,
                            ]
                          : [
                              AppColors.mintGradient,
                              Colors.transparent,
                            ],
                    ),
                  ),
                ),
              ),
              // Main content
              SafeArea(
                child: Column(
                  children: [
                    _buildHeader(context, isDark),
                    Expanded(
                      child: _buildContent(isDark),
                    ),
                    _buildBottomButton(context, isDark),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 24, 16),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          // Progress bar
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.25,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.tealAccent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Ninja mascot
          _buildMascot(isDark),
          const SizedBox(height: 24),
          // Title
          Text(
            _getLocalizedString('jlpt_level_question'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 24),
          // Level cards
          ...JlptLevelModel.levels.map((level) {
            final isSelected = level.id == _selectedLevel;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: JlptLevelCard(
                level: level,
                title: level.titleKey.startsWith('JLPT')
                    ? level.titleKey
                    : _getLocalizedString(level.titleKey),
                description: _getLocalizedString(level.descKey),
                isSelected: isSelected,
                onTap: () {
                  setState(() {
                    _selectedLevel = level.id;
                  });
                },
              ),
            );
          }),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildMascot(bool isDark) {
    return Container(
      width: 140,
      height: 140,
      margin: const EdgeInsets.only(top: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.tealAccent.withValues(alpha: 0.15)
                  : const Color(0xFFE0F7F4),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.tealAccent.withValues(alpha: 0.2),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
          // Ninja image
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              'https://lh3.googleusercontent.com/aida-public/AB6AXuAMiAdzbAQKtTK2zSjf5v4IH_xt3GVLwqmqkPET6u5Wci7m5xcAPLc0BMngnhxNma0lYyhmnCbfr64F467RBRJeRLgSr1WArUSjYFB6YfpKmE53nwaX89610I8qUkF40Z6X4Ptwvb-u8xDDSIT0BVN1G89ozV2mLkk6Q4sVPmR1Az9SE26Hp3ml9O1CDCbBzwuux0d-w5Xn41KXWjgyi2H5gbr_AjMFUVuTVdF5p3cJUt2ApBiyFo0r8t2Nfk82SCZfub9vFx7VxA',
              width: 100,
              height: 100,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.tealAccent,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.person,
                  size: 60,
                  color: Colors.grey,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomButton(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  AppColors.backgroundDark.withValues(alpha: 0),
                  AppColors.backgroundDark,
                  AppColors.backgroundDark,
                ]
              : [
                  AppColors.mintLight.withValues(alpha: 0),
                  AppColors.mintLight,
                  AppColors.mintLight,
                ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                // Convert level string to API level integer
                // beginner = null, n5 = 5, n4 = 4, n3 = 3, n2 = 2, n1 = 1
                int? levelValue;
                switch (_selectedLevel) {
                  case 'n5':
                    levelValue = 5;
                    break;
                  case 'n4':
                    levelValue = 4;
                    break;
                  case 'n3':
                    levelValue = 3;
                    break;
                  case 'n2':
                    levelValue = 2;
                    break;
                  case 'n1':
                    levelValue = 1;
                    break;
                  default:
                    levelValue = null; // beginner
                }
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SignUpScreen(
                      languageCode: widget.languageCode,
                      selectedLevel: levelValue,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? Colors.white : AppColors.buttonDark,
                foregroundColor:
                    isDark ? AppColors.buttonDark : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              child: Text(
                _getLocalizedString('continue_button'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Home indicator
          Container(
            width: 128,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  String _getLocalizedString(String key) {
    return _localizedStrings[widget.languageCode]?[key] ??
        _localizedStrings['en']?[key] ??
        key;
  }

  static const Map<String, Map<String, String>> _localizedStrings = {
    'ja': {
      'jlpt_level_question': 'あなたのJLPTレベルは\nどのくらいですか？',
      'beginner': '初心者',
      'beginner_desc': '日本語についてまだ何も知らない',
      'n5_desc': '日本語学習を始めたばかり',
      'n4_desc': '簡単な会話を理解できる',
      'n3_desc': '読解と基本的なコミュニケーション',
      'n2_desc': '仕事で日本語を使える',
      'n1_desc': 'ネイティブレベル',
      'continue_button': '続ける',
    },
    'en': {
      'jlpt_level_question': 'What is your current\nJLPT level?',
      'beginner': 'Beginner',
      'beginner_desc': "Don't know anything about Japanese",
      'n5_desc': 'Just started learning Japanese',
      'n4_desc': 'Understand simple conversations',
      'n3_desc': 'Reading comprehension and basic communication',
      'n2_desc': 'Proficient for work use',
      'n1_desc': 'Native-like proficiency',
      'continue_button': 'Continue',
    },
    'vn': {
      'jlpt_level_question': 'Trình độ JLPT của bạn\nđang ở cấp độ nào?',
      'beginner': 'Người mới',
      'beginner_desc': 'Chưa biết gì về tiếng Nhật',
      'n5_desc': 'Mới bắt đầu học tiếng Nhật',
      'n4_desc': 'Hiểu hội thoại đơn giản',
      'n3_desc': 'Đọc hiểu và giao tiếp cơ bản',
      'n2_desc': 'Sử dụng tốt trong công việc',
      'n1_desc': 'Thành thạo như người bản xứ',
      'continue_button': 'Tiếp tục',
    },
    'es_auto': {
      'jlpt_level_question': '¿Cuál es tu nivel\nactual de JLPT?',
      'beginner': 'Principiante',
      'beginner_desc': 'No sé nada de japonés',
      'n5_desc': 'Acabo de empezar a aprender japonés',
      'n4_desc': 'Entiendo conversaciones simples',
      'n3_desc': 'Comprensión lectora y comunicación básica',
      'n2_desc': 'Competente para uso laboral',
      'n1_desc': 'Dominio nativo',
      'continue_button': 'Continuar',
    },
    'fr_auto': {
      'jlpt_level_question': 'Quel est votre niveau\nJLPT actuel ?',
      'beginner': 'Débutant',
      'beginner_desc': 'Je ne connais rien au japonais',
      'n5_desc': 'Je viens de commencer à apprendre le japonais',
      'n4_desc': 'Je comprends les conversations simples',
      'n3_desc': 'Compréhension écrite et communication de base',
      'n2_desc': 'Compétent pour le travail',
      'n1_desc': 'Maîtrise native',
      'continue_button': 'Continuer',
    },
    'cn_auto': {
      'jlpt_level_question': '您目前的JLPT\n水平是多少？',
      'beginner': '初学者',
      'beginner_desc': '对日语一无所知',
      'n5_desc': '刚开始学习日语',
      'n4_desc': '能理解简单对话',
      'n3_desc': '阅读理解和基本交流',
      'n2_desc': '可用于工作',
      'n1_desc': '母语水平',
      'continue_button': '继续',
    },
    'tw_auto': {
      'jlpt_level_question': '您目前的JLPT\n程度是多少？',
      'beginner': '初學者',
      'beginner_desc': '對日語一無所知',
      'n5_desc': '剛開始學習日語',
      'n4_desc': '能理解簡單對話',
      'n3_desc': '閱讀理解和基本交流',
      'n2_desc': '可用於工作',
      'n1_desc': '母語程度',
      'continue_button': '繼續',
    },
    'ru_auto': {
      'jlpt_level_question': 'Какой у вас текущий\nуровень JLPT?',
      'beginner': 'Начинающий',
      'beginner_desc': 'Ничего не знаю о японском',
      'n5_desc': 'Только начал изучать японский',
      'n4_desc': 'Понимаю простые разговоры',
      'n3_desc': 'Чтение и базовое общение',
      'n2_desc': 'Владею для работы',
      'n1_desc': 'Владение на уровне носителя',
      'continue_button': 'Продолжить',
    },
    'id_auto': {
      'jlpt_level_question': 'Berapa level JLPT\nAnda saat ini?',
      'beginner': 'Pemula',
      'beginner_desc': 'Tidak tahu apa-apa tentang bahasa Jepang',
      'n5_desc': 'Baru mulai belajar bahasa Jepang',
      'n4_desc': 'Memahami percakapan sederhana',
      'n3_desc': 'Pemahaman membaca dan komunikasi dasar',
      'n2_desc': 'Mahir untuk pekerjaan',
      'n1_desc': 'Kemahiran seperti penutur asli',
      'continue_button': 'Lanjutkan',
    },
    'ko_auto': {
      'jlpt_level_question': '현재 JLPT 레벨이\n어떻게 되시나요?',
      'beginner': '초보자',
      'beginner_desc': '일본어에 대해 아무것도 모름',
      'n5_desc': '일본어 학습을 막 시작함',
      'n4_desc': '간단한 대화를 이해함',
      'n3_desc': '독해 및 기본 의사소통',
      'n2_desc': '업무에 능숙하게 사용',
      'n1_desc': '원어민 수준',
      'continue_button': '계속',
    },
    'my_auto': {
      'jlpt_level_question': 'Apakah tahap JLPT\nanda sekarang?',
      'beginner': 'Pemula',
      'beginner_desc': 'Tidak tahu apa-apa tentang bahasa Jepun',
      'n5_desc': 'Baru mula belajar bahasa Jepun',
      'n4_desc': 'Faham perbualan mudah',
      'n3_desc': 'Pemahaman bacaan dan komunikasi asas',
      'n2_desc': 'Mahir untuk kerja',
      'n1_desc': 'Kemahiran seperti penutur asli',
      'continue_button': 'Teruskan',
    },
    'pt_auto': {
      'jlpt_level_question': 'Qual é o seu nível\natual de JLPT?',
      'beginner': 'Iniciante',
      'beginner_desc': 'Não sei nada sobre japonês',
      'n5_desc': 'Acabei de começar a aprender japonês',
      'n4_desc': 'Entendo conversas simples',
      'n3_desc': 'Compreensão de leitura e comunicação básica',
      'n2_desc': 'Proficiente para trabalho',
      'n1_desc': 'Proficiência nativa',
      'continue_button': 'Continuar',
    },
    'cn': {
      'jlpt_level_question': '您目前的JLPT\n水平是多少？',
      'beginner': '初学者',
      'beginner_desc': '对日语一无所知',
      'n5_desc': '刚开始学习日语',
      'n4_desc': '能理解简单对话',
      'n3_desc': '阅读理解和基本交流',
      'n2_desc': '可用于工作',
      'n1_desc': '母语水平',
      'continue_button': '继续',
    },
  };
}
