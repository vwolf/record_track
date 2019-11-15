import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:record_track/readWrite/readFile.dart';
import 'package:record_track/services/geolocationService.dart';
import 'package:record_track/waypoint/waypoint.dart';

import '../track/trackService.dart';
import 'mapScale/scaleLayerPluginOptions.dart';
import 'mapStatusBar/statusbarPluginOptions.dart';
import 'mapMarkerDraggable/markerDraggableOptions.dart';
import 'mapInfoElement/infoModal.dart';
import 'package:record_track/services//directoryList.dart';
import 'package:record_track/services/settings.dart';
//import 'package:flutter_map/src/geo/crs/crs.dart';

//import 'package:record_track/waypoint/waypointModal.dart';
import 'package:record_track/db/models/trackItem.dart';

typedef StatusbarEvent = void Function(StatusBarEvent event);
typedef MapPathCallback = void Function(String mapPath);

/// Provide a map view using flutter_map package
/// Map view gets also a [StatusbarLayer] and a [ScaleLayer].
/// Own position: switch in [MapStatusLayer] and receive message via [StatusbarEvent]
/// In [switchGeolocation] subscribe to [GeoLocationService]
///
/// User Action on map
/// - select start or end point
/// - move start and end point
/// - select track segment
/// - 
class MapTrack extends StatefulWidget {
  final StreamController<TrackPageStreamMsg> streamController;
  final TrackService trackService;

  MapTrack(this.trackService, this.streamController);

  @override
  MapTrackState createState() => MapTrackState(trackService, streamController);
}

/// State for MapTrack page
///
class MapTrackState extends State<MapTrack> {

  TrackService trackService;
  StreamController<TrackPageStreamMsg> streamController = StreamController.broadcast();
  MapTrackState(this.trackService, this.streamController);

  MapController _mapController = MapController();

  StreamController geoLocationStreamController;

  LatLng get startPos => widget.trackService.getTrackStart();

  List<int> _activeMarker = [];
  //List<int> _editMarker = [];
  //List<LatLng> editMarkerLatLng = [];

  // status values
  bool _offline = false;
  bool _location = false;
  //bool _edit = false;

  // Map statusbar icons settings
  Map<String, bool> mapStatusbarState = {
    'offline' : false,
    'location' : false,
    'edit' : false,
    'add' : false,
    'info' : true,
    'zoomIn' : true,
    'zoomOut' : true,
  };

  LatLng _currentPosition;

  Key _mapOptionKey = new Key("mapOptionkey");
  //ObjectKey _objectKey = new ObjectKey("objectKey");
  //LocalKey _localKey = LocalKey();

  /// This is the callback for the statusbar
  StatusbarEvent statusbarCall;
  // track modified - save or reload?
  bool trackModFlag = false;

  InfoModal _infoModal = InfoModal(
      point: LatLng(0.0, 0.0),
      color: Colors.blue.withOpacity(0.8),
      borderStrokeWidth: 1.0,
      // useRadiusInMeter: true,
      size: Size(100.0, 50.0),
  );
  LatLng _infoModalPosition;

  
  /// For persistent bottomsheet
  //final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  //PersistentBottomSheetController _persistentBottomSheetController;

  /// callback function
  MapPathCallback setMapPath;

  /// last map position
  MapPosition _mapPosition;

  void initState() {
    super.initState();
    initStreamController();
    setMapPath = getMapPath;
  }

  @override 
  void dispose() {
    if (streamController != null) {
      streamController.close();
    }
    if (geoLocationStreamController != null) {
      geoLocationStreamController.close();
    } 
    if (trackModFlag == true) {
      trackService.saveTrack();
    }
    super.dispose();
  }

  initStreamController() {
    streamController.stream.listen((TrackPageStreamMsg mapPageStreamMsg) {
      onMapPageEvent(mapPageStreamMsg);
    }, onDone: () {
      print("MapTrack TrackPageStreamMsg Done");
    }, onError: (e) {
      print('MapTrack StreamController error $e');
    });
  }

