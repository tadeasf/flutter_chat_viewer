import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'photo_handler.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePhoto extends StatefulWidget {
  final String collectionName;
  final double size;
  final bool isOnline;
  final bool showButtons;

  const ProfilePhoto({
    super.key,
    required this.collectionName,
    this.size = 50.0,
    this.isOnline = false,
    this.showButtons = true,
  });

  @override
  _ProfilePhotoState createState() => _ProfilePhotoState();
}

class _ProfilePhotoState extends State<ProfilePhoto> {
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
    try {
      final requestUrl = ApiService.getProfilePhotoUrl(widget.collectionName);
      print('Fetching profile photo from: $requestUrl'); // Debug print
      final response = await http.get(Uri.parse(requestUrl));
      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _imageUrl = requestUrl;
            _isLoading = false;
          });
          print('Profile photo fetched successfully'); // Debug print
        }
      } else {
        if (mounted) {
          setState(() {
            _isError = true;
            _isLoading = false;
          });
          print(
              'Error fetching profile photo: ${response.statusCode}'); // Debug print
        }
      }
    } catch (e) {
      print('Error fetching profile photo: $e');
      if (mounted) {
        setState(() {
          _isError = true;
          _isLoading = false;
        });
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
                  child: Center(child: CircularProgressIndicator()),
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
                      return Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print('Error loading image: $error'); // Debug print
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
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _handlePhotoAction,
                child:
                    Text(_imageUrl != null ? 'Delete Photo' : 'Upload Photo'),
              ),
              SizedBox(width: 8),
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
