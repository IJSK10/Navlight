import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:navlight/components.dart/route_info_widget.dart';
import 'package:navlight/components.dart/suggestions_list.dart';
import 'package:navlight/directions_service.dart';
import 'package:navlight/location_service.dart';
import 'package:navlight/place_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? mapController;
  final TextEditingController searchController = TextEditingController();
  final List<String> recentSearches = [];
  List<Map<String, dynamic>> suggestions = [];
  Set<Marker> markers = {};
  Set<Polyline> _polylines = {};
  LatLng? destinationLocation;
  String? routeDistance;
  String? routeDuration;
  bool isRouteVisible = false;
  LatLng? currentLocation;
  bool isLoadingLocation = true;
  String locationError = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    final result = await LocationService.getCurrentLocation();
    if (result != null) {
      setState(() {
        currentLocation = result;
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
    } else {
      setState(() {
        locationError = 'Unable to get current location';
        isLoadingLocation = false;
      });
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

  @override
  Widget build(BuildContext context) {
    if (isLoadingLocation) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
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
            polylines: _polylines,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            onTap: (LatLng position) {
              PlaceService.getPlaceFromPoint(position).then((place) {
                if (place != null) {
                  PlaceService.showPlaceDetails(context, place, currentLocation,
                      destinationLocation, DirectionsService.getDirections);
                }
              });
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SearchBar(
                    controller: searchController,
                    onChanged: (query) {
                      PlaceService.getPlaceSuggestions(query).then((result) {
                        setState(() => suggestions = result);
                      });
                    },
                    onTap: () {
                      searchController.clear();
                      setState(() => suggestions = []);
                    },
                  ),
                  if (suggestions.isNotEmpty ||
                      (searchController.text.isEmpty &&
                          recentSearches.isNotEmpty))
                    SuggestionsList(
                      suggestions: suggestions,
                      recentSearches: recentSearches,
                      onSuggestionTap: (suggestion) {
                        PlaceService.getPlaceDetails(suggestion['place_id'])
                            .then((place) {
                          if (place != null) {
                            PlaceService.showPlaceDetails(
                                context,
                                place,
                                currentLocation,
                                destinationLocation,
                                DirectionsService.getDirections);
                          }
                        });
                        setState(() => suggestions = []);
                        searchController.clear();
                      },
                      onRecentSearchTap: (search) {
                        searchController.text = search;
                        PlaceService.getPlaceSuggestions(search).then((result) {
                          setState(() => suggestions = result);
                        });
                      },
                    ),
                ],
              ),
            ),
          ),
          if (isRouteVisible && routeDistance != null && routeDuration != null)
            RouteInfoWidget(
              routeDistance: routeDistance!,
              routeDuration: routeDuration!,
              onClearRoute: _clearRoute,
            ),
        ],
      ),
    );
  }
}
