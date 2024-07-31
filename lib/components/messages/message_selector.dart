import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:async';
import 'dart:io';
import '../api_db/load_collections.dart';
import 'fetch_messages.dart';
import '../search/search_messages.dart';
import '../gallery/photo_handler.dart';
import '../ui_utils/date_selector.dart';
import '../ui_utils/theme_manager.dart';
import 'message_list.dart';
import '../profile_photo/profile_photo.dart'; // Import ProfilePhoto
import '../profile_photo/profile_photo_manager.dart'; // Add this import
import '../api_db/database_manager.dart'; // Add this import
import '../search/navigate_search.dart'; // Add this import

class MessageSelector extends StatefulWidget {
  final Function(ThemeMode) setThemeMode;
  final ThemeMode themeMode;

  const MessageSelector(
      {super.key, required this.setThemeMode, required this.themeMode});

  @override
  MessageSelectorState createState() => MessageSelectorState();
}

class MessageSelectorState extends State<MessageSelector> {
  List<Map<String, dynamic>> collections = [];
  List<Map<String, dynamic>> filteredCollections = [];
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
  String? profilePhotoUrl; // Add this property
  bool _isProfilePhotoVisible = true; // Add this property
  int get maxMessageCount => filteredCollections.isNotEmpty
      ? filteredCollections
          .map((c) => c['messageCount'] as int)
          .reduce((a, b) => a > b ? a : b)
      : 1;
  bool isDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    loadCollections((loadedCollections) {
      setState(() {
        collections = loadedCollections;
        filteredCollections = loadedCollections;
      });
    });
  }

  void filterCollections(String query) {
    setState(() {
      filteredCollections = collections
          .where((collection) =>
              collection['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
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

  void _scrollToHighlightedMessage(int index) {
    itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
      alignment: 0.0,
    );
  }

  void _performSearch(String query) {
    searchMessages(
      query,
      _debounce,
      setState,
      messages,
      _scrollToHighlightedMessage,
      (List<int> results) {
        setState(() {
          searchResults = results;
        });
      },
      (int index) {
        setState(() {
          currentSearchIndex = index;
        });
      },
      (bool active) {
        setState(() {
          isSearchActive = active;
        });
      },
      selectedCollection,
    );
  }

  void _navigateSearch(int direction) {
    navigateSearch(
      direction,
      searchResults,
      currentSearchIndex,
      (int index) {
        setState(() {
          currentSearchIndex = index;
        });
      },
      () => _scrollToHighlightedMessage(searchResults[currentSearchIndex]),
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
      // Fetch and store the profile photo URL
      profilePhotoUrl =
          await ProfilePhotoManager.getProfilePhotoUrl(selectedCollection!);
    }
  }

  void _toggleProfilePhotoVisibility() {
    setState(() {
      _isProfilePhotoVisible = !_isProfilePhotoVisible;
    });
  }

  // Add this method to refresh collections
  void refreshCollections() {
    loadCollections((loadedCollections) {
      setState(() {
        collections = loadedCollections;
        filteredCollections = loadedCollections;
      });
    });
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
                  isSearchActive = false;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(_isProfilePhotoVisible
                ? Icons.visibility_off
                : Icons.visibility),
            onPressed: _toggleProfilePhotoVisibility,
            tooltip: _isProfilePhotoVisible
                ? 'Hide Profile Photo'
                : 'Show Profile Photo',
          ),
          IconButton(
            icon: const Icon(Icons.storage),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('Database Management'),
                    content:
                        DatabaseManager(refreshCollections: refreshCollections),
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
            },
            tooltip: 'Database Management',
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
                const SizedBox(height: 8),
                CustomDropdown(
                  value: selectedCollection,
                  hint: 'Select a collection',
                  onChanged: _changeCollection,
                  items: filteredCollections,
                  searchController: searchController,
                  onSearch: filterCollections,
                  maxMessageCount: maxMessageCount,
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
                          onChanged: _performSearch,
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
          if (_isProfilePhotoVisible && selectedCollection != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ProfilePhoto(
                  collectionName: selectedCollection!,
                  size: 60.0,
                  isOnline: true,
                  profilePhotoUrl: profilePhotoUrl,
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
                    profilePhotoUrl:
                        profilePhotoUrl, // Pass the profile photo URL
                  ),
          ),
        ],
      ),
    );
  }
}

class CustomDropdown extends StatefulWidget {
  final String? value;
  final String hint;
  final Function(String?) onChanged;
  final List<Map<String, dynamic>> items;
  final TextEditingController searchController;
  final Function(String) onSearch;
  final int maxMessageCount;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.hint,
    required this.onChanged,
    required this.items,
    required this.searchController,
    required this.onSearch,
    required this.maxMessageCount,
  });

  @override
  CustomDropdownState createState() => CustomDropdownState();
}

class CustomDropdownState extends State<CustomDropdown> {
  bool isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              isOpen = !isOpen;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.value ?? widget.hint),
                Icon(isOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
        if (isOpen)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: widget.searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search collections...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: widget.onSearch,
                  ),
                ),
                SizedBox(
                  height: 200,
                  child: ListView(
                    children: widget.items.map((item) {
                      final int messageCount = item['messageCount'] as int;
                      final double percentage =
                          messageCount / widget.maxMessageCount;
                      return ListTile(
                        title: Text('${item['name']} ($messageCount messages)'),
                        subtitle: LinearProgressIndicator(
                          value: percentage,
                          backgroundColor: Colors.grey[300],
                          valueColor:
                              const AlwaysStoppedAnimation<Color>(Colors.blue),
                        ),
                        onTap: () {
                          widget.onChanged(item['name']);
                          setState(() {
                            isOpen = false;
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
