import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_i18n/flutter_i18n_delegate.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:notable/sync/webdav.dart';
import 'package:preferences/preference_service.dart';

import 'package:notable/page/note_list.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

main() async {
  await PrefService.init(prefix: 'pref_');
  /* 
  await initializeDateFormatting("en_US", null); */
  Intl.defaultLocale = 'en_US';

  runApp(MaterialApp(
    title: 'Notable',
    theme: ThemeData(
        primaryColor: Color(0xfff5b746), accentColor: Color(0xfff5b746)),
    /*  theme: ThemeData.dark().copyWith(
          primaryColor: Color(0xfff5b746), accentColor: Color(0xfff5b746)), */
    home:
        /*  Banner(
      location: BannerLocation.bottomStart,
      message: 'WIP',
      color: Colors.blue,
      child: */
        NoteListPage(),
    /* ), */
    localizationsDelegates: [
      FlutterI18nDelegate(path: 'assets/i18n', fallbackFile: 'en'),
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate
    ],
    /* debugShowCheckedModeBanner: false, */
  ));
}
