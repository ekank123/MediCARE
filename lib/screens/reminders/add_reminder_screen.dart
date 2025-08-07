import 'dart:io';
import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:flutter/material.dart' as flutter;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:medicare_plus/constants/app_constants.dart';
import 'package:medicare_plus/models/reminder_model.dart';
import 'package:medicare_plus/services/reminder_service.dart';
import 'package:medicare_plus/services/scan_service.dart';
import 'package:medicare_plus/utils/connectivity_service.dart';
import 'package:provider/provider.dart';

class AddReminderScreen extends StatefulWidget {
  final String? scanId;
  final ReminderModel? reminderToEdit;

  const AddReminderScreen({super.key, this.scanId, this.reminderToEdit});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _reminderService = ReminderService();
  final _scanService = ScanService();
  final _imagePicker = ImagePicker();

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  List<TimeOfDay> _times = [const TimeOfDay(hour: 8, minute: 0)];
  List<bool> _daysOfWeek = List.filled(7, true); // Days of week selection
  bool _isActive = true;
  bool _isLoading = false;
  bool _isUploading = false;
  File? _medicineImage;
  String? _medicineImageUrl;
  String? _scanId;

  @override
  void initState() {
    super.initState();
    _scanId = widget.scanId;
    
    if (widget.reminderToEdit != null) {
      _populateFormWithExistingReminder();
    }
  }

  void _populateFormWithExistingReminder() {
    final reminder = widget.reminderToEdit!;
    _titleController.text = reminder.title;
    _descriptionController.text = reminder.description ?? '';
    _startDate = reminder.startDate;
    _endDate = reminder.endDate ?? DateTime.now().add(const Duration(days: 7));
    _times = reminder.times;
    
    // Use daysOfWeek directly as it's now a List<bool>
    _daysOfWeek = reminder.daysOfWeek;
    
    _isActive = reminder.isActive;
    _medicineImageUrl = reminder.medicineImageUrl;
    _scanId = reminder.scanId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _medicineImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _saveReminder() async {
    if (!_formKey.currentState!.validate()) return;

    final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    final isConnected = await connectivityService.checkConnectivity();
    
    if (!isConnected) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet connection. Please check your connection and try again.')),
        );
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload medicine image if selected
      if (_medicineImage != null) {
        setState(() {
          _isUploading = true;
        });

        _medicineImageUrl = await _scanService.uploadImageToStorage(
          _medicineImage!.path,
          'medicine_images',
        );

        setState(() {
          _isUploading = false;
        });
      }

      final reminder = ReminderModel(
        id: widget.reminderToEdit?.id ?? '',
        userId: '',  // Will be set by the service
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        startDate: _startDate,
        endDate: _endDate,
        times: _times,
        daysOfWeek: _daysOfWeek,
        isActive: _isActive,
        medicineImageUrl: _medicineImageUrl,
        scanId: _scanId,
      );

      if (widget.reminderToEdit != null) {
        await _reminderService.updateReminder(reminder);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder updated successfully')),
          );
        }
      } else {
        await _reminderService.createReminder(reminder);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder created successfully')),
          );
        }
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save reminder: $e')),
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

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: isStartDate ? DateTime.now() : _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Ensure end date is not before start date
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _addTime() async {
    final materialTimeOfDay = await showTimePicker(
      context: context,
      initialTime: const flutter.TimeOfDay(hour: 12, minute: 0),
    );

    if (materialTimeOfDay != null) {
      setState(() {
        _times.add(TimeOfDay(hour: materialTimeOfDay.hour, minute: materialTimeOfDay.minute));
      });
    }
  }

  void _removeTime(int index) {
    setState(() {
      _times.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reminderToEdit != null ? 'Edit Reminder' : 'Add Reminder'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            children: [
              // Title
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Medicine Name *',
                  hintText: 'Enter the name of the medicine',
                  prefixIcon: Icon(Icons.medication),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a medicine name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter dosage, instructions, etc.',
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Date Range
              Text(
                'Date Range',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Start Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('MMM d, yyyy').format(_startDate),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'End Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('MMM d, yyyy').format(_endDate),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Reminder Times
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Reminder Times',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  TextButton.icon(
                    onPressed: _addTime,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Time'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_times.isEmpty)
                const Text('No times added. Tap "Add Time" to add reminder times.'),
              ..._times.asMap().entries.map((entry) {
                final index = entry.key;
                final time = entry.value;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time),
                      const SizedBox(width: 12),
                      Text(
                        time.format(context),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _removeTime(index),
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),

              // Days of Week
              Text(
                'Repeat on Days',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDayToggle(0, 'M'),
                  _buildDayToggle(1, 'T'),
                  _buildDayToggle(2, 'W'),
                  _buildDayToggle(3, 'T'),
                  _buildDayToggle(4, 'F'),
                  _buildDayToggle(5, 'S'),
                  _buildDayToggle(6, 'S'),
                ],
              ),
              const SizedBox(height: 24),

              // Medicine Image
              Text(
                'Medicine Image (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _isUploading
                      ? const Center(child: CircularProgressIndicator())
                      : _medicineImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                              child: Image.file(
                                _medicineImage!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            )
                          : _medicineImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                                  child: Image.network(
                                    _medicineImageUrl!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Center(
                                        child: Icon(
                                          Icons.broken_image,
                                          size: 50,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      Icon(
                                        Icons.add_photo_alternate,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text('Tap to add medicine image'),
                                    ],
                                  ),
                                ),
                ),
              ),
              const SizedBox(height: 24),

              // Active Status
              SwitchListTile(
                title: const Text('Reminder Active'),
                subtitle: const Text('Turn off to temporarily disable this reminder'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
              const SizedBox(height: 32),

              // Save Button
              ElevatedButton(
                onPressed: _isLoading ? null : _saveReminder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        widget.reminderToEdit != null ? 'Update Reminder' : 'Create Reminder',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayToggle(int dayIndex, String label) {
    return InkWell(
      onTap: () {
        setState(() {
          _daysOfWeek[dayIndex] = !_daysOfWeek[dayIndex];
        });
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _daysOfWeek[dayIndex]
              ? AppConstants.primaryColor
              : Colors.grey[300],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: _daysOfWeek[dayIndex] ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}