import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:medicare_plus/constants/app_constants.dart';
import 'package:medicare_plus/services/reminder_service.dart';
import 'package:medicare_plus/utils/theme_provider.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final ReminderService _reminderService = ReminderService();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  
  // Notification settings
  bool _enableAllNotifications = true;
  bool _enableMedicationReminders = true;
  bool _enableScanResults = true;
  bool _enableAppUpdates = true;
  bool _enablePromotions = false;
  
  // Sound and vibration
  bool _enableSound = true;
  bool _enableVibration = true;
  
  // Reminder settings
  int _reminderLeadTime = 15; // minutes
  bool _enableSnooze = true;
  int _snoozeTime = 5; // minutes
  
  final List<int> _reminderLeadTimeOptions = [5, 10, 15, 30, 60];
  final List<int> _snoozeTimeOptions = [5, 10, 15, 30];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      setState(() {
        _enableAllNotifications = prefs.getBool(AppConstants.prefEnableAllNotifications) ?? true;
        _enableMedicationReminders = prefs.getBool(AppConstants.prefEnableMedicationReminders) ?? true;
        _enableScanResults = prefs.getBool(AppConstants.prefEnableScanResults) ?? true;
        _enableAppUpdates = prefs.getBool(AppConstants.prefEnableAppUpdates) ?? true;
        _enablePromotions = prefs.getBool(AppConstants.prefEnablePromotions) ?? false;
        
        _enableSound = prefs.getBool(AppConstants.prefEnableSound) ?? true;
        _enableVibration = prefs.getBool(AppConstants.prefEnableVibration) ?? true;
        
        _reminderLeadTime = prefs.getInt(AppConstants.prefReminderLeadTime) ?? 15;
        _enableSnooze = prefs.getBool(AppConstants.prefEnableSnooze) ?? true;
        _snoozeTime = prefs.getInt(AppConstants.prefSnoozeTime) ?? 5;
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load notification settings: $e';
      });
    }
  }

  Future<void> _saveSettings() async {
    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Save notification settings
      await prefs.setBool(AppConstants.prefEnableAllNotifications, _enableAllNotifications);
      await prefs.setBool(AppConstants.prefEnableMedicationReminders, _enableMedicationReminders);
      await prefs.setBool(AppConstants.prefEnableScanResults, _enableScanResults);
      await prefs.setBool(AppConstants.prefEnableAppUpdates, _enableAppUpdates);
      await prefs.setBool(AppConstants.prefEnablePromotions, _enablePromotions);
      
      // Save sound and vibration settings
      await prefs.setBool(AppConstants.prefEnableSound, _enableSound);
      await prefs.setBool(AppConstants.prefEnableVibration, _enableVibration);
      
      // Save reminder settings
      await prefs.setInt(AppConstants.prefReminderLeadTime, _reminderLeadTime);
      await prefs.setBool(AppConstants.prefEnableSnooze, _enableSnooze);
      await prefs.setInt(AppConstants.prefSnoozeTime, _snoozeTime);
      
      // Update notification settings in the reminder service
      await _reminderService.updateNotificationSettings(
        enableNotifications: _enableAllNotifications,
        enableMedicationReminders: _enableMedicationReminders,
        enableSound: _enableSound,
        enableVibration: _enableVibration,
      );

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification settings saved')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _errorMessage = 'Failed to save notification settings: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notification Settings'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // General notification settings
                  Text(
                    'Notification Preferences',
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
                        SwitchListTile(
                          title: const Text('Enable All Notifications'),
                          subtitle: const Text('Master control for all notifications'),
                          value: _enableAllNotifications,
                          onChanged: (value) {
                            setState(() {
                              _enableAllNotifications = value;
                              if (!value) {
                                // If master switch is turned off, disable all notifications
                                _enableMedicationReminders = false;
                                _enableScanResults = false;
                                _enableAppUpdates = false;
                                _enablePromotions = false;
                              }
                            });
                          },
                        ),
                        const Divider(),
                        SwitchListTile(
                          title: const Text('Medication Reminders'),
                          subtitle: const Text('Notifications for your medicine schedule'),
                          value: _enableMedicationReminders && _enableAllNotifications,
                          onChanged: _enableAllNotifications
                              ? (value) {
                                  setState(() {
                                    _enableMedicationReminders = value;
                                  });
                                }
                              : null,
                        ),
                        const Divider(),
                        SwitchListTile(
                          title: const Text('Scan Results'),
                          subtitle: const Text('Notifications when scan analysis is complete'),
                          value: _enableScanResults && _enableAllNotifications,
                          onChanged: _enableAllNotifications
                              ? (value) {
                                  setState(() {
                                    _enableScanResults = value;
                                  });
                                }
                              : null,
                        ),
                        const Divider(),
                        SwitchListTile(
                          title: const Text('App Updates'),
                          subtitle: const Text('Notifications about new features and updates'),
                          value: _enableAppUpdates && _enableAllNotifications,
                          onChanged: _enableAllNotifications
                              ? (value) {
                                  setState(() {
                                    _enableAppUpdates = value;
                                  });
                                }
                              : null,
                        ),
                        const Divider(),
                        SwitchListTile(
                          title: const Text('Promotions and Tips'),
                          subtitle: const Text('Health tips and promotional content'),
                          value: _enablePromotions && _enableAllNotifications,
                          onChanged: _enableAllNotifications
                              ? (value) {
                                  setState(() {
                                    _enablePromotions = value;
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Sound and vibration settings
                  Text(
                    'Sound & Vibration',
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
                        SwitchListTile(
                          title: const Text('Sound'),
                          subtitle: const Text('Play sound with notifications'),
                          value: _enableSound && _enableAllNotifications,
                          onChanged: _enableAllNotifications
                              ? (value) {
                                  setState(() {
                                    _enableSound = value;
                                  });
                                }
                              : null,
                        ),
                        const Divider(),
                        SwitchListTile(
                          title: const Text('Vibration'),
                          subtitle: const Text('Vibrate with notifications'),
                          value: _enableVibration && _enableAllNotifications,
                          onChanged: _enableAllNotifications
                              ? (value) {
                                  setState(() {
                                    _enableVibration = value;
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Reminder settings
                  Text(
                    'Reminder Settings',
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
                          title: const Text('Reminder Lead Time'),
                          subtitle: Text('Notify $_reminderLeadTime minutes before scheduled time'),
                          enabled: _enableAllNotifications && _enableMedicationReminders,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: _reminderLeadTimeOptions.map((time) {
                              return Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 4),
                                  child: ChoiceChip(
                                    label: Text('$time min'),
                                    selected: _reminderLeadTime == time,
                                    onSelected: _enableAllNotifications && _enableMedicationReminders
                                        ? (selected) {
                                            if (selected) {
                                              setState(() {
                                                _reminderLeadTime = time;
                                              });
                                            }
                                          }
                                        : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        SwitchListTile(
                          title: const Text('Enable Snooze'),
                          subtitle: const Text('Allow snoozing reminders'),
                          value: _enableSnooze && _enableAllNotifications && _enableMedicationReminders,
                          onChanged: _enableAllNotifications && _enableMedicationReminders
                              ? (value) {
                                  setState(() {
                                    _enableSnooze = value;
                                  });
                                }
                              : null,
                        ),
                        if (_enableSnooze && _enableAllNotifications && _enableMedicationReminders) ...[                          
                          ListTile(
                            title: const Text('Snooze Duration'),
                            subtitle: Text('Snooze for $_snoozeTime minutes'),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: _snoozeTimeOptions.map((time) {
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: ChoiceChip(
                                      label: Text('$time min'),
                                      selected: _snoozeTime == time,
                                      onSelected: (selected) {
                                        if (selected) {
                                          setState(() {
                                            _snoozeTime = time;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveSettings,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save Settings'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Error Message
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(AppConstants.smallPadding),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Theme.of(context).colorScheme.error),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Note about permissions
                  Container(
                    padding: const EdgeInsets.all(AppConstants.smallPadding),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Make sure to allow notifications for Medicare+ in your device settings for these preferences to take effect.',
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
    );
  }
}