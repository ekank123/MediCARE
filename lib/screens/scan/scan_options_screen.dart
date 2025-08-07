import 'package:flutter/material.dart';
import 'package:medicare_plus/constants/app_constants.dart';
import 'package:medicare_plus/screens/scan/skin_scan_screen.dart';
import 'package:medicare_plus/screens/scan/eye_scan_screen.dart';
import 'package:provider/provider.dart';
import 'package:medicare_plus/utils/theme_provider.dart';

class ScanOptionsScreen extends StatelessWidget {
  const ScanOptionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan & Diagnose'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What would you like to scan?',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose the type of condition you want to analyze',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 32),
              
              // Skin scan option
              _buildScanOption(
                context: context,
                title: 'Skin Condition',
                description: 'Analyze rashes, spots, moles, and other skin issues',
                icon: Icons.face_outlined,
                color: AppConstants.primaryColor,
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const SkinScanScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              
              // Eye scan option
              _buildScanOption(
                context: context,
                title: 'Eye Condition',
                description: 'Analyze redness, irritation, and other eye issues',
                icon: Icons.remove_red_eye_outlined,
                color: Colors.blue,
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const EyeScanScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              
              // Instructions section
              Container(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tips for better results:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _buildTip(
                      context: context,
                      icon: Icons.lightbulb_outline,
                      text: 'Use good lighting for clear images',
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 12),
                    _buildTip(
                      context: context,
                      icon: Icons.center_focus_strong_outlined,
                      text: 'Keep the camera steady and focused',
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 12),
                    _buildTip(
                      context: context,
                      icon: Icons.crop_free,
                      text: 'Capture the entire affected area',
                      isDarkMode: isDarkMode,
                    ),
                    const SizedBox(height: 12),
                    _buildTip(
                      context: context,
                      icon: Icons.compare_outlined,
                      text: 'Take multiple angles if possible',
                      isDarkMode: isDarkMode,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Medical disclaimer
              Container(
                padding: const EdgeInsets.all(AppConstants.smallPadding),
                decoration: BoxDecoration(
                  color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  border: Border.all(color: AppConstants.warningColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppConstants.warningColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This app provides preliminary analysis only. Always consult a healthcare professional for proper diagnosis.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                            ),
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

  Widget _buildScanOption({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[800] : Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 40,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
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
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTip({
    required BuildContext context,
    required IconData icon,
    required String text,
    required bool isDarkMode,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                ),
          ),
        ),
      ],
    );
  }
}