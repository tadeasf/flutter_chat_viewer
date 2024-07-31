import 'package:flutter/material.dart';
import 'message_item.dart';
import 'custom_scroll_behavior.dart';

class MessageList extends StatelessWidget {
  final List<dynamic> messages;
  final List<int> searchResults;
  final int currentSearchIndex;
  final ScrollController scrollController;

  const MessageList({
    super.key,
    required this.messages,
    required this.searchResults,
    required this.currentSearchIndex,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return ScrollConfiguration(
      behavior: CustomScrollBehavior(),
      child: Scrollbar(
        controller: scrollController,
        thumbVisibility: true,
        thickness: 8.0,
        radius: const Radius.circular(4.0),
        child: ListView.builder(
          controller: scrollController,
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final message = messages[index];
            return MessageItem(
              message: message,
              isAuthor: message['sender_name'] == 'Tadeáš Fořt',
              isHighlighted:
                  searchResults.contains(index) && index == currentSearchIndex,
            );
          },
          cacheExtent: 100,
        ),
      ),
    );
  }
}
