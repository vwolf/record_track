import 'dart:convert';
import 'package:latlong/latlong.dart';
import 'package:record_track/db/database.dart';
import 'package:record_track/db/models/trackCoord.dart';
import 'package:record_track/gpx/gpxParser.dart';
import 'package:record_track/readWrite/readFile.dart';
import 'package:record_track/services/geolocationService.dart';

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
   // list of coords in table trackCoord
  List<TrackCoord> trackCoords;
  List<LatLng> trackLatLngs;

  Future<void> getTrack(String path) async {
    await ReadFile().readFile(path).then((contents) {
      gpxFileData = new GpxParser(contents).parseData();
      gpxFileData.coordsToLatLng();
    }).whenComplete(() {
      return true;
    });
  }

  loadTrack(Track trackToLoad) async {
    gpxFileData.trackName = trackToLoad.name;
    gpxFileData.trackDescription = trackToLoad.description;
    gpxFileData.defaultCoord = getTrackStart();
    /// track coords
    List<TrackCoord> coords = await DBProvider.db.getTrackCoords(track.track);
    if (coords.length > 0) {
      trackCoords = coords;
      trackLatLngs = GeoLocationService.gls.coordsToLatLng(trackCoords);
    } else {
      // no coords add default coord to trackPoints
    }
    //gpxFileData.gpxLatLng = trackToLoad
  }

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