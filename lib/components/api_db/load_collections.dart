import 'api_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

Future<void> loadCollections(
    Function(List<Map<String, dynamic>>) updateCollections) async {
  try {
    final loadedCollections = await ApiService.fetchCollections();
    updateCollections(loadedCollections);
  } catch (e) {
    if (kDebugMode) {
      print('Error fetching collections: $e');
    }
  }
}
