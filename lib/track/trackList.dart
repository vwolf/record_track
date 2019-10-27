import 'package:flutter/material.dart';


import '../db/database.dart';
import '../db/models/track.dart';
import 'trackService.dart';
import 'trackListItem.dart';
import '../map/mapPage.dart';
import 'newTrack.dart';

/// Display all saved tracks in ListView
/// 
class TrackList extends StatefulWidget {

  final List<Track> tracks;
  TrackList(this.tracks);

  @override 
  _TrackListState createState() => _TrackListState();
}


class _TrackListState extends State<TrackList> {

  _TrackListState();

  List<Track> _tracks = [];
  ListSortState trackSortState = ListSortState.unsorted;

  @override 
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tracks"),
      ),
      endDrawer: Drawer(
        child: ListView(
          children: <Widget>[
            const DrawerHeader(
              child: const Center(
                child: const Text("Sorting"),
              ),
            ),
            ListTile(
              title: Text("Date created"),
              trailing: IconButton(
                icon: Icon(Icons.sort),
                onPressed: () {
                  sortTracks("date");
                  Navigator.pop(context);
                },
              ),
            ),
            
            ListTile(
              title: Text("Name"),
              trailing: IconButton(
                icon: Icon(Icons.sort_by_alpha),
                onPressed: () {
                  sortTracks("alphabethically");
                  Navigator.pop(context);
                },
              ),
            ) 
          ],
        ),
      ),
      body: _buildFutureList(context)
    );
  }

 

  /// Get all [Track] in db and as gpx files.
  /// 
  Future<List<Track>> getTracks() async {
    _tracks = widget.tracks;
    return _tracks;
  }

  /// Sort items in [tracks].
  /// [order] == alphabethically then switch between [ListSortState.alpabethicallyDown]
  /// and [ListSortState.alpabethicallyUp].
  sortTracks(String order) {
    if (order == "alphabethically" )  {
      if(trackSortState != ListSortState.alpabethicallyDown) {
        widget.tracks.sort((a, b) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        trackSortState = ListSortState.alpabethicallyDown;
      } else {
        widget.tracks.sort((a, b) {
          return b.name.toLowerCase().compareTo(a.name.toLowerCase());
        });
        trackSortState = ListSortState.alpabethicallyUp;
      }
    }

    if (order == "date") {
      if(trackSortState != ListSortState.dateDown) {
        widget.tracks.sort((a, b) {
          return a.createdAt.toLowerCase().compareTo(b.createdAt.toLowerCase());
        });
        trackSortState = ListSortState.dateDown;
      } else {
        widget.tracks.sort((a, b) {
          return b.createdAt.toLowerCase().compareTo(a.createdAt.toLowerCase());
        });
        trackSortState = ListSortState.dateUp;
      }
    }

    setState(() {
      
    });
  }


  editTour(BuildContext context, Track track) {
    Navigator.of(context).push(
      new MaterialPageRoute(builder: (context) {
        return NewTrack.withTrack(track);
      })
    );
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
    if (widget.tracks[index].items != null ) {
      DBProvider.db.deleteTable(widget.tracks[index].items);
    }
    DBProvider.db.deleteTrack(widget.tracks[index].id);
    
    if (_tracks[index] != null) {
      _tracks.removeAt(index);
    }
    setState(() {});
  }


  goTrackDetailPage(TrackService trackService) {
    setState(() {
      
    });
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) {
        return new MapPage(trackService);
      })
    );
  }

  /// Handle tap on list item.
  /// [Track] at [trackAtIndex] can be
  /// - read from db
  /// - read from gpx file
  /// 
  _handleTap(Track trackAtIndex) async {
    TrackService trackService = TrackService(trackAtIndex);
    await trackService.getTrack().then((r) {
      setState(() {
        
      });
    }).whenComplete(() {
      goTrackDetailPage(trackService);
    });

    // if (trackAtIndex.gpxFilePath != null) {
    //   // there is a gpx file with the track points
    //   await trackService.getTrack().then((r) {

    //   }).whenComplete(() {
    //     goTrackDetailPage(trackService);
    //   });
    // } else {
    //   await trackService.loadTrack(trackAtIndex);
    //   goTrackDetailPage(trackService);
    // }
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
                // child: Container(
                //   padding: EdgeInsets.only(top: 2.0),
                //   child: Text(snapshot.data[index].location),
                // ));
                child: Container(
                  padding: const EdgeInsets.only(top: 2.0),
                  height: 120,
                  //constraints: BoxConstraints(maxHeight: 200.0, minHeight: 100.0),
                  //constraints: BoxFit.fitHeight,
                  //height: double.infinity,
                  child: Card(child: InkWell(
                    onTap: () {
                      _handleTap(snapshot.data[index]);
                    },
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
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
                        style: TextStyle(fontSize: 22.0),
                        //style: Theme.of(context).textTheme.display1,
                      ),
                      subtitle: ListView(
                        scrollDirection: Axis.horizontal,
                        children: <Widget>[
                          Text(snapshot.data[index].location),
                        ],
                      ),
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


enum ListSortState {
  unsorted,
  alpabethicallyUp,
  alpabethicallyDown,
  dateUp,
  dateDown
}