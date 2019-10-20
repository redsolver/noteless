import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:notable/model/note.dart';
import 'package:markd/markdown.dart' as markd;
import 'package:front_matter/front_matter.dart' as fm;
import 'package:bsdiff/bsdiff.dart';
import 'package:notable/page/note_list.dart';
import 'package:notable/provider/theme.dart';
import 'package:notable/store/notes.dart';
import 'package:notable/store/persistent.dart';
import 'package:path_provider/path_provider.dart';
import 'package:preferences/preference_service.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class EditPage extends StatefulWidget {
  final Note note;
  final NotesStore store;

  EditPage(this.note, this.store);

  @override
  _EditPageState createState() => _EditPageState();
}

class _EditPageState extends State<EditPage> {
  NotesStore get store => widget.store;
  TextEditingController ctrl;

  Note note;

  bool _saved = true;

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
              IconButton(
                icon: Icon(Icons.chrome_reader_mode),
                onPressed: () async {
                  final directory = await getApplicationDocumentsDirectory();

                  final previewDir = Directory('${directory.path}/preview');

                  const staticPreviewDir =
                      'file:///android_asset/flutter_assets/assets/preview';

                  /*  final previewAssetsDir =
                      Directory('${directory.path}/preview/assets'); */

                  final File previewFile =
                      File('${previewDir.path}/index.html');
                  previewFile.createSync(recursive: true);

                  // TODO iOS Preview

                  String content = ctrl.text;

                  content = content.replaceAllMapped(
                      RegExp(r'(?<=\]\(@note\/).*(?=\))'), (match) {
                    return content
                        .substring(match.start, match.end)
                        .replaceAll(' ', '%20');
                  });

                  content = content.replaceAll(RegExp(r'\\\\'), '\\\\\\\\');

                  ThemeData theme = Theme.of(context);

                  String backgroundColor = theme.scaffoldBackgroundColor.value
                      .toRadixString(16)
                      .padLeft(8, '0')
                      .substring(2);

                  String textColor = theme.textTheme.body1.color.value
                      .toRadixString(16)
                      .padLeft(8, '0')
                      .substring(2);

                  String accentColor = theme.accentColor.value
                      .toRadixString(16)
                      .padLeft(8, '0')
                      .substring(2);

                  String generatedPreview = '''
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8"/>
''' +
                      (Provider.of<ThemeNotifier>(context).currentTheme ==
                              ThemeType.light
                          ? ''
                          : '''
  <style>
  body {
    background-color: #$backgroundColor;
    color: #$textColor;
  }
  a {
    color: #$accentColor;
  }
  img {
    filter: grayscale(20%);
  }
  </style>
  ''') +
                      '''

	<link href="$staticPreviewDir/prism.css" rel="stylesheet" />

  <link rel="stylesheet" href="$staticPreviewDir/katex.min.css">

  <script defer src="$staticPreviewDir/katex.min.js"></script>

  <script defer src="$staticPreviewDir/mhchem.min.js"></script>


    <!-- KaTeX auto-render extension -->
    <script defer src="$staticPreviewDir/katex.auto-render.min.js"
        onload="renderMathInElement(document.body, 
        {delimiters:
        [
          {left: '\$\$', right: '\$\$', display: true},
          {left: '\$', right: '\$', display: false}
        ],
        preProcess: (math)=>math.trim()
        });
"></script>


</head>
<body>
                      ''' +
                      markd.markdownToHtml(
                        content,
                        extensionSet: markd.ExtensionSet.gitHubWeb,
                      ) +
                      '''
<script src="$staticPreviewDir/mermaid.min.js"></script>
<script>mermaid.initialize({startOnLoad:true}, ".language-mermaid");</script>


      <script src="$staticPreviewDir/prism.js"></script>

      
  <script>
  document.querySelectorAll(".language-mermaid").forEach(function(entry) {
      entry.className="mermaid"
});
  mermaid.initialize({startOnLoad:true}, ".language-mermaid");
  </script>
  </body>
  </html>''';
                  generatedPreview = generatedPreview.replaceAll(
                      'src="@attachment/',
                      'src="' +
                          'file://' +
                          PrefService.getString(
                              'notable_attachments_directory') +
                          '/');

                  previewFile.writeAsStringSync(generatedPreview);

                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => Scaffold(
                          appBar: AppBar(
                            title: Text('Preview'),
                          ),
                          body: Padding(
                            padding: const EdgeInsets.symmetric(horizontal:8.0),
                            child: WebView(
                              initialUrl: 'file://' + previewFile.path,
                              javascriptMode: JavascriptMode.unrestricted,
                              onWebViewCreated: (ctrl) {},
                              navigationDelegate: (request) {
                                print(request.url);

                                if (request.url.startsWith('file://')) {
                                  String link = Uri.decodeFull(
                                      RegExp(r'@.*').stringMatch(request.url));
                                  print(link);

                                  String type =
                                      RegExp(r'(?<=@).*(?=/)').stringMatch(link);

                                  String data =
                                      RegExp(r'(?<=/).*').stringMatch(link);
                                  print(type);
                                  print(data);
                                  print(Theme.of(context).brightness);
                                  switch (type) {
                                    case 'note':
                                      _navigateToNote(data);

                                      break;
                                    case 'tag':
                                      _navigateToTag(data);
                                      break;
                                    case 'search':
                                      _navigateToSearch(data);
                                      break;
                                    case 'attachment':
                                      break;
                                  }
                                } else {
                                  launch(
                                    request.url,
                                  );
                                }
                                return NavigationDecision.prevent;
                              },
                            ),
                          ))));
                },
              ),
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
                        Icon(note.favorited ? MdiIcons.starOff : MdiIcons.star),
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
                        Icon(note.pinned ? MdiIcons.pinOff : MdiIcons.pin),
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
                          Icon(MdiIcons.paperclip),
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
                        Icon(MdiIcons.filePlus),
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
                          Icon(MdiIcons.tag),
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
                        Icon(MdiIcons.tagPlus),
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
                                  scrollPhysics: NeverScrollableScrollPhysics(),
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
                                    print('change!');

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
                                              currentData = utf8.decode(bspatch(
                                                  utf8.encode(currentData),
                                                  history.removeLast()));

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

  void _navigateToNote(String title) async {
    if (!title.endsWith('.md')) title += '.md';
    Note newNote = await PersistentStore.readNote(
        File('${PrefService.getString('notable_notes_directory')}/${title}'));
    if (newNote == null) {
      // TODO Show Error
    } else {
      Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => EditPage(newNote, store)));
    }
  }

  void _navigateToTag(String tag) async {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => NoteListPage(
              filterTag: tag,
              isFirstPage: false,
            )));
  }

  void _navigateToSearch(String search) async {
    Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => NoteListPage(
              searchText: search,
              isFirstPage: false,
            )));
  }
}
