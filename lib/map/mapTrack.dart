import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart';

import '../track/trackService.dart';
import 'mapScale/scaleLayerPluginOptions.dart';

// Provide a map view using flutter_map package
///
/// Own position: switch in [MapStatusLayer] and receive message in [streamEvent]
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
  //MapStatusLayer _mapStatusLayer = MapStatusLayer(false, false, "...", false);
  
  LatLng get startPos => widget.trackService.getTrackStart();

  // status values
  bool _offline = false;
  bool _location = false;

  @override 
  Widget build(BuildContext context) {
    return Flexible(
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: startPos,
          zoom: 13,
          minZoom: 3,
          maxZoom: 18,
          onTap: _handleTap,
          onLongPress: _handleLongPress,
          onPositionChanged: _handlePositionChange,
          plugins: [
            ScaleLayerPlugin(),
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
            lineWidth: 2,
            textStyle: TextStyle(color: Colors.blue, fontSize: 12),
            padding: EdgeInsets.all(10),
          )
        ], 
      ),
    );
  }


/// Tap on map (not on marker or polyline)
///
void _handleTap(LatLng latlng) async {}

void _handleLongPress(LatLng latlng) {
  print("_handleLongPress at $latlng");
}

void _handlePositionChange(MapPosition mapPosition, bool hasGesture) {
  //_mapStatusLayer.zoomNotification(_mapController.zoom.toInt());
}

}