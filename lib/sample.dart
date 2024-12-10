//Future<void> getNearbyPlaces() async {
  //   if (currentLocation == null || mapController == null) return;

  //   // Get visible region bounds
  //   final LatLngBounds bounds = await mapController!.getVisibleRegion();
  //   final LatLng center = LatLng(
  //     (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
  //     (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
  //   );

  //   // Calculate radius based on visible region
  //   final double radius = calculateRadius(bounds);

  //   // Clear existing place markers (keep current location marker)
  //   markers.removeWhere(
  //       (marker) => marker.markerId != const MarkerId('currentLocation'));

  //   // Fetch places for each type
  //   for (String type in placeTypes) {
  //     final String url =
  //         'https://maps.googleapis.com/maps/api/place/nearbysearch/json?'
  //         'location=${center.latitude},${center.longitude}'
  //         '&radius=$radius'
  //         '&type=$type'
  //         '&key=$apiKey';

  //     try {
  //       final response = await Dio().get(url);
  //       if (response.data['status'] == 'OK') {
  //         for (var place in response.data['results']) {
  //           final location = place['geometry']['location'];
  //           final latLng = LatLng(location['lat'], location['lng']);

  //           setState(() {
  //             markers.add(
  //               Marker(
  //                 markerId: MarkerId(place['place_id']),
  //                 position: latLng,
  //                 // Remove custom icon to use default Google Maps marker
  //                 infoWindow: InfoWindow(
  //                   title: place['name'],
  //                   snippet: place['vicinity'],
  //                 ),
  //                 onTap: () => showPlaceDetails(place['place_id']),
  //               ),
  //             );
  //           });
  //         }
  //       }
  //     } catch (e) {
  //       debugPrint('Error fetching nearby places: $e');
  //     }
  //   }
  // }

  // double calculateRadius(LatLngBounds bounds) {
  //   final double distance = Geolocator.distanceBetween(
  //     bounds.northeast.latitude,
  //     bounds.northeast.longitude,
  //     bounds.southwest.latitude,
  //     bounds.southwest.longitude,
  //   );
  //   return distance / 2;
  // }

  // Future<void> getPlaceFromCoordinates(LatLng location) async {
  //   final String url = 'https://maps.googleapis.com/maps/api/geocode/json?'
  //       'latlng=${location.latitude},${location.longitude}'
  //       '&key=$apiKey';

  //   try {
  //     final response = await Dio().get(url);
  //     if (response.data['status'] == 'OK' &&
  //         response.data['results'].isNotEmpty) {
  //       final result = response.data['results'][0];

  //       setState(() {
  //         tappedLocation = location;
  //         // Use default marker
  //         markers.add(
  //           Marker(
  //             markerId: const MarkerId('tapped_location'),
  //             position: location,
  //             infoWindow: InfoWindow(
  //               title: 'Selected Location',
  //               snippet: result['formatted_address'],
  //             ),
  //           ),
  //         );
  //       });

  //       showPlaceDetailsFromTap(result, location);
  //     }
  //   } catch (e) {
  //     debugPrint('Error fetching place details: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Error getting location details: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  // void showPlaceDetailsFromTap(
  //     Map<String, dynamic> placeDetails, LatLng location) {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     backgroundColor: Colors.transparent,
  //     builder: (context) => DraggableScrollableSheet(
  //       initialChildSize: 0.3,
  //       minChildSize: 0.2,
  //       maxChildSize: 0.8,
  //       builder: (context, scrollController) => Container(
  //         decoration: const BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //         ),
  //         padding: const EdgeInsets.all(16),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           mainAxisSize: MainAxisSize.min,
  //           children: [
  //             Center(
  //               child: Container(
  //                 width: 40,
  //                 height: 4,
  //                 margin: const EdgeInsets.only(bottom: 16),
  //                 decoration: BoxDecoration(
  //                   color: Colors.grey[300],
  //                   borderRadius: BorderRadius.circular(2),
  //                 ),
  //               ),
  //             ),
  //             Text(
  //               'Selected Location',
  //               style: const TextStyle(
  //                 fontSize: 20,
  //                 fontWeight: FontWeight.bold,
  //               ),
  //             ),
  //             const SizedBox(height: 8),
  //             Text(
  //               placeDetails['formatted_address'] ?? '',
  //               style: const TextStyle(fontSize: 16),
  //             ),
  //             const SizedBox(height: 16),
  //             Row(
  //               mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //               children: [
  //                 ElevatedButton.icon(
  //                   onPressed: () {
  //                     if (currentLocation != null) {
  //                       destinationLocation = location;
  //                       _getDirections(currentLocation!, location);
  //                     }
  //                     Navigator.pop(context);
  //                   },
  //                   icon: const Icon(Icons.directions),
  //                   label: const Text('Get Directions'),
  //                 ),
  //                 ElevatedButton.icon(
  //                   onPressed: () {
  //                     // Add your custom action here
  //                     // For example: save location, share location, etc.
  //                     Navigator.pop(context);
  //                   },
  //                   icon: const Icon(Icons.bookmark_border),
  //                   label: const Text('Save Location'),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  // Future<void> showPlaceDetails(String placeId) async {
  //   final String url =
  //       'https://maps.googleapis.com/maps/api/place/details/json?'
  //       'place_id=$placeId'
  //       '&fields=name,formatted_address,rating,opening_hours,photos,types,website,formatted_phone_number'
  //       '&key=$apiKey';

  //   try {
  //     final response = await Dio().get(url);
  //     if (response.data['status'] == 'OK') {
  //       final place = response.data['result'];
  //       showModalBottomSheet(
  //         context: context,
  //         isScrollControlled: true,
  //         backgroundColor: Colors.transparent,
  //         builder: (context) => DraggableScrollableSheet(
  //           initialChildSize: 0.4,
  //           minChildSize: 0.2,
  //           maxChildSize: 0.8,
  //           builder: (context, scrollController) => Container(
  //             decoration: const BoxDecoration(
  //               color: Colors.white,
  //               borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  //             ),
  //             padding: const EdgeInsets.all(16),
  //             child: ListView(
  //               controller: scrollController,
  //               children: [
  //                 Center(
  //                   child: Container(
  //                     width: 40,
  //                     height: 4,
  //                     margin: const EdgeInsets.only(bottom: 16),
  //                     decoration: BoxDecoration(
  //                       color: Colors.grey[300],
  //                       borderRadius: BorderRadius.circular(2),
  //                     ),
  //                   ),
  //                 ),
  //                 Text(
  //                   place['name'] ?? 'Unknown Place',
  //                   style: const TextStyle(
  //                     fontSize: 24,
  //                     fontWeight: FontWeight.bold,
  //                   ),
  //                 ),
  //                 const SizedBox(height: 8),
  //                 if (place['rating'] != null)
  //                   Row(
  //                     children: [
  //                       const Icon(Icons.star, color: Colors.amber),
  //                       Text(
  //                         ' ${place['rating']}',
  //                         style: const TextStyle(fontSize: 16),
  //                       ),
  //                     ],
  //                   ),
  //                 const SizedBox(height: 8),
  //                 Text(
  //                   place['formatted_address'] ?? '',
  //                   style: const TextStyle(fontSize: 16),
  //                 ),
  //                 const SizedBox(height: 16),
  //                 if (place['formatted_phone_number'] != null)
  //                   ListTile(
  //                     leading: const Icon(Icons.phone),
  //                     title: Text(place['formatted_phone_number']),
  //                   ),
  //                 if (place['opening_hours']?['weekday_text'] != null)
  //                   ExpansionTile(
  //                     leading: const Icon(Icons.access_time),
  //                     title: const Text('Opening Hours'),
  //                     children: [
  //                       ...place['opening_hours']['weekday_text']
  //                           .map<Widget>((hours) => Padding(
  //                                 padding: const EdgeInsets.all(8.0),
  //                                 child: Text(hours),
  //                               ))
  //                           .toList(),
  //                     ],
  //                   ),
  //                 const SizedBox(height: 16),
  //                 Row(
  //                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
  //                   children: [
  //                     ElevatedButton.icon(
  //                       onPressed: () {
  //                         if (currentLocation != null) {
  //                           final location = place['geometry']['location'];
  //                           final destination =
  //                               LatLng(location['lat'], location['lng']);
  //                           _getDirections(currentLocation!, destination);
  //                         }
  //                         Navigator.pop(context);
  //                       },
  //                       icon: const Icon(Icons.directions),
  //                       label: const Text('Directions'),
  //                     ),
  //                     if (place['website'] != null)
  //                       ElevatedButton.icon(
  //                         onPressed: () {
  //                           // Add website handling
  //                         },
  //                         icon: const Icon(Icons.language),
  //                         label: const Text('Website'),
  //                       ),
  //                   ],
  //                 ),
  //               ],
  //             ),
  //           ),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     debugPrint('Error fetching place details: $e');
  //   }
  // }

  // // Check and request location permissions
  // Future<bool> _handleLocationPermission() async {
  //   bool serviceEnabled;
  //   LocationPermission permission;

  //   serviceEnabled = await Geolocator.isLocationServiceEnabled();
  //   if (!serviceEnabled) {
  //     setState(() {
  //       locationError = 'Location services are disabled. Please enable them.';
  //       isLoadingLocation = false;
  //     });
  //     return false;
  //   }

  //   permission = await Geolocator.checkPermission();
  //   if (permission == LocationPermission.denied) {
  //     permission = await Geolocator.requestPermission();
  //     if (permission == LocationPermission.denied) {
  //       setState(() {
  //         locationError = 'Location permissions are denied';
  //         isLoadingLocation = false;
  //       });
  //       return false;
  //     }
  //   }

  //   if (permission == LocationPermission.deniedForever) {
  //     setState(() {
  //       locationError = 'Location permissions are permanently denied';
  //       isLoadingLocation = false;
  //     });
  //     return false;
  //   }

  //   return true;
  // }

  // // Get current location
  // Future<void> _getCurrentLocation() async {
  //   final hasPermission = await _handleLocationPermission();

  //   if (!hasPermission) return;

  //   try {
  //     final Position position = await Geolocator.getCurrentPosition(
  //         desiredAccuracy: LocationAccuracy.high);

  //     setState(() {
  //       currentLocation = LatLng(position.latitude, position.longitude);
  //       isLoadingLocation = false;
  //       locationError = '';

  //       // Update markers with default style
  //       markers.clear();
  //       markers.add(
  //         Marker(
  //           markerId: const MarkerId('currentLocation'),
  //           position: currentLocation!,
  //           infoWindow: const InfoWindow(title: 'You are here'),
  //           // Remove icon property to use default marker
  //         ),
  //       );
  //     });

  //     if (mapController != null) {
  //       await mapController!.animateCamera(
  //         CameraUpdate.newCameraPosition(
  //           CameraPosition(
  //             target: currentLocation!,
  //             zoom: 15,
  //           ),
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     setState(() {
  //       locationError = 'Error getting location: $e';
  //       isLoadingLocation = false;
  //     });
  //   }
  // }


  // // Rest of the methods remain same as before
  // Future<void> getPlaceSuggestions(String query) async {
  //   if (query.isEmpty) {
  //     setState(() => suggestions = []);
  //     return;
  //   }

  //   final String url =
  //       'https://maps.googleapis.com/maps/api/place/autocomplete/json?'
  //       'input=$query&key=$apiKey';

  //   try {
  //     final response = await Dio().get(url);
  //     print("suggestions");
  //     print(response.data);
  //     setState(() => suggestions = response.data['predictions']);
  //   } catch (e) {
  //     debugPrint('Error fetching suggestions: $e');
  //   }
  // }

  // Future<void> getPlaceDetails(String placeId) async {
  //   if (mapController == null) return; // Add this check
  //   print("place id");
  //   print(placeId);
  //   final String url =
  //       'https://maps.googleapis.com/maps/api/place/details/json?'
  //       'place_id=$placeId&fields=name,formatted_address,geometry,photos&key=$apiKey';

  //   try {
  //     final response = await Dio().get(url);
  //     final result = response.data['result'];
  //     final location = result['geometry']['location'];
  //     final LatLng placeLatLng = LatLng(location['lat'], location['lng']);

  //     if (!recentSearches.contains(result['formatted_address'])) {
  //       setState(() {
  //         recentSearches.insert(0, result['formatted_address']);
  //         if (recentSearches.length > 5) recentSearches.removeLast();
  //       });
  //     }

  //     setState(() {
  //       markers.clear();
  //       // Add back the current location marker
  //       if (currentLocation != null) {
  //         markers.add(
  //           Marker(
  //             markerId: const MarkerId('currentLocation'),
  //             position: currentLocation!,
  //             infoWindow: const InfoWindow(title: 'You are here'),
  //           ),
  //         );
  //       }
  //       // Add the searched place marker
  //       markers.add(
  //         Marker(
  //           markerId: MarkerId(placeId),
  //           position: placeLatLng,
  //           infoWindow: InfoWindow(
  //             title: result['name'],
  //             snippet: result['formatted_address'],
  //           ),
  //         ),
  //       );
  //     });

  //     await mapController!.animateCamera(
  //       CameraUpdate.newCameraPosition(
  //         CameraPosition(target: placeLatLng, zoom: 15),
  //       ),
  //     );

  //     showPlaceDetails(result);
  //     searchController.clear();
  //     setState(() => suggestions = []);
  //   } catch (e) {
  //     debugPrint('Error fetching place details: $e');
  //   }
  // }

  // // void showPlaceDetails(Map<String, dynamic> placeDetails) {
  // //   final location = placeDetails['geometry']['location'];
  // //   destinationLocation = LatLng(location['lat'], location['lng']);

  // //   showModalBottomSheet(
  // //     context: context,
  // //     isScrollControlled: true, // This allows the modal to be draggable
  // //     backgroundColor: Colors.transparent,
  // //     builder: (context) => DraggableScrollableSheet(
  // //       initialChildSize: 0.3,
  // //       minChildSize: 0.2,
  // //       maxChildSize: 0.8,
  // //       builder: (context, scrollController) => Container(
  // //         decoration: const BoxDecoration(
  // //           color: Colors.white,
  // //           borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  // //         ),
  // //         padding: const EdgeInsets.all(16),
  // //         child: Column(
  // //           crossAxisAlignment: CrossAxisAlignment.start,
  // //           mainAxisSize: MainAxisSize.min,
  // //           children: [
  // //             // Drag handle
  // //             Center(
  // //               child: Container(
  // //                 width: 40,
  // //                 height: 4,
  // //                 margin: const EdgeInsets.only(bottom: 16),
  // //                 decoration: BoxDecoration(
  // //                   color: Colors.grey[300],
  // //                   borderRadius: BorderRadius.circular(2),
  // //                 ),
  // //               ),
  // //             ),
  // //             Text(
  // //               placeDetails['name'] ?? '',
  // //               style: const TextStyle(
  // //                 fontSize: 20,
  // //                 fontWeight: FontWeight.bold,
  // //               ),
  // //             ),
  // //             const SizedBox(height: 8),
  // //             Text(
  // //               placeDetails['formatted_address'] ?? '',
  // //               style: const TextStyle(fontSize: 16),
  // //             ),
  // //             const SizedBox(height: 16),
  // //             ElevatedButton(
  // //               onPressed: () {
  // //                 if (currentLocation != null && destinationLocation != null) {
  // //                   print("pressed getdirections");
  // //                   _getDirections(currentLocation!, destinationLocation!);
  // //                 }
  // //                 Navigator.pop(context);
  // //               },
  // //               child: const Text('Get Directions'),
  // //             ),
  // //           ],
  // //         ),
  // //       ),
  // //     ),
  // //   );
  // // }

  // void onMapCreated(GoogleMapController controller) {
  //   setState(() {
  //     mapController = controller;
  //     if (currentLocation != null) {
  //       controller.animateCamera(
  //         CameraUpdate.newCameraPosition(
  //           CameraPosition(
  //             target: currentLocation!,
  //             zoom: 15,
  //           ),
  //         ),
  //       );
  //       // Fetch nearby places when map is created
  //       getNearbyPlaces();
  //     }
  //   });
  // }

  // Future<void> _getDirections(LatLng origin, LatLng destination) async {
  //   final String url = 'https://maps.googleapis.com/maps/api/directions/json?'
  //       'origin=${origin.latitude},${origin.longitude}'
  //       '&destination=${destination.latitude},${destination.longitude}'
  //       '&key=$apiKey';

  //   try {
  //     final response = await Dio().get(url);

  //     if (response.data['status'] == 'OK' &&
  //         response.data['routes'].isNotEmpty) {
  //       final route = response.data['routes'][0];
  //       final leg = route['legs'][0];

  //       // Get distance and duration
  //       setState(() {
  //         routeDistance = leg['distance']['text'];
  //         routeDuration = leg['duration']['text'];
  //         isRouteVisible = true;
  //       });

  //       // Decode polyline points
  //       final points = _decodePolyline(route['overview_polyline']['points']);

  //       setState(() {
  //         _polylines.clear();
  //         _polylines.add(Polyline(
  //           polylineId: const PolylineId('route'),
  //           points: points,
  //           color: Colors.blue,
  //           width: 5,
  //         ));
  //       });

  //       // Adjust camera to show the entire route
  //       if (points.isNotEmpty) {
  //         LatLngBounds bounds = _calculateBounds(points);
  //         mapController?.animateCamera(
  //           CameraUpdate.newLatLngBounds(bounds, 50),
  //         );
  //       }
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content: Text('Could not find route: ${response.data['status']}'),
  //           backgroundColor: Colors.red,
  //         ),
  //       );
  //     }
  //   } catch (e) {
  //     print('Error getting directions: $e');
  //     ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('Error getting directions: $e'),
  //         backgroundColor: Colors.red,
  //       ),
  //     );
  //   }
  // }

  // void _clearRoute() {
  //   setState(() {
  //     _polylines.clear();
  //     routeDistance = null;
  //     routeDuration = null;
  //     isRouteVisible = false;
  //   });
  // }

  // List<LatLng> _decodePolyline(String encoded) {
  //   List<LatLng> points = [];
  //   int index = 0, len = encoded.length;
  //   int lat = 0, lng = 0;

  //   while (index < len) {
  //     int b, shift = 0, result = 0;
  //     do {
  //       b = encoded.codeUnitAt(index++) - 63;
  //       result |= (b & 0x1F) << shift;
  //       shift += 5;
  //     } while (b >= 0x20);
  //     int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
  //     lat += dlat;

  //     shift = 0;
  //     result = 0;
  //     do {
  //       b = encoded.codeUnitAt(index++) - 63;
  //       result |= (b & 0x1F) << shift;
  //       shift += 5;
  //     } while (b >= 0x20);
  //     int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
  //     lng += dlng;

  //     points.add(LatLng(lat / 1E5, lng / 1E5));
  //   }
  //   return points;
  // }

  // LatLngBounds _calculateBounds(List<LatLng> points) {
  //   double? minLat, maxLat, minLng, maxLng;

  //   for (LatLng point in points) {
  //     if (minLat == null || point.latitude < minLat) minLat = point.latitude;
  //     if (maxLat == null || point.latitude > maxLat) maxLat = point.latitude;
  //     if (minLng == null || point.longitude < minLng) minLng = point.longitude;
  //     if (maxLng == null || point.longitude > maxLng) maxLng = point.longitude;
  //   }

  //   return LatLngBounds(
  //     southwest: LatLng(minLat!, minLng!),
  //     northeast: LatLng(maxLat!, maxLng!),
  //   );
  // }