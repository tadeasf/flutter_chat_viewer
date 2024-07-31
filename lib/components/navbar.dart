import 'package:flutter/material.dart';

class Navbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback onSearchPressed;
  final VoidCallback onDatabasePressed;
  final VoidCallback onCollectionSelectorPressed;
  final bool isCollectionSelectorVisible;

  const Navbar({
    super.key,
    required this.title,
    required this.onSearchPressed,
    required this.onDatabasePressed,
    required this.onCollectionSelectorPressed,
    required this.isCollectionSelectorVisible,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          Scaffold.of(context).openDrawer();
        },
      ),
      title: Text(title, style: const TextStyle(fontSize: 18)),
      actions: [
        IconButton(
          icon: Icon(isCollectionSelectorVisible
              ? Icons.view_list
              : Icons.view_list_outlined),
          onPressed: onCollectionSelectorPressed,
        ),
        IconButton(
          icon: const Icon(Icons.search),
          onPressed: onSearchPressed,
        ),
        IconButton(
          icon: const Icon(Icons.storage),
          onPressed: onDatabasePressed,
        ),
      ],
      elevation: 4.0, // Add shadow for a modern look
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
