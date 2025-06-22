import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:elephant_tracker_app/models/app_user.dart';
import 'package:elephant_tracker_app/models/elephant.dart';
import 'package:elephant_tracker_app/services/data_service.dart';
import 'package:elephant_tracker_app/controllers/map_controller.dart' as AppMapController;
import 'package:elephant_tracker_app/views/driver/widgets/alert_banner.dart';

class DriverMapScreen extends StatefulWidget {
  final AppUser user;
  const DriverMapScreen({super.key, required this.user});

  @override
  _DriverMapScreenState createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  final DataService _dataService = DataService();
  final AppMapController.MapController _mapController = AppMapController.MapController();
  final MapController _flutterMapController = MapController();

  StreamSubscription? _trainSubscription;
  StreamSubscription? _elephantSubscription;

  List<Elephant> _elephants = [];
  LatLng? _trainPosition;

  String _alertMessage = "All Clear";
  Color _alertColor = Colors.green;
  bool _isMapReady = false; // Flag to track if the map is initialized

  @override
  void initState() {
    super.initState();
    _startListening();
  }
  
  @override
  void dispose() {
    _trainSubscription?.cancel();
    _elephantSubscription?.cancel();
    super.dispose();
  }

  void _startListening() {
    _trainSubscription = _dataService.getTrainPositionStream().listen((pos) {
      if (mounted) {
        // Only move the map if it's ready and the position has changed
        if (_isMapReady && pos != _trainPosition) {
           _flutterMapController.move(pos, 15.0);
        }
        setState(() {
          _trainPosition = pos;
        });
        _updateAlerts();
      }
    });

    _elephantSubscription = _dataService.getElephantsStream().listen((elephants) {
      if (mounted) {
        setState(() {
          _elephants = elephants;
        });
        _updateAlerts();
      }
    });
  }

  void _updateAlerts() {
    if (_trainPosition == null) return;

    bool dangerFound = false;
    bool cautionFound = false;

    for (var elephant in _elephants) {
      double distance = _mapController.getDistance(_trainPosition!, elephant.position);
      if (distance < AppMapController.MapController.DANGER_ZONE_RADIUS) {
        dangerFound = true;
        break; 
      }
      if (distance < AppMapController.MapController.CAUTION_ZONE_RADIUS) {
        cautionFound = true;
      }
    }

    if (dangerFound) {
      _alertMessage = "DANGER! Elephant on track!";
      _alertColor = Colors.red;
    } else if (cautionFound) {
      _alertMessage = "CAUTION: Elephant nearby";
      _alertColor = Colors.orange;
    } else {
      _alertMessage = "All Clear";
      _alertColor = Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Show the user's name even on the loading screen
    if (_trainPosition == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Driver View (${widget.user.username})')),
        body: const Center(child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        )),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: Text('Driver View (${widget.user.username})')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _flutterMapController,
            options: MapOptions(
              initialCenter: _trainPosition!,
              initialZoom: 15.0,
              // FIX: Use onMapReady to know when the controller can be used
              onMapReady: () {
                setState(() {
                  _isMapReady = true;
                });
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c'],
              ),
              MarkerLayer(
                markers: [
                  // Train Marker
                  Marker(
                    point: _trainPosition!,
                    child: const Icon(Icons.train, color: Colors.blue, size: 40),
                  ),
                  // Elephant Markers
                  ..._elephants.map((elephant) {
                     double distance = _mapController.getDistance(_trainPosition!, elephant.position);
                     Color color = Colors.green.withOpacity(0.8);
                     if(distance < AppMapController.MapController.DANGER_ZONE_RADIUS) {
                       color = Colors.red;
                     } else if (distance < AppMapController.MapController.CAUTION_ZONE_RADIUS) {
                       color = Colors.orange;
                     }
                     
                     return Marker(
                       point: elephant.position,
                       child: Icon(Icons.location_on, color: color, size: 40),
                     );
                  })
                ],
              ),
            ],
          ),
          if (_alertMessage != "All Clear")
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: AlertBanner(message: _alertMessage, color: _alertColor),
            ),
        ],
      ),
    );
  }
}
