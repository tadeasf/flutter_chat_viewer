import 'package:flutter/material.dart';
import 'dart:convert';
import '../api_db/api_service.dart';

class CrossCollectionSearchDialog extends StatefulWidget {
  final Function(List<dynamic>) onSearchResults;

  const CrossCollectionSearchDialog({
    super.key,
    required this.onSearchResults,
  });

  @override
  CrossCollectionSearchDialogState createState() =>
      CrossCollectionSearchDialogState();
}

class CrossCollectionSearchDialogState
    extends State<CrossCollectionSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  Future<void> _performSearch() async {
    if (!mounted) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final encodedQuery = Uri.encodeComponent(_searchController.text);
      final response =
          await ApiService.post('/search', body: {'query': encodedQuery});

      if (!mounted) return;

      if (response.statusCode == 200) {
        final List<dynamic> searchResults =
            json.decode(utf8.decode(response.bodyBytes));
        widget.onSearchResults(searchResults);
        Navigator.of(context).pop();
      } else {
        throw Exception('Failed to perform cross-collection search');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cross-Collection Search'),
      content: TextField(
        controller: _searchController,
        decoration: const InputDecoration(hintText: 'Enter search query'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSearching ? null : _performSearch,
          child: _isSearching
              ? const CircularProgressIndicator()
              : const Text('Search'),
        ),
      ],
    );
  }
}
