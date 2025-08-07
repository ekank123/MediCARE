import 'dart:io';
import 'dart:math' as math;
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:medicare_plus/models/scan_model.dart';

class GeminiService {
  late final GenerativeModel _model;
  static const String _apiKey = 'YOUR_GEMINI_API_KEY'; // Replace with actual API key

  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-pro-vision',
      apiKey: _apiKey,
    );
  }

  Future<DiagnosticResponse> analyzeSkinCondition(File imageFile, {String? symptoms}) async {
    try {
      final content = await _prepareContent(imageFile, ScanRegionType.skin, symptoms);
      final response = await _model.generateContent([content]);
      return _parseResponse(response.text ?? '');
    } catch (e) {
      throw Exception('Failed to analyze skin condition: $e');
    }
  }

  Future<DiagnosticResponse> analyzeEyeCondition(File imageFile, {String? symptoms}) async {
    try {
      final content = await _prepareContent(imageFile, ScanRegionType.eye, symptoms);
      final response = await _model.generateContent([content]);
      return _parseResponse(response.text ?? '');
    } catch (e) {
      throw Exception('Failed to analyze eye condition: $e');
    }
  }

  Future<Content> _prepareContent(File imageFile, ScanRegionType type, String? symptoms) async {
    final bytes = await imageFile.readAsBytes();
    final part = DataPart('image/jpeg', bytes);

    String prompt;
    if (type == ScanRegionType.skin) {
      prompt = '''Analyze this skin condition image and provide the following information in JSON format:
      1. Possible conditions (list up to 3)
      2. Confidence score for each condition (0-1)
      3. Urgency level for each condition (mild, needsMonitoring, seeDoctor)
      4. Suggested home remedies or over-the-counter treatments
      5. Hygiene tips
      6. When to see a doctor
      
      Additional symptoms described by user: ${symptoms ?? 'None provided'}
      
      IMPORTANT: Your response must be in valid JSON format with the following structure:
      {
        "conditions": [
          {
            "name": "Condition name",
            "confidenceScore": 0.85,
            "urgencyLevel": "mild|needsMonitoring|seeDoctor"
          }
        ],
        "remedies": ["Remedy 1", "Remedy 2"],
        "hygieneTips": ["Tip 1", "Tip 2"],
        "whenToSeeDoctor": "Description"
      }
      ''';
    } else {
      prompt = '''Analyze this eye condition image and provide the following information in JSON format:
      1. Possible conditions (list up to 3)
      2. Confidence score for each condition (0-1)
      3. Urgency level for each condition (mild, needsMonitoring, seeDoctor)
      4. Suggested home remedies or over-the-counter treatments
      5. Eye care tips
      6. When to see an ophthalmologist
      
      Additional symptoms described by user: ${symptoms ?? 'None provided'}
      
      IMPORTANT: Your response must be in valid JSON format with the following structure:
      {
        "conditions": [
          {
            "name": "Condition name",
            "confidenceScore": 0.85,
            "urgencyLevel": "mild|needsMonitoring|seeDoctor"
          }
        ],
        "remedies": ["Remedy 1", "Remedy 2"],
        "eyeCareTips": ["Tip 1", "Tip 2"],
        "whenToSeeDoctor": "Description"
      }
      ''';
    }

    return Content.multi([TextPart(prompt), part]);
  }

  DiagnosticResponse _parseResponse(String responseText) {
    try {
      // In a real implementation, parse the JSON response
      // For now, return a mock response
      return DiagnosticResponse(
        diagnosticResults: [
          DiagnosticResult(
            condition: 'Sample Condition',
            confidenceScore: 0.85,
            urgencyLevel: UrgencyLevel.mild,
          ),
        ],
        remedies: ['Apply aloe vera gel', 'Keep the area clean'],
        careTips: ['Wash regularly', 'Avoid scratching'],
        whenToSeeDoctor: 'If symptoms persist for more than a week',
      );
    } catch (e) {
      // If parsing fails, return a simple response with the raw text
      return DiagnosticResponse(
        diagnosticResults: 'Unable to analyze properly. Raw response: ${responseText.substring(0, math.min(100, responseText.length))}...',
        remedies: 'Please consult with a healthcare professional for proper diagnosis.',
      );
    }
  }
}

class DiagnosticResponse {
  final dynamic diagnosticResults; // Can be a String or List<DiagnosticResult>
  final dynamic remedies; // Can be a String or List<String>
  final List<String>? careTips;
  final String? whenToSeeDoctor;

  DiagnosticResponse({
    required this.diagnosticResults,
    required this.remedies,
    this.careTips,
    this.whenToSeeDoctor,
  });
}