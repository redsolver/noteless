import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:app/model/note.dart';
import 'package:app/page/edit.dart';
import 'package:app/page/settings.dart';
import 'package:app/store/notes.dart';
import 'package:app/store/persistent.dart';
import 'package:package_info/package_info.dart';
import 'package:preferences/preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:quick_actions/quick_actions.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:uuid/uuid.dart';
// import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'about.dart';

class NoteListPage extends StatefulWidget {
  final String filterTag;
  final String searchText;
  final bool isFirstPage;

  NoteListPage({this.filterTag, this.searchText, @required this.isFirstPage});

  @override
  _NoteListPageState createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  NotesStore store = NotesStore();

  TextEditingController _searchFieldCtrl = TextEditingController();
  bool searching = false;

  StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    store.currTag =
        widget.filterTag ?? PrefService.getString('current_tag') ?? '';

    if (widget.searchText != null) {
      _searchFieldCtrl.text = widget.searchText;
      store.searchText = widget.searchText;
      searching = true;
    }

    store.init();
    _load().then((_) {
      if (widget.isFirstPage) {
        final quickActions = QuickActions();
        quickActions.initialize((shortcutType) {
          if (shortcutType == 'action_create_note') {
            createNewNote();
          }
        });
        quickActions.setShortcutItems(<ShortcutItem>[
          const ShortcutItem(
              type: 'action_create_note',
              localizedTitle: 'Create note',
              icon: 'ic_shortcut_add'),
        ]);

        // For sharing or opening urls/text coming from outside the app while the app is in the memory
        _intentDataStreamSubscription =
            ReceiveSharingIntent.getTextStream().listen((String value) {
          handleSharedText(value);
          ReceiveSharingIntent.reset();
        }, onError: (err) {
          print("getLinkStream error: $err");
        });

        // For sharing or opening urls/text coming from outside the app while the app is closed
        ReceiveSharingIntent.getInitialText().then((String value) {
          handleSharedText(value);
          ReceiveSharingIntent.reset();
        });
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  handleSharedText(String value) {
    if (value == null) return;

    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text('Received text'),
              content:
                  Scrollbar(child: SingleChildScrollView(child: Text(value))),
              actions: [
                FlatButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel')),
                // FlatButton(onPressed: () {}, child: Text('Append to note')),
                FlatButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      createNewNote(value);
                    },
                    child: Text('Create new note')),
              ],
            ));
  }

  Future<bool> _onWillPop() async {
    if (_selectedNotes.isNotEmpty) {
      setState(() {
        _selectedNotes = {};
      });
      return false;
    }
    if (!widget.isFirstPage) return true;
    return await showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text('Do you want to exit the app?'),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('Cancel'),
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                    ),
                    FlatButton(
                      child: Text('Exit'),
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                    )
                  ],
                )) ??
        false;
  }

  Directory notesDir, attachmentsDir;

  Future _filterAndSortNotes() async {
    store.filterAndSortNotes();
    setState(() {});
  }

  bool _syncing = false;
  Future _load() async {
    print('LOAD');
    await store.listNotes();

    store.updateTagList();

    store.filterAndSortNotes();

    setState(() {});
  }

  Future _modifyAll(Function processNote) async {
    Navigator.of(context).pop();
    for (String title in _selectedNotes.toList()) {
      Note note = store.getNote(title);

      await processNote(note);
    }

    await _filterAndSortNotes();
  }

  Future _refresh() async {
    print('REFRESH');
    if (store.syncMethod == '') {
      await _load();
    } else {
      setState(() {
        _syncing = true;
      });
      String result = await store.syncNow();
      if (result != null) {
        showDialog(
            context: context,
            builder: (context) => AlertDialog(
                  title: Text('Sync Error'),
                  content: Text(result),
                  actions: <Widget>[
                    FlatButton(
                      child: Text('Ok'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    )
                  ],
                ));
      }
      if (!mounted) return;
      setState(() {
        _syncing = false;
      });

      await store.listNotes();

      store.updateTagList();

      store.filterAndSortNotes();

      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    Color searchFieldColor = Theme.of(context).primaryTextTheme.body1.color;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: searching
                ? TextField(
                    decoration: InputDecoration(
                      isDense: true,
                      labelText: 'Search',
                      labelStyle: TextStyle(color: searchFieldColor),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: searchFieldColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: searchFieldColor),
                      ),
                    ),
                    style: TextStyle(color: searchFieldColor),
                    autofocus: true,
                    cursorColor: searchFieldColor,
                    controller: _searchFieldCtrl,
                    onChanged: (text) {
                      store.searchText = _searchFieldCtrl.text;
                      _filterAndSortNotes();
                    },
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text('Noteless'),
                      if (store.currentTag.length > 0)
                        Text(
                          store.currentTag,
                          style: TextStyle(
                            fontSize: 12,
                          ),
                        )
                    ],
                  ),
          ),
          actions: <Widget>[
            if (!searching)
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  store.searchText = _searchFieldCtrl.text;
                  setState(() {
                    searching = true;
                  });
                  _filterAndSortNotes();
                },
              ),
            if (searching)
              IconButton(
                icon: Icon(Icons.close),
                onPressed: () {
                  store.searchText = null;
                  setState(() {
                    searching = false;
                  });
                  _filterAndSortNotes();
                },
              ),

            /* IconButton(
              icon: Icon(Icons.),
            ), */
          ],
        ),
        body: store.shownNotes == null
            ? LinearProgressIndicator()
            : RefreshIndicator(
                onRefresh: () async {
                  await _load();
                },
                child: Scrollbar(
                  child: ListView(
                    children: <Widget>[
                      if (_syncing) ...[
                        LinearProgressIndicator(),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child:
                              Text('Syncing with ${store.syncMethodName}...'),
                        ),
                        Container(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                      ],
                      Container(
                        child: Row(
                          children: <Widget>[
                            SizedBox(
                              width: 16,
                            ),
                            DropdownButton(
                              value:
                                  PrefService.getString('sort_key') ?? 'title',
                              underline: Container(),
                              onChanged: (key) {
                                PrefService.setString('sort_key', key);
                                _filterAndSortNotes();
                              },
                              items: <DropdownMenuItem>[
                                DropdownMenuItem(
                                  value: 'title',
                                  child: Text('Sort by Title'),
                                ),
                                DropdownMenuItem(
                                  value: 'date_created',
                                  child: Text('Sort by Date Created'),
                                ),
                                DropdownMenuItem(
                                  value: 'date_modified',
                                  child: Text('Sort by Date Modified'),
                                ),
                              ],
                            ),
                            Expanded(
                              child: Container(),
                            ),
                            InkWell(
                              child: Icon(
                                (PrefService.getBool('sort_direction_asc') ??
                                        true)
                                    ? Icons.keyboard_arrow_down
                                    : Icons.keyboard_arrow_up,
                                size: 32,
                              ),
                              onTap: () {
                                PrefService.setBool(
                                    'sort_direction_asc',
                                    !(PrefService.getBool(
                                            'sort_direction_asc') ??
                                        true));

                                _filterAndSortNotes();
                              },
                            ),
                            SizedBox(
                              width: 16,
                            ),
                            /*  Expanded(
                              child: 
                            ) */
                          ],
                        ),
                      ),
                      Container(
                        height: 1,
                        color: Colors.grey.shade300,
                      ),
                      for (Note note in store.shownNotes)
                        note.file == null
                            ? ListTile(
                                title: Text(
                                  note.title,
                                  style: TextStyle(
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : Slidable(
                                actionPane: SlidableDrawerActionPane(),
                                actions: <Widget>[
                                  if (note.deleted) ...[
                                    IconSlideAction(
                                      caption: 'Delete',
                                      color: Colors.red,
                                      icon: Icons.delete_forever,
                                      onTap: () async {
                                        if (await showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    AlertDialog(
                                                      title: Text(
                                                          'Do you really want to delete this note?'),
                                                      content: Text(
                                                          'This will delete it permanently.'),
                                                      actions: <Widget>[
                                                        FlatButton(
                                                          child: Text('Cancel'),
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop(false);
                                                          },
                                                        ),
                                                        FlatButton(
                                                          child: Text('Delete'),
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop(true);
                                                          },
                                                        )
                                                      ],
                                                    )) ??
                                            false) {
                                          store.allNotes.remove(note);
                                          PersistentStore.deleteNote(note);

                                          await _filterAndSortNotes();
                                        }
                                      },
                                    ),
                                    IconSlideAction(
                                      caption: 'Restore',
                                      color: Colors.redAccent,
                                      icon: MdiIcons.deleteRestore,
                                      onTap: () async {
                                        note.deleted = false;

                                        PersistentStore.saveNote(note);

                                        await _filterAndSortNotes();
                                      },
                                    ),
                                  ],
                                  if (!note.deleted)
                                    IconSlideAction(
                                      caption: 'Trash',
                                      color: Colors.red,
                                      icon: Icons.delete,
                                      onTap: () async {
                                        note.deleted = true;

                                        PersistentStore.saveNote(note);

                                        await _filterAndSortNotes();
                                      },
                                    ),
                                ],
                                secondaryActions: <Widget>[
                                  IconSlideAction(
                                    caption: note.favorited ? 'Unstar' : 'Star',
                                    color: Colors.yellow,
                                    icon: note.favorited
                                        ? MdiIcons.starOff
                                        : MdiIcons.star,
                                    onTap: () async {
                                      note.favorited = !note.favorited;

                                      PersistentStore.saveNote(note);

                                      await _filterAndSortNotes();
                                    },
                                  ),
                                  IconSlideAction(
                                    caption: note.pinned ? 'Unpin' : 'Pin',
                                    color: Colors.green,
                                    icon: note.pinned
                                        ? MdiIcons.pinOff
                                        : MdiIcons.pin,
                                    onTap: () async {
                                      note.pinned = !note.pinned;

                                      PersistentStore.saveNote(note);

                                      await _filterAndSortNotes();
                                    },
                                  ),
                                ],
                                child: ListTile(
                                  selected: _selectedNotes.contains(note.title),
                                  title: Text(note.title),
                                  subtitle: store.isDendronModeEnabled
                                      ? Text(note.file.path.substring(
                                          store.notesDir.path.length + 1))
                                      : null,
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      if (note.attachments.isNotEmpty)
                                        Icon(MdiIcons.paperclip),
                                      if (note.favorited) Icon(MdiIcons.star),
                                      if (note.pinned) Icon(MdiIcons.pin),
                                      if (note.tags.contains('color/red'))
                                        Container(
                                          color: Colors.red,
                                          width: 5,
                                        ),
                                      if (note.tags.contains('color/yellow'))
                                        Container(
                                          color: Colors.yellow,
                                          width: 5,
                                        ),
                                      if (note.tags.contains('color/green'))
                                        Container(
                                          color: Colors.green,
                                          width: 5,
                                        ),
                                      if (note.tags.contains('color/blue'))
                                        Container(
                                          color: Colors.blue,
                                          width: 5,
                                        ),
                                    ],
                                  ),
                                  onTap: () async {
                                    if (_selectedNotes.isNotEmpty) {
                                      setState(() {
                                        if (_selectedNotes
                                            .contains(note.title)) {
                                          _selectedNotes.remove(note.title);
                                        } else {
                                          _selectedNotes.add(note.title);
                                        }
                                      });
                                      return;
                                    }

                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => EditPage(
                                          note,
                                          store,
                                        ),
                                      ),
                                    );
                                    _filterAndSortNotes();
                                  },
                                  onLongPress: () {
                                    setState(() {
                                      if (_selectedNotes.contains(note.title)) {
                                        _selectedNotes.remove(note.title);
                                      } else {
                                        _selectedNotes.add(note.title);
                                      }
                                    });
                                  },
                                ),
                              )
                    ],
                  ),
                ),
              ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () async {
            createNewNote();
          },
        ),
        bottomNavigationBar: _selectedNotes.isEmpty
            ? null
            : BottomAppBar(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                                '${_selectedNotes.length} note${_selectedNotes.length > 1 ? 's' : ''} selected'),
                            Row(
                              children: <Widget>[
                                InkWell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text('ALL'),
                                  ),
                                  onTap: () {
                                    store.shownNotes.forEach((s) {
                                      _selectedNotes.add(s.title);
                                    });
                                    setState(() {});
                                  },
                                ),
                                InkWell(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text('NONE'),
                                  ),
                                  onTap: () {
                                    store.shownNotes.forEach((s) {
                                      _selectedNotes.remove(s.title);
                                    });
                                    setState(() {});
                                  },
                                )
                              ],
                            )
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(MdiIcons.star),
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    title: Text('Favorite'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        children: <Widget>[
                                          ListTile(
                                            leading: Icon(MdiIcons.star),
                                            title: Text('Favorite selected'),
                                            onTap: () =>
                                                _modifyAll((Note note) async {
                                              note.favorited = true;

                                              PersistentStore.saveNote(note);
                                            }),
                                          ),
                                          ListTile(
                                            leading: Icon(MdiIcons.starOff),
                                            title: Text('Unfavorite selected'),
                                            onTap: () =>
                                                _modifyAll((Note note) async {
                                              note.favorited = false;
                                              PersistentStore.saveNote(note);
                                            }),
                                          )
                                        ],
                                      ),
                                    ),
                                  ));
                        },
                      ),
                      IconButton(
                        icon: Icon(MdiIcons.pin),
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    title: Text('Pin'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        children: <Widget>[
                                          ListTile(
                                            leading: Icon(MdiIcons.pin),
                                            title: Text('Pin selected'),
                                            onTap: () =>
                                                _modifyAll((Note note) async {
                                              note.pinned = true;
                                              PersistentStore.saveNote(note);
                                            }),
                                          ),
                                          ListTile(
                                            leading: Icon(MdiIcons.pinOff),
                                            title: Text('Unpin selected'),
                                            onTap: () =>
                                                _modifyAll((Note note) async {
                                              note.pinned = false;
                                              PersistentStore.saveNote(note);
                                            }),
                                          )
                                        ],
                                      ),
                                    ),
                                  ));
                        },
                      ),
                      IconButton(
                        icon: Icon(MdiIcons.tag),
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    title: Text('Tags'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        children: <Widget>[
                                          ListTile(
                                            leading: Icon(MdiIcons.tagPlus),
                                            title: Text(
                                                'Add Tag to selected notes'),
                                            onTap: () async {
                                              /* 
                                                    Navigator.of(context).pop(); */
                                              TextEditingController ctrl =
                                                  TextEditingController();
                                              String newTag = await showDialog(
                                                  context: context,
                                                  builder: (context) =>
                                                      AlertDialog(
                                                        title: Text('Add Tag'),
                                                        content: TextField(
                                                          controller: ctrl,
                                                          autofocus: true,
                                                          onSubmitted: (str) {
                                                            Navigator.of(
                                                                    context)
                                                                .pop(str);
                                                          },
                                                        ),
                                                        actions: <Widget>[
                                                          FlatButton(
                                                            child:
                                                                Text('Cancel'),
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop();
                                                            },
                                                          ),
                                                          FlatButton(
                                                            child: Text('Add'),
                                                            onPressed: () {
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(ctrl
                                                                      .text);
                                                            },
                                                          ),
                                                        ],
                                                      ));
                                              if ((newTag ?? '').length > 0) {
                                                print('ADD');
                                                await _modifyAll(
                                                    (Note note) async {
                                                  note.tags.add(newTag);
                                                  PersistentStore.saveNote(
                                                      note);
                                                });
                                                store.updateTagList();
                                              } else {
                                                /* Navigator.of(context)
                                                          .pop(); */
                                              }
                                            },
                                          ),
                                          ListTile(
                                            leading: Icon(MdiIcons.tagMinus),
                                            title: Text(
                                                'Remove Tag from selected notes'),
                                            onTap: () async {
                                              Set<String> tags = {};

                                              for (String title
                                                  in _selectedNotes) {
                                                Note note =
                                                    store.getNote(title);
                                                tags.addAll(note.tags);
                                              }

                                              String tagToRemove =
                                                  await showDialog(
                                                      context: context,
                                                      builder: (context) =>
                                                          AlertDialog(
                                                            title: Text(
                                                                'Choose Tag to remove'),
                                                            content:
                                                                SingleChildScrollView(
                                                              child: Column(
                                                                children: <
                                                                    Widget>[
                                                                  for (String tag
                                                                      in tags)
                                                                    ListTile(
                                                                        title: Text(
                                                                            tag),
                                                                        onTap:
                                                                            () {
                                                                          Navigator.of(context)
                                                                              .pop(tag);
                                                                        })
                                                                ],
                                                              ),
                                                            ),
                                                            actions: <Widget>[
                                                              FlatButton(
                                                                child: Text(
                                                                    'Cancel'),
                                                                onPressed: () {
                                                                  Navigator.of(
                                                                          context)
                                                                      .pop();
                                                                },
                                                              ),
                                                            ],
                                                          ));
                                              if ((tagToRemove ?? '').length >
                                                  0) {
                                                print('REMOVE');
                                                await _modifyAll(
                                                    (Note note) async {
                                                  note.tags.remove(tagToRemove);
                                                  PersistentStore.saveNote(
                                                      note);
                                                });
                                                store.updateTagList();
                                              }
                                              /*                      _modifyAll(
                                                      (Note note) async {
                                                    note.pinned = false;
                                                    PersistentStore.saveNote(
                                                        note);
                                                  }) */
                                            },
                                          )
                                        ],
                                      ),
                                    ),
                                  ));
                        },
                      ),
                      IconButton(
                        icon: Icon(MdiIcons.delete),
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                    title: Text('Delete selected'),
                                    content: SingleChildScrollView(
                                      child: Column(
                                        children: <Widget>[
                                          ListTile(
                                            leading: Icon(MdiIcons.delete),
                                            title: Text('Move to trash'),
                                            onTap: () =>
                                                _modifyAll((Note note) {
                                              note.deleted = true;

                                              PersistentStore.saveNote(note);
                                            }),
                                          ),
                                          ListTile(
                                            leading:
                                                Icon(MdiIcons.deleteRestore),
                                            title: Text('Restore from trash'),
                                            onTap: () =>
                                                _modifyAll((Note note) {
                                              note.deleted = false;

                                              PersistentStore.saveNote(note);
                                            }),
                                          ),
                                          ListTile(
                                              leading:
                                                  Icon(MdiIcons.deleteForever),
                                              title: Text('Delete forever'),
                                              onTap: () async {
                                                if (await showDialog(
                                                        context: context,
                                                        builder:
                                                            (context) =>
                                                                AlertDialog(
                                                                  title: Text(
                                                                      'Do you really want to delete the selected notes?'),
                                                                  content: Text(
                                                                      'This will delete them permanently.'),
                                                                  actions: <
                                                                      Widget>[
                                                                    FlatButton(
                                                                      child: Text(
                                                                          'Cancel'),
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.of(context)
                                                                            .pop(false);
                                                                      },
                                                                    ),
                                                                    FlatButton(
                                                                      child: Text(
                                                                          'Delete'),
                                                                      onPressed:
                                                                          () {
                                                                        Navigator.of(context)
                                                                            .pop(true);
                                                                      },
                                                                    )
                                                                  ],
                                                                )) ??
                                                    false) {
                                                  await _modifyAll((Note note) {
                                                    store.allNotes.remove(note);

                                                    PersistentStore.deleteNote(
                                                        note);
                                                    _selectedNotes
                                                        .remove(note.title);
                                                  });
                                                }
                                              })
                                        ],
                                      ),
                                    ),
                                  ));
                        },
                      ),
                    ],
                  ),
                ),
              ),
        drawer: store.shownNotes == null
            ? Container()
            : Drawer(
                child: ListView(
                children: <Widget>[
                  ListTile(
                      title: FutureBuilder(
                        future: PackageInfo.fromPlatform(),
                        builder: (context, snap) {
                          if (!snap.hasData) return SizedBox();
                          PackageInfo info = snap.data;
                          return Text('${info.appName} ${info.version}');
                        },
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          IconButton(
                            icon: Icon(Icons.info),
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => AboutPage(store)));
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.settings),
                            onPressed: () async {
                              await Navigator.of(context).push(
                                  MaterialPageRoute(
                                      builder: (context) =>
                                          SettingsPage(store)));
                              setState(() {});
                            },
                          ),
                        ],
                      )),
                  Divider(),
                  /* DrawerHeader(
                    child: Text('Hello'),
                  ), */
                  TagDropdown('', store, () {
                    Navigator.of(context).pop();
                    _filterAndSortNotes();
                  },
                      icon: MdiIcons.noteText,
                      displayTag: 'All Notes',
                      hasSubTags: false),
                  TagDropdown('Favorites', store, () {
                    Navigator.of(context).pop();
                    _filterAndSortNotes();
                  }, icon: MdiIcons.star, hasSubTags: false),
                  for (String tag in store.rootTags)
                    TagDropdown(
                        tag,
                        store /* 
                        store.allTags.where((t) => t.startsWith(tag)).toList() */
                        , () {
                      Navigator.of(context).pop();
                      _filterAndSortNotes();
                    }, foldedByDefault: !['Notebooks'].contains(tag)),
                  TagDropdown(
                    'Untagged',
                    store,
                    () {
                      Navigator.of(context).pop();
                      _filterAndSortNotes();
                    },
                    icon: MdiIcons.labelOff,
                    hasSubTags: false,
                  ),
                  TagDropdown('Trash', store, () {
                    Navigator.of(context).pop();
                    _filterAndSortNotes();
                  }, icon: Icons.delete),
                ],
              )),
      ),
    );
  }

  Future<void> createNewNote([String content = '']) async {
    Note newNote = Note();
    int i = 1;
    while (true) {
      String title = 'Untitled';
      if (i > 1) title += ' ($i)';

      bool exists = false;

      for (Note note in store.allNotes) {
        if (title == note.title) {
          exists = true;
          break;
        }
      }

      if (!exists) {
        newNote.title = title;
        break;
      }

      i++;
    }

    if (store.isDendronModeEnabled) {
      newNote.usesMillis = true;
      newNote.usesUpdatedInsteadOfModified = true;
      newNote.additionalFrontMatterKeys = {
        'id': Uuid().v4(),
        'desc': '',
      };
    }

    newNote.created = DateTime.now();
    newNote.modified = newNote.created;

    newNote.file = File('${store.notesDir.path}/${newNote.title}.md');
    store.allNotes.add(newNote);

    _filterAndSortNotes();

    PrefService.setBool('editor_mode_switcher_is_preview', false);

    await PersistentStore.saveNote(newNote, '# ${newNote.title}\n\n$content');

    await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => EditPage(
              newNote,
              store,
              autofocus: true,
            )));
    _filterAndSortNotes();
  }

  Set<String> _selectedNotes = {};

  /* _setFilterTagAndRefresh(BuildContext context, String tag) {
    Navigator.of(context).pop();
    store.currentTag = tag;
    _filterAndSortNotes();
  } */
}

