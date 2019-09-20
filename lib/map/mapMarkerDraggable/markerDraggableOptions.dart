import 'package:flutter/material.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart';


class MarkerDraggableLayerPluginOptions extends LayerOptions {
  final List<MarkerDraggable> markers;

  MarkerDraggableLayerPluginOptions( {
    this.markers = const [],
    rebuild
  }) : super(rebuild: rebuild);
}


class AnchorDraggable {
  final double left;
  final double top;

  AnchorDraggable(this.left, this.top);

  AnchorDraggable._(double width, double height, AnchorDraggableAlign alignOpt)
    : left = _leftOffset(width, alignOpt),
      top = _topOffset(height, alignOpt);

  static double _leftOffset(double width, AnchorDraggableAlign alignOpt) {
    switch (alignOpt) {
      case AnchorDraggableAlign.left: 
      return 0.0;
      case AnchorDraggableAlign.right:
      return width;
      case AnchorDraggableAlign.top: 
      case AnchorDraggableAlign.bottom:
      case AnchorDraggableAlign.center:

      default: 
      return width / 2;
    }
  }

  static double _topOffset(double height, AnchorDraggableAlign alignOpt) {
    switch (alignOpt) {
      case AnchorDraggableAlign.top:
        return 0.0;
      case AnchorDraggableAlign.bottom:
        return height;
      case AnchorDraggableAlign.left:
      case AnchorDraggableAlign.right:
      case AnchorDraggableAlign.center:
      default:
        return height / 2;
    }
  }

  factory AnchorDraggable.forPos(AnchorDraggablePos pos, double width, double height) {
    if (pos == null) return AnchorDraggable._(width, height, null);
    if (pos.value is AnchorAlign) return AnchorDraggable._(width, height, pos.value);
    if (pos.value is Anchor) return pos.value;
    throw Exception('Unsupported AnchorDragggablePos value type: ${pos.runtimeType}');
  }
}



class AnchorDraggablePos<T> {
  AnchorDraggablePos._(this.value);
  T value;
  static AnchorDraggablePos exactly(AnchorDraggable anchor) => AnchorDraggablePos._(anchor);
  static AnchorDraggablePos align(AnchorDraggableAlign alignOpt) => AnchorDraggablePos._(alignOpt);
}

enum AnchorDraggableAlign {
  left,
  right,
  top,
  bottom,
  center
}

class MarkerDraggable {
  final LatLng point;
  final WidgetBuilder builder;
  final double width;
  final double height;
  final AnchorDraggable anchor;

  MarkerDraggable({
    this.point,
    this.builder,
    this.width = 30.0,
    this.height = 30.0,
    AnchorDraggablePos anchorPos
  }) : anchor = AnchorDraggable.forPos(anchorPos, width, height);
}


class MarkerDraggablePlugin implements MapPlugin {

  @override 
  Widget createLayer(
    LayerOptions options, MapState mapState, Stream<Null> stream
  ) {
    if (options is MarkerDraggableLayerPluginOptions) {
      return MarkerDraggableLayer(options, mapState, stream);
    }
    throw Exception('Unkown options type for MarkerDraggablePlugin');
  }

  @override 
  bool supportsLayer(LayerOptions options) {
    return options is MarkerDraggableLayerPluginOptions;
  }
}


class MarkerDraggableLayer extends StatelessWidget {

  final MarkerDraggableLayerPluginOptions markerOpts;
  final MapState map;
  final Stream<Null> stream;

  MarkerDraggableLayer(
    this.markerOpts,
    this.map,
    this.stream,
  );


  bool _boundsContainsMarker(MarkerDraggable marker) {

    var pixelPoint = map.project(marker.point);

    final width = marker.width - marker.anchor.left;
    final height = marker.height - marker.anchor.top;

    var sw = CustomPoint(pixelPoint.x + width, pixelPoint.y -height);
    var ne = CustomPoint(pixelPoint.x - width, pixelPoint.y + height);

    return map.pixelBounds.containsPartialBounds(Bounds(sw, ne));
  }

  @override 
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
        var markers = <Widget>[];
        for (var markerOpt in markerOpts.markers) {
          var pos = map.project(markerOpt.point);
          pos = pos.multiplyBy(map.getZoomScale(map.zoom, map.zoom)) - 
            map.getPixelOrigin();
          
          var pixelPosX = (
            pos.x - (markerOpt.width - markerOpt.anchor.left)).toDouble();

          var pixelPosY = (
            pos.y -  (markerOpt.height - markerOpt.anchor.top)).toDouble();

          if (!_boundsContainsMarker(markerOpt)) {
            continue;
          }

          markers.add(
            Positioned(
              width: markerOpt.width,
              height: markerOpt.height,
              left: pixelPosX,
              top: pixelPosY,
              child: markerOpt.builder(context),
            ),
          );
        }
        return Container(
          child: Stack(
            children: markers,
          ),
        );

      }
    );
  }


}