import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:medicare_plus/constants/app_constants.dart';
import 'package:medicare_plus/services/auth_service.dart';
import 'package:medicare_plus/utils/connectivity_service.dart';
import 'package:medicare_plus/utils/localization_provider.dart';
import 'package:medicare_plus/utils/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AuthService _authService = AuthService();
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showSignOutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _signOut();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AboutDialog(
        applicationName: AppConstants.appName,
        applicationVersion: 'Version ${_packageInfo.version} (${_packageInfo.buildNumber})',
        applicationIcon: Image.asset(
          'assets/images/logo.png',
          width: 48,
          height: 48,
        ),
        applicationLegalese: '© ${DateTime.now().year} Medicare+ Team',
        children: [
          const SizedBox(height: 16),
          Text(AppConstants.appDescription),
          const SizedBox(height: 16),
          const Text(
            'Medicare+ is a healthcare application designed to help users diagnose skin and eye conditions, manage medication reminders, and find nearby specialists.',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final localizationProvider = Provider.of<LocalizationProvider>(context);
    final connectivityService = Provider.of<ConnectivityService>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: StreamBuilder<bool>(
        stream: connectivityService.connectionStream,
        builder: (context, snapshot) {
          final isConnected = snapshot.data ?? true;
          
          return ListView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            children: [
              // User profile section
              if (currentUser != null) ...[                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: AppConstants.primaryColor.withOpacity(0.2),
                        child: Text(
                          currentUser.displayName?.isNotEmpty == true
                              ? currentUser.displayName![0].toUpperCase()
                              : currentUser.email?[0].toUpperCase() ?? 'U',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppConstants.primaryColor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentUser.displayName ?? 'User',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        currentUser.email ?? '',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/profile');
                        },
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                          ),
                        ),
                        child: const Text('Edit Profile'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // App preferences section
              Text(
                'App Preferences',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  children: [
                    // Theme toggle
                    SwitchListTile(
                      title: const Text('Dark Mode'),
                      subtitle: const Text('Toggle between light and dark theme'),
                      secondary: Icon(
                        isDarkMode ? Icons.dark_mode : Icons.light_mode,
                        color: isDarkMode ? Colors.amber : Colors.blueGrey,
                      ),
                      value: isDarkMode,
                      onChanged: (value) {
                        themeProvider.toggleTheme();
                      },
                    ),
                    const Divider(),
                    // Language selection
                    ListTile(
                      title: const Text('Language'),
                      subtitle: Text(localizationProvider.currentLanguageName),
                      leading: const Icon(Icons.language),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Select Language'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: localizationProvider.supportedLocales.length,
                                itemBuilder: (context, index) {
                                  final locale = localizationProvider.supportedLocales[index];
                                  final languageName = localizationProvider.getDisplayLanguage(locale);
                                  final isSelected = locale.languageCode == localizationProvider.locale.languageCode;
                                  
                                  return ListTile(
                                    title: Text(languageName),
                                    trailing: isSelected ? const Icon(Icons.check, color: AppConstants.primaryColor) : null,
                                    onTap: () {
                                      localizationProvider.setLocale(locale);
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Cancel'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    const Divider(),
                    // Notification settings
                    ListTile(
                      title: const Text('Notification Settings'),
                      subtitle: const Text('Manage app notifications'),
                      leading: const Icon(Icons.notifications_outlined),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushNamed(context, AppConstants.notificationSettingsRoute);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Data and privacy section
              Text(
                'Data & Privacy',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Privacy Policy'),
                      leading: const Icon(Icons.privacy_tip_outlined),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushNamed(context, '/privacy_policy');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Terms of Service'),
                      leading: const Icon(Icons.description_outlined),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushNamed(context, '/terms_of_service');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Data Management'),
                      subtitle: const Text('Manage your data and export options'),
                      leading: const Icon(Icons.storage_outlined),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        if (!isConnected) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No internet connection. Please check your connection and try again.')),
                          );
                          return;
                        }
                        Navigator.pushNamed(context, '/data_management');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Support and feedback section
              Text(
                'Support & Feedback',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  border: Border.all(
                    color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                  ),
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text('Help Center'),
                      leading: const Icon(Icons.help_outline),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushNamed(context, '/help_center');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('Send Feedback'),
                      leading: const Icon(Icons.feedback_outlined),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        Navigator.pushNamed(context, '/feedback');
                      },
                    ),
                    const Divider(),
                    ListTile(
                      title: const Text('About Medicare+'),
                      leading: const Icon(Icons.info_outline),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _showAboutDialog,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Sign out button
              if (currentUser != null) ...[                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _showSignOutConfirmation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Sign Out'),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // App version
              Center(
                child: Text(
                  'Version ${_packageInfo.version} (${_packageInfo.buildNumber})',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '© ${DateTime.now().year} Medicare+ Team',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          );
        },
      ),
    );
  }
}