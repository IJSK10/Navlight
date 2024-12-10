import 'package:google_maps_flutter/google_maps_flutter.dart';

class Directions {
  final String? distance;
  final String? duration;
  final Set<Polyline> polylines;
  final LatLngBounds? bounds;

  Directions({
    this.distance,
    this.duration,
    required this.polylines,
    this.bounds,
  });

  factory Directions.empty() {
    return Directions(polylines: {});
  }
}
