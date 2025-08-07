import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:medicare_plus/constants/app_constants.dart';
import 'package:medicare_plus/models/reminder_model.dart';
import 'package:medicare_plus/services/reminder_service.dart';
import 'package:medicare_plus/utils/connectivity_service.dart';
import 'package:medicare_plus/utils/theme_provider.dart';
import 'package:medicare_plus/screens/reminders/add_reminder_screen.dart';

class RemindersListScreen extends StatefulWidget {
  const RemindersListScreen({super.key});

  @override
  State<RemindersListScreen> createState() => _RemindersListScreenState();
}

class _RemindersListScreenState extends State<RemindersListScreen> with SingleTickerProviderStateMixin {
  final ReminderService _reminderService = ReminderService();
  late TabController _tabController;
  bool _isLoading = true;
  List<ReminderModel> _allReminders = [];
  List<ReminderModel> _todayReminders = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReminders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReminders() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
      final isConnected = await connectivityService.checkConnectivity();
      
      if (!isConnected) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'No internet connection. Please check your connection and try again.';
          });
        }
        return;
      }

      final allReminders = await _reminderService.getAllReminders();
      final todayReminders = await _reminderService.getTodayReminders();
      
      if (mounted) {
        setState(() {
          _allReminders = allReminders;
          _todayReminders = todayReminders;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load reminders: $e';
        });
      }
    }
  }

  Future<void> _toggleReminderStatus(ReminderModel reminder) async {
    try {
      await _reminderService.toggleReminderStatus(reminder.id!, !reminder.isActive);
      
      if (mounted) {
        setState(() {
          // Update the reminder in both lists
          final updatedReminder = reminder.copyWith(isActive: !reminder.isActive);
          
          final allIndex = _allReminders.indexWhere((r) => r.id == reminder.id);
          if (allIndex != -1) {
            _allReminders[allIndex] = updatedReminder;
          }
          
          final todayIndex = _todayReminders.indexWhere((r) => r.id == reminder.id);
          if (todayIndex != -1) {
            _todayReminders[todayIndex] = updatedReminder;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update reminder status: $e')),
        );
      }
    }
  }

  Future<void> _deleteReminder(ReminderModel reminder) async {
    try {
      await _reminderService.deleteReminder(reminder.id!);
      
      if (mounted) {
        setState(() {
          _allReminders.removeWhere((r) => r.id == reminder.id);
          _todayReminders.removeWhere((r) => r.id == reminder.id);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reminder deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete reminder: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final connectivityService = Provider.of<ConnectivityService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Reminders'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'All Reminders'),
          ],
        ),
      ),
      body: StreamBuilder<bool>(
        stream: connectivityService.connectionStream,
        builder: (context, snapshot) {
          final isConnected = snapshot.data ?? true;
          
          if (!isConnected) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.wifi_off,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No internet connection',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your connection and try again',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadReminders,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red[300],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _loadReminders,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildReminderList(_todayReminders),
              _buildReminderList(_allReminders),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddReminderScreen(),
            ),
          );
          _loadReminders(); // Refresh the list after returning
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildReminderList(List<ReminderModel> reminders) {
    if (reminders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No reminders found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add a reminder to get started',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddReminderScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Reminder'),
            ),
          ],
        ),
      );
    }

    // Sort reminders by next occurrence time
    final sortedReminders = List<ReminderModel>.from(reminders);
    sortedReminders.sort((a, b) {
      // First sort by active status (active first)
      if (a.isActive != b.isActive) {
        return a.isActive ? -1 : 1;
      }
      
      // Then sort by start date
      return a.startDate.compareTo(b.startDate);
    });

    return RefreshIndicator(
      onRefresh: _loadReminders,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: sortedReminders.length,
        itemBuilder: (context, index) {
          final reminder = sortedReminders[index];
          final dateFormat = DateFormat('MMM d, yyyy');
          final startDate = dateFormat.format(reminder.startDate);
          final endDate = dateFormat.format(reminder.endDate);
          
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddReminderScreen(reminderToEdit: reminder),
                  ),
                ).then((_) => _loadReminders());
              },
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            reminder.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  decoration: reminder.isActive ? null : TextDecoration.lineThrough,
                                ),
                          ),
                        ),
                        Switch(
                          value: reminder.isActive,
                          onChanged: (value) => _toggleReminderStatus(reminder),
                        ),
                      ],
                    ),
                    if (reminder.description?.isNotEmpty == true) ...[                      
                      const SizedBox(height: 8),
                      Text(
                        reminder.description!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          decoration: reminder.isActive ? null : TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          '$startDate - $endDate',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reminder.times.map((time) => '${time.hour}:${time.minute.toString().padLeft(2, '0')}').join(', '),
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.repeat, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          _getDaysText(reminder.daysOfWeek),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Reminder'),
                                content: const Text(
                                  'Are you sure you want to delete this reminder? This action cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _deleteReminder(reminder);
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: Colors.red,
                                    ),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => AddReminderScreen(reminderToEdit: reminder),
                              ),
                            ).then((_) => _loadReminders());
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _getDaysText(List<bool> daysOfWeek) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final selectedDays = <String>[];
    
    for (int i = 0; i < daysOfWeek.length; i++) {
      if (daysOfWeek[i]) {
        selectedDays.add(days[i]);
      }
    }
    
    if (selectedDays.length == 7) {
      return 'Every day';
    } else if (selectedDays.length == 0) {
      return 'No days selected';
    } else if (selectedDays.length == 5 && 
               daysOfWeek[0] && daysOfWeek[1] && daysOfWeek[2] && 
               daysOfWeek[3] && daysOfWeek[4]) {
      return 'Weekdays';
    } else if (selectedDays.length == 2 && daysOfWeek[5] && daysOfWeek[6]) {
      return 'Weekends';
    } else {
      return selectedDays.join(', ');
    }
  }
}