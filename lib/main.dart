import 'package:flutter/material.dart';
import 'components/message_list.dart';
import 'components/api_service.dart';
import 'components/theme_manager.dart';
import 'components/date_selector.dart';
import 'components/photo_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:async';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
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
      title: 'Chat Viewer',
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _themeMode,
      home: MessageSelector(setThemeMode: _setThemeMode, themeMode: _themeMode),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCollections() async {
    try {
      final loadedCollections = await ApiService.fetchCollections();
      setState(() {
        collections = loadedCollections;
      });
    } catch (e) {
      print('Error fetching collections: $e');
    }
  }

  Future<void> fetchMessages() async {
    if (selectedCollection == null) return;
    setState(() {
      isLoading = true;
    });
    try {
      final loadedMessages = await ApiService.fetchMessages(
        selectedCollection!,
        fromDate: fromDate != null
            ? DateFormat('yyyy-MM-dd').format(fromDate!)
            : null,
        toDate:
            toDate != null ? DateFormat('yyyy-MM-dd').format(toDate!) : null,
      );
      setState(() {
        messages = loadedMessages;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching messages: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void searchMessages(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isEmpty) {
        setState(() {
          searchResults.clear();
          currentSearchIndex = -1;
        });
      } else {
        _performSearch(query);
      }
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
    if (currentSearchIndex >= 0 && currentSearchIndex < searchResults.length) {
      final int messageIndex = searchResults[currentSearchIndex];
      itemScrollController.scrollTo(
        index: messageIndex,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        alignment: 0.0, // This will align the item to the top of the viewport
      );
    }
  }

  void navigateSearch(int direction) {
    if (searchResults.isEmpty) return;

    setState(() {
      currentSearchIndex =
          (currentSearchIndex + direction) % searchResults.length;
      if (currentSearchIndex < 0) currentSearchIndex = searchResults.length - 1;
    });

    _scrollToHighlightedMessage();
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
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedCollection = newValue;
                    });
                    PhotoHandler.checkPhotoAvailability(
                        selectedCollection, setState);
                    fetchMessages();
                  },
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
                          onChanged: searchMessages,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_upward),
                        onPressed: () => navigateSearch(-1),
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_downward),
                        onPressed: () => navigateSearch(1),
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
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : MessageList(
                    messages: messages,
                    searchResults: searchResults,
                    currentSearchIndex: currentSearchIndex,
                    itemScrollController: itemScrollController,
                    itemPositionsListener: itemPositionsListener,
                  ),
          ),
        ],
      ),
    );
  }
}
