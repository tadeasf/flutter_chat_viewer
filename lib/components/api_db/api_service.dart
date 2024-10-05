import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // Add this import for File
import 'package:http_parser/http_parser.dart'; // Add this import for MediaType
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add this import for dotenv

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
                'name': item['name'].toString(),
                'messageCount': item['messageCount'] as int,
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
    var request = http.MultipartRequest('POST', url)
      ..headers.addAll(headers)
      ..files.add(await http.MultipartFile.fromPath(
        'photo',
        imageFile.path,
        contentType: MediaType('image', 'jpeg'),
      ));
    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode != 200) {
      throw Exception('Failed to upload photo');
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

  // Update this method to fetch all collections without pagination
  static Future<List<Map<String, dynamic>>> fetchCollectionsPaginated() async {
    final response =
        await http.get(Uri.parse('$baseUrl/collections'), headers: headers);
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data
          .map((item) => {
                'name': item['name'].toString(),
                'messageCount': item['messageCount'] as int,
              })
          .toList();
    } else {
      throw Exception('Failed to load collections');
    }
  }
}
