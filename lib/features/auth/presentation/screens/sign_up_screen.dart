import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';

class SignUpScreen extends StatefulWidget {
  final String languageCode;
  final int? selectedLevel;

  const SignUpScreen({
    super.key,
    required this.languageCode,
    this.selectedLevel,
  });

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _agreedToTerms = true;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
        body: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : Colors.white,
          ),
          child: Column(
            children: [
              _buildHeader(context, isDark),
              Expanded(
                child: _buildBody(context, isDark),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        bottom: 24,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: AppColors.tealAccent,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
            ),
          ),
          Expanded(
            child: Text(
              _getLocalizedString('sign_up'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, bool isDark) {
    return Stack(
      children: [
        // Bottom wave decoration
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: CustomPaint(
            size: Size(MediaQuery.of(context).size.width, 120),
            painter: WavePainter(
              color: AppColors.tealAccent.withValues(alpha: 0.15),
            ),
          ),
        ),
        // Content
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildLogo(isDark),
                const SizedBox(height: 24),
                _buildInputField(
                  controller: _fullNameController,
                  icon: Icons.person_outline,
                  hint: _getLocalizedString('full_name'),
                  isRequired: true,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _emailController,
                  icon: Icons.mail_outline,
                  hint: _getLocalizedString('email'),
                  isRequired: true,
                  keyboardType: TextInputType.emailAddress,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _phoneController,
                  icon: Icons.phone_outlined,
                  hint: _getLocalizedString('phone_number'),
                  isRequired: false,
                  keyboardType: TextInputType.phone,
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _passwordController,
                  icon: Icons.lock_outline,
                  hint: _getLocalizedString('password'),
                  isRequired: true,
                  isPassword: true,
                  obscureText: _obscurePassword,
                  onToggleVisibility: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _confirmPasswordController,
                  icon: Icons.lock_outline,
                  hint: _getLocalizedString('confirm_password'),
                  isRequired: true,
                  isPassword: true,
                  obscureText: _obscureConfirmPassword,
                  onToggleVisibility: () {
                    setState(
                        () => _obscureConfirmPassword = !_obscureConfirmPassword);
                  },
                  isDark: isDark,
                ),
                const SizedBox(height: 20),
                _buildTermsCheckbox(isDark),
                const SizedBox(height: 20),
                _buildSignUpButton(isDark),
                const SizedBox(height: 8),
                Text(
                  _getLocalizedString('required_field_note'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 24),
                _buildDivider(isDark),
                const SizedBox(height: 24),
                _buildSocialButtons(isDark),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(bool isDark) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.tealAccent.withValues(alpha: 0.2),
              width: 4,
            ),
            color: isDark ? AppColors.cardBackgroundDark : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuAMiAdzbAQKtTK2zSjf5v4IH_xt3GVLwqmqkPET6u5Wci7m5xcAPLc0BMngnhxNma0lYyhmnCbfr64F467RBRJeRLgSr1WArUSjYFB6YfpKmE53nwaX89610I8qUkF40Z6X4Ptwvb-u8xDDSIT0BVN1G89ozV2mLkk6Q4sVPmR1Az9SE26Hp3ml9O1CDCbBzwuux0d-w5Xn41KXWjgyi2H5gbr_AjMFUVuTVdF5p3cJUt2ApBiyFo0r8t2Nfk82SCZfub9vFx7VxA',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.person,
                  size: 50,
                  color: Colors.grey,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Migii JLPT',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.tealAccent,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    required bool isRequired,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.tealAccent,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              obscureText: isPassword && obscureText,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF334155),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : const Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          if (isPassword)
            IconButton(
              onPressed: onToggleVisibility,
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : const Color(0xFF94A3B8),
                size: 20,
              ),
            ),
          if (isRequired && !isPassword)
            Text(
              '*',
              style: TextStyle(
                color: isDark
                    ? AppColors.textSecondaryDark
                    : const Color(0xFF94A3B8),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreedToTerms,
            onChanged: (value) {
              setState(() => _agreedToTerms = value ?? false);
            },
            activeColor: AppColors.tealAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : const Color(0xFF64748B),
                height: 1.5,
              ),
              children: [
                TextSpan(text: _getLocalizedString('terms_agree_prefix')),
                TextSpan(
                  text: _getLocalizedString('terms_and_privacy'),
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(text: _getLocalizedString('terms_agree_suffix')),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleSignUp,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.tealAccent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 4,
          shadowColor: AppColors.tealAccent.withValues(alpha: 0.3),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                _getLocalizedString('sign_up'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            _getLocalizedString('or'),
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : const Color(0xFF94A3B8),
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialButtons(bool isDark) {
    return Column(
      children: [
        // Google Sign In Button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _handleGoogleSignIn,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              side: BorderSide(
                color: isDark ? AppColors.borderDark : const Color(0xFFE2E8F0),
              ),
              backgroundColor: isDark ? AppColors.cardBackgroundDark : Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuDrsS-_Fegl9jCq32OV9Yzkngjv3VZnyQNFhx0Nq4PPOZxejZ7ZIMdLpl8j_6y0gMOf2sK8KCVJi5f8ITRXkUPyvydSUbMjEd6HptW3YKojbR9TEJraHP8hNvYDdLy3oZSAmJa_u8dKZi1lQlH1Cc6ksgTEhjzlIiDKUrV-uC2ijQOfxK84GyCmIXH5lOXTdiC_tXPa7R8gx5fj_Q0QRfT9EQ7N3AJKR2HsPcld62ruv41yObvxd7gFSVw4mR7J-BPbYV96uP2e0w',
                  width: 20,
                  height: 20,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.g_mobiledata,
                    size: 24,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _getLocalizedString('sign_in_google'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF475569),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Apple Sign In Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _handleAppleSignIn,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              backgroundColor: isDark ? Colors.white : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.apple,
                  size: 22,
                  color: isDark ? Colors.black : Colors.white,
                ),
                const SizedBox(width: 12),
                Text(
                  _getLocalizedString('sign_in_apple'),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _handleSignUp() async {
    if (!_agreedToTerms) {
      _showError(_getLocalizedString('error_terms'));
      return;
    }

    if (_fullNameController.text.isEmpty) {
      _showError(_getLocalizedString('error_name_required'));
      return;
    }

    if (_emailController.text.isEmpty) {
      _showError(_getLocalizedString('error_email_required'));
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showError(_getLocalizedString('error_password_required'));
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError(_getLocalizedString('error_password_min'));
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError(_getLocalizedString('error_password_mismatch'));
      return;
    }

    setState(() => _isLoading = true);

    // TODO: Call API
    await Future.delayed(const Duration(seconds: 2));

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_getLocalizedString('sign_up_success')),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.tealAccent,
        ),
      );
    }
  }

  void _handleGoogleSignIn() {
    // TODO: Implement Google Sign In
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Sign In - Coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _handleAppleSignIn() {
    // TODO: Implement Apple Sign In
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Apple Sign In - Coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red,
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
      'sign_up': '新規登録',
      'full_name': '氏名',
      'email': 'メールアドレス',
      'phone_number': '電話番号',
      'password': 'パスワード',
      'confirm_password': 'パスワード確認',
      'terms_agree_prefix': 'Migii JLPTに登録することで、',
      'terms_and_privacy': '利用規約とプライバシーポリシー',
      'terms_agree_suffix': 'に同意します',
      'required_field_note': '* は必須項目です',
      'or': 'または',
      'sign_in_google': 'Googleでログイン',
      'sign_in_apple': 'Appleでログイン',
      'error_terms': '利用規約に同意してください',
      'error_name_required': '氏名を入力してください',
      'error_email_required': 'メールアドレスを入力してください',
      'error_password_required': 'パスワードを入力してください',
      'error_password_min': 'パスワードは6文字以上必要です',
      'error_password_mismatch': 'パスワードが一致しません',
      'sign_up_success': '登録成功！',
    },
    'en': {
      'sign_up': 'Sign Up',
      'full_name': 'Full Name',
      'email': 'Email',
      'phone_number': 'Phone Number',
      'password': 'Password',
      'confirm_password': 'Confirm Password',
      'terms_agree_prefix': 'By signing up with Migii JLPT, you agree to our ',
      'terms_and_privacy': 'Terms and Privacy Policy',
      'terms_agree_suffix': '',
      'required_field_note': '* Required fields',
      'or': 'or',
      'sign_in_google': 'Sign in with Google',
      'sign_in_apple': 'Sign in with Apple',
      'error_terms': 'Please agree to the terms',
      'error_name_required': 'Please enter your name',
      'error_email_required': 'Please enter your email',
      'error_password_required': 'Please enter a password',
      'error_password_min': 'Password must be at least 6 characters',
      'error_password_mismatch': 'Passwords do not match',
      'sign_up_success': 'Sign up successful!',
    },
    'vn': {
      'sign_up': 'Đăng ký',
      'full_name': 'Họ và tên',
      'email': 'Email',
      'phone_number': 'Số điện thoại',
      'password': 'Mật khẩu',
      'confirm_password': 'Nhập lại mật khẩu',
      'terms_agree_prefix': 'Bằng việc đăng ký với Migii JLPT, bạn đồng ý với ',
      'terms_and_privacy': 'Điều khoản và Chính sách bảo mật',
      'terms_agree_suffix': ' của chúng tôi',
      'required_field_note': 'Dấu * là trường bắt buộc điền thông tin',
      'or': 'hoặc',
      'sign_in_google': 'Đăng nhập với Google',
      'sign_in_apple': 'Đăng nhập với Apple',
      'error_terms': 'Vui lòng đồng ý với điều khoản',
      'error_name_required': 'Vui lòng nhập họ tên',
      'error_email_required': 'Vui lòng nhập email',
      'error_password_required': 'Vui lòng nhập mật khẩu',
      'error_password_min': 'Mật khẩu phải có ít nhất 6 ký tự',
      'error_password_mismatch': 'Mật khẩu không khớp',
      'sign_up_success': 'Đăng ký thành công!',
    },
    'es_auto': {
      'sign_up': 'Registrarse',
      'full_name': 'Nombre completo',
      'email': 'Correo electrónico',
      'phone_number': 'Número de teléfono',
      'password': 'Contraseña',
      'confirm_password': 'Confirmar contraseña',
      'terms_agree_prefix': 'Al registrarte en Migii JLPT, aceptas nuestros ',
      'terms_and_privacy': 'Términos y Política de Privacidad',
      'terms_agree_suffix': '',
      'required_field_note': '* Campos obligatorios',
      'or': 'o',
      'sign_in_google': 'Iniciar sesión con Google',
      'sign_in_apple': 'Iniciar sesión con Apple',
      'error_terms': 'Por favor acepta los términos',
      'error_name_required': 'Por favor ingresa tu nombre',
      'error_email_required': 'Por favor ingresa tu email',
      'error_password_required': 'Por favor ingresa una contraseña',
      'error_password_min': 'La contraseña debe tener al menos 6 caracteres',
      'error_password_mismatch': 'Las contraseñas no coinciden',
      'sign_up_success': '¡Registro exitoso!',
    },
    'fr_auto': {
      'sign_up': "S'inscrire",
      'full_name': 'Nom complet',
      'email': 'Email',
      'phone_number': 'Numéro de téléphone',
      'password': 'Mot de passe',
      'confirm_password': 'Confirmer le mot de passe',
      'terms_agree_prefix': "En vous inscrivant à Migii JLPT, vous acceptez nos ",
      'terms_and_privacy': 'Conditions et Politique de confidentialité',
      'terms_agree_suffix': '',
      'required_field_note': '* Champs obligatoires',
      'or': 'ou',
      'sign_in_google': 'Se connecter avec Google',
      'sign_in_apple': 'Se connecter avec Apple',
      'error_terms': 'Veuillez accepter les conditions',
      'error_name_required': 'Veuillez entrer votre nom',
      'error_email_required': 'Veuillez entrer votre email',
      'error_password_required': 'Veuillez entrer un mot de passe',
      'error_password_min': 'Le mot de passe doit contenir au moins 6 caractères',
      'error_password_mismatch': 'Les mots de passe ne correspondent pas',
      'sign_up_success': 'Inscription réussie!',
    },
    'cn_auto': {
      'sign_up': '注册',
      'full_name': '姓名',
      'email': '邮箱',
      'phone_number': '电话号码',
      'password': '密码',
      'confirm_password': '确认密码',
      'terms_agree_prefix': '注册即表示您同意Migii JLPT的',
      'terms_and_privacy': '条款和隐私政策',
      'terms_agree_suffix': '',
      'required_field_note': '* 为必填项',
      'or': '或',
      'sign_in_google': '使用Google登录',
      'sign_in_apple': '使用Apple登录',
      'error_terms': '请同意条款',
      'error_name_required': '请输入姓名',
      'error_email_required': '请输入邮箱',
      'error_password_required': '请输入密码',
      'error_password_min': '密码至少需要6个字符',
      'error_password_mismatch': '密码不匹配',
      'sign_up_success': '注册成功！',
    },
    'tw_auto': {
      'sign_up': '註冊',
      'full_name': '姓名',
      'email': '電子郵件',
      'phone_number': '電話號碼',
      'password': '密碼',
      'confirm_password': '確認密碼',
      'terms_agree_prefix': '註冊即表示您同意Migii JLPT的',
      'terms_and_privacy': '條款和隱私政策',
      'terms_agree_suffix': '',
      'required_field_note': '* 為必填項',
      'or': '或',
      'sign_in_google': '使用Google登入',
      'sign_in_apple': '使用Apple登入',
      'error_terms': '請同意條款',
      'error_name_required': '請輸入姓名',
      'error_email_required': '請輸入電子郵件',
      'error_password_required': '請輸入密碼',
      'error_password_min': '密碼至少需要6個字符',
      'error_password_mismatch': '密碼不匹配',
      'sign_up_success': '註冊成功！',
    },
    'ru_auto': {
      'sign_up': 'Регистрация',
      'full_name': 'Полное имя',
      'email': 'Электронная почта',
      'phone_number': 'Номер телефона',
      'password': 'Пароль',
      'confirm_password': 'Подтвердите пароль',
      'terms_agree_prefix': 'Регистрируясь в Migii JLPT, вы соглашаетесь с нашими ',
      'terms_and_privacy': 'Условиями и Политикой конфиденциальности',
      'terms_agree_suffix': '',
      'required_field_note': '* Обязательные поля',
      'or': 'или',
      'sign_in_google': 'Войти через Google',
      'sign_in_apple': 'Войти через Apple',
      'error_terms': 'Пожалуйста, примите условия',
      'error_name_required': 'Пожалуйста, введите имя',
      'error_email_required': 'Пожалуйста, введите email',
      'error_password_required': 'Пожалуйста, введите пароль',
      'error_password_min': 'Пароль должен содержать не менее 6 символов',
      'error_password_mismatch': 'Пароли не совпадают',
      'sign_up_success': 'Регистрация успешна!',
    },
    'id_auto': {
      'sign_up': 'Daftar',
      'full_name': 'Nama Lengkap',
      'email': 'Email',
      'phone_number': 'Nomor Telepon',
      'password': 'Kata Sandi',
      'confirm_password': 'Konfirmasi Kata Sandi',
      'terms_agree_prefix': 'Dengan mendaftar di Migii JLPT, Anda menyetujui ',
      'terms_and_privacy': 'Syarat dan Kebijakan Privasi',
      'terms_agree_suffix': ' kami',
      'required_field_note': '* Kolom wajib diisi',
      'or': 'atau',
      'sign_in_google': 'Masuk dengan Google',
      'sign_in_apple': 'Masuk dengan Apple',
      'error_terms': 'Silakan setujui ketentuan',
      'error_name_required': 'Silakan masukkan nama',
      'error_email_required': 'Silakan masukkan email',
      'error_password_required': 'Silakan masukkan kata sandi',
      'error_password_min': 'Kata sandi minimal 6 karakter',
      'error_password_mismatch': 'Kata sandi tidak cocok',
      'sign_up_success': 'Pendaftaran berhasil!',
    },
    'ko_auto': {
      'sign_up': '회원가입',
      'full_name': '이름',
      'email': '이메일',
      'phone_number': '전화번호',
      'password': '비밀번호',
      'confirm_password': '비밀번호 확인',
      'terms_agree_prefix': 'Migii JLPT에 가입하면 ',
      'terms_and_privacy': '이용약관 및 개인정보 보호정책',
      'terms_agree_suffix': '에 동의하게 됩니다',
      'required_field_note': '* 필수 입력 항목',
      'or': '또는',
      'sign_in_google': 'Google로 로그인',
      'sign_in_apple': 'Apple로 로그인',
      'error_terms': '약관에 동의해 주세요',
      'error_name_required': '이름을 입력해 주세요',
      'error_email_required': '이메일을 입력해 주세요',
      'error_password_required': '비밀번호를 입력해 주세요',
      'error_password_min': '비밀번호는 최소 6자 이상이어야 합니다',
      'error_password_mismatch': '비밀번호가 일치하지 않습니다',
      'sign_up_success': '가입 성공!',
    },
    'my_auto': {
      'sign_up': 'Daftar',
      'full_name': 'Nama Penuh',
      'email': 'E-mel',
      'phone_number': 'Nombor Telefon',
      'password': 'Kata Laluan',
      'confirm_password': 'Sahkan Kata Laluan',
      'terms_agree_prefix': 'Dengan mendaftar dengan Migii JLPT, anda bersetuju dengan ',
      'terms_and_privacy': 'Terma dan Dasar Privasi',
      'terms_agree_suffix': ' kami',
      'required_field_note': '* Medan wajib',
      'or': 'atau',
      'sign_in_google': 'Log masuk dengan Google',
      'sign_in_apple': 'Log masuk dengan Apple',
      'error_terms': 'Sila bersetuju dengan terma',
      'error_name_required': 'Sila masukkan nama',
      'error_email_required': 'Sila masukkan e-mel',
      'error_password_required': 'Sila masukkan kata laluan',
      'error_password_min': 'Kata laluan mesti sekurang-kurangnya 6 aksara',
      'error_password_mismatch': 'Kata laluan tidak sepadan',
      'sign_up_success': 'Pendaftaran berjaya!',
    },
    'pt_auto': {
      'sign_up': 'Cadastrar',
      'full_name': 'Nome Completo',
      'email': 'Email',
      'phone_number': 'Número de Telefone',
      'password': 'Senha',
      'confirm_password': 'Confirmar Senha',
      'terms_agree_prefix': 'Ao se cadastrar no Migii JLPT, você concorda com nossos ',
      'terms_and_privacy': 'Termos e Política de Privacidade',
      'terms_agree_suffix': '',
      'required_field_note': '* Campos obrigatórios',
      'or': 'ou',
      'sign_in_google': 'Entrar com Google',
      'sign_in_apple': 'Entrar com Apple',
      'error_terms': 'Por favor, aceite os termos',
      'error_name_required': 'Por favor, insira seu nome',
      'error_email_required': 'Por favor, insira seu email',
      'error_password_required': 'Por favor, insira uma senha',
      'error_password_min': 'A senha deve ter pelo menos 6 caracteres',
      'error_password_mismatch': 'As senhas não coincidem',
      'sign_up_success': 'Cadastro realizado com sucesso!',
    },
    'cn': {
      'sign_up': '注册',
      'full_name': '姓名',
      'email': '邮箱',
      'phone_number': '电话号码',
      'password': '密码',
      'confirm_password': '确认密码',
      'terms_agree_prefix': '注册即表示您同意Migii JLPT的',
      'terms_and_privacy': '条款和隐私政策',
      'terms_agree_suffix': '',
      'required_field_note': '* 为必填项',
      'or': '或',
      'sign_in_google': '使用Google登录',
      'sign_in_apple': '使用Apple登录',
      'error_terms': '请同意条款',
      'error_name_required': '请输入姓名',
      'error_email_required': '请输入邮箱',
      'error_password_required': '请输入密码',
      'error_password_min': '密码至少需要6个字符',
      'error_password_mismatch': '密码不匹配',
      'sign_up_success': '注册成功！',
    },
  };
}

class WavePainter extends CustomPainter {
  final Color color;

  WavePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.5);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.3,
      size.width * 0.5,
      size.height * 0.5,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.7,
      size.width,
      size.height * 0.4,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
