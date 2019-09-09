import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import 'package:latlong/latlong.dart';
import 'package:flutter/rendering.dart';
import 'package:record_track/gpx/gpxFileData.dart';
import 'package:record_track/gpx/gpxParser.dart';

import '../services/geolocationService.dart';
import '../db/models/track.dart';
import '../db/database.dart';

import 'package:path/path.dart' as path;
import '../readWrite/readFile.dart';

/// Create new track or update track
/// Initilizer for new track and update track
/// 
class NewTrack extends StatefulWidget {

  Track track = Track();

  NewTrack();

  NewTrack.withTrack(Track track) {
    this.track = track;  
  }

  @override 
  _NewTrackState createState() => _NewTrackState();
}


class _NewTrackState extends State<NewTrack> {

  Track savedTrack;
  bool _newTrack = true;
  bool _formSaved = false;
  String _gpxFilePath;
  String _trackType = "walk";

  // form key and controller
  final _formkey = GlobalKey<FormState>();
  final _formNameController = TextEditingController();
  final _formDescriptionController = TextEditingController();
  final _formLocationController = TextEditingController();
  final _formStartLatitudeController = TextEditingController();
  final _formStartLongitudeController = TextEditingController();

  // Form style
  TextStyle _formTextStyle = TextStyle(color: Colors.white);
 
  InputDecoration _formInputDecoration = InputDecoration(
      labelText: 'Name', labelStyle: TextStyle(color: Colors.white70));


  @override 
  void initState() {
    super.initState();
  }


  setTrackType(String type) {
    setState(() {
      _trackType = type;
    });
  }

  /// Get current position,
  /// ToDo: GeoloctionService can fail - set default values
  getStartPosition() async {
    LatLng currentPosition = await GeoLocationService.gls.simpleLocation();
    _formStartLatitudeController.text = currentPosition.latitude.toString();
    _formStartLongitudeController.text = currentPosition.longitude.toString();

    /// startPosition to country, locality and administrativeArea
    String description = await GeoLocationService.gls.getCoordDescription(currentPosition);
    _formLocationController.text = description;
  }

  /// Save or update track data 
  /// Used as closure in SubmitBtnWithState
  /// 
  Future submitEvent(int i) async {
    if ( !_newTrack ) {

    }

    // save new track
    if (_formkey.currentState.validate()) {
      widget.track.name = _formNameController.text;
      widget.track.description = _formDescriptionController.text;
      widget.track.location = _formLocationController.text;
      widget.track.open = false;

      /// start coordinates
      LatLng startCoords = LatLng(
        _formStartLatitudeController.text.isNotEmpty
        ? double.parse(_formStartLatitudeController.text)
        : 0.0,
        _formStartLongitudeController.text.isNotEmpty
        ? double.parse(_formStartLongitudeController.text)
        : 0.0,
      );
      widget.track.coords = GeoLocationService.gls.latlngToJson(startCoords);

      /// options
      Map<String, dynamic> options = {"type" : _trackType};

       /// Gpx file path
      if (_gpxFilePath != null) {
        //widget.tour.options = jsonEncode({"gpxFilePath": _gpxFilePath});
        options["gpxFilePath"] =  _gpxFilePath;
      }

      widget.track.options = jsonEncode(options);

      /// Add timestamp to track (created or modified)
      widget.track.timestamp = DateTime.now();

      /// Write to db, returns int
      var dbResult = await DBProvider.db.newTrack(widget.track);
      print(dbResult);
      _formSaved = true;
    }
  }

  Future getTrack() async {
    final filePath = await ReadFile().getPath();
    String fileType = path.extension(filePath);
    if (filePath != '.gpx') {
      debugPrint("Wrong file type");
      bottomSheet(fileType);
      return null;
    }

    // fileType ok
    _gpxFilePath = filePath;
    final fileContent = await ReadFile().readFile(filePath);
    GpxFileData trackGpxData = await GpxParser(fileContent).parseData();

    // fill form
    _formNameController.text = trackGpxData.trackName;
    _formDescriptionController.text = trackGpxData.trackSeqName;
    _formLocationController.text = trackGpxData.trackSeqName;

    // translate first point to an address
    GpxCoord firstPoint = trackGpxData.gpxCoords.first;

    List<Placemark> placemark = await Geolocator().placemarkFromCoordinates(firstPoint.lat, firstPoint.lon, localeIdentifier: "de_DE");
    if (placemark.isNotEmpty && placemark != null) {
      String loc = placemark[0].country + ", " + placemark[0].locality;
      _formLocationController.text = loc;
    }

    // use first point as startCoords
    _formStartLatitudeController.text = firstPoint.lat.toString();
    _formStartLongitudeController.text = firstPoint.lon.toString();

  }


