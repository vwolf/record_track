
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
//import 'package:latlong/latlong.dart';

import '../track/trackService.dart';
import 'mapTrack.dart';

typedef TrackEvent = void Function(String event);

/// Page with map. Display selected track on map.
/// 
/// [PersistentBottomSheet] for
/// - track edit options
/// - track marker info
/// 
/// [MapInfoElement] for track point info
/// 
/// [Overlay] for track marker images fullscreen
class MapPage extends StatefulWidget {

  final TrackService trackService;
  MapPage(this.trackService);

  @override 
  MapPageState createState() => MapPageState();
}

class MapPageState extends State<MapPage> {

  GlobalKey mapPageKey = GlobalKey();

  /// Communication with map via streams
  StreamController<TrackPageStreamMsg> _streamController = StreamController.broadcast();

  /// Create map view
  MapTrack get _mapTrack => MapTrack(widget.trackService, _streamController);
  
  /// For persistent bottomsheet
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  PersistentBottomSheetController _persistentBottomSheetController;

  /// for waypoints
  int openWayPoint;
  List<FileImage> images = [];
  OverlayEntry _imageOverlay;

  TrackEvent trackEvent;

  void initState() {
    super.initState();
    initStreamController();
  }

  @override 
  void dispose() {
    if (_streamController != null) {
      _streamController.close();
    }
    super.dispose();
  }


  /// Initialize [_streamController] subscription to listen for TrackPageStreamMsg
  initStreamController() {
    _streamController.stream.listen((TrackPageStreamMsg trackingPageStreamMsg) {
      onMapEvent(trackingPageStreamMsg);
    }, onDone: () {
      print("TrackingPageStreamMsg done");
    }, onError: (e) {
      print("TrackingPage StreamController error $e");
    });
  }

  /// Touch events from map (status layer or marker).
  /// Registered at initStreamController
  /// 
  /// [trackingPageStreamMsg]
  bool onMapEvent(TrackPageStreamMsg trackingPageStreamMsg) {
    print("TrackingPage.onMapEvent ${trackingPageStreamMsg.type}");
    if (trackingPageStreamMsg.type == "pathOptions") {
      if (trackingPageStreamMsg.msg == "edit") {
        openPathEditOptionsSheet();
        return true;
      }
    }

    if (trackingPageStreamMsg.type == "infoBottomSheet") {
      openPersistentBottomSheet();
      return true;
    }

    return false;
  }

  /// Event notification used in [_trackEditOptionSheet] as Closure
  /// [event]'s: insertPoint, deletePoint, 
  /// redo-insertPoint,redo-addPoint, redo-deletePoint  
  void trackEventCall(String event) {
    print("MapPage.trackEventCall $event");
    _streamController.add(TrackPageStreamMsg('updateTrack', 'reload'));
    
    // always update state of bottom sheet [_reverseButton] IconButton
    if (_persistentBottomSheetController != null ) {
      _persistentBottomSheetController.setState(() {});       
    }
    
  }

