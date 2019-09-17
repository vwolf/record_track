import 'dart:convert';
import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart' as prefix0;
import 'package:geolocator/geolocator.dart';

import 'package:latlong/latlong.dart';
import 'package:flutter/rendering.dart';
import 'package:record_track/db/models/trackCoord.dart';
import 'package:record_track/gpx/gpxFileData.dart';
import 'package:record_track/gpx/gpxParser.dart';

import '../services/geolocationService.dart';
import '../db/models/track.dart';
import '../db/database.dart';

import 'package:path/path.dart' as path;
import '../readWrite/readFile.dart';
import '../services/status.dart';
import 'startTrackMap.dart';

/// Create new track or update track
/// Initilizer for new track and update track
/// New Track start position: 
/// 1. Enter name for start location, no coords. 
///    Get [Placemark] list for location [GeoLocationService] [getPlacemarksFromLocationName]
/// 2. Enter lat / lon values and get [Placemark] for position.
///    [getStartPosition] -> [GeoLocationService] []
/// 3. Click Add sign to get current position.
///    Get [Placemark] for current position
/// 4. Click on map icon next to location name to display a map to
///    choose a position on map.
///    After a position [LatLng] is selected on map, try to get 
///    [Placemark] for position. If there is a [Placemark] use 
///    [Placemark.name] as location name.
/// 
/// All this will only work if connected to internet
/// 4. No connection 
///    Enter location name -> no coords -> use default coords
///    Enter location name -> use offline map tiles to set start position
/// 
class NewTrack extends StatefulWidget {

  final Track track = Track();
  Track _track = Track();
  
  NewTrack();

