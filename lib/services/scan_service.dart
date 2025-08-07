import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:medicare_plus/models/scan_model.dart';
import 'package:medicare_plus/services/gemini_service.dart';

class ScanService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final GeminiService _geminiService = GeminiService();

  // Upload image to Firebase Storage
  Future<String> _uploadImage({required File imageFile, required String userId}) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${userId}.jpg';
      final ref = _storage.ref().child('scans/$userId/$fileName');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }
  
  // Upload image to Firebase Storage with custom path
  Future<String> uploadImageToStorage(String imagePath, String storagePath) async {
    try {
      final File imageFile = File(imagePath);
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('$storagePath/$fileName');
      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask.whenComplete(() {});
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  // Create a new skin scan
  Future<ScanModel> createSkinScan({required String userId, required File imageFile, String? symptoms}) async {
    try {
      // Upload image to Firebase Storage
      final imageUrl = await _uploadImage(imageFile: imageFile, userId: userId);

      // Analyze image using Gemini API
      final diagnosticResponse = await _geminiService.analyzeSkinCondition(imageFile, symptoms: symptoms);

      // Create scan document in Firestore
      final scanId = _firestore.collection('scans').doc().id;
      final scanModel = ScanModel(
        id: scanId,
        userId: userId,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
        regionType: ScanRegionType.skin,
        diagnosticResults: diagnosticResponse.diagnosticResults,
        suggestedRemedies: diagnosticResponse.remedies,
        userNotes: symptoms,
      );

      await _firestore.collection('scans').doc(scanId).set(scanModel.toMap());
      return scanModel;
    } catch (e) {
      throw Exception('Failed to create skin scan: $e');
    }
  }

  // Create a new eye scan
  Future<ScanModel> createEyeScan({required String userId, required File imageFile, String? symptoms}) async {
    try {
      // Upload image to Firebase Storage
      final imageUrl = await _uploadImage(imageFile: imageFile, userId: userId);

      // Analyze image using Gemini API
      final diagnosticResponse = await _geminiService.analyzeEyeCondition(imageFile, symptoms: symptoms);

      // Create scan document in Firestore
      final scanId = _firestore.collection('scans').doc().id;
      final scanModel = ScanModel(
        id: scanId,
        userId: userId,
        imageUrl: imageUrl,
        timestamp: DateTime.now(),
        regionType: ScanRegionType.eye,
        diagnosticResults: diagnosticResponse.diagnosticResults,
        suggestedRemedies: diagnosticResponse.remedies,
        userNotes: symptoms,
      );

      await _firestore.collection('scans').doc(scanId).set(scanModel.toMap());
      return scanModel;
    } catch (e) {
      throw Exception('Failed to create eye scan: $e');
    }
  }
  
  // Create a new eye scan without image (symptoms only)
  Future<ScanModel> createEyeScanWithoutImage({required String userId, String? symptoms}) async {
    try {
      if (symptoms == null || symptoms.isEmpty) {
        throw Exception('Symptoms are required when no image is provided');
      }
      
      // Create a placeholder response since we don't have an image to analyze
      final diagnosticResponse = DiagnosticResponse(
        diagnosticResults: 'Based on the symptoms provided: $symptoms',
        remedies: 'Please consult with a specialist for accurate diagnosis and treatment.',
      );

      // Create scan document in Firestore
      final scanId = _firestore.collection('scans').doc().id;
      final scanModel = ScanModel(
        id: scanId,
        userId: userId,
        imageUrl: '', // No image URL
        timestamp: DateTime.now(),
        regionType: ScanRegionType.eye,
        diagnosticResults: diagnosticResponse.diagnosticResults,
        suggestedRemedies: diagnosticResponse.remedies,
        userNotes: symptoms,
      );

      await _firestore.collection('scans').doc(scanId).set(scanModel.toMap());
      return scanModel;
    } catch (e) {
      throw Exception('Failed to create eye scan without image: $e');
    }
  }
  
  // Create a new skin scan without image (symptoms only)
  Future<ScanModel> createSkinScanWithoutImage({required String userId, String? symptoms}) async {
    try {
      if (symptoms == null || symptoms.isEmpty) {
        throw Exception('Symptoms are required when no image is provided');
      }
      
      // Create a placeholder response since we don't have an image to analyze
      final diagnosticResponse = DiagnosticResponse(
        diagnosticResults: 'Based on the symptoms provided: $symptoms',
        remedies: 'Please consult with a dermatologist for accurate diagnosis and treatment.',
      );

      // Create scan document in Firestore
      final scanId = _firestore.collection('scans').doc().id;
      final scanModel = ScanModel(
        id: scanId,
        userId: userId,
        imageUrl: '', // No image URL
        timestamp: DateTime.now(),
        regionType: ScanRegionType.skin,
        diagnosticResults: diagnosticResponse.diagnosticResults,
        suggestedRemedies: diagnosticResponse.remedies,
        userNotes: symptoms,
      );

      await _firestore.collection('scans').doc(scanId).set(scanModel.toMap());
      return scanModel;
    } catch (e) {
      throw Exception('Failed to create skin scan without image: $e');
    }
  }

  // Get all scans for a user
  Future<List<ScanModel>> getUserScans([String? userId]) async {
    try {
      final query = userId != null
          ? _firestore
              .collection('scans')
              .where('userId', isEqualTo: userId)
              .orderBy('timestamp', descending: true)
          : _firestore
              .collection('scans')
              .orderBy('timestamp', descending: true);
      
      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ScanModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      throw Exception('Failed to get user scans: $e');
    }
  }

  // Get a specific scan by ID
  Future<ScanModel?> getScanById(String scanId) async {
    try {
      final doc = await _firestore.collection('scans').doc(scanId).get();
      if (doc.exists) {
        return ScanModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get scan: $e');
    }
  }

  // Update user notes for a scan
  Future<void> updateScanNotes(String scanId, String notes) async {
    try {
      await _firestore.collection('scans').doc(scanId).update({
        'userNotes': notes,
      });
    } catch (e) {
      throw Exception('Failed to update scan notes: $e');
    }
  }

  // Delete a scan
  Future<void> deleteScan(String scanId) async {
    try {
      // Get the scan first to get the image URL
      final scanDoc = await _firestore.collection('scans').doc(scanId).get();
      if (scanDoc.exists) {
        final scanData = scanDoc.data();
        if (scanData != null && scanData['imageUrl'] != null && scanData['imageUrl'] != '') {
          // Delete image from Firebase Storage
          final ref = _storage.refFromURL(scanData['imageUrl']);
          await ref.delete();
        }
      }

      // Delete scan document from Firestore
      await _firestore.collection('scans').doc(scanId).delete();
    } catch (e) {
      throw Exception('Failed to delete scan: $e');
    }
  }
}