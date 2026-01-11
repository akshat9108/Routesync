import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../services/passenger_location_service.dart';

class PassengerMapScreen extends StatefulWidget {
  final String busId;
  const PassengerMapScreen({Key? key, required this.busId}) : super(key: key);

  @override
  State<PassengerMapScreen> createState() => _PassengerMapScreenState();
}

class _PassengerMapScreenState extends State<PassengerMapScreen> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    final locationService = Provider.of<PassengerLocationService>(context, listen: false);
    locationService.init().then((_) {
      locationService.listenToBus(widget.busId);
    });
  }

  void _moveMap(LatLng point) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mapController.move(point, 15.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PassengerLocationService>(
      builder: (context, locationService, child) {
        final busPos = locationService.busPosition;
        final busLatLng = busPos != null ? LatLng(busPos.latitude, busPos.longitude) : null;

        if (busLatLng != null) {
          _moveMap(busLatLng);
        }

        return Scaffold(
          appBar: AppBar(title: const Text("RouteSync - Passenger")),
          body: busLatLng == null ? const Center(child: CircularProgressIndicator()) : _buildMap(busLatLng),
          bottomSheet: busLatLng != null ? _buildBottomSheet(locationService, busLatLng) : null,
        );
      },
    );
  }

  Widget _buildMap(LatLng busLatLng) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialZoom: 15.0,
        initialCenter: busLatLng,
      ),
      children: [
        TileLayer(
          urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
          subdomains: const [
            'a',
            'b',
            'c'
          ],
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: busLatLng,
              width: 40,
              height: 40,
              child: const Icon(
                Icons.directions_bus,
                color: Colors.blue,
                size: 40,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBottomSheet(PassengerLocationService locationService, LatLng busLatLng) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(12),
      child: Text(
        "Bus Location: ${locationService.busAddress ?? "Unknown"}\n"
        "Lat: ${busLatLng.latitude}, Lng: ${busLatLng.longitude}",
        style: const TextStyle(fontSize: 16),
      ),
    );
  }
}
