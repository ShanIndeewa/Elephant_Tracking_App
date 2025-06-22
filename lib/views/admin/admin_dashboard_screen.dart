import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:elephant_tracker_app/models/app_user.dart';
import 'package:elephant_tracker_app/models/elephant.dart';
import 'package:elephant_tracker_app/services/data_service.dart';
import 'package:elephant_tracker_app/controllers/auth_controller.dart';
import 'package:elephant_tracker_app/controllers/map_controller.dart' as AppMapController;
import 'package:elephant_tracker_app/views/login/login_screen.dart';
import 'package:elephant_tracker_app/views/admin/create_driver_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final AppUser user;
  const AdminDashboardScreen({super.key, required this.user});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DataService _dataService = DataService();
  final AuthController _authController = AuthController();
  final AppMapController.MapController _mapLogicController = AppMapController.MapController();

  StreamSubscription? _elephantSubscription;
  StreamSubscription? _trainSubscription;

  List<Elephant> _elephants = [];
  LatLng? _trainPosition;
  String _currentTileLayer = 'Street';

  bool _isDrawingMode = false;
  List<LatLng> _specialAreaPoints = [];
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  @override
  void dispose() {
    _elephantSubscription?.cancel();
    _trainSubscription?.cancel();
    super.dispose();
  }

  void _startListening() {
    _elephantSubscription =
        _dataService.getElephantsStream().listen((elephants) {
          if (mounted) setState(() => _elephants = elephants);
        });
    _trainSubscription = _dataService.getTrainPositionStream().listen((pos) {
      if (mounted) setState(() => _trainPosition = pos);
    });
  }

  void _handleMapTap(TapPosition tapPosition, LatLng point) {
    if (_isDrawingMode) {
      setState(() {
        _specialAreaPoints.add(point);
      });
    }
  }

  void _logout() async {
    await _authController.logoutUser();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
    );
  }

  Widget _buildMap() {
    List<Marker> markers = [];

    markers.addAll(_elephants.map((elephant) {
      final isHighlighted = _mapLogicController.isPointInPolygon(
          elephant.position, _specialAreaPoints);
      return Marker(
        point: elephant.position,
        width: 80,
        height: 80,
        child: Icon(
          Icons.location_on,
          color: isHighlighted
              ? Colors.yellow[700]
              : Theme.of(context).colorScheme.secondary,
          size: isHighlighted ? 40 : 30,
        ),
      );
    }));

    if (_trainPosition != null) {
      markers.add(Marker(
        point: _trainPosition!,
        width: 80,
        height: 80,
        child: Icon(Icons.train,
            color: Theme.of(context).colorScheme.primary, size: 30),
      ));
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(7.8731, 80.7718),
        initialZoom: 9.0,
        onTap: _handleMapTap,
      ),
      children: [
        if (_currentTileLayer == 'Street')
          TileLayer(
              urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png'),
        if (_currentTileLayer == 'Satellite')
          TileLayer(
              urlTemplate:
              'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}'),
        if (_specialAreaPoints.length > 2)
          PolygonLayer(polygons: [
            Polygon(
              points: _specialAreaPoints,
              isFilled: true,
              color: Colors.yellow.withOpacity(0.2),
              borderColor: Colors.yellow[700]!,
              borderStrokeWidth: 2,
            ),
          ]),
        MarkerLayer(markers: markers),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard (${widget.user.username})'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildMap(),
          Positioned(
            top: 10,
            right: 10,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _currentTileLayer,
                    underline: Container(),
                    onChanged: (String? newValue) =>
                        setState(() => _currentTileLayer = newValue!),
                    items: ['Street', 'Satellite']
                        .map<DropdownMenuItem<String>>(
                            (String value) => DropdownMenuItem<String>(
                          value: value,
                          child: Text(value,
                              style: const TextStyle(fontSize: 14)),
                        ))
                        .toList(),
                  ),
                ),
                const SizedBox(height: 10),
                // --- FIX: Logic for drawing and clearing is now separated ---
                FloatingActionButton(
                  onPressed: () => setState(() {
                    _isDrawingMode = !_isDrawingMode;
                  }),
                  tooltip: _isDrawingMode ? 'Stop Drawing' : 'Mark Special Area',
                  backgroundColor: _isDrawingMode ? Colors.amber[800] : Theme.of(context).colorScheme.secondary,
                  child: Icon(_isDrawingMode ? Icons.pause : Icons.draw),
                ),
                const SizedBox(height: 10),
                if (_specialAreaPoints.isNotEmpty)
                  FloatingActionButton.small(
                    onPressed: () => setState(() {
                      _specialAreaPoints.clear();
                      _isDrawingMode = false;
                    }),
                    tooltip: 'Clear Marked Area',
                    backgroundColor: Colors.redAccent,
                    child: const Icon(Icons.close),
                  )
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CreateDriverScreen()),
        ),
        tooltip: 'Create Driver',
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.person_add),
      ),
    );
  }
}