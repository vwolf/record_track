import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import '../mapTrack.dart';

class StatusbarLayerPluginOption extends LayerOptions {
  
  StatusbarEvent eventCallback;
  bool offlineMode;
  bool location;
  bool edit;

  StatusbarLayerPluginOption( {this.eventCallback, this.offlineMode, this.location, this.edit } );
}


class StatusbarPlugin implements MapPlugin {

  @override 
  Widget createLayer(
    LayerOptions options,MapState mapState, Stream<Null> stream) {
      if (options is StatusbarLayerPluginOption) {
        return StatusbarLayer(options, mapState, stream);
      }
      throw Exception('Unkown options type for StatusbarLayerPlugin: $options');
  }

  @override 
  bool supportsLayer(LayerOptions options) {
    return options is StatusbarLayerPluginOption;
  }
}


class StatusbarLayer extends StatelessWidget {

  final StatusbarLayerPluginOption statusbarLayerOpts;
  final MapState map;
  final Stream<Null> stream;

  StatusbarLayer(
    this.statusbarLayerOpts,
    this.map,
    this.stream,
  );


  @override 
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white70,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Row(
            children: <Widget>[
              IconButton(
                icon: Icon(Icons.zoom_in,
                color: Colors.orange,
                size: 36.0,
              ),
              onPressed: () => statusBarEvent("zoom_in"),
            ),
            IconButton(
              icon: Icon(Icons.zoom_out,
              color: Colors.orange,
              size: 36.0,
              ),
              onPressed: () => statusBarEvent("zoom_out"),
            ),
            IconButton(
              icon: Icon(statusbarLayerOpts.location ? Icons.location_on : Icons.location_off,
              color: Colors.orange,
              size: 36.0,
              ),
              onPressed: () => statusBarEvent("location_on"),
            ),
            IconButton(
              icon: Icon(Icons.offline_pin,
              color: statusbarLayerOpts.offlineMode ? Colors.orange : Colors.black26,
              size: 36.0,
              ),
              onPressed: () => statusBarEvent("offlineMode"),
            ),
            IconButton(
              icon: Icon(Icons.info,
              color: Colors.orange,
              size: 36.0,
              ),
              onPressed: () => statusBarEvent("info"),
            ),
            IconButton(
              icon:Icon(Icons.edit,
              color: statusbarLayerOpts.edit ? Colors.orange : Colors.black26,
              size: 36.0,
            ),
            onPressed: () => statusBarEvent("edit"),
            
            ),
          ],
          )
        ],
      )
    );
  }

  statusBarEvent(String event) {
    statusbarLayerOpts.eventCallback(event);
  }
}


// class StatusBar extends StatelessWidget {

//   @override 
//   Widget build(BuildContext context) {}
// }