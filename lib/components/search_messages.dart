import 'dart:async';

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
