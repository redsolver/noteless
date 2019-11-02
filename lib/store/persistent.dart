import 'dart:io';

import 'package:preferences/preference_service.dart';
import 'package:yamlicious/yamlicious.dart';
import 'package:front_matter/front_matter.dart' as fm;

import 'package:notable/model/note.dart';

class PersistentStore {
  static Future saveNote(Note note, [String content]) async {
    // print('PersistentStore.saveNote');

    if (content == null) {
      content = fm.parse(note.file.readAsStringSync()).content;
    }

    String header = '---\n';
    Map data = {};

    data['title'] = note.title;

    if (PrefService.getBool('notes_list_virtual_tags') ?? false) {
      note.tags.removeWhere((s) => s.startsWith('#/'));
    }

    if (note.tags.isNotEmpty) data['tags'] = note.tags;
    if (note.attachments.isNotEmpty) data['attachments'] = note.attachments;

    data['created'] = note.created.toIso8601String();
    data['modified'] = note.modified.toIso8601String();

    if (note.pinned) data['pinned'] = true;
    if (note.favorited) data['favorited'] = true;
    if (note.deleted) data['deleted'] = true;

    header += toYamlString(data);

    header += '\n---\n\n';

    // print(header);

    note.file.writeAsStringSync(header + content);
    /*  print(header + content); */
  }

  static Future<Note> readNote(File file) async {
    // print('PersistentStore.readNote');

    if (!file.existsSync()) return null;

    String fileContent = file.readAsStringSync();

    var doc = fm.parse(fileContent);
/* 
        String headerString = fileContent.split('---')[1]; */

    var header = doc.data /* loadYaml(headerString) */;

    if (header == null) return null;

    // TODO Better Error Handling for unexpected Layout
    /* for (String line in headerString.split('\n')) {
          if (line.trim().length == 0) continue;
          print(line);
          String key=line.split(':').first;
          header[key] = line.sub;
        } */
    //print(header);
    Note note = Note();

    note.file = file;

    note.title = header['title'];
    note.created = DateTime.parse(header['created']);
    note.modified = DateTime.parse(header['modified']);
    /* 
        note.tags =
            (header['tags'] as YamlList).map((s) => s.toString()).toList(); */
    note.tags = List.from((header['tags'] ?? []).cast<String>());
    note.attachments = List.from((header['attachments'] ?? []).cast<String>());

    note.pinned = header['pinned'] ?? false;
    note.favorited = header['favorited'] ?? false;
    note.deleted = header['deleted'] ?? false;

    return note;
  }

  static Future deleteNote(Note note) async {
    await note.file.delete();
  }
}
