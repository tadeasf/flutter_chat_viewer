import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'photo_view_screen.dart';
import '../api_db/api_service.dart';
import 'dart:async';
import 'package:logging/logging.dart';

class PhotoGallery extends StatefulWidget {
  final String collectionName;

  const PhotoGallery({
    super.key,
    required this.collectionName,
  });

  @override
  State<PhotoGallery> createState() => _PhotoGalleryState();
}

class _PhotoGalleryState extends State<PhotoGallery> {
  final Logger _logger = Logger('PhotoGallery');
  List<dynamic> photos = [];
  bool isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchPhotos() async {
    try {
      final fetchedPhotos = await ApiService.fetchPhotos(widget.collectionName);
      setState(() {
        photos = fetchedPhotos;
        isLoading = false;
      });

      if (photos.isEmpty) {
        // If photos are empty, start periodic checks
        _startPeriodicChecks();
      }
    } catch (e) {
      _logger.warning('Error fetching photos: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _startPeriodicChecks() {
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final fetchedPhotos =
            await ApiService.fetchPhotos(widget.collectionName);
        if (fetchedPhotos.isNotEmpty) {
          setState(() {
            photos = fetchedPhotos;
          });
          _timer?.cancel(); // Stop checking once we have photos
        }
      } catch (e) {
        _logger.warning('Error during periodic check: $e');
      }
    });
  }

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
