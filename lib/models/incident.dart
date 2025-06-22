import 'package:latlong2/latlong.dart';

class Incident {
  final String id;
  final LatLng location;
  final DateTime timestamp;
  final int elephantCount;
  final String trainId;

  Incident({
    required this.id,
    required this.location,
    required this.timestamp,
    required this.elephantCount,
    required this.trainId,
  });

  // Factory constructor to create an Incident from a Map
  factory Incident.fromMap(String id, Map<dynamic, dynamic> data) {
    return Incident(
      id: id,
      location: LatLng(
        (data['location']['lat'] as num).toDouble(),
        (data['location']['lng'] as num).toDouble(),
      ),
      timestamp: DateTime.fromMillisecondsSinceEpoch(data['timestamp']),
      elephantCount: data['elephantCount'] ?? 1,
      trainId: data['trainId'] ?? 'Unknown',
    );
  }
}