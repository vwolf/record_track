import 'package:flutter/material.dart';

import '../db/database.dart';
import '../db/models/track.dart';

class TrackList extends StatefulWidget {

  TrackList();

  @override 
  _TrackListState createState() => _TrackListState();
}

class _TrackListState extends State<TrackList> {

  @override 
  Widget build(BuildContext context) {
    return _buildFutureList(context);
  }

  List<Track> _tracks = [];

  Future<List<Track>> getTracks() async {
    List tracks = await DBProvider.db.getAllTracks();
    _tracks = tracks;
    return _tracks;
  }


  /// Slideable version
  /// 
  _buildFutureList(context) {
    return FutureBuilder(
      future: getTracks(),
      builder: (BuildContext context, AsyncSnapshot<List<Track>> snapshot) {
        if (snapshot.hasData) {
          return ListView.builder(
            itemCount: snapshot.data.length,
            itemBuilder: (BuildContext context, int index) {
              debugPrint("TrackList ListView.builder itemCount: ${snapshot.data.length}");
            },
          );
        }
      },
    );
  }
}