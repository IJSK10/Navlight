import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

class GeoJsonMapScreen extends StatefulWidget {
  @override
  _GeoJsonMapScreenState createState() => _GeoJsonMapScreenState();
}

class _GeoJsonMapScreenState extends State<GeoJsonMapScreen> {
  late GoogleMapController mapController;
  LatLng? _currentLocation;
  LatLng? _startPoint;
  LatLng? _endPoint;
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _originController = TextEditingController();
  List<dynamic> _autocompleteResults = [];
  bool _isOriginSearch = false;
  final String _googleApiKey =
      'YOUR_GOOGLE_API_KEY'; // Replace with your API key

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Get the user's current location
  Future<void> _getCurrentLocation() async {
    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    setState(() {
      _currentLocation = LatLng(position.latitude, position.longitude);
      _startPoint = _currentLocation; // Default starting location
    });
  }

  // Fetch autocomplete suggestions
  Future<void> _fetchAutocompleteSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _autocompleteResults = [];
      });
      return;
    }

    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_googleApiKey';

    try {
      final response = await Dio().get(url);
      setState(() {
        _autocompleteResults = response.data['predictions'];
      });
    } catch (e) {
      print('Error fetching autocomplete results: $e');
    }
  }

  // Move the camera to the selected location
  void _moveCamera(LatLng location) {
    mapController.animateCamera(CameraUpdate.newCameraPosition(
      CameraPosition(target: location, zoom: 16),
    ));
  }

  // Handle destination selection
  void _selectDestination(String placeId) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?place_id=$placeId&key=$_googleApiKey';

    try {
      final response = await Dio().get(url);
      final location = response.data['results'][0]['geometry']['location'];
      LatLng destination = LatLng(location['lat'], location['lng']);

      setState(() {
        _endPoint = destination;
        _destinationController.text =
            response.data['results'][0]['formatted_address'];
        _autocompleteResults = [];
      });

      _moveCamera(destination);
      _showDirectionsModal(); // Show "Get Directions" modal
    } catch (e) {
      print('Error fetching place details: $e');
    }
  }

  // Show the directions modal
  void _showDirectionsModal() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Destination: ${_destinationController.text}'),
              subtitle: _startPoint == null
                  ? const Text('Start: Not Set')
                  : Text('Start: $_startPoint'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_startPoint == null) {
                  // Prompt to select origin if not set
                  setState(() {
                    _isOriginSearch = true;
                  });
                  Navigator.pop(context);
                } else {
                  // Proceed to show directions
                  print('Starting at: $_startPoint, Heading to: $_endPoint');
                  Navigator.pop(context);
                }
              },
              child: const Text('Get Directions'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('GeoJSON Map with Directions'),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target:
                  _currentLocation ?? LatLng(0, 0), // Default if no location
              zoom: 14,
            ),
            onMapCreated: (GoogleMapController controller) {
              mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          Positioned(
            top: 10,
            left: 10,
            right: 10,
            child: Column(
              children: [
                // Destination Search Field
                TextField(
                  controller: _destinationController,
                  decoration: InputDecoration(
                    hintText: 'Search Destination',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: _fetchAutocompleteSuggestions,
                ),
                if (_isOriginSearch)
                  // Origin Search Field (Appears when required)
                  TextField(
                    controller: _originController,
                    decoration: InputDecoration(
                      hintText: 'Search Origin',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: _fetchAutocompleteSuggestions,
                  ),
                // Autocomplete Suggestions
                if (_autocompleteResults.isNotEmpty)
                  Container(
                    color: Colors.white,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _autocompleteResults.length,
                      itemBuilder: (context, index) {
                        final suggestion = _autocompleteResults[index];
                        return ListTile(
                          title: Text(suggestion['description']),
                          onTap: () =>
                              _selectDestination(suggestion['place_id']),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
