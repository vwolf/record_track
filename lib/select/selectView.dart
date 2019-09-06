import "package:flutter/material.dart";

import '../track/newTrack.dart';

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

  void _allTracks() {
    debugPrint("allTracks");
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
                _allTracks();
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



