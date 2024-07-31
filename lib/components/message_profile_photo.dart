import 'package:flutter/material.dart';
import 'profile_photo.dart';

class MessageProfilePhoto extends StatelessWidget {
  final String collectionName;
  final double size;
  final bool isOnline;

  const MessageProfilePhoto({
    super.key,
    required this.collectionName,
    this.size = 40.0,
    this.isOnline = false,
  });

  @override
  Widget build(BuildContext context) {
    return ProfilePhoto(
      collectionName: collectionName,
      size: size,
      isOnline: isOnline,
      showButtons: false,
    );
  }
}
