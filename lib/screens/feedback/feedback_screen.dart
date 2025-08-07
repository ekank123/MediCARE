import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:medicare_plus/constants/app_constants.dart';
import 'package:medicare_plus/models/feedback_model.dart';
import 'package:medicare_plus/services/auth_service.dart';
import 'package:medicare_plus/services/feedback_service.dart';
import 'package:medicare_plus/utils/connectivity_service.dart';
import 'package:medicare_plus/utils/theme_provider.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feedbackService = FeedbackService();
  final _authService = AuthService();
  
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  
  int _rating = 0;
  String _feedbackType = 'General';
  bool _isSubmitting = false;
  String? _errorMessage;
  
  final List<String> _feedbackTypes = [
    'General',
    'Bug Report',
    'Feature Request',
    'Scan Accuracy',
    'User Interface',
    'Other'
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_rating == 0) {
      setState(() {
        _errorMessage = 'Please provide a rating';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
      final isConnected = await connectivityService.checkConnectivity();
      
      if (!isConnected) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'No internet connection. Please check your connection and try again.';
        });
        return;
      }

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'You must be logged in to submit feedback';
        });
        return;
      }

      final feedback = FeedbackModel(
        userId: currentUser.uid,
        userName: currentUser.displayName ?? 'Anonymous',
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        rating: _rating,
        type: _feedbackType,
        timestamp: DateTime.now(),
        status: 'Pending',
      );

      await _feedbackService.submitFeedback(feedback);

      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thank you for your feedback!')),
        );

        // Reset form
        _subjectController.clear();
        _messageController.clear();
        setState(() {
          _rating = 0;
          _feedbackType = 'General';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to submit feedback: $e';
        });
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
        title: const Text('Send Feedback'),
        elevation: 0,
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
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Introduction
                  Text(
                    'We value your feedback!',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your feedback helps us improve Medicare+ and provide better healthcare services.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),

                  // Rating
                  Text(
                    'How would you rate your experience?',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                      (index) => IconButton(
                        icon: Icon(
                          index < _rating ? Icons.star : Icons.star_border,
                          color: index < _rating ? Colors.amber : Colors.grey,
                          size: 36,
                        ),
                        onPressed: () {
                          setState(() {
                            _rating = index + 1;
                            _errorMessage = null;
                          });
                        },
                      ),
                    ),
                  ),
                  if (_errorMessage != null && _rating == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Feedback Type
                  Text(
                    'Feedback Type',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _feedbackType,
                        isExpanded: true,
                        icon: const Icon(Icons.arrow_drop_down),
                        items: _feedbackTypes.map((String type) {
                          return DropdownMenuItem<String>(
                            value: type,
                            child: Text(type),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _feedbackType = newValue;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Subject
                  Text(
                    'Subject',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _subjectController,
                    decoration: InputDecoration(
                      hintText: 'Enter a subject',
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a subject';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Message
                  Text(
                    'Message',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Enter your feedback',
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                        ),
                      ),
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your feedback';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitFeedback,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Submit Feedback'),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // View History Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/feedback_history');
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                        ),
                      ),
                      child: const Text('View Feedback History'),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error Message
                  if (_errorMessage != null && _rating > 0)
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

                  // Privacy Note
                  Container(
                    padding: const EdgeInsets.all(AppConstants.smallPadding),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.privacy_tip_outlined,
                          color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your feedback may be used to improve our services. Personal information will be handled according to our Privacy Policy.',
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
        },
      ),
    );
  }
}