/// Parser for *.gpx xml files
///
/// xml schemas
/// <gpx xmlns="http://www.topografix.com/GPX/1/1"
/// xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
/// xsi:schemaLocation="http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd">
/// points in <trk><trkseg><trkpt> section (trkseg is optional)
///
/// <gpx xmlns="http://www.topografix.com/GPX/1/1"
/// xmlns:gpxx="http://www.garmin.com/xmlschemas/GpxExtensions/v3"
/// xmlns:rcxx="http://www.routeconverter.de/xmlschemas/RouteCatalogExtensions/1.0"
/// point in wpt items
///
/// ToDo parse only tour meta data for new tour
///
import 'package:xml/xml.dart' as xml;
import 'package:latlong/latlong.dart';

import 'gpxFileData.dart';

class GpxParser {

  String gpxData;

  GpxParser(this.gpxData);

  GpxFileData gpxFileData = new GpxFileData();

  /// Start parsing .gpx xml file
  parseData() {
    print("Start parsing gpx file");
    var document = xml.parse(gpxData);
    GPXDocumentType documentType = GPXDocumentType.xsi;

    // what xml schema
    var root = document.findElements('gpx');
    root.forEach((xml.XmlElement f) {
      // print("documentType: ${f.getAttribute("xmlns:gpxx")}");
      if (f.getAttribute("xmlns:gpxx") != null) {
        documentType = GPXDocumentType.gpxx;
      }
    });

    // get trackname -> try <metadata><name>
    /// parse metadata for common and special infos about track
    /// use: name (string), desc (string), keywords (xsd:string)
    /// author, copyright, link,
    String trackName = "";
    Iterable<xml.XmlElement> metadataItems = document.findAllElements('metadata');

    if (metadataItems.isNotEmpty) {
      metadataItems.map((xml.XmlElement metadataItem) {
        trackName = getValue(metadataItem.findElements('name'));
        trackName == null ?? getValue(metadataItem.findElements('description'));
      }).toList(growable: true);
    }
    
    // track segment name
    Iterable<xml.XmlElement> items = document.findAllElements('trk');
    items.map((xml.XmlElement item) {
      var trkName = getValue(item.findElements('name'));
      if (trackName == "") { 
        trackName = trkName; 
      }
      gpxFileData.trackSeqName = trkName;
    }).toList(growable: true);

    List<GpxCoord> trkList = List();

    if (documentType == GPXDocumentType.gpxx) {
      Iterable<xml.XmlElement> wpt = document.findAllElements('wpt');
      trkList = parseGpxx(wpt);
    } else {
      Iterable<xml.XmlElement> trkseg = document.findAllElements('trkseg');
      trkList = parseGpx(trkseg);
    }

    gpxFileData.trackName = trackName != null ? trackName : "?";
    gpxFileData.gpxCoords = trkList;

    /// [GpxFileData.defaultCoords] is the first track point
    /// 
    if (gpxFileData.gpxCoords.length > 0) {
      gpxFileData.defaultCoord = LatLng(trkList.first.lat, trkList.first.lon);
    }

    gpxFileData.addOption("type", "walk");

    return gpxFileData;
  }

List<GpxCoord> parseGpx(Iterable<xml.XmlElement> trkseq) {
    List<GpxCoord> trkList = List();
    trkseq.map((xml.XmlElement trkpt) {
      Iterable<xml.XmlElement> pts = trkpt.findElements('trkpt');
      pts.forEach((xml.XmlElement f) {
        var ele = getValue(f.findElements('ele'));
        ele = ele == null ? "0.0" : ele;
        trkList.add(GpxCoord(
            double.parse(f.getAttribute('lat')),
            double.parse(f.getAttribute('lon')),
            double.parse(ele)
        ));
      });
    }).toList(growable: true);

    return trkList;
  }

  List<GpxCoord> parseGpxx(Iterable<xml.XmlElement> wpt) {
    List<GpxCoord> wpttrkList = List();
    wpt.forEach((xml.XmlElement f) {
      var ele = getValue(f.findElements('ele'));
      ele = ele == null ? "0.0" : ele;
      wpttrkList.add(GpxCoord(
          double.parse(f.getAttribute('lat')),
          double.parse(f.getAttribute('lon')),
          double.parse(ele)
      ));
    });
    return wpttrkList;
  }


  /// extract node text
  String getValue(Iterable<xml.XmlElement> items) {
    var nodeText;
    items.map((xml.XmlElement node) {
      nodeText = node.text;
    }).toList(growable: true);

    return nodeText;
  }
}

enum GPXDocumentType {
  xsi,
  gpxx
}