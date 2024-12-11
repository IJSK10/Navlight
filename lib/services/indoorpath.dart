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
      // Load the rectangular path points
      final rectangleJsonString =
          await rootBundle.loadString("assets/walkpoints.geojson");
      final rectangleJsonData = json.decode(rectangleJsonString);

      // Load the middle path points
      final middlePathJsonString =
          await rootBundle.loadString("assets/walkpoints1.geojson");
      final middlePathJsonData = json.decode(middlePathJsonString);

      // Parse and create graph nodes for both paths
      final rectangleFeatures = rectangleJsonData['features'] as List;
      final middlePathFeatures = middlePathJsonData['features'] as List;

      // Combine features from both paths
      final allFeatures = [...rectangleFeatures, ...middlePathFeatures];

      // Create nodes for all features
      for (var feature in allFeatures) {
        final coords = feature['geometry']['coordinates'][0];
        final node = GraphNode(
            id: feature['properties']['id'] ?? 0,
            location: LatLng(coords[1], coords[0]));
        _graphNodes.add(node);
      }

      // Connect nodes within each original path
      void connectNodesInPath(
          List<GraphNode> pathNodes, bool connectFirstLast) {
        for (int i = 0; i < pathNodes.length - 1; i++) {
          final currentNode = pathNodes[i];
          final nextNode = pathNodes[i + 1];

          final distance =
              _calculateDistance(currentNode.location, nextNode.location);

          // Bidirectional connection
          currentNode.connections[nextNode] = distance;
          nextNode.connections[currentNode] = distance;
        }

        // Only connect first and last for rectangular path
        if (connectFirstLast && pathNodes.length > 1) {
          final firstNode = pathNodes.first;
          final lastNode = pathNodes.last;

          final circuitDistance =
              _calculateDistance(firstNode.location, lastNode.location);

          firstNode.connections[lastNode] = circuitDistance;
          lastNode.connections[firstNode] = circuitDistance;
        }
      }

      // Split nodes back into original paths
      final rectanglePathNodes =
          _graphNodes.sublist(0, rectangleFeatures.length);
      final middlePathNodes = _graphNodes.sublist(rectangleFeatures.length);

      // Connect nodes within each path
      // Only connect first and last for rectangular path
      connectNodesInPath(rectanglePathNodes, true);
      connectNodesInPath(middlePathNodes, false);

      // Optional: Add connections between paths if needed
      _connectPathsIfNecessary(rectanglePathNodes, middlePathNodes);
    } catch (e) {
      print('Error loading pathway graph: $e');
    }
  }

  // Optional method to connect paths if they are meant to intersect
  void _connectPathsIfNecessary(List<GraphNode> path1, List<GraphNode> path2) {
    // Find the closest points between the two paths and connect them
    GraphNode? closestNodePath1;
    GraphNode? closestNodePath2;
    double minDistance = double.infinity;

    for (var node1 in path1) {
      for (var node2 in path2) {
        final distance = _calculateDistance(node1.location, node2.location);
        if (distance < minDistance) {
          minDistance = distance;
          closestNodePath1 = node1;
          closestNodePath2 = node2;
        }
      }
    }

    // Connect the closest nodes if found
    if (closestNodePath1 != null && closestNodePath2 != null) {
      closestNodePath1.connections[closestNodePath2] = minDistance;
      closestNodePath2.connections[closestNodePath1] = minDistance;
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
