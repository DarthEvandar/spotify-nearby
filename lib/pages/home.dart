import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'settings.dart';
import 'package:spotify_nearby/backend/spotifyService.dart' as spotifyService;
import 'package:spotify_nearby/pages/auth.dart';

class Home extends StatefulWidget {
  HomeState createState() => new HomeState();
}

class HomeState extends State<Home> {

  String _token;

  @override
  Widget build(BuildContext context) {

    // Launch auth page, currently broken don't uncomment
    //_loadAuth();

    return Scaffold(
        appBar: new AppBar(
          title: new Text("Spotify Nearby"),
          // Anything that should be on appbar should be added to actions List
          actions: <Widget>[
            new IconButton(
                icon: Icon(Icons.settings),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Settings())))
          ],
        ),
        body: new Material(
          child: Center(
              child: Column(
                // TODO add gesture controller to reload, if not constantly
                children: <Widget>[
                  /*new LinearProgressIndicator(
                    // TODO change value to 1 when done loading
                    value: null,
                  ),*/
                  Expanded(
                    child: new ListView.builder(
                      // Max 50 items for now, increase for each nearby
                        itemCount: 1,
                        shrinkWrap: true,
                        padding: const EdgeInsets.all(16.0),
                        itemBuilder: (BuildContext context, int index) {
                          Padding(padding: EdgeInsets.all(16.0));
                          return new InkWell(
                              onTap: () => setState(() {
                              }),
                              child: ListTile(
                                title: Text("PlaceHolder Title"),
                                subtitle: Text("PlaceHolder Subtitle"),
                                trailing: new Icon(Icons.music_note),
                                // TODO add an onTap event to listen to that music
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => Auth())),
                              )
                          );
                        }
                    ),
                  )
                ],
              )
            /*new RaisedButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MyHomePage())),
            child: new Text('API Stuff'),
        ),*/
          ),
        ),
      );
  }

  _loadAuth() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!(await spotifyService.tokenExists())) Navigator.pushNamed(context, '/auth');
  }
}