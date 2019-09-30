import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:record_track/map/mapTracking.dart';
import 'package:record_track/track/trackService.dart';
import 'package:record_track/db/models/track.dart';

/// Start tracking current position.
/// Create an empty track
/// 
class TrackingPage extends StatefulWidget {

  TrackingPage();

  @override 
  TrackingPageState createState() => TrackingPageState();
}


class TrackingPageState extends State<TrackingPage> {

  final GlobalKey <ScaffoldState>_scaffoldKey = GlobalKey<ScaffoldState>();

  /// communication with map via streams
  StreamController<TrackPageStreamMsg> _streamController = StreamController.broadcast();

  /// TrackService with empty track, then save track with default values
  TrackService trackService = TrackService(Track());

  MapTracking get _mapTracking => MapTracking(_streamController, trackService );

  bool emptyTrackReady = false;

  @override 
  void initState() {
    super.initState();

    initEmptyTrack();
  }

  @override 
  void dispose() {
    _streamController.close();
    super.dispose();
  }

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text("Tracking"),
      ),
      body: Column(
        children: <Widget>[
          emptyTrackReady == true ? _mapTracking : Container()
        ],
      ),
    );
  }

  /// Save an empty track to db, then show map
  /// 
  Future initEmptyTrack() async {
    try {
      trackService.saveEmptyTrack().then((r) {
        if (r == true) {
          trackService.setTrackStart(trackService.trackLatLngs.first);
          setState(() {
            emptyTrackReady = true; 
          });
        }
      });
    } catch (e) {
      print("initEmptyTrack error $e");
    }
  }
}