import 'dart:io';

import 'package:flutter/material.dart';
import 'package:app/model/note.dart';
import 'package:app/page/edit.dart';
import 'package:app/page/note_list.dart';
import 'package:app/provider/theme.dart';
import 'package:app/store/notes.dart';
import 'package:app/store/persistent.dart';
import 'package:markd/markdown.dart';
import 'package:preferences/preference_service.dart';

import 'package:provider/provider.dart';
import 'package:rich_code_editor/rich_code_controller.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:markd/markdown.dart' as markd;

import 'package:markd/src/ast.dart' as markd_ast;

class PreviewPage extends StatefulWidget {
  final NotesStore store;
  final String textContent;
  final RichCodeEditingController richCtrl;

  final ThemeData theme;

  PreviewPage(this.store, this.textContent, this.richCtrl, this.theme);

  @override
  _PreviewPageState createState() => _PreviewPageState();
}

class _PreviewPageState extends State<PreviewPage> {
  // BuildContext context;

  String currentTextContent;

  @override
  void initState() {
    _processContent();
    super.initState();
  }

  List<int> checkboxPositions = [];

  File previewFile;

  _processContent() async {
    //this.context = context;

    final directory = widget.store.applicationDocumentsDirectory;

    final previewDir = Directory('${directory.path}/preview');

    const staticPreviewDir =
        'file:///android_asset/flutter_assets/assets/preview';

    /*  final previewAssetsDir =
                      Directory('${directory.path}/preview/assets'); */

    previewFile = File('${previewDir.path}/index.html');
    previewFile.createSync(recursive: true);

    // TODO iOS Preview

    currentTextContent = widget.textContent;

    for (final match in RegExp(r'\[(x| )\]').allMatches(currentTextContent)) {
      // print(match);
      checkboxPositions.add(match.start + 1);
    }

    String content = widget.textContent;

    // Wiki-Style note links like [[Note]]

    content = content.replaceAllMapped(RegExp(r'\[\[[^\]]+\]\]'), (match) {
      var str = match.input.substring(match.start, match.end);

      String title = str.substring(2).split(']').first;

      return '[$title](@note/$title' +
          (title.endsWith('.md') ? '' : '.md') +
          ')';
    });

    content =
        content.replaceAllMapped(RegExp(r'(?<=\]\(@note\/).*(?=\))'), (match) {
      return content.substring(match.start, match.end).replaceAll(' ', '%20');
    });

    content = content.replaceAll(RegExp(r'\\\\'), '\\\\\\\\');

    ThemeData theme = widget.theme;

    String backgroundColor = theme.scaffoldBackgroundColor.value
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2);

    String textColor = theme.textTheme.body1.color.value
        .toRadixString(16)
        .padLeft(8, '0')
        .substring(2);

    String accentColor =
        theme.accentColor.value.toRadixString(16).padLeft(8, '0').substring(2);

    String generatedPreview = '''
<!DOCTYPE html>
<html>
<head>
''' +
        (Provider.of<ThemeNotifier>(context, listen: false).currentTheme ==
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

  <script src="$staticPreviewDir/asciimath2tex.umd.js" ></script>



    <!-- KaTeX auto-render extension -->
    <script defer src="$staticPreviewDir/katex.auto-render.min.js"
        onload="const parser = new AsciiMathParser();renderMathInElement(document.body, 
        {delimiters:
        [
          {left: '\$\$', right: '\$\$', display: true},
          {left: '\$', right: '\$', display: false},
        ],
        preProcess: (math)=>{
          return math.trim();
        }
        });
renderMathInElement(document.body, 
        {delimiters:
        [
          {left: '&&', right: '&&', display: true},
          {left: '&', right: '&', display: false},
        ],
        preProcess: (math)=>{
          return parser.parse(math.trim());
        }
        });
"></script>

<style>
table {
  border-collapse: collapse;
}

table, th, td {
  border: 1px solid ${theme.brightness == Brightness.light ? 'lightgrey' : 'grey'};
}

th, td {
  padding: 8px;
}

tr:nth-child(even) {background-color: ${theme.brightness == Brightness.light ? '#f2f2f2' : '#404040'};}

pre {
  max-width: 100%;
  overflow-x: scroll;
}

blockquote{
  padding: 0em 0em 0em .6em;
  margin-left: .1em;
  border-left: 0.3em solid ${theme.brightness == Brightness.light ? 'lightgrey' : 'grey'};
}


</style>
</head>
<body>
                      ''' +
        markd.markdownToHtml(
          content,
          extensionSet: markd.ExtensionSet.gitHubWeb,
          inlineSyntaxes: [
            if (PrefService.getBool('single_line_break_syntax') ?? false)
              SingleLineBreakSyntax(),
          ],
          /* blockSyntaxes: [FencedCodeBlockSyntax()], */
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

<script>
 window.addEventListener('load', function () {
        flutternotable.postMessage('');
});
</script>

  </body>
  </html>''';

/*     generatedPreview = generatedPreview.replaceAll('\\ ', ' '); */
    generatedPreview = generatedPreview
        .replaceAll(
            'src="@attachment/',
            'src="' +
                'file://' +
                PrefService.getString('notable_attachments_directory') +
                '/')
        .replaceAll(
            'src="/',
            'src="' +
                'file://' +
                PrefService.getString('notable_notes_directory') +
                '/');

