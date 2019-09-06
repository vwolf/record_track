import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'l10n/messages_all.dart';

import 'select/selectView.dart';

/// Example uses locale.countryĆode, which is not working as countyCode is null
/// 
class DemoLocalizations {
  static Future<DemoLocalizations> load(Locale locale) {
    String localeName = Intl.canonicalizedLocale("en");

    if (locale.languageCode == null) {
      debugPrint("languageCode is null");
    } else {
      debugPrint("languageCode is not null");
      final String name = locale.languageCode.isEmpty ? locale.languageCode : locale.toString();
      localeName = Intl.canonicalizedLocale(name);
    }

    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      return DemoLocalizations();
    });
  }

  static DemoLocalizations of(BuildContext context) {
    return Localizations.of<DemoLocalizations>(context, DemoLocalizations);
  }

  String get title {
    return Intl.message(
      'Record Track',
      name: 'title',
      desc: 'App title',
    );
  }

  String get hello {
    return Intl.message(
      "Hallo",
      name: 'hello',
      desc: 'Greeting'
    );
  }
}

class DemoLocalizationsDelegate extends LocalizationsDelegate<DemoLocalizations> {
  const DemoLocalizationsDelegate();

  @override 
  bool isSupported(Locale locale) => ['en', 'de'].contains(locale.languageCode);

  @override 
  Future<DemoLocalizations> load(Locale locale) => DemoLocalizations.load(locale);

  @override 
  bool shouldReload(DemoLocalizationsDelegate old) => false;
}




class MyApp extends StatelessWidget {
  // final String localeName = Intl.canonicalizedLocale("de");
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (BuildContext context) => DemoLocalizations.of(context).title,
      localizationsDelegates: [
        const DemoLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('en'),
        const Locale('de'),
      ],

      title: 'Record Track',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Record Track Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(DemoLocalizations.of(context).title),
      ),
      body: Center(
        child: SelectPage(),
      ),
    //  body: SelectPage(),
    );
  }
}

void main() => runApp(MyApp());
