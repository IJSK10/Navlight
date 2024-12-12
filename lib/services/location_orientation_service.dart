import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_compass/flutter_compass.dart';

class LocationOrientationService {
  StreamController<LocationOrientationData> _dataController =
      StreamController<LocationOrientationData>.broadcast();

  Stream<LocationOrientationData> get locationOrientationStream =>
      _dataController.stream;

  StreamSubscription? _compassSubscription;
  StreamSubscription? _accelerometerSubscription;
  StreamSubscription? _positionSubscription;

  double _compassHeading = 0.0;
  double _accelerometerX = 0.0;
  double _accelerometerY = 0.0;
  double _accelerometerZ = 0.0;
  Position? _lastPosition;

  LocationOrientationService() {
    _initSensorListeners();
  }

  void _initSensorListeners() {
    _compassSubscription = FlutterCompass.events?.listen((CompassEvent event) {
      _compassHeading = event.heading ?? 0.0;
      _emitLocationData();
    });

    _accelerometerSubscription =
        accelerometerEvents.listen((AccelerometerEvent event) {
      _accelerometerX = event.x;
      _accelerometerY = event.y;
      _accelerometerZ = event.z;
      _emitLocationData();
    });

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((Position position) {
      _lastPosition = position;
      _emitLocationData();
    });
  }

  void _emitLocationData() {
    if (_lastPosition != null) {
      final orientationData = LocationOrientationData(
        latitude: _lastPosition!.latitude,
        longitude: _lastPosition!.longitude,
        heading: _compassHeading,
        accuracy: _lastPosition!.accuracy,
        speed: _lastPosition!.speed,
        accelerometerX: _accelerometerX,
        accelerometerY: _accelerometerY,
        accelerometerZ: _accelerometerZ,
      );

      _dataController.add(orientationData);
    }
  }

  double calculateDeviceMovementDirection() {
    double magnitude = sqrt(pow(_accelerometerX, 2) +
        pow(_accelerometerY, 2) +
        pow(_accelerometerZ, 2));

    double direction = atan2(_accelerometerY, _accelerometerX);

    return direction;
  }

  Future<bool> checkLocationPermissions() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  void dispose() {
    _compassSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    _positionSubscription?.cancel();
    _dataController.close();
  }
}

class LocationOrientationData {
  final double latitude;
  final double longitude;
  final double heading;
  final double accuracy;
  final double speed;
  final double accelerometerX;
  final double accelerometerY;
  final double accelerometerZ;

  LocationOrientationData({
    required this.latitude,
    required this.longitude,
    required this.heading,
    required this.accuracy,
    required this.speed,
    required this.accelerometerX,
    required this.accelerometerY,
    required this.accelerometerZ,
  });

  @override
  String toString() {
    return 'LocationOrientationData(lat: $latitude, lon: $longitude, '
        'heading: $heading, speed: $speed)';
  }
}
