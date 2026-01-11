import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const DriverApp());
}

class DriverApp extends StatelessWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Driver Location',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Montserrat',
      ),
      home: const DriverHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> with TickerProviderStateMixin {
  String _location = "Unknown";
  bool _isLoading = false;

  late AnimationController _bgController;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;
  late AnimationController _pulseController;
  late AnimationController _rippleController;

  // WebSocket
  final channel = WebSocketChannel.connect(
    Uri.parse('ws://10.0.46.137:8080'), // Replace with your server IP
  );

  final String driverId = "driver_1";

  Timer? _trackingTimer;

  @override
  void initState() {
    super.initState();

    // Smooth background animation
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 5))..repeat(reverse: true);
    _color1 = ColorTween(begin: Colors.indigo.shade700, end: Colors.purple.shade400).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));
    _color2 = ColorTween(begin: Colors.blue.shade300, end: Colors.pink.shade300).animate(CurvedAnimation(parent: _bgController, curve: Curves.easeInOut));

    // Button pulse
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2), lowerBound: 0.95, upperBound: 1.05)..repeat(reverse: true);

    // Ripple effect
    _rippleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    // Start automatic location tracking every 5 seconds
    _startAutoTracking();
  }

  void _startAutoTracking() {
    _trackingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _sendLocation();
    });
  }

  @override
  void dispose() {
    _bgController.dispose();
    _pulseController.dispose();
    _rippleController.dispose();
    _trackingTimer?.cancel();
    channel.sink.close();
    super.dispose();
  }

  Future<void> _sendLocation() async {
    _rippleController.forward(from: 0);
    setState(() => _isLoading = true);

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _location = "Location services are disabled.";
        _isLoading = false;
      });
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _location = "Location permissions are denied";
          _isLoading = false;
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _location = "Location permissions are permanently denied.";
        _isLoading = false;
      });
      return;
    }

    Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    setState(() {
      _location = "Lat: ${pos.latitude.toStringAsFixed(4)}, Lng: ${pos.longitude.toStringAsFixed(4)}";
      _isLoading = false;
    });

    final locationData = {
      'id': driverId,
      'lat': pos.latitude,
      'lng': pos.longitude,
      'timestamp': DateTime.now().toIso8601String(),
    };
    channel.sink.add(jsonEncode(locationData));
    print("Sent: $locationData");
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            title: const Text("Driver App"),
            elevation: 0,
            backgroundColor: Colors.transparent,
          ),
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _color1.value!,
                  _color2.value!
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Location display
                  if (_isLoading)
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    )
                  else
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        _location,
                        key: ValueKey<String>(_location),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 50),

                  // Pulse + ripple button
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _rippleController,
                        builder: (context, child) {
                          double scale = 1 + _rippleController.value * 2.0;
                          double opacity = 1 - _rippleController.value;
                          return Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: opacity,
                              child: Container(
                                width: 140,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      ScaleTransition(
                        scale: _pulseController,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.deepPurple,
                            elevation: 12,
                          ),
                          onPressed: _sendLocation,
                          child: const Text(
                            "Send Location",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
