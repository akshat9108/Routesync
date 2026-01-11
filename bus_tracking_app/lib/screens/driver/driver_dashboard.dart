import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/location_service.dart';
import 'tracking_screen.dart';

class DriverDashboard extends StatefulWidget {
  @override
  _DriverDashboardState createState() => _DriverDashboardState();
}

class _DriverDashboardState extends State<DriverDashboard> {
  String? _selectedBusId;
  String? _selectedRoute;

  final List<String> _buses = [
    '101',
    '102',
    '103',
    '104',
    '105'
  ];
  final List<String> _routes = [
    'City Center to Airport',
    'Railway Station to Mall',
    'University to Tech Park',
    'Hospital to Bus Stand'
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationService>(
      builder: (context, locationService, child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Driver Dashboard'),
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Bus Selection
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Bus Information',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Select Bus',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.directions_bus),
                          ),
                          value: _selectedBusId,
                          items: _buses.map((busId) {
                            return DropdownMenuItem(
                              value: busId,
                              child: Text('Bus $busId'),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedBusId = value;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Select Route',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.route),
                          ),
                          value: _selectedRoute,
                          items: _routes.map((route) {
                            return DropdownMenuItem(
                              value: route,
                              child: Text(route),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRoute = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Tracking Status
                Card(
                  elevation: 4,
                  color: locationService.isTracking ? Colors.green[50] : Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          locationService.isTracking ? Icons.gps_fixed : Icons.gps_off,
                          size: 48,
                          color: locationService.isTracking ? Colors.green : Colors.red,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          locationService.isTracking ? 'Tracking Active' : 'Tracking Inactive',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: locationService.isTracking ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                        if (locationService.isTracking && _selectedBusId != null) ...[
                          const SizedBox(height: 8),
                          Text('Bus $_selectedBusId', style: const TextStyle(fontSize: 16)),
                          Text(
                            'Route: $_selectedRoute',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                          if (locationService.currentPosition != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Lat: ${locationService.currentPosition!.latitude.toStringAsFixed(6)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                            Text(
                              'Lng: ${locationService.currentPosition!.longitude.toStringAsFixed(6)}',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Start/Stop Tracking Button
                ElevatedButton(
                  onPressed: _selectedBusId != null && _selectedRoute != null ? () => _toggleTracking(locationService) : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: locationService.isTracking ? Colors.red : Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(
                    locationService.isTracking ? 'Stop Tracking' : 'Start Tracking',
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),

                if (locationService.isTracking) ...[
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TrackingScreen(
                            busId: _selectedBusId!,
                            route: _selectedRoute!,
                          ),
                        ),
                      );
                    },
                    child: const Text('View Tracking Details'),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleTracking(LocationService locationService) async {
    if (locationService.isTracking) {
      // Stop tracking
      locationService.stopTracking();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tracking stopped')),
      );
    } else {
      // Start tracking
      try {
        await locationService.init(); // make sure Firebase is ready
        await locationService.startTracking(_selectedBusId!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Tracking started for Bus $_selectedBusId')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start tracking: $e')),
        );
      }
    }
  }
}
