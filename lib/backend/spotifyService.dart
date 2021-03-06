import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart';

String clientID = 'a08c7a5c79304ac1bb28fed5b687f0c1';
String clientSecret = '2d710351a8ef47c18e29c875da325b7f';

Client client = Client();

Future<Response> initialAuth(String code, SharedPreferences prefs) {
  return client.post('https://accounts.spotify.com/api/token', headers:  clientHeaders(), body: preAuthBody(code)).then((Response response) {
    final Map<String, dynamic> map = json.decode(response.body);
    updateAuthToken(map['access_token'], prefs);
    updateRefreshToken(map['refresh_token'], prefs);
    updateExpireTime(map['expires_in'].toString(), prefs);
    updateCurrentUser(map['access_token'], prefs);
  });
}

Future<Response> refreshAuth(String refreshToken, SharedPreferences prefs) {
  return client.post('https://accounts.spotify.com/api/token', headers: clientHeaders(), body: refreshBody(refreshToken))
      .then((Response result) {
        final Map<String, dynamic> map = json.decode(result.body);
        updateAuthToken(map['access_token'], prefs);
        updateExpireTime(map['expires_in'].toString(), prefs);
        if (map.containsKey('refresh_token')) {
          updateRefreshToken(map['refresh_token'], prefs);
        }
    });
}

Future<Map<String, dynamic>> nowPlaying(String authToken) async {
  return client.get('https://api.spotify.com/v1/me/player/currently-playing', headers: authHeaders(authToken))
      .then<Map<String, dynamic>>((Response response) {
        if (response.body != '' && response.statusCode == 200) {
          return json.decode(response.body)['item'];
        } else {
          if (response.statusCode == 204) {
            throw 'No song playing';
          }
          throw 'Unexpected Error';
        }
      })
      .catchError((Object e) => <String, dynamic>{'name': 'No song playing'},
        test: (Object e) => e == 'No song playing')
      .catchError((Object e) => <String, dynamic>{'name': 'Unable to retrieve Song'},
        test: (Object e) => e == 'Unexpected Error');

}

Future<void> updateInfo(String authToken, SharedPreferences prefs) async {
  Map<String, dynamic> map = <String, dynamic>{'name': 'No song playing'};
  await client.get('https://api.spotify.com/v1/me/player/currently-playing', headers: authHeaders(authToken))
      .then<Map<String, dynamic>>((Response response) {
    //print(response.body);
    if (response.body != '' && response.statusCode == 200) {
      map = json.decode(response.body)['item'];
      final String nowPlaying = map['name'];
      prefs.setString('now_playing', nowPlaying);
      final String id = map['id'];
      prefs.setString('song_id', id);
    }
  });
}

Future<Map<String, dynamic>> getUserData(String authToken) async {
  Map<String, dynamic> map;
  return client.get('https://api.spotify.com/v1/me', headers: authHeaders(authToken))
      .then<Map<String, dynamic>>((Response response) {
        if (response.body != '' && response.statusCode == 200) {
          map = json.decode(response.body);
        } else {
          throw 'Invalid Response';
        }
        return map;
      })
      .catchError((Object error) => <String, dynamic>{'display_name': 'Unable to retrieve username'});
}

void updateAuthToken(String authToken, SharedPreferences prefs) =>
    prefs.setString('auth_token', authToken);

void updateExpireTime(String duration, SharedPreferences prefs) {
  prefs.setInt('expire_time', int.parse(duration));
  prefs.setInt('set_time', DateTime.now().millisecondsSinceEpoch);
}

void updateRefreshToken(String refreshToken, SharedPreferences prefs) =>
    prefs.setString('refresh_token', refreshToken);

void updateCurrentUser(String auth, SharedPreferences prefs) {
  client.get('https://api.spotify.com/v1/me', headers: authHeaders(auth))
      .then((Response response) {
        prefs.setString('current_user', json.decode(response.body)['id']);
      }
  );
}

bool tokenExists(SharedPreferences prefs) =>
    prefs.getKeys().contains('auth_token');

String getRefreshToken(SharedPreferences prefs) =>
    prefs.getString('refresh_token');

String getAuthToken(SharedPreferences prefs) =>
    prefs.getString('auth_token');

String getNowPlaying(SharedPreferences prefs) =>
    prefs.getString('now_playing');

String getSongId(SharedPreferences prefs) =>
    prefs.getString('song_id');

String getCurrentUser(SharedPreferences prefs) =>
    prefs.getString('current_user');

void clearTokens(SharedPreferences prefs) {
  prefs.remove('auth_token');
  prefs.remove('refresh_token');
  prefs.remove('set_time');
  prefs.remove('expire_time');
  prefs.remove('current_user');
}

bool authTokenExpired(SharedPreferences prefs) =>
  prefs.getInt('set_time') + (1000 * prefs.getInt('expire_time')) - DateTime.now().millisecondsSinceEpoch < 0;

Map<String, String> clientHeaders() {
  return <String, String> {
    'Authorization': 'Basic ${base64Encode(utf8.encode(clientID + ':' + clientSecret))}'
  };
}

Map<String, String> authHeaders(String authCode) {
  return <String, String> {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $authCode'
  };
}

Map<String, String> preAuthBody(String authCode) {
  return <String, String>{
    'grant_type': 'authorization_code',
    'code': authCode,
    'redirect_uri': 'http://localhost:4200/spotify'
  };
}

Map<String, String> refreshBody(String refreshToken) {
  return <String, String> {
    'grant_type': 'refresh_token',
    'refresh_token': refreshToken
  };
}
