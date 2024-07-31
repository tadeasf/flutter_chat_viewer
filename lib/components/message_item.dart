import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MessageItem extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isAuthor;
  final bool isHighlighted;

  const MessageItem({
    required this.message,
    required this.isAuthor,
    required this.isHighlighted,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isAuthor ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isHighlighted
              ? (isDarkMode ? Colors.teal[700] : Colors.teal[100])
              : (isAuthor
                  ? (isDarkMode ? Colors.blue[700] : Colors.blue[100])
                  : (isDarkMode ? Colors.grey[800] : Colors.grey[300])),
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
            SizedBox(height: 4),
            Text(
              message['content'] ?? 'No content',
              style: TextStyle(
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
            SizedBox(height: 4),
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
