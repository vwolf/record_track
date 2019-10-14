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

typedef TrackingStatusbarEvent = void Function(StatusBarEvent event);

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
  MapController mapController;

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

  @override 
  void initState() {
    super.initState();
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
                points: widget.trackingService.trackPoints,
                strokeWidth: 4.0,
                color: Colors.blueAccent,
              )
            ],
            //onTap: (Polyline polyline, LatLng latlng, int polylineIdx) => _onTap("track", polyline, latlng, polylineIdx),  
          ),
          StatusbarLayerPluginOption(
            eventCallback: statusbarCallback,
            offlineMode: _offline,
            location: _location,
            edit: _edit,
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
      widget.trackingService.addTrackingPoint(currentPos);

     // makeGpsPosList(currentPos: currentPos);
    }
  }


}