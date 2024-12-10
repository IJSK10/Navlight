import 'package:google_maps_flutter/google_maps_flutter.dart';

List<LatLng> decodePolyline(String encoded) {
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

LatLngBounds calculateBounds(List<LatLng> points) {
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
