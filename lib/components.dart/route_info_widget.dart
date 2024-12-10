import 'package:flutter/material.dart';

class RouteInfoWidget extends StatelessWidget {
  final String routeDistance;
  final String routeDuration;
  final VoidCallback onClearRoute;

  const RouteInfoWidget({
    super.key,
    required this.routeDistance,
    required this.routeDuration,
    required this.onClearRoute,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                      const Icon(Icons.directions_car, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        routeDuration,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    routeDistance,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: onClearRoute,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text('Clear Route'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
