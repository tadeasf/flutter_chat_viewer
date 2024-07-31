import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'components/messages/message_selector.dart';
import 'components/ui/theme_manager.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    ThemeManager.loadThemeMode().then((mode) {
      setState(() {
        _themeMode = mode;
      });
    });
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    ThemeManager.saveThemeMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meta Chat Viewer',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: MessageSelector(setThemeMode: _setThemeMode, themeMode: _themeMode),
    );
  }
}

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
    this.showButtons = false,
  });

  @override
  State<ProfilePhoto> createState() => _ProfilePhotoState();
}

class _ProfilePhotoState extends State<ProfilePhoto> {
  String? _imageUrl;
  bool _isLoading = true;
  bool _isError = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      if (kDebugMode) {
        print('Collection Name: ${widget.collectionName}');
      }
    } // Debug print
    _loadCachedPhoto();
  }

  Future<void> _loadCachedPhoto() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedUrl = prefs.getString('profile_photo_${widget.collectionName}');
    if (kDebugMode) {
      print('Cached URL: $cachedUrl');
    }
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
      final requestUrl =
          'https://secondary.dev.tadeasfort.com/messages/${widget.collectionName}/photo';
      if (kDebugMode) {
        if (kDebugMode) {}
        print('Request URL: $requestUrl');
      }
      final response = await http.get(
        Uri.parse(requestUrl),
      );
      if (kDebugMode) {
        print('Response status: ${response.statusCode}');
      }
      if (kDebugMode) {
        print('Response body: ${response.body}');
      }
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
            child: const CircularProgressIndicator(),
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
        if (widget.showButtons)
          Positioned(
            bottom: 0,
            left: 0,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.message),
                  onPressed: () {
                    // Handle message button press
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.call),
                  onPressed: () {
                    // Handle call button press
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
