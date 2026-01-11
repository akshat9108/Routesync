import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:latlong2/latlong.dart';
import '../firebase_options.dart';

class PassengerLocationService extends ChangeNotifier {
  DatabaseReference? _dbRef;
  LatLng? _busPosition;
  String? _busAddress;

  LatLng? get busPosition => _busPosition;
  String? get busAddress => _busAddress;

  /// Initialize Firebase Database reference
  Future<void> init() async {
    try {
      final app = Firebase.app();

      // ✅ Use database from options
      _dbRef = FirebaseDatabase.instanceFor(
        app: app,
        databaseURL: "https://bus-tracking-app-e6ddf-default-rtdb.firebaseio.com",
      ).ref().child('buses');
    } catch (e) {
      debugPrint("Firebase init error (passenger): $e");
    }
  }

  /// Listen for real-time updates of a specific bus
  void listenToBus(String busId) {
    if (_dbRef == null) return;

    _dbRef!.child(busId).onValue.listen((event) {
      final data = event.snapshot.value as Map?;
      if (data != null) {
        final lat = (data['latitude'] as num).toDouble();
        final lng = (data['longitude'] as num).toDouble();
        final address = data['address'] as String?;

        _busPosition = LatLng(lat, lng);
        _busAddress = address ?? "Unknown Location";

        notifyListeners();
        debugPrint("📍 Bus $busId is at $lat, $lng → $_busAddress");
      }
    });
  }
}
