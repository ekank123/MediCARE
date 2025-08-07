import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:medicare_plus/constants/app_constants.dart';
import 'package:medicare_plus/models/scan_model.dart';
import 'package:medicare_plus/services/scan_service.dart';
import 'package:medicare_plus/utils/connectivity_service.dart';
import 'package:medicare_plus/utils/theme_provider.dart';
import 'package:medicare_plus/screens/scan/scan_result_screen.dart';

class ScanHistoryScreen extends StatefulWidget {
  const ScanHistoryScreen({super.key});

  @override
  State<ScanHistoryScreen> createState() => _ScanHistoryScreenState();
}

class _ScanHistoryScreenState extends State<ScanHistoryScreen> with SingleTickerProviderStateMixin {
  final ScanService _scanService = ScanService();
  late TabController _tabController;
  bool _isLoading = true;
  List<ScanModel> _allScans = [];
  List<ScanModel> _skinScans = [];
  List<ScanModel> _eyeScans = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadScans();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadScans() async {
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

      final scans = await _scanService.getUserScans();
      
      if (mounted) {
        setState(() {
          _allScans = scans;
          _skinScans = scans.where((scan) => scan.regionType == ScanRegionType.skin).toList();
          _eyeScans = scans.where((scan) => scan.regionType == ScanRegionType.eye).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load scans: $e';
        });
      }
    }
  }

  Future<void> _deleteScan(ScanModel scan) async {
    try {
      await _scanService.deleteScan(scan.id);
      if (mounted) {
        setState(() {
          _allScans.removeWhere((s) => s.id == scan.id);
          _skinScans.removeWhere((s) => s.id == scan.id);
          _eyeScans.removeWhere((s) => s.id == scan.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Scan deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete scan: $e')),
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
        title: const Text('Scan History'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Skin'),
            Tab(text: 'Eye'),
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
                    onPressed: _loadScans,
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
                    onPressed: _loadScans,
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
              _buildScanList(_allScans),
              _buildScanList(_skinScans),
              _buildScanList(_eyeScans),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, AppConstants.scanOptionsRoute);
        },
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }

  Widget _buildScanList(List<ScanModel> scans) {
    if (scans.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No scans found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Your scan history will appear here',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppConstants.scanOptionsRoute);
              },
              icon: const Icon(Icons.add_a_photo),
              label: const Text('New Scan'),
            ),
          ],
        ),
      );
    }

    // Sort scans by timestamp (newest first)
    final sortedScans = List<ScanModel>.from(scans)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return RefreshIndicator(
      onRefresh: _loadScans,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        itemCount: sortedScans.length,
        itemBuilder: (context, index) {
          final scan = sortedScans[index];
          final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
          final formattedDate = dateFormat.format(scan.timestamp);
          
          // Get the most severe urgency level
          UrgencyLevel? highestUrgency;
          if (scan.diagnosticResults.isNotEmpty) {
            highestUrgency = scan.diagnosticResults
                .map((result) => result.urgencyLevel)
                .reduce((a, b) => a.index > b.index ? a : b);
          }

          // Get the condition with highest confidence
          String? topCondition;
          if (scan.diagnosticResults.isNotEmpty) {
            topCondition = scan.diagnosticResults
                .reduce((a, b) => a.confidenceScore > b.confidenceScore ? a : b)
                .condition;
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
            ),
            child: InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ScanResultScreen(scan: scan),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (scan.imageUrl != null) ...[                    
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppConstants.defaultBorderRadius),
                        topRight: Radius.circular(AppConstants.defaultBorderRadius),
                      ),
                      child: Image.network(
                        scan.imageUrl!,
                        width: double.infinity,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: double.infinity,
                            height: 150,
                            color: Colors.grey[300],
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 40),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  scan.regionType == ScanRegionType.skin
                                      ? Icons.face
                                      : Icons.remove_red_eye,
                                  size: 20,
                                  color: scan.regionType == ScanRegionType.skin
                                      ? Colors.orange
                                      : Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  scan.regionType == ScanRegionType.skin
                                      ? 'Skin Scan'
                                      : 'Eye Scan',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            if (highestUrgency != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _getUrgencyColor(highestUrgency).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  _getUrgencyText(highestUrgency),
                                  style: TextStyle(
                                    color: _getUrgencyColor(highestUrgency),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (topCondition != null) ...[                          
                          Text(
                            topCondition,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text(
                          formattedDate,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        if (scan.userNotes?.isNotEmpty == true) ...[                          
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.note,
                                size: 16,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  scan.userNotes!,
                                  style: Theme.of(context).textTheme.bodySmall,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Scan'),
                                content: const Text(
                                  'Are you sure you want to delete this scan? This action cannot be undone.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _deleteScan(scan);
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
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ScanResultScreen(scan: scan),
                              ),
                            );
                          },
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
}