  NewTrack.withTrack(Track track) {
    this._track = track;
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

  // Form focus nodes
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _descriptionFocus = FocusNode();
  final FocusNode _locationFocus = FocusNode();

  // Form style
  TextStyle _formTextStyle = TextStyle(color: Colors.white);
 
  InputDecoration _formInputDecoration = InputDecoration(
      labelText: 'Name', labelStyle: TextStyle(color: Colors.white70));


  @override 
  void initState() {
    super.initState();

    if (widget._track.name != null) {
      insertSavedTrack();
    }
  }

  /// Insert values from saved track[widget._track] into Formfields
  /// 
  void insertSavedTrack() {
    _newTrack = false;
      _formSaved = true;
      _formNameController.text = widget._track.name;
      _formDescriptionController.text = widget._track.description;
      _formLocationController.text = widget._track.location;

      if (widget._track.coords != null) {
        LatLng trackCoords = GeoLocationService.gls.stringToLatLng(widget._track.coords);
        _formStartLatitudeController.text = trackCoords.latitude.toString();
        _formStartLongitudeController.text = trackCoords.longitude.toString();
      }

      if (widget._track.options != null) {

      }

      savedTrack = widget._track;
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

  /// Show map, centered at [StartTrackMap][_center].
  /// Return value is the clicked coords [] in map
  /// 
  getStartPositionMap() async {
    LatLng result = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) {
        return new StartTrackMap();
      })
    );
    if (result != null) {
      print( "getStartPositionResult: ${result.latitude}, ${result.longitude}" );
      _formStartLatitudeController.text = result.latitude.toString();
      _formStartLongitudeController.text = result.longitude.toString();
      // get location name for position
      String description = await GeoLocationService.gls.getCoordDescription(result);
      _formLocationController.text = description;

    } else {}
  }


  /// Save or update track data 
  /// Used as closure in SubmitBtnWithState
  /// Change tracks read from gpx files?
  ///  Write changes to an local text file?
  ///  Write changes to gpx file?
  ///  Write track to db, write changes and mark track entry
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

      /// If coords are zero, try to get coords from location name
      if (startCoords.latitude == 0.0 && startCoords.longitude == 0.0) {
        List<Placemark> placemarks = await GeoLocationService.gls.getPlacemarksFromLocationName(widget.track.location);
       if (placemarks.length > 0) {
          print(placemarks[0].position);
          startCoords.latitude = placemarks[0].position.latitude;
          startCoords.longitude = placemarks[0].position.longitude;
          widget.track.coords = GeoLocationService.gls.latlngToJson(startCoords);
        }
      }

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

      /// Add [widget.track.coords] to track coords
      TrackCoord trackCoord = TrackCoord(latitude: startCoords.latitude, longitude: startCoords.longitude);
      var addTrackCoordResult = await DBProvider.db.addTrackCoord(trackCoord, widget.track.track);
      debugPrint("addTrackCoordResult $addTrackCoordResult");
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
           _gpxFileInfo,
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
              textInputAction: TextInputAction.next,
              focusNode: _nameFocus,
              onFieldSubmitted: (term) {
                _fieldFocusChange(context, _nameFocus, _descriptionFocus);
              },
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
              textInputAction: TextInputAction.next,
              focusNode: _descriptionFocus,
              onFieldSubmitted: (term) {
                _fieldFocusChange(context, _descriptionFocus, _locationFocus);
              },
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Flexible(
                    child: TextFormField(
                      controller: _formLocationController,
                      style: _formTextStyle,
                      textInputAction: TextInputAction.done,
                      focusNode: _locationFocus,
                      onFieldSubmitted: (term) {
                        _fieldFocusChange(context, _locationFocus, _locationFocus);
                      },
                      decoration: InputDecoration(
                        labelText: 'Location Name',
                        labelStyle: TextStyle(color: Colors.white70,),
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return 'Please enter location name';
                        }
                        return null;
                      },
                    ),
                  ),
                  FlatButton.icon(
                    onPressed: getStartPositionMap,
                    icon: Icon(Icons.map,
                    color: Colors.white,),
                    label: Text(' '),
                  )
                ],
              )
              // child: TextFormField(
              //   controller: _formLocationController,
              //   style: _formTextStyle,
              //   textInputAction: TextInputAction.done,
              //   focusNode: _locationFocus,
              //   onFieldSubmitted: (term) {
              //     _fieldFocusChange(context, _locationFocus, _locationFocus);
              //   },
              //   decoration: InputDecoration(
              //     labelText: 'Location name',
              //     labelStyle: TextStyle(color: Colors.white70),
              //   ),
              //   validator: (value) {
              //     if (value.isEmpty) {
              //       return 'Please enter location name';
              //     }
              //     return null;
              //   },
              // ),
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
                    // FlatButton.icon(
                    //   onPressed: _formSaved == true ? getImage : null,
                    //   icon: new Icon(Icons.image),
                    //   label: Text('Add Image'),
                    //   disabledColor: Colors.white30,
                    //   color: Colors.blue,
                    // ),
                  ],
                ),
            ),
        ],
      ),
    );
  }

  _fieldFocusChange(BuildContext context, FocusNode currentFocus, FocusNode nextFocus) {
    currentFocus.unfocus();
    if (currentFocus == _locationFocus) {
      // here we start validating the location name
      checkLocationName(_formLocationController.text);
    } else {
      FocusScope.of(context).requestFocus(nextFocus);
    }
    
  }

  /// If [getPlacementFromLoctionName] return null then ...
  /// If [placemarks] list has more then one entry then...
  /// 
  checkLocationName(String locationName) async {
    try {
      List<Placemark> placemarks = await GeoLocationService.gls.getPlacemarksFromLocationName(locationName);
      if (placemarks.length > 0) {
        locationDialog(placemarks[0]);        
      } 
    } catch (e) {
      print(e);
      noLocationDialog();
    }
  }

  /// If parameter [placemark] is null 
  /// - no valid location name?
  /// - no internet connection?
  /// More the one [Placemark] possible
  locationDialog([Placemark placemark]) {
    String contentString = placemark != null ? 
      "${placemark.name} at ${placemark.position.latitude}, ${placemark.position.longitude}"
      : "No Infos for this location!";
      contentString += "\n${AppStatus.appStatus.connectivityResult.toString()}";

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(contentString),
          actions: <Widget>[
            FlatButton(
              child: Text("OK"),
              onPressed: () {
                _formStartLatitudeController.text = placemark.position.latitude.toString();
                _formStartLongitudeController.text = placemark.position.longitude.toString();
                Navigator.of(context).pop();
              },)
          ],
        );
      }
    );
  }


  /// Dialog if no location available
  /// Network connection or WiFi?
  /// 
  noLocationDialog() {
    String contentString = "No Infos for this location!";
    ConnectivityResult connect = AppStatus.appStatus.connectivityResult;
    if (connect == ConnectivityResult.none) {
      contentString += "\nNo Network Connection";
    } else {
      contentString += "\nThere is a network connection, but no internet service.";
    }
    contentString += "\nEnter a name for location.";
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Text(contentString),
          actions: <Widget>[
            FlatButton(
              child: Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      }
    );
  }


  Widget get _gpxFileInfo {
    if (savedTrack != null) {
      return Padding(
        padding: EdgeInsets.only(left: 16.0, right: 12.0, top: 12.0),
        child: Text("This track is loaded from ${savedTrack.gpxFilePath}"),
      
      );
    } else {
      return Container();
    }
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
