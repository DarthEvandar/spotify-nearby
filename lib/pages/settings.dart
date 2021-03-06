import 'package:flutter/material.dart';

import '../backend/storageService.dart';
import '../backend/settingsService.dart' as settingsService;
import '../backend/spotifyService.dart' as spotifyService;
import '../backend/themeService.dart' as themeService;
import 'package:spotify_nearby/backend/nearbyApiTesting.dart';
import 'package:shared_preferences/shared_preferences.dart';


class Settings extends StatefulWidget {
  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {

  // Initialization and declaration on _isDark to prevent errors with async methods
  bool _isDark = false;
  bool _isSharing = true;
  // ignore: unused_field
  String _themeColorString = 'blue';
  String _currentUser = 'Loading...';

  // Loads the initial state when opened and calls _loadDarkTheme to see if
  // button should be pressed
  @override
  void initState() {
    _loadSharing();
    _loadDarkTheme();
    _loadThemeColor();
    _loadCurrentUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Material(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16.0),
          children: <Widget>[
            _themeColor(),
            _newSettingSwitch(
                title: 'Dark Theme',
                subtitle: 'Changes in app theme to dark',
                value: _isDark,
                onChange: _toggleDarkTheme,
                key: const Key('toggleDarkTheme')
            ),
            _newSettingSwitch(
              title: 'Currently Sharing',
              subtitle: 'Toggles nearby sharing',
              value: _isSharing, 
              onChange: _setSharing,
              key: const Key('currentlySharing')
            ),
            _accountSetting(),
            ListTile(
              title: const Text('Nearby API stuff'),
              subtitle: const Text('keep out'),
              onTap: () => Navigator.push<Object> (context, MaterialPageRoute<dynamic>(builder: (BuildContext context) => Nearby())
            ),
            )
          ],
        ),
      ),
    );
  }

  // Generic Widget for creating a simple switch setting, provide onChange with a function call
  // ignore: strong_mode_implicit_dynamic_parameter, always_specify_types
  Widget _newSettingSwitch({String title, String subtitle, bool value, onChange, Key key}) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
          value: value,
          onChanged: onChange,
      ),
      key: key,
    );
  }

  // Allows user to see connected account and logout
  Widget _accountSetting() {
    return ListTile(
      title: const Text('Logout'),
      subtitle: Text((_currentUser == null) ? 'Not signed in' : 'Signed in as: $_currentUser'),
      onTap: () async {
        final SharedPreferences prefs = await getStorageInstance();
        setState(() => spotifyService.clearTokens(prefs));
        Navigator.pushNamed(context, '/auth');
      },
    );
  }

  Widget _themeColor() {
    return ListTile(
      title: const Text('Primary Theme Color'),
      subtitle: const Text('Changes theme to selected color'),
      trailing:
        // TODO Make color current color
        PopupMenuButton<String>(
          icon: const Icon(Icons.color_lens, color: null),
          onSelected: (String result) {
            setState(() {
              _setThemeColor(result);
            });
          },
          itemBuilder: (BuildContext context) =>
            <String>['Blue', 'Green', 'Red', 'Yellow', 'Pink', 'Purple', 'Cyan']
              .map((String x) =>
                PopupMenuItem<String>(
                    value: x.toLowerCase(),
                    child: Text(x)
                )
              )
              .toList()
          ),
      );
  }

  // Loads the initial dark theme bool from SharedPreferences, if none are found
  // loads as false
  Future<void> _loadDarkTheme() async {
    final SharedPreferences prefs = await getStorageInstance();
    setState(() => _isDark = themeService.darkThemeEnabled(prefs));
  }

  // Saves the dark theme bool value to SharedPreferences
  Future<void> _toggleDarkTheme(bool value) async {
    final SharedPreferences prefs = await getStorageInstance();

    setState(() {
      themeService.toggleDarkTheme(value, prefs);
      _isDark = value;
    });
  }

  Future<void> _loadSharing() async {
    final SharedPreferences prefs = await getStorageInstance();
    spotifyService.nowPlaying(spotifyService.getAuthToken(prefs));
    setState(() => _isSharing = settingsService.isSharing(prefs));
  }

  Future<void> _setSharing(bool value) async {
    final SharedPreferences prefs = await getStorageInstance();
    settingsService.setSharing(value, prefs);
    setState(() => _isSharing = value);
  }

  Future<void> _loadThemeColor() async {
    final SharedPreferences prefs = await getStorageInstance();
    setState(() => _themeColorString = themeService.getColor(prefs));
  }

  Future<void> _setThemeColor(String value) async {
    final SharedPreferences prefs = await getStorageInstance();
    themeService.setColor(value, prefs);
    setState(() => _themeColorString = value);
  }

  Future<void> _loadCurrentUser() async {
    final SharedPreferences prefs = await getStorageInstance();
    setState(() => _currentUser = spotifyService.getCurrentUser(prefs));
  }
}