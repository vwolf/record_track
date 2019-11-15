import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:record_track/db/database.dart';
import 'package:xml/xml.dart' as xml;
import 'package:record_track/db/models/trackCoord.dart';
import 'package:record_track/db/models/track.dart';
import 'package:record_track/services/settings.dart';
import 'package:record_track/readWrite/writeFile.dart';

/// Save a track as gpx file.
/// Save track only or track with items?
///
/// - @param [track]
class GpxCreator extends StatefulWidget {

  final Track track;

  GpxCreator(this.track);

  GpxCreatorState createState() => GpxCreatorState();

}


class GpxCreatorState extends State<GpxCreator> {

  final _formkey = GlobalKey<FormState>();

  final _trackNameController = TextEditingController();

  String fileName;
  String filePath;
  String fileExistsMsg;


  @override
  void initState() {
    super.initState();

    _trackNameController.text = widget.track.name;
    // default file name and path
    fileName = "${widget.track.name}.gpx";
    filePath = "${Settings.settings.externalPaths[0]}/$fileName";

    doesFileExists(filePath);
  }

  /// File exists check and set [fileExistsMsg]
  ///
  doesFileExists(String filePath) async {
    var fileExists = await File(filePath).exists();
    if (fileExists == true) {
      print("fileExists");
      fileExistsMsg = "A file with this name exists already! You can change the file name!";

    } else {
      fileExistsMsg = null;
    }

    setState(() {

    });
  }


  /// Save track data to sd card
  /// - set file name and path
  /// - parse track into xml
  /// Which path?
  /// Test
  /// - save to external storage : ok
  /// - create folder in external storage : ok
  /// - create folder in external storage and save to : ok
  /// - save to folder in external storage which does not exists jet : false
  /// - save to sd card root
  /// - create folder at sd card root : ok
  /// - save to folder at sd card root : fails
  /// - save to folder at sd card root which does not exists jet : fails
  ///
  /// Save tracks to external storage, first entry in list
  /// Check if file with [fileName] exists, add unique id to name (fileName001)
  ///
  saveTrack() async {



    // external storage path
    // emulated - ok
    //if (Settings.settings.externalPaths.length > 0) {
      //fileName  = "P1" + fileName;
      //filePath = "${Settings.settings.externalPaths[0]}/$fileName";
    //}



    // sd card - ok
//    if (Settings.settings.externalPaths.length > 1) {
//      fileName = "P2" + fileName;
//      filePath = "${Settings.settings.externalPaths[1]}/$fileName";
//    }

    // create folder - ok
//    if (Settings.settings.externalPaths.length > 0) {
//      var folderName = "Test";
//      await makeFolder(Settings.settings.externalPaths[0], folderName).then((result) {
//        print("makeFolder result: $result");
//      });
//    }

//    if (Settings.settings.externalPaths.length > 1) {
//      var folderName = "Test";
//      await makeFolder(Settings.settings.externalPaths[1], folderName).then((result) {
//        print("makeFolder result: $result");
//      });
//    }

    // save to folder in external storage - ok
//    if (Settings.settings.externalPaths.length > 0) {
//      fileName  = "P1" + fileName;
//      filePath = "${Settings.settings.externalPaths[0]}/Test/$fileName";
//    }

//    if (Settings.settings.externalPaths.length > 1) {
//      fileName  = "P2" + fileName;
//      filePath = "${Settings.settings.externalPaths[1]}/Test/$fileName";
//    }

    // save to folder which does not exists - false
//    if (Settings.settings.externalPaths.length > 1) {
//      fileName = "P2" + fileName;
//      filePath = "${Settings.settings.externalPaths[1]}/test/$fileName";
//    }

    // Save to sd card root
    //filePath = Settings.settings.externalSDCard;
//    var folderName = "Test";
//    await makeFolder(Settings.settings.externalSDCard, folderName).then((result) {
//        print("makeFolder result: $result");
//    });

    // make folder emulated - fails
//    filePath = "storage/emulated/0";
//    var folderName = "Test";
//    await makeFolder(filePath, folderName).then((result) {
//      print("makeFolder result: $result");
//    });

    // /sdcard/Tracks/no-sf-s12-01kloten-gillersklack.gpx
    // storage/C4AB-1401/Tracks/d_66_seen_weg_001.gpx

    // save to folder created by app
//    fileName = "SD$fileName";
//    filePath = "${Settings.settings.externalSDCard}/Test/$fileName";
    //filePath = "storage/emulated/0/Tracks/$fileName";


    /// Save track as *.gpx file, use track and trackCoord table
    //List<TrackCoord> trackCoords = await DBProvider.db.getTrackCoords(widget.track.track);
    var fileContent = "c";
    WriteFileExternal writeFileExternal = WriteFileExternal(filePath, fileContent);

    await writeFileExternal.requestPermission().then((r) {
      print("r: $r");
      if (r == true) {
        DBProvider.db.getTrackCoords(widget.track.track).then((trackCoords){
          fileContent = buildGpx(widget.track, trackCoords);
          writeFileExternal.writeToFile(filePath, fileContent).then((result) {
            if (result == true) {
              print( "File saved!");
              Navigator.pop(context);
            } else {
              print( "Error File saved");
            }
          });
        });
      }
    });

  }


