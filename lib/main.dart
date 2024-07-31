import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'components/message_list.dart';
import 'components/api_service.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:flutter/material.dart';
import 'components/photo_gallery.dart';

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
    _loadThemeMode();
  }

  void _loadThemeMode() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode =
          ThemeMode.values[prefs.getInt('themeMode') ?? ThemeMode.system.index];
    });
  }

  void _setThemeMode(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt('themeMode', mode.index);
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

  Future<void> handleShowAllPhotos() async {
    if (selectedCollection == null) return;

    setState(() {
      isGalleryLoading = true;
    });

    try {
      final photoData = await ApiService.fetchPhotos(selectedCollection!);
      final photoUrls = photoData
          .expand((msg) => (msg['photos'] as List)
              .map((photo) => ApiService.getPhotoUrl(photo['uri'])))
          .toList();

      setState(() {
        galleryPhotos = photoUrls;
        isGalleryLoading = false;
      });

      // Navigate to the PhotoGallery
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoGallery(photos: galleryPhotos),
        ),
      );
    } catch (error) {
      print('Failed to fetch photo data: $error');
      setState(() {
        isGalleryLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isFromDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isFromDate
          ? (fromDate ?? DateTime.now())
          : (toDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2025),
    );
    if (picked != null) {
      setState(() {
        if (isFromDate) {
          fromDate = picked;
        } else {
          toDate = picked;
        }
      });
      if (selectedCollection != null) {
        fetchMessages();
      }
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

  Future<void> _uploadImage() async {
    if (_image == null || selectedCollection == null) return;

    try {
      await ApiService.uploadPhoto(selectedCollection!, _image!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo uploaded successfully')));
      checkPhotoAvailability();
    } catch (e) {
      print('Error uploading photo: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Error uploading photo')));
    }
  }

  Future<void> _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      }
    });
  }

  Future<void> checkPhotoAvailability() async {
    if (selectedCollection == null) return;

    try {
      final isAvailable =
          await ApiService.checkPhotoAvailability(selectedCollection!);
      setState(() {
        isPhotoAvailable = isAvailable;
      });
    } catch (e) {
      print('Error checking photo availability: $e');
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Theme Mode'),
              DropdownButton<ThemeMode>(
                value: widget.themeMode,
                onChanged: (ThemeMode? newValue) {
                  if (newValue != null) {
                    widget.setThemeMode(newValue);
                    Navigator.of(context).pop();
                  }
                },
                items: ThemeMode.values.map((ThemeMode mode) {
                  return DropdownMenuItem<ThemeMode>(
                    value: mode,
                    child: Text(mode.toString().split('.').last),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
                handleShowAllPhotos();
              },
            ),
            ListTile(
              title: Text(
                  'From Date: ${fromDate != null ? DateFormat('yyyy-MM-dd').format(fromDate!) : 'Not set'}'),
              onTap: () => _selectDate(context, true),
            ),
            ListTile(
              title: Text(
                  'To Date: ${toDate != null ? DateFormat('yyyy-MM-dd').format(toDate!) : 'Not set'}'),
              onTap: () => _selectDate(context, false),
            ),
            ListTile(
              title: const Text('Select Photo'),
              onTap: () {
                _getImage();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: const Text('Upload Photo'),
              onTap: () {
                _uploadImage();
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                _showSettingsDialog();
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
                    checkPhotoAvailability();
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
