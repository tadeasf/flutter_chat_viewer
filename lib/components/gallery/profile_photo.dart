import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'photo_handler.dart';
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
    this.size = 50.0,
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
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _fetchProfilePhoto();
  }

  Future<void> _fetchProfilePhoto() async {
    if (widget.profilePhotoUrl != null) {
      setState(() {
        _imageUrl = widget.profilePhotoUrl;
        _isLoading = false;
      });
    } else {
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
  }

  void _toggleVisibility() {
    setState(() {
      _isVisible = !_isVisible;
    });
  }

  Future<void> _handlePhotoAction() async {
    if (_imageUrl != null) {
      // Delete photo
      await PhotoHandler.deletePhoto(widget.collectionName, (newState) {
        if (mounted) {
          setState(newState);
        }
      });
      if (mounted) {
        _fetchProfilePhoto(); // Refresh the photo status
      }
    } else {
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
        _fetchProfilePhoto(); // Refresh the photo status
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isVisible)
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
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _handlePhotoAction,
                child:
                    Text(_imageUrl != null ? 'Delete Photo' : 'Upload Photo'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _toggleVisibility,
                child: Text(_isVisible ? 'Hide Photo' : 'Show Photo'),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
