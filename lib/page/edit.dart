import 'dart:convert';
import 'dart:io';

import 'package:app/main.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:app/model/note.dart';
import 'package:markd/markdown.dart' as markd;
import 'package:front_matter/front_matter.dart' as fm;
import 'package:bsdiff/bsdiff.dart';
import 'package:app/page/note_list.dart';
import 'package:app/page/preview.dart';
import 'package:app/store/notes.dart';
import 'package:app/store/persistent.dart';
import 'package:preferences/preference_service.dart';

class EditPage extends StatefulWidget {
  final Note note;
  final NotesStore store;
  final bool autofocus;

  EditPage(this.note, this.store, {this.autofocus = false});

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  NotesStore get store => widget.store;
  TextEditingController ctrl;

  Note note;

  bool _saved = true;

  bool _previewEnabled = false;

  @override
  void initState() {
    note = widget.note;

    _loadContent();

    super.initState();
  }

  _loadContent() async {
    String content = note.file.readAsStringSync();

    var doc = fm.parse(content);

    ctrl = TextEditingController(text: doc.content.trimLeft());

    currentData = ctrl.text;

    _updateMaxLines();
    if (PrefService.getBool('editor_mode_switcher') ?? true) {
      if (PrefService.getBool('editor_mode_switcher_is_preview') ?? false) {
        setState(() {
          _previewEnabled = true;
        });
      }
    }
  }

  GlobalKey<ScaffoldState> _scaffold = GlobalKey();

