import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:async';
import '../api_db/load_collections.dart';
import 'fetch_messages.dart';
import '../search/search_messages.dart';
import '../gallery/photo_handler.dart';
import 'message_list.dart';
import '../profile_photo/profile_photo_manager.dart';
import '../api_db/database_manager.dart';
import '../search/navigate_search.dart';
import '../app_drawer.dart';
import 'collection_selector.dart';
import '../navbar.dart';

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
  bool isSearchActive = false;
  String? profilePhotoUrl;
  final bool _isProfilePhotoVisible = true;
  int get maxMessageCount => filteredCollections.isNotEmpty
      ? filteredCollections
          .map((c) => c['messageCount'] as int)
          .reduce((a, b) => a > b ? a : b)
      : 1;
  bool isCollectionSelectorVisible = false;

  @override
  void initState() {
    super.initState();
    loadCollections((loadedCollections) {
      setState(() {
        collections = loadedCollections;
        filteredCollections = loadedCollections;
        isCollectionSelectorVisible = selectedCollection == null;
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
      isCollectionSelectorVisible = false;
    });
    if (selectedCollection != null) {
      await PhotoHandler.checkPhotoAvailability(selectedCollection, setState);
      await fetchMessages(selectedCollection, fromDate, toDate, setState,
          setLoading, setMessages);
      profilePhotoUrl =
          await ProfilePhotoManager.getProfilePhotoUrl(selectedCollection!);
    } else {
      setState(() {
        isCollectionSelectorVisible = true;
      });
    }
  }

  void refreshCollections() {
    loadCollections((loadedCollections) {
      setState(() {
        collections = loadedCollections;
        filteredCollections = loadedCollections;
      });
    });
  }

  void toggleCollectionSelector() {
    setState(() {
      isCollectionSelectorVisible = !isCollectionSelectorVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(
        selectedCollection: selectedCollection,
        isPhotoAvailable: isPhotoAvailable,
        isProfilePhotoVisible: _isProfilePhotoVisible,
        fromDate: fromDate,
        toDate: toDate,
        profilePhotoUrl: profilePhotoUrl,
        refreshCollections: refreshCollections,
        setState: setState,
        fetchMessages: fetchMessages,
        setThemeMode: widget.setThemeMode,
        themeMode: widget.themeMode,
        picker: picker,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Chat Viewer',
              style: Theme.of(context).textTheme.titleMedium,
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
                    isSearchActive: isSearchVisible,
                    selectedCollectionName: selectedCollection ?? '',
                    profilePhotoUrl: profilePhotoUrl,
                  ),
          ),
          if (isCollectionSelectorVisible || selectedCollection == null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CollectionSelector(
                selectedCollection: selectedCollection,
                initialCollections: filteredCollections,
                onCollectionChanged: _changeCollection,
                maxMessageCount: maxMessageCount,
              ),
            ),
          if (isSearchVisible) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
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
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                  '${searchResults.isNotEmpty ? currentSearchIndex + 1 : 0}/${searchResults.length} results'),
            ),
          ],
          if (isPhotoAvailable && selectedCollection != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Image.network(
                'https://secondary.dev.tadeasfort.com/serve/photo/${Uri.encodeComponent(selectedCollection!)}',
                height: 100,
                errorBuilder: (context, error, stackTrace) {
                  return const Text('Failed to load image');
                },
              ),
            ),
        ],
      ),
      bottomNavigationBar: Navbar(
        title: 'Chat Viewer',
        onSearchPressed: () {
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
        onDatabasePressed: () {
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
        onCollectionSelectorPressed: toggleCollectionSelector,
        isCollectionSelectorVisible: isCollectionSelectorVisible,
      ),
    );
  }
}
