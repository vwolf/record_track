import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:record_track/track/trackService.dart';


class MapTracking extends StatefulWidget {

  final StreamController<TrackPageStreamMsg> streamController;
  final TrackService trackService;

  MapTracking( this.streamController, this.trackService);

  @override 
  MapTrackingState createState() => MapTrackingState();
}

class MapTrackingState extends State<MapTracking> {

  /// MapController
  MapController mapController;

  LatLng get startPos => widget.trackService.getTrackStart();
  @override 
  void initState() {
    super.initState();
  }

  @override 
  void dispose() {
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Flexible(
      child: FlutterMap(
        mapController: mapController,
        options: MapOptions(
          center: startPos,
          zoom: 15,
          minZoom: 4,
          maxZoom: 18,
        ),
        layers: [
          TileLayerOptions(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
        ],)
    );
  }

}