import 'dart:io';

class Note {
  String title;
  DateTime created;
  DateTime modified;
  List<String> tags = [];
  List<String> attachments = [];
  bool pinned = false;
  bool favorited = false;
  bool deleted = false;
  File file;

  bool usesMillis = false;
  bool usesUpdatedInsteadOfModified = false;
  Map<String, dynamic> additionalFrontMatterKeys;

  bool hasTag(String cTag) {
    if (cTag != '') {
      if (cTag == 'Trash') {
        return deleted;
      } else if (cTag == 'Favorites') {
        return favorited;
      } else if (cTag == 'Untagged') {
        return tags.isEmpty;
      } else {
        bool hasTag = false;
        for (String tag in tags) {
          if (tag.startsWith(cTag)) {
            hasTag = true;
            break;
          }
        }
        if (!hasTag) return false;
      }
    } else {}
    if (deleted) return false;
    //if (note.deleted) return false;
    return true;
  }
}
