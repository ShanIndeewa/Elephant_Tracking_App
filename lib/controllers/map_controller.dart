import 'dart:math';
import 'package:latlong2/latlong.dart';

class MapController {
  // In meters
  static const double DANGER_ZONE_RADIUS = 500;
  static const double CAUTION_ZONE_RADIUS = 2000;

  // Haversine formula to calculate distance
  double getDistance(LatLng pos1, LatLng pos2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((pos2.latitude - pos1.latitude) * p) / 2 +
        cos(pos1.latitude * p) *
            cos(pos2.latitude * p) *
            (1 - cos((pos2.longitude - pos1.longitude) * p)) /
            2;
    return 12742 * asin(sqrt(a)) * 1000; // 2 * R * 1000
  }

  // Ray-casting algorithm to check if a point is inside a polygon
  bool isPointInPolygon(LatLng point, List<LatLng> polygon) {
    if (polygon.length < 3) {
      return false;
    }
    bool isInside = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; j = i++) {
      if (((polygon[i].latitude > point.latitude) !=
          (polygon[j].latitude > point.latitude)) &&
          (point.longitude <
              (polygon[j].longitude - polygon[i].longitude) *
                  (point.latitude - polygon[i].latitude) /
                  (polygon[j].latitude - polygon[i].latitude) +
                  polygon[i].longitude)) {
        isInside = !isInside;
      }
    }
    return isInside;
  }
}
