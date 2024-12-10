import 'package:flutter/material.dart';

class RouteSelectionWidget extends StatelessWidget {
  final Map<String, dynamic> routes;
  final String? selectedMode;
  final Function(String) onRouteSelected;
  final VoidCallback onClearRoute;
  final VoidCallback onStartNavigation;

  const RouteSelectionWidget({
    super.key,
    required this.routes,
    this.selectedMode,
    required this.onRouteSelected,
    required this.onClearRoute,
    required this.onStartNavigation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: routes.keys.map((mode) {
              final route = routes[mode];
              return Expanded(
                child: GestureDetector(
                  onTap: () => onRouteSelected(mode),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: selectedMode == mode
                          ? Colors.blue.shade50
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: selectedMode == mode
                              ? Colors.blue
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getIconForMode(mode),
                          color:
                              selectedMode == mode ? Colors.blue : Colors.grey,
                        ),
                        Text(
                          mode.capitalizeFirst(),
                          style: TextStyle(
                            color: selectedMode == mode
                                ? Colors.blue
                                : Colors.grey,
                          ),
                        ),
                        Text(
                          '${route.distance} | ${route.duration}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: onClearRoute,
              ),
              if (selectedMode != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.navigation),
                  label: const Text('Start'),
                  onPressed: onStartNavigation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIconForMode(String mode) {
    switch (mode) {
      case 'driving':
        return Icons.car_rental;
      case 'walking':
        return Icons.directions_walk;
      case 'transit':
        return Icons.directions_transit;
      default:
        return Icons.route;
    }
  }
}

// Extension to capitalize first letter of a string
extension StringExtension on String {
  String capitalizeFirst() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
