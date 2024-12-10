import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/place.dart';

class PlaceDetailsSheet extends StatelessWidget {
  final Place place;
  final VoidCallback onGetDirections;

  const PlaceDetailsSheet({
    super.key,
    required this.place,
    required this.onGetDirections,
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
            // Drag handle
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
            // Place name
            Text(
              place.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            // Rating
            if (place.rating != null)
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  Text(
                    ' ${place.rating}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            const SizedBox(height: 8),
            // Address
            Text(
              place.address,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            // Phone number
            if (place.phoneNumber != null)
              ListTile(
                leading: const Icon(Icons.phone),
                title: Text(place.phoneNumber!),
                onTap: () async {
                  final url = 'tel:${place.phoneNumber}';
                  if (await canLaunchUrl(Uri.parse(url))) {
                    await launchUrl(Uri.parse(url));
                  }
                },
              ),
            // Opening hours
            if (place.openingHours != null && place.openingHours!.isNotEmpty)
              ExpansionTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Opening Hours'),
                children: [
                  ...place.openingHours!.map(
                    (hours) => Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(hours.toString()),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 16),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    onGetDirections();
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.directions),
                  label: const Text('Directions'),
                ),
                if (place.website != null)
                  ElevatedButton.icon(
                    onPressed: () async {
                      if (await canLaunchUrl(Uri.parse(place.website!))) {
                        await launchUrl(
                          Uri.parse(place.website!),
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    icon: const Icon(Icons.language),
                    label: const Text('Website'),
                  ),
                ElevatedButton.icon(
                  onPressed: () {
                    final text = '${place.name}\n'
                        '${place.address}\n'
                        'Rating: ${place.rating ?? 'N/A'}\n'
                        '${place.website ?? ''}';
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
