import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import './gallery/photo_handler.dart';
import './ui_utils/date_selector.dart';
import './ui_utils/theme_manager.dart';
import './profile_photo/profile_photo.dart';

class AppDrawer extends StatelessWidget {
  final String? selectedCollection;
  final bool isPhotoAvailable;
  final bool isProfilePhotoVisible;
  final DateTime? fromDate;
  final DateTime? toDate;
  final String? profilePhotoUrl;
  final Function refreshCollections;
  final Function setState;
  final Function fetchMessages;
  final void Function(ThemeMode) setThemeMode;
  final ThemeMode themeMode;
  final ImagePicker picker;

  const AppDrawer({
    super.key,
    required this.selectedCollection,
    required this.isPhotoAvailable,
    required this.isProfilePhotoVisible,
    required this.fromDate,
    required this.toDate,
    required this.profilePhotoUrl,
    required this.refreshCollections,
    required this.setState,
    required this.fetchMessages,
    required this.setThemeMode,
    required this.themeMode,
    required this.picker,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    selectedCollection ?? 'No Collection Selected',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (isProfilePhotoVisible && selectedCollection != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: ProfilePhoto(
                      collectionName: selectedCollection!,
                      size: 80.0,
                      isOnline: true,
                      profilePhotoUrl: profilePhotoUrl,
                      showButtons: true,
                    ),
                  ),
                const SizedBox(height: 16),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Date Range',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      ListTile(
                        leading: const Icon(Icons.date_range),
                        title: Text(
                          'From: ${fromDate != null ? DateFormat('yyyy-MM-dd').format(fromDate!) : 'Not set'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        onTap: () => DateSelector.selectDate(
                            context,
                            true,
                            fromDate,
                            toDate,
                            setState,
                            selectedCollection,
                            fetchMessages),
                      ),
                      ListTile(
                        leading: const Icon(Icons.date_range),
                        title: Text(
                          'To: ${toDate != null ? DateFormat('yyyy-MM-dd').format(toDate!) : 'Not set'}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        onTap: () => DateSelector.selectDate(
                            context,
                            false,
                            fromDate,
                            toDate,
                            setState,
                            selectedCollection,
                            fetchMessages),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: Text('Gallery',
                      style: Theme.of(context).textTheme.bodyMedium),
                  onTap: () async {
                    Navigator.pop(context);
                    await PhotoHandler.handleShowAllPhotos(
                      context,
                      selectedCollection,
                      setState,
                      [],
                      false,
                    );
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: Text('Settings',
                      style: Theme.of(context).textTheme.bodyMedium),
                  onTap: () {
                    Navigator.pop(context);
                    ThemeManager.showSettingsDialog(
                        context, themeMode, setThemeMode);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
