import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../api_db/api_service.dart';
import 'photo_gallery.dart';
import 'dart:convert';
import 'package:logging/logging.dart';

class PhotoHandler {
  static final Logger _logger = Logger('PhotoHandler');
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

    // Immediately open the gallery with a loading skeleton
    if (context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoGallery(
            photos: [],
            isLoading: true,
            collectionName: selectedCollection,
          ),
        ),
      );
    }

    try {
      final photoData = await ApiService.fetchPhotos(selectedCollection);

      if (context.mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoGallery(
              photos: photoData,
              isLoading: false,
              collectionName: selectedCollection,
            ),
          ),
        );
      }
    } catch (error) {
      _logger.warning('Error fetching photos: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load photos')),
        );
      }
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
      List<int> imageBytes = await image.readAsBytes();
      String base64Image = base64Encode(imageBytes);

      // Ensure we're sending a proper JSON object with the photo as a string
      final photoData = {
        'photo': base64Image,
      };

      await ApiService.uploadPhoto(selectedCollection, photoData);

      setState(() {
        isUploading = false;
        imageUrl = ApiService.getProfilePhotoUrl(selectedCollection);
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded successfully')));
        await checkPhotoAvailability(selectedCollection, setState);
      }
    } catch (e) {
      _logger.warning('Error uploading photo: $e');
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
      _logger.warning('Error checking photo availability: $e');
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
      _logger.warning('Error deleting photo: $e');
      throw Exception('Failed to delete photo');
    }
  }
}
