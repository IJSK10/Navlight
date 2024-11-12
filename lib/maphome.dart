import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';

void initializeApp() {
  WidgetsFlutterBinding.ensureInitialized();
}

class Maphome extends StatefulWidget {
  const Maphome({super.key});

  @override
  State<Maphome> createState() => _MaphomeState();
}

class _MaphomeState extends State<Maphome> {
  GoogleMapController? mapController;
  static const LatLng _initialPosition = LatLng(40.9136, -73.1257);
  final Set<Polygon> _polygons = {};
  final Set<Marker> _markers = {};

  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGeoJson();
  }

  Future<void> _loadGeoJson() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load the GeoJSON file from assets
      final String geoJsonString =
          await rootBundle.loadString('assets/floor.geojson');
      await _parseGeoJson(geoJsonString);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading GeoJSON: $e');
      setState(() {
        _isLoading = false;
        _error = 'Failed to load floor plan data. Please try again.';
      });
    }
  }

  Future<void> _parseGeoJson(String geoJsonString) async {
    try {
      final mapData = json.decode(geoJsonString);
      for (var feature in mapData['features']) {
        final properties = feature['properties'];
        final geometry = feature['geometry'];

        if (geometry['type'] == 'MultiPolygon') {
          // Add each polygon to the map
          final polygonId = PolygonId(properties['name']);
          final List<LatLng> polygonPoints = [];

          // Extracting coordinates for polygons
          for (var coords in geometry['coordinates'][0]) {
            polygonPoints.add(LatLng(coords[1], coords[0]));
          }

          _polygons.add(
            Polygon(
              polygonId: polygonId,
              points: polygonPoints,
              strokeWidth: 2,
              strokeColor:
                  properties['type'] == 'hallway' ? Colors.grey : Colors.blue,
              fillColor: properties['type'] == 'hallway'
                  ? Colors.grey.withOpacity(0.3)
                  : Colors.blue.withOpacity(0.3),
            ),
          );
        } else if (geometry['type'] == 'Point') {
          // Add markers for points
          final coordinates = geometry['coordinates'];
          _markers.add(
            Marker(
              markerId: MarkerId(properties['name']),
              position: LatLng(coordinates[1], coordinates[0]),
              infoWindow: InfoWindow(title: properties['name']),
            ),
          );
        }
      }

      setState(() {});
    } catch (e) {
      print('Error parsing GeoJSON: $e');
      setState(() {
        _error =
            'Failed to parse floor plan data. Please check the file format.';
      });
    }
  }

  // void _showRoomInfo(String name, int id, String type) {
  //   showModalBottomSheet(
  //     context: context,
  //     builder: (context) => Container(
  //       padding: const EdgeInsets.all(16),
  //       child: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text('Room: $name', style: Theme.of(context).textTheme.titleLarge),
  //           const SizedBox(height: 8),
  //           Text('ID: $id'),
  //           Text('Type: $type'),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  // @override
  // Widget build(BuildContext context) {
  //   // final CameraPosition initialPosition = CameraPosition(
  //   //   target: LatLng(40.913513, -73.125500),
  //   //   zoom: 21,
  //   // );

  //   return MaterialApp(
  //     home: Scaffold(
  //       appBar: AppBar(
  //         title: const Text('Floor Plan Map'),
  //         actions: [
  //           IconButton(
  //             icon: const Icon(Icons.refresh),
  //             onPressed: _loadGeoJson,
  //           ),
  //           IconButton(
  //             icon: const Icon(Icons.info_outline),
  //             onPressed: () {
  //               showDialog(
  //                 context: context,
  //                 builder: (context) => AlertDialog(
  //                   title: const Text('Map Legend'),
  //                   content: Column(
  //                     mainAxisSize: MainAxisSize.min,
  //                     crossAxisAlignment: CrossAxisAlignment.start,
  //                     children: [
  //                       Row(
  //                         children: [
  //                           Container(
  //                             width: 20,
  //                             height: 20,
  //                             color: Colors.blue.withOpacity(0.3),
  //                           ),
  //                           const SizedBox(width: 8),
  //                           const Text('Cabin'),
  //                         ],
  //                       ),
  //                       const SizedBox(height: 8),
  //                       Row(
  //                         children: [
  //                           Container(
  //                             width: 20,
  //                             height: 20,
  //                             color: Colors.grey.withOpacity(0.2),
  //                           ),
  //                           const SizedBox(width: 8),
  //                           const Text('Hallway'),
  //                         ],
  //                       ),
  //                     ],
  //                   ),
  //                   actions: [
  //                     TextButton(
  //                       onPressed: () => Navigator.pop(context),
  //                       child: const Text('Close'),
  //                     ),
  //                   ],
  //                 ),
  //               );
  //             },
  //           ),
  //         ],
  //       ),
  //       body: _isLoading
  //           ? const Center(child: CircularProgressIndicator())
  //           : _error != null
  //               ? Center(
  //                   child: Column(
  //                     mainAxisAlignment: MainAxisAlignment.center,
  //                     children: [
  //                       Text(_error!,
  //                           style: const TextStyle(color: Colors.red)),
  //                       const SizedBox(height: 16),
  //                       ElevatedButton(
  //                         onPressed: _loadGeoJson,
  //                         child: const Text('Retry'),
  //                       ),
  //                     ],
  //                   ),
  //                 )
  //               : GoogleMap(
  //                   initialCameraPosition: initialPosition,
  //                   mapType: MapType.satellite,
  //                   polygons: _polygons,
  //                   markers: _markers,
  //                   buildingsEnabled: false,
  //                   mapToolbarEnabled: false,
  //                   zoomControlsEnabled: false,
  //                   minMaxZoomPreference: const MinMaxZoomPreference(19, 22),
  //                   onMapCreated: (GoogleMapController controller) {
  //                     mapController = controller;
  //                     controller.setMapStyle('''
  //                       [
  //                         {
  //                           "featureType": "poi",
  //                           "stylers": [{ "visibility": "off" }]
  //                         },
  //                         {
  //                           "featureType": "transit",
  //                           "stylers": [{ "visibility": "off" }]
  //                         }
  //                       ]
  //                     ''');
  //                   },
  //                 ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Indoor Map"),
      ),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        initialCameraPosition: const CameraPosition(
          target: _initialPosition,
          zoom: 20,
        ),
        polygons: _polygons,
        markers: _markers,
      ),
    );
  }
}
