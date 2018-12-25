import 'dart:async';

import 'pages/home.dart';
import 'pages/auth.dart';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotify_nearby/backend/themeService.dart' as themeService;
/*
 * TODO: Local Storage for Auth keys
 * TODO: Build basic UI controls
 * TODO: Set up Nearby for Android
 * TODO: Set up Nearby for iOS
 * TODO: Basic Spotify Auth flow
 * TODO: Transmit Spotify data
 * TODO: Add UI for list of nearby users
 * TODO: Add UI page for account
 * TODO: Implement Nearby Sharing toggle in settings
 * TODO: Implement Logout in settings
 */


void main() => runApp(new MyApp());

class MyApp extends StatefulWidget {
  MyAppState createState() => new MyAppState();
}

// Needs to be stateful to correctly change theme
class MyAppState extends State<MyApp> {

  // Variables used to manage a dark theme
  String _color = "blue";
  MaterialColor _colorMat = Colors.blue;
  bool _isDark = false;
  String _token;

  @override
  Widget build(BuildContext context) {

    //loads theme data, then coverts it to brightness variable
    _loadColor();
    _loadDarkMode();

    Map<String, MaterialColor> colorMap = new Map();
    colorMap['blue'] = Colors.blue;
    colorMap['red'] = Colors.red;
    colorMap['green'] = Colors.green;
    colorMap['yellow'] = Colors.yellow;
    colorMap['pink'] = Colors.pink;
    colorMap['purple'] = Colors.purple;
    colorMap['cyan'] = Colors.cyan;

    _colorMat = colorMap[_color];

    // Main Material app return calling home class
    // Main theme for the entire application, Do not override primary color
    // of children otherwise primary app color picker won't function on it
    return new MaterialApp(
      title: 'Spotify Nearby',
      theme: new ThemeData(
        primarySwatch: _colorMat,
        brightness: _isDark ? Brightness.dark : Brightness.light, //Controls dark theme
      ),
     initialRoute: '/',
      routes: {
        '/': (context) => Home(),
        '/auth': (context) => Auth(),
      }
    );
  }

  // Accesses theme data stored in shared preferences "darkMode"
  _loadDarkMode() async {
    bool dark = await themeService.darkThemeEnabled();
    setState(() {
      _isDark = dark;
    });
  }

  _loadColor() async {
    String currentColor = await themeService.getColor();
    setState(() {
      _color = currentColor;
    });
  }

}

