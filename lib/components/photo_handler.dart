import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'api_service.dart';
import 'photo_gallery.dart';

class PhotoHandler {
  static File? image; // Define the _image variable
  static bool isPhotoAvailable = false; // Define the isPhotoAvailable variable

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
              .map((photo) => ApiService.getPhotoUrl(photo['uri'])))
          .toList();

      setState(() {
        galleryPhotos = photoUrls;
        isGalleryLoading = false;
      });

      // Navigate to the PhotoGallery
      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PhotoGallery(photos: galleryPhotos),
          ),
        );
      }
    } catch (error) {
      print('Failed to fetch photo data: $error');
      setState(() {
        isGalleryLoading = false;
      });
    }
  }

  static Future<void> getImage(ImagePicker picker, Function setState) async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        image = File(pickedFile.path);
      }
    });
  }

  static Future<void> uploadImage(BuildContext context, File? image,
      String? selectedCollection, Function setState) async {
    if (image == null || selectedCollection == null) return;

    try {
      await ApiService.uploadPhoto(selectedCollection, image);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Photo uploaded successfully')));
        checkPhotoAvailability(selectedCollection, setState);
      }
    } catch (e) {
      print('Error uploading photo: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error uploading photo')));
      }
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
      print('Error checking photo availability: $e');
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
      print('Error deleting photo: $e');
    }
  }
}
