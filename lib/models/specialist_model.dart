import 'package:cloud_firestore/cloud_firestore.dart';

enum SpecialistType { dermatologist, ophthalmologist }

extension SpecialistTypeExtension on SpecialistType {
  String capitalize() {
    return toString().split('.').last[0].toUpperCase() + toString().split('.').last.substring(1);
  }
}

class SpecialistModel {
  final String id;
  final String name;
  final SpecialistType type;
  final GeoPoint location;
  final String address;
  final String? phoneNumber;
  final Map<String, dynamic>? clinicHours;
  final double? rating;
  final int? reviewCount;
  double? distance; // Distance from user's location in km

  SpecialistModel({
    required this.id,
    required this.name,
    required this.type,
    required this.location,
    required this.address,
    this.phoneNumber,
    this.clinicHours,
    this.rating,
    this.reviewCount,
    this.distance,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString().split('.').last,
      'location': location,
      'address': address,
      'phoneNumber': phoneNumber,
      'clinicHours': clinicHours,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  factory SpecialistModel.fromMap(Map<String, dynamic> map) {
    return SpecialistModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: SpecialistType.values.firstWhere(
        (type) => type.toString().split('.').last == map['type'],
        orElse: () => SpecialistType.dermatologist,
      ),
      location: map['location'] ?? const GeoPoint(0, 0),
      address: map['address'] ?? '',
      phoneNumber: map['phoneNumber'],
      clinicHours: map['clinicHours'],
      rating: map['rating']?.toDouble(),
      reviewCount: map['reviewCount'],
    );
  }
}