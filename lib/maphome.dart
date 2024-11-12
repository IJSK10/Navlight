import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
// import 'package:latlong2/latlong.dart';

class GeoJsonMapScreen extends StatefulWidget {
  @override
  _GeoJsonMapScreenState createState() => _GeoJsonMapScreenState();
}

class _GeoJsonMapScreenState extends State<GeoJsonMapScreen> {
  late GoogleMapController mapController;
  Set<Marker> _markers = Set();
  Set<Polygon> _polygons = Set();
  late Future<Map<String, dynamic>> geoJsonData;

  @override
  void initState() {
    super.initState();
    geoJsonData = loadGeoJson();
  }

  // Load GeoJSON from assets
  Future<Map<String, dynamic>> loadGeoJson() async {
    String geoJsonString = await rootBundle.loadString('assets/floor.geojson');
    return jsonDecode(geoJsonString);
  }

  // Process GeoJSON data and extract coordinates
  void processGeoJson(Map<String, dynamic> geoJsonData) {
    int polygonId = 0;
    int markerId = 0;

    for (var feature in geoJsonData['features']) {
      var geometry = feature['geometry'];
      if (geometry['type'] == 'MultiPolygon') {
        var coordinates = geometry['coordinates'];
        for (var polygon in coordinates) {
          List<LatLng> polygonCoordinates = [];
          for (var ring in polygon) {
            for (var coordinate in ring) {
              double longitude = double.parse(coordinate[0].toString());
              double latitude = double.parse(coordinate[1].toString());
              polygonCoordinates.add(LatLng(latitude, longitude));
            }
          }

          // Add the polygon to the set
          _polygons.add(
            Polygon(
              polygonId: PolygonId('polygon_$polygonId'),
              points: polygonCoordinates,
              strokeColor: Colors.blue,
              strokeWidth: 3,
              fillColor: Colors.blue.withOpacity(0.2),
            ),
          );
          polygonId++;
        }
      } else if (geometry['type'] == 'Point') {
        var coordinates = geometry['coordinates'];
        double longitude = double.parse(coordinates[0].toString());
        double latitude = double.parse(coordinates[1].toString());

        // Add the marker for the point
        _markers.add(
          Marker(
            markerId: MarkerId('marker_$markerId'),
            position: LatLng(latitude, longitude),
            infoWindow: InfoWindow(title: 'Point $markerId'),
          ),
        );
        markerId++;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GeoJSON with Google Maps'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: geoJsonData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            // Process the GeoJSON data and extract coordinates
            processGeoJson(snapshot.data!);

            return GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(37.7749, -122.4194), // Default to San Francisco
                zoom: 10.0,
              ),
              onMapCreated: (GoogleMapController controller) {
                mapController = controller;
              },
              markers: _markers,
              polygons: _polygons,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
            );
          } else {
            return Center(child: Text('No data available.'));
          }
        },
      ),
    );
  }
}
