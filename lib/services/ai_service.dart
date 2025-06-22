import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:latlong2/latlong.dart';
import 'package:elephant_tracker_app/models/incident.dart';

class AIService {
  // --- IMPORTANT ---
  // 1. Get your API Key from Google AI Studio: [https://makersuite.google.com/app/apikey](https://makersuite.google.com/app/apikey)
  // 2. It's recommended to store this key securely (e.g., using environment variables)
  //    and not directly in the code for a production app.
  static const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';

  final GenerativeModel _model;

  AIService()
      : _model = GenerativeModel(model: 'gemini-pro', apiKey: _apiKey);

  // Generates a descriptive, real-time alert for the driver
  Future<String> generateDynamicAlert({
    required int elephantCount,
    required double distance,
    required LatLng trainLocation,
  }) async {
    final prompt =
        'Generate a short, urgent safety alert for a train driver. Be concise. The driver needs to know this information immediately. Data: There are $elephantCount elephants, approximately ${distance.round()} meters away from the train. The train\'s current location is latitude ${trainLocation.latitude}, longitude ${trainLocation.longitude}.';
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "ALERT: Elephant proximity!";
    } catch (e) {
      print("Gemini API Error (Alert): $e");
      return "DANGER! Elephant in proximity!"; // Fallback message
    }
  }

  // Generates a formal incident report for the admin
  Future<String> generateIncidentReport(Incident incident) async {
    final prompt = '''
      Write a formal incident report based on the following data.
      The report should be structured, professional, and clear.

      Data:
      - Incident ID: ${incident.id}
      - Date & Time: ${incident.timestamp.toLocal().toString()}
      - Location (Lat/Lng): ${incident.location.latitude}, ${incident.location.longitude}
      - Train ID: ${incident.trainId}
      - Number of Elephants Involved: ${incident.elephantCount}

      Structure the report with headings for Summary, Location Details, and Recommendations.
      ''';
    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      return response.text ?? "Could not generate report.";
    } catch (e) {
      print("Gemini API Error (Report): $e");
      return "Error generating report. Please check the logs.";
    }
  }
}