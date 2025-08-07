import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medicare_plus/constants/app_constants.dart';
import 'package:medicare_plus/models/scan_model.dart';
import 'package:medicare_plus/services/scan_service.dart';
import 'package:medicare_plus/utils/theme_provider.dart';
import 'package:medicare_plus/screens/reminders/add_reminder_screen.dart';
import 'package:medicare_plus/screens/specialists/specialist_map_screen.dart';

class ScanResultScreen extends StatefulWidget {
  final ScanModel? scan;

  const ScanResultScreen({super.key, required this.scan});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  final ScanService _scanService = ScanService();
  final _notesController = TextEditingController();
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.scan != null) {
      _notesController.text = widget.scan!.userNotes ?? '';
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _saveNotes() async {
    if (widget.scan == null) return;
    
    setState(() {
      _isSaving = true;
    });

    try {
      await _scanService.updateScanNotes(
        widget.scan!.id,
        _notesController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notes saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save notes: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.scan?.regionType == ScanRegionType.skin ? 'Skin Analysis' : 'Eye Analysis',
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // TODO: Implement share functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Share functionality not implemented yet')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image and timestamp
              if (widget.scan?.imageUrl != null) ...[                
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  child: Image.network(
                    widget.scan!.imageUrl!,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: double.infinity,
                        height: 250,
                        color: Colors.grey[300],
                        child: const Center(
                          child: Icon(Icons.broken_image, size: 50),
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        width: double.infinity,
                        height: 250,
                        color: Colors.grey[300],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Timestamp
              if (widget.scan != null) Text(
                dateFormat.format(widget.scan!.timestamp),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 24),

              // Diagnostic results section
              Text(
                'Diagnostic Results',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              // Results list
              if (widget.scan == null)
                const Text('No scan data available'),
              if (widget.scan != null && widget.scan!.diagnosticResults.isEmpty)
                const Text('No diagnostic results available'),
              if (widget.scan != null)
                ...widget.scan!.diagnosticResults.map((result) {
                final Color urgencyColor = _getUrgencyColor(result.urgencyLevel);
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
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                result.condition,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: urgencyColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                _getUrgencyText(result.urgencyLevel),
                                style: TextStyle(
                                  color: urgencyColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: result.confidenceScore / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getConfidenceColor(result.confidenceScore),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Confidence: ${result.confidenceScore.toStringAsFixed(1)}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 24),

              // Suggested remedies section
              Text(
                'Suggested Remedies',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),

              if (widget.scan == null)
                const Text('No scan data available'),
              if (widget.scan != null && widget.scan!.suggestedRemedies?.isEmpty == true)
                const Text('No remedies available'),
              if (widget.scan != null && widget.scan!.suggestedRemedies?.isNotEmpty == true)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...(widget.scan!.suggestedRemedies?.map((remedy) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 20,
                                color: AppConstants.successColor,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(remedy),
                              ),
                            ],
                          ),
                        );
                      }).toList() ?? []),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              Text(
                'Next Steps',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      icon: Icons.notifications_active_outlined,
                      label: 'Set Reminder',
                      color: Colors.orange,
                      onTap: () {
                        if (widget.scan != null) {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddReminderScreen(scanId: widget.scan!.id),
                            ),
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      icon: Icons.shopping_cart_outlined,
                      label: 'Buy Medicine',
                      color: AppConstants.primaryColor,
                      onTap: () {
                        // TODO: Implement medicine purchase
                        // For now, just open a pharmacy website
                        _launchUrl('https://www.netmeds.com');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      icon: Icons.map_outlined,
                      label: 'Find Specialist',
                      color: Colors.green,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SpecialistMapScreen(
                              initialSpecialistType: widget.scan?.regionType == ScanRegionType.skin
                                  ? 'dermatologist'
                                  : 'ophthalmologist',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildActionButton(
                      context: context,
                      icon: Icons.info_outline,
                      label: 'Learn More',
                      color: Colors.blue,
                      onTap: () {
                        // Open relevant health information website
                        if (widget.scan?.regionType == ScanRegionType.skin) {
                          _launchUrl('https://www.aad.org/public/diseases');
                        } else {
                          _launchUrl('https://www.aao.org/eye-health');
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Notes section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Your Notes',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  if (!_isEditing)
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        setState(() {
                          _isEditing = true;
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isEditing) ...[                
                TextField(
                  controller: _notesController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    hintText: 'Add your notes here...',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isSaving
                          ? null
                          : () {
                              setState(() {
                                _isEditing = false;
                                _notesController.text = widget.scan?.userNotes ?? '';
                              });
                            },
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _saveNotes,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ],
                ),
              ] else ...[                
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                    border: Border.all(
                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                    ),
                  ),
                  child: Text(
                    widget.scan?.userNotes?.isNotEmpty == true
                        ? widget.scan!.userNotes!
                        : 'No notes added yet. Tap the edit button to add your notes.',
                    style: TextStyle(
                      color: widget.scan?.userNotes?.isNotEmpty == true
                          ? null
                          : Colors.grey[500],
                      fontStyle: widget.scan?.userNotes?.isNotEmpty == true
                          ? FontStyle.normal
                          : FontStyle.italic,
                    ),
                  ),
                ),
              ],
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
                        AppConstants.medicalDisclaimer,
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

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getUrgencyColor(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.mild:
        return AppConstants.mildUrgencyColor;
      case UrgencyLevel.needsMonitoring:
        return AppConstants.moderateUrgencyColor;
      case UrgencyLevel.seeDoctor:
        return AppConstants.severeUrgencyColor;
      default:
        return Colors.grey;
    }
  }

  String _getUrgencyText(UrgencyLevel level) {
    switch (level) {
      case UrgencyLevel.mild:
        return 'Mild';
      case UrgencyLevel.needsMonitoring:
        return 'Needs Monitoring';
      case UrgencyLevel.seeDoctor:
        return 'See a Doctor';
      default:
        return 'Unknown';
    }
  }

  Color _getConfidenceColor(double score) {
    if (score >= 80) {
      return AppConstants.successColor;
    } else if (score >= 50) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
}