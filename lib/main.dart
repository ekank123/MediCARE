import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'package:medicare_plus/constants/app_constants.dart';
import 'package:medicare_plus/models/scan_model.dart';
import 'package:medicare_plus/utils/theme_provider.dart';
import 'package:medicare_plus/utils/localization_provider.dart';
import 'package:medicare_plus/utils/connectivity_service.dart';
import 'package:medicare_plus/screens/splash_screen.dart';
import 'package:medicare_plus/screens/auth/login_screen.dart';
import 'package:medicare_plus/screens/auth/register_screen.dart';
import 'package:medicare_plus/screens/home/home_screen.dart';
import 'package:medicare_plus/screens/settings/profile_screen.dart';
import 'package:medicare_plus/screens/scan/scan_options_screen.dart';
import 'package:medicare_plus/screens/scan/scan_result_screen.dart';
import 'package:medicare_plus/screens/scan/scan_history_screen.dart';
import 'package:medicare_plus/screens/reminders/reminders_list_screen.dart';
import 'package:medicare_plus/screens/specialists/specialist_map_screen.dart';
import 'package:medicare_plus/screens/feedback/feedback_screen.dart';
import 'package:medicare_plus/screens/settings/settings_screen.dart';
import 'package:medicare_plus/screens/settings/notification_settings_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => LocalizationProvider()),
        Provider(create: (_) => ConnectivityService()),
      ],
      child: Consumer2<ThemeProvider, LocalizationProvider>(
        builder: (context, themeProvider, localizationProvider, _) {
          return MaterialApp(
            title: AppConstants.appName,
            theme: themeProvider.getTheme(),
            locale: localizationProvider.locale,
            supportedLocales: localizationProvider.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: AppConstants.splashRoute,
            routes: {
              AppConstants.splashRoute: (context) => const SplashScreen(),
              AppConstants.loginRoute: (context) => const LoginScreen(),
              AppConstants.registerRoute: (context) => const RegisterScreen(),
              AppConstants.homeRoute: (context) => const HomeScreen(),
              AppConstants.profileRoute: (context) => const ProfileScreen(),
              AppConstants.scanOptionsRoute: (context) =>
                  const ScanOptionsScreen(),
              AppConstants.scanHistoryRoute: (context) =>
                  const ScanHistoryScreen(),
              AppConstants.historyRoute: (context) => const ScanHistoryScreen(),
              AppConstants.reminderRoute: (context) =>
                  const RemindersListScreen(),
              AppConstants.remindersRoute: (context) =>
                  const RemindersListScreen(),
              AppConstants.specialistMapRoute: (context) =>
                  const SpecialistMapScreen(),
              AppConstants.feedbackRoute: (context) => const FeedbackScreen(),
              AppConstants.settingsRoute: (context) => const SettingsScreen(),
              AppConstants.notificationSettingsRoute: (context) =>
                  const NotificationSettingsScreen(),
            },
            onGenerateRoute: (settings) {
              if (settings.name == AppConstants.scanResultRoute) {
                final args = settings.arguments as Map<String, dynamic>?;
                final scan = args?['scan'] as ScanModel?;
                return MaterialPageRoute(
                  builder: (context) => ScanResultScreen(scan: scan!),
                );
              }
              return null;
            },
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
