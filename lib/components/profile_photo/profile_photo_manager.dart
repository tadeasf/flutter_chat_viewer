import '../api_db/api_service.dart';
import 'package:logging/logging.dart';

class ProfilePhotoManager {
  static final Logger _logger = Logger('ProfilePhotoManager');
  static final Map<String, String?> _profilePhotoUrls = {};

  static Future<String?> getProfilePhotoUrl(String collectionName) async {
    try {
      final isPhotoAvailable =
          await ApiService.checkPhotoAvailability(collectionName);
      if (!isPhotoAvailable) {
        _profilePhotoUrls.remove(collectionName);
        return null;
      }

      final url = ApiService.getProfilePhotoUrl(collectionName);
      _profilePhotoUrls[collectionName] = url;
      return url;
    } catch (e) {
      _logger.warning('Error fetching profile photo URL: $e');
      _profilePhotoUrls.remove(collectionName);
      return null;
    }
  }

  static void clearCache(String collectionName) {
    _profilePhotoUrls.remove(collectionName);
  }

  static void clearAllCache() {
    _profilePhotoUrls.clear();
  }
}
