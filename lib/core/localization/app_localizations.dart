import 'package:flutter/material.dart';

class AppLocalizations {
  final String languageCode;

  AppLocalizations(this.languageCode);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations('en');
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String get(String key) {
    return _localizedStrings[languageCode]?[key] ??
        _localizedStrings['en']?[key] ??
        key;
  }

  static const Map<String, Map<String, String>> _localizedStrings = {
    // Japanese
    'ja': {
      // Language Selection Screen
      'choose_display_language': '表示言語を選択',
      'change_later_settings': '後で設定から変更できます',
      'continue_button': '続ける',

      // Welcome Screen
      'join_millions': '2000万人以上の学習者がMigiiで学習中',
      'master_japanese': 'AIによる採点システムと個別学習プランで日本語を早くマスター',
      'get_started': '始める',
      'already_have_account': 'すでにアカウントをお持ちの方',

      // JLPT Level Screen
      'jlpt_level_question': 'あなたのJLPTレベルは\nどのくらいですか？',
      'beginner': '初心者',
      'beginner_desc': '日本語についてまだ何も知らない',
      'n5_desc': '日本語学習を始めたばかり',
      'n4_desc': '簡単な会話を理解できる',
      'n3_desc': '読解と基本的なコミュニケーション',
      'n2_desc': '仕事で日本語を使える',
      'n1_desc': 'ネイティブレベル',
    },

    // English
    'en': {
      'choose_display_language': 'Choose display language',
      'change_later_settings': "Don't worry, you can change it later in Settings",
      'continue_button': 'Continue',

      'join_millions': 'Join over 20 million learners studying with Migii',
      'master_japanese': 'Master Japanese faster with our AI-powered grading system and personalized study plans.',
      'get_started': 'Get started',
      'already_have_account': 'I already have an account',

      'jlpt_level_question': 'What is your current\nJLPT level?',
      'beginner': 'Beginner',
      'beginner_desc': "Don't know anything about Japanese",
      'n5_desc': 'Just started learning Japanese',
      'n4_desc': 'Understand simple conversations',
      'n3_desc': 'Reading comprehension and basic communication',
      'n2_desc': 'Proficient for work use',
      'n1_desc': 'Native-like proficiency',
    },

    // Vietnamese
    'vn': {
      'choose_display_language': 'Chọn ngôn ngữ hiển thị',
      'change_later_settings': 'Đừng lo, bạn có thể thay đổi sau trong Cài đặt',
      'continue_button': 'Tiếp tục',

      'join_millions': 'Tham gia cùng hơn 20 triệu người học với Migii',
      'master_japanese': 'Thành thạo tiếng Nhật nhanh hơn với hệ thống chấm điểm AI và kế hoạch học tập cá nhân hóa.',
      'get_started': 'Bắt đầu',
      'already_have_account': 'Tôi đã có tài khoản',

      'jlpt_level_question': 'Trình độ JLPT của bạn\nđang ở cấp độ nào?',
      'beginner': 'Người mới',
      'beginner_desc': 'Chưa biết gì về tiếng Nhật',
      'n5_desc': 'Mới bắt đầu học tiếng Nhật',
      'n4_desc': 'Hiểu hội thoại đơn giản',
      'n3_desc': 'Đọc hiểu và giao tiếp cơ bản',
      'n2_desc': 'Sử dụng tốt trong công việc',
      'n1_desc': 'Thành thạo như người bản xứ',
    },

    // Spanish
    'es_auto': {
      'choose_display_language': 'Elegir idioma de visualización',
      'change_later_settings': 'No te preocupes, puedes cambiarlo más tarde en Configuración',
      'continue_button': 'Continuar',

      'join_millions': 'Únete a más de 20 millones de estudiantes que aprenden con Migii',
      'master_japanese': 'Domina el japonés más rápido con nuestro sistema de calificación con IA y planes de estudio personalizados.',
      'get_started': 'Comenzar',
      'already_have_account': 'Ya tengo una cuenta',

      'jlpt_level_question': '¿Cuál es tu nivel\nactual de JLPT?',
      'beginner': 'Principiante',
      'beginner_desc': 'No sé nada de japonés',
      'n5_desc': 'Acabo de empezar a aprender japonés',
      'n4_desc': 'Entiendo conversaciones simples',
      'n3_desc': 'Comprensión lectora y comunicación básica',
      'n2_desc': 'Competente para uso laboral',
      'n1_desc': 'Dominio nativo',
    },

    // French
    'fr_auto': {
      'choose_display_language': "Choisir la langue d'affichage",
      'change_later_settings': 'Ne vous inquiétez pas, vous pouvez le changer plus tard dans les Paramètres',
      'continue_button': 'Continuer',

      'join_millions': 'Rejoignez plus de 20 millions d\'apprenants qui étudient avec Migii',
      'master_japanese': 'Maîtrisez le japonais plus rapidement grâce à notre système de notation IA et nos plans d\'étude personnalisés.',
      'get_started': 'Commencer',
      'already_have_account': 'J\'ai déjà un compte',

      'jlpt_level_question': 'Quel est votre niveau\nJLPT actuel ?',
      'beginner': 'Débutant',
      'beginner_desc': 'Je ne connais rien au japonais',
      'n5_desc': 'Je viens de commencer à apprendre le japonais',
      'n4_desc': 'Je comprends les conversations simples',
      'n3_desc': 'Compréhension écrite et communication de base',
      'n2_desc': 'Compétent pour le travail',
      'n1_desc': 'Maîtrise native',
    },

    // Chinese Simplified
    'cn_auto': {
      'choose_display_language': '选择显示语言',
      'change_later_settings': '别担心，您可以稍后在设置中更改',
      'continue_button': '继续',

      'join_millions': '加入超过2000万正在使用Migii学习的学习者',
      'master_japanese': '通过我们的AI评分系统和个性化学习计划，更快地掌握日语。',
      'get_started': '开始',
      'already_have_account': '我已有账户',

      'jlpt_level_question': '您目前的JLPT\n水平是多少？',
      'beginner': '初学者',
      'beginner_desc': '对日语一无所知',
      'n5_desc': '刚开始学习日语',
      'n4_desc': '能理解简单对话',
      'n3_desc': '阅读理解和基本交流',
      'n2_desc': '可用于工作',
      'n1_desc': '母语水平',
    },

    // Chinese Traditional
    'tw_auto': {
      'choose_display_language': '選擇顯示語言',
      'change_later_settings': '別擔心，您可以稍後在設定中更改',
      'continue_button': '繼續',

      'join_millions': '加入超過2000萬正在使用Migii學習的學習者',
      'master_japanese': '透過我們的AI評分系統和個人化學習計劃，更快地掌握日語。',
      'get_started': '開始',
      'already_have_account': '我已有帳戶',

      'jlpt_level_question': '您目前的JLPT\n程度是多少？',
      'beginner': '初學者',
      'beginner_desc': '對日語一無所知',
      'n5_desc': '剛開始學習日語',
      'n4_desc': '能理解簡單對話',
      'n3_desc': '閱讀理解和基本交流',
      'n2_desc': '可用於工作',
      'n1_desc': '母語程度',
    },

    // Russian
    'ru_auto': {
      'choose_display_language': 'Выберите язык отображения',
      'change_later_settings': 'Не волнуйтесь, вы можете изменить это позже в Настройках',
      'continue_button': 'Продолжить',

      'join_millions': 'Присоединяйтесь к более чем 20 миллионам учеников, изучающих с Migii',
      'master_japanese': 'Освойте японский быстрее с нашей системой оценки на базе ИИ и персонализированными планами обучения.',
      'get_started': 'Начать',
      'already_have_account': 'У меня уже есть аккаунт',

      'jlpt_level_question': 'Какой у вас текущий\nуровень JLPT?',
      'beginner': 'Начинающий',
      'beginner_desc': 'Ничего не знаю о японском',
      'n5_desc': 'Только начал изучать японский',
      'n4_desc': 'Понимаю простые разговоры',
      'n3_desc': 'Чтение и базовое общение',
      'n2_desc': 'Владею для работы',
      'n1_desc': 'Владение на уровне носителя',
    },

    // Indonesian
    'id_auto': {
      'choose_display_language': 'Pilih bahasa tampilan',
      'change_later_settings': 'Jangan khawatir, Anda dapat mengubahnya nanti di Pengaturan',
      'continue_button': 'Lanjutkan',

      'join_millions': 'Bergabunglah dengan lebih dari 20 juta pelajar yang belajar dengan Migii',
      'master_japanese': 'Kuasai bahasa Jepang lebih cepat dengan sistem penilaian AI kami dan rencana belajar yang dipersonalisasi.',
      'get_started': 'Mulai',
      'already_have_account': 'Saya sudah punya akun',

      'jlpt_level_question': 'Berapa level JLPT\nAnda saat ini?',
      'beginner': 'Pemula',
      'beginner_desc': 'Tidak tahu apa-apa tentang bahasa Jepang',
      'n5_desc': 'Baru mulai belajar bahasa Jepang',
      'n4_desc': 'Memahami percakapan sederhana',
      'n3_desc': 'Pemahaman membaca dan komunikasi dasar',
      'n2_desc': 'Mahir untuk pekerjaan',
      'n1_desc': 'Kemahiran seperti penutur asli',
    },

    // Korean
    'ko_auto': {
      'choose_display_language': '표시 언어 선택',
      'change_later_settings': '걱정 마세요, 나중에 설정에서 변경할 수 있습니다',
      'continue_button': '계속',

      'join_millions': 'Migii로 공부하는 2천만 명 이상의 학습자와 함께하세요',
      'master_japanese': 'AI 기반 채점 시스템과 맞춤형 학습 계획으로 일본어를 더 빠르게 마스터하세요.',
      'get_started': '시작하기',
      'already_have_account': '이미 계정이 있습니다',

      'jlpt_level_question': '현재 JLPT 레벨이\n어떻게 되시나요?',
      'beginner': '초보자',
      'beginner_desc': '일본어에 대해 아무것도 모름',
      'n5_desc': '일본어 학습을 막 시작함',
      'n4_desc': '간단한 대화를 이해함',
      'n3_desc': '독해 및 기본 의사소통',
      'n2_desc': '업무에 능숙하게 사용',
      'n1_desc': '원어민 수준',
    },

    // Malay
    'my_auto': {
      'choose_display_language': 'Pilih bahasa paparan',
      'change_later_settings': 'Jangan risau, anda boleh menukarnya kemudian di Tetapan',
      'continue_button': 'Teruskan',

      'join_millions': 'Sertai lebih 20 juta pelajar yang belajar dengan Migii',
      'master_japanese': 'Kuasai bahasa Jepun dengan lebih pantas dengan sistem penggredan AI kami dan pelan kajian yang diperibadikan.',
      'get_started': 'Mula',
      'already_have_account': 'Saya sudah mempunyai akaun',

      'jlpt_level_question': 'Apakah tahap JLPT\nanda sekarang?',
      'beginner': 'Pemula',
      'beginner_desc': 'Tidak tahu apa-apa tentang bahasa Jepun',
      'n5_desc': 'Baru mula belajar bahasa Jepun',
      'n4_desc': 'Faham perbualan mudah',
      'n3_desc': 'Pemahaman bacaan dan komunikasi asas',
      'n2_desc': 'Mahir untuk kerja',
      'n1_desc': 'Kemahiran seperti penutur asli',
    },

    // Portuguese
    'pt_auto': {
      'choose_display_language': 'Escolher idioma de exibição',
      'change_later_settings': 'Não se preocupe, você pode alterar depois nas Configurações',
      'continue_button': 'Continuar',

      'join_millions': 'Junte-se a mais de 20 milhões de alunos estudando com Migii',
      'master_japanese': 'Domine o japonês mais rápido com nosso sistema de avaliação com IA e planos de estudo personalizados.',
      'get_started': 'Começar',
      'already_have_account': 'Já tenho uma conta',

      'jlpt_level_question': 'Qual é o seu nível\natual de JLPT?',
      'beginner': 'Iniciante',
      'beginner_desc': 'Não sei nada sobre japonês',
      'n5_desc': 'Acabei de começar a aprender japonês',
      'n4_desc': 'Entendo conversas simples',
      'n3_desc': 'Compreensão de leitura e comunicação básica',
      'n2_desc': 'Proficiente para trabalho',
      'n1_desc': 'Proficiência nativa',
    },

    // Chinese (generic)
    'cn': {
      'choose_display_language': '选择显示语言',
      'change_later_settings': '别担心，您可以稍后在设置中更改',
      'continue_button': '继续',

      'join_millions': '加入超过2000万正在使用Migii学习的学习者',
      'master_japanese': '通过我们的AI评分系统和个性化学习计划，更快地掌握日语。',
      'get_started': '开始',
      'already_have_account': '我已有账户',

      'jlpt_level_question': '您目前的JLPT\n水平是多少？',
      'beginner': '初学者',
      'beginner_desc': '对日语一无所知',
      'n5_desc': '刚开始学习日语',
      'n4_desc': '能理解简单对话',
      'n3_desc': '阅读理解和基本交流',
      'n2_desc': '可用于工作',
      'n1_desc': '母语水平',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale.languageCode);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
