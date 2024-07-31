void navigateSearch(
    int direction,
    List<int> searchResults,
    int currentSearchIndex,
    Function setState,
    Function scrollToHighlightedMessage) {
  if (searchResults.isEmpty) return;

  setState(() {
    currentSearchIndex =
        (currentSearchIndex + direction) % searchResults.length;
    if (currentSearchIndex < 0) currentSearchIndex = searchResults.length - 1;
  });

  scrollToHighlightedMessage();
}
