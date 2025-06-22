import 'package:latlong2/latlong.dart';

class Elephant {
  final String id;
  LatLng position; // Made non-final to allow movement simulation

  Elephant({required this.id, required this.position});
}