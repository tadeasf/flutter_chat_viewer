import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../components/api_service.dart';
import 'message_profile_photo.dart';
import 'photo_view_screen.dart';

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
  _MessageItemState createState() => _MessageItemState();
}

class _MessageItemState extends State<MessageItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isInstagram = widget.message['is_geoblocked_for_viewer'] != null;

    Color getBubbleColor() {
      if (widget.isHighlighted) {
        return isDarkMode ? Colors.yellow[700]! : Colors.yellow[300]!;
      }
      if (isInstagram) {
        return widget.isAuthor
            ? (isDarkMode
                ? Colors.pink[900]!.withOpacity(0.25)
                : Colors.pink[500]!.withOpacity(0.5))
            : (isDarkMode
                ? Colors.pink[500]!.withOpacity(0.5)
                : Colors.pink[300]!.withOpacity(0.5));
      }
      // Facebook styling
      return widget.isAuthor
          ? (isDarkMode
              ? Colors.grey[800]!.withOpacity(0.5)
              : Colors.grey[300]!.withOpacity(0.5))
          : (isDarkMode
              ? Colors.grey[700]!.withOpacity(0.5)
              : Colors.grey[400]!.withOpacity(0.5));
    }

    Color getTextColor() {
      if (widget.isHighlighted) {
        return isDarkMode ? Colors.black : Colors.black;
      }
      return isDarkMode ? Colors.white70 : Colors.black87;
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
                ),
              ),
            const SizedBox(height: 8),
            GestureDetector(
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
          ],
        );
      } else {
        return Text(
          widget.message['content'] ?? 'No content',
          style: TextStyle(
            color: getTextColor(),
          ),
        );
      }
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
      },
      child: Align(
        alignment:
            widget.isAuthor ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: getBubbleColor(),
            borderRadius: BorderRadius.circular(12),
            border: widget.isHighlighted
                ? Border.all(
                    color: isDarkMode ? Colors.yellow : Colors.orange,
                    width: 2,
                  )
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (!widget.isAuthor)
                    MessageProfilePhoto(
                      collectionName: widget.selectedCollectionName,
                      size: 40.0,
                      isOnline: widget.message['is_online'] ?? false,
                      profilePhotoUrl: widget.profilePhotoUrl,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    widget.message['sender_name'] ?? 'Unknown sender',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: getTextColor(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
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
                    color: getTextColor(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
