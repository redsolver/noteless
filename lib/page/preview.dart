import 'dart:io';

import 'package:flutter/material.dart';
import 'package:app/model/note.dart';
import 'package:app/page/edit.dart';
import 'package:app/page/note_list.dart';
import 'package:app/provider/theme.dart';
import 'package:app/store/notes.dart';
import 'package:app/store/persistent.dart';
import 'package:preferences/preference_service.dart';

import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'package:markd/markdown.dart' as markd;

class PreviewPage extends StatelessWidget {
  final NotesStore store;
  final String textContent;

  PreviewPage(this.store, this.textContent);

  BuildContext context;

  @override
  Widget build(BuildContext context) {
    this.context = context;

    final directory = store.applicationDocumentsDirectory;

    final previewDir = Directory('${directory.path}/preview');

    const staticPreviewDir =
        'file:///android_asset/flutter_assets/assets/preview';

    /*  final previewAssetsDir =
                      Directory('${directory.path}/preview/assets'); */

    final File previewFile = File('${previewDir.path}/index.html');
    previewFile.createSync(recursive: true);

    // TODO iOS Preview

    String content = textContent;

    content =
        content.replaceAllMapped(RegExp(r'(?<=\]\(@note\/).*(?=\))'), (match) {
      return content.substring(match.start, match.end).replaceAll(' ', '%20');
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

<script>
 window.addEventListener('load', function () {
        flutternotable.postMessage('');
});
</script>

  </body>
  </html>''';
    generatedPreview = generatedPreview.replaceAll(
        'src="@attachment/',
        'src="' +
            'file://' +
            PrefService.getString('notable_attachments_directory') +
            '/');

    previewFile.writeAsStringSync(generatedPreview);

    bool _pageLoaded = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Stack(
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
                    })
              },
              navigationDelegate: (request) {
                print(request.url);

                if (request.url.startsWith('file://')) {
                  String link =
                      Uri.decodeFull(RegExp(r'@.*').stringMatch(request.url));
                  print(link);

                  String type = RegExp(r'(?<=@).*(?=/)').stringMatch(link);

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
