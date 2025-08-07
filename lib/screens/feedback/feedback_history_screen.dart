import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:medicare_plus/constants/app_constants.dart';
import 'package:medicare_plus/models/feedback_model.dart';
import 'package:medicare_plus/services/auth_service.dart';
import 'package:medicare_plus/services/feedback_service.dart';
import 'package:medicare_plus/utils/connectivity_service.dart';
import 'package:medicare_plus/utils/theme_provider.dart';

class FeedbackHistoryScreen extends StatefulWidget {
  const FeedbackHistoryScreen({super.key});

  @override
  State<FeedbackHistoryScreen> createState() => _FeedbackHistoryScreenState();
}

class _FeedbackHistoryScreenState extends State<FeedbackHistoryScreen> {
  final _feedbackService = FeedbackService();
  final _authService = AuthService();
  
  bool _isLoading = true;
  String? _errorMessage;
  List<FeedbackModel> _feedbackList = [];
  StreamSubscription<List<FeedbackModel>>? _feedbackSubscription;

  @override
  void initState() {
    super.initState();
    _loadFeedbackHistory();
  }
  
  @override
  void dispose() {
    _feedbackSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadFeedbackHistory() async {
    // Cancel any existing subscription
    await _feedbackSubscription?.cancel();
    _feedbackSubscription = null;
    
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

      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'You must be logged in to view feedback history';
          });
        }
        return;
      }

      // Subscribe to the stream of feedback
      _feedbackSubscription = _feedbackService.getUserFeedback(currentUser.uid).listen((feedbackList) {
        if (mounted) {
          setState(() {
            _feedbackList = feedbackList;
            _isLoading = false;
          });
        }
      }, onError: (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = 'Failed to load feedback history: $e';
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load feedback history: $e';
        });
      }
    }
  }

  Future<void> _deleteFeedback(String feedbackId) async {
    try {
      final connectivityService = Provider.of<ConnectivityService>(context, listen: false);
      final isConnected = await connectivityService.checkConnectivity();
      
      if (!isConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet connection. Please check your connection and try again.')),
        );
        return;
      }

      await _feedbackService.deleteFeedback(feedbackId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Feedback deleted successfully')),
        );
        _loadFeedbackHistory();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete feedback: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final connectivityService = Provider.of<ConnectivityService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Feedback History'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFeedbackHistory,
            tooltip: 'Refresh',
          ),
        ],
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
                    onPressed: _loadFeedbackHistory,
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
                    onPressed: _loadFeedbackHistory,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (_feedbackList.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.feedback_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No feedback yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your submitted feedback will appear here',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Submit Feedback'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            itemCount: _feedbackList.length,
            itemBuilder: (context, index) {
              final feedback = _feedbackList[index];
              final formattedDate = DateFormat('MMM d, yyyy • h:mm a').format(feedback.timestamp!);
              
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header with type and date
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              feedback.type ?? 'General',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          Text(
                            formattedDate,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Subject
                      Text(
                        feedback.subject ?? 'No Subject',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),

                      // Rating
                      Row(
                        children: List.generate(
                          5,
                          (i) => Icon(
                            i < (feedback.rating ?? 0) ? Icons.star : Icons.star_border,
                            color: i < (feedback.rating ?? 0) ? Colors.amber : Colors.grey,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Message
                      Text(
                        feedback.message ?? 'No message provided',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),

                      // Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(feedback.status ?? 'Pending'),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Status: ${feedback.status ?? 'Pending'}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getStatusColor(feedback.status ?? 'Pending'),
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            color: Colors.red[300],
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Feedback'),
                                  content: const Text(
                                    'Are you sure you want to delete this feedback? This action cannot be undone.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        _deleteFeedback(feedback.id!);
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
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Icon(Icons.add),
        tooltip: 'Submit New Feedback',
      ),
    );
  }
}