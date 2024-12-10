import 'package:dio/dio.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/place.dart';

class PlacesService {
  final String apiKey = 'AIzaSyDIR8Xqw9wrMxKrUYELmblVmWiiHlOs3sM';
  final Dio _dio = Dio();

  Future<Place?> getPlaceDetails(String placeId) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?'
        'place_id=$placeId'
        '&fields=name,formatted_address,rating,opening_hours,photos,types,website,formatted_phone_number,geometry'
        '&key=$apiKey';

    try {
      final response = await _dio.get(url);
      if (response.data['status'] == 'OK') {
        final result = response.data['result'];
        final location = result['geometry']['location'];
        return Place(
          id: placeId,
          name: result['name'] ?? 'Unknown Place',
          address: result['formatted_address'] ?? '',
          rating: result['rating']?.toString(),
          phoneNumber: result['formatted_phone_number'],
          website: result['website'],
          openingHours: result['opening_hours']?['weekday_text'],
          location: LatLng(location['lat'], location['lng']),
        );
      }
    } catch (e) {
      print('Error fetching place details: $e');
    }
    return null;
  }

  Future<List<Map<String, dynamic>>> getPlaceSuggestions(String query) async {
    if (query.isEmpty) return [];
    //print(query);
    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
        'input=$query&key=$apiKey';

    try {
      final response = await _dio.get(url);
      //print(response);
      return List<Map<String, dynamic>>.from(response.data['predictions']);
    } catch (e) {
      print('Error fetching suggestions: $e');
      return [];
    }
  }

  Future<void> getPlaceFromPoint(
      LatLng location, Function(String) placeselect) async {
    print(location);
    final String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
        'location=${location.latitude},${location.longitude}'
        '&rankby=distance'
        '&key=$apiKey';
    try {
      final response = await _dio.get(url);
      if (response.data['status'] == 'OK' &&
          response.data['results'].isNotEmpty) {
        final place = response.data['results'][0];
        print(place);
        await getPlaceDetails(place['place_id']);
        placeselect(place['place_id']);
      }
    } catch (e) {
      print('Error fetching place from point: $e');
    }
  }
}