  Future makeFolder(String path, String folderName) async {

    String folderPath = "$path/$folderName";
    Directory dir = Directory(folderPath);
    if (await dir.exists() == false ) {
      dir.createSync(recursive: true);
      print("Directory created at $folderPath");
      return true;
    } else {
      print("Directory exists at $folderPath");
      return true;
    }
  }

  /// Build form and info
  ///
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Save Track"),
      ),
      body: ListView(
        children: <Widget>[
          _info,
          _form,
        ],
      )
    );
  }

  Widget get _info {
    return Container(
      margin: EdgeInsets.only(left: 20.0, top: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: EdgeInsets.only(top: 4.0),
            child: Divider(
              color: Colors.white,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Expanded(
                //child: Text(widget.track.name),
                child: TextFormField(
                  controller: _trackNameController,
                  maxLines: 1,
                  onFieldSubmitted: (term) {
                    _trackNameFocusChange();
                  },
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    if (value.isEmpty) {
                      return "Please enter a name";
                    }
                    return null;
                  },
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.edit,
                  size: 24.0,
                ),
                onPressed: () {},
              )
            ],
          ),



          Padding(
            padding: EdgeInsets.only(top: 24.0),
              child: Divider(
                color: Colors.white,
              ),
          ),

          Text( fileExistsMsg != null ? fileExistsMsg  : "OK"),

          Padding(
            padding: EdgeInsets.only(top: 24.0),
            child: Divider(
              color: Colors.white,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text("Save to SD card:\n ${Settings.settings.externalPaths[0]}/${_trackNameController.text}.gpx"),
              ),

              IconButton(
                icon: Icon(
                  Icons.create_new_folder,
                  size: 32.0,
                ),
                onPressed: () {

                },
              ),
            ],
          ),

          Padding(
            padding: EdgeInsets.only(top: 24.0),
            child: Divider(
              color: Colors.white,
            ),
          ),
        ],
      )


    );
  }


  Widget get _nameTextField {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: <Widget>[
        TextFormField(
          controller: _trackNameController,
          decoration: InputDecoration(labelText: "Name"),
          maxLines: 1,
          validator: (value) {
            if (value.isEmpty) {
              return "Please enter a name";
            }
            return null;
          },
        )
      ],

    );
  }


  Widget get _form {
    return Form(
      key: _formkey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                RaisedButton(
                  child: Text('SAVE'),
                  onPressed: saveTrack,
                ),
                RaisedButton(
                  child: Text("CANCEL"),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }


  _trackNameFocusChange() {
    print("_trackNameFocusChange");
    fileName = "${_trackNameController.text}.gpx";
    filePath = "${Settings.settings.externalPaths[0]}/$fileName";
    doesFileExists(filePath);
  }


  /// Build the gpx file as xml.
  String buildGpx(Track track, List<TrackCoord> trackCoords) {
    var builder = xml.XmlBuilder();

    builder.processing('xml', 'version="1.0" encoding="utf-8"');

    builder.element('gpx', nest: () {
      // schema ...
      builder.attribute('xmlns', 'http://www.topografix.com/GPX/1/1');
      builder.attribute('xmlns:xsd', 'http://www.w3.org/2001/XMLSchema');

      // metadata
      builder.element('metadata', nest: () {
        builder.element('name', nest: () {
          builder.text(track.name);
        });
        builder.element('copyright', nest: () {
          builder.attribute('author', "OpenStreetMap and Contributors");
          builder.element('license', nest: () {
            builder.text("OpenStreetMap and Contributors");
          });
        });

      });

      // trk
      builder.element('trk', nest: () {
        builder.element('name', nest: () {
          builder.text(track.name);
        });
        builder.element('desc', nest: () {
          builder.text(track.description);
        });

        // trkseg
        builder.element('trkseg', nest: () {
          for ( TrackCoord coord in trackCoords) {
            builder.element('trkpt', nest: () {
              builder.attribute('lat', coord.latitude);
              builder.attribute('lon', coord.longitude);
              builder.element('ele', nest: () {
                builder.text(coord.altitude == null ? 0.0 : coord.altitude);
              });
            });
          }
        });
      });
    });





    var gpx = builder.build().toXmlString(pretty: true, indent: '\t');
    return gpx;
  }
}


