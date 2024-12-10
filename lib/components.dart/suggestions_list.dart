import 'package:flutter/material.dart';

class SuggestionsList extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions;
  final List<String> recentSearches;
  final Function(Map<String, dynamic>) onSuggestionTap;
  final Function(String) onRecentSearchTap;

  const SuggestionsList({
    super.key,
    required this.suggestions,
    required this.recentSearches,
    required this.onSuggestionTap,
    required this.onRecentSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
        children: [
          if (suggestions.isEmpty && recentSearches.isNotEmpty) ...[
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
                onTap: () => onRecentSearchTap(search),
              ),
            ),
          ],
          if (suggestions.isNotEmpty)
            ...suggestions.map(
              (suggestion) => ListTile(
                leading: const Icon(Icons.location_on),
                title: Text(suggestion['description']),
                onTap: () => onSuggestionTap(suggestion),
              ),
            ),
        ],
      ),
    );
  }
}
