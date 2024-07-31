import 'api_service.dart';

Future<void> loadCollections(
    Function(List<Map<String, dynamic>>) updateCollections) async {
  try {
    final loadedCollections = await ApiService.fetchCollections();
    updateCollections(loadedCollections);
  } catch (e) {
    print('Error fetching collections: $e');
  }
}
