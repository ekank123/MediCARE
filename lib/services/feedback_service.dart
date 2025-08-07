import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:medicare_plus/models/feedback_model.dart';

class FeedbackService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Submit feedback
  Future<FeedbackModel> submitFeedback(FeedbackModel feedback) async {
    try {
      final docRef = _firestore.collection('feedback').doc();
      
      // Create a new feedback with the generated ID
      final updatedFeedback = FeedbackModel(
        id: docRef.id,
        userId: feedback.userId,
        userName: feedback.userName,
        subject: feedback.subject,
        message: feedback.message,
        rating: feedback.rating,
        type: feedback.type,
        timestamp: feedback.timestamp,
        status: feedback.status,
      );

      await docRef.set(updatedFeedback.toMap());
      return updatedFeedback;
    } catch (e) {
      throw Exception('Failed to submit feedback: $e');
    }
  }

  // Get user's feedback history
  Stream<List<FeedbackModel>> getUserFeedback(String userId) {
    return _firestore
        .collection('feedback')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FeedbackModel.fromMap(doc.data()))
              .toList();
        });
  }

  // Update feedback
  Future<void> updateFeedback(String feedbackId, {String? subject, String? message, int? rating, String? type, String? status}) async {
    try {
      final Map<String, dynamic> updateData = {};
      
      if (subject != null) updateData['subject'] = subject;
      if (message != null) updateData['message'] = message;
      if (rating != null) updateData['rating'] = rating;
      if (type != null) updateData['type'] = type;
      if (status != null) updateData['status'] = status;
      
      await _firestore.collection('feedback').doc(feedbackId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update feedback: $e');
    }
  }

  // Delete feedback
  Future<void> deleteFeedback(String feedbackId) async {
    try {
      await _firestore.collection('feedback').doc(feedbackId).delete();
    } catch (e) {
      throw Exception('Failed to delete feedback: $e');
    }
  }
}