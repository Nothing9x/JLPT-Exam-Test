import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../models/language_model.dart';
import '../../../welcome/presentation/screens/welcome_screen.dart';
import '../widgets/language_item_card.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLanguageCode = 'ja';
  late List<LanguageModel> _sortedLanguages;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final deviceLocale = View.of(context).platformDispatcher.locale;
    _sortedLanguages = LanguageModel.getSortedLanguages(deviceLocale);
  }

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
                // Status bar mock (optional - for visual consistency)
                _buildStatusBar(isDark),
                // Header
                _buildHeader(isDark),
                // Language list
                Expanded(
                  child: _buildLanguageList(isDark),
                ),
                // Bottom button
                _buildBottomButton(isDark),
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

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          Text(
            _getLocalizedString('choose_display_language'),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _getLocalizedString('change_later_settings'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textPrimaryLight.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageList(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _sortedLanguages.length,
      itemBuilder: (context, index) {
        final language = _sortedLanguages[index];
        final isSelected = language.code == _selectedLanguageCode;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: LanguageItemCard(
            language: language,
            isSelected: isSelected,
            onTap: () {
              setState(() {
                _selectedLanguageCode = language.code;
              });
            },
          ),
        );
      },
    );
  }

  Widget _buildBottomButton(bool isDark) {
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
                  AppColors.backgroundLight.withValues(alpha: 0),
                  AppColors.backgroundLight,
                  AppColors.backgroundLight,
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
                // Navigate to Welcome screen with selected language
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WelcomeScreen(
                      languageCode: _selectedLanguageCode,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: AppColors.primaryLight.withValues(alpha: 0.4),
              ),
              child: Text(
                _getLocalizedString('continue_button'),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Home indicator
          Container(
            width: 128,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : const Color(0xFFCBD5E1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _getLocalizedString(String key) {
    return _localizedStrings[_selectedLanguageCode]?[key] ??
        _localizedStrings['en']?[key] ??
        key;
  }

  static const Map<String, Map<String, String>> _localizedStrings = {
    'ja': {
      'choose_display_language': '表示言語を選択',
      'change_later_settings': '後で設定から変更できます',
      'continue_button': '続ける',
    },
    'en': {
      'choose_display_language': 'Choose display language',
      'change_later_settings': "Don't worry, you can change it later in Settings",
      'continue_button': 'Continue',
    },
    'vn': {
      'choose_display_language': 'Chọn ngôn ngữ hiển thị',
      'change_later_settings': 'Đừng lo, bạn có thể thay đổi sau trong Cài đặt',
      'continue_button': 'Tiếp tục',
    },
    'es_auto': {
      'choose_display_language': 'Elegir idioma de visualización',
      'change_later_settings': 'No te preocupes, puedes cambiarlo más tarde en Configuración',
      'continue_button': 'Continuar',
    },
    'fr_auto': {
      'choose_display_language': "Choisir la langue d'affichage",
      'change_later_settings': 'Ne vous inquiétez pas, vous pouvez le changer plus tard dans les Paramètres',
      'continue_button': 'Continuer',
    },
    'cn_auto': {
      'choose_display_language': '选择显示语言',
      'change_later_settings': '别担心，您可以稍后在设置中更改',
      'continue_button': '继续',
    },
    'tw_auto': {
      'choose_display_language': '選擇顯示語言',
      'change_later_settings': '別擔心，您可以稍後在設定中更改',
      'continue_button': '繼續',
    },
    'ru_auto': {
      'choose_display_language': 'Выберите язык отображения',
      'change_later_settings': 'Не волнуйтесь, вы можете изменить это позже в Настройках',
      'continue_button': 'Продолжить',
    },
    'id_auto': {
      'choose_display_language': 'Pilih bahasa tampilan',
      'change_later_settings': 'Jangan khawatir, Anda dapat mengubahnya nanti di Pengaturan',
      'continue_button': 'Lanjutkan',
    },
    'ko_auto': {
      'choose_display_language': '표시 언어 선택',
      'change_later_settings': '걱정 마세요, 나중에 설정에서 변경할 수 있습니다',
      'continue_button': '계속',
    },
    'my_auto': {
      'choose_display_language': 'Pilih bahasa paparan',
      'change_later_settings': 'Jangan risau, anda boleh menukarnya kemudian di Tetapan',
      'continue_button': 'Teruskan',
    },
    'pt_auto': {
      'choose_display_language': 'Escolher idioma de exibição',
      'change_later_settings': 'Não se preocupe, você pode alterar depois nas Configurações',
      'continue_button': 'Continuar',
    },
    'cn': {
      'choose_display_language': '选择显示语言',
      'change_later_settings': '别担心，您可以稍后在设置中更改',
      'continue_button': '继续',
    },
  };
}
