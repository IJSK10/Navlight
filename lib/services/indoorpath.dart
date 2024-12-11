import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/directions.dart';

class GraphNode {
  final int id;
  final LatLng location;
  final Map<GraphNode, double> connections = {};

  GraphNode({required this.id, required this.location});
}

class IndoorPathfinder {
  List<GraphNode> _graphNodes = [];

  // Calculate distance between two LatLng points (in meters)
  double _calculateDistance(LatLng start, LatLng end) {
    const earthRadius = 6371000; // meters
    final lat1 = start.latitude * pi / 180;
    final lat2 = end.latitude * pi / 180;
    final lon1 = start.longitude * pi / 180;
    final lon2 = end.longitude * pi / 180;

    final dLat = lat2 - lat1;
    final dLon = lon2 - lon1;

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  // Load and create graph from GeoJSON
  Future<void> loadPathwayGraph() async {
    _graphNodes.clear();

    try {
      final jsonString =
          await rootBundle.loadString("assets/walkpoints.geojson");
      final jsonData = json.decode(jsonString);

      // Parse features and create graph nodes
      final features = jsonData['features'] as List;

      // Create nodes first
      for (var feature in features) {
        final coords = feature['geometry']['coordinates'][0];
        final node = GraphNode(
            id: feature['properties']['id'] ?? 0,
            location: LatLng(coords[1], coords[0]));
        _graphNodes.add(node);
      }

      // Connect successive nodes
      for (int i = 0; i < _graphNodes.length - 1; i++) {
        final currentNode = _graphNodes[i];
        final nextNode = _graphNodes[i + 1];

        final distance =
            _calculateDistance(currentNode.location, nextNode.location);

        // Bidirectional connection
        currentNode.connections[nextNode] = distance;
        nextNode.connections[currentNode] = distance;
      }

      print('Loaded ${_graphNodes.length} graph nodes');
    } catch (e) {
      print('Error loading pathway graph: $e');
    }
  }

  // Find the nearest graph node to a given point
  GraphNode? findNearestNode(LatLng point, {double maxDistance = 50}) {
    GraphNode? nearest;
    double minDistance = double.infinity;

    for (var node in _graphNodes) {
      final distance = _calculateDistance(point, node.location);
      if (distance < minDistance && distance <= maxDistance) {
        minDistance = distance;
        nearest = node;
      }
    }

    return nearest;
  }

  // Dijkstra's shortest path algorithm
  List<GraphNode> _dijkstraShortestPath(GraphNode start, GraphNode end) {
    // Reset tracking
    final distances = <GraphNode, double>{};
    final previousNodes = <GraphNode, GraphNode?>{};
    final unvisitedNodes = <GraphNode>{};

    // Initialize
    for (var node in _graphNodes) {
      distances[node] = double.infinity;
      previousNodes[node] = null;
      unvisitedNodes.add(node);
    }
    distances[start] = 0;

    while (unvisitedNodes.isNotEmpty) {
      // Find node with minimum distance
      final currentNode = unvisitedNodes
          .reduce((a, b) => distances[a]! < distances[b]! ? a : b);

      unvisitedNodes.remove(currentNode);

      // Reached destination
      if (currentNode == end) break;

      // Check connections
      for (var entry in currentNode.connections.entries) {
        final neighborNode = entry.key;
        final distance = entry.value;

        if (!unvisitedNodes.contains(neighborNode)) continue;

        final tentativeDistance = distances[currentNode]! + distance;

        if (tentativeDistance < distances[neighborNode]!) {
          distances[neighborNode] = tentativeDistance;
          previousNodes[neighborNode] = currentNode;
        }
      }
    }

    // Reconstruct path
    final path = <GraphNode>[];
    GraphNode? current = end;
    while (current != null) {
      path.insert(0, current);
      current = previousNodes[current];
    }

    return path;
  }

  // Find shortest path between two points
  Future<Directions> findShortestPath(LatLng origin, LatLng destination) async {
    // Ensure graph is loaded
    if (_graphNodes.isEmpty) {
      await loadPathwayGraph();
    }

    // Find nearest nodes
    final originNode = findNearestNode(origin);
    final destNode = findNearestNode(destination);

    if (originNode == null || destNode == null) {
      print('Could not find suitable pathway nodes');
      return Directions.empty();
    }

    // Find shortest path
    final pathNodes = _dijkstraShortestPath(originNode, destNode);

    // Create polyline for the path
    final List<LatLng> pathPoints = [
      origin,
      ...pathNodes.map((node) => node.location),
      destination
    ];

    // Calculate total distance
    double totalDistance = 0;
    for (int i = 0; i < pathPoints.length - 1; i++) {
      totalDistance += _calculateDistance(pathPoints[i], pathPoints[i + 1]);
    }

    final polyline = Polyline(
      polylineId: PolylineId('indoor_path'),
      points: pathPoints,
      color: Colors.green,
      width: 5,
    );

    return Directions(
      distance: '${(totalDistance / 1000).toStringAsFixed(2)} km',
      duration: '${(totalDistance / 1.4 / 60).toStringAsFixed(1)} mins',
      polylines: {polyline},
      bounds: _calculateBounds(pathPoints),
    );
  }

  // Calculate bounds for the path
  LatLngBounds _calculateBounds(List<LatLng> points) {
    double minLat = points.map((p) => p.latitude).reduce(min);
    double maxLat = points.map((p) => p.latitude).reduce(max);
    double minLon = points.map((p) => p.longitude).reduce(min);
    double maxLon = points.map((p) => p.longitude).reduce(max);

    return LatLngBounds(
      southwest: LatLng(minLat, minLon),
      northeast: LatLng(maxLat, maxLon),
    );
  }

  // Getter for graph nodes
  List<GraphNode> get graphNodes => _graphNodes;
}
