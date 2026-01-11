import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const RouteSyncPassenger());
}

class RouteSyncPassenger extends StatelessWidget {
  const RouteSyncPassenger({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RouteSync Passenger',
      theme: ThemeData(fontFamily: 'Montserrat', primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: const LandingPage(),
    );
  }
}

// ----------------- LANDING PAGE -----------------
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
    _animation = Tween<double>(begin: -20, end: 20).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildButton(String text, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF6D5DF6),
              Color(0xFF46C2FF)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 12, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF1A2A6C),
              Color(0xFFb21f1f),
              Color(0xFFfdbb2d)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _animation,
                builder: (context, child) {
                  return Transform.translate(offset: Offset(_animation.value, 0), child: child);
                },
                child: const Icon(Icons.directions_bus, size: 120, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text("RouteSync", style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
              const SizedBox(height: 8),
              const Text("Track your bus in real-time", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white70)),
              const SizedBox(height: 60),
              _buildButton("Chat with Assistant", Icons.chat, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatPage()));
              }),
              _buildButton("View Map", Icons.map, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const MapPage()));
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------- CHAT PAGE -----------------
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final List<Map<String, String>> _messages = [];

  LatLng _driver = LatLng(20.5937, 78.9629);
  LatLng _passenger = LatLng(20.591, 78.965);

  final channel = WebSocketChannel.connect(Uri.parse('ws://10.0.46.137:8080')); // change IP

  @override
  void initState() {
    super.initState();

    channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['id'] == 'driver_1') {
        setState(() {
          _driver = LatLng(data['lat'], data['lng']);
        });
        _addMessage("Driver Update", "Driver: ${data['lat'].toStringAsFixed(4)}, ${data['lng'].toStringAsFixed(4)}");
      }
    });

    _initPassengerLocation();
  }

  Future<void> _initPassengerLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Geolocator.getPositionStream(locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10)).listen((Position position) {
      setState(() {
        _passenger = LatLng(position.latitude, position.longitude);
      });
    });
  }

  void _addMessage(String user, String bot) {
    setState(() {
      _messages.add({
        'user': user,
        'bot': bot
      });
    });
  }

  void _sendLocationButton() {
    _addMessage(
        "Get locations",
        "Driver: ${_driver.latitude.toStringAsFixed(4)}, ${_driver.longitude.toStringAsFixed(4)} | "
            "Passenger: ${_passenger.latitude.toStringAsFixed(4)}, ${_passenger.longitude.toStringAsFixed(4)}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Chat Assistant"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF6D5DF6),
              Color(0xFF46C2FF),
              Color(0xFF00FFF7)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    return Column(
                      children: [
                        if (msg['user']!.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(msg['user']!, style: const TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        if (msg['bot']!.isNotEmpty)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[300],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(msg['bot']!, style: const TextStyle(color: Colors.black87)),
                                ),
                              ),
                            ],
                          ),
                      ],
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Wrap(
                  spacing: 12,
                  children: [
                    ElevatedButton(
                      onPressed: () => _addMessage("Where is the bus?", "Bus is near XYZ"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurpleAccent, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                      child: const Text("Bus Location"),
                    ),
                    ElevatedButton(
                      onPressed: () => _addMessage("Show bus route", "Bus route is traced"),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                      child: const Text("Route Info"),
                    ),
                    ElevatedButton(
                      onPressed: _sendLocationButton,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                      child: const Text("Driver & Passenger"),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ----------------- MAP PAGE -----------------
class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  LatLng? _passenger; // start null until GPS found
  LatLng _driver = LatLng(20.5937, 78.9629);

  final channel = WebSocketChannel.connect(Uri.parse('ws://10.0.46.137:8080'));

  @override
  void initState() {
    super.initState();
    channel.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['id'] == 'driver_1') {
        setState(() {
          _driver = LatLng(data['lat'], data['lng']);
        });
      }
    });
    _initPassengerLocation();
  }

  Future<void> _initPassengerLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    // Get the most accurate current position
    Position pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.bestForNavigation,
      timeLimit: const Duration(seconds: 5),
    );

    setState(() {
      _passenger = LatLng(pos.latitude, pos.longitude);
    });

    // Listen for updates
    Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      setState(() {
        _passenger = LatLng(position.latitude, position.longitude);
      });
    });
  }

  void _centerOnPassenger() {
    if (_passenger != null) {
      _mapController.move(_passenger!, 17); // use ! since we checked for null
    } else {
      debugPrint("Passenger location not available yet");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Bus Map")),
      body: _passenger == null
          ? const Center(child: CircularProgressIndicator())
          : FlutterMap(
              mapController: _mapController,
              options: MapOptions(initialCenter: _passenger!, initialZoom: 15),
              children: [
                TileLayer(
                  urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                  userAgentPackageName: "com.example.bus_tracking_app",
                ),
                MarkerLayer(markers: [
                  Marker(
                    point: _driver,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.directions_bus, color: Colors.red, size: 36),
                  ),
                  Marker(
                    point: _passenger!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.person_pin_circle, color: Colors.blue, size: 36),
                  ),
                ]),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _centerOnPassenger,
        backgroundColor: Colors.deepPurple,
        child: const Icon(Icons.my_location),
      ),
    );
  }
}
