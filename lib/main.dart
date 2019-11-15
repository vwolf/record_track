import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'l10n/messages_all.dart';

import 'select/selectView.dart';

import 'services/status.dart';
import 'services/settings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_ex/path_provider_ex.dart';
import 'package:flutter/services.dart';
import 'services/permissionService.dart';
import 'db/models/track.dart';
import 'track/trackListService.dart';
import 'db/database.dart';

import 'package:record_track/services/directoryList.dart';

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

  /// callback function
  MapPathCallback setMapPath;

  String _gpxFileDirectoryString = "?";
  List<Track> _tracks = [];
  Map<String, dynamic> trackSettings = {};
  bool tracksRead = false;

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(DemoLocalizations.of(context).title),
      ),
      endDrawer: Drawer(
        child: ListView(
          children: <Widget>[
            const DrawerHeader(
              child: const Center(
                child: const Text("Settings"),
              ),
            ),
            ListTile(
              title: Text("Track Directory SD Card" ),
              subtitle: Settings.settings.pathTracksExternal != null ? Text(Settings.settings.pathTracksExternal) : Text("Not directory selected"),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  openFileIO();
                  //Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              title: Text("Offline Map Directory"),
              subtitle: Text(Settings.settings.pathToMapTiles),
              trailing: IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            ListTile(
              contentPadding: EdgeInsets.only(right: 44.0, top: 12.0),
              trailing: IconButton(
                icon: Icon(Icons.keyboard_return,
                size: 52.0,
                ),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            )
          ],
        ),
      ),
      body: Center(
        child: SelectPage(_tracks, tracksRead),
      ),
    //  body: SelectPage(),
    );
  }

  /// Read tracks from database and from storage
  /// This should not be here, transfer this functionality 
  /// to showTrackList in [SelectPage]?
  /// 
  void initState() {
    super.initState();

    setMapPath = setTracksFilePath;

    loadTracks();
  }

  /// Use [Path_Provider] to get path to external storage directory.
  /// Default directory is Tracks. This can be changed using settings.
  /// First search default external storage then custom folder on SDCard.
  ///
  void loadTracks() async {

    var permission = await RequestPermissions().requestPermission(PermissionGroup.storage);
    if (permission) {
      await setStoragePath().then((result) {
        if (result) {
          // no directory at internal storage path then create empty directory
            _gpxFileDirectoryString = Settings.settings.pathTracksInternal;
            if (Directory(_gpxFileDirectoryString).existsSync() == false) {
              Directory(_gpxFileDirectoryString).create(recursive: true);
            }
            getTracksFromDb();
            for (String p in Settings.settings.externalPaths) {
              findTracks(p);
            }
            //findTracks(_gpxFileDirectoryString);
        }
      }).then((_) {
        // tracks on sd card?
        // first check default location then pathTrackExternal in Settings
        print("SDCard path: ${Settings.settings.externalSDCard}");
        print("Settings.pathTrackExternal: ${Settings.settings.pathTracksExternal}");
        if (Settings.settings.externalSDCard != null) {
          // build default path
          String trackDirectory = "${Settings.settings.externalSDCard}/${Settings.settings.defaultTrackDirectory}";
          print("SDCard default path: $trackDirectory");
          Settings.settings.pathTracksExternal = trackDirectory;
          searchSDCard().then((r) {
            if (r == true) {
              print("SEARCH SDCARD!!");
              findTracks(trackDirectory);
//              if (Settings.settings.pathTracksExternal != null) {
//                findTracks(Settings.settings.pathTracksExternal);
//              }
            } else {
              // r == null: click outside of dialog, r == false: cancel button in dialog
              print("Search SD card canceled");
            }
          });
        }
      });

    }
  }

  /// Set path to external Storage (emulated and SDCard?).
  /// Paths:
  /// - storage/emulated/0
  /// - storage/C4AB.1401/Android/data/com.../files (is the sd card name?)
  /// - storage/C4AB-1401/ root of external storage (/Tracks)
  /// Add to [Settings]
  /// Uses [path_provider_ex] to get root of SD card path
  ///
  /// ToDo: Path from [getExternalStorageDirectory] does not work? Path hard coded!
  Future<bool> setStoragePath() async {
    List<StorageInfo> storageInfo;

    // storage Android
    if (Platform.isAndroid) {
      // storage external default
      List<Directory> dirs = await getExternalStorageDirectories();

//      var dir = await getExternalStorageDirectory();
//      var cacheDirs = await getExternalCacheDirectories();
//      var appdir = await getApplicationDocumentsDirectory();
//      var supportDir = await getApplicationSupportDirectory();
//       /sdcard/Tracks/no-sf-s12-01kloten-gillersklack.gpx
//       /storage/C4AB-1401/Android/data/com.devwolf.record_track/files/test.gpx

      //Settings.settings.pathTracksInternal = "/storage/C4AB-1401/Android/data/com.devwolf.record_track/files";
      Settings.settings.pathTracksInternal = "${dirs[0].path}";
      for (Directory d in dirs) {
        //Settings.settings.set({"externalPath": d.path});
        Settings.settings.externalPaths.add(d.path);
      }
      print("Settings externalPath.length: ${Settings.settings.externalPaths.length}");


      // storage sd card (external)
      try {
        storageInfo = await PathProviderEx.getStorageInfo();

      } on PlatformException {}

      if (mounted) {
        if (storageInfo.length >= 1) {
          Settings.settings.externalSDCard = storageInfo[1].rootDir;
        }
      }
      return true;
    }
    return false;
  }

  /// Read settings from local file into [trackSettings].
  ///
  // void readSettings() async {
  //   print("Read track settings from local file");
  //   trackSettings = await LocalFile().readJson("tracksSettings.txt");
  //   print("trackSettings: $trackSettings");
  //   Settings.settings.set(trackSettings);
  // }

  void getTracksFromDb() {
    DBProvider.db.getAllTracks().then((tracks) {
      _tracks.addAll(tracks);
    });
    
  }

  /// Add all gpx files in [directoryPath] to [trackPath].
  /// Then call [loadTrackMetaData] to read gpx files.
  ///
  /// - @param [directoryPath]
  /// - @param bool [customDir] true: search directories in [directoryPath]
  void findTracks(String directoryPath, {customDirs: true}) {
    print("findTracks for path: $directoryPath");
    List<String> trackPath = [];
    Directory(directoryPath).list(recursive: customDirs, followLinks: false)
        .listen((FileSystemEntity entity) {
          print("path: ${entity.path}");
          if (path.extension(entity.path) == ".gpx") {
            if (trackPath.contains(entity.path) == false) {
              if (_tracks.indexWhere((t) => t.gpxFilePath == entity.path) == -1 ) {
                trackPath.add(entity.path);
              }
            }
          }
        })
        .onDone( () => {
          //trackPath.length == 0 ? searchSDCard() : this.loadTrackMetaData(trackPath)
          this.loadTrackMetaData(trackPath)
    });
  }

  /// Load meta data from tracks in [_gpxFileDirectory] into [Track]
  ///
  /// [filePaths] list of gpx files in track directory
  /// Filter track files from waypoint files
  void loadTrackMetaData(List<String> filePaths) async {

    for (var path in filePaths) {
      print ("loadTrackMetaData from $path");
      Track oneTrack = await TrackListService().getTrackMetaData(path);
      if (oneTrack.name != "") {
        _tracks.add(oneTrack);
        // any settings for track?
        if (trackSettings.containsKey(oneTrack.name)) {
          oneTrack.offlineMapPath = trackSettings[oneTrack.name];
        }
      }

     // _tracks.add(oneTrack);
    }
    setState(() {
      tracksRead = true;
    });
  }

  /// Show [SimpleDialogOption] to search on SD card
  /// Return [Future] [bool]
  Future searchSDCard() async {
    print("searchSDCard");
    switch(
      await showDialog(
          context: context,
          builder: (BuildContext context) {
            return SimpleDialog(
              title: Text('Search on SD Card?'),
              children: <Widget>[
                SimpleDialogOption(
                  child: Text("Yes"),
                  onPressed: () {
                    Navigator.pop(context, "Yes");
                  } ),
                SimpleDialogOption(
                  child: Text("No"),
                  onPressed: () {
                    Navigator.pop(context, "No");
                  } ),
              ],
            );
          },
        )
    )  {
      case "Yes" :
        return true;
        break;

      case "No" :
        return false;
        break;
    }
  }

  openFileIO() {
    //Settings.settings.get({"externalSDCard": true});
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) {
        return DirectoryList(setMapPath, Settings.settings.externalSDCard);
      })
    );
  }


  /// Callback offline map directory selection
  /// There was already a basic check if valid directory
  ///
  void setTracksFilePath(String mapPath) {
    print("mapPath: $mapPath");
    setState(() {
      Settings.settings.pathToTracks = mapPath;
      Settings.settings.pathTracksExternal = mapPath;

      findTracks(Settings.settings.pathTracksExternal);
      //trackService.pathToOfflineMap = mapPath;
      //_offline = !_offline;
      //_mapStatusLayer.statusNotification("offline_on", _offline);

    });

    // add the path to offline map tiles to settings file
    //ReadFile().addToJson("tracksSettings.txt", trackService.track.name, mapPath);
    // update track
    //trackService.track.offlineMapPath = mapPath;
  }
}



//void main() => runApp(MyApp());
void main () {

  AppStatus.appStatus.checkConnection(); 

  //AppStatus.appStatus.setDirectorys();

  runApp(MyApp());
}
