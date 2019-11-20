

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map/plugin_api.dart';
import 'package:latlong/latlong.dart';

class InfoModalLayerOptions extends LayerOptions {
  final List<InfoModal> infoElements;
  final MapState mapState;

  InfoModalLayerOptions({
    this.infoElements,
    this.mapState, 
    rebuild
  }) : super(rebuild: rebuild);
}


class InfoModal implements MapPlugin {
  final LatLng point;
  final Size size;
  final Color color;
  final double borderStrokeWidth;
  final Color borderColor;
  final String infoText;
  final bool visible;

  Offset offset = Offset.zero;
  CustomPoint tapPosition; 
  num realRadius = 0;


  InfoModal({
    this.point,
    this.size, 
    this.color,
    this.borderStrokeWidth,
    this.borderColor,
    this.infoText,
    this.visible,
  });

  @override 
  Widget createLayer(
    LayerOptions options, MapState state, Stream<Null> stream) {
    if (options is InfoModalLayerOptions) {
      return InfoModalLayer(options, state, stream);
    }
    throw Exception('Unkown options type for StatusbarLayerPlugin: $options');
  }

  @override 
  bool supportsLayer(LayerOptions options) {
    return options is InfoModalLayerOptions;
  }
}


class InfoModalLayer extends StatelessWidget {
  final InfoModalLayerOptions layerOptions;
  final MapState mapState;
  final Stream<Null> stream;

  InfoModalLayer(this.layerOptions, this.mapState, this.stream);

  @override 
  Widget build(BuildContext context) {
    // return SizedBox(
    //   height: 200,
    //   width: 200,
    //   child: LayoutBuilder(
    //     builder: (BuildContext context, BoxConstraints bc) {
    //       final size = Size(bc.maxWidth, bc.maxHeight-80);
    //       return _build(context, size);
    //     },
    //   ),
    // );
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints bc) {
        var size = Size(0.0, 0.0);
        for (var mapInfoElement in layerOptions.infoElements) {
          print("infoModal visible ${mapInfoElement.visible}");
          if (mapInfoElement.visible ) {
            size = Size(bc.maxWidth, bc.maxHeight);
          }
        }
        //final size = Size(bc.maxWidth, bc.maxHeight);
        //final size = Size(200.0, 350.0);

        return _build(context, size);
        //return Container();
      },
    );
  }

  Widget _build(BuildContext context, Size size) {
    return StreamBuilder<int>(
      stream: stream,
      builder: (BuildContext context, _) {
        var mapInfoWidgets = <Widget>[];
        for (var mapInfoElement in layerOptions.infoElements) {
          if (mapInfoElement.visible) {
            var pos = mapState.project(mapInfoElement.point);
            pos = pos.multiplyBy(
                mapState.getZoomScale(mapState.zoom, mapState.zoom)) -
                mapState.getPixelOrigin();
            mapInfoElement.tapPosition = pos;
            //mapInfoElement.offset = Offset(pos.x.toDouble(), pos.y.toDouble());
            mapInfoElement.offset =
                getInfoElementOffset(pos, size, mapInfoElement.size);

            mapInfoWidgets.add(
              CustomPaint(
                  painter: InfoModalPainter(mapInfoElement),
                  size: size
              ),
            );
          } else {
            print("InfoModal return Container");
            return Container();
          }
        }

        return Container(
          child: Stack(
            
            children: mapInfoWidgets,
          ),
        );
      }
    );
  }

  /// - @param pos : tap position on layer
  /// - @param layerSize : size of layer
  /// - @param size : size of infoModal
  Offset getInfoElementOffset(CustomPoint pos, Size layerSize, Size size) {
    if (pos.x > layerSize.width / 2) {
      return Offset((pos.x - size.width).toDouble(), pos.y.toDouble());
    }

    return Offset(pos.x.toDouble(), pos.y.toDouble());
  }
}

/// Paint [InfoModal].
/// 
class InfoModalPainter extends CustomPainter {
  final InfoModal mapInfoElement;

  InfoModalPainter(this.mapInfoElement);


  @override 
  void paint(Canvas canvas, Size size) {
    // final rect = Offset.zero & size;
    final rect = Offset(0.0, 0.0) & size;
    canvas.clipRect(rect);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = mapInfoElement.color;

    _paintRect(canvas, mapInfoElement.offset, mapInfoElement.size, paint);

    if (mapInfoElement.borderStrokeWidth > 0) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..color = mapInfoElement.borderColor
        ..strokeWidth = mapInfoElement.borderStrokeWidth;

        _paintRect(canvas, mapInfoElement.offset, mapInfoElement.size, paint);
    }

    paint.color = Colors.red;
    Offset circleOffset = Offset.zero;
    if (mapInfoElement.offset.dx < mapInfoElement.tapPosition.x) {
      circleOffset = Offset(mapInfoElement.offset.dx + mapInfoElement.size.width, mapInfoElement.offset.dy );
    } else {
      circleOffset = mapInfoElement.offset;
    }


    _paintCircle(canvas, circleOffset, 4.0, paint);

    _paintText(canvas, mapInfoElement.offset, mapInfoElement.infoText);
  }

  void _paintCircle(Canvas canvas, Offset offset, double radius, Paint paint) {
    canvas.drawCircle(offset, radius, paint);
  }

  void _paintRect(Canvas canvas, Offset offset, Size size, Paint paint) {
    var rect = offset & size;
    // canvas.drawRect(rect, paint);
    var rrect = RRect.fromRectAndRadius(rect, Radius.circular(6.0));
    canvas.drawRRect(rrect, paint);
  }

// void _paintParagraph(Canvas canvas, Offset offset, String text) {
//     ParagraphBuilder paragraphBuilder = ParagraphBuilder(ParagraphStyle(textAlign: TextAlign.left, textDirection: TextDirection.ltr))
//     ..addText(text);

//     Paragraph paragraph = paragraphBuilder.build();
//     paragraph.layout(ParagraphConstraints(width: 200.0));
//     //Offset nullOffset = Offset(0.0, 0.0);
//     canvas.drawParagraph(paragraph, offset);
//   }
  
  void _paintText(Canvas canvas, Offset offset, String text) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(color: Colors.black, fontSize: 12.0)),
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr
    )..layout(maxWidth: 200.0 - 24.0);

    offset = offset + Offset(12.0, 12.0);
    textPainter.paint(canvas, offset);
  }

  @override 
  bool shouldRepaint(InfoModalPainter other) => false;
}