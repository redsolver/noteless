import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:app/provider/theme.dart';
import 'package:app/store/notes.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
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
      'theme': 'light',
      'search_content': true,
      'editor_mode_switcher': true,
      'editor_pair_brackets': false,
      'notes_list_virtual_tags': false,
      'debug_logs_sync': false,
      'editor_auto_save': false,
      'dendron_mode': false,
      'sort_tags_in_sidebar': true,
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
            Provider.of<ThemeNotifier>(context, listen: false)
                .updateTheme('light');
          },
        ),
        RadioPreference(
          'Dark',
          'dark',
          'theme',
          onSelect: () {
            Provider.of<ThemeNotifier>(context, listen: false)
                .updateTheme('dark');
          },
        ),
        RadioPreference(
          'Black / AMOLED',
          'black',
          'theme',
          onSelect: () {
            Provider.of<ThemeNotifier>(context, listen: false)
                .updateTheme('black');
          },
        ),
        ListTile(
          title: Text('Accent Color'),
          trailing: Padding(
            padding: const EdgeInsets.only(right: 9, left: 9),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(),
                color: Color(PrefService.getInt('theme_color') ?? 0xff21d885),
              ),
              child: SizedBox(
                width: 28,
                height: 28,
              ),
            ),
          ),
          onTap: () async {
            Color color = await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                      title: Text('Select accent color'),
                      content: Container(
                        child: GridView.count(
                          crossAxisCount: 5,
                          children: [
                            for (Color color in [
                              Color(0xff21d885),
                              ...Colors.primaries,
                              ...Colors.accents,
                            ])
                              InkWell(
                                child: Container(
                                  margin: const EdgeInsets.all(5),
                                  color: color,
                                ),
                                onTap: () {
                                  Navigator.of(context).pop(color);
                                },
                              )
                          ],
                        ),
                        width: MediaQuery.of(context).size.width * .7,
                      ),
                      actions: <Widget>[
                        FlatButton(
                          child: Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ));
            if (color != null) {
              PrefService.setInt('theme_color', color.value);

              Provider.of<ThemeNotifier>(context, listen: false).accentColor =
                  color;
            }
          },
        ),
        if (Platform.isAndroid) ...[
          PreferenceTitle('Data Directory'),
          SwitchPreference(
            'Use external storage',
            'notable_external_directory_enabled',
            onChange: () async {
              if (PrefService.getString('notable_external_directory') == null) {
                PrefService.setString('notable_external_directory',
                    (await getExternalStorageDirectory()).path);
              }

              await store.listNotes();
              await store.filterAndSortNotes();
              await store.updateTagList();

              if (mounted) setState(() {});
            },
          ),
          PreferenceHider([
            ListTile(
              title: Text('Location'),
              subtitle: Text(
                PrefService.getString('notable_external_directory') ?? '',
              ),
              onTap: () async {
                Directory dir;

                final dirStr = await _pickExternalDir();

                if (dirStr == null) {
                  return;
                }

                dir = Directory(dirStr);

                if (dir != null) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: ListTile(
                        leading: CircularProgressIndicator(),
                        title: Text('Processing files...'),
                      ),
                    ),
                    barrierDismissible: false,
                  );
                  PrefService.setString('notable_external_directory', dir.path);

                  await store.listNotes();
                  await store.filterAndSortNotes();
                  await store.updateTagList();
                  setState(() {});
                  Navigator.of(context).pop();
                }
              },
            ),
          ], '!notable_external_directory_enabled'),
        ],
        PreferenceTitle('Editor'),
        SwitchPreference(
          'Auto Save',
          'editor_auto_save',
        ),
        SwitchPreference(
          'Use Mode Switcher',
          'editor_mode_switcher',
        ),
        SwitchPreference(
          'Pair Brackets/Quotes',
          'editor_pair_brackets',
        ),
        PreferenceTitle('Search'),
        SwitchPreference(
          'Search content of notes',
          'search_content',
        ),
        PreferenceTitle('Tags'),
        SwitchPreference(
          'Sort tags alphabetically in the sidebar',
          'sort_tags_in_sidebar',
        ),
        PreferenceTitle('Preview'),
        SwitchPreference(
          'Enable single line break syntax',
          'single_line_break_syntax',
          desc:
              'When enabled, single line breaks are rendered as real line breaks',
        ),
        /*        PreferenceTitle('Sync'),
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
                  'WARNING: WebDav Sync is not supported! Please use another app to sync if possible (Syncthing is recommended) and do NOT use it for important data or accounts! ',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              TextFieldPreference(
                'Host',
                'sync_webdav_host',
                hintText: 'mynextcloud.tld/remote.php/webdav/',
              ),
              TextFieldPreference(
                'Path',
                'sync_webdav_path',
                hintText: 'notable',
              ),
              TextFieldPreference('Username', 'sync_webdav_username'),
              TextFieldPreference(
                'Password',
                'sync_webdav_password',
                obscureText: true,
              ),
            ],
          ),
        */
        PreferenceTitle('More'),
        ListTile(
          title: Text('Recreate tutorial notes'),
          onTap: () async {
            if (await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                          title: Text(
                              'Do you want to recreate the tutorial notes and attachments?'),
                          actions: <Widget>[
                            FlatButton(
                              child: Text('Cancel'),
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                            ),
                            FlatButton(
                              child: Text('Recreate'),
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                            )
                          ],
                        )) ??
                false) {
              await store.createTutorialNotes();
              await store.createTutorialAttachments();
              await store.listNotes();
              await store.filterAndSortNotes();
              await store.updateTagList();
            }
          },
        ),
        /*        PreferenceTitle('Debug'),
        SwitchPreference(
          'Create sync logfile ',
          'debug_logs_sync',
        ), */
        PreferenceTitle('Experimental'),
        SwitchPreference(
          'Enable Dendron support',
          'dendron_mode',
          desc: 'Dendron is a VSCode-based note-taking tool',
          onChange: () async {
            await store.listNotes();
            await store.filterAndSortNotes();
            await store.updateTagList();

            if (mounted) setState(() {});
          },
        ),
        SwitchPreference(
          'Automatic bullet points',
          'auto_bullet_points',
          desc:
              'Adds a bullet point to a new line if the line before it had one',
        ),
        SwitchPreference(
          'Show virtual tags',
          'notes_list_virtual_tags',
          desc:
              'Adds a virtual tag (#/path) to notes which are in a subdirectory',
        ),
      ]),
    );
  }

  Future<String> _pickExternalDir() async {
    if (!await Permission.storage.request().isGranted) {
      return null;
    }

    var dir = await FilePicker.platform.getDirectoryPath();
    if ((dir ?? '').isNotEmpty) {
      if (await _checkIfDirectoryIsWritable(dir)) {
        return dir;
      }
    }

    if ((await Permission.storage.request()).isDenied) {
      return null;
    }

    var externalDir = await getExternalStorageDirectory();
    if (await _checkIfDirectoryIsWritable(externalDir.path)) {
      return externalDir.path;
    }
    return null;
  }

  Future<bool> _checkIfDirectoryIsWritable(String path) async {
    final testFile = File('$path/${Random().nextInt(1000000)}');

    try {
      await testFile.create(recursive: true);
      await testFile.writeAsString("This is only a test file, please ignore.");
      await testFile.delete();
    } catch (e) {
      return false;
    }
    return true;
  }
}
