import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:medicare_plus/models/reminder_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medicare_plus/constants/app_constants.dart';

class ReminderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // Initialize notifications
  Future<void> initNotifications() async {
    // Request permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
      
      // Get FCM token
      String? token = await _messaging.getToken();
      print('FCM Token: $token');
      
      // Handle token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        // Update token in Firestore
        // This would typically update the user's document with the new token
      });
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');

        if (message.notification != null) {
          print('Message also contained a notification: ${message.notification}');
        }
      });
    } else {
      print('User declined or has not accepted permission');
    }
  }

  // Create a new reminder
  Future<ReminderModel> createReminder(ReminderModel reminder) async {
    try {
      final docRef = _firestore.collection('reminders').doc();
      final reminderWithId = ReminderModel(
        id: docRef.id,
        userId: reminder.userId,
        title: reminder.title,
        description: reminder.description,
        startDate: reminder.startDate,
        endDate: reminder.endDate,
        times: reminder.times,
        daysOfWeek: reminder.daysOfWeek,
        isActive: reminder.isActive,
        medicineImageUrl: reminder.medicineImageUrl,
        scanId: reminder.scanId,
      );

      await docRef.set(reminderWithId.toMap());
      return reminderWithId;
    } catch (e) {
      throw Exception('Failed to create reminder: $e');
    }
  }

  // Get all reminders for a user
  Stream<List<ReminderModel>> getUserReminders(String userId) {
    return _firestore
        .collection('reminders')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ReminderModel.fromMap(doc.data()))
              .toList();
        });
  }

  // Update a reminder
  Future<void> updateReminder(ReminderModel reminder) async {
    try {
      await _firestore
          .collection('reminders')
          .doc(reminder.id)
          .update(reminder.toMap());
    } catch (e) {
      throw Exception('Failed to update reminder: $e');
    }
  }

  // Delete a reminder
  Future<void> deleteReminder(String reminderId) async {
    try {
      await _firestore.collection('reminders').doc(reminderId).delete();
    } catch (e) {
      throw Exception('Failed to delete reminder: $e');
    }
  }

  // Toggle reminder active status
  Future<void> toggleReminderStatus(String reminderId, bool isActive) async {
    try {
      await _firestore
          .collection('reminders')
          .doc(reminderId)
          .update({'isActive': isActive});
    } catch (e) {
      throw Exception('Failed to toggle reminder status: $e');
    }
  }
  
  // Update notification settings
  Future<void> updateNotificationSettings({
    required bool enableNotifications,
    required bool enableMedicationReminders,
    required bool enableSound,
    required bool enableVibration,
  }) async {
    try {
      // Save settings to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefEnableAllNotifications, enableNotifications);
      await prefs.setBool(AppConstants.prefEnableMedicationReminders, enableMedicationReminders);
      await prefs.setBool(AppConstants.prefEnableSound, enableSound);
      await prefs.setBool(AppConstants.prefEnableVibration, enableVibration);
      
      // If notifications are disabled, we would handle canceling scheduled notifications here
      // This would be implemented with a local notifications plugin in a real app
      
      // For now, we'll just log the settings change
      print('Notification settings updated: enableNotifications=$enableNotifications, '
          'enableMedicationReminders=$enableMedicationReminders, '
          'enableSound=$enableSound, enableVibration=$enableVibration');
    } catch (e) {
      throw Exception('Failed to update notification settings: $e');
    }
  }

  // Get all reminders for a user (non-stream version)
  Future<List<ReminderModel>> getAllReminders() async {
    try {
      final snapshot = await _firestore
          .collection('reminders')
          .get();
      
      return snapshot.docs
          .map((doc) => ReminderModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get all reminders: $e');
    }
  }
  
  // Get reminders for today
  Future<List<ReminderModel>> getTodayReminders() async {
    try {
      final now = DateTime.now();
      final today = now.weekday - 1; // 0-6 (Monday-Sunday)

      final snapshot = await _firestore
          .collection('reminders')
          .where('isActive', isEqualTo: true)
          .get();
      
      // Filter reminders that are scheduled for today
      final reminders = snapshot.docs
          .map((doc) => ReminderModel.fromMap(doc.data()))
          .where((reminder) {
            // Check if today is in the daysOfWeek list
            return reminder.daysOfWeek[today];
          })
          .toList();
      
      return reminders;
    } catch (e) {
      throw Exception('Failed to get today\'s reminders: $e');
    }
  }
}