import 'dart:io';

import 'package:notable/model/note.dart';
import 'package:notable/store/persistent.dart';
import 'package:notable/sync/webdav.dart';
import 'package:path_provider/path_provider.dart';
import 'package:preferences/preference_service.dart';
import 'package:notable/data/samples.dart';
import 'package:flutter/services.dart' show rootBundle;

class NotesStore {
  Directory notesDir, attachmentsDir;

  String searchText;

  String syncMethod;

  get syncMethodName {
    switch (syncMethod) {
      case 'webdav':
        return 'WebDav';
      default:
        return 'No';
    }
  }

  void init() {
    syncMethod = PrefService.getString('sync') ?? '';
  }

  Future createTutorialNotes() async {
    for (String fileName in Samples.tutorialNotes) {
      File('${notesDir.path}/$fileName').writeAsStringSync(
          await rootBundle.loadString('assets/tutorial/notes/$fileName'));
    }
  }

  Future createTutorialAttachments() async {
    for (String fileName in Samples.tutorialAttachments) {
      File('${attachmentsDir.path}/$fileName').writeAsBytesSync(
          (await rootBundle.load('assets/tutorial/attachments/$fileName'))
              .buffer
              .asUint8List());
    }
  }

  Directory applicationDocumentsDirectory;
  Future listNotes() async {
    applicationDocumentsDirectory = await getApplicationDocumentsDirectory();
    Directory directory;

    if (PrefService.getBool('notable_external_directory_enabled') ?? false) {
      directory =
          Directory(PrefService.getString('notable_external_directory'));
    } else {
      directory = applicationDocumentsDirectory;
    }
    PrefService.setString('notable_directory', directory.path);

    notesDir = Directory('${directory.path}/notes');

    PrefService.setString('notable_notes_directory', notesDir.path);

    if (!notesDir.existsSync()) {
      notesDir.createSync();
      await createTutorialNotes();
    }
    attachmentsDir = Directory('${directory.path}/attachments');
    PrefService.setString('notable_attachments_directory', attachmentsDir.path);

    if (!attachmentsDir.existsSync()) {
      attachmentsDir.createSync();
      await createTutorialAttachments();
    }

    /* for (String fileName in Samples.tutorialNotes) {
      File('${notesDir.path}/$fileName').writeAsStringSync(
          await rootBundle.loadString('assets/tutorial/notes/$fileName'));
    } */

    allNotes = [];

    await _listNotesInFolder('');

    // _updateTagList();
  }

  Future _listNotesInFolder(String dir, [bool isSubDirectory = false]) async {
    await for (var entity in Directory('${notesDir.path}$dir').list()) {
      if (entity is File) {
        Note note = await PersistentStore.readNote(entity);

        if (note != null) {
          if (PrefService.getBool('notes_list_virtual_tags') ?? false) {
            if (isSubDirectory) note.tags.add('#$dir');
          }

          allNotes.add(note);
        }
      } else if (entity is Directory) {
        await _listNotesInFolder(dir + '/' + entity.path.split('/').last, true);
      }
    }
  }

  updateTagList() {
    for (Note note in allNotes) {
      for (String tag in note.tags) {
        allTags.add(tag);
      }
    }

    for (String tag in allTags) {
      rootTags.add(tag.split('/').first);
    }
  }

  Set<String> getSubTags(String forTag) {
    Set<String> subTags =
        allTags.where((tag) => tag.startsWith(forTag) && tag != forTag).toSet();

    subTags = subTags.map((String t) => t.replaceFirst('$forTag/', '')).toSet();

    subTags = subTags.map((String t) => t.split('/').first).toSet();

    return subTags;
  }

  filterAndSortNotes() {
    //shownNotes = List.from(allNotes);

    shownNotes = _filterByTag(allNotes, currentTag);

    if (searchText != null) {
      List keywords =
          searchText.split(' ').map((s) => s.toLowerCase()).toList();

      if (PrefService.getBool('search_content') ?? true) {
        List<String> toRemove = [];

        for (Note note in shownNotes) {
          String content = note.file.readAsStringSync().toLowerCase();

          bool _contains = true;
          for (String keyword in keywords) {
            if (!content.contains(keyword)) {
              _contains = false;
              break;
            }
          }
          if (!_contains) {
            toRemove.add(note.title);
          }
        }
        shownNotes.removeWhere((n) => toRemove.contains(n.title));
      } else {
        shownNotes.retainWhere((note) {
          String noteTitle = note.title.toLowerCase();
          for (String keyword in keywords) {
            if (!noteTitle.contains(keyword)) return false;
          }
          return true;
        });
      }
    }

    shownNotes.sort((a, b) {
      if (a.pinned ^ b.pinned) {
        return a.pinned ? -1 : 1;
      } else {
        int value = 0;

        switch (PrefService.getString('sort_key') ?? 'title') {
          case 'title':
            value = a.title.compareTo(b.title);
            break;
          case 'date_created':
            value = a.created.compareTo(b.created);
            break;
          case 'date_modified':
            value = a.modified.compareTo(b.modified);
            break;
        }
        if (!(PrefService.getBool('sort_direction_asc') ?? true)) value *= -1;

        return value;
      }
    });
  }

  List<Note> _filterByTag(List<Note> notes, String cTag) {
    return notes.where((note) => note.hasTag(cTag)).toList();
  }

  int countNotesWithTag(List<Note> notes, String tag) {
    int count = 0;
    notes.forEach((note) {
      if (note.hasTag(tag)) count++;
    });
    return count;
  }

  List<Note> allNotes;

  List<Note> shownNotes;

  String currTag = '';

  set currentTag(String newTag) {
    currTag = newTag;
    PrefService.setString('current_tag', newTag);
  }

  String get currentTag => currTag;

  Set<String> allTags = {};

  Set<String> rootTags = {};

  Future<String> syncNow() async {
    switch (syncMethod) {
      case 'webdav':
        return await WebdavSync().syncFiles(this);
    }
    return null;
  }

  Note getNote(String title) {
    return allNotes.firstWhere((n) => n.title == title);
  }
}
