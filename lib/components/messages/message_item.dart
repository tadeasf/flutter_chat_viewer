import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../api_db/api_service.dart';
import 'message_profile_photo.dart';
import '../gallery/photo_view_screen.dart';

class MessageItem extends StatefulWidget {
  final Map<String, dynamic> message;
  final bool isAuthor;
  final bool isHighlighted;
  final String selectedCollectionName;
  final String? profilePhotoUrl;

  const MessageItem({
    super.key,
    required this.message,
    required this.isAuthor,
    required this.isHighlighted,
    required this.selectedCollectionName,
    required this.profilePhotoUrl,
  });

  @override
  MessageItemState createState() => MessageItemState();
}

class MessageItemState extends State<MessageItem> {
  bool _isExpanded = false;

  // Darker and less vibrant Catppuccin Mocha inspired colors
  static const Color base = Color(0xFF0D0D0D);
  static const Color surface0 = Color(0xFF1A1A1A);
  static const Color surface1 = Color(0xFF262626);
  static const Color surface2 = Color(0xFF333333);
  static const Color blue = Color(0xFF4A90A4); // Adjusted blue
  static const Color lavender = Color(0xFF6A6A75);
  static const Color sapphire = Color(0xFF005B99);
  static const Color sky = Color(0xFF4A90A4);
  static const Color teal = Color(0xFF3A8C7E);
  static const Color green = Color(0xFF2A8C59);
  static const Color yellow = Color(0xFFCCAA00);
  static const Color peach = Color(0xFFCC7A00);
  static const Color maroon = Color(0xFFCC3A30);
  static const Color red = Color(0xFFCC2D55);
  static const Color mauve = Color(0xFF8A52CC);
  static const Color pink = Color(0xFFCC2D55);
  static const Color flamingo = Color(0xFFCC3A30);
  static const Color rosewater = Color(0xFFCC2D55);
  static const Color text = Color(0xFFE5E5EA);
  static const Color subtext1 = Color(0xFF8E8E93);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isInstagram = widget.message['is_geoblocked_for_viewer'] != null;

    Color getBubbleColor() {
      if (widget.isHighlighted) {
        return isDarkMode ? yellow : yellow.withOpacity(0.3);
      }
      if (isInstagram) {
        if (widget.isAuthor) {
          return isDarkMode
              ? Color(0xFF8A4F6D)
                  .withOpacity(0.3) // Lighter and less vibrant pinkish color
              : Color(0xFF8A4F6D)
                  .withOpacity(0.3); // Lighter and less vibrant pinkish color
        } else {
          return isDarkMode
              ? Color(0xFF8A4F6D)
                  .withOpacity(0.6) // Darker and less vibrant pinkish color
              : Color(0xFF8A4F6D)
                  .withOpacity(0.6); // Darker and less vibrant pinkish color
        }
      }
      // Facebook styling
      if (widget.isAuthor) {
        return isDarkMode ? surface1 : surface1.withOpacity(0.3);
      } else {
        return isDarkMode ? sapphire : sapphire.withOpacity(0.3);
      }
    }

    Color getTextColor() {
      if (widget.isHighlighted) {
        return isDarkMode ? base : Colors.black87;
      }
      return isDarkMode ? text : Colors.black87;
    }

    Widget buildMessageContent() {
      if (widget.message['photos'] != null &&
          (widget.message['photos'] as List).isNotEmpty) {
        final photoUrl =
            ApiService.getPhotoUrl(widget.message['photos'][0]['uri']);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.message['content'] != null)
              Text(
                widget.message['content'],
                style: TextStyle(
                  color: getTextColor(),
                  fontSize: 16,
                ),
              ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PhotoViewScreen(
                        imageUrl: photoUrl,
                      ),
                    ),
                  );
                },
                child: Image.network(
                  photoUrl,
                  height: 200,
                  width: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (BuildContext context, Widget child,
                      ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('Failed to load image');
                  },
                ),
              ),
            ),
          ],
        );
      } else {
        return Text(
          widget.message['content'] ?? 'No content',
          style: TextStyle(
            color: getTextColor(),
            fontSize: 16,
          ),
        );
      }
    }

    return Align(
      alignment: widget.isAuthor ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 4,
          bottom: 4,
          left: widget.isAuthor ? 64 : 8,
          right: widget.isAuthor ? 8 : 64,
        ),
        child: Column(
          crossAxisAlignment: widget.isAuthor
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!widget.isAuthor)
              Padding(
                padding: const EdgeInsets.only(left: 8, bottom: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MessageProfilePhoto(
                      collectionName: widget.selectedCollectionName,
                      size: 24.0,
                      isOnline: widget.message['is_online'] ?? false,
                      profilePhotoUrl: widget.profilePhotoUrl,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.message['sender_name'] ?? 'Unknown sender',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isDarkMode ? subtext1 : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: getBubbleColor(),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildMessageContent(),
                    if (_isExpanded) ...[
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('yyyy-MM-dd HH:mm').format(
                          DateTime.fromMillisecondsSinceEpoch(
                              widget.message['timestamp_ms']),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          color: getTextColor().withOpacity(0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
