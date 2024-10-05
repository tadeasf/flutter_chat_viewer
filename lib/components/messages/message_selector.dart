import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'fetch_messages.dart';
import '../search/search_messages.dart';
import '../gallery/photo_handler.dart';
import 'message_list.dart';
import '../api_db/api_service.dart';
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
  int get maxCollectionIndex => filteredCollections.isNotEmpty
      ? filteredCollections
          .map((c) => c['index'] as int? ?? 0)
          .reduce((a, b) => a > b ? a : b)
      : 0;
  bool isCollectionSelectorVisible = false;
  List<dynamic> crossCollectionMessages = [];
  bool isCrossCollectionSearch = false;

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
      messages = loadedMessages
          .expand((message) => message is List ? message : [message])
          .toList();
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

  void _handleCrossCollectionSearch(List<dynamic> searchResults) {
    setState(() {
      crossCollectionMessages = searchResults.map((result) {
        return {
          ...result,
          'content': _decodeIfNeeded(result['content']),
          'sender_name': _decodeIfNeeded(result['sender_name']),
          'collectionName': _decodeIfNeeded(result['collectionName']),
        };
      }).toList();
      isCrossCollectionSearch = true;
    });
  }

  String _decodeIfNeeded(String? text) {
    if (text == null) return '';
    try {
      return utf8.decode(text.runes.toList());
    } catch (e) {
      return text;
    }
  }

  Future<void> _navigateToMessage(String collectionName, int timestamp) async {
    setState(() {
      isLoading = true;
    });

    if (collectionName != selectedCollection) {
      await _changeCollection(collectionName);
    }

    setState(() {
      isCrossCollectionSearch = false;
      crossCollectionMessages = [];
    });

    await Future.delayed(const Duration(milliseconds: 500));

    final messageIndex =
        messages.indexWhere((message) => message['timestamp_ms'] == timestamp);

    if (messageIndex != -1) {
      itemScrollController.scrollTo(
        index: messageIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        alignment: 0.3,
      );
    }

    setState(() {
      isLoading = false;
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
        onCrossCollectionSearch: _handleCrossCollectionSearch,
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
                    messages: isCrossCollectionSearch
                        ? crossCollectionMessages
                        : messages,
                    searchResults: searchResults,
                    currentSearchIndex: currentSearchIndex,
                    itemScrollController: itemScrollController,
                    itemPositionsListener: itemPositionsListener,
                    isSearchActive: isSearchVisible,
                    selectedCollectionName: selectedCollection ?? '',
                    profilePhotoUrl: profilePhotoUrl,
                    isCrossCollectionSearch: isCrossCollectionSearch,
                    onMessageTap: _navigateToMessage,
                  ),
          ),
          if (isCollectionSelectorVisible || selectedCollection == null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CollectionSelector(
                selectedCollection: selectedCollection,
                initialCollections: filteredCollections,
                onCollectionChanged: _changeCollection,
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
                'https://backend.jevrej.cz/serve/photo/${Uri.encodeComponent(selectedCollection!)}',
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

  Future<void> loadCollections(
      Function(List<Map<String, dynamic>>) callback) async {
    try {
      final loadedCollections = await ApiService.fetchCollections();
      callback(loadedCollections);
    } catch (e) {
      if (kDebugMode) {
        print('Error loading collections: $e');
      }
    }
  }
}
