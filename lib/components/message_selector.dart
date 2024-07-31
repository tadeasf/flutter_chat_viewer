import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:async';
import 'dart:io';
import 'load_collections.dart';
import 'fetch_messages.dart';
import 'search_messages.dart';
import 'navigate_search.dart';
import 'photo_handler.dart';
import 'date_selector.dart';
import 'theme_manager.dart';
import 'message_list.dart';
import 'scroll_to_highlighted_message.dart';
import 'profile_photo.dart'; // Import ProfilePhoto

class MessageSelector extends StatefulWidget {
  final Function(ThemeMode) setThemeMode;
  final ThemeMode themeMode;

  const MessageSelector(
      {super.key, required this.setThemeMode, required this.themeMode});

  @override
  _MessageSelectorState createState() => _MessageSelectorState();
}

class _MessageSelectorState extends State<MessageSelector> {
  List<String> collections = [];
  String? selectedCollection;
  DateTime? fromDate;
  DateTime? toDate;
  List<dynamic> messages = [];
  bool isLoading = false;
  TextEditingController searchController = TextEditingController();
  File? _image;
  final picker = ImagePicker();
  bool isPhotoAvailable = false;
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  List<dynamic> galleryPhotos = [];
  bool isGalleryLoading = false;
  List<int> searchResults = [];
  int currentSearchIndex = -1;
  bool isSearchVisible = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;
  bool isSearchActive = false; // Added this flag

  @override
  void initState() {
    super.initState();
    loadCollections((loadedCollections) {
      setState(() {
        collections = loadedCollections;
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void setLoading(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  void setMessages(List<dynamic> loadedMessages) {
    setState(() {
      messages = loadedMessages;
    });
  }

  void updateCurrentSearchIndex(int index) {
    setState(() {
      currentSearchIndex = index;
    });
  }

  void _performSearch(String query) {
    setState(() {
      searchResults = messages
          .asMap()
          .entries
          .where((entry) {
            final message = entry.value;
            final content = message['content']?.toLowerCase() ?? '';
            final senderName = message['sender_name']?.toLowerCase() ?? '';
            return content.contains(query.toLowerCase()) ||
                senderName.contains(query.toLowerCase());
          })
          .map((e) => e.key)
          .toList();
      currentSearchIndex = searchResults.isNotEmpty ? 0 : -1;
    });

    if (searchResults.isNotEmpty) {
      _scrollToHighlightedMessage();
    }
  }

  void _scrollToHighlightedMessage() {
    scrollToHighlightedMessage(
      currentSearchIndex,
      searchResults,
      itemScrollController,
    );
  }

  void _navigateSearch(int direction) {
    navigateSearch(
      direction,
      searchResults,
      currentSearchIndex,
      (index) {
        setState(() {
          currentSearchIndex = index;
        });
      },
      _scrollToHighlightedMessage,
    );
  }

  Future<void> _changeCollection(String? newValue) async {
    setState(() {
      selectedCollection = newValue;
    });
    if (selectedCollection != null) {
      await PhotoHandler.checkPhotoAvailability(selectedCollection, setState);
      await fetchMessages(selectedCollection, fromDate, toDate, setState,
          setLoading, setMessages);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat Viewer'),
        actions: [
          IconButton(
            icon: Icon(isSearchVisible ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearchVisible = !isSearchVisible;
                if (!isSearchVisible) {
                  searchController.clear();
                  searchResults.clear();
                  currentSearchIndex = -1;
                  isSearchActive = false; // Set to false when search is closed
                }
              });
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Text(
                'Chat Options',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Display All Images'),
              onTap: () {
                Navigator.pop(context);
                PhotoHandler.handleShowAllPhotos(
                  context,
                  selectedCollection,
                  setState,
                  galleryPhotos,
                  isGalleryLoading,
                );
              },
            ),
            ListTile(
              title: Text(
                  'From Date: ${fromDate != null ? DateFormat('yyyy-MM-dd').format(fromDate!) : 'Not set'}'),
              onTap: () => DateSelector.selectDate(context, true, fromDate,
                  toDate, setState, selectedCollection, fetchMessages),
            ),
            ListTile(
              title: Text(
                  'To Date: ${toDate != null ? DateFormat('yyyy-MM-dd').format(toDate!) : 'Not set'}'),
              onTap: () => DateSelector.selectDate(context, false, fromDate,
                  toDate, setState, selectedCollection, fetchMessages),
            ),
            ListTile(
              title: const Text('Select Photo'),
              onTap: () {
                PhotoHandler.getImage(picker, setState);
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Upload Photo'),
              onTap: () {
                PhotoHandler.uploadImage(
                    context, _image, selectedCollection, setState);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                ThemeManager.showSettingsDialog(
                    context, widget.themeMode, widget.setThemeMode);
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Select Collection:',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: selectedCollection,
                  isExpanded: true,
                  hint: const Text('Select a collection'),
                  onChanged: _changeCollection,
                  items:
                      collections.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                if (isSearchVisible) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: const InputDecoration(
                            labelText: 'Search messages',
                            suffixIcon: Icon(Icons.search),
                          ),
                          onChanged: (query) => searchMessages(
                              query,
                              _debounce,
                              setState,
                              messages,
                              _performSearch,
                              searchResults,
                              currentSearchIndex,
                              isSearchActive), // Pass the flag here
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_upward),
                        onPressed: () => _navigateSearch(-1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward),
                        onPressed: () => _navigateSearch(1),
                      ),
                    ],
                  ),
                  Text(
                      '${searchResults.isNotEmpty ? currentSearchIndex + 1 : 0}/${searchResults.length} results'),
                ],
                const SizedBox(height: 20),
                if (isPhotoAvailable && selectedCollection != null)
                  Image.network(
                    'https://secondary.dev.tadeasfort.com/serve/photo/${Uri.encodeComponent(selectedCollection!)}',
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text('Failed to load image');
                    },
                  ),
              ],
            ),
          ),
          if (selectedCollection != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ProfilePhoto(
                  collectionName: selectedCollection!,
                  size: 60.0,
                  isOnline: true,
                ),
                IconButton(
                  icon:
                      Icon(isPhotoAvailable ? Icons.delete : Icons.add_a_photo),
                  onPressed: () {
                    if (isPhotoAvailable) {
                      PhotoHandler.deletePhoto(selectedCollection!, setState);
                    } else {
                      PhotoHandler.getImage(picker, setState);
                    }
                  },
                ),
              ],
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : MessageList(
                    messages: messages,
                    searchResults: searchResults,
                    currentSearchIndex: currentSearchIndex,
                    itemScrollController: itemScrollController,
                    itemPositionsListener: itemPositionsListener,
                    isSearchActive: isSearchVisible,
                    selectedCollectionName:
                        selectedCollection ?? '', // Add this line
                  ),
          ),
        ],
      ),
    );
  }
}