    generatedPreview =
        generatedPreview.replaceAll('<img ', '<img width="100%" ');

    // print(generatedPreview.split('<body>')[1]);

    int checkboxIndex = -1;

    generatedPreview = generatedPreview.replaceAllMapped(
        'disabled="disabled" class="todo" type="checkbox"', (match) {
      checkboxIndex++;

      return 'class="todo" type="checkbox" onclick="notelesscheckbox.postMessage( this.checked + \'-$checkboxIndex\');"';
    });

    await previewFile.writeAsString(generatedPreview);

    setState(() {
      _processingDone = true;
    });
  }

  bool _processingDone = false;

  bool _pageLoaded = false;

  @override
  Widget build(BuildContext context) {
    // print('BUILD');

    return StatefulBuilder(
      builder: (context, setState) {
        return !_processingDone
            ? Center(
                child: CircularProgressIndicator(),
              )
            : Stack(
                children: <Widget>[
                  WebView(
                    initialUrl: 'file://' + previewFile.path,
                    javascriptMode: JavascriptMode.unrestricted,
                    onWebViewCreated: (ctrl) {},
                    javascriptChannels: {
                      JavascriptChannel(
                          name: 'flutternotable',
                          onMessageReceived: (_) async {
                            setState(() {
                              _pageLoaded = true;
                            });
                          }),
                      JavascriptChannel(
                          name: 'notelesscheckbox',
                          onMessageReceived: (msg) async {
                            final parts = msg.message.split('-');

                            final bool checked = parts[0] == 'true';

                            final int id = int.parse(parts[1]);

                            final index = checkboxPositions[id];

                            currentTextContent =
                                currentTextContent.substring(0, index) +
                                    (checked ? 'x' : ' ') +
                                    currentTextContent.substring(index + 1);

                            widget.richCtrl.text = currentTextContent;

                            // textContent
                          }),
                    },
                    navigationDelegate: (request) {
                      print(request.url);

                      if (request.url.startsWith('file://')) {
                        String link = Uri.decodeFull(
                            RegExp(r'@.*').stringMatch(request.url));
                        print(link);

                        String type =
                            RegExp(r'(?<=@).*(?=/)').stringMatch(link);

                        String data = RegExp(r'(?<=/).*').stringMatch(link);
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
                  if (!_pageLoaded)
                    Container(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(),
                    ),
                ],
              );
      },
    );
  }

  void _navigateToNote(String title) async {
    if (!title.endsWith('.md')) title += '.md';
    Note newNote = await PersistentStore.readNote(
        File('${PrefService.getString('notable_notes_directory')}/${title}'));
    if (newNote == null) {
      // TODO Show Error
    } else {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => EditPage(newNote, widget.store)));
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

/// Represents a hard line break.
class SingleLineBreakSyntax extends InlineSyntax {
  SingleLineBreakSyntax() : super(r'\n');

  /// Create a void <br> element.
  @override
  bool onMatch(InlineParser parser, Match match) {
    parser.addNode(markd_ast.Element.empty('br'));
    return true;
  }
}
