import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:record_track/map/mapScale/scalebar_utils.dart';
import 'package:sqflite/sqlite_api.dart';
import 'package:vector_math/vector_math.dart';
//import 'package:geolocator/geolocator.dart';
import 'package:latlong/latlong.dart';
import 'package:record_track/db/database.dart';
import 'package:record_track/db/models/trackCoord.dart';
import 'package:record_track/gpx/gpxParser.dart';
import 'package:record_track/readWrite/readFile.dart';
import 'package:record_track/services/geolocationService.dart';
//import 'package:sqflite/sqlite_api.dart';

import '../db/models/track.dart';
import '../gpx/gpxFileData.dart';
import '../map/mapPage.dart';

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

  /// Map State variables
  List<int> selectedTrackPoints;

  List<TrackRollbackObj> trackRollbackObjs = [];

  /// Track info
  double trackDistance = 0.0;

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
        getTrackDistance().then((r) {
          trackDistance = r;
        });
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
        getTrackDistance().then((r) {
          trackDistance = r;
        });
        return true;
      });
    }
    return false;
  }


  Future saveEmptyTrack() async {
    LatLng currentPosition = await GeoLocationService.gls.simpleLocation();

    var name_ext = DateTime.now().toString();
    // replace not allowed chars in table name
    name_ext = name_ext.replaceAll(RegExp(r'[:\.\-]'), '_');
    track.name = "track_$name_ext";
    track.description = "tracking start";
    track.location = "later";
    track.timestamp = DateTime.now();
    track.createdAt = DateTime.now().toIso8601String();
    track.coords = GeoLocationService.gls.latlngToJson(currentPosition);
    trackLatLngs = [];
    trackLatLngs.add(currentPosition);
    trackCoords = [];
    TrackCoord newTrackCoord = TrackCoord(
      latitude: currentPosition.latitude,
      longitude: currentPosition.longitude,
      timestamp: DateTime.now());

    await DBProvider.db.newTrack(track);
    trackCoords.add(newTrackCoord);

    // placement infos for location name
    GeoLocationService.gls.getCoordDescription(currentPosition).then((r) {
      track.location = r;
    });

    return true;
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
  /// - [LatLng] point 
  /// - @param redo [bool] optional
  Future<int> addPointToTrack(LatLng point, {bool redo}) async {
    int res = 0;
    TrackCoord tc = latLngToTrackCoord(point);
    await DBProvider.db.addTrackCoord(tc, track.track).then((r) {
      if (r > 0) {
        trackCoords.add(tc);
        trackLatLngs.add(point);
        if ( redo != true ) {
          trackRollbackObjs.add( TrackRollbackObj(TrackAction.AddPoint, [trackCoords.length.toDouble()] ));
        }

        res = r;
      }
    });

    return res;
  }

  /// Insert a new point between to track points.
  /// New point position is halfway between [selectedTrackPoints].
  /// Selected track points in [selectedTrackPoints] list.
  /// 
  /// - [pos] - optinal position of new point. No pos then add in middle
  /// 
  /// - @param trackEvent [TrackEvent] callback to [MapPage]
  /// - @param pos [LatLng] optional
  /// - @param redo [bool] optional
  insertPointInTrack( TrackEvent trackevent,  {LatLng pos, bool redo} ) async {
    if (selectedTrackPoints.length == 2) {
      if (pos == null) {
        pos = midPoint(trackLatLngs[selectedTrackPoints[0]], trackLatLngs[selectedTrackPoints[1]]);
      } 
      TrackCoord trackCoord = TrackCoord(latitude: pos.latitude, longitude: pos.longitude);
      await DBProvider.db.insertTrackCoord(trackCoord, track.track, selectedTrackPoints[1] + 1);      
      trackLatLngs.insert(selectedTrackPoints[1], pos);
      trackCoords.insert(selectedTrackPoints[1], trackCoord);
      if ( redo != true ) {
        trackRollbackObjs.add( TrackRollbackObj(TrackAction.InsertPoint, [selectedTrackPoints[1].toDouble()]));
      }
      trackevent("insertPoint");
    } else {
      debugPrint("selectedTrackPoints?");
    }
  }

  /// Delete [TrackPoint] at [trackPointIndex].
  /// Delete the second point in [selectedTrackPoints].
  /// Update track distance 
  /// 
  /// - First trackpoint: update start point
  deletePointInTrack( TrackEvent trackEvent) async {
    if (selectedTrackPoints.length == 2) {
      int trackPointIndex = selectedTrackPoints[1];
    
      if ( trackPointIndex < trackLatLngs.length ) {
        int trackCoordId = trackCoords[trackPointIndex].id;

        var r = await DBProvider.db.deleteTrackCoord(trackCoordId, track.track);
        print("deletPointInTrack result: $r");
        if (r != false) {
          trackRollbackObjs.add( TrackRollbackObj(TrackAction.DeletePoint, [
            selectedTrackPoints[1].toDouble(), 
            trackCoords[trackPointIndex].latitude, 
            trackCoords[trackPointIndex].longitude 
          ]));
          trackLatLngs.removeAt(trackPointIndex);
          trackCoords.removeAt(trackPointIndex);
          // update seletedTrackPoints if last point
          if (selectedTrackPoints[1] >= trackLatLngs.length) {
            int lastTrackPoint = trackLatLngs.length;
            selectedTrackPoints[0] = lastTrackPoint - 2;
            selectedTrackPoints[1] = lastTrackPoint - 1;
          }
          getTrackDistance().then((r) {
            trackDistance = r;
          });
        }
        
        trackEvent("deletePoint");
      } 
    }
  }

  deletePointAtIndex( TrackEvent trackEvent, int trackPointIndex, {bool redo = false}) async {
    if ( trackPointIndex < trackLatLngs.length ) {
      int trackCoordId = trackCoords[trackPointIndex].id;

      var r = await DBProvider.db.deleteTrackCoord(trackCoordId, track.track);
      if (r != false) {
        if ( redo ) {
          trackRollbackObjs.add( TrackRollbackObj(TrackAction.DeletePoint, [
            selectedTrackPoints[1].toDouble(), 
            trackCoords[trackPointIndex].latitude, 
            trackCoords[trackPointIndex].longitude 
          ]));
          trackLatLngs.removeAt(trackPointIndex);
          trackCoords.removeAt(trackPointIndex);
        }
      }
    }
  }


  /// Caluclate the midpoint between [l1] and [l2].
  /// 
  /// - [LatLng] [l1] start point,
  /// - [LatLng] [l2] end point,
  /// - returns [LatLng]
  LatLng midPoint(LatLng l1, LatLng l2) {
    var l1LatitudeRadians = radians(l1.latitude); 
    var l1LongitudeRadians = radians(l1.longitude);
    var l2LatitudeRadians = radians(l2.latitude);
    //var l2_longitudeRadians = radians(l2.longitude);

    var deltaLon = radians(l2.longitude - l1.longitude); 
    
    /// get cartesian coordinates for both points
    Map A = { 'x': cos(l1LatitudeRadians), 'y': 0, 'z': sin(l1LatitudeRadians)};
    Map B = { 'x': cos(l2LatitudeRadians), 
    'y': cos(l2LatitudeRadians) * sin(deltaLon), 
    'z': sin(l2LatitudeRadians)}; 

    /// Vector to midpoint is sum of vectors to two points (no need to normalise)
    Map C = {'x': A['x'] + B['x'], 'y': A['y'] + B['y'], 'z': A['z'] + B['z']};

    var latM = atan2(C['z'], sqrt((C['x'] * C['x']) + (C['y'] * C['y'])));
    var lonM = l1LongitudeRadians + atan2(C['y'], C['x']);

    print("$latM - $lonM");
    return LatLng(toDegrees(latM), toDegrees(lonM));
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
  TrackCoord latLngToTrackCoord(LatLng latLng)  {
    return TrackCoord(latitude: latLng.latitude, longitude: latLng.longitude);
  }  

  /// Change track point position at [trackPointIndex]
  /// Make new [TrackCoord] and replace in db.
  /// If db write successful. update 
  /// [trackLatLngs] and [trackCoords].
  ///
  Future<int> changeTrackPointCoord(int trackPointIndex, LatLng latlng) async {
    TrackCoord newTrackCoord = trackCoords[trackPointIndex];
    newTrackCoord.latitude = latlng.latitude;
    newTrackCoord.longitude = latlng.longitude;
    int res;

    await DBProvider.db.replaceTrackCoord(track.track, trackCoords[trackPointIndex]).then((r) {
      if (r > 0) {
        trackLatLngs[trackPointIndex].latitude = latlng.latitude;
        trackLatLngs[trackPointIndex].longitude = latlng.longitude;
        trackCoords[trackPointIndex] = newTrackCoord;
      }
      res = r;
    });
    return res;
  }

  saveTrack() {
    DBProvider.db.updateTrack(track);
  }

  /// Reverse last action in [TrackRollbackObj] list
  /// 
  /// @param [TrackEvent] trackEvent - callback to [MapPage]
  redoTrackEditAction(TrackEvent trackEvent) {
    if (trackRollbackObjs.length > 0) {
      TrackRollbackObj t = trackRollbackObjs.last;
      switch (t.trackAction) {
        case TrackAction.InsertPoint : 
        // one param in actionParams  - index of added coord
        // reverse insertPoint action
        deletePointAtIndex(trackEvent, t.actionParams[0].toInt(), redo: true);
        trackRollbackObjs.removeLast();
        trackEvent('redo-insertPoint');
        break;

        // reverse addPoint action (point to end of track)
        // delete last point of track
        case TrackAction.AddPoint :
        deletePointAtIndex(trackEvent, t.actionParams[0].toInt(), redo: true);
        trackRollbackObjs.removeLast();
        trackEvent('redo-addPoint');
        break;

        // Reverse deletePoint action params 3, index, lat, lon
        case TrackAction.DeletePoint :
        if (t.actionParams.length == 3) {
          // if last on in coors list - add otherwise -insert
          if (trackCoords.length < t.actionParams[0].toInt()) {
            addPointToTrack(LatLng(t.actionParams[1], t.actionParams[2]), redo: true);
            trackRollbackObjs.removeLast();
            trackEvent('redo-deletePoint');
          } else {
            insertPointInTrack( trackEvent,  pos: LatLng(t.actionParams[1], t.actionParams[2]), redo: true );
            trackRollbackObjs.removeLast();
            trackEvent('redo-deletePoint');
          }
        }
        break;
      }
    }
  }

  /// Track info's
  /// 
  
  /// Return length of track in meter
  /// 
  Future<double> getTrackDistance() async {
    //double totalDistance = 0;
    double totalDistanceGeo = 0;
    for (var i = 0; i < trackLatLngs.length - 1; i++) {
      totalDistanceGeo += await Geolocator().distanceBetween(
        trackLatLngs[i].latitude, 
        trackLatLngs[i].longitude, 
        trackLatLngs[i + 1].latitude, 
        trackLatLngs[i + 1].longitude); 
    }
    
    int distanceMeter = totalDistanceGeo.toInt();
    double distanceKm = (distanceMeter / 1000);
    return distanceKm;
  }
}


/// Stream messages
class TrackPageStreamMsg {
  String type;
  var msg;

  TrackPageStreamMsg(this.type, this.msg);
}


/// [Track] edit rollback.
class TrackRollbackObj {
  final TrackAction trackAction;
  final List<double> actionParams;

  TrackRollbackObj(this.trackAction, this.actionParams);
}


enum TrackAction {
  AddPoint,
  DeletePoint,
  InsertPoint,
}