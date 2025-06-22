import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:elephant_tracker_app/models/app_user.dart';
import 'package:elephant_tracker_app/models/elephant.dart';
import 'package:elephant_tracker_app/services/data_service.dart';
import 'package:elephant_tracker_app/views/admin/create_driver_screen.dart'; // Import the new screen

class AdminDashboardScreen extends StatefulWidget {
  final AppUser user;
  const AdminDashboardScreen({super.key, required this.user});

  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final DataService _dataService = DataService();
  List<Elephant> _elephants = [];

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  void _fetchData() async {
    // This now uses the live stream from the service
    _dataService.getElephantsStream().listen((elephants) {
      if (mounted) {
        setState(() {
          _elephants = elephants;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Admin Dashboard (${widget.user.username})')),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(7.8731, 80.7718),
          initialZoom: 9.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          MarkerLayer(
            markers: _elephants.map((elephant) {
              return Marker(
                width: 80.0,
                height: 80.0,
                point: elephant.position,
                child: const Icon(Icons.location_on, color: Colors.purple, size: 40),
              );
            }).toList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the new CreateDriverScreen
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateDriverScreen()),
          );
        },
        tooltip: 'Create Driver',
        child: const Icon(Icons.person_add),
      ),
    );
  }
}