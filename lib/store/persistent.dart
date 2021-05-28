import 'dart:io';

import 'package:app/utils/yaml.dart';
import 'package:preferences/preference_service.dart';
import 'package:front_matter/front_matter.dart' as fm;

import 'package:app/model/note.dart';

const supportedFrontMatterKeys = [
  'title',
  'modified',
  'created',
  'tags',
  'attachments',
  'pinned',
  'favorited',
  'deleted',
  'updated',
];

class PersistentStore {
  static bool get isDendronModeEnabled =>
      (PrefService.getBool('dendron_mode') ?? false);

  static Future<String> readContent(
    Note note,
  ) async {
    if (!note.file.existsSync()) return null;

    String fileContent = await note.file.readAsString();

    var content;

    if (fileContent.trimLeft().startsWith('---')) {
      var doc = fm.parse(fileContent);
      if (doc.content != null) {
        content = doc.content.trimLeft();
      } else {
        content = fileContent.trimLeft();
      }
    } else {
      content = fileContent.trimLeft();
    }

    if (isDendronModeEnabled) {
      if (!content.startsWith('# ')) {
        content = '# ${note.title}\n\n' + content;
      }
    }

    return content;
  }

  static Future saveNote(Note note, [String content]) async {
    // print('PersistentStore.saveNote');

    if (content == null) {
      content = await readContent(note);
    }
    if (isDendronModeEnabled) {
      final index = content.indexOf('\n');
      if (index != -1) content = content.substring(index).trimLeft();
    }

    String header = '---\n';
    Map data = {};

    data['title'] = note.title;

    if (PrefService.getBool('notes_list_virtual_tags') ?? false) {
      note.tags.removeWhere((s) => s.startsWith('#/'));
    }

    if (!isDendronModeEnabled) {
      if (note.tags.isNotEmpty) data['tags'] = note.tags;
    }

    if (note.attachments.isNotEmpty) data['attachments'] = note.attachments;

    if (note.usesMillis ?? false) {
      data['created'] = note.created.millisecondsSinceEpoch;
      data[note.usesUpdatedInsteadOfModified ? 'updated' : 'modified'] =
          note.modified.millisecondsSinceEpoch;
    } else {
      data['created'] = note.created.toIso8601String();
      data[note.usesUpdatedInsteadOfModified ? 'updated' : 'modified'] =
          note.modified.toIso8601String();
    }

    if (note.pinned) data['pinned'] = true;
    if (note.favorited) data['favorited'] = true;
    if (note.deleted) data['deleted'] = true;

    if (note.additionalFrontMatterKeys != null) {
      data.addAll(note.additionalFrontMatterKeys.cast<String, dynamic>());
    }

    header += toYamlString(data);

    if (!header.endsWith('\n')) header += '\n';

    header += '---\n\n';

    // print(header);

    note.file.writeAsStringSync(header + content);
    /*  print(header + content); */
  }

  static Future<Note> readNote(File file) async {
    // print('PersistentStore.readNote');

    if (!file.existsSync()) return null;

    String fileContent = file.readAsStringSync();

    Map header;

    if (fileContent.trimLeft().startsWith('---')) {
      var doc = fm.parse(fileContent);
/* 
        String headerString = fileContent.split('---')[1]; */

      header = doc.data ?? {};
    } else {
      header = {};
    }

    /* for (String line in headerString.split('\n')) {
          if (line.trim().length == 0) continue;
          print(line);
          String key=line.split(':').first;
          header[key] = line.sub;
        } */
    //print(header);
    Note note = Note();

    note.file = file;

    note.title = header['title'].toString();

    if (note.title == null) {
      var title = file.path.split('/').last;
      if (title.endsWith('.md')) {
        title = title.substring(0, title.length - 3);
      }
      note.title = title;
    }

    if (header['modified'] != null && !isDendronModeEnabled) {
      if (header['modified'] is int) {
        note.usesMillis = true;
        note.modified = DateTime.fromMillisecondsSinceEpoch(header['modified']);
      } else {
        note.modified = DateTime.tryParse(header['modified']);
      }
    } else if (header['updated'] != null) {
      note.usesUpdatedInsteadOfModified = true;
      if (header['updated'] is int) {
        note.usesMillis = true;
        note.modified = DateTime.fromMillisecondsSinceEpoch(header['updated']);
      } else {
        note.modified = DateTime.tryParse(header['updated']);
      }
    } else {
      note.modified = file.lastModifiedSync();
    }

    if (header['created'] != null) {
      if (header['created'] is int) {
        note.usesMillis = true;
        note.created = DateTime.fromMillisecondsSinceEpoch(header['created']);
      } else {
        note.created = DateTime.tryParse(header['created']);
      }
    }
    if (note.created == null) {
      note.created = note.modified;
    }

    /* 
        note.tags =
            (header['tags'] as YamlList).map((s) => s.toString()).toList(); */
    note.tags = List.from((header['tags'] ?? []).cast<String>());
    note.attachments = List.from((header['attachments'] ?? []).cast<String>());

    note.pinned = header['pinned'] ?? false;
    note.favorited = header['favorited'] ?? false;
    note.deleted = header['deleted'] ?? false;

    if (header.isNotEmpty) {
      note.additionalFrontMatterKeys = Map<String, dynamic>.from(header);

      note.additionalFrontMatterKeys
          .removeWhere((key, value) => supportedFrontMatterKeys.contains(key));
    }

    return note;
  }

/*   static Future<Note> readNoteMetadata(File file) async {
    // print('PersistentStore.readNote');

    if (!file.existsSync()) return null;

    var raf = await file.open();

    List<int> bytes = [];

    bool equalBytes(List<int> l1, List<int> l2) {
      int i = -1;
      return l1.every((val) {
        i++;
        return l2[i] == val;
      });
    }

    while (true) {
      var byte = raf.readByteSync();
      if (byte == -1) break;

      bytes.add(byte);

      int length = bytes.length;

      if (length > 6 &&
          equalBytes(bytes.sublist(bytes.length - 4, bytes.length),
              <int>[10, 45, 45, 45] /* == "\n---" */)) break;
    }

    String fileContent = utf8.decode(bytes);

    var doc = fm.parse(fileContent);
/* 
        String headerString = fileContent.split('---')[1]; */

    var header = doc.data /* loadYaml(headerString) */;

    if (header == null) return null;

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
  } */

  static Future deleteNote(Note note) async {
    await note.file.delete();
  }
}