  /// Touch events from map (status layer or marker).
  /// Registered at initStreamController
  /// 
  /// [TrackPageStreamMsg] trackPageStreamMsg
  onMapPageEvent(TrackPageStreamMsg trackPageStreamMsg) {
    print("MapTrack.onMapPageEvent ${trackPageStreamMsg.type}");
    switch (trackPageStreamMsg.type) {
      case TrackPageStreamMsgType.UpdateTrack: 
      setState(() {
        
      });
      break;
      default: break;
    }
  }


  @override 
  Widget build(BuildContext context) {
    return Flexible(
      
      child: FlutterMap(
        mapController: _mapController,
        key: _mapOptionKey,
        options: MapOptions(
          center: startPos,
          zoom: 13,
          minZoom: 3,
          maxZoom: 19,
          onTap: _handleTap,
          onLongPress: _handleLongPress,
          onPositionChanged: _handlePositionChange,
          //onTapUp: _handleTapUp,
          plugins: [
            ScaleLayerPlugin(),
            StatusbarPlugin(),
            MarkerDraggablePlugin(),
            _infoModal,
          ],
        ),
        
        layers: [
          TileLayerOptions(
            tileProvider: _offline ? FileTileProvider() : CachedNetworkTileProvider(),
            urlTemplate: _offline ? "${trackService.pathToOfflineMap}/{z}/{x}/{y}.png" : "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: _offline ? const <String>[] : ['a', 'b', 'c'],
          ),
          ScaleLayerPluginOption(
            lineColor: Colors.blue,
            lineWidth: 3,
            textStyle: TextStyle(color: Colors.blue, fontSize: 12),
            padding: EdgeInsets.all(10),
          ),
          
          PolylineLayerOptions(
            polylines: [
              Polyline(
                points: trackService.trackLatLngs,
                strokeWidth: 4.0,
                color: Colors.blueAccent,
              )
            ],
            onTap: (Polyline polyline, LatLng latlng, int polylineIdx) => _handleTapOnPolyline("track", polyline, latlng, polylineIdx),
            onLongPress: (Polyline polyline, LatLng latlng, int polylineIdx) => _handleLongPressOnPolyline("track", polyline, latlng, polylineIdx),
          ),
          
          MarkerLayerOptions(
            markers: gpsPositionList 
          ),

          MarkerLayerOptions(
            markers: trackStartEndMarker
          ),

          MarkerLayerOptions(
            markers: itemMarker
          ),
//          InfoModalLayerOptions(
//            infoElements: infoModal,
//
//          ),

          StatusbarLayerPluginOption(
            eventCallback: statusbarCallback,
            offlineMode: _offline,
            location: _location,
            //edit: _edit,
            state: mapStatusbarState,
          ),
          // MarkerLayerOptions(
          //   markers: gpsPositionList 
          // ),
          // MarkerLayerOptions(
          //   markers: trackStartEndMarker
          // ),
          // MarkerLayerOptions(
          //   //markers: editMarker
          //   markers: moveMarker
          // )
          /// Here we use a extra layer for draggable points
          /// Works also with normal [Marker] layer.
          /// 
          MarkerDraggableLayerPluginOptions(
            markers: draggableMarker,
          ),
          /// InfoModalLayer is blocking Statusbar, sort layer in some way
          /// InfoModalLayer should be on top of track and marker layers
          /// This happens only in simulator?
          // InfoModalLayerOptions(
          //   infoElements: infoModal
          // ),
        ], 
      ),
    );
  }


