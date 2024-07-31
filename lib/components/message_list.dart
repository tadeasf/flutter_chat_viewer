import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'message_item.dart';
import 'custom_scroll_behavior.dart';

class MessageList extends StatelessWidget {
  final List<dynamic> messages;
  final List<int> searchResults;
  final int currentSearchIndex;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final bool isSearchActive; // Add this flag

  const MessageList({
    super.key,
    required this.messages,
    required this.searchResults,
    required this.currentSearchIndex,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.isSearchActive, // Add this flag
  });

  @override
  Widget build(BuildContext context) {
    // Debug prints to check searchResults and currentSearchIndex
    if (isSearchActive) {
      print('Search Results: $searchResults');
      print('Current Search Index: $currentSearchIndex');
    }

    return ScrollConfiguration(
      behavior: CustomScrollBehavior(),
      child: ScrollablePositionedList.builder(
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final message = messages[index];
          final isHighlighted = isSearchActive &&
              searchResults.contains(index) &&
              searchResults.indexOf(index) == currentSearchIndex;
          // Debug print to check isHighlighted value
          if (isSearchActive) {
            print('Message at index $index is highlighted: $isHighlighted');
          }
          return MessageItem(
            message: message,
            isAuthor: message['sender_name'] == 'Tadeáš Fořt',
            isHighlighted: isHighlighted,
          );
        },
        itemScrollController: itemScrollController,
        itemPositionsListener: itemPositionsListener,
      ),
    );
  }
}
