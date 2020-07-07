/* import 'dart:core' hide writeDebugLine;
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:app/model/note.dart';
import 'package:app/store/notes.dart';
import 'package:app/store/persistent.dart';
import 'package:preferences/preferences.dart';
import 'package:webdav/webdav.dart';
import 'package:webdav/src/client.dart';
import 'package:intl/intl.dart';

class WebdavSync {
  Future<String> syncFiles(NotesStore store) async {
    debugOutput = '';
    var hostUri =
        Uri.parse('https://' + PrefService.getString('sync_webdav_host') ?? '');
    var hostPath = hostUri.path;
    if (hostPath.startsWith('/')) {
      hostPath = hostPath.substring(1);
    }
    if (hostPath.endsWith('/')) {
      hostPath = hostPath.substring(0, hostPath.length - 1);
    }
    Client client = Client(
        hostUri.host,
        PrefService.getString('sync_webdav_username') ?? '',
        PrefService.getString('sync_webdav_password') ?? '',
        hostPath,
        port: 443,
        protocol: 'https');

    try {
      var path = PrefService.getString('sync_webdav_path');
      client.mkdirs(path);
      await syncDirectory(client, '$path/notes/', 'notes');
      await syncDirectory(client, '$path/attachments/', 'attachments');
    } catch (e, st) {
      writeDebugLine(e);
      writeDebugLine(st);
      if (e is WebDavException) {
        return e.cause;
      } else {
        return e.toString();
      }
    }

    if (PrefService.getBool('debug_logs_sync') ?? false) {
      Note logNote = Note();
      logNote.title = '[DEBUG] Sync';

      logNote.created = DateTime.now();
      logNote.modified = logNote.created;

      logNote.tags.add('debug');

      logNote.file = File('${store.notesDir.path}/${logNote.title}.md');

      await PersistentStore.saveNote(
          logNote,
          '# ${logNote.title}\n\n${DateTime.now().toIso8601String()}\n\n' +
              debugOutput);
    }
    return null;
  }

  String debugOutput;

  writeDebugLine(var o) {
    if (PrefService.getBool('debug_logs_sync') ?? false) {
      debugOutput += o.toString() + '\n';
    }
  }

  Future syncDirectory(Client client, String path, String dir) async {
    await client.mkdir('$path');

    List<FileInfo> noteFiles = await client.ls('$path');

    writeDebugLine('SYNC $path');
    writeDebugLine('${noteFiles.length} files');

    final directory = Directory(PrefService.getString('notable_directory'));

    final fileDir = Directory('${directory.path}/$dir');

    final timestampFile = File('${directory.path}/.$dir.sync');
    if (!timestampFile.existsSync()) {
      timestampFile.createSync();
      timestampFile.writeAsStringSync('{}');
    }

    Map localSyncTimestamps = json.decode(timestampFile.readAsStringSync());
    writeDebugLine('localSyncTimestamps: $localSyncTimestamps');

    List syncedNotes = [];

    for (FileInfo info in noteFiles) {
      if (info.isDict) {
        continue;
      }

      writeDebugLine('----');

      writeDebugLine(info.name);
      writeDebugLine(info.contentType);
      writeDebugLine(info.ctime);
      writeDebugLine(info.mtime);

      String name = Uri.decodeFull(info.name).split('/').last;
      writeDebugLine(name);
      if (name.trim().isEmpty) continue;

      syncedNotes.add(name);

      DateFormat format = new DateFormat("EEE, dd MMM yyyy hh:mm:ss zzz");

      String localFilePath = '${fileDir.path}/${name}';
      File localFile = File(localFilePath);
      DateTime lastModifiedServer = format.parse(info.mtime, true);

      writeDebugLine('LMS $lastModifiedServer');

      if (!localFile.existsSync()) {
        writeDebugLine('File does not exist locally -> DOWNLOAD');
        // DOWNLOAD
        client.download('$path${name}', localFilePath);
        localSyncTimestamps[name] = lastModifiedServer.toIso8601String();
      } else {
        DateTime lastModifiedClientSync =
            DateTime.tryParse(localSyncTimestamps[name] ?? '');

        if (lastModifiedClientSync == null)
          lastModifiedClientSync = DateTime.fromMillisecondsSinceEpoch(0);
        DateTime lastModifiedClientFile = localFile.lastModifiedSync().toUtc();

        DateTime lastModifiedClient;

        if (lastModifiedClientSync.isAfter(lastModifiedClientFile)) {
          lastModifiedClient = lastModifiedClientSync;
        } else {
          lastModifiedClient = lastModifiedClientFile;
        }

        writeDebugLine('lastModifiedServer');
        writeDebugLine(lastModifiedServer);
        writeDebugLine('lastModifiedClient');
        writeDebugLine(lastModifiedClient);

        writeDebugLine(lastModifiedClient.difference(lastModifiedServer));
        if (lastModifiedServer.difference(lastModifiedClient).abs().inSeconds <
            3) {
          writeDebugLine('FILE MATCH!');
        } else if (lastModifiedServer.isBefore(lastModifiedClient)) {
          // UPLOAD
          writeDebugLine('UPLOAD');
          client.uploadFile(localFilePath, '$path${name}');

          localSyncTimestamps[name] = DateTime.now().toIso8601String();
        } else if (lastModifiedServer.isAfter(lastModifiedClient)) {
          // DOWNLOAD
          writeDebugLine('DOWNLOAD');
          client.download('$path${name}', localFilePath);
          localSyncTimestamps[name] = lastModifiedServer.toIso8601String();
        }

        // _upload();
      }
    }
    writeDebugLine(syncedNotes);

    for (var entity in fileDir.listSync()) {
      if (entity is! File) continue;
      String name = entity.uri.pathSegments.last;
      writeDebugLine(entity);
      if (!syncedNotes.contains(name)) {
        writeDebugLine('DOESNT EXIST ON SERVER $entity -> UPLOAD');
        client.uploadFile(entity.path, '$path${name}');
        localSyncTimestamps[name] = DateTime.now().toIso8601String();
      }
    }

    timestampFile.writeAsStringSync(json.encode(localSyncTimestamps));
  }
}
 */