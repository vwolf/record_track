import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:record_track/track/trackService.dart';
import 'package:record_track/track/trackingService.dart';
import 'package:record_track/map/mapScale/scaleLayerPluginOptions.dart';
import 'package:record_track/map/mapStatusBar/statusbarPluginOptions.dart';
import 'package:record_track/services/geolocationService.dart';
import 'package:record_track/services//directoryList.dart';
import 'package:record_track/readWrite/readFile.dart';
import 'package:record_track/services/settings.dart';

typedef TrackingStatusbarEvent = void Function(StatusBarEvent event);
typedef MapPathCallback = void Function(String mapPath);

/// Track current position and display as track.
/// - show [FlutterMap]
/// - subscribe to [subscribeToPositionStream] in [GeoLocationService].
/// - save positions from tracker stream
/// 
class MapTracking extends StatefulWidget {

  final StreamController<TrackPageStreamMsg> streamController;
  final TrackingService trackingService;

  MapTracking( this.streamController, this.trackingService);

  @override 
  MapTrackingState createState() => MapTrackingState();
}

class MapTrackingState extends State<MapTracking> {

  /// MapController
  MapController mapController = MapController();

  LatLng get startPos => widget.trackingService.getTrackStart();

  /// communication with map via streams
  StreamController<TrackPageStreamMsg> _streamController = StreamController.broadcast();

  StreamController _positionStreamController;

  /// State variables
  //bool _showItem = false;
  bool _tracking = false;

  StatusbarPlugin _statusbarPlugin = StatusbarPlugin();
  // status values
  bool _offline = false;
  bool _location = false;
  bool _edit = false;

  TrackingStatusbarEvent statusbarCall;

  /// callback function
  MapPathCallback setMapPath;

  @override 
  void initState() {
    super.initState();
    setMapPath = getMapPath;
  }

  @override 
  void dispose() {
    _streamController.close();
    if (_positionStreamController != null) {
      _positionStreamController.close();
    }
    super.dispose();
  }

  /// Initialize _streamController subscription to listen 
  /// for [TrackPageStreamMsg].
  /// 
  initStreamController() {
    _streamController.stream.listen((TrackPageStreamMsg trackingPageStreamMsg) {
      onMapEvent(trackingPageStreamMsg);
    }, onDone: () {
      print('TrackingPageStreamMsg Done');
    }, onError: (error) {
      print('TrackingPage StreamContorller error $error');
    });
  }


  onMapEvent(TrackPageStreamMsg trackingPageStreamMsg) {
    print("TrackingPage.onMapEvent ${trackingPageStreamMsg.type}");
    switch (trackingPageStreamMsg.type) {
      case TrackPageStreamMsgType.TrackingMapStatusAction :
        if ( trackingPageStreamMsg.msg == "camera") {
          // openPersistentBottomSheet("camera");
          Navigator.of(context).push(
              MaterialPageRoute(builder: (context) {
                //return CameraPage();
              })
          );
        };
        break;
        default: 
        print("Unkown trackingPageStreamMsg.type");
        break;
    };

  }

