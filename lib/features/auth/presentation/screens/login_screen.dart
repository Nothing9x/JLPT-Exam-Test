import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/token_storage.dart';
import '../../data/services/auth_service.dart';
import 'sign_up_screen.dart';
import '../../../home/presentation/screens/home_screen.dart';

class LoginScreen extends StatefulWidget {
  final String languageCode;
  final int? selectedLevel;

  const LoginScreen({
    super.key,
    required this.languageCode,
    this.selectedLevel,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _authService = AuthService();
  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  bool _isLoading = false;
  bool _agreedToTerms = true;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authService.dispose();
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
      decoration: const BoxDecoration(
        color: AppColors.tealAccent,
        borderRadius: BorderRadius.only(
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
              _getLocalizedString('login'),
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
          child: Column(
            children: [
              _buildLogo(isDark),
              const SizedBox(height: 32),
              _buildInputField(
                controller: _emailController,
                icon: Icons.mail_outline,
                hint: _getLocalizedString('enter_email'),
                keyboardType: TextInputType.emailAddress,
                isDark: isDark,
              ),
              const SizedBox(height: 16),
              _buildPasswordField(isDark),
              const SizedBox(height: 20),
              _buildTermsCheckbox(isDark),
              const SizedBox(height: 24),
              _buildLoginButton(isDark),
              const SizedBox(height: 24),
              _buildDivider(isDark),
              const SizedBox(height: 16),
              _buildForgotPassword(isDark),
              const SizedBox(height: 16),
              _buildSocialButtons(isDark),
              const SizedBox(height: 24),
              _buildSignUpLink(context, isDark),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogo(bool isDark) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.tealAccent.withValues(alpha: 0.1),
              width: 4,
            ),
            color: isDark ? AppColors.cardBackgroundDark : Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppColors.tealAccent.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Padding(
              padding: const EdgeInsets.all(12),
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
        const SizedBox(height: 12),
        const Text(
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
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
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
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : const Color(0xFF6B7280),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordField(bool isDark) {
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
          const Icon(
            Icons.lock_outline,
            color: AppColors.tealAccent,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : const Color(0xFF1F2937),
              ),
              decoration: InputDecoration(
                hintText: _getLocalizedString('enter_password'),
                hintStyle: TextStyle(
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : const Color(0xFF6B7280),
                  fontSize: 15,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : const Color(0xFF6B7280),
              size: 20,
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
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : const Color(0xFF6B7280),
                height: 1.5,
              ),
              children: [
                TextSpan(text: _getLocalizedString('terms_agree_prefix')),
                TextSpan(
                  text: _getLocalizedString('terms_and_privacy'),
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.underline,
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

  Widget _buildLoginButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
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
                _getLocalizedString('login'),
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
              fontWeight: FontWeight.w500,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : const Color(0xFF6B7280),
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

  Widget _buildForgotPassword(bool isDark) {
    return TextButton(
      onPressed: () {
        // TODO: Navigate to forgot password
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getLocalizedString('forgot_password_coming_soon')),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      child: Text(
        _getLocalizedString('forgot_password'),
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.tealAccent,
        ),
      ),
    );
  }

  Widget _buildSocialButtons(bool isDark) {
    return Column(
      children: [
        // Google Sign In Button - Prominent design
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleGoogleSignIn,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF4285F4)
                      : const Color(0xFFE8EAED),
                  width: 1.5,
                ),
              ),
              backgroundColor: isDark
                  ? const Color(0xFF1F1F1F)
                  : Colors.white,
              foregroundColor: isDark ? Colors.white : const Color(0xFF1F1F1F),
              elevation: 0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Google "G" Logo with colors
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Image.network(
                      'https://lh3.googleusercontent.com/aida-public/AB6AXuBNM5YycW8dHLgkPiqePjEzvkiZ-G3lH9t8MkkTs1_A0swDwd-uKglZiNCB5nrO-Uz2Y9674ons7lbt_S-_BNp0rTxiA3YTQjaKhBUBJ-kHMY9_Eydaunq7l-We_vYMzGPWrIoFVDS01k87TMun0IDx_wHgbXyRhVd7jEpYRBZrWK5Sttq07eQbnsy6x-haejwoDP-67vpj332D9KumG9jl8gnfcFoXYSsqitxE7iiboXHATNULs2URNd-hpLlW8ymCcfDTULORig',
                      width: 18,
                      height: 18,
                      errorBuilder: (context, error, stackTrace) =>
                          const _GoogleLogo(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _getLocalizedString('sign_in_google'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF1F1F1F),
                    letterSpacing: 0.25,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Apple Sign In Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleAppleSignIn,
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

  Widget _buildSignUpLink(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _getLocalizedString('no_account'),
          style: TextStyle(
            fontSize: 14,
            color: isDark
                ? AppColors.textSecondaryDark
                : const Color(0xFF6B7280),
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => SignUpScreen(
                  languageCode: widget.languageCode,
                  selectedLevel: widget.selectedLevel,
                ),
              ),
            );
          },
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          child: Text(
            _getLocalizedString('sign_up_now'),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.tealAccent,
            ),
          ),
        ),
      ],
    );
  }

  void _handleLogin() async {
    if (!_agreedToTerms) {
      _showError(_getLocalizedString('error_terms'));
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

    setState(() => _isLoading = true);

    try {
      final response = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getLocalizedString('login_success')),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.tealAccent,
          ),
        );
        debugPrint('Logged in user: ${response.user.email}');
        debugPrint('Token: ${response.token}');
        
        // Save token and language for persistent login
        await TokenStorage.saveToken(response.token);
        await TokenStorage.saveLanguage(widget.languageCode);
        await TokenStorage.saveEmail(response.user.email);
        await TokenStorage.saveFullName(response.user.fullName);
        
        // Navigate to home screen
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  languageCode: widget.languageCode,
                  token: response.token,
                ),
              ),
              (route) => false,
            );
          }
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showError(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showError(_getLocalizedString('error_network'));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleGoogleSignIn() async {
    setState(() => _isLoading = true);

    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final response = await _authService.oauthLogin(
        email: googleUser.email,
        provider: 'google',
        oauthId: googleUser.id,
        fullName: googleUser.displayName ?? googleUser.email.split('@')[0],
        avatarUrl: googleUser.photoUrl,
        language: widget.languageCode,
        level: widget.selectedLevel,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getLocalizedString('login_success')),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.tealAccent,
          ),
        );
        debugPrint('Google user: ${response.user.email}');
        debugPrint('Token: ${response.token}');
        
        // Save token and language for persistent login
        await TokenStorage.saveToken(response.token);
        await TokenStorage.saveLanguage(widget.languageCode);
        await TokenStorage.saveEmail(response.user.email);
        await TokenStorage.saveFullName(response.user.fullName);
        
        // Navigate to home screen
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  languageCode: widget.languageCode,
                  token: response.token,
                ),
              ),
              (route) => false,
            );
          }
        });
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showError(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showError(_getLocalizedString('error_google_sign_in'));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleAppleSignIn() async {
    if (!Platform.isIOS && !Platform.isMacOS) {
      _showError(_getLocalizedString('error_apple_not_available'));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final email = credential.email ?? '';
      final fullName = [
        credential.givenName,
        credential.familyName,
      ].where((s) => s != null && s.isNotEmpty).join(' ');

      if (email.isEmpty) {
        _showError(_getLocalizedString('error_apple_no_email'));
        setState(() => _isLoading = false);
        return;
      }

      final response = await _authService.oauthLogin(
        email: email,
        provider: 'apple',
        oauthId: credential.userIdentifier ?? '',
        fullName: fullName.isEmpty ? email.split('@')[0] : fullName,
        language: widget.languageCode,
        level: widget.selectedLevel,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_getLocalizedString('login_success')),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.tealAccent,
          ),
        );
        debugPrint('Apple user: ${response.user.email}');
        debugPrint('Token: ${response.token}');
        
        // Save token and language for persistent login
        await TokenStorage.saveToken(response.token);
        await TokenStorage.saveLanguage(widget.languageCode);
        await TokenStorage.saveEmail(response.user.email);
        await TokenStorage.saveFullName(response.user.fullName);
        
        // Navigate to home screen
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => HomeScreen(
                  languageCode: widget.languageCode,
                  token: response.token,
                ),
              ),
              (route) => false,
            );
          }
        });
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        // User cancelled
      } else if (mounted) {
        _showError(e.message);
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showError(e.message);
      }
    } catch (e) {
      if (mounted) {
        _showError(_getLocalizedString('error_apple_sign_in'));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
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
      'login': 'ログイン',
      'enter_email': 'メールアドレスを入力',
      'enter_password': 'パスワードを入力',
      'terms_agree_prefix': 'Migii JLPTにログインすることで、',
      'terms_and_privacy': '利用規約とプライバシーポリシー',
      'terms_agree_suffix': 'に同意します',
      'or': 'または',
      'forgot_password': 'パスワードを忘れた',
      'forgot_password_coming_soon': 'パスワードリセット機能は近日公開',
      'sign_in_google': 'Googleでログイン',
      'sign_in_apple': 'Appleでログイン',
      'no_account': 'アカウントをお持ちでない方',
      'sign_up_now': '今すぐ登録',
      'error_terms': '利用規約に同意してください',
      'error_email_required': 'メールアドレスを入力してください',
      'error_password_required': 'パスワードを入力してください',
      'error_network': 'ネットワークエラー。もう一度お試しください',
      'error_google_sign_in': 'Googleログインに失敗しました',
      'error_apple_sign_in': 'Appleログインに失敗しました',
      'error_apple_not_available': 'Appleログインはこのデバイスでは利用できません',
      'error_apple_no_email': 'メールアドレスを取得できませんでした',
      'login_success': 'ログイン成功！',
    },
    'en': {
      'login': 'Log In',
      'enter_email': 'Enter your email',
      'enter_password': 'Enter your password',
      'terms_agree_prefix': 'By logging in to Migii JLPT, you agree to our ',
      'terms_and_privacy': 'Terms and Privacy Policy',
      'terms_agree_suffix': '',
      'or': 'or',
      'forgot_password': 'Forgot password',
      'forgot_password_coming_soon': 'Password reset coming soon',
      'sign_in_google': 'Sign in with Google',
      'sign_in_apple': 'Sign in with Apple',
      'no_account': "Don't have an account?",
      'sign_up_now': 'Sign up now',
      'error_terms': 'Please agree to the terms',
      'error_email_required': 'Please enter your email',
      'error_password_required': 'Please enter your password',
      'error_network': 'Network error. Please try again',
      'error_google_sign_in': 'Google sign in failed',
      'error_apple_sign_in': 'Apple sign in failed',
      'error_apple_not_available': 'Apple sign in is not available on this device',
      'error_apple_no_email': 'Could not retrieve email address',
      'login_success': 'Login successful!',
    },
    'vn': {
      'login': 'Đăng nhập',
      'enter_email': 'Nhập email của bạn',
      'enter_password': 'Nhập mật khẩu của bạn',
      'terms_agree_prefix': 'Bằng việc đăng nhập vào Migii JLPT, bạn đồng ý với ',
      'terms_and_privacy': 'Điều khoản và Chính sách bảo mật',
      'terms_agree_suffix': ' của chúng tôi',
      'or': 'hoặc',
      'forgot_password': 'Quên mật khẩu',
      'forgot_password_coming_soon': 'Tính năng đặt lại mật khẩu sắp ra mắt',
      'sign_in_google': 'Đăng nhập với Google',
      'sign_in_apple': 'Đăng nhập bằng Apple',
      'no_account': 'Bạn chưa có tài khoản?',
      'sign_up_now': 'Đăng ký ngay',
      'error_terms': 'Vui lòng đồng ý với điều khoản',
      'error_email_required': 'Vui lòng nhập email',
      'error_password_required': 'Vui lòng nhập mật khẩu',
      'error_network': 'Lỗi mạng. Vui lòng thử lại',
      'error_google_sign_in': 'Đăng nhập Google thất bại',
      'error_apple_sign_in': 'Đăng nhập Apple thất bại',
      'error_apple_not_available': 'Đăng nhập Apple không khả dụng trên thiết bị này',
      'error_apple_no_email': 'Không thể lấy địa chỉ email',
      'login_success': 'Đăng nhập thành công!',
    },
    'es_auto': {
      'login': 'Iniciar sesión',
      'enter_email': 'Ingresa tu email',
      'enter_password': 'Ingresa tu contraseña',
      'terms_agree_prefix': 'Al iniciar sesión en Migii JLPT, aceptas nuestros ',
      'terms_and_privacy': 'Términos y Política de Privacidad',
      'terms_agree_suffix': '',
      'or': 'o',
      'forgot_password': 'Olvidé mi contraseña',
      'forgot_password_coming_soon': 'Restablecimiento de contraseña próximamente',
      'sign_in_google': 'Iniciar sesión con Google',
      'sign_in_apple': 'Iniciar sesión con Apple',
      'no_account': '¿No tienes cuenta?',
      'sign_up_now': 'Regístrate ahora',
      'error_terms': 'Por favor acepta los términos',
      'error_email_required': 'Por favor ingresa tu email',
      'error_password_required': 'Por favor ingresa tu contraseña',
      'error_network': 'Error de red. Por favor intenta de nuevo',
      'error_google_sign_in': 'Error al iniciar sesión con Google',
      'error_apple_sign_in': 'Error al iniciar sesión con Apple',
      'error_apple_not_available': 'Inicio de sesión con Apple no disponible',
      'error_apple_no_email': 'No se pudo obtener el correo electrónico',
      'login_success': '¡Inicio de sesión exitoso!',
    },
    'fr_auto': {
      'login': 'Connexion',
      'enter_email': 'Entrez votre email',
      'enter_password': 'Entrez votre mot de passe',
      'terms_agree_prefix': 'En vous connectant à Migii JLPT, vous acceptez nos ',
      'terms_and_privacy': 'Conditions et Politique de confidentialité',
      'terms_agree_suffix': '',
      'or': 'ou',
      'forgot_password': 'Mot de passe oublié',
      'forgot_password_coming_soon': 'Réinitialisation du mot de passe bientôt disponible',
      'sign_in_google': 'Se connecter avec Google',
      'sign_in_apple': 'Se connecter avec Apple',
      'no_account': "Vous n'avez pas de compte?",
      'sign_up_now': "S'inscrire maintenant",
      'error_terms': 'Veuillez accepter les conditions',
      'error_email_required': 'Veuillez entrer votre email',
      'error_password_required': 'Veuillez entrer votre mot de passe',
      'error_network': 'Erreur réseau. Veuillez réessayer',
      'error_google_sign_in': 'Échec de la connexion Google',
      'error_apple_sign_in': 'Échec de la connexion Apple',
      'error_apple_not_available': 'Connexion Apple non disponible',
      'error_apple_no_email': "Impossible d'obtenir l'adresse email",
      'login_success': 'Connexion réussie!',
    },
    'cn_auto': {
      'login': '登录',
      'enter_email': '输入您的邮箱',
      'enter_password': '输入您的密码',
      'terms_agree_prefix': '登录Migii JLPT即表示您同意',
      'terms_and_privacy': '条款和隐私政策',
      'terms_agree_suffix': '',
      'or': '或',
      'forgot_password': '忘记密码',
      'forgot_password_coming_soon': '密码重置功能即将推出',
      'sign_in_google': '使用Google登录',
      'sign_in_apple': '使用Apple登录',
      'no_account': '还没有账户？',
      'sign_up_now': '立即注册',
      'error_terms': '请同意条款',
      'error_email_required': '请输入邮箱',
      'error_password_required': '请输入密码',
      'error_network': '网络错误，请重试',
      'error_google_sign_in': 'Google登录失败',
      'error_apple_sign_in': 'Apple登录失败',
      'error_apple_not_available': 'Apple登录在此设备上不可用',
      'error_apple_no_email': '无法获取邮箱地址',
      'login_success': '登录成功！',
    },
    'tw_auto': {
      'login': '登入',
      'enter_email': '輸入您的電子郵件',
      'enter_password': '輸入您的密碼',
      'terms_agree_prefix': '登入Migii JLPT即表示您同意',
      'terms_and_privacy': '條款和隱私政策',
      'terms_agree_suffix': '',
      'or': '或',
      'forgot_password': '忘記密碼',
      'forgot_password_coming_soon': '密碼重置功能即將推出',
      'sign_in_google': '使用Google登入',
      'sign_in_apple': '使用Apple登入',
      'no_account': '還沒有帳戶？',
      'sign_up_now': '立即註冊',
      'error_terms': '請同意條款',
      'error_email_required': '請輸入電子郵件',
      'error_password_required': '請輸入密碼',
      'error_network': '網路錯誤，請重試',
      'error_google_sign_in': 'Google登入失敗',
      'error_apple_sign_in': 'Apple登入失敗',
      'error_apple_not_available': 'Apple登入在此裝置上不可用',
      'error_apple_no_email': '無法獲取郵件地址',
      'login_success': '登入成功！',
    },
    'ru_auto': {
      'login': 'Войти',
      'enter_email': 'Введите ваш email',
      'enter_password': 'Введите ваш пароль',
      'terms_agree_prefix': 'Входя в Migii JLPT, вы соглашаетесь с нашими ',
      'terms_and_privacy': 'Условиями и Политикой конфиденциальности',
      'terms_agree_suffix': '',
      'or': 'или',
      'forgot_password': 'Забыли пароль',
      'forgot_password_coming_soon': 'Сброс пароля скоро будет доступен',
      'sign_in_google': 'Войти через Google',
      'sign_in_apple': 'Войти через Apple',
      'no_account': 'Нет аккаунта?',
      'sign_up_now': 'Зарегистрируйтесь',
      'error_terms': 'Пожалуйста, примите условия',
      'error_email_required': 'Пожалуйста, введите email',
      'error_password_required': 'Пожалуйста, введите пароль',
      'error_network': 'Ошибка сети. Попробуйте еще раз',
      'error_google_sign_in': 'Не удалось войти через Google',
      'error_apple_sign_in': 'Не удалось войти через Apple',
      'error_apple_not_available': 'Вход через Apple недоступен на этом устройстве',
      'error_apple_no_email': 'Не удалось получить email',
      'login_success': 'Вход выполнен успешно!',
    },
    'id_auto': {
      'login': 'Masuk',
      'enter_email': 'Masukkan email Anda',
      'enter_password': 'Masukkan kata sandi Anda',
      'terms_agree_prefix': 'Dengan masuk ke Migii JLPT, Anda menyetujui ',
      'terms_and_privacy': 'Syarat dan Kebijakan Privasi',
      'terms_agree_suffix': ' kami',
      'or': 'atau',
      'forgot_password': 'Lupa kata sandi',
      'forgot_password_coming_soon': 'Reset kata sandi segera hadir',
      'sign_in_google': 'Masuk dengan Google',
      'sign_in_apple': 'Masuk dengan Apple',
      'no_account': 'Belum punya akun?',
      'sign_up_now': 'Daftar sekarang',
      'error_terms': 'Silakan setujui ketentuan',
      'error_email_required': 'Silakan masukkan email',
      'error_password_required': 'Silakan masukkan kata sandi',
      'error_network': 'Kesalahan jaringan. Silakan coba lagi',
      'error_google_sign_in': 'Gagal masuk dengan Google',
      'error_apple_sign_in': 'Gagal masuk dengan Apple',
      'error_apple_not_available': 'Masuk dengan Apple tidak tersedia di perangkat ini',
      'error_apple_no_email': 'Tidak dapat mengambil alamat email',
      'login_success': 'Berhasil masuk!',
    },
    'ko_auto': {
      'login': '로그인',
      'enter_email': '이메일을 입력하세요',
      'enter_password': '비밀번호를 입력하세요',
      'terms_agree_prefix': 'Migii JLPT에 로그인하면 ',
      'terms_and_privacy': '이용약관 및 개인정보 보호정책',
      'terms_agree_suffix': '에 동의하게 됩니다',
      'or': '또는',
      'forgot_password': '비밀번호 찾기',
      'forgot_password_coming_soon': '비밀번호 재설정 기능 출시 예정',
      'sign_in_google': 'Google로 로그인',
      'sign_in_apple': 'Apple로 로그인',
      'no_account': '계정이 없으신가요?',
      'sign_up_now': '지금 가입하세요',
      'error_terms': '약관에 동의해 주세요',
      'error_email_required': '이메일을 입력해 주세요',
      'error_password_required': '비밀번호를 입력해 주세요',
      'error_network': '네트워크 오류. 다시 시도해 주세요',
      'error_google_sign_in': 'Google 로그인 실패',
      'error_apple_sign_in': 'Apple 로그인 실패',
      'error_apple_not_available': '이 기기에서는 Apple 로그인을 사용할 수 없습니다',
      'error_apple_no_email': '이메일 주소를 가져올 수 없습니다',
      'login_success': '로그인 성공!',
    },
    'my_auto': {
      'login': 'Log Masuk',
      'enter_email': 'Masukkan e-mel anda',
      'enter_password': 'Masukkan kata laluan anda',
      'terms_agree_prefix': 'Dengan log masuk ke Migii JLPT, anda bersetuju dengan ',
      'terms_and_privacy': 'Terma dan Dasar Privasi',
      'terms_agree_suffix': ' kami',
      'or': 'atau',
      'forgot_password': 'Lupa kata laluan',
      'forgot_password_coming_soon': 'Tetapan semula kata laluan akan datang',
      'sign_in_google': 'Log masuk dengan Google',
      'sign_in_apple': 'Log masuk dengan Apple',
      'no_account': 'Tiada akaun?',
      'sign_up_now': 'Daftar sekarang',
      'error_terms': 'Sila bersetuju dengan terma',
      'error_email_required': 'Sila masukkan e-mel',
      'error_password_required': 'Sila masukkan kata laluan',
      'error_network': 'Ralat rangkaian. Sila cuba lagi',
      'error_google_sign_in': 'Log masuk Google gagal',
      'error_apple_sign_in': 'Log masuk Apple gagal',
      'error_apple_not_available': 'Log masuk Apple tidak tersedia pada peranti ini',
      'error_apple_no_email': 'Tidak dapat mendapatkan alamat e-mel',
      'login_success': 'Log masuk berjaya!',
    },
    'pt_auto': {
      'login': 'Entrar',
      'enter_email': 'Digite seu email',
      'enter_password': 'Digite sua senha',
      'terms_agree_prefix': 'Ao entrar no Migii JLPT, você concorda com nossos ',
      'terms_and_privacy': 'Termos e Política de Privacidade',
      'terms_agree_suffix': '',
      'or': 'ou',
      'forgot_password': 'Esqueceu a senha',
      'forgot_password_coming_soon': 'Redefinição de senha em breve',
      'sign_in_google': 'Entrar com Google',
      'sign_in_apple': 'Entrar com Apple',
      'no_account': 'Não tem uma conta?',
      'sign_up_now': 'Cadastre-se agora',
      'error_terms': 'Por favor, aceite os termos',
      'error_email_required': 'Por favor, insira seu email',
      'error_password_required': 'Por favor, insira sua senha',
      'error_network': 'Erro de rede. Por favor, tente novamente',
      'error_google_sign_in': 'Falha no login com Google',
      'error_apple_sign_in': 'Falha no login com Apple',
      'error_apple_not_available': 'Login com Apple não disponível neste dispositivo',
      'error_apple_no_email': 'Não foi possível obter o endereço de email',
      'login_success': 'Login realizado com sucesso!',
    },
    'cn': {
      'login': '登录',
      'enter_email': '输入您的邮箱',
      'enter_password': '输入您的密码',
      'terms_agree_prefix': '登录Migii JLPT即表示您同意',
      'terms_and_privacy': '条款和隐私政策',
      'terms_agree_suffix': '',
      'or': '或',
      'forgot_password': '忘记密码',
      'forgot_password_coming_soon': '密码重置功能即将推出',
      'sign_in_google': '使用Google登录',
      'sign_in_apple': '使用Apple登录',
      'no_account': '还没有账户？',
      'sign_up_now': '立即注册',
      'error_terms': '请同意条款',
      'error_email_required': '请输入邮箱',
      'error_password_required': '请输入密码',
      'error_network': '网络错误，请重试',
      'error_google_sign_in': 'Google登录失败',
      'error_apple_sign_in': 'Apple登录失败',
      'error_apple_not_available': 'Apple登录在此设备上不可用',
      'error_apple_no_email': '无法获取邮箱地址',
      'login_success': '登录成功！',
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

// Google Logo widget for fallback when network image fails
class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Google colors
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final greenPaint = Paint()..color = const Color(0xFF34A853);

    // Draw G shape with arcs
    final rect = Rect.fromLTWH(0, 0, w, h);

    // Blue arc (right side)
    canvas.drawArc(rect, -0.4, 1.4, true, bluePaint);

    // Red arc (top)
    canvas.drawArc(rect, -0.4, -1.2, true, redPaint);

    // Yellow arc (bottom left)
    canvas.drawArc(rect, 2.2, 1.2, true, yellowPaint);

    // Green arc (bottom)
    canvas.drawArc(rect, 1.0, 1.2, true, greenPaint);

    // White center circle
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w / 2, h / 2), w * 0.35, whitePaint);

    // Blue horizontal bar
    canvas.drawRect(
      Rect.fromLTWH(w * 0.5, h * 0.4, w * 0.5, h * 0.2),
      bluePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