  Future<bool> _onWillPop() async {
    if (_saved) return true;
    return await showDialog(
            context: context,
            child: AlertDialog(
              title: Text('Unsaved changes'),
              content:
                  Text('Do you really want to discard your current changes?'),
              actions: <Widget>[
                FlatButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                ),
                FlatButton(
                  child: Text('Discard'),
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                )
              ],
            )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
          key: _scaffold,
          appBar: AppBar(
            title: Text(note.title),
            actions: <Widget>[
              if (!_saved)
                IconButton(
                  icon: Icon(Icons.save),
                  onPressed: () async {
                    String markedTitle = markd.markdownToHtml(
                        RegExp(
                          r'(?<=# ).*',
                        ).stringMatch(currentData),
                        extensionSet: markd.ExtensionSet.gitHubWeb);
                    print(markedTitle);

                    String title =
                        markedTitle.replaceAll(RegExp(r'<[^>]*>'), '').trim();
                    print(title);

                    File oldFile;
                    if (note.title != title) {
                      if (File(
                              PrefService.getString('notable_notes_directory') +
                                  '/' +
                                  title +
                                  '.md')
                          .existsSync()) {
                        showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                                  title: Text('Conflict'),
                                  content: Text(
                                      'There is already a note with this title.'),
                                  actions: <Widget>[
                                    FlatButton(
                                      child: Text('Ok'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      },
                                    )
                                  ],
                                ));
                        return;
                      } else {
                        oldFile = note.file;
                        note.file = File(
                            PrefService.getString('notable_notes_directory') +
                                '/' +
                                title +
                                '.md');
                      }
                    }

                    note.title = title;

                    note.modified = DateTime.now();

                    await PersistentStore.saveNote(note, currentData);

                    if (oldFile != null) oldFile.deleteSync();

                    setState(() {
                      _saved = true;
                    });
                  },
                ),
              if (previewFeatureEnabled)
                ((PrefService.getBool('editor_mode_switcher') ?? true)
                    ? Switch(
                        value: _previewEnabled,
                        activeColor: Theme.of(context).primaryIconTheme.color,
                        onChanged: (value) {
                          PrefService.setBool(
                              'editor_mode_switcher_is_preview', value);
                          setState(() {
                            _previewEnabled = value;
                          });
                        },
                      )
                    : IconButton(
                        icon: Icon(Icons.chrome_reader_mode),
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(
                                  title: Text('Preview'),
                                ),
                                body: PreviewPage(store, ctrl.text),
                              ),
                            ),
                          );
                        },
                      )),
              PopupMenuButton<String>(
                onSelected: (String result) async {
                  int divIndex = result.indexOf('.');
                  if (divIndex == -1) divIndex = result.length;

                  switch (result.substring(0, divIndex)) {
                    case 'favorite':
                      note.favorited = !note.favorited;

                      break;
                    case 'pin':
                      note.pinned = !note.pinned;

                      break;

                    case 'addAttachment':
                      File file = await FilePicker.getFile();

                      if (file != null) {
                        String fullFileName = file.path.split('/').last;
                        int dotIndex = fullFileName.indexOf('.');

                        String fileName = fullFileName.substring(0, dotIndex);
                        String fileEnding = fullFileName.substring(dotIndex);

                        File newFile = File(
                            store.attachmentsDir.path + '/' + fullFileName);

                        int i = 0;

                        while (newFile.existsSync()) {
                          i++;
                          newFile = File(store.attachmentsDir.path +
                              '/' +
                              fileName +
                              ' ($i)' +
                              fileEnding);
                        }
                        await file.copy(newFile.path);

                        note.attachments.add(newFile.path.split('/').last);

                        await file.delete();
                      }

                      break;

                    case 'removeAttachment':
                      String attachment = result.substring(divIndex + 1);

                      bool remove = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                                title: Text('Delete Attachment'),
                                content: Text(
                                    'Do you want to delete the attachment "$attachment"? This will remove it from this note and delete it permanently on disk.'),
                                actions: <Widget>[
                                  FlatButton(
                                    child: Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  FlatButton(
                                    child: Text('Delete'),
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                  ),
                                ],
                              ));
                      if (remove ?? false) {
                        File file =
                            File(store.attachmentsDir.path + '/' + attachment);
                        await file.delete();
                        note.attachments.remove(attachment);
                      }

                      break;

                    case 'addTag':
                      TextEditingController ctrl = TextEditingController();
                      String newTag = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                                title: Text('Add Tag'),
                                content: TextField(
                                  controller: ctrl,
                                  autofocus: true,
                                ),
                                actions: <Widget>[
                                  FlatButton(
                                    child: Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  FlatButton(
                                    child: Text('Add'),
                                    onPressed: () {
                                      Navigator.of(context).pop(ctrl.text);
                                    },
                                  ),
                                ],
                              ));
                      if ((newTag ?? '').length > 0) {
                        print('ADD');
                        note.tags.add(newTag);
                        store.updateTagList();
                      }
                      break;

                    case 'removeTag':
                      String tag = result.substring(divIndex + 1);

                      bool remove = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                                title: Text('Remove Tag'),
                                content: Text(
                                    'Do you want to remove the tag "$tag" from this note?'),
                                actions: <Widget>[
                                  FlatButton(
                                    child: Text('Cancel'),
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                  FlatButton(
                                    child: Text('Remove'),
                                    onPressed: () {
                                      Navigator.of(context).pop(true);
                                    },
                                  ),
                                ],
                              ));
                      if (remove ?? false) {
                        print('REMOVE');
                        note.tags.remove(tag);
                        store.updateTagList();
                      }

                      break;
                  }
                  PersistentStore.saveNote(note);
                },
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'favorite',
                    child: Row(
                      children: <Widget>[
                        Icon(
                          note.favorited ? MdiIcons.starOff : MdiIcons.star,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Text(note.favorited ? 'Unfavorite' : 'Favorite'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'pin',
                    child: Row(
                      children: <Widget>[
                        Icon(
                          note.pinned ? MdiIcons.pinOff : MdiIcons.pin,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Text(note.pinned ? 'Unpin' : 'Pin'),
                      ],
                    ),
                  ),
                  for (String attachment in note.attachments)
                    PopupMenuItem<String>(
                      value: 'removeAttachment.$attachment',
                      child: Row(
                        children: <Widget>[
                          Icon(
                            MdiIcons.paperclip,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Text(attachment),
                        ],
                      ),
                    ),
                  PopupMenuItem<String>(
                    value: 'addAttachment',
                    child: Row(
                      children: <Widget>[
                        Icon(
                          MdiIcons.filePlus,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Text('Add Attachment'),
                      ],
                    ),
                  ),
                  for (String tag in note.tags)
                    PopupMenuItem<String>(
                      value: 'removeTag.$tag',
                      child: Row(
                        children: <Widget>[
                          Icon(
                            MdiIcons.tag,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          SizedBox(
                            width: 8,
                          ),
                          Text(tag),
                        ],
                      ),
                    ),
                  PopupMenuItem<String>(
                    value: 'addTag',
                    child: Row(
                      children: <Widget>[
                        Icon(
                          MdiIcons.tagPlus,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        SizedBox(
                          width: 8,
                        ),
                        Text('Add Tag'),
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
          body: /* GestureDetector(
          child: */
              ctrl == null
                  ? LinearProgressIndicator()
                  : _previewEnabled
                      ? PreviewPage(store, ctrl.text)
                      : Column(
                          children: <Widget>[
                            Expanded(
                              /* 
                          fit: FlexFit.tight, */
                              child: Scrollbar(
                                child: SingleChildScrollView(
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextField(
                                      autofocus: widget.autofocus,
                                      scrollPhysics:
                                          NeverScrollableScrollPhysics(),
                                      controller: ctrl,
                                      style: TextStyle(
                                          fontFamily: 'FiraMono',
                                          fontFamilyFallback: ['monospace']),
                                      decoration: InputDecoration(
                                          border: InputBorder.none,
                                          contentPadding:
                                              const EdgeInsets.all(0.0)),
                                      scrollPadding: const EdgeInsets.all(0.0),
                                      /*  autofocus: true, */
                                      keyboardType: TextInputType.multiline,
                                      maxLines: null,
                                      onChanged: (str) {
                                        //print('change!');

                                        var diff = bsdiff(utf8.encode(str),
                                            utf8.encode(currentData));
                                        history.add(diff);
                                        if (history.length == 1) {
                                          // First entry
                                          setState(() {});
                                        } else if (history.length > 1000) {
                                          // First entry
                                          history.removeAt(0);
                                        }

                                        currentData = str;
                                        if (_saved)
                                          setState(() {
                                            _saved = false;
                                          });
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 32,
                              color: Theme.of(context).dividerColor,
                              child: Material(
                                color: Colors.transparent,
                                child: Row(
                                  children: <Widget>[
                                    /* 
                                if (history.isNotEmpty) */
                                    Flexible(
                                      fit: FlexFit.tight,
                                      child: SizedBox(
                                        height: double.infinity,
                                        child: InkWell(
                                          child: Icon(
                                            Icons.undo,
                                            color: history.isEmpty
                                                ? Colors.grey
                                                : null,
                                          ),
                                          onTap: history.isEmpty
                                              ? null
                                              : () {
                                                  currentData = utf8.decode(
                                                      bspatch(
                                                          utf8.encode(
                                                              currentData),
                                                          history
                                                              .removeLast()));

                                                  ctrl.text = currentData;
                                                  if (history.isEmpty) {
                                                    setState(() {});
                                                  }
                                                  if (_saved)
                                                    setState(() {
                                                      _saved = false;
                                                    });
                                                },
                                        ),
                                      ),
                                    ),
                                    /*       Flexible(
                                      fit: FlexFit.tight,
                                      child: SizedBox(
                                        height: double.infinity,
                                        child: InkWell(
                                          child: Icon(
                                            Icons.undo,
                                            color: history.isEmpty
                                                ? Colors.grey
                                                : null,
                                          ),
                                          onTap: history.isEmpty
                                              ? null
                                              : () {
                                                  currentData = utf8.decode(
                                                      bspatch(
                                                          utf8.encode(
                                                              currentData),
                                                          history
                                                              .removeLast()));

                                                  ctrl.text = currentData;
                                                  if (history.isEmpty) {
                                                    setState(() {});
                                                  }
                                                  if (_saved)
                                                    setState(() {
                                                      _saved = false;
                                                    });
                                                },
                                        ),
                                      ),
                                    ), */
                                    Flexible(
                                      fit: FlexFit.tight,
                                      child: SizedBox(
                                        height: double.infinity,
                                        child: InkWell(
                                          child: Icon(
                                            Icons.check_box_outline_blank,
                                          ),
                                          onTap: () {
                                            _scaffold.currentState
                                                .showSnackBar(SnackBar(
                                              content: Text('Not implemented'),
                                            ));
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          ],
                        )),
    );
  }

  String currentData = '';

  List history = [];

  int maxLines = 0;
  _updateMaxLines() {
    int newMaxLines = ctrl.text.split('\n').length + 3;
    if (newMaxLines < 10) newMaxLines = 10;
    if (newMaxLines != maxLines) {
      setState(() {
        maxLines = newMaxLines;
      });
    }
  }
}
