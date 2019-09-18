import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:latlong/latlong.dart';
import 'package:record_track/db/database.dart';
import 'package:record_track/db/models/trackCoord.dart';
import 'package:record_track/gpx/gpxParser.dart';
import 'package:record_track/readWrite/readFile.dart';
import 'package:record_track/services/geolocationService.dart';
import 'package:sqflite/sqlite_api.dart';

import '../db/models/track.dart';
import '../gpx/gpxFileData.dart';

/// Service used by [MapTrack]
/// A [TrackService] object is created when
/// in [TrackList] an [Track] is selected. 
/// A [Track] can be a db entry or a parsed gpx file.
/// 
class TrackService {
  Track track;

  TrackService(this.track);

  GpxFileData gpxFileData = GpxFileData();
   // list of coords in table trackCoord
  List<TrackCoord> trackCoords;
  List<LatLng> trackLatLngs;

  /// Fill or update [Track] object to be used by [MapTrack].
  /// 
  Future<void> getTrack() async {
    if(track != null && track.gpxFilePath != null) {
      // track from gpx file
      // read gpx file, transform coords and update track 
      await ReadFile().readFile(track.gpxFilePath).then((contents) {
      gpxFileData = new GpxParser(contents).parseData();
      gpxFileData.coordsToLatLng();
      trackCoords = convertToTrackCoord( gpxFileData.gpxCoords);
      trackLatLngs = gpxFileData.gpxLatLng;
      }).whenComplete(() {
        return true;
      });
    } else {
      // track from db
      await DBProvider.db.getTrackCoords(track.track).then((result) {
        if(result.length > 0) {
          trackCoords = result;
          trackLatLngs = GeoLocationService.gls.coordsToLatLng(trackCoords);
          track.coords = GeoLocationService.gls.latlngToJson(trackLatLngs.first);
        }
      }).whenComplete(() {
        return true;
      });
    }
    return false;
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

  /// Set or change the track start position
  /// 
  setTrackStart(LatLng startPos) async {
    if (trackLatLngs.length > 0) {
      trackLatLngs.replaceRange(0, 1, [startPos]);
      trackCoords[0].latitude = startPos.latitude;
      trackCoords[0].longitude = startPos.longitude;
      track.coords = GeoLocationService.gls.latlngToJson(trackLatLngs.first);
      DBProvider.db.updateTrack(track);
      // update TrackCoords table (index 0)
      DBProvider.db.replaceTrackCoord(track.track, trackCoords[0]);
    }
  }

  String pathToOfflineMap;
  String pathToTracksDirectory;

  /// Add new track point to end of track.
  /// 
  addPointToTrack(LatLng point) async {
    TrackCoord tc = latLngToTrackCoord(point);
    await DBProvider.db.addTrackCoord(tc, track.track);
    trackCoords.add(tc);
    trackLatLngs.add(point);
  }


/// SERVICE FUNCTIONS
  /// Convert [GpxCoords] to [TrackCoord]
  ///
  convertToTrackCoord(List<GpxCoord> gpxCoords) {
    List<TrackCoord> trackCoords = [];
    gpxCoords.forEach((f) {
      trackCoords.add(TrackCoord(
        latitude: f.lat, 
        longitude: f.lon,
        altitude: f.ele ));
    });
  }

  /// Convert [LatLng] to [TrackCoord]
  /// 
  TrackCoord latLngToTrackCoord(LatLng latLng) {
    return TrackCoord(latitude: latLng.latitude, longitude: latLng.longitude);
  }  



































































  


  saveTrack() {
    DBProvider.db.updateTrack(track);
  }
}


/// Stream messages
class TrackPageStreamMsg {
  String type;
  var msg;

  TrackPageStreamMsg(this.type, this.msg);
}