import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackModel {
  final String? id;
  final String userId;
  final String? userName;
  final String? subject;
  final String message;
  final int? rating; // 1-5 rating scale
  final String? type;
  final DateTime timestamp;
  final String? status;

  FeedbackModel({
    this.id,
    required this.userId,
    this.userName,
    this.subject,
    required this.message,
    this.rating,
    this.type,
    required this.timestamp,
    this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'subject': subject,
      'message': message,
      'rating': rating,
      'type': type,
      'timestamp': timestamp,
      'status': status,
    };
  }

  factory FeedbackModel.fromMap(Map<String, dynamic> map) {
    return FeedbackModel(
      id: map['id'],
      userId: map['userId'] ?? '',
      userName: map['userName'],
      subject: map['subject'],
      message: map['message'] ?? '',
      rating: map['rating'],
      type: map['type'],
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      status: map['status'],
    );
  }
}