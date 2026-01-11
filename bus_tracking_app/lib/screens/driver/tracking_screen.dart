import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/location_service.dart';

class TrackingScreen extends StatefulWidget {
  final String busId;
  final String route;

  TrackingScreen({required this.busId, required this.route});

  @override
  _TrackingScreenState createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  int _updateCount = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<LocationService>(
      builder: (context, locationService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Bus ${widget.busId} Tracking'),
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
          body: Column(
            children: [
              // Status Bar
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                color: Colors.green[100],
                child: Row(
                  children: [
                    Icon(Icons.gps_fixed, color: Colors.green),
                    SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tracking Active - Bus ${widget.busId}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Route: ${widget.route}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'LIVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Location Info
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Current Location Card
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: Colors.blue),
                                  SizedBox(width: 8),
                                  Text(
                                    'Current Location',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              if (locationService.currentPosition != null) ...[
                                Text(
                                  'Latitude: ${locationService.currentPosition!.latitude.toStringAsFixed(6)}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  'Longitude: ${locationService.currentPosition!.longitude.toStringAsFixed(6)}',
                                  style: TextStyle(fontSize: 16),
                                ),
                                Text(
                                  'Accuracy: ${locationService.currentPosition!.accuracy.toStringAsFixed(1)}m',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                              ] else ...[
                                Text(
                                  'Getting location...',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      SizedBox(height: 16),

                      // Stats Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Updates Sent',
                              _updateCount.toString(),
                              Icons.update,
                              Colors.blue,
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: _buildStatCard(
                              'Status',
                              locationService.isTracking ? 'Active' : 'Inactive',
                              Icons.radio_button_checked,
                              locationService.isTracking ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Map Placeholder
                      Expanded(
                        child: Card(
                          elevation: 4,
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.map,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Map View',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  'Google Maps integration coming soon',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
