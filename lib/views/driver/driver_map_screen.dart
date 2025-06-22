import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:elephant_tracker_app/data/railway_data.dart'; // Import railway data
import 'package:elephant_tracker_app/models/app_user.dart';
import 'package:elephant_tracker_app/models/elephant.dart';
import 'package:elephant_tracker_app/services/data_service.dart';
import 'package:elephant_tracker_app/controllers/auth_controller.dart';
import 'package:elephant_tracker_app/controllers/map_controller.dart' as AppMapController;
import 'package:elephant_tracker_app/views/login/login_screen.dart';
import 'package:elephant_tracker_app/views/driver/widgets/alert_banner.dart';

class DriverMapScreen extends StatefulWidget {
  final AppUser user;
  const DriverMapScreen({super.key, required this.user});

  @override
  _DriverMapScreenState createState() => _DriverMapScreenState();
}

// Add TickerProviderStateMixin for the animation controller
class _DriverMapScreenState extends State<DriverMapScreen> with TickerProviderStateMixin {
  final DataService _dataService = DataService();
  final AuthController _authController = AuthController();
  final AppMapController.MapController _mapLogicController = AppMapController.MapController();
  final MapController _flutterMapController = MapController();

  StreamSubscription? _trainSubscription;
  StreamSubscription? _elephantSubscription;

  List<Elephant> _elephants = [];
  LatLng? _trainPosition;

  String _alertMessage = "All Clear";
  Color _alertColor = Colors.green;
  bool _isMapReady = false;
  String _currentTileLayer = 'Street';
  bool _isCurrentTrackInDanger = false;

  final String _driverRouteKey = 'main_line';

  // --- Animation Controller for Loading Screen ---
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;


  @override
  void initState() {
    super.initState();

    // --- Setup for the loading animation ---
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.4).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // --- Original setup ---
    _dataService.startSendingTrainLocation();
    _startListeningToData();
  }

  @override
  void dispose() {
    _animationController.dispose(); // Dispose the animation controller
    _dataService.stopSendingTrainLocation();
    _trainSubscription?.cancel();
    _elephantSubscription?.cancel();
    super.dispose();
  }

  void _startListeningToData() {
    _trainSubscription = _dataService.getTrainPositionStream().listen((pos) {
      if (mounted) {
        if (_isMapReady && pos != _trainPosition) {
          _flutterMapController.move(pos, 15.0);
        }
        setState(() => _trainPosition = pos);
        _updateAlerts();
      }
    });

    _elephantSubscription = _dataService.getElephantsStream().listen((elephants) {
      if (mounted) {
        setState(() => _elephants = elephants);
        _updateAlerts();
      }
    });
  }

  void _logout() async {
    await _authController.logoutUser();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }

  void _updateAlerts() {
    if (_trainPosition == null) return;
    bool dangerFound = false;
    bool cautionFound = false;
    bool trackDanger = false;

    const double TRACK_DANGER_DISTANCE = 100;

    List<LatLng> currentRoute = RailwayData.allTracks[_driverRouteKey] ?? [];

    for (var elephant in _elephants) {
      double distanceToTrain = _mapLogicController.getDistance(_trainPosition!, elephant.position);
      if (distanceToTrain < AppMapController.MapController.DANGER_ZONE_RADIUS) dangerFound = true;
      if (distanceToTrain < AppMapController.MapController.CAUTION_ZONE_RADIUS) cautionFound = true;

      for (int i = 0; i < currentRoute.length - 1; i++) {
        if (_mapLogicController.getDistance(elephant.position, currentRoute[i]) < TRACK_DANGER_DISTANCE) {
          trackDanger = true;
          break;
        }
      }
      if (trackDanger) break;
    }

    setState(() {
      _isCurrentTrackInDanger = trackDanger;
      if (dangerFound) {
        _alertMessage = "DANGER! Elephant in proximity!";
        _alertColor = Theme.of(context).colorScheme.error;
      } else if (cautionFound) {
        _alertMessage = "CAUTION: Elephant nearby";
        _alertColor = Colors.orangeAccent;
      } else {
        _alertMessage = "All Clear";
        _alertColor = Colors.green;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_trainPosition == null) {
      // --- New Animated Loading Screen ---
      return Scaffold(
        appBar: AppBar(title: Text('Driver View (${widget.user.username})')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(
                scale: _scaleAnimation,
                child: Icon(
                  Icons.gps_fixed,
                  size: 60,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Waiting for GPS signal...',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
      );
    }

    List<Polyline> allTracks = RailwayData.allTracks.entries.map((entry) {
      final isCurrentRoute = entry.key == _driverRouteKey;
      return Polyline(
        points: entry.value,
        strokeWidth: isCurrentRoute ? 6.0 : 3.0,
        color: isCurrentRoute
            ? (_isCurrentTrackInDanger ? Colors.red.withOpacity(0.9) : Theme.of(context).colorScheme.primary.withOpacity(0.8))
            : Colors.black.withOpacity(0.3),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Driver View (${widget.user.username})'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _flutterMapController,
            options: MapOptions(
              initialCenter: _trainPosition!,
              initialZoom: 15.0,
              onMapReady: () => setState(() => _isMapReady = true),
            ),
            children: [
              if (_currentTileLayer == 'Street')
                TileLayer(urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'),
              if (_currentTileLayer == 'Satellite')
                TileLayer(urlTemplate: '[https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/](https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/){z}/{y}/{x}'),

              PolylineLayer(polylines: allTracks),

              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _trainPosition!,
                    radius: AppMapController.MapController.DANGER_ZONE_RADIUS,
                    useRadiusInMeter: true,
                    color: Colors.red.withOpacity(0.1),
                    borderColor: Colors.red.withOpacity(0.5),
                    borderStrokeWidth: 2,
                  ),
                  CircleMarker(
                    point: _trainPosition!,
                    radius: AppMapController.MapController.CAUTION_ZONE_RADIUS,
                    useRadiusInMeter: true,
                    color: Colors.orange.withOpacity(0.1),
                    borderColor: Colors.orange.withOpacity(0.5),
                    borderStrokeWidth: 1,
                  ),
                ],
              ),

              MarkerLayer(
                markers: [
                  Marker(
                    point: _trainPosition!,
                    child: Icon(Icons.train, color: Theme.of(context).colorScheme.primary, size: 30),
                  ),
                  ..._elephants.map((elephant) {
                    double distance = _mapLogicController.getDistance(_trainPosition!, elephant.position);
                    Color color = Colors.green;
                    if (distance < AppMapController.MapController.DANGER_ZONE_RADIUS) color = Colors.red;
                    else if (distance < AppMapController.MapController.CAUTION_ZONE_RADIUS) color = Colors.orangeAccent;
                    return Marker(point: elephant.position, child: Icon(Icons.location_on, color: color, size: 35));
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
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _currentTileLayer,
                underline: Container(),
                onChanged: (String? newValue) => setState(() => _currentTileLayer = newValue!),
                items: ['Street', 'Satellite']
                    .map<DropdownMenuItem<String>>((String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(fontSize: 14)),
                ))
                    .toList(),
              ),
            ),
          )
        ],
      ),
    );
  }
}
