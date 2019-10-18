import 'package:flutter/material.dart';
import 'package:notable/provider/theme.dart';
import 'package:notable/store/notes.dart';
import 'package:preferences/preferences.dart';
import 'package:preferences/radio_preference.dart';
import 'package:provider/provider.dart';

class SettingsPage extends StatefulWidget {
  final NotesStore store;
  SettingsPage(this.store);
  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  NotesStore get store => widget.store;
  @override
  void initState() {
    PrefService.setDefaultValues({
      'sync': '',
      'sync_webdav_host': '',
      'sync_webdav_path': '',
      'sync_webdav_username': '',
      'sync_webdav_password': '',
      'theme': 'light'
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(children: <Widget>[
        PreferenceTitle('Theme'),
        RadioPreference(
          'Light',
          'light',
          'theme',
          isDefault: true,
          onSelect: () {
            Provider.of<ThemeNotifier>(context).currentTheme = ThemeType.light;
          },
        ),
        RadioPreference(
          'Dark',
          'dark',
          'theme',
          onSelect: () {
            Provider.of<ThemeNotifier>(context).currentTheme = ThemeType.dark;
          },
        ),
        PreferenceTitle('Sync'),
        RadioPreference(
          'No Sync',
          '',
          'sync',
          isDefault: true,
          onSelect: () {
            setState(() {
              store.syncMethod = '';
            });
          },
        ),
        RadioPreference(
          'WebDav Sync',
          'webdav',
          'sync',
          onSelect: () {
            setState(() {
              store.syncMethod = 'webdav';
            });
          },
        ),
        if (store.syncMethod == 'webdav')
          Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Warning: Webdav Sync isn\'t stable! Please do NOT use it for important data or accounts!',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              TextFieldPreference(
                'Host',
                'sync_webdav_host',
                hintText: 'mynextcloud.tld',
              ),
              TextFieldPreference(
                'Path',
                'sync_webdav_path',
                hintText: 'remote.php/webdav/',
              ),
              TextFieldPreference('Username', 'sync_webdav_username'),
              TextFieldPreference(
                'Password',
                'sync_webdav_password',
                obscureText: true,
              ),
            ],
          ),
      ]),
    );
  }
}
