import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:elephant_tracker_app/models/incident.dart';
import 'package:elephant_tracker_app/services/ai_service.dart';
import 'package:elephant_tracker_app/services/data_service.dart';

class IncidentListScreen extends StatefulWidget {
  const IncidentListScreen({super.key});

  @override
  _IncidentListScreenState createState() => _IncidentListScreenState();
}

class _IncidentListScreenState extends State<IncidentListScreen> {
  final DataService _dataService = DataService();
  final AIService _aiService = AIService();

  void _showGeneratedReport(BuildContext context, Incident incident) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final report = await _aiService.generateIncidentReport(incident);

    Navigator.of(context).pop(); // Close the loading dialog

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generated Incident Report'),
        content: Scrollbar(
          child: SingleChildScrollView(
            child: Text(report, style: const TextStyle(fontSize: 14)),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('High-Risk Incidents'),
      ),
      body: StreamBuilder<List<Incident>>(
        stream: _dataService.getIncidentsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No incidents have been logged.'));
          }

          final incidents = snapshot.data!;

          return ListView.builder(
            itemCount: incidents.length,
            itemBuilder: (context, index) {
              final incident = incidents[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.warning_amber, color: Colors.red),
                  title: Text(
                      '${incident.elephantCount} elephants near Train ${incident.trainId}'),
                  subtitle: Text(DateFormat('yyyy-MM-dd – kk:mm')
                      .format(incident.timestamp)),
                  trailing: ElevatedButton(
                    onPressed: () => _showGeneratedReport(context, incident),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Theme.of(context).colorScheme.onSecondary
                    ),
                    child: const Text('Report'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}