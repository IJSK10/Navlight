import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

class NavigationService {
  static double calculateDistance(LatLng point1, LatLng point2) {
    return Geolocator.distanceBetween(
        point1.latitude, point1.longitude, point2.latitude, point2.longitude);
  }

  static LatLng findClosestPointOnRoute(
      LatLng currentLocation, List<LatLng> routePoints) {
    return routePoints.reduce((closest, point) =>
        calculateDistance(currentLocation, point) <
                calculateDistance(currentLocation, closest)
            ? point
            : closest);
  }

  static LatLng findNextWaypoint(
      LatLng currentLocation, List<LatLng> routePoints) {
    int currentIndex = routePoints.indexWhere((point) =>
        calculateDistance(currentLocation, point) < 10); // within 10 meters

    return currentIndex < routePoints.length - 1
        ? routePoints[currentIndex + 1]
        : routePoints.last;
  }

  static double calculateBearing(LatLng point1, LatLng point2) {
    double lat1 = point1.latitude * pi / 180;
    double lon1 = point1.longitude * pi / 180;
    double lat2 = point2.latitude * pi / 180;
    double lon2 = point2.longitude * pi / 180;

    double dLon = lon2 - lon1;

    double y = sin(dLon) * cos(lat2);
    double x = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    double brng = atan2(y, x);

    return (brng * 180 / pi + 360) % 360;
  }

  static String generateTurnInstruction(
      LatLng currentLocation, LatLng nextWaypoint, double currentBearing) {
    double bearingToNextPoint = calculateBearing(currentLocation, nextWaypoint);
    double angleDifference = (bearingToNextPoint - currentBearing + 360) % 360;

    if (angleDifference < 22.5 || angleDifference > 337.5) {
      return 'Continue straight';
    } else if (angleDifference >= 22.5 && angleDifference < 67.5) {
      return 'Slight right';
    } else if (angleDifference >= 67.5 && angleDifference < 112.5) {
      return 'Turn right';
    } else if (angleDifference >= 112.5 && angleDifference < 157.5) {
      return 'Sharp right';
    } else if (angleDifference >= 157.5 && angleDifference < 202.5) {
      return 'U-turn';
    } else if (angleDifference >= 202.5 && angleDifference < 247.5) {
      return 'Sharp left';
    } else if (angleDifference >= 247.5 && angleDifference < 292.5) {
      return 'Turn left';
    } else {
      return 'Slight left';
    }
  }

  static String formatRemainingDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} km';
    }
  }
}