  bottomSheet(String fileType) {
    showBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.error, color: Colors.redAccent),
              title: Text("Can\'t read file of type $fileType. Choose a *.gpx file"),
            )
          ],
        );
      }
    );
  }

  Future getImage() async {}

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _newTrack ? Text("New Track") : Text("Update Track"),
      ),
      body: ListView(
        children: <Widget>[
          _form,
        ],
      ),
    );
  }

  /// Form fields
  Widget get _form {
    return Form(
      key: _formkey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextFormField(
              style: _formTextStyle,
              controller: _formNameController,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              cursorColor: Colors.white,
              decoration: _formInputDecoration,
              validator: (value) {
                if (value.isEmpty) {
                  return "Please enter a name!";
                }
                return null;
              },
              maxLines: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextFormField(
              style: _formTextStyle,
              controller: _formDescriptionController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: "Description",
                labelStyle: TextStyle(color: Colors.white70),
              ),
              validator: (value) {
                if (value.isEmpty) {
                  return "Please enter a description";
                }
                return null;
              },
              maxLines: null,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                FlatButton.icon(
                  onPressed: () => setTrackType('walk'),
                  icon: Icon(Icons.directions_walk,
                  color: !(_trackType == "walk") ? Colors.white30 : Colors.white),
                  label: Text(""),
                ),
                FlatButton.icon(
                  onPressed: () => setTrackType('bike'),
                  icon: Icon(Icons.directions_bike,
                  color: !(_trackType == "bike") ? Colors.white30 : Colors.white),
                  label: Text("")
                ),
              ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextFormField(
                controller: _formLocationController,
                style: _formTextStyle,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Location name',
                  labelStyle: TextStyle(color: Colors.white70),
                ),
                validator: (value) {
                  if (value.isEmpty) {
                    return 'Please enter location name';
                  }
                  return null;
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0),
              child: Text(
                'Start Coordinates',
                style: _formTextStyle,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 8.0, right: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Flexible(
                      child: TextFormField(
                    controller: _formStartLatitudeController,
                    style: _formTextStyle,
                    decoration: InputDecoration(
                        labelText: 'Latitude',
                        labelStyle: TextStyle(color: Colors.white)),
                    keyboardType: TextInputType.number,
                  )),
                  Flexible(
                    child: TextFormField(
                      controller: _formStartLongitudeController,
                      style: _formTextStyle,
                      decoration: InputDecoration(
                        labelText: 'Longitude',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  FlatButton.icon(
                    onPressed: getStartPosition,
                    icon: Icon(Icons.add,
                    color: Colors.white,),
                    label: Text(' '),
                  ),
                ],
              ),
            ),
            Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    SubmitBtnWithState(submitEvent, 'Processing'),
                    RaisedButton(
                      child: Text('Load GPX'),
                      color: Colors.blue,
                      onPressed: getTrack,
                    ),
                    FlatButton.icon(
                      onPressed: _formSaved == true ? getImage : null,
                      icon: new Icon(Icons.image),
                      label: Text('Add Image'),
                      disabledColor: Colors.white30,
                      color: Colors.blue,
                    ),
                  ],
                ),
            ),
        ],
      ),
    );
  }
}


class SubmitBtnWithState extends StatefulWidget {
  final void Function(int) callback;
  final String btnText;

  SubmitBtnWithState(this.callback, this.btnText);

  @override
  _SubmitBtnWithState createState() => _SubmitBtnWithState();
}


/// State for class SubmitBtnWithState
class _SubmitBtnWithState extends State<SubmitBtnWithState> {
  @override
  Widget build(BuildContext context) {
    return RaisedButton(
      child: Text('Submit'),
      color: Colors.blue,
      onPressed: () {
        widget.callback(1);
        Scaffold.of(context).showSnackBar(SnackBar(
          content: Text(widget.btnText),
          duration: Duration(seconds: 2),
        ));
      },
    );
  }
}
