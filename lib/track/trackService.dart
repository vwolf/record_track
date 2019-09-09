import 'dart:convert';
import 'package:latlong/latlong.dart';

import '../db/models/track.dart';
import '../gpx/gpxFileData.dart';

/// Service used by [MapTrack]
/// A [TrackService] object is created when
/// in [TrackList] an [Track] is selected. 
/// A [Track] can be a db entry or a parsed gpx file.
/// 
class TrackService {
  final Track track;

  TrackService(this.track);

  GpxFileData gpxFileData = GpxFileData();

  /// Track start in track from db is in [track.coords]
  /// Track start in track from parsed gpx file is first entry in [gpxFileData.gpxLatLng]
  /// 
  LatLng getTrackStart() {
    if (track.coords != null) {
      var coordsAsJson = jsonDecode(track.coords);
      return LatLng(coordsAsJson['lat'], coordsAsJson['lon']);
    }

    if (gpxFileData.gpxLatLng.length > 0) {
      return gpxFileData.gpxLatLng.first;
    } else {
      print("getTrackStart gpxFileData.gpxLatLng length = 0");
    }
    return null;
  }

  String pathToOfflineMap;
  String pathToTracksDirectory;
}


/// Stream messages
class TrackPageStreamMsg {
  String type;
  var msg;

  TrackPageStreamMsg(this.type, this.msg);
}