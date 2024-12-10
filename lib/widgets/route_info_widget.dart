import 'package:flutter/material.dart';

class RouteInfoWidget extends StatelessWidget {
  final String distance;
  final String duration;
  final VoidCallback onClearRoute;

  const RouteInfoWidget({
    Key? key,
    required this.distance,
    required this.duration,
    required this.onClearRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Row(
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
                    duration,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                distance,
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
    );
  }
}
