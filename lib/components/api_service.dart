import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io'; // Add this import for File
import 'package:http_parser/http_parser.dart'; // Add this import for MediaType

class ApiService {
  static const String baseUrl = 'https://secondary.dev.tadeasfort.com';

  static Future<List<String>> fetchCollections() async {
    final response = await http.get(Uri.parse('$baseUrl/collections'));
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((item) => item['name'].toString()).toList();
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
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load messages');
    }
  }

  static Future<bool> checkPhotoAvailability(String collectionName) async {
    final url = Uri.parse(
        '$baseUrl/messages/${Uri.encodeComponent(collectionName)}/photo');
    final response = await http.get(url);
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
    var request = http.MultipartRequest('POST', url);
    request.files.add(await http.MultipartFile.fromPath(
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
}
