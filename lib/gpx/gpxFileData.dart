import 'package:latlong/latlong.dart';
import '../db/models/waypoint.dart';


/// Class to hold parsed gpx file data.
/// 
class GpxFileData {
  String trackName = "";
  String trackDescription = "";
  String trackSeqName = "";
  LatLng defaultCoord = LatLng(53.0, 13.10);
  List<GpxCoord> gpxCoords = [];
  List<LatLng> gpxLatLng = [];
  List<Waypoint> wayPoints = [];
  String createdAt = "9999";
  Map<String, dynamic> options = {};

  /// Convert to LatLng
  coordsToLatLng() {
    gpxLatLng = [];
    gpxCoords.forEach((GpxCoord f) {
      gpxLatLng.add(new LatLng(f.lat, f.lon));
    });
  }

  addWaypoint(List<Waypoint> newWaypoints) {
    wayPoints.addAll(newWaypoints);
  }

  addOption(String option, dynamic value) {
    options.addAll({option: value});
  }
}

class GpxCoord {
  double lat;
  double lon;
  double ele;

  GpxCoord(this.lat, this.lon, this.ele);
}