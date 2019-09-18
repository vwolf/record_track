import 'dart:async';
import 'package:flutter/material.dart';
//import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:record_track/services/geolocationService.dart';

import '../track/trackService.dart';
import 'mapScale/scaleLayerPluginOptions.dart';
import 'mapStatusBar/statusbarPluginOptions.dart';

typedef StatusbarEvent = void Function(String event);

/// Provide a map view using flutter_map package
/// Map view gets also a [StatusbarLayer] and a [ScaleLayer].
/// Own position: switch in [MapStatusLayer] and receive message via [StatusbarEvent]
/// In [switchGeolocation] subscribe to [GeoLocationService]
///
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
  StreamController streamController;
  MapTrackState(this.trackService, this.streamController);

  MapController _mapController = MapController();

  StreamController geoLocationStreamController;

  LatLng get startPos => widget.trackService.getTrackStart();

  List<int> _activeMarker = [];

  // status values
  bool _offline = false;
  bool _location = false;
  bool _edit = false;

  LatLng _currentPosition;

  /// This is the callback for the statusbar
  StatusbarEvent statusbarCall;
  // track modified - save or reload?
  bool trackModFlag = false;

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

  @override 
  Widget build(BuildContext context) {
    return Flexible(
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: startPos,
          zoom: 13,
          minZoom: 3,
          maxZoom: 19,
          onTap: _handleTap,
          onLongPress: _handleLongPress,
          onPositionChanged: _handlePositionChange,
          plugins: [
            ScaleLayerPlugin(),
            StatusbarPlugin(),
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
            ]
          ),
          StatusbarLayerPluginOption(
            eventCallback: statusbarCallback,
            offlineMode: _offline,
            location: _location,
            edit: _edit,
          ),
          MarkerLayerOptions(
            markers: gpsPositionList 
          ),
          MarkerLayerOptions(
            markers: trackStartEndMarker
          )
        ], 
      ),
    );
  }


  /// Tap on map (not on marker or polyline). 
  /// 
  /// Edit mode: 
  /// - on tap add to new point to track
  /// - 
  void _handleTap(LatLng latlng) async {
    print("mapTrack._handleTap ");
    if (_edit && _activeMarker.length == 0) {
      trackService.addPointToTrack(latlng);
      setState(() {
        
      });
    }
  }

  /// Tap on map marker.
  /// StartMarker: option to change track start coords
  /// 
  void _handleTapOnMarker(LatLng latlng, int index) {
    debugPrint("_handleTapOnMarker at index: $index");
    // start marker select / deselect
    if (_activeMarker.contains(index)) {
      _activeMarker.remove(index);
    } else {
      _activeMarker.add(index);
    }

    setState(() {
        
      });
  }

  /// Long tap on map
  void _handleLongPress(LatLng latlng) {
    print("mapTrack._handleLongPress at $latlng");
    if(_activeMarker.contains(0) && _edit) {
      widget.trackService.setTrackStart(latlng);
      setState(() {
        trackModFlag = true;
      });
    }
  }


  void _handlePositionChange(MapPosition mapPosition, bool hasGesture) {
    //_mapStatusLayer.zoomNotification(_mapController.zoom.toInt());
  }

  Color _getMarkerIconColor(int markerIndex) {
    if (_activeMarker.contains(markerIndex)) {
      return Colors.redAccent;
    }

    return Colors.green;
  }


  void statusbarCallback(String event) {
    debugPrint("statusbarCall $event");

    switch (event) {
      case "zoom_in" :
      setState(() {
        _mapController.move(_mapController.center, _mapController.zoom + 1.0);
      });
      debugPrint("zoom: ${_mapController.zoom}");
      break;

      case "zoom_out" :
      setState(() {
       _mapController.move((_mapController.center), _mapController.zoom - 1.0);
      });
      break;

      // geolocation tracking switch
      case "location_on" :
      setState(() {
        _location = !_location;
        switchLocation();
      });
      break;

      case "offlineMode" : 
      break;

      case "info" :
      break;

      case "edit" :
      setState(() {
        _edit = !_edit;
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
                Icons.pin_drop,
                color: _getMarkerIconColor(0),
              ),
            )
          )
        );
        ml.add(newMarker);
    }

    return ml;
  }


}