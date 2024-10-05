import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiService {
  static const String baseUrl = 'https://backend.jevrej.cz';
  static final String? apiKey = dotenv.env['X_API_KEY'];

  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
        'X-API-KEY': apiKey ?? '',
      };

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

  static Future<void> uploadPhoto(String collectionName, File imageFile) async {
    final url = Uri.parse(
        '$baseUrl/upload/photo/${Uri.encodeComponent(collectionName)}');

    // Read the image file as bytes and encode to base64
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Prepare the request body
    final body = jsonEncode({
      'photo': base64Image,
    });

    // Send the POST request
    final response = await http.post(
      url,
      headers: headers,
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to upload photo: ${response.statusCode}');
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
    final processedUri = uri.replaceFirst('messages/inbox/', '');
    return '$baseUrl/inbox/$processedUri';
  }

  static Future<void> deletePhoto(String collectionName) async {
    final url = Uri.parse(
        '$baseUrl/delete/photo/${Uri.encodeComponent(collectionName)}');
    final response = await http.delete(url, headers: headers);
    if (response.statusCode != 200) {
      throw Exception('Failed to delete photo');
    }
  }

  static String getProfilePhotoUrl(String collectionName) {
    return '$baseUrl/serve/photo/${Uri.encodeComponent(collectionName)}';
  }

  // Update this method to match fetchCollections
  static Future<List<Map<String, dynamic>>> fetchCollectionsPaginated() async {
    return fetchCollections(); // Since pagination is not implemented on the server side
  }
}
