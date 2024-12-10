import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import '../models/directions.dart';

class DirectionsService {
  final String apiKey = 'AIzaSyDIR8Xqw9wrMxKrUYELmblVmWiiHlOs3sM';
  final Dio _dio = Dio();

  /// Get directions for multiple travel modes
  Future<Map<String, Directions>> getDirections({
    required LatLng origin,
    required LatLng destination,
  }) async {
    // Define travel modes to retrieve
    final modes = ['driving', 'walking'];

    // Store results for different modes
    Map<String, Directions> directionResults = {};

    // Fetch directions for each mode
    for (String mode in modes) {
      final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
          'origin=${origin.latitude},${origin.longitude}'
          '&destination=${destination.latitude},${destination.longitude}'
          '&mode=$mode'
          '&key=$apiKey';

      try {
        final response = await _dio.get(url);
        if (response.data['status'] == 'OK' &&
            response.data['routes'].isNotEmpty) {
          final route = response.data['routes'][0];
          final leg = route['legs'][0];
          final points = _decodePolyline(route['overview_polyline']['points']);

          directionResults[mode] = Directions(
            distance: leg['distance']['text'],
            duration: leg['duration']['text'],
            polylines: {
              Polyline(
                polylineId: PolylineId('route_$mode'),
                points: points,
                color: _getColorForMode(mode),
                width: 5,
              ),
            },
            bounds: _calculateBounds(points),
          );
        }
      } catch (e) {
        print('Error getting $mode directions: $e');
        directionResults[mode] = Directions.empty();
      }
    }

    return directionResults;
  }

  /// Choose color based on travel mode
  Color _getColorForMode(String mode) {
    switch (mode) {
      case 'driving':
        return Colors.blue;
      case 'walking':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Previous methods remain the same
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  LatLngBounds _calculateBounds(List<LatLng> points) {
    double? minLat, maxLat, minLng, maxLng;

    for (LatLng point in points) {
      if (minLat == null || point.latitude < minLat) minLat = point.latitude;
      if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
      if (minLng == null || point.longitude < minLng) minLng = point.longitude;
      if (maxLng == null || point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }
}
