import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePhoto extends StatefulWidget {
  final String collectionName;
  final double size;
  final bool isOnline;

  const ProfilePhoto({
    super.key,
    required this.collectionName,
    this.size = 50.0,
    this.isOnline = false,
  });

  @override
  _ProfilePhotoState createState() => _ProfilePhotoState();
}

class _ProfilePhotoState extends State<ProfilePhoto> {
  String? _imageUrl;
  bool _isLoading = true;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    _loadCachedPhoto();
  }

  Future<void> _loadCachedPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString('profile_photo_${widget.collectionName}');
    if (cachedUrl != null) {
      setState(() {
        _imageUrl = cachedUrl;
        _isLoading = false;
      });
    } else {
      _fetchProfilePhoto();
    }
  }

  Future<void> _fetchProfilePhoto() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://secondary.dev.tadeasfort.com/messages/${widget.collectionName}/photo'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['isPhotoAvailable'] == true && data['photoUrl'] != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(
              'profile_photo_${widget.collectionName}', data['photoUrl']);
          if (mounted) {
            setState(() {
              _imageUrl = data['photoUrl'];
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _isError = true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        if (_isLoading)
          SizedBox(
            width: widget.size,
            height: widget.size,
            child: CircularProgressIndicator(),
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
              _imageUrl ?? '',
              width: widget.size,
              height: widget.size,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
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
              width: widget.size * 0.2,
              height: widget.size * 0.2,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2.0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
