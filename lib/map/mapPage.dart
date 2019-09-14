
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
//import 'package:latlong/latlong.dart';

import '../track/trackService.dart';
import 'mapTrack.dart';

/// Page with map. Display selected track on map
/// [PersistentBottomSheet] for track marker infos
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

  MapTrack get _mapTrack => MapTrack(widget.trackService, _streamController);
  
  /// For persistent bottomsheet
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  PersistentBottomSheetController _persistentBottomSheetController;

  /// for waypoints
  int openWayPoint;
  List<FileImage> images = [];
  OverlayEntry _imageOverlay;

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

  /// Touch events from map (status layer or marker)
  ///
  /// [trackingPageStreamMsg]
  onMapEvent(TrackPageStreamMsg trackingPageStreamMsg) {
    print("TrackingPage.onMapEvent ${trackingPageStreamMsg.type}");
  }


  /// Show a [PersistentBottomSheet]
  /// First close open [PersistentBottomSheet]
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

  /// Bottomsheet content for track info
  /// ToDo Needs some style and more possible content (profile height?)
  ///
  Widget get _trackInfoSheet {
    return Container();
  }

  /// Use [WillPopScope] to close [OverlayEntry] [imageOverlay]
  ///
  @override build(BuildContext context) {

    return WillPopScope(
      onWillPop: _requestPop,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(""),
        ),
        body: Column(children: <Widget>[
          _mapTrack,
        ],),
      ),
    );
  }


  Future<bool> _requestPop() {
    print("_requestPop()");
    if (_imageOverlay == null) {

      Navigator.of(context).pop();
      return Future.value(false);

    } else {
      _imageOverlay.remove();
      _imageOverlay = null;
      return Future.value(false);
    }
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