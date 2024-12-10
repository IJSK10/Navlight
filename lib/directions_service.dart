import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'utils.dart';

class DirectionsService {
  static const String apiKey = 'AIzaSyDIR8Xqw9wrMxKrUYELmblVmWiiHlOs3sM';

  static Future<Map<String, dynamic>?> getDirections(
      LatLng origin, LatLng destination) async {
    print("called getDirections");
    final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
        'origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&key=$apiKey';

    try {
      final response = await Dio().get(url);
      if (response.data['status'] == 'OK' &&
          response.data['routes'].isNotEmpty) {
        final route = response.data['routes'][0];
        final leg = route['legs'][0];
        final points = decodePolyline(route['overview_polyline']['points']);

        return {
          'distance': leg['distance']['text'],
          'duration': leg['duration']['text'],
          'polyline': Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: Colors.blue,
            width: 5,
          ),
          'bounds': calculateBounds(points),
        };
      }
    } catch (e) {
      print('Error getting directions: $e');
    }
    return null;
  }
}
