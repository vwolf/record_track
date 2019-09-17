import 'dart:convert';


import '../db/models/track.dart';
import '../readWrite/readFile.dart';
import '../gpx/gpxFileData.dart';
import '../gpx/gpxParser.dart';


/// Service functions for [TrackList] class. 
/// Find tracks in internal and external local storage
/// Read track metadata for [TrackListItem]
/// 
class TrackListService  {

  Map<String, dynamic> trackSettings = {};


  Future<Track> getTrackMetaData(String gpxFilePath) async {
    var fc = await ReadFile().readFile(gpxFilePath);
    GpxFileData gpxFileData = new GpxParser(fc).parseData();

    Track aTrack = Track();
    aTrack.name = gpxFileData.trackName;
    aTrack.location =
        gpxFileData.trackSeqName == null ? "" : gpxFileData.trackSeqName;

    aTrack.coords = jsonEncode({
      "lat": gpxFileData.defaultCoord.latitude,
      "lon": gpxFileData.defaultCoord.longitude
    });

    aTrack.gpxFilePath = gpxFilePath;
    //aTrack.coords = gpxFileData.gpxLatLng;
    if (gpxFileData.options.length > 0) {
      gpxFileData.options.forEach((k, v) {
        aTrack.addOption(k, v);
      });
    }
    
    aTrack.createdAt = gpxFileData.createdAt;

    return aTrack;
  }
}