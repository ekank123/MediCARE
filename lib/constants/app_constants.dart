import 'package:flutter/material.dart';

class AppConstants {
  // App information
  static const String appName = 'Medicare+';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Self-screening for skin and eye conditions';
  
  // Firebase collections
  static const String usersCollection = 'users';
  static const String scansCollection = 'scans';
  static const String remindersCollection = 'reminders';
  static const String feedbackCollection = 'feedback';
  static const String specialistsCollection = 'specialists';
  
  // Routes
  static const String splashRoute = '/';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String completeProfileRoute = '/complete-profile';
  static const String homeRoute = '/home';
  static const String profileRoute = '/profile';
  static const String scanRoute = '/scan';
  static const String scanOptionsRoute = '/scan-options';
  static const String scanResultRoute = '/scan-result';
  static const String historyRoute = '/history';
  static const String scanHistoryRoute = '/scan-history';
  static const String reminderRoute = '/reminders';
  static const String remindersRoute = '/reminders';
  static const String specialistMapRoute = '/specialist-map';
  static const String feedbackRoute = '/feedback';
  static const String settingsRoute = '/settings';
  static const String notificationSettingsRoute = '/notification_settings';
  
  // Shared preferences keys
  static const String themePreference = 'theme_preference';
  static const String languagePreference = 'language_preference';
  static const String userIdPreference = 'user_id_preference';
  static const String onboardingCompletePreference = 'onboarding_complete';
  
  // Notification preferences
  static const String prefEnableAllNotifications = 'enable_all_notifications';
  static const String prefEnableMedicationReminders = 'enable_medication_reminders';
  static const String prefEnableScanResults = 'enable_scan_results';
  static const String prefEnableAppUpdates = 'enable_app_updates';
  static const String prefEnablePromotions = 'enable_promotions';
  static const String prefEnableSound = 'enable_sound';
  static const String prefEnableVibration = 'enable_vibration';
  static const String prefReminderLeadTime = 'reminder_lead_time';
  static const String prefEnableSnooze = 'enable_snooze';
  static const String prefSnoozeTime = 'snooze_time';
  
  // API keys and endpoints
  // Note: In a production app, these would be stored securely, not hardcoded
  static const String geminiApiKey = 'YOUR_GEMINI_API_KEY';
  
  // Default map settings
  static const double defaultMapZoom = 14.0;
  static const double defaultSearchRadius = 5.0; // km
  
  // UI constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultElevation = 2.0;
  
  // Colors
  static const Color primaryColor = Color(0xFF4CAF50);
  static const Color accentColor = Color(0xFF81C784);
  static const Color backgroundColor = Colors.white;
  static const Color darkBackgroundColor = Color(0xFF121212);
  static const Color errorColor = Color(0xFFE57373);
  static const Color warningColor = Color(0xFFFFB74D);
  static const Color successColor = Color(0xFF81C784);
  
  // Urgency level colors
  static const Color mildColor = Color(0xFF81C784); // Light green
  static const Color monitoringColor = Color(0xFFFFB74D); // Orange
  static const Color seeDoctorColor = Color(0xFFE57373); // Red
  
  // Urgency level colors (aliases for compatibility)
  static const Color mildUrgencyColor = mildColor;
  static const Color moderateUrgencyColor = monitoringColor;
  static const Color severeUrgencyColor = seeDoctorColor;
  
  // Animation durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 500);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  
  // Disclaimer text
  static const String disclaimerText = 
      'The information provided by Medicare+ is not intended to be a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of your physician or other qualified health provider with any questions you may have regarding a medical condition.';
      
  // Medical disclaimer (alias for compatibility)
  static const String medicalDisclaimer = disclaimerText;
}