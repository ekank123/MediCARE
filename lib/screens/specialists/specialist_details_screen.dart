import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:medicare_plus/constants/app_constants.dart';
import 'package:medicare_plus/models/specialist_model.dart';
import 'package:medicare_plus/services/specialist_service.dart';
import 'package:medicare_plus/utils/connectivity_service.dart';
import 'package:medicare_plus/utils/theme_provider.dart';

class SpecialistDetailsScreen extends StatefulWidget {
  final String specialistId;

  const SpecialistDetailsScreen({super.key, required this.specialistId});

  @override
  State<SpecialistDetailsScreen> createState() => _SpecialistDetailsScreenState();
}

class _SpecialistDetailsScreenState extends State<SpecialistDetailsScreen> {
  final SpecialistService _specialistService = SpecialistService();
  bool _isLoading = true;
  String? _errorMessage;
  SpecialistModel? _specialist;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _loadSpecialist();
  }

  Future<void> _loadSpecialist() async {
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

      final specialist = await _specialistService.getSpecialistById(widget.specialistId);
      
      if (mounted) {
        setState(() {
          _specialist = specialist;
          _isLoading = false;
          _updateMarkers();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load specialist details: $e';
        });
      }
    }
  }

  void _updateMarkers() {
    if (_specialist == null || _specialist!.location == null) return;

    final location = _specialist!.location!;
    final latLng = LatLng(location.latitude, location.longitude);
    
    setState(() {
      _markers = {
        Marker(
          markerId: MarkerId(_specialist!.id!),
          position: latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _specialist!.type == 'dermatologist'
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueViolet,
          ),
          infoWindow: InfoWindow(
            title: _specialist!.name,
            snippet: '${_specialist!.type.capitalize()} • ${_specialist!.rating} ★',
          ),
        ),
      };
    });
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _updateMapTheme();
  }

  void _updateMapTheme() {
    if (_mapController == null) return;
    
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    
    if (isDarkMode) {
      _mapController!.setMapStyle('''[
        {
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#242f3e"
            }
          ]
        },
        {
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#746855"
            }
          ]
        },
        {
          "elementType": "labels.text.stroke",
          "stylers": [
            {
              "color": "#242f3e"
            }
          ]
        },
        {
          "featureType": "administrative.locality",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#d59563"
            }
          ]
        },
        {
          "featureType": "poi",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#d59563"
            }
          ]
        },
        {
          "featureType": "poi.park",
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#263c3f"
            }
          ]
        },
        {
          "featureType": "poi.park",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#6b9a76"
            }
          ]
        },
        {
          "featureType": "road",
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#38414e"
            }
          ]
        },
        {
          "featureType": "road",
          "elementType": "geometry.stroke",
          "stylers": [
            {
              "color": "#212a37"
            }
          ]
        },
        {
          "featureType": "road",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#9ca5b3"
            }
          ]
        },
        {
          "featureType": "road.highway",
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#746855"
            }
          ]
        },
        {
          "featureType": "road.highway",
          "elementType": "geometry.stroke",
          "stylers": [
            {
              "color": "#1f2835"
            }
          ]
        },
        {
          "featureType": "road.highway",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#f3d19c"
            }
          ]
        },
        {
          "featureType": "transit",
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#2f3948"
            }
          ]
        },
        {
          "featureType": "transit.station",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#d59563"
            }
          ]
        },
        {
          "featureType": "water",
          "elementType": "geometry",
          "stylers": [
            {
              "color": "#17263c"
            }
          ]
        },
        {
          "featureType": "water",
          "elementType": "labels.text.fill",
          "stylers": [
            {
              "color": "#515c6d"
            }
          ]
        },
        {
          "featureType": "water",
          "elementType": "labels.text.stroke",
          "stylers": [
            {
              "color": "#17263c"
            }
          ]
        }
      ]''');
    } else {
      _mapController!.setMapStyle(null); // Reset to default style
    }
  }

  Future<void> _makePhoneCall() async {
    if (_specialist == null || _specialist!.phoneNumber == null) return;
    
    final Uri uri = Uri(scheme: 'tel', path: _specialist!.phoneNumber);
    if (!await launchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch ${uri.toString()}')),
        );
      }
    }
  }

  Future<void> _openMaps() async {
    if (_specialist == null || _specialist!.location == null) return;
    
    final location = _specialist!.location!;
    final url = 'https://www.google.com/maps/search/?api=1&query=${location.latitude},${location.longitude}';
    final Uri uri = Uri.parse(url);
    
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch maps')),
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
                    onPressed: _loadSpecialist,
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
                    onPressed: _loadSpecialist,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (_specialist == null) {
            return const Center(child: Text('Specialist not found'));
          }

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(_specialist!.name),
                  background: Container(
                    color: _specialist!.type == 'dermatologist'
                        ? Colors.orange[100]
                        : Colors.purple[100],
                    child: Center(
                      child: Icon(
                        _specialist!.type == 'dermatologist'
                            ? Icons.face
                            : Icons.remove_red_eye,
                        size: 80,
                        color: _specialist!.type == 'dermatologist'
                            ? Colors.orange[800]
                            : Colors.purple[800],
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Specialist type and rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _specialist!.type == 'dermatologist'
                                  ? Colors.orange[100]
                                  : Colors.purple[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _specialist!.type.capitalize(),
                              style: TextStyle(
                                color: _specialist!.type == 'dermatologist'
                                    ? Colors.orange[800]
                                    : Colors.purple[800],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Text(
                                '${_specialist!.rating}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const Icon(
                                Icons.star,
                                color: Colors.amber,
                                size: 20,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${_specialist!.reviewCount})',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Contact and action buttons
                      Row(
                        children: [
                          Expanded(
                            child: _buildActionButton(
                              context: context,
                              icon: Icons.phone,
                              label: 'Call',
                              color: Colors.green,
                              onTap: _makePhoneCall,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionButton(
                              context: context,
                              icon: Icons.directions,
                              label: 'Directions',
                              color: Colors.blue,
                              onTap: _openMaps,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildActionButton(
                              context: context,
                              icon: Icons.calendar_today,
                              label: 'Book',
                              color: AppConstants.primaryColor,
                              onTap: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Booking functionality not implemented yet'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Address
                      Text(
                        'Address',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                          border: Border.all(
                            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(_specialist!.address ?? 'Address not available'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Clinic hours
                      Text(
                        'Clinic Hours',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                          border: Border.all(
                            color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildClinicHoursRow('Monday', _specialist!.clinicHours?['monday']),
                            _buildClinicHoursRow('Tuesday', _specialist!.clinicHours?['tuesday']),
                            _buildClinicHoursRow('Wednesday', _specialist!.clinicHours?['wednesday']),
                            _buildClinicHoursRow('Thursday', _specialist!.clinicHours?['thursday']),
                            _buildClinicHoursRow('Friday', _specialist!.clinicHours?['friday']),
                            _buildClinicHoursRow('Saturday', _specialist!.clinicHours?['saturday']),
                            _buildClinicHoursRow('Sunday', _specialist!.clinicHours?['sunday']),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Map
                      Text(
                        'Location',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (_specialist!.location != null) ...[                        
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                            border: Border.all(
                              color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                            child: GoogleMap(
                              onMapCreated: _onMapCreated,
                              initialCameraPosition: CameraPosition(
                                target: LatLng(
                                  _specialist!.location!.latitude,
                                  _specialist!.location!.longitude,
                                ),
                                zoom: 15,
                              ),
                              markers: _markers,
                              zoomControlsEnabled: false,
                              mapToolbarEnabled: false,
                              myLocationButtonEnabled: false,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton.icon(
                            onPressed: _openMaps,
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open in Google Maps'),
                          ),
                        ),
                      ] else ...[                        
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                          ),
                          child: const Center(
                            child: Text('Location information not available'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Disclaimer
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
                                'The information provided is for reference only. Please contact the specialist directly to confirm availability and services.',
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
            ],
          );
        },
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

  Widget _buildClinicHoursRow(String day, String? hours) {
    final now = DateTime.now();
    final currentDay = DateFormat('EEEE').format(now).toLowerCase();
    final isToday = currentDay == day.toLowerCase();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            day,
            style: TextStyle(
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: isToday ? AppConstants.primaryColor : null,
            ),
          ),
          Text(
            hours ?? 'Closed',
            style: TextStyle(
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
              color: hours == null ? Colors.red : (isToday ? AppConstants.primaryColor : null),
            ),
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}