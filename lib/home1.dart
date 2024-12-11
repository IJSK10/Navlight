import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:navlight/models/place.dart';
import 'package:navlight/widgets/navigation_guidance_widget.dart';
import 'package:navlight/widgets/route_selection_widget.dart';
import '../../services/location_service.dart';
import '../../services/places_service.dart';
import '../../services/directions_service.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/place_details_sheet.dart';
import 'package:geolocator/geolocator.dart';
import 'package:navlight/services/navigation_service.dart';
import 'package:navlight/services/location_orientation_service.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:permission_handler/permission_handler.dart';

class HomeScreen1 extends StatefulWidget {
  const HomeScreen1({super.key});

  @override
  State<HomeScreen1> createState() => _MapScreenState();
}

class _MapScreenState extends State<HomeScreen1> {
  final LocationService _locationService = LocationService();
  final PlacesService _placesService = PlacesService();
  final DirectionsService _directionsService = DirectionsService();

  GoogleMapController? mapController;
  final TextEditingController searchController = TextEditingController();
  final List<String> recentSearches = [];
  List<dynamic> suggestions = [];
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};
  Set<Polygon> polygons = {};
  List<String> roomname = [];
  Map<String, LatLng> roomlocation = {};

  LatLng? destinationLocation;
  LatLng? currentLocation;
  bool isLoadingLocation = true;
  String locationError = '';

  Map<String, dynamic> routeOptions = {};
  String? selectedRouteMode;
  String? routeDistance;
  String? routeDuration;
  bool isRouteVisible = false;

  bool isNavigating = false;
  String currentNavigationInstruction = 'Start navigation';
  String remainingDistance = '0 km';
  String remainingDuration = '0 min';

  StreamSubscription<Position>? _locationSubscription;
  Position? _currentPosition;
  List<LatLng> _currentRoutePoints = [];
  double _currentBearing = 0.0;

  double _compassHeading = 0.0;
  StreamSubscription<CompassEvent>? _compassSubscription;

  double _smoothedHeading = 0.0;
  double _lastHeading = 0.0;
  DateTime _lastUpdateTime = DateTime.now();
  final LocationOrientationService _locationOrientationService =
      LocationOrientationService();
  StreamSubscription? _locationOrientationSubscription;
  LatLng? _lastReportedLocation;
  double _lastReportedHeading = 0.0;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _initCompassListener();
    _initLocationOrientationTracking();
    _loadGeoJson();
    _loadroomGeoJson();
  }

  Future<void> _loadGeoJson() async {
    try {
      final String geoJsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/pathway.geojson');
      final geoJson = jsonDecode(geoJsonString);

      final features = geoJson['features'] as List;
      //print((features.length));

      for (var feature in features) {
        if (feature['geometry']['type'] == 'MultiPolygon') {
          final coordinates = feature['geometry']['coordinates'] as List;
          final properties = feature['properties'];

          for (var polygon in coordinates) {
            final List<LatLng> polygonCoords = [];

            for (var point in polygon[0]) {
              polygonCoords.add(LatLng(point[1], point[0]));
            }

            final newPolygon = Polygon(
                polygonId: PolygonId(properties['id'].toString()),
                points: polygonCoords,
                fillColor: Colors.black.withOpacity(0.2),
                strokeColor: Colors.black,
                strokeWidth: 2,
                consumeTapEvents: true,
                onTap: () {
                  print('Tapped polygon: ${properties['name']}');
                });

            setState(() {
              polygons.add(newPolygon);
            });
          }
        }
      }
    } catch (e) {
      print('Error loading GeoJSON: $e');
    }
  }

  Future<void> _loadroomGeoJson() async {
    try {
      // Load GeoJSON file
      final String geoJsonString = await DefaultAssetBundle.of(context)
          .loadString('assets/rooms.geojson');
      final geoJson = jsonDecode(geoJsonString);

      final features = geoJson['features'] as List;
      //print('Number of features: ${features.length}');

      // Initialize list and map
      List<String> names = [];
      Map<String, LatLng> locationMap = {};

      // Iterate through features
      for (var feature in features) {
        if (feature['geometry']['type'] == 'Point') {
          //print("1");
          // Check if the feature is a point
          final coordinates = feature['geometry']['coordinates'] as List;
          final properties = feature['properties'];

          // Extract name and coordinates
          final name = properties['type'];
          final LatLng pointCoords = LatLng(coordinates[1], coordinates[0]);

          // Add to list and map
          names.add(name);
          locationMap[name] = pointCoords;
        }
      }
      // print(names.length);
      setState(() {
        roomname = names;
        roomlocation = locationMap;
      });
      //print(roomname);
      //print(roomlocation);
    } catch (e) {
      print('Error loading GeoJSON: $e');
    }
  }

  void _initLocationOrientationTracking() {
    _locationOrientationSubscription =
        _locationOrientationService.locationOrientationStream.listen(
      (locationData) {
        // Compare and validate location
        _validateAndUpdateLocation(locationData);
      },
      onError: (error) {
        print('Location Orientation Error: $error');
      },
    );
  }

  void _validateAndUpdateLocation(LocationOrientationData locationData) {
    final newLocation = LatLng(locationData.latitude, locationData.longitude);

    // Check if location has changed significantly
    bool locationChanged = _lastReportedLocation == null ||
        Geolocator.distanceBetween(
                _lastReportedLocation!.latitude,
                _lastReportedLocation!.longitude,
                newLocation.latitude,
                newLocation.longitude) >
            10; // More than 10 meters

    // Check if heading has changed significantly
    bool headingChanged = (_lastReportedHeading - locationData.heading).abs() >
        5; // More than 5 degrees

    if (locationChanged || headingChanged) {
      setState(() {
        currentLocation = newLocation;
        _lastReportedLocation = newLocation;
        _lastReportedHeading = locationData.heading;

        // Update markers and camera
        _updateCurrentLocationMarker();
        _updateMapCamera(newLocation, locationData.heading);
      });
    }
  }

  void _updateMapCamera(LatLng location, double heading) {
    mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          bearing: heading,
          tilt: 45.0,
          zoom: 17.0,
        ),
      ),
    );
  }

  void _initCompassListener() {
    _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      final currentTime = DateTime.now();
      final heading = event.heading ?? 0.0;

      // Limit update frequency and add smoothing
      if (currentTime.difference(_lastUpdateTime).inMilliseconds > 200) {
        // Calculate smallest rotation angle
        double angleDiff = _calculateShortestRotation(_lastHeading, heading);

        // Simple exponential smoothing
        _smoothedHeading = _smoothHeading(_lastHeading, heading, 0.2);

        if (isNavigating && mapController != null && angleDiff > 2) {
          mapController?.animateCamera(
            CameraUpdate.newCameraPosition(
              CameraPosition(
                target: currentLocation ?? const LatLng(0, 0),
                bearing: _smoothedHeading,
                tilt: 45.0,
                zoom: 17.0,
              ),
            ),
          );
        }

        _lastHeading = _smoothedHeading;
        _lastUpdateTime = currentTime;
      }
    });
  }

  // Calculate smallest rotation angle between two headings
  double _calculateShortestRotation(double from, double to) {
    double diff = (to - from + 360) % 360;
    return diff > 180 ? 360 - diff : diff;
  }

  // Simple exponential smoothing
  double _smoothHeading(double previous, double current, double smoothFactor) {
    return previous + smoothFactor * (current - previous);
  }

  Future<void> _getCurrentLocation() async {
    bool hasPermission =
        await _locationOrientationService.checkLocationPermissions();

    if (!hasPermission) {
      setState(() {
        locationError = 'Location permissions are required';
        isLoadingLocation = false;
      });
      return;
    }

    // The location will be updated through the stream listener
    setState(() {
      isLoadingLocation = false;
      locationError = '';
    });
  }

  void _startNavigation() {
    if (selectedRouteMode == null || routeOptions.isEmpty) return;

    final selectedRoute = routeOptions[selectedRouteMode];
    setState(() {
      isNavigating = true;
      _currentRoutePoints = selectedRoute.polylines.first.points;
    });
    print

    // Start location tracking with higher accuracy
    _locationSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 10, // Update every 10 meters
      ),
    ).listen(_updateNavigation);
  }

  void _updateNavigation(Position position) {
    if (!isNavigating) return;

    final currentLocation = LatLng(position.latitude, position.longitude);

    setState(() {
      _currentPosition = position;
      _currentBearing = position.heading;
    });

    // Find closest point on the route
    final closestPoint = NavigationService.findClosestPointOnRoute(
        currentLocation, _currentRoutePoints);

    // Find next waypoint
    final nextWaypoint = NavigationService.findNextWaypoint(
        currentLocation, _currentRoutePoints);

    // Calculate remaining distance
    final remainingDistance = Geolocator.distanceBetween(
        currentLocation.latitude,
        currentLocation.longitude,
        _currentRoutePoints.last.latitude,
        _currentRoutePoints.last.longitude);

    // Generate turn instruction
    final turnInstruction = NavigationService.generateTurnInstruction(
        currentLocation, nextWaypoint, _currentBearing);

    setState(() {
      currentNavigationInstruction = turnInstruction;
      this.remainingDistance =
          NavigationService.formatRemainingDistance(remainingDistance);

      // Update map camera
      mapController?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: currentLocation,
            bearing: _currentBearing,
            tilt: 45.0,
            zoom: 17.0,
          ),
        ),
      );

      // Update markers and polylines
      markers.clear();
      markers.add(
        Marker(
          markerId: const MarkerId('currentLocation'),
          position: currentLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );

      // Highlight current route segment
      polylines = {
        Polyline(
          polylineId: const PolylineId('currentRoute'),
          points: _currentRoutePoints,
          color: Colors.blue,
          width: 5,
          patterns: [PatternItem.dash(10), PatternItem.gap(10)],
        ),
      };
    });

    // Check if destination is reached
    if (remainingDistance < 50) {
      _endNavigation();
    }
  }

  void _endNavigation() {
    _locationSubscription?.cancel();
    setState(() {
      isNavigating = false;
      _currentPosition = null;
      _currentRoutePoints = [];
      currentNavigationInstruction = 'Navigation ended';
      remainingDistance = '0 km';
      remainingDuration = '0 min';
      _clearRoute();
    });
  }

  void _showPlaceDetails(Place place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => PlaceDetailsSheet(
        place: place,
        onGetDirections: () {
          if (currentLocation != null && destinationLocation != null) {
            _getDirections();
          }
        },
      ),
    );
  }

  void _updateCurrentLocationMarker() {
    markers.clear();
    if (currentLocation != null) {
      // markers.add(
      //   Marker(
      //     markerId: const MarkerId('currentLocation'),
      //     position: currentLocation!,
      //     infoWindow: const InfoWindow(title: 'You are here'),
      //   ),
      //);
    }
  }

  Future<void> _handlePlaceSelection(
      String placeId, Map<String, LatLng> roomlocation) async {
    final place = await _placesService.getPlaceDetails(placeId, roomlocation);
    if (place != null) {
      setState(() {
        destinationLocation = place.location;
        markers.removeWhere((marker) => marker.markerId.value == 'destination');
        markers.add(
          Marker(
            markerId: const MarkerId('destination'),
            position: place.location,
            infoWindow: InfoWindow(title: place.name),
          ),
        );
      });

      // _updateRecentSearches(place.name);
      _showPlaceDetails(place);
      _animateToLocation(place.location);
    }
  }

  void _updateRecentSearches(String placeName) {
    if (!recentSearches.contains(placeName)) {
      setState(() {
        recentSearches.insert(0, placeName);
        if (recentSearches.length > 5) {
          recentSearches.removeLast();
        }
      });
    }
  }

  Future<void> _handleSearch(String query) async {
    //print("Search query: $query");
    if (query.isEmpty) {
      setState(() => suggestions = []);
      return;
    }

    try {
      final results = await _placesService.getPlaceSuggestions(query, roomname);
      setState(() {
        suggestions = results;
      });
    } catch (e) {
      print('Error updating suggestions: $e');
      setState(() => suggestions = []);
    }
  }

  Future<void> _animateToLocation(LatLng location) async {
    if (mapController != null) {
      await mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(location, 15),
      );
    }
  }

  Future<void> _getDirections() async {
    if (currentLocation == null || destinationLocation == null) return;

    try {
      // Get directions for multiple modes
      final directions = await _directionsService.getDirections(
        origin: currentLocation!,
        destination: destinationLocation!,
      );

      setState(() {
        routeOptions = directions;

        // Default to first mode if available
        if (directions.isNotEmpty) {
          selectedRouteMode = directions.keys.first;
          final selectedRoute = directions[selectedRouteMode];

          routeDistance = selectedRoute!.distance;
          routeDuration = selectedRoute.duration;
          polylines = selectedRoute.polylines;
          isRouteVisible = true;
        }
      });

      // Adjust camera to show entire route
      final selectedRoute = directions[selectedRouteMode];
      if (selectedRoute != null && selectedRoute.bounds != null) {
        mapController?.animateCamera(
          CameraUpdate.newLatLngBounds(selectedRoute.bounds!, 50),
        );
      }
    } catch (e) {
      print('Error getting directions: $e');
      setState(() {
        routeOptions = {};
        isRouteVisible = false;
      });
    }
  }

  void _selectRoute(String mode) {
    if (routeOptions.containsKey(mode)) {
      setState(() {
        selectedRouteMode = mode;
        final selectedRoute = routeOptions[mode];

        routeDistance = selectedRoute.distance;
        routeDuration = selectedRoute.duration;
        polylines = selectedRoute.polylines;
      });
    }
  }

  void _clearRoute() {
    setState(() {
      polylines.clear();
      routeDistance = null;
      routeDuration = null;
      isRouteVisible = false;
    });
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _locationSubscription?.cancel();
    _locationOrientationSubscription?.cancel();
    _locationOrientationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoadingLocation) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
            onMapCreated: (controller) =>
                setState(() => mapController = controller),
            initialCameraPosition: CameraPosition(
              target: currentLocation ?? const LatLng(0, 0),
              zoom: 15,
            ),
            markers: markers,
            polylines: polylines,
            polygons: polygons,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onTap: (position) => _placesService.getPlaceFromPoint(
                position, _handlePlaceSelection, roomlocation),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SearchBarWidget(
                    controller: searchController,
                    onSearch: _handleSearch,
                    onSuggestionSelected: _handlePlaceSelection,
                    recentSearches: recentSearches,
                    suggestions: suggestions,
                    roomlocation: roomlocation,
                  ),
                  if (isRouteVisible &&
                      routeOptions.isNotEmpty &&
                      !isNavigating)
                    RouteSelectionWidget(
                      routes: routeOptions,
                      selectedMode: selectedRouteMode,
                      onRouteSelected: _selectRoute,
                      onClearRoute: _clearRoute,
                      onStartNavigation: _startNavigation,
                    ),
                  if (isNavigating)
                    NavigationGuidanceWidget(
                      currentInstruction: currentNavigationInstruction,
                      remainingDistance: remainingDistance,
                      remainingDuration: remainingDuration,
                      onEndNavigation: _endNavigation,
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
