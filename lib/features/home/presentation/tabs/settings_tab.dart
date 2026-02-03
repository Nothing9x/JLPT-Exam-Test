import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/token_storage.dart';
import '../../../../core/services/theme_notifier.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../models/language_model.dart';
import '../screens/profile_settings_screen.dart';
import '../screens/offline_download_screen.dart';

class SettingsTab extends StatefulWidget {
  final String languageCode;
  final String? token;
  final Map<String, dynamic>? userData;

  const SettingsTab({
    super.key,
    required this.languageCode,
    this.token,
    this.userData,
  });

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  late String _selectedLanguage;
  bool _studyRemindersEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 9, minute: 0);
  Map<String, dynamic>? _userData;
  final ThemeNotifier _themeNotifier = ThemeNotifier();
  final NotificationService _notificationService = NotificationService();

  static const String _baseUrl = 'https://8e23deb9e9e2.ngrok-free.app/api';

  @override
  void initState() {
    super.initState();
    _selectedLanguage = widget.languageCode;
    _userData = widget.userData;
    _loadSettings();
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

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studyRemindersEnabled = prefs.getBool('studyReminders') ?? true;
      final hour = prefs.getInt('reminderHour') ?? 9;
      final minute = prefs.getInt('reminderMinute') ?? 0;
      _reminderTime = TimeOfDay(hour: hour, minute: minute);
    });
  }

  Future<void> _updateLanguageOnServer(String languageCode) async {
    if (widget.token == null) return;

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/user/profile'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'language': languageCode}),
      );

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('languageCode', languageCode);
        await TokenStorage.saveLanguage(languageCode);
      }
    } catch (e) {
      debugPrint('Error updating language: $e');
    }
  }

  Future<void> _updateProfileOnServer(String fullName) async {
    if (widget.token == null) return;

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/user/profile'),
        headers: {
          'Authorization': 'Bearer ${widget.token}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'fullName': fullName}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _userData = {...?_userData, 'fullName': fullName};
        });
      }
    } catch (e) {
      debugPrint('Error updating profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: _buildAppBar(isDark),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAccountCard(isDark),
              const SizedBox(height: 24),
              _buildSectionTitle('App Settings', isDark),
              const SizedBox(height: 12),
              _buildAppSettingsCard(isDark),
              const SizedBox(height: 24),
              _buildSectionTitle('Upgrade', isDark),
              const SizedBox(height: 12),
              _buildUpgradeCard(isDark),
              const SizedBox(height: 24),
              _buildSectionTitle('Support', isDark),
              const SizedBox(height: 12),
              _buildSupportCard(isDark),
              const SizedBox(height: 24),
              _buildVersionText(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDark) {
    return AppBar(
      backgroundColor: isDark
          ? AppColors.backgroundDark.withValues(alpha: 0.8)
          : AppColors.backgroundLight.withValues(alpha: 0.8),
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back,
          color: isDark ? Colors.white : AppColors.textPrimaryLight,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'Settings',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : AppColors.textPrimaryLight,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white : AppColors.textPrimaryLight,
        ),
      ),
    );
  }

  Widget _buildAccountCard(bool isDark) {
    final userName = _userData?['fullName'] ?? 'User';
    final avatarUrl = _userData?['avatarUrl'];
    final isPremium = _userData?['isPremium'] ?? false;

    return GestureDetector(
      onTap: () => _navigateToProfileSettings(isDark),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBackgroundDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: AppColors.shadowPink,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Colors.grey[200],
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Icon(Icons.person, size: 32, color: Colors.grey[400])
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 12,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isPremium ? 'Premium Account' : 'Free Account',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _showLogoutDialog(context),
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Log out',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppSettingsCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppColors.shadowPink,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        children: [
          _buildSettingsListItem(
            isDark: isDark,
            icon: Icons.menu_book,
            title: 'How to use Migii',
            showDivider: true,
            onTap: () {},
          ),
          _buildSettingsListItem(
            isDark: isDark,
            icon: Icons.notifications_outlined,
            title: 'Study Reminders',
            showDivider: true,
            onTap: () => _showStudyRemindersDialog(context, isDark),
          ),
          _buildSettingsListItem(
            isDark: isDark,
            icon: Icons.translate,
            title: 'App Language',
            trailing: _buildLanguageValue(isDark),
            showDivider: true,
            onTap: () => _showLanguageDialog(context, isDark),
          ),
          _buildDarkModeItem(isDark),
        ],
      ),
    );
  }

  Widget _buildLanguageValue(bool isDark) {
    final lang = LanguageModel.supportedLanguages.firstWhere(
      (l) => l.code == _selectedLanguage,
      orElse: () => LanguageModel.supportedLanguages.first,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          lang.name,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(width: 4),
        Icon(Icons.chevron_right, color: Colors.grey[400]),
      ],
    );
  }

  Widget _buildDarkModeItem(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.dark_mode_outlined,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Dark Mode',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.textPrimaryLight,
              ),
            ),
          ),
          Switch(
            value: _themeNotifier.isDarkMode,
            onChanged: (value) {
              _themeNotifier.setDarkMode(value);
            },
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsListItem({
    required bool isDark,
    required IconData icon,
    required String title,
    Widget? trailing,
    bool showDivider = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: showDivider
              ? Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
                  ),
                )
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.textPrimaryLight,
                ),
              ),
            ),
            trailing ?? Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildUpgradeCard(bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OfflineDownloadScreen(token: widget.token),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardBackgroundDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                    color: AppColors.shadowPink,
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cloud_download_outlined,
                    color: Colors.indigo),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offline Practice',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Download lessons for travel',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[700] : Colors.grey[100],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.download,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSupportCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: AppColors.shadowPink,
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Column(
        children: [
          _buildSettingsListItem(
            isDark: isDark,
            icon: Icons.star_outline,
            title: 'Rate Us',
            showDivider: true,
            onTap: () {},
          ),
          _buildSettingsListItem(
            isDark: isDark,
            icon: Icons.mail_outline,
            title: 'Feedback',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildVersionText() {
    return Center(
      child: Text(
        'Migii Japanese v2.4.0',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, bool isDark) {
    String tempSelected = _selectedLanguage;
    final languages = LanguageModel.supportedLanguages;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor:
                  isDark ? AppColors.cardBackgroundDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Select Language',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: languages.length,
                        itemBuilder: (context, index) {
                          final lang = languages[index];
                          final isSelected = lang.code == tempSelected;
                          return InkWell(
                            onTap: () =>
                                setDialogState(() => tempSelected = lang.code),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 24, vertical: 12),
                              child: Row(
                                children: [
                                  Text(
                                    lang.flagEmoji,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          lang.name,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: isDark
                                                ? Colors.white
                                                : AppColors.textPrimaryLight,
                                          ),
                                        ),
                                        if (lang.nativeName != lang.name)
                                          Text(
                                            lang.nativeName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isSelected
                                          ? AppColors.primary
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: isSelected
                                            ? AppColors.primary
                                            : Colors.grey[400]!,
                                        width: 2,
                                      ),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check,
                                            size: 14, color: Colors.white)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Divider(
                        color: isDark ? Colors.grey[800] : Colors.grey[200]),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setState(() => _selectedLanguage = tempSelected);
                              _updateLanguageOnServer(tempSelected);
                              Navigator.pop(context);
                            },
                            child: Text(
                              'Confirm',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showStudyRemindersDialog(BuildContext context, bool isDark) {
    bool tempEnabled = _studyRemindersEnabled;
    TimeOfDay tempTime = _reminderTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor:
                  isDark ? AppColors.cardBackgroundDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Study Reminders',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color:
                            isDark ? Colors.white : AppColors.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Enable study reminders',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        Switch(
                          value: tempEnabled,
                          onChanged: (value) {
                            setDialogState(() => tempEnabled = value);
                          },
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Reminder time',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimaryLight,
                          ),
                        ),
                        InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: tempTime,
                            );
                            if (picked != null) {
                              setDialogState(() => tempTime = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isDark ? Colors.grey[800] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tempTime.format(context),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimaryLight,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Divider(
                        color: isDark ? Colors.grey[700] : Colors.grey[200]),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 24,
                          color: isDark ? Colors.grey[700] : Colors.grey[200],
                        ),
                        Expanded(
                          child: TextButton(
                            onPressed: () async {
                              // Store references before async operations
                              final navigator = Navigator.of(context);
                              final scaffoldMessenger = ScaffoldMessenger.of(context);
                              final formattedTime = tempTime.format(context);
                              
                              setState(() {
                                _studyRemindersEnabled = tempEnabled;
                                _reminderTime = tempTime;
                              });

                              // Close dialog first
                              navigator.pop();

                              // Then schedule notifications in background
                              try {
                                await _notificationService.requestPermission();
                                await _notificationService.scheduleStudyReminder(
                                  time: tempTime,
                                  enabled: tempEnabled,
                                );
                                
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      tempEnabled
                                          ? 'Reminder set for $formattedTime'
                                          : 'Reminders disabled',
                                    ),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              } catch (e) {
                                debugPrint('Error scheduling notification: $e');
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      tempEnabled
                                          ? 'Reminder saved (notification may not work)'
                                          : 'Reminders disabled',
                                    ),
                                    backgroundColor: AppColors.primary,
                                  ),
                                );
                              }
                            },
                            child: Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _navigateToProfileSettings(bool isDark) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileSettingsScreen(
          token: widget.token,
          userData: _userData,
        ),
      ),
    );

    // If profile was updated, refresh the userData
    if (result != null) {
      setState(() {
        _userData = result;
        _selectedLanguage = result['language'] ?? _selectedLanguage;
      });
    }
  }

  void _showLogoutDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: isDark ? AppColors.cardBackgroundDark : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Are you sure you want to log out?',
                  style: TextStyle(
                    fontSize: 16,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await TokenStorage.clearAllUserData();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/language-selection',
                              (Route<dynamic> route) => false,
                            );
                          }
                        },
                        child: const Text(
                          'Log Out',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
