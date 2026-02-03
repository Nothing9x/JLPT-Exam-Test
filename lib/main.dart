import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/services/token_storage.dart';
import 'core/services/theme_notifier.dart';
import 'core/services/notification_service.dart';
import 'features/language_selection/presentation/screens/language_selection_screen.dart';
import 'features/home/presentation/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
    ),
  );

  // Initialize services
  await ThemeNotifier().initialize();
  await NotificationService().initialize();

  runApp(const JLPTExamTestApp());
}

class JLPTExamTestApp extends StatefulWidget {
  const JLPTExamTestApp({super.key});

  @override
  State<JLPTExamTestApp> createState() => _JLPTExamTestAppState();
}

class _JLPTExamTestAppState extends State<JLPTExamTestApp> {
  final ThemeNotifier _themeNotifier = ThemeNotifier();

  @override
  void initState() {
    super.initState();
    _themeNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    _themeNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JLPT Exam Test',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeNotifier.themeMode,
      home: const _InitialScreen(),
    );
  }
}

class _InitialScreen extends StatefulWidget {
  const _InitialScreen();

  @override
  State<_InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<_InitialScreen> {
  late Future<Widget> _initialRoute;

  @override
  void initState() {
    super.initState();
    _initialRoute = _getInitialRoute();
  }

  Future<Widget> _getInitialRoute() async {
    // Check if user is already logged in
    final isLoggedIn = await TokenStorage.isLoggedIn();
    
    if (isLoggedIn) {
      // Get stored language and token
      final language = await TokenStorage.getLanguage();
      final token = await TokenStorage.getToken();
      
      return HomeScreen(
        languageCode: language,
        token: token,
      );
    } else {
      // Show language selection screen
      return const LanguageSelectionScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _initialRoute,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
          return snapshot.data!;
        }
        // Loading screen while checking login status
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }
}
