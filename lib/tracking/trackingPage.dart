import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:record_track/map/mapTracking.dart';
import 'package:record_track/track/trackService.dart';
import 'package:record_track/track/trackingService.dart';
import 'package:record_track/db/models/track.dart';

/// Page for a [MapTracking] map to show current position / track.
/// 1. Create an empty track and show map [MapTracking].
/// 2. Restart tracking using [StatusBarLayer].
/// 3. Activate tracking for existing track 
///    (add points to end of track).
/// When to save positions to db?
/// Immidiatly or when leaving page?
/// Add pictures/videos/audios to track points 
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
  TrackingService trackingService = TrackingService();

  MapTracking get _mapTracking => MapTracking(_streamController, trackingService );

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
      trackingService.saveEmptyTrack().then((r) {
        if (r == true) {
          trackingService.setTrackStart(trackingService.trackLatLngs.first);
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