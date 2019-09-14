import 'package:flutter/material.dart';

import 'trackListService.dart';
import '../db/database.dart';
import '../db/models/track.dart';
import 'trackService.dart';

import 'trackListItem.dart';
import '../map/mapPage.dart';

/// Display all saved tracks in ListView
/// 
class TrackList extends StatefulWidget {

  TrackList();

  @override 
  _TrackListState createState() => _TrackListState();
}

class _TrackListState extends State<TrackList> {

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tracks"),
        ),
      body: _buildFutureList(context)
    );
  }

  List<Track> _tracks = [];

  /// Get all [Track] in db and as gpx files
  Future<List<Track>> getTracks() async {
    List tracks = await DBProvider.db.getAllTracks();
    _tracks = tracks;

    List<Track> gpxTracks = await TrackListService().getAllTracksFromFile();
    _tracks.addAll(gpxTracks);
    
    return _tracks;
  }


  editTour(BuildContext context, Track track) {

  }

  /// Go to Save tour to external page
  archiveTour(BuildContext context, Track track) {
    // Navigator.of(context).push(
    //     new MaterialPageRoute(builder: (context) {
    //       return new WriteTrackPage(track);
    //     })
    // );
  }


  /// Delete track in Track table and
  /// coords and item table for track
  deleteTrack(BuildContext context, int index) {
    if (_tracks[index].track != null ) {
      DBProvider.db.deleteTable(_tracks[index].track);
    }
    if (_tracks[index].items != null ) {
      DBProvider.db.deleteTable(_tracks[index].items);
    }
    DBProvider.db.deleteTrack(_tracks[index].id);

    setState(() {});
  }


  goTrackDetailPage(Track track) {
    setState(() {
      
    });
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) {
        return new MapPage(TrackService(track));
      })
    );
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
              return TrackListItem(
                items: <ActionItems>[
                  ActionItems(
                    icon: IconButton(
                      icon: Icon(Icons.edit,
                      size: 36.0,),
                      onPressed: () {},
                      color: Colors.green,
                    ),
                    onPress: () {
                      editTour(context, snapshot.data[index]);
                    }
                  ),
                  ActionItems(
                    icon: IconButton(
                          icon: Icon(Icons.archive,
                          size: 36.0,),
                          onPressed: () {},
                          color:  Colors.green,
                      ),
                      onPress: () {
                        archiveTour(context, snapshot.data[index]);
                      },
                      backgroundColor: Colors.orange
                    ),
                    ActionItems(
                      icon: IconButton(
                          icon: Icon(Icons.delete,
                            size: 36.0,),
                          onPressed: () {},
                          color:  Colors.red,
                        ),
                        onPress: () {
                          print("delete track");
                          deleteTrack(context, index);
                        },
                        backgroundColor: Colors.white70
                    ),
                ],
                child: Container(
                  padding: const EdgeInsets.only(top: 2.0),
                  height: 115,
                  child: Card(child: InkWell(
                    onTap: () {
                      goTrackDetailPage(snapshot.data[index]);
                    },
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                      leading: Container(
                        padding: EdgeInsets.only(right: 10.0),
                        decoration: BoxDecoration(
                          border: Border(
                            right: BorderSide(width: 1.0, color: Colors.black87)
                          )
                        ),
                        child: Icon(
                          snapshot.data[index].getOption("type") == "walk" ? Icons.directions_walk : Icons.directions_bike,
                          size: 40.0,
                        ),
                      ),
                      title: Text(snapshot.data[index].name,
                        style: Theme.of(context).textTheme.headline,
                      ),
                      // subtitle: ListView(
                      //   scrollDirection: Axis.horizontal,
                      //   children: <Widget>[
                      //     Text(snapshot.data[index].location),
                      //   ],
                      // ),
                      trailing: Icon(Icons.keyboard_arrow_right, size: 30.0,),
                    )
                  ),
                  ),
                ),
              );
            }
          );
        } else {
          return Center(child: CircularProgressIndicator());
        }
      }
    );
  }


  // _buildFutureList(context) {
  //   return FutureBuilder(
  //     future: getTracks(),
  //     builder: (BuildContext context, AsyncSnapshot<List<Track>> snapshot) {
  //       if (snapshot.hasData) {
  //         return ListView.builder(
  //           itemCount: snapshot.data.length,
  //           itemBuilder: (BuildContext context, int index) {
  //             debugPrint("TrackList ListView.builder itemCount: ${snapshot.data.length}");
  //             return ListTile(
  //               contentPadding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
  //               leading: Container(
  //                 padding: EdgeInsets.only(right: 10.0),
  //                 child: Icon(Icons.directions_walk, size: 40.0,
  //                 ),
  //               ),
  //               title: Text(
  //                 _tracks[index].name,
  //                 style: Theme.of(context).textTheme.headline,
  //               ),
  //               subtitle: Container(
  //                 //height: 115.0,
  //                 child: Text(snapshot.data[index].location),
  //                 ),
  //               // subtitle: ListView(
  //               //   //scrollDirection: Axis.horizontal,
  //               //   children: <Widget>[
  //               //     Text(snapshot.data[index].location),
  //               //   ],
  //               // ),
  //               trailing: Icon(Icons.keyboard_arrow_right, size: 30.0,),
  //             );
  //           },
  //         );
  //       } else {
  //         return Center(child: CircularProgressIndicator());
  //       }
  //     },
  //   );
  // }
}