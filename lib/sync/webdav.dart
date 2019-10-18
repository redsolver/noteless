import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:preferences/preferences.dart';
import 'package:webdav/webdav.dart';
import 'package:webdav/src/client.dart';
import 'package:intl/intl.dart';

class WebdavSync {
  Future<String> syncFiles() async {
    Client client = Client(
        PrefService.getString('sync_webdav_host') ?? '',
        PrefService.getString('sync_webdav_username') ?? '',
        PrefService.getString('sync_webdav_password') ?? '',
        PrefService.getString('sync_webdav_path') ?? '',
        port: 443,
        protocol: 'https');
    try {
      await client.mkdir('/notable/');
      await syncDirectory(client, '/notable/notes/', 'notes');
      await syncDirectory(client, '/notable/attachments/', 'attachments');
    } catch (e, st) {
      print(e);
      print(st);
      if (e is WebDavException) {
        return e.cause;
      } else {
        return e.toString();
      }
    }
    return null;
  }

  Future syncDirectory(Client client, String path, String dir) async {
    await client.mkdir('$path');

    List<FileInfo> noteFiles = await client.ls('$path');

    print('SYNCSYNCSYNC $path');
    print(noteFiles);

    final directory = await getApplicationDocumentsDirectory();

    final fileDir = Directory('${directory.path}/$dir');

    final timestampFile = File('${directory.path}/.$dir.sync');
    if (!timestampFile.existsSync()) {
      timestampFile.createSync();
      timestampFile.writeAsStringSync('{}');
    }

    Map localSyncTimestamps = json.decode(timestampFile.readAsStringSync());
    print(localSyncTimestamps);

    List syncedNotes = [];

    for (FileInfo info in noteFiles) {
      print('----');

      print(info.name);
      print(info.contentType);
      print(info.creationTime);
      print(info.modificationTime);

      String name = Uri.decodeFull(info.name).split('/').last;
      print(name);
      if (name.trim().isEmpty) continue;

      syncedNotes.add(name);

      DateFormat format = new DateFormat("EEE, dd MMM yyyy hh:mm:ss zzz");

      String localFilePath = '${fileDir.path}/${name}';
      File localFile = File(localFilePath);
      DateTime lastModifiedServer = format.parse(info.modificationTime, true);

      print('LMS $lastModifiedServer');

      if (!localFile.existsSync()) {
        print('File doesnt exist local');
        // DOWNLOAD
        print('DOWNLOAD');
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

        print('lastModifiedServer');
        print(lastModifiedServer);
        print('lastModifiedClient');
        print(lastModifiedClient);

        print(lastModifiedClient.difference(lastModifiedServer));
        if (lastModifiedServer.difference(lastModifiedClient).abs().inSeconds <
            3) {
          print('FILE MATCH!');
        } else if (lastModifiedServer.isBefore(lastModifiedClient)) {
          // UPLOAD
          print('UPLOAD');
          client.uploadFile(localFilePath, '$path${name}');

          localSyncTimestamps[name] = DateTime.now().toIso8601String();
        } else if (lastModifiedServer.isAfter(lastModifiedClient)) {
          // DOWNLOAD
          print('DOWNLOAD');
          client.download('$path${name}', localFilePath);
          localSyncTimestamps[name] = lastModifiedServer.toIso8601String();
        }

        // _upload();
      }
    }
    print(syncedNotes);

    for (var entity in fileDir.listSync()) {
      if (entity is! File) continue;
      String name = entity.uri.pathSegments.last;
      print(entity);
      if (!syncedNotes.contains(name)) {
        print('DOESNT EXIST ON SERVER $entity');
        print('UPLOAD');
        client.uploadFile(entity.path, '$path${name}');
        localSyncTimestamps[name] = DateTime.now().toIso8601String();
      }
    }

    timestampFile.writeAsStringSync(json.encode(localSyncTimestamps));
  }
}
