import 'dart:io';

import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:notable/model/note.dart';
import 'package:notable/page/edit.dart';
import 'package:notable/page/settings.dart';
import 'package:notable/store/notes.dart';
import 'package:notable/store/persistent.dart';
import 'package:path_provider/path_provider.dart';
import 'package:preferences/preferences.dart';
import 'package:yaml/yaml.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import 'about.dart';

class NoteListPage extends StatefulWidget {
  final String filterTag;
  final String searchText;

  NoteListPage({this.filterTag, this.searchText});

  @override
  _NoteListPageState createState() => _NoteListPageState();
}

class _NoteListPageState extends State<NoteListPage> {
  NotesStore store = NotesStore();

  TextEditingController _searchFieldCtrl = TextEditingController();
  bool searching = false;

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
    _load().then((_) => _refresh());

    super.initState();
  }

  Future<bool> _onWillPop() {
    return showDialog(
            context: context,
            child: AlertDialog(
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
      setState(() {
        _syncing = false;
      });

      await store.listNotes();

      store.updateTagList();

      store.filterAndSortNotes();

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: searching
                ? TextField(
                    decoration: InputDecoration(
                      labelText: 'Search',
                      labelStyle: TextStyle(color: Colors.black),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red),
                      ),
                    ),
                    autofocus: true,
                    cursorColor: Colors.black,
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
                      Text('Notable Alpha'),
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
                  await _refresh();
                },
                child: ListView(
                  children: <Widget>[
                    if (_syncing) ...[
                      LinearProgressIndicator(),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text('Syncing with ${store.syncMethodName}...'),
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
                            value: PrefService.getString('sort_key') ?? 'title',
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
                                  !(PrefService.getBool('sort_direction_asc') ??
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
                      Slidable(
                        actionPane: SlidableDrawerActionPane(),
                        actions: <Widget>[
                          if (note.deleted)
                            IconSlideAction(
                              caption: 'Delete',
                              color: Colors.red,
                              icon: Icons.delete_forever,
                              onTap: () async {
                                store.allNotes.remove(note);
                                PersistentStore.deleteNote(note);

                                await _filterAndSortNotes();
                              },
                            ),
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
                        child: ListTile(
                          title: Text(note.title),
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
                            await Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) => EditPage(note, store)));
                            _filterAndSortNotes();
                          },
                        ),
                      )
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () async {
            Note newNote = Note();
            int i = 1;
            while (true) {
              String title = 'Untitled';
              if (i > 1) title += ' ($i)';

              bool exists = false;
              print(i);
              for (Note note in store.allNotes) {
                if (title == note.title) {
                  exists = true;
                  break;
                }
              }
              print(i);
              if (!exists) {
                newNote.title = title;
                break;
              }
              print(i);

              i++;
            }

            newNote.created = DateTime.now();
            newNote.modified = newNote.created;

            newNote.file = File('${store.notesDir.path}/${newNote.title}.md');
            store.allNotes.add(newNote);

            _filterAndSortNotes();

            await PersistentStore.saveNote(newNote, '# ${newNote.title}');

            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => EditPage(newNote, store)));
          },
        ),
        drawer: store.shownNotes == null
            ? Container()
            : Drawer(
                child: ListView(
                children: <Widget>[
                  ListTile(
                      title: Text(store.syncMethodName + ' Sync'),
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
                            onPressed: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => SettingsPage(store)));
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
