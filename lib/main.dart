import 'dart:async';

import 'pages/home.dart';
import 'pages/auth.dart';

import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  Brightness brightness;
  //String _color = "Colors.blue";
  //MaterialColor _color2 = _color;
  bool _isDark = false;
  String _token;

  @override
  Widget build(BuildContext context) {

    //loads theme data, then coverts it to brightness variable
    _loadColor();
    _loadTheme();
    brightness = _isDark ? Brightness.dark : Brightness.light;



    // Main Material app return calling home class
    // Main theme for the entire application, Do not override primary color
    // of children otherwise primary app color picker won't function on it
    return new MaterialApp(
      title: 'Spotify Nearby',
      theme: new ThemeData(
        primarySwatch: Colors.blue,
        brightness: brightness, //Controls dark theme
      ),
     initialRoute: '/',
      routes: {
        '/': (context) => Home(),
        '/auth': (context) => Auth(),
      }
    );
  }

  // Accesses theme data stored in shared preferences "darkMode"
  _loadTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDark = prefs.getBool("darkMode") ?? false;
    });
  }

  _loadColor() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      //_color = prefs.getString("themeColor") ?? "Colors.blue";
    });
  }

}