  /// Tap on map (not on marker or polyline). 
  /// 
  /// Edit mode: 
  /// - on tap add to new point to track
  /// - [trackService.selectedTrackPoints] length > 0 then deselect track points
  /// 
  void _handleTap(LatLng latlng) async {
    print("mapTrack._handleTap ");
    if (mapStatusbarState['edit'] && _activeMarker.length == 1) {
      if ( _activeMarker[0] == trackService.trackLatLngs.length - 1 ) {
        await trackService.addPointToTrack(latlng).whenComplete(() {
          setState(() {
            _activeMarker[0] += 1;
          });
          return;
        });
        //return;
      }
    }

    /// Close bottomSheet edit
    if (mapStatusbarState['edit'] && trackService.selectedTrackPoints.isNotEmpty) {
      trackService.selectedTrackPoints = [];
      streamController.add(TrackPageStreamMsg(TrackPageStreamMsgType.PathOptions, "close"));
      setState(() {
        
      });
    }

    if (_infoModalPosition != null) {
      setState(() {
         _infoModalPosition = LatLng(0.0, 0.0);
      });
    }

    if (mapStatusbarState['add']) {
      print( "Add waypoint item");
      addWayPoint(latlng);

    }
  }

  void _handleTapUp() {}


  /// Tap on map marker.
  /// StartMarker: option to change track start coords
  /// 
  void _handleTapOnMarker(LatLng latlng, int index) {
    debugPrint("_handleTapOnMarker at index: $index");
    // start marker select / deselect
    if (_activeMarker.contains(index)) {
      _activeMarker.remove(index);
    } else {
      _activeMarker = [];
      _activeMarker.add(index);
      if (trackService.selectedTrackPoints.isNotEmpty) {
        trackService.selectedTrackPoints = [];
      }
    }

    setState(() {});
  }

  /// Tap on [TrackItem] marker
  /// Display item
  /// Option to edit item
  void _handleTapOnItem(int index) async {
    TrackItem item = trackService.trackItems[index];
    WayPoint wayPoint = WayPoint.withItem(item);

    if (!mapStatusbarState["add"]) {
      await wayPoint.triggerDialog(context, "show").then((result) {

      });
    } else {
      await wayPoint.triggerDialog(context, "update").then((result) {
        if (result is TrackItem) {
          print ("Update item: ${result.name}");
          trackService.updateTrackItem(wayPoint.item);
        }

        if (result == "DELETE") {
          print("Delete item");
          trackService.deleteTrackItem(wayPoint.item).then((result) {
            print("TrackItem deleteted!");
            setState(() {
              itemMarker;
            });
          });
        }
      });
    }

  }


  /// Long tap on map
  /// If first [Marker] of [Track] is in [_activeMarker] List and
  /// [_edit] is true, change first [Marker] (Start of track).
  /// 
  /// If last [Marker] of [Track] is the only entry in [_activeMarker] list and
  /// [_edit] is true, change last [Marker] (End of track).
  /// 
  /// Edit track segment if [_editMarker] contains the start and end point. 
  void _handleLongPress(LatLng latlng) {
    print("mapTrack._handleLongPress at $latlng");
    if ( _activeMarker.length == 1 && mapStatusbarState['edit']) {
      if (_activeMarker.contains(0)) {
        trackService.setTrackStart(latlng);
        setState(() {
          trackModFlag = true;
        });
        return;
      }
      if (_activeMarker[0] == trackService.trackLatLngs.length - 1) {
        trackService.trackLatLngs.last.latitude = latlng.latitude;
        trackService.trackLatLngs.last.longitude = latlng.longitude;
        setState(() {
          trackModFlag = true;
        });
        return;
      }
    }

    if ( trackService.selectedTrackPoints.length == 2 ) {
      /// Here we open a Modal, BottomSheet, Snackbar... ?
      /// Send message to page to show a [PersistentBottomSheet].
      /// 
      print("LatLng at _handleLongPress ${latlng.latitude}, ${latlng.longitude}");
      streamController.add(TrackPageStreamMsg(TrackPageStreamMsgType.PathOptions, "edit"));
      
      // setState(() {
      //   _infoModalPosition = latlng;
      // });
    }
    
  }


