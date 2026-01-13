import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../jlpt_level/presentation/screens/jlpt_level_screen.dart';

class WelcomeScreen extends StatelessWidget {
  final String languageCode;

  const WelcomeScreen({
    super.key,
    required this.languageCode,
  });

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
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark
                  ? [
                      AppColors.backgroundDark,
                      AppColors.backgroundDark,
                      AppColors.backgroundDarkSecondary,
                    ]
                  : [
                      AppColors.sakuraPink,
                      AppColors.backgroundLight,
                      AppColors.backgroundLight,
                    ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildStatusBar(isDark),
                Expanded(
                  child: _buildContent(context, isDark),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '9:41',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
            ),
          ),
          Row(
            children: [
              Icon(
                Icons.signal_cellular_alt,
                size: 16,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.wifi,
                size: 16,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              ),
              const SizedBox(width: 4),
              RotatedBox(
                quarterTurns: 1,
                child: Icon(
                  Icons.battery_full,
                  size: 16,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool isDark) {
    return Column(
      children: [
        // Illustration area
        Expanded(
          flex: 5,
          child: _buildIllustration(isDark),
        ),
        // Text and buttons area
        Expanded(
          flex: 4,
          child: _buildBottomSection(context, isDark),
        ),
      ],
    );
  }

  Widget _buildIllustration(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              Colors.white,
              Colors.white.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.85, 1.0],
          ).createShader(bounds);
        },
        blendMode: BlendMode.dstIn,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background glow effect
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: isDark
                          ? [
                              Colors.teal.withValues(alpha: 0.1),
                              Colors.transparent,
                            ]
                          : [
                              Colors.white.withValues(alpha: 0.8),
                              const Color(0xFFE8F5E9).withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            // Ninja illustration container
            Container(
              margin: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.cardBackgroundDark
                    : const Color(0xFFF5F5DC).withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuBPU3i2S4cQijulHdEpSbF-g1U-zrPt59ZC6rlmRDDBETzbJ_bKBYGTsVvDWU8vidSKyByECZWibVySW5BZYz0oMXYUkrEenBmvILlZ_j6_1gIb9WrzH6gJ9iWK0drd1L8lvJ-VJimv2rBxmmRAvdiyk4GNwAt0GwQ_o_SCR6LlUc05Vyg3OuD5mDIFlNWFoRHvyyLAOqHO5Y0SSvsOn2sSuVkPWI-mm__pFSAW3avs2695ImLwohu4ovkyPasXGdc1dzg_yK3Nzg',
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppColors.primaryLight,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(
                        Icons.person,
                        size: 100,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection(BuildContext context, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [
                  Colors.transparent,
                  AppColors.backgroundDark.withValues(alpha: 0.9),
                  AppColors.backgroundDark,
                ]
              : [
                  Colors.transparent,
                  AppColors.backgroundLight.withValues(alpha: 0.9),
                  AppColors.backgroundLight,
                ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          _buildTitle(isDark),
          const SizedBox(height: 16),
          // Subtitle
          Text(
            _getLocalizedString('master_japanese'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          // Get started button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => JlptLevelScreen(
                      languageCode: languageCode,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 8,
                shadowColor: AppColors.primaryLight.withValues(alpha: 0.4),
              ),
              child: Text(
                _getLocalizedString('get_started'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Already have account button
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => LoginScreen(
                    languageCode: languageCode,
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: isDark
                  ? const Color(0xFFA5B4FC)
                  : AppColors.primaryLight,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            ),
            child: Text(
              _getLocalizedString('already_have_account'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Home indicator
          Container(
            width: 128,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(bool isDark) {
    final titleParts = _getTitleParts();
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          height: 1.3,
          letterSpacing: -0.5,
        ),
        children: [
          TextSpan(text: titleParts['before']),
          TextSpan(
            text: titleParts['highlight'],
            style: TextStyle(
              color: isDark
                  ? const Color(0xFF4ADE80)
                  : const Color(0xFF059669),
            ),
          ),
          TextSpan(text: titleParts['after']),
        ],
      ),
    );
  }

  Map<String, String> _getTitleParts() {
    switch (languageCode) {
      case 'ja':
        return {
          'before': '',
          'highlight': '2000万人以上',
          'after': 'の学習者がMigiiで学習中',
        };
      case 'vn':
        return {
          'before': 'Tham gia cùng hơn ',
          'highlight': '20 triệu',
          'after': ' người học với Migii',
        };
      case 'es_auto':
        return {
          'before': 'Únete a más de ',
          'highlight': '20 millones',
          'after': ' de estudiantes con Migii',
        };
      case 'fr_auto':
        return {
          'before': 'Rejoignez plus de ',
          'highlight': '20 millions',
          'after': " d'apprenants avec Migii",
        };
      case 'cn_auto':
      case 'cn':
        return {
          'before': '加入超过',
          'highlight': '2000万',
          'after': '正在使用Migii学习的学习者',
        };
      case 'tw_auto':
        return {
          'before': '加入超過',
          'highlight': '2000萬',
          'after': '正在使用Migii學習的學習者',
        };
      case 'ru_auto':
        return {
          'before': 'Присоединяйтесь к ',
          'highlight': '20 миллионам',
          'after': ' учеников с Migii',
        };
      case 'id_auto':
        return {
          'before': 'Bergabunglah dengan ',
          'highlight': '20 juta',
          'after': ' pelajar yang belajar dengan Migii',
        };
      case 'ko_auto':
        return {
          'before': '',
          'highlight': '2천만 명',
          'after': ' 이상의 학습자와 Migii로 함께하세요',
        };
      case 'my_auto':
        return {
          'before': 'Sertai lebih ',
          'highlight': '20 juta',
          'after': ' pelajar dengan Migii',
        };
      case 'pt_auto':
        return {
          'before': 'Junte-se a mais de ',
          'highlight': '20 milhões',
          'after': ' de alunos com Migii',
        };
      default: // en
        return {
          'before': 'Join over ',
          'highlight': '20 million',
          'after': ' learners studying with Migii',
        };
    }
  }

  String _getLocalizedString(String key) {
    return _localizedStrings[languageCode]?[key] ??
        _localizedStrings['en']?[key] ??
        key;
  }

  static const Map<String, Map<String, String>> _localizedStrings = {
    'ja': {
      'master_japanese': 'AIによる採点システムと個別学習プランで日本語を早くマスター',
      'get_started': '始める',
      'already_have_account': 'すでにアカウントをお持ちの方',
    },
    'en': {
      'master_japanese': 'Master Japanese faster with our AI-powered grading system and personalized study plans.',
      'get_started': 'Get started',
      'already_have_account': 'I already have an account',
    },
    'vn': {
      'master_japanese': 'Thành thạo tiếng Nhật nhanh hơn với hệ thống chấm điểm AI và kế hoạch học tập cá nhân hóa.',
      'get_started': 'Bắt đầu',
      'already_have_account': 'Tôi đã có tài khoản',
    },
    'es_auto': {
      'master_japanese': 'Domina el japonés más rápido con nuestro sistema de calificación con IA y planes de estudio personalizados.',
      'get_started': 'Comenzar',
      'already_have_account': 'Ya tengo una cuenta',
    },
    'fr_auto': {
      'master_japanese': "Maîtrisez le japonais plus rapidement grâce à notre système de notation IA et nos plans d'étude personnalisés.",
      'get_started': 'Commencer',
      'already_have_account': "J'ai déjà un compte",
    },
    'cn_auto': {
      'master_japanese': '通过我们的AI评分系统和个性化学习计划，更快地掌握日语。',
      'get_started': '开始',
      'already_have_account': '我已有账户',
    },
    'tw_auto': {
      'master_japanese': '透過我們的AI評分系統和個人化學習計劃，更快地掌握日語。',
      'get_started': '開始',
      'already_have_account': '我已有帳戶',
    },
    'ru_auto': {
      'master_japanese': 'Освойте японский быстрее с нашей системой оценки на базе ИИ и персонализированными планами обучения.',
      'get_started': 'Начать',
      'already_have_account': 'У меня уже есть аккаунт',
    },
    'id_auto': {
      'master_japanese': 'Kuasai bahasa Jepang lebih cepat dengan sistem penilaian AI kami dan rencana belajar yang dipersonalisasi.',
      'get_started': 'Mulai',
      'already_have_account': 'Saya sudah punya akun',
    },
    'ko_auto': {
      'master_japanese': 'AI 기반 채점 시스템과 맞춤형 학습 계획으로 일본어를 더 빠르게 마스터하세요.',
      'get_started': '시작하기',
      'already_have_account': '이미 계정이 있습니다',
    },
    'my_auto': {
      'master_japanese': 'Kuasai bahasa Jepun dengan lebih pantas dengan sistem penggredan AI kami dan pelan kajian yang diperibadikan.',
      'get_started': 'Mula',
      'already_have_account': 'Saya sudah mempunyai akaun',
    },
    'pt_auto': {
      'master_japanese': 'Domine o japonês mais rápido com nosso sistema de avaliação com IA e planos de estudo personalizados.',
      'get_started': 'Começar',
      'already_have_account': 'Já tenho uma conta',
    },
    'cn': {
      'master_japanese': '通过我们的AI评分系统和个性化学习计划，更快地掌握日语。',
      'get_started': '开始',
      'already_have_account': '我已有账户',
    },
  };
}