  /// Show or remove [PersistentBottomSheet]
  /// 
  /// Todo Sometimes error 'removeLocalHistoryEntry' was called on null.
  /// Todo [_persistentBottomSheetController] not null even bottomSheet is no visible?
  /// added async await [_persistentBottomSheetController].closed
  openPersistentBottomSheet() async {
    if (_persistentBottomSheetController == null ) {
      setState(() {
        getDistance();
      });
      _persistentBottomSheetController =
          _scaffoldKey.currentState.showBottomSheet((BuildContext context) {
            return _trackInfoSheet;
          });

    } else {
      _persistentBottomSheetController.close();
      await _persistentBottomSheetController.closed;
      _persistentBottomSheetController = null;
    }
  }

 
  /// Show or remove [PersistentBottomSheet]
  openPathEditOptionsSheet() async {
    if (_persistentBottomSheetController == null) {
      _persistentBottomSheetController = 
        _scaffoldKey.currentState.showBottomSheet((BuildContext context) {
            return _trackEditOptionSheet;
          
      });
    } else {
      _persistentBottomSheetController.close();
      await _persistentBottomSheetController.closed;
      _persistentBottomSheetController = null;
    }
  }

  
  /// [BottomSheet] content for track editing.
  /// User Events are send to [TrackService].
  /// 
  Widget get _trackEditOptionSheet {
    
    return StatefulBuilder(
      
      builder: (BuildContext context, setState) {
        return Container(
          //color: c,
          child: ButtonBar(
            alignment: MainAxisAlignment.start,
            children: <Widget>[
              IconButton(
              icon: Icon(Icons.remove_circle),
              tooltip: "Remove path segment",
              onPressed: () {
                _mapTrack.trackService.deletePointInTrack(trackEventCall);
                //_streamController.add(TrackPageStreamMsg('updateTrack', 'reload'));
              },
            ),
            Text("Remove"),
            IconButton(
              icon: Icon(Icons.add_circle,),
            
              onPressed: () {
                _mapTrack.trackService.insertPointInTrack(trackEventCall);
                //_streamController.add(TrackPageStreamMsg('updateTrack', 'reload'));
              },
            ),
            Text("Add"),
            _mapTrack.trackService.trackRollbackObjs.length > 0 ? _reverseButton : Container(height: 0,), 
            ],
            
          )
        );
      }
    );
    
  }


  /// Redo button used in _trackEditOptionSheet
  Widget get _reverseButton {
    return IconButton(
      icon: Icon(Icons.replay),
      onPressed: () {
        _mapTrack.trackService.redoTrackEditAction(trackEventCall);
      },);
  }


  /// Bottomsheet content for track info.
  /// Track infos are: 
  /// - Total length of track
  /// - Description of track (in gpx file)
  /// - Distance from tapped point to start and end of track
  /// 
  /// ToDo Needs some style and more possible content (profile height?)
  ///
  Widget get _trackInfoSheet {
    return Container(
      height: MediaQuery.of(context).size.height * 0.33,
      color: Colors.blueGrey,
    );
  }

  /// Use [WillPopScope] to close [OverlayEntry] [imageOverlay]
  ///
  @override build(BuildContext context) {

    return WillPopScope(
      onWillPop: _requestPop,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text("${widget.trackService.gpxFileData.trackName}"),
        ),
        body: Column(children: <Widget>[
          _mapTrack,
        ],),
      ),
    );
  }

  

  Future<bool> _requestPop() async {
    print("_requestPop()");
    // if (_imageOverlay == null) {
    //   Navigator.of(context).pop();
    //   return Future.value(false);
    // } 

    if (_imageOverlay != null) {
      _imageOverlay.remove();
      _imageOverlay = null;
      return Future.value(false);
    }

    if ( _persistentBottomSheetController != null ) {
      _persistentBottomSheetController.close();
      await _persistentBottomSheetController.closed;
      _persistentBottomSheetController = null;
      
      return Future.value(false);
    }

    Navigator.of(context).pop();
    return Future.value(false);
  }


  /// Calculate the distance from current position to start and end of track
  ///
  getDistance() {
    // LatLng startLatLng = _mapTrack.trackService.gpxFileData.gpxLatlng.first;
    // LatLng endLatLng = _mapTrack.trackService.gpxFileData.gpxLatlng.last;
    // LatLng currentPosition = _mapTrack.trackService.currentPosition;
    // if (currentPosition != null) {
    //   GeoLocationService.gls.getDistanceBetweenCoords(startLatLng, currentPosition)
    //       .then((result) {
    //         distanceToStart = result.truncateToDouble();
    //   });

    //   GeoLocationService.gls.getDistanceBetweenCoords(endLatLng, currentPosition)
    //   .then((result) {
    //     distanceToEnd = result.truncateToDouble();
    //   });
    // }
  }
}