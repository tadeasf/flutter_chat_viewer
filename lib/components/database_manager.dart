import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'load_collections.dart';

class DatabaseManager extends StatefulWidget {
  final VoidCallback refreshCollections;

  const DatabaseManager({super.key, required this.refreshCollections});

  @override
  _DatabaseManagerState createState() => _DatabaseManagerState();
}

class _DatabaseManagerState extends State<DatabaseManager> {
  String currentDb = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCurrentDb();
  }

  Future<void> fetchCurrentDb() async {
    try {
      final response = await http
          .get(Uri.parse('https://secondary.dev.tadeasfort.com/current_db'));
      if (response.statusCode == 200) {
        setState(() {
          currentDb = response.body;
        });
      } else {
        throw Exception('Failed to load current database');
      }
    } catch (e) {
      print('Error fetching current database: $e');
    }
  }

  Future<void> switchDbAndFetch() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http
          .get(Uri.parse('https://secondary.dev.tadeasfort.com/switch_db'));
      if (response.statusCode == 200) {
        await Future.delayed(Duration(seconds: 30)); // Wait for 30 seconds
        await fetchCurrentDb();
        await loadCollections((collections) {
          // Update collections in the parent widget
          widget.refreshCollections();
        });
      } else {
        throw Exception('Failed to switch database');
      }
    } catch (e) {
      print('Error switching database: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Current DB: $currentDb'),
        SizedBox(width: 8),
        ElevatedButton(
          onPressed: isLoading ? null : switchDbAndFetch,
          child: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text('Switch DB'),
        ),
      ],
    );
  }
}
