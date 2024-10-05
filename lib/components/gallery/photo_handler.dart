import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:image_picker/image_picker.dart';
import '../api_db/api_service.dart';
import 'photo_gallery.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PhotoHandler {
  static XFile? image;
  static bool isPhotoAvailable = false;
  static bool isUploading = false;
  static String? imageUrl;

  static Future<void> handleShowAllPhotos(
      BuildContext context,
      String? selectedCollection,
      Function setState,
      List<dynamic> galleryPhotos,
      bool isGalleryLoading) async {
    if (selectedCollection == null) return;

    setState(() {
      isGalleryLoading = true;
    });

    try {
      final photoData = await ApiService.fetchPhotos(selectedCollection);
      final photoUrls = photoData
          .expand((msg) => (msg['photos'] as List)
              .map((photo) => ApiService.getPhotoUrl(photo['fullUri'])))
          .toList();

      setState(() {
        galleryPhotos = photoUrls;
        isGalleryLoading = false;
      });

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoGallery(photos: galleryPhotos),
          ),
        );
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching photos: $error');
      }
      setState(() {
        isGalleryLoading = false;
      });
    }
  }

  static Future<void> getImage(ImagePicker picker, Function setState) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        image = pickedFile;
      }
    });
  }

  static Future<void> uploadImage(BuildContext context, XFile? image,
      String? selectedCollection, Function setState) async {
    if (image == null || selectedCollection == null) return;

    setState(() {
      isUploading = true;
    });

    try {
      // Read the file as bytes
      List<int> imageBytes = await image.readAsBytes();
      // Convert to base64
      String base64Image = base64Encode(imageBytes);

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}/upload/photo/$selectedCollection'),
        headers: {
          'Content-Type': 'application/json',
          'X-API-KEY': ApiService.apiKey ?? '',
        },
        body: jsonEncode({
          'photo': base64Image,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          isUploading = false;
          imageUrl = '${ApiService.baseUrl}/serve/photo/$selectedCollection';
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Photo uploaded successfully')));
          await checkPhotoAvailability(selectedCollection, setState);
        }
      } else {
        throw Exception('Failed to upload image: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error uploading photo: $e');
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error uploading photo')));
      }
    } finally {
      setState(() {
        isUploading = false;
      });
    }
  }

  static Future<void> checkPhotoAvailability(
      String? selectedCollection, Function setState) async {
    if (selectedCollection == null) return;

    try {
      final isAvailable =
          await ApiService.checkPhotoAvailability(selectedCollection);
      setState(() {
        isPhotoAvailable = isAvailable;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error checking photo availability: $e');
      }
    }
  }

  static Future<void> deletePhoto(
      String collectionName, Function setState) async {
    try {
      await ApiService.deletePhoto(collectionName);
      setState(() {
        isPhotoAvailable = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting photo: $e');
      }
      throw Exception('Failed to delete photo');
    }
  }
}
