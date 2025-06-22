import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:geolocator/geolocator.dart';
import 'package:elephant_tracker_app/models/elephant.dart';
import 'package:latlong2/latlong.dart';

class DataService {
  final FirebaseDatabase _db = FirebaseDatabase.instance;
  StreamSubscription<Position>? _positionStreamSubscription;

  // --- Live Location Sending ---

  // Starts sending the device's location to Firebase.
  Future<void> startSendingTrainLocation() async {
    // 1. Check for location permissions
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        print('Location permissions are denied');
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      print('Location permissions are permanently denied, we cannot request permissions.');
      return;
    }

    // 2. Start listening to location updates
    _positionStreamSubscription = Geolocator.getPositionStream().listen((Position position) {
      // 3. Write the new position to the Realtime Database
      _db.ref('vehicles/train01/position').set({
        'lat': position.latitude,
        'lng': position.longitude,
      });
    });
  }

  // Stops sending the device's location.
  void stopSendingTrainLocation() {
    _positionStreamSubscription?.cancel();
  }


  // --- Data Fetching (Streams) ---

  // Provides a real-time stream of all elephants
  Stream<List<Elephant>> getElephantsStream() {
    return _db.ref('elephants').onValue.map((event) {
      final List<Elephant> elephants = [];
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        data.forEach((key, value) {
          final elephantData = value as Map;
          final positionData = elephantData['position'] as Map;
          elephants.add(
            Elephant(
              id: key,
              position: LatLng(
                (positionData['lat'] as num).toDouble(),
                (positionData['lng'] as num).toDouble(),
              ),
            ),
          );
        });
      }
      return elephants;
    });
  }

  // Provides a real-time stream of the train's position
  Stream<LatLng> getTrainPositionStream() {
    return _db.ref('vehicles/train01/position').onValue.map((event) {
      final data = event.snapshot.value;
      if (data != null && data is Map) {
        return LatLng(
          (data['lat'] as num).toDouble(),
          (data['lng'] as num).toDouble(),
        );
      }
      return const LatLng(0, 0); // Default position
    });
  }
}
