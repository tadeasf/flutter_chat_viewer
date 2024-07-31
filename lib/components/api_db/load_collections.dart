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
          List<Map<String, dynamic>>.from(json.decode(cachedCollections));
      updateCollections(collections);
    }

    // Fetch new collections (first page)
    final loadedCollections = await ApiService.fetchCollectionsPaginated(1, 20);
    updateCollections(loadedCollections);

    // Cache the new collections
    await prefs.setString('cachedCollections', json.encode(loadedCollections));
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching collections: $e');
    }
  }
}

Future<List<Map<String, dynamic>>> loadMoreCollections(
    int page, int pageSize) async {
  try {
    return await ApiService.fetchCollectionsPaginated(page, pageSize);
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching more collections: $e');
    }
    return [];
  }
}
