// components/photo_gallery.dart

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'photo_view_screen.dart';
import '../api_db/api_service.dart';

class PhotoGallery extends StatelessWidget {
  final List<dynamic> photos;
  final bool isLoading;
  final String collectionName;

  const PhotoGallery({
    super.key,
    required this.photos,
    required this.isLoading,
    required this.collectionName,
  });

  String _getPhotoUrl(dynamic photo) {
    if (photo is Map<String, dynamic> && photo.containsKey('photos')) {
      var photoData = photo['photos'][0];
      if (photoData.containsKey('uri')) {
        String uri = photoData['uri'];
        return ApiService.getPhotoUrl(uri);
      }
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Photo Gallery')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Photo Gallery')),
      body: photos.isEmpty
          ? const Center(child: Text('No photos available'))
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photoUrl = _getPhotoUrl(photos[index]);

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            PhotoViewScreen(imageUrl: photoUrl),
                      ),
                    );
                  },
                  child: CachedNetworkImage(
                    imageUrl: photoUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.error, color: Colors.red),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
