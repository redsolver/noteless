import 'package:flutter/material.dart';
import 'package:app/store/notes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info/package_info.dart';

class AboutPage extends StatefulWidget {
  final NotesStore store;
  AboutPage(this.store);
  @override
  _AboutPageState createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('About'),
        ),
        body: Center(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            FutureBuilder(
              future: PackageInfo.fromPlatform(),
              builder: (context, snap) {
                if (!snap.hasData) return Container();
                PackageInfo info = snap.data;
                return Column(
                  children: <Widget>[
                    Text('${info.appName}'),
                    Text('${info.packageName}'),
                    SizedBox(
                      height: 8,
                    ),
                    Text('Version ${info.version}'),
                    Text('Build ${info.buildNumber}'),
                  ],
                );
              },
            ),
            SizedBox(
              height: 16,
            ),
            RaisedButton(
              child: Text('GitHub Repo'),
              onPressed: () {
                launch('https://github.com/redsolver/noteless');
              },
            ),
          ],
        )));
  }
}
