import "package:flutter/material.dart";
import 'package:record_track/tracking/trackingPage.dart';

import '../track/newTrack.dart';
import '../track/trackList.dart';
import '../db/models/track.dart';

/// Kind of main navigation page
/// - New Track
/// - Show All Tracks
/// - Start Recording Track
/// 
class SelectPage extends StatelessWidget {
  final List<Track> tracks;
  final bool tracksRead;

  SelectPage(this.tracks, this.tracksRead);

  /// Go to NewTrack page
  /// 
  _newTrack(BuildContext context) async {
    debugPrint("newTrack");
    var result = Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewTrack(tracks) )
    );

    if (result != null) {
      if (result is Track) {
        tracks.add(result as Track);

      }
    }
  }

  /// Start tracking now. 
  /// Create new track
  _startTrack(BuildContext context) {
    debugPrint("startTrack");
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TrackingPage() )
    );
  }

  /// All [tracks] in ListView
  ///
  void _allTracks(BuildContext context) {
    debugPrint("allTracks");
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) {
        return TrackList(tracks);
      })
    );
  }



  @override
  Widget build(BuildContext context) {

    return Container(
     // height: ,
      width: double.maxFinite,
      color: Colors.red,
      child: Column(
        mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 48.0), 
              child: Divider(
                color: Colors.white,
              ),
            ),
            IconButton(
              icon: Icon(Icons.directions_walk, size: 52.0),
              tooltip: "Start Track",
              onPressed: () {
                _startTrack(context);
              },
            ),
            Padding(
              padding: EdgeInsets.only(top: 24.0),  
              child: Divider(
                color: Colors.white,
              ),
            ),
            IconButton(
             icon: Icon(Icons.add_circle, size: 52.0),
             tooltip: "New Track",
             onPressed: () {
              _newTrack(context);
             },
            ),
            Padding(
              padding: EdgeInsets.only(top: 24.0),
              child: Divider(
                color: Colors.white,
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.format_list_bulleted, size: 52.0, color: tracksRead == true ? Colors.white : Colors.white10,),
              tooltip: "All Tracks",
              onPressed: () {
                _allTracks(context);
              },
            ),
            Padding(
              padding: EdgeInsets.only(top: 24.0),
              child: Divider(
                color: Colors.white,
              ),
            )
         ],),
    );
  }
}



