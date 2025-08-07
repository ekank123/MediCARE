import 'package:cloud_firestore/cloud_firestore.dart';

enum ScanRegionType { skin, eye }

enum UrgencyLevel { mild, needsMonitoring, seeDoctor }

class ScanModel {
  final String id;
  final String userId;
  final String? imageUrl;
  final DateTime timestamp;
  final ScanRegionType regionType;
  final List<DiagnosticResult> diagnosticResults;
  final List<String>? suggestedRemedies;
  final String? userNotes;

  ScanModel({
    required this.id,
    required this.userId,
    this.imageUrl,
    required this.timestamp,
    required this.regionType,
    required this.diagnosticResults,
    this.suggestedRemedies,
    this.userNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'imageUrl': imageUrl,
      'timestamp': timestamp,
      'regionType': regionType.toString().split('.').last,
      'diagnosticResults': diagnosticResults.map((result) => result.toMap()).toList(),
      'suggestedRemedies': suggestedRemedies,
      'userNotes': userNotes,
    };
  }

  factory ScanModel.fromMap(Map<String, dynamic> map) {
    return ScanModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      imageUrl: map['imageUrl'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      regionType: ScanRegionType.values.firstWhere(
        (type) => type.toString().split('.').last == map['regionType'],
        orElse: () => ScanRegionType.skin,
      ),
      diagnosticResults: List<DiagnosticResult>.from(
        map['diagnosticResults']?.map((result) => DiagnosticResult.fromMap(result)) ?? [],
      ),
      suggestedRemedies: map['suggestedRemedies'] != null
          ? List<String>.from(map['suggestedRemedies'])
          : null,
      userNotes: map['userNotes'],
    );
  }
}

class DiagnosticResult {
  final String condition;
  final double confidenceScore;
  final UrgencyLevel urgencyLevel;

  DiagnosticResult({
    required this.condition,
    required this.confidenceScore,
    required this.urgencyLevel,
  });

  Map<String, dynamic> toMap() {
    return {
      'condition': condition,
      'confidenceScore': confidenceScore,
      'urgencyLevel': urgencyLevel.toString().split('.').last,
    };
  }

  factory DiagnosticResult.fromMap(Map<String, dynamic> map) {
    return DiagnosticResult(
      condition: map['condition'] ?? '',
      confidenceScore: map['confidenceScore']?.toDouble() ?? 0.0,
      urgencyLevel: UrgencyLevel.values.firstWhere(
        (level) => level.toString().split('.').last == map['urgencyLevel'],
        orElse: () => UrgencyLevel.mild,
      ),
    );
  }
}