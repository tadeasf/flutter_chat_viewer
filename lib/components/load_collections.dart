import 'api_service.dart';

Future<void> loadCollections(
    Function setState, List<String> collections) async {
  try {
    final loadedCollections = await ApiService.fetchCollections();
    setState(() {
      collections = loadedCollections;
    });
  } catch (e) {
    print('Error fetching collections: $e');
  }
}
