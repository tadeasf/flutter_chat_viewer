import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import '../gallery/photo_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'profile_photo_manager.dart';

class ProfilePhoto extends StatefulWidget {
  final String collectionName;
  final double size;
  final bool isOnline;
  final bool showButtons;
  final String? profilePhotoUrl;

  const ProfilePhoto({
    super.key,
    required this.collectionName,
    this.size = 100.0,
    this.isOnline = false,
    this.showButtons = true,
    this.profilePhotoUrl,
  });

  @override
  ProfilePhotoState createState() => ProfilePhotoState();
}

class ProfilePhotoState extends State<ProfilePhoto> {
  String? _imageUrl;
  bool _isLoading = true;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _fetchProfilePhoto();
  }

  Future<void> _fetchProfilePhoto() async {
    try {
      final url =
          await ProfilePhotoManager.getProfilePhotoUrl(widget.collectionName);
      if (mounted) {
        setState(() {
          _imageUrl = url;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching profile photo: $e');
      }
      if (mounted) {
        setState(() {
          _isError = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePhotoAction(bool isUpload) async {
    setState(() => _isLoading = true);
    try {
      if (isUpload) {
        // Upload photo
        await PhotoHandler.getImage(ImagePicker(), (newState) {
          if (mounted) {
            setState(newState);
          }
        });
        if (PhotoHandler.image != null && mounted) {
          await PhotoHandler.uploadImage(
            context,
            PhotoHandler.image,
            widget.collectionName,
            (newState) {
              if (mounted) {
                setState(newState);
              }
            },
          );
        }
      } else {
        // Delete photo
        await PhotoHandler.deletePhoto(widget.collectionName, (newState) {
          if (mounted) {
            setState(newState);
          }
        });
      }
      _fetchProfilePhoto(); // Refresh the photo status
    } catch (e) {
      if (kDebugMode) {
        print('Error ${isUpload ? 'uploading' : 'deleting'} photo: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Failed to ${isUpload ? 'upload' : 'delete'} photo. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            if (_isLoading)
              Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey[300],
                ),
                child: const Center(child: CircularProgressIndicator()),
              )
            else if (_isError || _imageUrl == null)
              Icon(
                Icons.account_circle,
                size: widget.size,
                color: Colors.grey,
              )
            else
              ClipOval(
                child: Image.network(
                  _imageUrl!,
                  width: widget.size,
                  height: widget.size,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(child: CircularProgressIndicator());
                  },
                  errorBuilder: (context, error, stackTrace) {
                    if (kDebugMode) {
                      print('Error loading image: $error');
                    } // Debug print
                    return Icon(
                      Icons.account_circle,
                      size: widget.size,
                      color: Colors.grey,
                    );
                  },
                ),
              ),
            if (widget.isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: widget.size * 0.3,
                  height: widget.size * 0.3,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        if (widget.showButtons) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => _handlePhotoAction(false),
                tooltip: 'Delete Photo',
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.upload),
                onPressed: () => _handlePhotoAction(true),
                tooltip: 'Upload Photo',
              ),
            ],
          ),
        ],
      ],
    );
  }
}
