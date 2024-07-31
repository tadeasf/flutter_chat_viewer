import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import '../components/api_service.dart';

class MessageItem extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isAuthor;
  final bool isHighlighted;

  const MessageItem({
    Key? key,
    required this.message,
    required this.isAuthor,
    required this.isHighlighted,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isInstagram = message['is_geoblocked_for_viewer'] != null;

    Color getBubbleColor() {
      if (isHighlighted) {
        return isDarkMode ? Colors.cyan[700]! : Colors.cyan[300]!;
      }
      if (isInstagram) {
        return isAuthor
            ? (isDarkMode
                ? Colors.pink[900]!.withOpacity(0.25)
                : Colors.pink[500]!.withOpacity(0.5))
            : (isDarkMode
                ? Colors.pink[500]!.withOpacity(0.5)
                : Colors.pink[300]!.withOpacity(0.5));
      }
      // Facebook styling
      return isAuthor
          ? (isDarkMode
              ? Colors.grey[800]!.withOpacity(0.5)
              : Colors.grey[300]!.withOpacity(0.5))
          : (isDarkMode
              ? Colors.grey[700]!.withOpacity(0.5)
              : Colors.grey[400]!.withOpacity(0.5));
    }

    Widget _buildMessageContent() {
      if (message['photos'] != null && (message['photos'] as List).isNotEmpty) {
        final photoUrl = ApiService.getPhotoUrl(message['photos'][0]['uri']);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message['content'] != null)
              Text(
                message['content'],
                style: TextStyle(
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PhotoViewScreen(imageUrl: photoUrl),
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
          message['content'] ?? 'No content',
          style: TextStyle(
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
        );
      }
    }

    return Align(
      alignment: isAuthor ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: getBubbleColor(),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['sender_name'] ?? 'Unknown sender',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            _buildMessageContent(),
            const SizedBox(height: 4),
            Text(
              DateFormat('yyyy-MM-dd HH:mm').format(
                DateTime.fromMillisecondsSinceEpoch(message['timestamp_ms']),
              ),
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PhotoViewScreen extends StatelessWidget {
  final String imageUrl;

  const PhotoViewScreen({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: PhotoView(
        imageProvider: NetworkImage(imageUrl),
        minScale: PhotoViewComputedScale.contained * 0.8,
        maxScale: PhotoViewComputedScale.covered * 2,
        backgroundDecoration: const BoxDecoration(
          color: Colors.black,
        ),
        loadingBuilder: (context, event) => Center(
          child: CircularProgressIndicator(
            value: event == null
                ? 0
                : event.cumulativeBytesLoaded / event.expectedTotalBytes!,
          ),
        ),
        errorBuilder: (context, error, stackTrace) {
          return const Center(
              child: Text('Failed to load image',
                  style: TextStyle(color: Colors.white)));
        },
      ),
    );
  }
}