  /// Edit mode: 
  /// Tap on polyline segment in map will 
  /// add select start and end point of [Track] segment.
  /// Deselect any selected marker.
  /// 
  /// Info mode: 
  /// Tap on polyline segment in map will 
  /// select nearest track point and show info modal for point.
  ///
  /// Add/Update item mode:
  ///
  /// to [trackService.selectedTrackPoints]. 
  /// @param type [String] = track - tap on polyline
  /// @param polyline [Polyline]
  /// @param latlng [LatLng]
  /// @param polylineIdx [int]  
  /// 
  _handleTapOnPolyline(type, polyline, LatLng latlng, polylineIdx) {
    print("_onTap on $type at segment $polylineIdx");
    if (mapStatusbarState['edit'] == false && mapStatusbarState['add'] == false) {
      setState(() {
        trackService.selectedTrackPoints = [polylineIdx];
        _infoModalPosition = latlng;
      });
      return; 
    }

    // point is on track polyline
    if (mapStatusbarState["add"] == true) {
      addWayPoint(latlng);
      return;
    }

    // when mapStatusbarState['edit'] is true
    // start and end point of segment
    // select point closest to tap
    if (trackService.trackLatLngs.length > polylineIdx) {

      LatLng segmentStart = trackService.trackLatLngs[polylineIdx];
      LatLng segmentEnd = trackService.trackLatLngs[polylineIdx + 1];
      print("segmentStart at ${segmentStart.latitude.toStringAsFixed(4)}, ${segmentStart.longitude.toStringAsFixed(4)}");
      print("segmentEnd at ${segmentEnd.latitude.toStringAsFixed(4)}, ${segmentEnd.longitude.toStringAsFixed(4)}");

      // which segment point is closest to tap
      // distance segment
      Geolocator().distanceBetween(segmentStart.latitude, segmentStart.longitude, segmentEnd.latitude, segmentEnd.longitude).then((distance) {
        // distance from segment start to tap
        Geolocator().distanceBetween(segmentStart.latitude, segmentStart.longitude, latlng.latitude, latlng.longitude).then((distanceFromStart) {
          if (distanceFromStart < distance / 2) {
            print("Close to start point");
            trackService.selectedTrackPoints = [polylineIdx];
          } else {
            trackService.selectedTrackPoints = [polylineIdx + 1];
          }
        });
      });

      if (_activeMarker.length > 0) {
        _activeMarker = [];
      }

      setState(() {});

    } else {
      print("No segmentEnd");
    }
    
  }

  _handleLongPressOnPolyline(type, polyline, LatLng latlng, polylineIdx) {
    print("longPress on polyline at index $polylineIdx");
  }


  /// Call [WayPoint]. If [TrackItem] returns, add to db
  ///
  addWayPoint(LatLng latlng, {bool update: false}) async {
    WayPoint wayPoint = WayPoint();

    await wayPoint.triggerDialog(context, "trackItem").then((result) {
      if (result is TrackItem) {
        print (result.timestamp);
        result.latlng = jsonEncode( {"lat": latlng.latitude, "lon": latlng.longitude} );
        trackService.addItemToTrack(wayPoint.item);
      }

    });
  }

  /// Map is moving.
  /// If a track point is selected, then
  void _handlePositionChange(MapPosition mapPosition, bool hasGesture) {
    if (trackService.selectedTrackPoints.isNotEmpty) {
      print("handlePositionChange");
      print("mapPosition: ${mapPosition.center}");
      if (_mapPosition == null) {
        _mapPosition = mapPosition;
      } else {
        double _positionOffsetLat = mapPosition.center.latitude -
            _mapPosition.center.latitude;
        double _positionOffsetLon = mapPosition.center.longitude -
            _mapPosition.center.longitude;
        _mapPosition = mapPosition;
        print(
            "position change lat: $_positionOffsetLat lon: $_positionOffsetLon");
        Point p = Point(_positionOffsetLat, _positionOffsetLon);
        trackService.moveTrackPoint(trackService.selectedTrackPoints[0], p);
      }
    }

  }


