import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../tabs/practice_tab.dart';
import '../tabs/exams_tab.dart';
import '../tabs/upgrade_tab.dart';
import '../tabs/settings_tab.dart';

class HomeScreen extends StatefulWidget {
  final String languageCode;
  final String? token;

  const HomeScreen({
    super.key,
    required this.languageCode,
    this.token,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      PracticeTab(
        languageCode: widget.languageCode,
        token: widget.token,
        onMockExamsPressed: () {
          setState(() => _currentIndex = 1);
        },
      ),
      ExamsTab(
        languageCode: widget.languageCode,
        token: widget.token,
        onNavigateToUpgrade: () {
          setState(() => _currentIndex = 2);
        },
      ),
      const UpgradeTab(),
      SettingsTab(
        languageCode: widget.languageCode,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _tabs[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDark ? AppColors.cardBackgroundDark : Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: isDark
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
        elevation: 8,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_document),
            activeIcon: Icon(Icons.edit_document),
            label: 'Exam',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.workspace_premium_outlined),
            activeIcon: Icon(Icons.workspace_premium),
            label: 'Premium',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Setting',
          ),
        ],
      ),
    );
  }
}
