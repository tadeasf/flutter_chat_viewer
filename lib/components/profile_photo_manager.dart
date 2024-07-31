import 'api_service.dart';

class ProfilePhotoManager {
  static final Map<String, String?> _profilePhotoUrls = {};

  static Future<String?> getProfilePhotoUrl(String collectionName) async {
    if (!_profilePhotoUrls.containsKey(collectionName)) {
      try {
        final url = ApiService.getProfilePhotoUrl(collectionName);
        _profilePhotoUrls[collectionName] = url;
      } catch (e) {
        print('Error fetching profile photo URL: $e');
        _profilePhotoUrls[collectionName] = null;
      }
    }
    return _profilePhotoUrls[collectionName];
  }
}