  Color _getMarkerIconColor(int markerIndex) {
    if (_activeMarker.contains(markerIndex)) {
      return Colors.redAccent;
    }

    return Colors.green;
  }

  /// Event [StatusBarEvent] from [StatusbarLayer].
  /// 
  /// - [StatusBarEvent.ZoomIn], [StatusBarEvent.ZoomOut]: 
  /// - [StatusBarEvent.Location]: toogle gps tracking mode [_location] in switchLocation
  /// - [StatusBarEvent.OfflineMode]: 
  /// - [StatusBarEvent.Info] : stream msg to [MapPage]. 
  /// - [StatusBarEvent.Edit]: toogle track edit mode
  void statusbarCallback(StatusBarEvent event) {
    debugPrint("statusbarCall $event");

    switch (event) {
      case StatusBarEvent.ZoomIn :
      setState(() {
        _mapController.move(_mapController.center, _mapController.zoom + 1.0);
      });
      debugPrint("zoom: ${_mapController.zoom}");
      break;

      case StatusBarEvent.ZoomOut :
      setState(() {
       _mapController.move((_mapController.center), _mapController.zoom - 1.0);
      });
      break;

      // geolocation tracking switch
      case StatusBarEvent.Location :
      setState(() {
        _location = !_location;
        switchLocation();
      });
      break;

      case StatusBarEvent.OfflineMode : 
        if (trackService.track.offlineMapPath == null) {
          // user must set path to offline map tiles
          openFileIO();
        } else {
          trackService.pathToOfflineMap = trackService.track.offlineMapPath;

          setState(() {
            _offline = !_offline;
            //_mapStatusLayer.statusNotification(event.msg, _offline);
            //trackService.getTrackBoundingCoors();
          });
        }
      
      break;

      case StatusBarEvent.Info :
      streamController.add(TrackPageStreamMsg(TrackPageStreamMsgType.InfoBottomSheet, "open"));
      break;

      /// edit option only possible if track data in db
      /// ToDo: Modify gpx file directly?
      case StatusBarEvent.Edit :
        if (trackService.trackSource != TrackSource.DB) {
          print("Edit mode only possible if track source is DB");
          notificationDialog();
          break;
        }
        setState(() {
          //_edit = !_edit;
          mapStatusbarState['edit'] = !mapStatusbarState['edit'];
          trackService.selectedTrackPoints = [];
          _activeMarker = [];
          if (!mapStatusbarState['edit']) {
            streamController.add(TrackPageStreamMsg(TrackPageStreamMsgType.PathOptions, "close"));
          }
          if ( mapStatusbarState['add'] && mapStatusbarState['edit'] ) {
            mapStatusbarState['add'] = false;
          }
        });

        break;

      case StatusBarEvent.Add :
        setState(() {
          mapStatusbarState['add'] = !mapStatusbarState['add'];
          if (mapStatusbarState['edit'] && mapStatusbarState['add'] ) {
            mapStatusbarState['edit'] = false;
          }
        });

        break;
    }
  }

  /// Switch use of offline map 
  switchOfflineMode() {}

  /// Switch the display of current position.
  /// Subscribe / Unsubscribe to geoLocationStream in [Geolocation]
  /// 
  switchLocation() {
    if( _location ) {
      geoLocationStreamController = StreamController();
      geoLocationStreamController.stream.listen((coords) {
        onGeoLocationEvent(coords);
      });
      GeoLocationService.gls.subscribeToPositionStream(geoLocationStreamController);
    } else {
      GeoLocationService.gls.unsubcribeToPositionStream();
      
    }
  }

