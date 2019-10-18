import 'package:flutter/material.dart';
import 'package:notable/store/notes.dart';

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
            Text('This app is unofficial'),
            SizedBox(
              height: 16,
            ),
            Text('<< More interesting facts about this app >>'),
          ],
        )));
  }
}
