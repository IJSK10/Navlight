import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? mapController;
  final TextEditingController searchController = TextEditingController();
  final List<String> recentSearches = [];
  List<dynamic> suggestions = [];
  Set<Marker> markers = {};
  Set<Polyline> _polylines = {};
  LatLng? destinationLocation;

  String? routeDistance;
  String? routeDuration;
  bool isRouteVisible = false;

  final String apiKey = 'AIzaSyDIR8Xqw9wrMxKrUYELmblVmWiiHlOs3sM';

  LatLng? currentLocation;
  bool isLoadingLocation = true;
  String locationError = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  // Check and request location permissions
  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        locationError = 'Location services are disabled. Please enable them.';
        isLoadingLocation = false;
      });
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          locationError = 'Location permissions are denied';
          isLoadingLocation = false;
        });
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        locationError = 'Location permissions are permanently denied';
        isLoadingLocation = false;
      });
      return false;
    }

    return true;
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();

    if (!hasPermission) return;

    try {
      final Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      setState(() {
        currentLocation = LatLng(position.latitude, position.longitude);
        isLoadingLocation = false;
        locationError = '';

        // Update markers
        markers.clear();
        markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: currentLocation!,
            infoWindow: const InfoWindow(title: 'You are here'),
          ),
        );
      });

      // Only move camera if controller is initialized
      if (mapController != null) {
        await mapController!.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: currentLocation!,
              zoom: 15,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        locationError = 'Error getting location: $e';
        isLoadingLocation = false;
      });
    }
  }

  void onMapCreated(GoogleMapController controller) {
    setState(() {
      mapController = controller;
      // If location is already available, move camera
      if (currentLocation != null) {
        controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: currentLocation!,
              zoom: 15,
            ),
          ),
        );
      }
    });
  }

  // Rest of the methods remain same as before
  Future<void> getPlaceSuggestions(String query) async {
    if (query.isEmpty) {
      setState(() => suggestions = []);
      return;
    }

    final String url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
        'input=$query&key=$apiKey';

    try {
      final response = await Dio().get(url);
      print("suggestions");
      print(response.data);
      setState(() => suggestions = response.data['predictions']);
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    }
  }

  Future<void> getPlaceDetails(String placeId) async {
    if (mapController == null) return; // Add this check

    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?'
        'place_id=$placeId&fields=name,formatted_address,geometry,photos&key=$apiKey';

    try {
      final response = await Dio().get(url);
      final result = response.data['result'];
      final location = result['geometry']['location'];
      final LatLng placeLatLng = LatLng(location['lat'], location['lng']);

      if (!recentSearches.contains(result['formatted_address'])) {
        setState(() {
          recentSearches.insert(0, result['formatted_address']);
          if (recentSearches.length > 5) recentSearches.removeLast();
        });
      }

      setState(() {
        markers.clear();
        // Add back the current location marker
        if (currentLocation != null) {
          markers.add(
            Marker(
              markerId: const MarkerId('currentLocation'),
              position: currentLocation!,
              infoWindow: const InfoWindow(title: 'You are here'),
            ),
          );
        }
        // Add the searched place marker
        markers.add(
          Marker(
            markerId: MarkerId(placeId),
            position: placeLatLng,
            infoWindow: InfoWindow(
              title: result['name'],
              snippet: result['formatted_address'],
            ),
          ),
        );
      });

      await mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: placeLatLng, zoom: 15),
        ),
      );

      showPlaceDetails(result);
      searchController.clear();
      setState(() => suggestions = []);
    } catch (e) {
      debugPrint('Error fetching place details: $e');
    }
  }

  void showPlaceDetails(Map<String, dynamic> placeDetails) {
    final location = placeDetails['geometry']['location'];
    destinationLocation = LatLng(location['lat'], location['lng']);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // This allows the modal to be draggable
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.3,
        minChildSize: 0.2,
        maxChildSize: 0.8,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                placeDetails['name'] ?? '',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                placeDetails['formatted_address'] ?? '',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (currentLocation != null && destinationLocation != null) {
                    print("pressed getdirections");
                    _getDirections(currentLocation!, destinationLocation!);
                  }
                  Navigator.pop(context);
                },
                child: const Text('Get Directions'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getDirections(LatLng origin, LatLng destination) async {
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

        // Get distance and duration
        setState(() {
          routeDistance = leg['distance']['text'];
          routeDuration = leg['duration']['text'];
          isRouteVisible = true;
        });

        // Decode polyline points
        final points = _decodePolyline(route['overview_polyline']['points']);

        setState(() {
          _polylines.clear();
          _polylines.add(Polyline(
            polylineId: const PolylineId('route'),
            points: points,
            color: Colors.blue,
            width: 5,
          ));
        });

        // Adjust camera to show the entire route
        if (points.isNotEmpty) {
          LatLngBounds bounds = _calculateBounds(points);
          mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 50),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not find route: ${response.data['status']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error getting directions: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error getting directions: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _clearRoute() {
    setState(() {
      _polylines.clear();
      routeDistance = null;
      routeDuration = null;
      isRouteVisible = false;
    });
  }

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

  @override
  Widget build(BuildContext context) {
    // Show loading indicator while getting location
    if (isLoadingLocation) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Show error if location permission denied or error occurred
    if (locationError.isNotEmpty) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(locationError),
              ElevatedButton(
                onPressed: _getCurrentLocation,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: onMapCreated,
            initialCameraPosition: CameraPosition(
              target: currentLocation ?? const LatLng(0, 0),
              zoom: 15,
            ),
            markers: markers,
            polylines: _polylines, // Add this line
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search places...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  searchController.clear();
                                  setState(() => suggestions = []);
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: getPlaceSuggestions,
                    ),
                  ),
                  if (suggestions.isNotEmpty ||
                      (searchController.text.isEmpty &&
                          recentSearches.isNotEmpty))
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: ListView(
                        shrinkWrap: true,
                        physics: const ClampingScrollPhysics(),
                        children: [
                          if (searchController.text.isEmpty &&
                              recentSearches.isNotEmpty) ...[
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'Recent Searches',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            ...recentSearches.map(
                              (search) => ListTile(
                                leading: const Icon(Icons.history),
                                title: Text(search),
                                onTap: () {
                                  searchController.text = search;
                                  getPlaceSuggestions(search);
                                },
                              ),
                            ),
                          ],
                          if (suggestions.isNotEmpty)
                            ...suggestions.map(
                              (suggestion) => ListTile(
                                leading: const Icon(Icons.location_on),
                                title: Text(suggestion['description']),
                                onTap: () => getPlaceDetails(
                                  suggestion['place_id'],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  if (isRouteVisible &&
                      routeDistance != null &&
                      routeDuration != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        color: Colors.white,
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.directions_car,
                                            size: 20),
                                        const SizedBox(width: 8),
                                        Text(
                                          routeDuration!,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      routeDistance!,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                ElevatedButton(
                                  onPressed: _clearRoute,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Clear Route'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
