

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';

class StartTrackMap extends StatelessWidget {

  LatLng _center = LatLng(53.00, 13.00);
  BuildContext _context;

  StartTrackMap();
  
  @override
  Widget build(BuildContext context) {
    _context = context;
    return WillPopScope(
      onWillPop: _requestPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Select Start"),
        ),
        body: Column(
          children: <Widget>[
            Flexible(
              child: FlutterMap(
                options: MapOptions(
                  center: _center,
                  zoom: 13,
                  minZoom: 6,
                  maxZoom: 18, 
                  onTap: _handleTap,
                  
                ),
                layers: [
                  TileLayerOptions(
                    tileProvider: CachedNetworkTileProvider(),
                    urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
                    subdomains:  ['a', 'b', 'c'],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    // return Flexible(
    //   child: FlutterMap(
    //     options: MapOptions(
    //       center: _center,
    //       zoom: 13,
    //       minZoom: 6,
    //       maxZoom: 18, 
    //     ),
    //     layers: [
    //       TileLayerOptions(
    //         tileProvider: CachedNetworkTileProvider(),
    //         urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
    //         subdomains:  ['a', 'b', 'c'],
    //       ),
    //     ],
    //   ),
    // );
  }

  Future<bool> _requestPop() {
    Navigator.pop(_context, "no map location"); 
    return Future.value(true); 
  }


  void _handleTap(LatLng latlng) {
    print ("_handleTap at ${latlng.latitude}, ${latlng.longitude}");

    Navigator.pop(_context, latlng);
  }
}