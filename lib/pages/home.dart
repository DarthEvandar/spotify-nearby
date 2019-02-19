import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../backend/spotifyService.dart' as spotifyService;
import 'package:spotify_nearby/backend/nearbyService.dart' as nearbyService;
import '../backend/storageService.dart';
import 'settings.dart';

class Home extends StatefulWidget {
  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  String currentUser;
  String currentlyPlaying;

  @override
  void initState() {
    _loadNowPlaying();
    _loadCurrentUser();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {

    _loadNowPlaying();
    _loadCurrentUser();
    _updateTiles();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spotify Nearby'),
        // Anything that should be on appbar should be added to actions List
        actions: <Widget>[
          IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () => Navigator.push<Object>(
                  context,
                  MaterialPageRoute<dynamic>(builder: (BuildContext context) => Settings()))
          )
        ],
      ),
      body: Material(
        child: Center(
          child: GestureDetector(
            onHorizontalDragDown: (dynamic e) => (dynamic e) => const SnackBar(
              content: Text('update'),
            ),
          child: Column(
            // TODO add gesture controller to refresh
            children: <Widget>[
              const LinearProgressIndicator(
                // TODO change value to 1 when done loading
                value: null,
              ),
              InkWell(
                onTap: () =>  _launchSpotify(''),
              child: ListTile(
                title: Text(currentlyPlaying == null ? 'Nothing is playing': currentlyPlaying, textAlign: TextAlign.center),
                subtitle: Text(currentUser == null ? 'Not logged in' : currentUser, textAlign: TextAlign.center),
                ),
              ),
              Expanded(
              child: ListView.builder(
                // Max 50 items for now, increase for each nearby
                  itemCount: nearbyService.receivedUsers.length,
                  shrinkWrap: true,
                  padding: const EdgeInsets.all(16.0),
                  itemBuilder: (BuildContext context, int index) {
                    const Padding(padding: EdgeInsets.all(16.0));
                    return InkWell(
                      onTap: () => setState(() {}),
                      child: ListTile(
                        title: Text(nearbyService.receivedUsers[index][1]),
                        subtitle: Text(nearbyService.receivedUsers[index][0]),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            InkWell(
                              child: IconButton(
                                  icon: const Icon(Icons.music_note),
                                  onPressed: () => _launchSpotify(nearbyService.receivedUsers[index][2]),
                              ),
                            ),
                            InkWell(
                              child: IconButton(
                                  icon: const Icon(Icons.account_circle),
                                  onPressed: () => _launchUser(nearbyService.receivedUsers[index][0])
                              )
                            )
                          ],
                        ),
                        ),
                    );
                  }
              ),
              )
          ]
          ),
          ),
        ),
      ),
    );
  }


  Future<void> _launchSpotify(String track) async {
    final String url = 'https://open.spotify.com/track/$track';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  Future<void> _launchUser(String user) async {
    final String url = 'https://open.spotify.com/user/$user';
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Could not launch $url';
    }
  }

  // ignore: unused_element
  Future<void> _loadAuth() async {
    if (!spotifyService.tokenExists(await getStorageInstance())) {
      Navigator.pushNamed(context, '/auth');
    }
  }

  Future<void> _loadCurrentUser() async {
    final SharedPreferences prefs = await getStorageInstance();
    setState(() => currentUser = spotifyService.getCurrentUser(prefs));
  }

  void _loadNowPlaying() async {
    final SharedPreferences prefs = await getStorageInstance();
    setState(() => currentlyPlaying = spotifyService.getNowPlaying(prefs));
  }

  void _updateTiles() {
    setState(() {
      //userAccount = nearbyService.receivedUserAccount;
     // songTitle = nearbyService.receivedSongTitle;
      //songUrl = nearbyService.receivedSongUrl;
    });
  }
}