  /// Current geo location from [GeoLocationService] as [Position].
  /// Update [gpsPositionList] and center map on [currentPosition].
  /// Add [coords] to [lastPositions] in [trackService]
  onGeoLocationEvent(Position coords) {
    if(_location) {
      _currentPosition = LatLng(coords.latitude, coords.longitude);
      setState(() {
        gpsPositionList;
        _mapController.move(_currentPosition, _mapController.zoom);
      });
    }
  }

  /// Return current position as marker
  /// 
  List<Marker> get gpsPositionList => makeGpsPositionList();

  List<Marker> makeGpsPositionList() {
    List<Marker> ml = [];

    if (_location && _currentPosition != null) {
      Marker newMarker = Marker(
        width: 40.0,
        height: 40.0,
        point: _currentPosition,
        builder: (ctx) => 
          Container(
            child: Icon(
              Icons.location_searching,
              color: Colors.red,
            ),
          )
        );
        ml.add(newMarker);
    }
    return ml;
  }

  List<Marker> get trackStartEndMarker => makeTrackStartEndMarker();

  List<Marker> makeTrackStartEndMarker() {
    List<Marker> ml = [];

    if (trackService.trackLatLngs.length > 0) {
      Marker newMarker = Marker(
        width: 40.0,
        height: 40.0,
        point: trackService.trackLatLngs.first,
        builder: (ctx) =>
          Container(
            child: GestureDetector(
              onTap: () {
                _handleTapOnMarker(trackService.trackLatLngs.first, 0);
              },
              child: Icon(
                Icons.fiber_manual_record,
                color: _getMarkerIconColor(0),
                size: 18.0,
              ),
            )
          )
        );
        ml.add(newMarker);
    }
    // end marker
    if (trackService.trackLatLngs.length > 1) {
      Marker newMarker = Marker(
        point: trackService.trackLatLngs.last,
        builder: (ctx) => 
          Container(
            child: GestureDetector(
              onTap: () {
                _handleTapOnMarker(trackService.trackLatLngs.last, trackService.trackLatLngs.length - 1);
              },
              child: Icon(
                Icons.fiber_manual_record,
                color: _getMarkerIconColor(trackService.trackLatLngs.length -1),
                size: 18.0,
              ),
            )
          )
      );
      ml.add(newMarker);
    }
    return ml;
  }


  List<Marker> get itemMarker => makeItemMarker();

  List<Marker> makeItemMarker() {
    List<Marker> ml = [];

    if (trackService.trackItems.length > 0) {
      for (int i = 0; i < trackService.trackItems.length; i++) {
        Marker newMarker = Marker(
          width: 60.0,
          height: 60.0,
          point: trackService.latLngJsonToLatLng(trackService.trackItems[i].latlng),
          builder: (ctx) =>
              Container(
                child: GestureDetector(
                  onTap: () {
                    _handleTapOnItem(i);
                  },
                  child: Icon(
                    Icons.edit_location,
                    color: Colors.blueAccent,
                  ),

                ),
              )
        );
        ml.add(newMarker);
      }
    }
    return ml;
  }



  List<MarkerDraggable> get draggableMarker => makeDraggableMarker();
  List<MarkerDraggable> makeDraggableMarker() {
    List<MarkerDraggable> ml = [];
      if (trackService.selectedTrackPoints.isNotEmpty) {
        for (int i = 0; i < trackService.selectedTrackPoints.length; i++) {
          MarkerDraggable newMarker = MarkerDraggable(
            width: 30.0,
            height: 30.0,
            point: trackService.trackLatLngs[trackService.selectedTrackPoints[i]],
            builder: (ctx) => 
              Container(
                child: GestureDetector(
                  child: Draggable(
                    data: "dragData",
                    child: Icon(
                      Icons.fiber_manual_record,
                      color: Colors.deepOrange,
                      size: 24.0,
                    ),
                    feedback: Icon(
                      Icons.donut_large,
                      color: Colors.blueAccent,
                      size: 32.0,
                    ),
                    onDraggableCanceled: (a, b) => _dragCanceled(a, b, i),
                  ),
                  
                )
              ) 
          );
          ml.add(newMarker);
        }
      }
    return ml;
  }



  

