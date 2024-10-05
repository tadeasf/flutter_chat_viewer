import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static const String baseUrl = 'https://backend.jevrej.cz';
  static final String? apiKey = dotenv.env['X_API_KEY'];
  static final Map<String, String> _profilePhotoUrls = {};

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'X-API-KEY': apiKey ?? '',
      };

  static Future<http.Response> get(String endpoint) async {
    return await http.get(Uri.parse('$baseUrl$endpoint'), headers: headers);
  }

  static Future<http.Response> post(String endpoint, {Object? body}) async {
    return await http.post(Uri.parse('$baseUrl$endpoint'),
        headers: headers, body: jsonEncode(body));
  }

  static Future<List<Map<String, dynamic>>> fetchCollections() async {
    final response =
        await http.get(Uri.parse('$baseUrl/collections'), headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data
          .map((item) => {
                'name': item['name'] as String,
                'messageCount': item['messageCount'] as int? ?? 0,
              })
          .toList();
    } else {
      throw Exception('Failed to load collections');
    }
  }

  static Future<List<dynamic>> fetchMessages(String collectionName,
      {String? fromDate, String? toDate}) async {
    String url = '$baseUrl/messages/${Uri.encodeComponent(collectionName)}';
    if (fromDate != null || toDate != null) {
      List<String> queryParams = [];
      if (fromDate != null) queryParams.add('fromDate=$fromDate');
      if (toDate != null) queryParams.add('toDate=$toDate');
      url += '?${queryParams.join('&')}';
    }
    final response = await http.get(Uri.parse(url), headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load messages');
    }
  }

  static Future<int> fetchMessageCount(String collectionName) async {
    final response = await http.get(
        Uri.parse(
            '$baseUrl/messages/${Uri.encodeComponent(collectionName)}/count'),
        headers: headers);
    if (response.statusCode == 200) {
      Map<String, dynamic> data = json.decode(response.body);
      return data['count'] as int;
    } else {
      throw Exception('Failed to load message count');
    }
  }

  static Future<bool> checkPhotoAvailability(String collectionName) async {
    final url = Uri.parse(
        '$baseUrl/messages/${Uri.encodeComponent(collectionName)}/photo');
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['isPhotoAvailable'];
    } else {
      throw Exception('Failed to check photo availability');
    }
  }

  static Future<void> uploadPhoto(
      String collectionName, Map<String, String> photoData) async {
    final url = Uri.parse(
        '$baseUrl/upload/photo/${Uri.encodeComponent(collectionName)}');

    final response = await http.post(
      url,
      headers: {
        ...headers,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(photoData),
    );

    if (response.statusCode != 200) {
      throw Exception(
          'Failed to upload photo: ${response.statusCode}\n${response.body}');
    }
  }

  static Future<List<dynamic>> fetchPhotos(String collectionName) async {
    final url =
        Uri.parse('$baseUrl/photos/${Uri.encodeComponent(collectionName)}');
    final response = await http.get(url, headers: headers);
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load photos');
    }
  }

  static String getPhotoUrl(String uri) {
    return '$baseUrl/inbox/${uri.replaceFirst('messages/inbox/', '')}';
  }

  static Future<Map<String, dynamic>> deletePhoto(String collectionName) async {
    final url = Uri.parse(
        '$baseUrl/delete/photo/${Uri.encodeComponent(collectionName)}');
    final response = await http.delete(
      url,
      headers: headers,
      body: '{}', // Send an empty JSON object as the body
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Clear the cached photo URL for this collection
      _profilePhotoUrls.remove(collectionName);
      return {
        'success': true,
        'message': data['message'],
      };
    } else {
      String errorMessage;
      try {
        final errorData = json.decode(response.body);
        errorMessage = errorData['message'] ?? 'Failed to delete photo';
      } catch (e) {
        errorMessage = 'Failed to delete photo: ${response.body}';
      }
      return {
        'success': false,
        'message': errorMessage,
      };
    }
  }

  static String getProfilePhotoUrl(String collectionName) {
    // Check if we have a cached URL
    if (_profilePhotoUrls.containsKey(collectionName)) {
      return _profilePhotoUrls[collectionName]!;
    }
    // If not, generate a new URL with a timestamp to prevent caching
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final url =
        '$baseUrl/serve/photo/${Uri.encodeComponent(collectionName)}?t=$timestamp';
    _profilePhotoUrls[collectionName] = url;
    return url;
  }

  // Update this method to match fetchCollections
  static Future<List<Map<String, dynamic>>> fetchCollectionsPaginated() async {
    return fetchCollections(); // Since pagination is not implemented on the server side
  }
}
