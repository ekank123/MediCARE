import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:medicare_plus/models/specialist_model.dart';

class SpecialistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get user's current location
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }

  // Get specialists near a location
  Future<List<SpecialistModel>> getNearbySpecialists(
      double latitude, double longitude, double radiusInKm, {SpecialistType? type}) async {
    return findNearbySpecialists(latitude, longitude, radiusInKm, type == null ? null : type.toString().split('.').last);
  }
  
  // Find specialists near a location with string type parameter
  Future<List<SpecialistModel>> findNearbySpecialists(
      double latitude, double longitude, double radiusInKm, [String? specialistType]) async {
    try {
      // Convert km to degrees (approximate)
      // 1 degree of latitude = 111 km
      // 1 degree of longitude = 111 km * cos(latitude)
      final latDegrees = radiusInKm / 111.0;
      final lonDegrees = radiusInKm / (111.0 * _cosRadians(latitude * (3.14159 / 180)));

      final minLat = latitude - latDegrees;
      final maxLat = latitude + latDegrees;
      final minLon = longitude - lonDegrees;
      final maxLon = longitude + lonDegrees;

      // Create a query to find specialists within the bounding box
      Query query = _firestore.collection('specialists');

      // Filter by specialist type if provided
      if (specialistType != null && specialistType != 'all') {
        query = query.where('type', isEqualTo: specialistType);
      }

      // Get specialists within the bounding box
      final snapshot = await query.get();
      final specialists = snapshot.docs
          .map((doc) => SpecialistModel.fromMap(doc.data() as Map<String, dynamic>))
          .where((specialist) {
            final specialistLat = specialist.location.latitude;
            final specialistLon = specialist.location.longitude;
            return specialistLat >= minLat &&
                specialistLat <= maxLat &&
                specialistLon >= minLon &&
                specialistLon <= maxLon;
          })
          .toList();

      // Calculate and set distance for each specialist, then sort by distance
      for (var specialist in specialists) {
        specialist.distance = _calculateDistance(
            latitude, longitude, specialist.location.latitude, specialist.location.longitude);
      }
      
      specialists.sort((a, b) => (a.distance ?? double.infinity).compareTo(b.distance ?? double.infinity));

      return specialists;
    } catch (e) {
      throw Exception('Failed to get nearby specialists: $e');
    }
  }

  // Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a = _sinSquared(dLat / 2) +
        _cosRadians(_toRadians(lat1)) *
            _cosRadians(_toRadians(lat2)) *
            _sinSquared(dLon / 2);
    final c = 2 * _atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

  // Helper functions for distance calculation
  double _toRadians(double degrees) {
    return degrees * (3.14159 / 180);
  }

  double _sinSquared(double value) {
    return _sin(value) * _sin(value);
  }

  double _sin(double value) {
    return math.sin(value);
  }

  double _cosRadians(double radians) {
    return math.cos(radians);
  }

  double _atan2(double y, double x) {
    return math.atan2(y, x);
  }

  double sqrt(double value) {
    return math.sqrt(value);
  }

  // Get specialist details
  Future<SpecialistModel?> getSpecialistById(String specialistId) async {
    try {
      final doc = await _firestore.collection('specialists').doc(specialistId).get();
      if (doc.exists) {
        return SpecialistModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get specialist: $e');
    }
  }
}