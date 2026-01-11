import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:geocoding/geocoding.dart'; // ✅ new import

class LocationService extends ChangeNotifier {
  Position? _currentPosition;
  String? _currentAddress; // ✅ store place name
  bool _isTracking = false;
  StreamSubscription<Position>? _positionStream;
  Timer? _locationTimer;
  DatabaseReference? _dbRef;

  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress; // ✅ getter
  bool get isTracking => _isTracking;

  final LocationSettings _locationSettings = const LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10,
  );

  /// Initialize Firebase Database reference
  Future<void> init() async {
    try {
      final app = Firebase.app();
      _dbRef = FirebaseDatabase.instanceFor(
        app: app,
        databaseURL: "https://bus-tracking-app-e6ddf-default-rtdb.firebaseio.com/",
      ).ref().child('buses');
    } catch (e) {
      debugPrint("Firebase init error: $e");
    }
  }

  /// Request location permissions safely
  Future<bool> requestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("❌ Location services are disabled.");
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      debugPrint("❌ Location permission permanently denied.");
      return false;
    }

    return permission == LocationPermission.whileInUse || permission == LocationPermission.always;
  }

  /// Start tracking for a specific bus
  Future<void> startTracking(String busId) async {
    if (_isTracking) return;

    bool hasPermission = await requestPermissions();
    if (!hasPermission) {
      throw Exception('Location permission denied');
    }

    if (_dbRef == null) {
      await init();
    }

    _isTracking = true;
    notifyListeners();

    _positionStream = Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    ).listen((Position position) async {
      _currentPosition = position;

      // ✅ Convert to address
      _currentAddress = await _getAddressFromLatLng(position);

      notifyListeners();
      _sendLocationToFirebase(busId, position, _currentAddress);
    });

    _locationTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
      if (_isTracking) {
        try {
          Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          _currentPosition = position;

          // ✅ Convert to address
          _currentAddress = await _getAddressFromLatLng(position);

          notifyListeners();
          _sendLocationToFirebase(busId, position, _currentAddress);
        } catch (e) {
          debugPrint("Error getting location: $e");
        }
      }
    });
  }

  /// Stop tracking
  void stopTracking() {
    _isTracking = false;
    _positionStream?.cancel();
    _locationTimer?.cancel();
    notifyListeners();
  }

  /// Send location + address to Firebase
  Future<void> _sendLocationToFirebase(String busId, Position position, String? address) async {
    if (_dbRef == null) return;
    try {
      await _dbRef!.child(busId).set({
        'latitude': position.latitude,
        'longitude': position.longitude,
        'address': address ?? "Unknown Location", // ✅ send name
        'timestamp': ServerValue.timestamp,
      });
      debugPrint("✅ Sent location for bus $busId: ${position.latitude}, ${position.longitude}, $address");
    } catch (e) {
      debugPrint("❌ Failed to send location: $e");
    }
  }

  /// Convert lat/lng → place name
  Future<String?> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        return "${place.name}, ${place.locality}, ${place.administrativeArea}";
      }
    } catch (e) {
      debugPrint("❌ Failed to get address: $e");
    }
    return null;
  }

  /// One-time location fetch (for passenger)
  Future<Position> getCurrentLocationOnce() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception("Location services are disabled.");
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permission denied.");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permissions are permanently denied.");
    }

    return await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
