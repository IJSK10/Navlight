import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';

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
  final Set<Polyline> _polylines = {};

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

        markers.clear();
        markers.add(
          Marker(
            markerId: const MarkerId('currentLocation'),
            position: currentLocation!,
            infoWindow: const InfoWindow(title: 'You are here'),
          ),
        );
      });

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

  Future<void> getPlaceDetails(String placeId) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?'
        'place_id=$placeId'
        '&fields=name,formatted_address,rating,opening_hours,photos,types,website,formatted_phone_number,geometry'
        '&key=$apiKey';

    try {
      final response = await Dio().get(url);
      if (response.data['status'] == 'OK') {
        final place = response.data['result'];
        final location = place['geometry']['location'];
        destinationLocation = LatLng(location['lat'], location['lng']);

        // Update markers
        setState(() {
          markers
              .removeWhere((marker) => marker.markerId.value == 'destination');
          markers.add(
            Marker(
              markerId: const MarkerId('destination'),
              position: destinationLocation!,
              infoWindow: InfoWindow(title: place['name']),
            ),
          );
        });

        // Add to recent searches
        if (!recentSearches.contains(place['name'])) {
          setState(() {
            recentSearches.insert(0, place['name']);
            if (recentSearches.length > 5) {
              recentSearches.removeLast();
            }
          });
        }

        // Show place details bottom sheet
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.2,
            maxChildSize: 0.8,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: scrollController,
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
                  // Place name
                  Text(
                    place['name'] ?? 'Unknown Place',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Rating
                  if (place['rating'] != null)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        Text(
                          ' ${place['rating']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  // Address
                  Text(
                    place['formatted_address'] ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  // Phone number
                  if (place['formatted_phone_number'] != null)
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: Text(place['formatted_phone_number']),
                      onTap: () async {
                        final url = 'tel:${place['formatted_phone_number']}';
                        if (await canLaunchUrl(Uri.parse(url))) {
                          await launchUrl(Uri.parse(url));
                        }
                      },
                    ),
                  // Opening hours
                  if (place['opening_hours']?['weekday_text'] != null)
                    ExpansionTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Opening Hours'),
                      children: [
                        ...place['opening_hours']['weekday_text']
                            .map<Widget>((hours) => Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(hours),
                                ))
                            .toList(),
                      ],
                    ),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          if (currentLocation != null &&
                              destinationLocation != null) {
                            _getDirections(
                                currentLocation!, destinationLocation!);
                          }
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('Directions'),
                      ),
                      if (place['website'] != null)
                        ElevatedButton.icon(
                          onPressed: () async {
                            if (await canLaunchUrl(
                                Uri.parse(place['website']))) {
                              await launchUrl(
                                Uri.parse(place['website']),
                                mode: LaunchMode.externalApplication,
                              );
                            }
                          },
                          icon: const Icon(Icons.language),
                          label: const Text('Website'),
                        ),
                      ElevatedButton.icon(
                        onPressed: () {
                          // Share place details
                          final text = '${place['name']}\n'
                              '${place['formatted_address']}\n'
                              'Rating: ${place['rating'] ?? 'N/A'}\n'
                              '${place['website'] ?? ''}';
                          Share.share(text);
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        // Animate camera to show the place
        if (mapController != null) {
          await mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(
              destinationLocation!,
              15,
            ),
          );
        }
      }
    } catch (e) {
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching place details: $e'),
          backgroundColor: Colors.red,
        ),
      );
      debugPrint('Error fetching place details: $e');
    }
  }

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
      setState(() => suggestions = response.data['predictions']);
    } catch (e) {
      debugPrint('Error fetching suggestions: $e');
    }
  }

  Future<void> getPlaceFromPoint(LatLng location) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
        'location=${location.latitude},${location.longitude}'
        '&rankby=distance' // Use rankby to include places ordered by distance
        '&key=$apiKey';
    try {
      final response = await Dio().get(url);
      print(response.data['results'][0]);
      if (response.data['status'] == 'OK' &&
          response.data['results'].isNotEmpty) {
        // Get the closest place
        final place = response.data['results'][0];
        showPlaceDetails(place['place_id']);
      }
    } catch (e) {
      debugPrint('Error fetching place from point: $e');
    }
  }

  Future<void> showPlaceDetails(String placeId) async {
    final String url =
        'https://maps.googleapis.com/maps/api/place/details/json?'
        'place_id=$placeId'
        '&fields=name,formatted_address,rating,opening_hours,photos,types,website,formatted_phone_number,geometry'
        '&key=$apiKey';

    try {
      final response = await Dio().get(url);
      if (response.data['status'] == 'OK') {
        final place = response.data['result'];
        final location = place['geometry']['location'];
        destinationLocation = LatLng(location['lat'], location['lng']);

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => DraggableScrollableSheet(
            initialChildSize: 0.4,
            minChildSize: 0.2,
            maxChildSize: 0.8,
            builder: (context, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: scrollController,
                children: [
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
                    place['name'] ?? 'Unknown Place',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (place['rating'] != null)
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        Text(
                          ' ${place['rating']}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Text(
                    place['formatted_address'] ?? '',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  if (place['formatted_phone_number'] != null)
                    ListTile(
                      leading: const Icon(Icons.phone),
                      title: Text(place['formatted_phone_number']),
                    ),
                  if (place['opening_hours']?['weekday_text'] != null)
                    ExpansionTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Opening Hours'),
                      children: [
                        ...place['opening_hours']['weekday_text']
                            .map<Widget>((hours) => Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(hours),
                                ))
                            .toList(),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          if (currentLocation != null &&
                              destinationLocation != null) {
                            _getDirections(
                                currentLocation!, destinationLocation!);
                          }
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.directions),
                        label: const Text('Directions'),
                      ),
                      if (place['website'] != null)
                        ElevatedButton.icon(
                          onPressed: () {
                            // Add website handling
                          },
                          icon: const Icon(Icons.language),
                          label: const Text('Website'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error fetching place details: $e');
    }
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

        setState(() {
          routeDistance = leg['distance']['text'];
          routeDuration = leg['duration']['text'];
          isRouteVisible = true;
        });

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

        if (points.isNotEmpty) {
          LatLngBounds bounds = _calculateBounds(points);
          mapController?.animateCamera(
            CameraUpdate.newLatLngBounds(bounds, 50),
          );
        }
      }
    } catch (e) {
      debugPrint('Error getting directions: $e');
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

  //

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
            onMapCreated: (GoogleMapController controller) {
              setState(() {
                mapController = controller;
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
            },
            initialCameraPosition: CameraPosition(
              target: currentLocation ?? const LatLng(0, 0),
              zoom: 15,
            ),
            markers: markers,
            polylines: _polylines, // Add this line
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onTap: (LatLng position) {
              getPlaceFromPoint(position);
            },
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
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4,
                      ),
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
                        // physics: const ClampingScrollPhysics(),
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
                                onTap: () {
                                  getPlaceDetails(suggestion['place_id']);
                                  setState(() => suggestions = []);
                                  searchController.clear();
                                },
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
