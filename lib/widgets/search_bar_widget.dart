import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final Function(String) onSearch;
  final Function(String, Map<String, LatLng>) onSuggestionSelected;
  final List<String> recentSearches;
  final List<dynamic> suggestions;
  final Map<String, LatLng> roomlocation;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onSearch,
    required this.onSuggestionSelected,
    required this.recentSearches,
    required this.suggestions,
    required this.roomlocation,
  });

  @override
  Widget build(BuildContext context) {
    // Debug prints
    // print("debigs");
    // print('Current suggestions: $suggestions');
    // print('Recent searches: $recentSearches');
    // print('Search text: ${controller.text}');

    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Search places...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        controller.clear();
                        onSearch('');
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: onSearch,
          ),
        ),
        // Modified visibility condition
        if (suggestions.isNotEmpty || recentSearches.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.4,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: ListView(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              children: [
                // Recent searches section
                if (recentSearches.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Recent Searches',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ...recentSearches.map(
                    (search) => ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(search),
                      onTap: () {
                        controller.text = search;
                        onSearch(search);
                      },
                    ),
                  ),
                ],
                // Suggestions section
                if (suggestions.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'Suggestions',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ...suggestions.map(
                    (suggestion) => ListTile(
                      leading: const Icon(Icons.location_on),
                      title: Text(suggestion['description']),
                      onTap: () {
                        controller.clear();
                        onSearch('');
                        onSuggestionSelected(
                          suggestion['place_id'],
                          roomlocation,
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
