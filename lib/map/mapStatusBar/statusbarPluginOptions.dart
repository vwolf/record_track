import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import '../mapTrack.dart';

class StatusbarLayerPluginOption extends LayerOptions {
  
  StatusbarEvent eventCallback;
  String type = "followTrack";
  Map<String, bool> state;
  bool offlineMode;
  bool location;
  //bool edit;

  StatusbarLayerPluginOption({
    this.eventCallback, 
    this.offlineMode, 
    this.location, 
    //this.edit,
    this.type,
    this.state});
}


class StatusbarPlugin implements MapPlugin {

  StatusbarLayer statusbarLayer;

  @override
  Widget createLayer(LayerOptions options, MapState mapState,
      Stream<Null> stream) {
    if (options is StatusbarLayerPluginOption) {
      statusbarLayer = StatusbarLayer(options, mapState, stream);
      return statusbarLayer;
    }
    throw Exception('Unkown options type for StatusbarLayerPlugin: $options');
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is StatusbarLayerPluginOption;
  }

  StatusbarLayer getStatusbarLayer() {
    return statusbarLayer;
  }

}

/// Statusbar has following icons:
/// - zoomIn
/// - zoomOut
/// - location
/// - offlineMode
/// - info
/// - edit
/// Display depending on map context: following track or tracking
///
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
              onPressed: () => statusBarEvent(StatusBarEvent.ZoomIn),
            ),
              IconButton(
                icon: Icon(Icons.zoom_out,
                  color: Colors.orange,
                  size: 36.0,
                ),
                onPressed: () => statusBarEvent(StatusBarEvent.ZoomOut),
              ),
              IconButton(
                icon: Icon(
                  statusbarLayerOpts.location ? Icons.location_on : Icons
                      .location_off,
                  color: Colors.orange,
                  size: 36.0,
                ),
                onPressed: () => statusBarEvent(StatusBarEvent.Location),
              ),
              IconButton(
                icon: Icon(Icons.offline_pin,
                  color: statusbarLayerOpts.offlineMode ? Colors.orange : Colors
                      .black26,
                  size: 36.0,
                ),
                onPressed: () => statusBarEvent(StatusBarEvent.OfflineMode),
              ),
              IconButton(
                icon: Icon(Icons.info,
                  color: Colors.orange,
                  size: 36.0,
                ),
                onPressed: () => statusBarEvent(StatusBarEvent.Info),
              ),
              IconButton(
                icon: Icon(Icons.edit,
                  color: statusbarLayerOpts.state['edit'] ? Colors.orange : Colors
                      .black26,
                  size: 36.0,
                ),
                onPressed: () => statusBarEvent(StatusBarEvent.Edit),
              ),
              IconButton(
                icon:Icon(Icons.add,
                  color: statusbarLayerOpts.state['add'] ? Colors.orange : Colors.black26,
                  size: 36.0,
                ),
                onPressed: () => statusBarEvent(StatusBarEvent.Add),
              ),
          ],
          )
        ],
      )
    );
  }

//  Widget get _followTrackIcons {
//    return Container(
//      color: Colors.white70,
//      child: Row(
//        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//        mainAxisSize: MainAxisSize.max,
//        children: <Widget>[
//          IconButton(
//            icon: Icon(Icons.zoom_in,
//              color: Colors.orange,
//              size: 36.0,
//            ),
//            onPressed: () => statusBarEvent(StatusBarEvent.ZoomIn),
//          ),
//          IconButton(
//            icon: Icon(Icons.zoom_out,
//              color: Colors.orange,
//              size: 36.0,
//            ),
//            onPressed: () => statusBarEvent(StatusBarEvent.ZoomOut),
//          ),
//        ],
//      ),
//    );
//  }

  /// ZoomIn, ZoomOut, OfflineMode, Location, Info,
//  Widget get _trackingIcons {
//    return Container(
//      color: Colors.white70,
//      child: Row(
//        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//        mainAxisSize: MainAxisSize.max,
//        children: <Widget>[
//          IconButton(
//            icon: Icon(Icons.zoom_in,
//              color: Colors.orange,
//              size: 36.0,
//            ),
//            onPressed: () => statusBarEvent(StatusBarEvent.ZoomIn),
//          ),
//          IconButton(
//            icon: Icon(Icons.zoom_out,
//              color: Colors.orange,
//              size: 36.0,
//            ),
//            onPressed: () => statusBarEvent(StatusBarEvent.ZoomOut),
//          ),
//        ],
//      ),
//    );
//  }

  statusBarEvent(StatusBarEvent event) {
    print("statusBarEvent $event");
  
    statusbarLayerOpts.eventCallback(event);
  }
}

enum StatusBarEvent {
  ZoomIn,
  ZoomOut,
  Location,
  OfflineMode,
  Info,
  Edit,
  Add,
}

// class StatusBar extends StatelessWidget {

//   @override 
//   Widget build(BuildContext context) {}
// }