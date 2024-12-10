import 'package:google_maps_flutter/google_maps_flutter.dart';

class Place {
  final String id;
  final String name;
  final String address;
  final String? rating;
  final String? phoneNumber;
  final String? website;
  final List<dynamic>? openingHours;
  final LatLng location;

  Place({
    required this.id,
    required this.name,
    required this.address,
    this.rating,
    this.phoneNumber,
    this.website,
    this.openingHours,
    required this.location,
  });
}
