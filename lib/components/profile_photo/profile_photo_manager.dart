import '../api_db/api_service.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class ProfilePhotoManager {
  static final Map<String, String?> _profilePhotoUrls = {};

  static Future<String?> getProfilePhotoUrl(String collectionName) async {
    if (!_profilePhotoUrls.containsKey(collectionName)) {
      try {
        final url = ApiService.getProfilePhotoUrl(collectionName);
        _profilePhotoUrls[collectionName] = url;
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching profile photo URL: $e');
        }
        _profilePhotoUrls[collectionName] = null;
      }
    }
    return _profilePhotoUrls[collectionName];
  }
}
