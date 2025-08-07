import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:medicare_plus/constants/app_constants.dart';
import 'package:medicare_plus/models/specialist_model.dart';
import 'package:medicare_plus/services/specialist_service.dart';
import 'package:medicare_plus/utils/connectivity_service.dart';
import 'package:medicare_plus/utils/theme_provider.dart';
import 'package:medicare_plus/screens/specialists/specialist_details_screen.dart';

class SpecialistMapScreen extends StatefulWidget {
  final String? initialSpecialistType;

  const SpecialistMapScreen({super.key, this.initialSpecialistType});

  @override
  State<SpecialistMapScreen> createState() => _SpecialistMapScreenState();
}

class _SpecialistMapScreenState extends State<SpecialistMapScreen> {
  final SpecialistService _specialistService = SpecialistService();
  GoogleMapController? _mapController;
  bool _isLoading = true;
  bool _isLoadingSpecialists = false;
  String? _errorMessage;
  LatLng? _currentLocation;
  Set<Marker> _markers = {};
  List<SpecialistModel> _specialists = [];
  String _selectedSpecialistType = 'all';
  double _searchRadius = 5.0; // km

  @override
  void initState() {
    super.initState();
    if (widget.initialSpecialistType != null) {
      _selectedSpecialistType = widget.initialSpecialistType!;
    }
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
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

      final location = await _specialistService.getCurrentLocation();
      
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(location.latitude, location.longitude);
          _isLoading = false;
        });
        _loadNearbySpecialists();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to get current location: $e';
        });
      }
    }
  }

  Future<void> _loadNearbySpecialists() async {
    if (_currentLocation == null) return;

    if (mounted) {
      setState(() {
        _isLoadingSpecialists = true;
      });
    }

    try {
      final specialists = await _specialistService.findNearbySpecialists(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
        _searchRadius,
        _selectedSpecialistType == 'all' ? null : _selectedSpecialistType,
      );
      
      if (mounted) {
        setState(() {
          _specialists = specialists;
          _updateMarkers();
          _isLoadingSpecialists = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSpecialists = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to load specialists: $e')),
          );
        });
      }
    }
  }

  void _updateMarkers() {
    final Set<Marker> markers = {};
    
    // Add current location marker
    if (_currentLocation != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    // Add specialist markers
    for (final specialist in _specialists) {
      final location = specialist.location;
      if (location != null) {
        final latLng = LatLng(location.latitude, location.longitude);
        final marker = Marker(
          markerId: MarkerId(specialist.id!),
          position: latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            specialist.type == 'dermatologist'
                ? BitmapDescriptor.hueOrange
                : BitmapDescriptor.hueViolet,
          ),
          infoWindow: InfoWindow(
            title: specialist.name,
            snippet: '${specialist.type.capitalize()} • ${specialist.rating} ★',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SpecialistDetailsScreen(specialistId: specialist.id!),
                ),
              );
            },
          ),
        );
        markers.add(marker);
      }
    }

    setState(() {
      _markers = markers;
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

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final connectivityService = Provider.of<ConnectivityService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Specialists'),
        centerTitle: true,
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
                    onPressed: _getCurrentLocation,
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
                    onPressed: _getCurrentLocation,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (_currentLocation == null) {
            return const Center(child: Text('Unable to get current location'));
          }

          return Stack(
            children: [
              GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _currentLocation!,
                  zoom: AppConstants.defaultMapZoom,
                ),
                markers: _markers,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                compassEnabled: true,
              ),
              if (_isLoadingSpecialists)
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: isDarkMode ? Colors.grey[800] : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Loading specialists...'),
                        ],
                      ),
                    ),
                  ),
                ),
              Positioned(
                bottom: 16,
                right: 16,
                child: Column(
                  children: [
                    FloatingActionButton(
                      heroTag: 'btn_my_location',
                      mini: true,
                      onPressed: () {
                        if (_currentLocation != null && _mapController != null) {
                          _mapController!.animateCamera(
                            CameraUpdate.newLatLngZoom(
                              _currentLocation!,
                              AppConstants.defaultMapZoom,
                            ),
                          );
                        }
                      },
                      child: const Icon(Icons.my_location),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: 'btn_refresh',
                      mini: true,
                      onPressed: _loadNearbySpecialists,
                      child: const Icon(Icons.refresh),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Filter Specialists',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                decoration: const InputDecoration(
                                  labelText: 'Specialist Type',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                value: _selectedSpecialistType,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'all',
                                    child: Text('All Specialists'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'dermatologist',
                                    child: Text('Dermatologist'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'ophthalmologist',
                                    child: Text('Ophthalmologist'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _selectedSpecialistType = value;
                                    });
                                    _loadNearbySpecialists();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<double>(
                                decoration: const InputDecoration(
                                  labelText: 'Distance (km)',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                value: _searchRadius,
                                items: const [
                                  DropdownMenuItem(
                                    value: 2.0,
                                    child: Text('2 km'),
                                  ),
                                  DropdownMenuItem(
                                    value: 5.0,
                                    child: Text('5 km'),
                                  ),
                                  DropdownMenuItem(
                                    value: 10.0,
                                    child: Text('10 km'),
                                  ),
                                  DropdownMenuItem(
                                    value: 20.0,
                                    child: Text('20 km'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      _searchRadius = value;
                                    });
                                    _loadNearbySpecialists();
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Found ${_specialists.length} specialists',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              DraggableScrollableSheet(
                initialChildSize: 0.25,
                minChildSize: 0.1,
                maxChildSize: 0.5,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[900] : Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 8, bottom: 16),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Expanded(
                          child: _specialists.isEmpty
                              ? Center(
                                  child: Text(
                                    'No specialists found in this area',
                                    style: Theme.of(context).textTheme.bodyLarge,
                                  ),
                                )
                              : ListView.builder(
                                  controller: scrollController,
                                  itemCount: _specialists.length,
                                  itemBuilder: (context, index) {
                                    final specialist = _specialists[index];
                                    return ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: specialist.type == 'dermatologist'
                                            ? Colors.orange[100]
                                            : Colors.purple[100],
                                        child: Icon(
                                          specialist.type == 'dermatologist'
                                              ? Icons.face
                                              : Icons.remove_red_eye,
                                          color: specialist.type == 'dermatologist'
                                              ? Colors.orange[800]
                                              : Colors.purple[800],
                                        ),
                                      ),
                                      title: Text(specialist.name),
                                      subtitle: Text(
                                        '${specialist.type.capitalize()} • ${specialist.distance?.toStringAsFixed(1) ?? '?'} km',
                                      ),
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            '${specialist.rating}',
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          const Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                      onTap: () {
                                        // Center map on this specialist
                                        if (specialist.location != null && _mapController != null) {
                                          final latLng = LatLng(
                                            specialist.location!.latitude,
                                            specialist.location!.longitude,
                                          );
                                          _mapController!.animateCamera(
                                            CameraUpdate.newLatLngZoom(latLng, 15),
                                          );
                                        }
                                        
                                        // Navigate to specialist details
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => SpecialistDetailsScreen(
                                              specialistId: specialist.id!,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}