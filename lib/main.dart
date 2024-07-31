import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'message_item.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
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

  MessageSelector({required this.setThemeMode, required this.themeMode});

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
  List<int> searchResults = [];
  int currentSearchIndex = -1;
  bool isSearchVisible = false;
  final ScrollController _scrollController = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    fetchCollections();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchCollections() async {
    try {
      final response = await http
          .get(Uri.parse('https://secondary.dev.tadeasfort.com/collections'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          collections = data.map((item) => item['name'].toString()).toList();
        });
      } else {
        print('Failed to load collections');
      }
    } catch (e) {
      print('Error fetching collections: $e');
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

  Future<void> fetchMessages() async {
    if (selectedCollection == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      String url =
          'https://secondary.dev.tadeasfort.com/messages/${Uri.encodeComponent(selectedCollection!)}';

      if (fromDate != null || toDate != null) {
        List<String> queryParams = [];
        if (fromDate != null) {
          queryParams
              .add('fromDate=${DateFormat('yyyy-MM-dd').format(fromDate!)}');
        }
        if (toDate != null) {
          queryParams.add('toDate=${DateFormat('yyyy-MM-dd').format(toDate!)}');
        }
        if (queryParams.isNotEmpty) {
          url += '?' + queryParams.join('&');
        }
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          messages = json.decode(response.body);
          isLoading = false;
        });
      } else {
        print('Failed to load messages');
        setState(() {
          isLoading = false;
        });
      }
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

  void _performSearch(String query) async {
    final results = await compute(_searchMessagesCompute, {
      'messages': messages,
      'query': query.toLowerCase(),
    });

    setState(() {
      searchResults = results;
      currentSearchIndex = results.isNotEmpty ? 0 : -1;
    });

    if (results.isNotEmpty) {
      _scrollToHighlightedMessage();
    }
  }

  static List<int> _searchMessagesCompute(Map<String, dynamic> params) {
    final messages = params['messages'] as List<dynamic>;
    final query = params['query'] as String;
    List<int> results = [];

    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final content = (message['content'] ?? '').toLowerCase();
      final senderName = (message['sender_name'] ?? '').toLowerCase();
      if (content.contains(query) || senderName.contains(query)) {
        results.add(i);
      }
    }

    return results;
  }

  void _scrollToHighlightedMessage() {
    if (currentSearchIndex >= 0 && currentSearchIndex < searchResults.length) {
      final int messageIndex = searchResults[currentSearchIndex];
      _scrollController.jumpTo(messageIndex *
          100.0); // Adjust the multiplier based on your average item height
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

    final url = Uri.parse(
        'https://secondary.dev.tadeasfort.com/upload/photo/${Uri.encodeComponent(selectedCollection!)}');
    var request = http.MultipartRequest('POST', url);

    request.files.add(await http.MultipartFile.fromPath(
      'photo',
      _image!.path,
      contentType: MediaType('image', 'jpeg'),
    ));

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Photo uploaded successfully')));
        checkPhotoAvailability();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to upload photo')));
      }
    } catch (e) {
      print('Error uploading photo: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error uploading photo')));
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

    final url = Uri.parse(
        'https://secondary.dev.tadeasfort.com/messages/${Uri.encodeComponent(selectedCollection!)}/photo');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          isPhotoAvailable = data['isPhotoAvailable'];
        });
      }
    } catch (e) {
      print('Error checking photo availability: $e');
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Settings'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Theme Mode'),
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
              child: Text('Close'),
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
        title: Text('Chat Viewer'),
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
              child: Text(
                'Chat Options',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
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
              title: Text('Select Photo'),
              onTap: () {
                _getImage();
                Navigator.pop(context);
              },
            ),
            ListTile(
              title: Text('Upload Photo'),
              onTap: () {
                _uploadImage();
                Navigator.pop(context);
              },
            ),
            Divider(),
            ListTile(
              title: Text('Settings'),
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
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Select Collection:',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: selectedCollection,
                  isExpanded: true,
                  hint: Text('Select a collection'),
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
                SizedBox(height: 20),
                if (isSearchVisible) ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            labelText: 'Search messages',
                            suffixIcon: Icon(Icons.search),
                          ),
                          onChanged: searchMessages,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_upward),
                        onPressed: () => navigateSearch(-1),
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_downward),
                        onPressed: () => navigateSearch(1),
                      ),
                    ],
                  ),
                  Text(
                      '${searchResults.isNotEmpty ? currentSearchIndex + 1 : 0}/${searchResults.length} results'),
                ],
                SizedBox(height: 20),
                if (isPhotoAvailable && selectedCollection != null)
                  Image.network(
                    'https://secondary.dev.tadeasfort.com/serve/photo/${Uri.encodeComponent(selectedCollection!)}',
                    height: 100,
                    errorBuilder: (context, error, stackTrace) {
                      return Text('Failed to load image');
                    },
                  ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : ScrollConfiguration(
                    behavior: CustomScrollBehavior(),
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      thickness: 8.0,
                      radius: Radius.circular(4.0),
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return MessageItem(
                            message: message,
                            isAuthor: message['sender_name'] == 'Tadeáš Fořt',
                            isHighlighted: searchResults.contains(index) &&
                                index == searchResults[currentSearchIndex],
                          );
                        },
                        cacheExtent:
                            100, // Adjust this value based on your needs
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class CustomScrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
      BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics();
  }
}
