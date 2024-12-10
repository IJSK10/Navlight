import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class PlaceDetails extends StatelessWidget {
  final Map<String, dynamic> place;
  final LatLng? currentLocation;
  final LatLng? destinationLocation;
  final Function(LatLng, LatLng) getDirections;

  const PlaceDetails({
    super.key,
    required this.place,
    required this.currentLocation,
    required this.destinationLocation,
    required this.getDirections,
  });

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.8,
      builder: (context, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(16),
        child: ListView(
          controller: scrollController,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              place['name'] ?? 'Unknown Place',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (place['rating'] != null)
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  Text(
                    ' ${place['rating']}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            Text(
              place['formatted_address'] ?? '',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            if (place['formatted_phone_number'] != null)
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(place['formatted_phone_number']),
                onTap: () async {
                  final url = 'tel:${place['formatted_phone_number']}';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  }
                },
              ),
            if (place['opening_hours']?['weekday_text'] != null)
              ExpansionTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Opening Hours'),
                children: [
                  ...place['opening_hours']['weekday_text']
                      .map((hours) => Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(hours),
                          ))
                      .toList(),
                ],
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    print("getdirecr");
                    if (currentLocation != null &&
                        destinationLocation != null) {
                      print("call getdirec");
                      getDirections(currentLocation!, destinationLocation!);
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                ),
                if (place['website'] != null)
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (await canLaunchUrl(Uri.parse(place['website']))) {
                        await launchUrl(
                          Uri.parse(place['website']),
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    icon: const Icon(Icons.language),
                    label: const Text('Website'),
                  ),
                ElevatedButton.icon(
                  onPressed: () {
                    final text = '${place['name']}\n'
                        '${place['formatted_address']}\n'
                        'Rating: ${place['rating'] ?? 'N/A'}\n'
                        '${place['website'] ?? ''}';
                    Share.share(text);
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Share'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
