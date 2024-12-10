import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:navlight/components.dart/placedetails.dart';

class PlaceService {
  static const String apiKey = 'AIzaSyDIR8Xqw9wrMxKrUYELmblVmWiiHlOs3sM';

  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?'
        'place_id=$placeId'
        '&fields=name,formatted_address,rating,opening_hours,photos,types,website,formatted_phone_number,geometry'
        '&key=$apiKey';

    try {
      final response = await Dio().get(url);
      if (response.data['status'] == 'OK') {
        return response.data['result'];
      }
    } catch (e) {
      print('Error fetching place details: $e');
    }
    return null;
  }

  static Future<List<Map<String, dynamic>>> getPlaceSuggestions(
      String query) async {
    if (query.isEmpty) {
      return [];
    }

    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
        'input=$query&key=$apiKey';

    try {
      final response = await Dio().get(url);
      return List<Map<String, dynamic>>.from(response.data['predictions']);
    } catch (e) {
      print('Error fetching suggestions: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getPlaceFromPoint(
      LatLng location) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
        'location=${location.latitude},${location.longitude}'
        '&rankby=distance'
        '&key=$apiKey';

    try {
      final response = await Dio().get(url);
      if (response.data['status'] == 'OK' &&
          response.data['results'].isNotEmpty) {
        return response.data['results'][0];
      }
    } catch (e) {
      print('Error fetching place from point: $e');
    }
    return null;
  }

  static void showPlaceDetails(
      BuildContext context,
      Map<String, dynamic> place,
      final LatLng? currentLocation,
      final LatLng? destinationLocation,
      final Function(LatLng, LatLng) getDirections) {
        
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaceDetails(
        place: place,
        currentLocation: currentLocation,
        destinationLocation: destinationLocation,
        getDirections: getDirections,
      ),
    );
  }
}
