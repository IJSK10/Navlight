import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:dio/dio.dart';
import '../models/directions.dart';
import 'package:navlight/services/indoorpath.dart';

class DirectionsService {
  final String apiKey = 'AIzaSyDIR8Xqw9wrMxKrUYELmblVmWiiHlOs3sM';
  final Dio _dio = Dio();
  final List<LatLng> navlightCorners = const [
    LatLng(40.913834438241999, -73.125762270213727),
    LatLng(40.913313583257121, -73.125867512935272),
    LatLng(40.913221575512978, -73.125068906401154),
    LatLng(40.913748668990792, -73.124959536514041)
  ];

  bool isPointInBuilding(LatLng point, List<LatLng> buildingCorners) {
    int intersectCount = 0;

    for (int i = 0; i < buildingCorners.length; i++) {
      LatLng current = buildingCorners[i];
      LatLng next = buildingCorners[(i + 1) % buildingCorners.length];

      // Debugging output to inspect the edges and calculations
      //print('Edge from $current to $next');
      //print('Point: $point');
      //print(
      //'Latitude Check: ${(current.latitude <= point.latitude && point.latitude < next.latitude) || (next.latitude <= point.latitude && point.latitude < current.latitude)}');
      if ((current.latitude <= point.latitude &&
              point.latitude < next.latitude) ||
          (next.latitude <= point.latitude &&
              point.latitude < current.latitude)) {
        double intersectionLongitude = (next.longitude - current.longitude) *
                (point.latitude - current.latitude) /
                (next.latitude - current.latitude) +
            current.longitude;

        // print('Intersection Longitude: $intersectionLongitude');
        if (point.longitude < intersectionLongitude) {
          intersectCount++;
        }
      }
    }

    //print('Intersect Count: $intersectCount');
    return intersectCount % 2 == 1; // Odd means inside, even means outside
  }

  Future<Map<String, Directions>> getDirections({
    required LatLng origin,
    required LatLng destination,
    // List<LatLng>? buildingCorners, // Optional building corners for indoor check
  }) async {
    origin = const LatLng(
      40.91369619883824,
      -73.12566474820164,
    );
    // Check if both points are inside the building (if building corners provided)
    bool ori = await isPointInBuilding(origin, navlightCorners);
    bool dest = await isPointInBuilding(destination, navlightCorners);
    final indoorPathfinder = IndoorPathfinder();
    await indoorPathfinder.loadPathwayGraph();
    Map<String, Directions> directionResults = {};
    bool isIndoorNavigation = ori && dest;
    if (isIndoorNavigation) {
      try {
        // Use indoor pathfinder for indoor navigation
        final indoorDirections =
            await indoorPathfinder.findShortestPath(origin, destination);
        directionResults['walking'] = indoorDirections;
        directionResults['driving'] = indoorDirections;

        return directionResults;
      } catch (e) {
        print('Indoor navigation error: $e');
        // Fallback to Google Directions if indoor navigation fails
        return await _fetchGoogleDirections(origin, destination);
      }
    } else {
      // Use Google Directions for outdoor or mixed navigation
      return await _fetchGoogleDirections(origin, destination);
    }
  }

  String _estimateIndoorDuration(List<latlong.LatLng> path) {
    // Assuming average walking speed indoors
    const double walkingSpeedMps = 1.4; // meters per second
    const latlong.Distance distanceCalculator = latlong.Distance();

    double totalDistance = 0;
    for (int i = 0; i < path.length - 1; i++) {
      totalDistance += distanceCalculator.as(
          latlong.LengthUnit.Kilometer, path[i], path[i + 1]);
    }

    int durationSeconds = ((totalDistance * 1000) / walkingSpeedMps).round();
    int minutes = durationSeconds ~/ 60;
    int seconds = durationSeconds % 60;

    return '$minutes min $seconds sec';
  }

  String _calculateIndoorDistance(List<latlong.LatLng> path) {
    const latlong.Distance distanceCalculator = latlong.Distance();
    double totalDistance = 0;

    for (int i = 0; i < path.length - 1; i++) {
      totalDistance += distanceCalculator.as(
          latlong.LengthUnit.Kilometer, path[i], path[i + 1]);
    }

    return '${(totalDistance * 1000).toStringAsFixed(0)} m';
  }

  Future<Map<String, Directions>> _fetchGoogleDirections(
      LatLng origin, LatLng destination) async {
    final modes = ['driving', 'walking'];
    Map<String, Directions> directionResults = {};

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
