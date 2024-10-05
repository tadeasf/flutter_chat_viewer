import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kDebugMode;
import 'load_collections.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DatabaseManager extends StatefulWidget {
  final VoidCallback refreshCollections;

  const DatabaseManager({super.key, required this.refreshCollections});

  @override
  DatabaseManagerState createState() => DatabaseManagerState();
}

class DatabaseManagerState extends State<DatabaseManager> {
  String currentDb = '';
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    fetchCurrentDb();
  }

  Future<void> fetchCurrentDb() async {
    try {
      final response = await http.get(
        Uri.parse('https://backend.jevrej.cz/current_db'),
        headers: {'X-API-KEY': dotenv.env['X_API_KEY'] ?? ''},
      );
      if (response.statusCode == 200) {
        setState(() {
          currentDb = response.body;
        });
      } else {
        throw Exception('Failed to load current database');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching current database: $e');
      }
    }
  }

  Future<void> switchDbAndFetch() async {
    setState(() {
      isLoading = true;
    });
    try {
      final response = await http.get(
        Uri.parse('https://backend.jevrej.cz/switch_db'),
        headers: {'X-API-KEY': dotenv.env['X_API_KEY'] ?? ''},
      );
      if (response.statusCode == 200) {
        await Future.delayed(
            const Duration(seconds: 30)); // Wait for 30 seconds
        await fetchCurrentDb();
        await loadCollections((collections) {
          // Update collections in the parent widget
          widget.refreshCollections();
        });
      } else {
        throw Exception('Failed to switch database');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error switching database: $e');
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height:
          MediaQuery.of(context).size.height * 0.1, // 30% of the screen height
      child: Column(
        children: [
          Text('Current DB: $currentDb'),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: isLoading ? null : switchDbAndFetch,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Switch DB'),
          ),
        ],
      ),
    );
  }
}
