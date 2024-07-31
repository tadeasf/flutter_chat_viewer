import 'package:flutter/material.dart';
import 'components/theme_manager.dart';
import 'components/message_selector.dart'; // Import MessageSelector

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  @override
  void initState() {
    super.initState();
    ThemeManager.loadThemeMode().then((mode) {
      setState(() {
        _themeMode = mode;
      });
    });
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
    ThemeManager.saveThemeMode(mode);
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