  //_dragStarted(int index) {}
  //_dragComplete() {}

  /// DragCancel to react on drag end, there is no drag target
  /// [Offset] [off.dx] and [off.dy] needs to be an offset.
  /// Offset value? This is the result of some test.
  ///  
  _dragCanceled(Velocity vel, Offset off, int index) async {
    print("_dragCanceled ${off.distance}");
    
    var renderObject = context.findRenderObject() as RenderBox;
    var width = renderObject.size.width;
    var height = renderObject.size.height;

    // _offsetToPoint
    var localPoint = CustomPoint(off.dx, off.dy) + CustomPoint(12, -68);
    var localPointCenterDistance = 
      CustomPoint((width / 2) - localPoint.x, (height / 2) - localPoint.y);
    // get map center
    LatLng mapCenterLatLng = _mapController.center;
    var mapCenter = Epsg3857().latLngToPoint(mapCenterLatLng, _mapController.zoom);
    
    var point = mapCenter - localPointCenterDistance;
    var finalPos = Epsg3857().pointToLatLng(point, _mapController.zoom);

    int posIndex = trackService.selectedTrackPoints[index];
    
    await trackService.changeTrackPointCoord(posIndex, finalPos).then((r) {
      print("changeTrackPointCoord with $r");
      if (r == 0) {
        // error saving new trackpoint coords
        print("Error saving changed track point!");
      } else {
        setState(() {});
      }
    });

    
  }

  //_dragEnd(LatLng position) {}


  List<InfoModal> get infoModal => makeInfoModal();

  List<InfoModal> makeInfoModal() {

    var infoModal = <InfoModal>[
      InfoModal(
        point: _infoModalPosition != null ? _infoModalPosition : LatLng(0.0, 0.0),
        color: Colors.white.withOpacity(0.8),
        borderStrokeWidth: 1.0,
        borderColor: Colors.black,
        size: Size(200.0, 50.0),
        infoText: "infoText"
      )
    ];
    return infoModal;
  }


  /// Show dialog
  Future notificationDialog() async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: Text("Editing of tracks read from file not possible!"),
            children: <Widget>[
              SimpleDialogOption(
                child: Text("Ok"),
                onPressed: () {
                  Navigator.pop(context);
                },
              )
            ],
          );
        });
  }


  // openPersistenBottomSheet() async {
  //   if (_persistentBottomSheetController == null) {
  //     Scaffold cState = context.ancestorWidgetOfExactType(Scaffold);
  //     _persistentBottomSheetController = 
  //       cState.{
  //         return _pathOptionSheet;
  //       });
  //   } else {
  //     _persistentBottomSheetController.close();
  //     await _persistentBottomSheetController.closed;
  //     _persistentBottomSheetController = null;
  //   }
  // }

  // Widget get _pathOptionSheet {
  //   return Container();
  // }

  /// Open a kind of directory browser to select the director which contains the map tiles
  ///
  /// ToDo Open in a new page?
  openFileIO() async {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) {
          return DirectoryList(setMapPath, Settings.settings.externalSDCard);
        })
    );
  }

  /// Callback offline map directory selection
  /// There was already a basic check if valid directory
  ///
  void getMapPath(String mapPath) {
    print("mapPath: $mapPath");
    setState(() {
      trackService.pathToOfflineMap = mapPath;
      _offline = !_offline;
      //_mapStatusLayer.statusNotification("offline_on", _offline);

    });

    // add the path to offline map tiles to settings file
    ReadFile().addToJson("tracksSettings.txt", trackService.track.name, mapPath);
    // update track
    trackService.track.offlineMapPath = mapPath;
  }
}