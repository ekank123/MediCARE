import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final int? age;
  final String? gender;
  final List<String>? allergies;
  final String? medicalHistory;
  final double? height;
  final double? weight;
  final String? preferredLanguage;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.age,
    this.gender,
    this.allergies,
    this.medicalHistory,
    this.height,
    this.weight,
    this.preferredLanguage,
    required this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'age': age,
      'gender': gender,
      'allergies': allergies,
      'medicalHistory': medicalHistory,
      'height': height,
      'weight': weight,
      'preferredLanguage': preferredLanguage,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      age: map['age'],
      gender: map['gender'],
      allergies: map['allergies'] != null ? List<String>.from(map['allergies']) : null,
      medicalHistory: map['medicalHistory'],
      height: map['height'],
      weight: map['weight'],
      preferredLanguage: map['preferredLanguage'],
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    int? age,
    String? gender,
    List<String>? allergies,
    String? medicalHistory,
    double? height,
    double? weight,
    String? preferredLanguage,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      allergies: allergies ?? this.allergies,
      medicalHistory: medicalHistory ?? this.medicalHistory,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}