  Widget build(BuildContext context) {
    return Flexible(
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          center: startPos,
          zoom: 15,
          minZoom: 4,
          maxZoom: 18,
          plugins: [
            ScaleLayerPlugin(),
            //StatusbarPlugin(),
            _statusbarPlugin
          ],
        ),
        layers: [
          TileLayerOptions(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          ScaleLayerPluginOption(
            lineColor: Colors.blue,
            lineWidth: 3,
            textStyle: TextStyle(color: Colors.blue, fontSize: 12),
            padding: EdgeInsets.all(10),
          ),
          PolylineLayerOptions(
            polylines: [
              Polyline(
                points: widget.trackingService.trackLatLngs,
                strokeWidth: 4.0,
                color: Colors.blueAccent,
              )
            ],
            //onTap: (Polyline polyline, LatLng latlng, int polylineIdx) => _onTap("track", polyline, latlng, polylineIdx),  
          ),

          // layer for current position
          MarkerLayerOptions(
              markers: gpsPositionList
          ),

          StatusbarLayerPluginOption(
            eventCallback: statusbarCallback,
            offlineMode: _offline,
            location: _location,
            edit: _edit,
            type: "tracking",
          ),
        ],)
    );
  }


  /// Event [StatusBarEvent] from [StatusbarLayer].
  /// 
  /// - [StatusBarEvent.ZoomIn], [StatusBarEvent.ZoomOut]: 
  /// - [StatusBarEvent.Location]: toogle gps tracking mode [_location] in switchLocation
  /// - [StatusBarEvent.OfflineMode]: 
  /// - [StatusBarEvent.Info] : stream msg to [MapPage]. 
  /// - [StatusBarEvent.Edit]: toogle track edit mode
  void statusbarCallback(StatusBarEvent event) {
    debugPrint("statusbarCall $event");
    switch (event) {
      case StatusBarEvent.ZoomIn :
        setState(() {
          mapController.move(mapController.center, mapController.zoom + 1.0);
        });
        debugPrint("zoom: ${mapController.zoom}");
        break;

      case StatusBarEvent.ZoomOut :
        setState(() {
          mapController.move((mapController.center), mapController.zoom - 1.0);
        });
        break;

    // geolocation tracking switch
      case StatusBarEvent.Location :
        setState(() {
          _location = !_location;
          toggleTracker(true);
        });
        break;

      case StatusBarEvent.OfflineMode :
        if (widget.trackingService.track.offlineMapPath == null) {
          // user must set path to offline map tiles
          openFileIO();
        } else {
          widget.trackingService.pathToOfflineMap = widget.trackingService.track.offlineMapPath;

          setState(() {
            _offline = !_offline;
            //_mapStatusLayer.statusNotification(event.msg, _offline);
            //trackService.getTrackBoundingCoors();
          });
        }

        break;

      case StatusBarEvent.Info :
        _streamController.add(TrackPageStreamMsg(TrackPageStreamMsgType.InfoBottomSheet, "open"));
        break;

      case StatusBarEvent.Edit :
//        setState(() {
//          _edit = !_edit;
//          widget.trackingService.selectedTrackPoints = null;
//          _activeMarker = [];
//          if (!_edit) {
//            _streamController.add(TrackPageStreamMsg(TrackPageStreamMsgType.PathOptions, "close"));
//          }
//
//        });
        break;
    }
  }

  /// Return current position as marker
  /// Show last points (5?)
  List<Marker> get gpsPositionList => makeGpsPositionList();

  List<Marker> makeGpsPositionList() {
    List<Marker> ml = [];

    // use last marker
    if (widget.trackingService.trackPoints.length > 0) {
      Marker newMarker = Marker(
        width: 60.0,
        height: 60.0,
        point: widget.trackingService.trackPoints.last,
        builder: (ctx) =>
            Container(
              child: Icon(
                Icons.my_location,
              ),
            )
      );
      ml.add(newMarker);
    }
    return ml;
  }


  /// Position Stream from Geolocation
  /// 
  /// Subscribe / Unsubscribe to PositionStream in Geolocation
  toggleTracker(bool trackState) {
    print("tourmap.toggleTracker to $trackState");
    if (trackState == true && _tracking == false) {
      trackerStreamSetup();
      GeoLocationService.gls.subscribeToPositionStream(_positionStreamController);
      //GeolocationService.gls.streamGenerator(trackerStreamController);
      _tracking = true;
    } else {
      GeoLocationService.gls.unsubcribeToPositionStream();
      _tracking = false;
    }
  }

  trackerStreamSetup() {
    _positionStreamController = StreamController();
    _positionStreamController.stream.listen((coords) {
      onTrackerEvent(coords);
    });
  }

  /// trackStreamController stream msg
  /// Two possible listener tracking and show current Position, both possible
  onTrackerEvent(Position coords) {
    print(coords);
    // add coord
    if (_tracking) {
      widget.trackingService.addPointToTrack(LatLng(coords.latitude, coords.longitude), redo: false);
    }


    //StatusbarLayer sb = context.inheritFromWidgetOfExactType(StatusbarLayer);
    // update current position marker
    if (_statusbarPlugin.getStatusbarLayer().statusbarLayerOpts.location == true) {
      LatLng currentPos = LatLng(coords.latitude, coords.longitude);
      //widget.trackingService.addTrackingPoint(currentPos);

      //makeGpsPosList(currentPos: currentPos);
      setState(() {
        gpsPositionList;
      });

    }
  }


  /// Open a kind of directory browser to select the director which contains the map tiles
  ///
  /// ToDo Open in a new page?
  openFileIO() async {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) {
          return DirectoryList(setMapPath, Settings.settings.externalSDCard );
        })
    );
  }

  /// Callback offline map directory selection
  /// There was already a basic check if valid directory
  ///
  void getMapPath(String mapPath) {
    print("mapPath: $mapPath");
    setState(() {
      widget.trackingService.pathToOfflineMap = mapPath;
      _offline = !_offline;
      //_mapStatusLayer.statusNotification("offline_on", _offline);

    });

    // add the path to offline map tiles to settings file
    ReadFile().addToJson("tracksSettings.txt", widget.trackingService.track.name, mapPath);
    // update track
    widget.trackingService.track.offlineMapPath = mapPath;
  }
}