class TagDropdown extends StatefulWidget {
  final String tag;
  /*  final List<String> subTags; */

  final NotesStore store;

  final Function apply;

  final IconData icon;

  final bool foldedByDefault;

  final String displayTag;

  final bool hasSubTags;

  TagDropdown(this.tag, this.store /* this.subTags */, this.apply,
      {this.icon,
      this.foldedByDefault = true,
      this.displayTag,
      this.hasSubTags});

  @override
  _TagDropdownState createState() => _TagDropdownState();
}

class _TagDropdownState extends State<TagDropdown> {
  NotesStore get store => widget.store;

  bool _folded;

  @override
  void initState() {
    super.initState();

    if (widget.hasSubTags == null) {
      _hasSubTags = store.getSubTags(widget.tag).length > 0;
    } else {
      _hasSubTags = widget.hasSubTags;
    }
    _isSelected = store.currentTag == widget.tag;
    _folded = widget.foldedByDefault;
    if (store.currentTag.startsWith(widget.tag)) _folded = false;
  }

  bool _hasSubTags;

  bool _isSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        ListTile(
          leading: widget.icon != null
              ? Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(widget.icon,
                      color:
                          _isSelected ? Theme.of(context).accentColor : null),
                )
              : _hasSubTags
                  ? InkWell(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Icon(
                            _folded
                                ? MdiIcons.chevronRight
                                : MdiIcons.chevronDown,
                            color: _isSelected
                                ? Theme.of(context).accentColor
                                : null),
                      ),
                      onTap: () {
                        setState(() {
                          _folded = !_folded;
                        });
                      },
                    )
                  : Padding(
                      padding: const EdgeInsets.all(8.0),
                    ),
          // trailing: Text(_countNotesWithTag(allNotes, tag).toString()),
          title: Text(widget.displayTag ?? widget.tag.split('/').last,
              style: _isSelected
                  ? TextStyle(color: Theme.of(context).accentColor)
                  : null),
          trailing: Text(
              store.countNotesWithTag(store.allNotes, widget.tag).toString(),
              style: _isSelected
                  ? TextStyle(color: Theme.of(context).accentColor)
                  : null),

          onTap: () {
            store.currentTag = widget.tag;
            widget.apply();
          },
        ),
        if (_hasSubTags && !_folded)
          Padding(
            padding: const EdgeInsets.only(left: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                for (String subTag in store.getSubTags(widget.tag))
                  TagDropdown(widget.tag + '/' + subTag, store, widget.apply)
              ],
            ),
          )
      ],
    );
  }
}
