import 'dart:async';
import 'package:flutter/material.dart';

void searchMessages(
    String query,
    Timer? debounce,
    Function setState,
    List<dynamic> messages,
    Function performSearch,
    List<int> searchResults,
    int currentSearchIndex,
    bool isSearchActive) {
  if (debounce?.isActive ?? false) debounce!.cancel();
  debounce = Timer(const Duration(milliseconds: 500), () {
    if (query.isEmpty) {
      setState(() {
        searchResults.clear();
        currentSearchIndex = -1;
        isSearchActive = false;
      });
    } else {
      performSearch(query);
      isSearchActive = true;
    }
  });
}

Widget buildSearchBar(
  BuildContext context,
  TextEditingController searchController,
  Function(String) onChanged,
  VoidCallback onClear,
  bool isSearchActive,
  VoidCallback toggleProfilePhotoVisibility,
  bool isProfilePhotoVisible,
) {
  return Row(
    children: [
      Expanded(
        child: TextField(
          controller: searchController,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: 'Search messages...',
            prefixIcon: Icon(Icons.search),
            suffixIcon: isSearchActive
                ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: onClear,
                  )
                : null,
          ),
        ),
      ),
      IconButton(
        icon: Icon(
            isProfilePhotoVisible ? Icons.visibility_off : Icons.visibility),
        onPressed: toggleProfilePhotoVisibility,
        tooltip:
            isProfilePhotoVisible ? 'Hide Profile Photo' : 'Show Profile Photo',
      ),
    ],
  );
}
