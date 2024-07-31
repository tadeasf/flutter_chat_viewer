import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

Future<void> loadCollections(
    Function(List<Map<String, dynamic>>) updateCollections) async {
  try {
    // Try to load cached collections first
    final prefs = await SharedPreferences.getInstance();
    final cachedCollections = prefs.getString('cachedCollections');

    if (cachedCollections != null) {
      final List<Map<String, dynamic>> collections =
          List<Map<String, dynamic>>.from(json.decode(cachedCollections))
              .where((collection) => collection['name'] != 'unified_collection')
              .toList();
      updateCollections(collections);
    }

    // Fetch new collections
    final loadedCollections = (await ApiService.fetchCollectionsPaginated())
        .where((collection) => collection['name'] != 'unified_collection')
        .toList();
    updateCollections(loadedCollections);

    // Cache the new collections
    await prefs.setString('cachedCollections', json.encode(loadedCollections));
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching collections: $e');
    }
  }
}

Future<List<Map<String, dynamic>>> loadMoreCollections() async {
  try {
    return (await ApiService.fetchCollectionsPaginated())
        .where((collection) => collection['name'] != 'unified_collection')
        .toList();
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching more collections: $e');
    }
    return [];
  }
}
