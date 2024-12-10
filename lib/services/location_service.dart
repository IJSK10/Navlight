import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final LatLng? location;
  final String? error;

  LocationResult({this.location, this.error});
}

class LocationService {
  Future<LocationResult> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationResult(
        error: 'Location services are disabled. Please enable them.',
      );
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return LocationResult(error: 'Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return LocationResult(
        error: 'Location permissions are permanently denied',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      return LocationResult(
        location: LatLng(position.latitude, position.longitude),
      );
    } catch (e) {
      return LocationResult(error: 'Error getting location: $e');
    }
  }
}
