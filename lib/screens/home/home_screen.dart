import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:medicare_plus/constants/app_constants.dart';
import 'package:medicare_plus/services/auth_service.dart';
import 'package:medicare_plus/utils/theme_provider.dart';
import 'package:medicare_plus/utils/connectivity_service.dart';
import 'package:medicare_plus/screens/scan/scan_options_screen.dart';
import 'package:medicare_plus/screens/scan/scan_history_screen.dart';
import 'package:medicare_plus/screens/reminders/reminders_list_screen.dart';
import 'package:medicare_plus/screens/specialists/specialist_map_screen.dart';
import 'package:medicare_plus/screens/settings/settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  String _userName = '';
  bool _isLoading = true;
  bool _isConnected = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _setupConnectivityListener();
  }

  void _setupConnectivityListener() {
    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    connectivityService.connectionStream.listen((hasConnection) {
      setState(() {
        _isConnected = hasConnection;
      });
      
      if (!_isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are offline. Some features may be limited.'),
            backgroundColor: AppConstants.warningColor,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userData = await _authService.getUserProfile(user.uid);
        if (userData != null && mounted) {
          setState(() {
            _userName = userData.name;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // App bar with user greeting and settings button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hello, ${_userName.isNotEmpty ? _userName.split(' ')[0] : 'there'}!',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'How are you feeling today?',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings_outlined),
                          onPressed: () {
                            Navigator.of(context).pushNamed(AppConstants.settingsRoute);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Offline indicator
                    if (!_isConnected) ...[                    
                      Container(
                        padding: const EdgeInsets.all(AppConstants.smallPadding),
                        decoration: BoxDecoration(
                          color: AppConstants.warningColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.wifi_off,
                              color: AppConstants.warningColor,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'You are currently offline. Some features may be limited.',
                                style: TextStyle(color: AppConstants.warningColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Main feature cards
                    Text(
                      'What would you like to do?',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    
                    // Scan options card
                    _buildFeatureCard(
                      context: context,
                      title: 'Scan & Diagnose',
                      description: 'Analyze skin or eye conditions using your camera',
                      icon: Icons.camera_alt_outlined,
                      color: AppConstants.primaryColor,
                      onTap: () {
                        Navigator.of(context).pushNamed(AppConstants.scanOptionsRoute);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // History card
                    _buildFeatureCard(
                      context: context,
                      title: 'Scan History',
                      description: 'View your previous scans and track progress',
                      icon: Icons.history,
                      color: Colors.purple,
                      onTap: () {
                        Navigator.of(context).pushNamed(AppConstants.scanHistoryRoute);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Reminders card
                    _buildFeatureCard(
                      context: context,
                      title: 'Medicine Reminders',
                      description: 'Set and manage your medication schedule',
                      icon: Icons.notifications_active_outlined,
                      color: Colors.orange,
                      onTap: () {
                        Navigator.of(context).pushNamed(AppConstants.remindersRoute);
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Specialist map card
                    _buildFeatureCard(
                      context: context,
                      title: 'Find Specialists',
                      description: 'Locate nearby dermatologists and ophthalmologists',
                      icon: Icons.map_outlined,
                      color: Colors.green,
                      onTap: () {
                        Navigator.of(context).pushNamed(AppConstants.specialistMapRoute);
                      },
                    ),
                    const SizedBox(height: 24),

                    // Medical disclaimer
                    Container(
                      padding: const EdgeInsets.all(AppConstants.smallPadding),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Medical Disclaimer',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            AppConstants.medicalDisclaimer,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildFeatureCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ],
          ),
        ),
      ),
    );
  }
}