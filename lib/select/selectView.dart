import "package:flutter/material.dart";

import '../track/newTrack.dart';
import '../track/trackList.dart';

/// Kind of main navigation page
/// New Track
/// Show All Tracks
/// Start Recording Track
/// 
class SelectPage extends StatelessWidget {
  
  void _newTrack(BuildContext context) {
    debugPrint("newTrack");
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) {
        return NewTrack();
      })
    );
  }

  void _startTrack() {
    debugPrint("startTrack");
  }

  void _allTracks(BuildContext context) {
    debugPrint("allTracks");
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) {
        return TrackList();
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
               _startTrack();
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
              icon: Icon(Icons.format_list_bulleted, size: 52.0),
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



