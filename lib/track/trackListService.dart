import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as path;

import '../services/settings.dart';
import '../db/models/track.dart';
import '../readWrite/readFile.dart';
import '../gpx/gpxFileData.dart';
import '../gpx/gpxParser.dart';

/// Service functions for [TrackList] class. 
/// Find tracks in internal and external local storage
/// Read track metadata for [TrackListItem]
/// 
class TrackListService {

  List<Track> _tracks = [];
  Map<String, dynamic> trackSettings;

  Future<List<Track>> getAllTracksFromFile() async {
    String pathTrackInternal =  Settings.settings.pathTracksInternal;
    if (pathTrackInternal != null) {
      findTracks(pathTrackInternal);
    }


    // SD Card
    String pathTrackExternal = "${Settings.settings.externalSDCard}/${Settings.settings.defaultTrackDirectory}";
    if (pathTrackExternal != null) {
      findTracks(pathTrackExternal);
    }

    return _tracks;
  } 
  
  /// Add all gpx files in [directoryPath] to [trackPath].
  /// Then call [loadTrackMetaData] to read gpx files.
  ///
  /// [directoryPath]
  findTracks(String directoryPath) {
    List<String> trackPath = [];
    Directory(directoryPath).list(recursive: true, followLinks: false)
        .listen((FileSystemEntity entity) {
          if (path.extension(entity.path) == ".gpx") {
            if (trackPath.contains(entity.path) == false) {
              trackPath.add(entity.path);
            }
          }
        })
        .onDone( () => {
          //trackPath.length == 0 ? searchSDCard() : this.loadTrackMetaData(trackPath)
          this.loadTrackMetaData(trackPath)
    });
  }

  /// Load meta data from tracks in [_gpxFileDirectory] into [Track]
  ///
  /// [filePaths] list of gpx files in track directory
  /// Filter track files from waypoint files
  void loadTrackMetaData(List<String> filePaths) async {

    for (var path in filePaths) {
      print ("loadTrackMetaData from $path");
      Track oneTrack = await getTrackMetaData(path);
      if (oneTrack.name != "") {
        _tracks.add(oneTrack);
        // any settings for track?
        if (trackSettings.containsKey(oneTrack.name)) {
          oneTrack.offlineMapPath = trackSettings[oneTrack.name];
        }
      }

     // _tracks.add(oneTrack);
    }
  }

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

    return aTrack;
  }
}