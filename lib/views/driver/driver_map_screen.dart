import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:elephant_tracker_app/data/railway_data.dart';
import 'package:elephant_tracker_app/models/app_user.dart';
import 'package:elephant_tracker_app/models/elephant.dart';
import 'package:elephant_tracker_app/services/data_service.dart';
import 'package:elephant_tracker_app/services/ai_service.dart';
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

class _DriverMapScreenState extends State<DriverMapScreen> {
  final DataService _dataService = DataService();
  final AuthController _authController = AuthController();
  final AppMapController.MapController _mapLogicController = AppMapController.MapController();
  final MapController _flutterMapController = MapController();
  final AIService _aiService = AIService();

  StreamSubscription? _trainSubscription;
  StreamSubscription? _elephantSubscription;

  List<Elephant> _elephants = [];
  LatLng? _trainPosition;

  String _alertMessage = "All Clear";
  Color _alertColor = Colors.green;
  bool _isMapReady = false;
  String _currentTileLayer = 'Street';

  DateTime? _lastIncidentTime;

  @override
  void initState() {
    super.initState();
    _dataService.startSendingTrainLocation();
    _startListeningToData();
  }

  @override
  void dispose() {
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
    if(!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }

  void _updateAlerts() async {
    if (_trainPosition == null) return;

    int closeElephantCount = 0;
    double closestDistance = double.infinity;

    for (var elephant in _elephants) {
      double distance = _mapLogicController.getDistance(_trainPosition!, elephant.position);
      if (distance < AppMapController.MapController.DANGER_ZONE_RADIUS) {
        closeElephantCount++;
        if(distance < closestDistance) closestDistance = distance;
      }
    }

    if (closeElephantCount > 0) {
      if (_lastIncidentTime == null || DateTime.now().difference(_lastIncidentTime!).inMinutes > 1) {

        if(!mounted) return;
        setState(() => _alertMessage = "Generating smart alert...");

        final dynamicAlert = await _aiService.generateDynamicAlert(
          elephantCount: closeElephantCount,
          distance: closestDistance,
          trainLocation: _trainPosition!,
        );

        _dataService.logIncident({
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'location': {'lat': _trainPosition!.latitude, 'lng': _trainPosition!.longitude},
          'elephantCount': closeElephantCount,
          'trainId': widget.user.username,
        });

        if(!mounted) return;
        setState(() {
          _alertMessage = dynamicAlert;
          _alertColor = Theme.of(context).colorScheme.error;
          _lastIncidentTime = DateTime.now();
        });
      }
    } else {
      if(!mounted) return;
      setState(() {
        _alertMessage = "All Clear";
        _alertColor = Colors.green;
        _lastIncidentTime = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_trainPosition == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Driver View (${widget.user.username})')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
                TileLayer(urlTemplate: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'),

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
