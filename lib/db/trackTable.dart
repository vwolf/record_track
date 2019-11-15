import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:sqflite/sqflite.dart';

import 'models/track.dart';
import 'trackCoord.dart';
import 'trackItem.dart';

class TrackTable {
  TrackTable();

  createTrackTable(Database db) async {
    debugPrint("CreateTourTable()");

    try {
      var result = db.transaction((txn) async {
        await txn.execute("CREATE TABLE TRACK ("
          "id INTEGER PRIMARY KEY,"
          "name TEXT,"
            "description TEXT,"
            "timestamp TEXT,"
            "open BIT,"
            "location TEXT,"
            "tourImage TEXT,"
            "options TEXT,"
            "coords TEXT,"
            "track INTEGER,"
            "items INTEGER,"
            "createdAt TEXT )");
      });
      debugPrint("Collection Track create ok: $result");
      return result;
    } on DatabaseException catch (e) {
      debugPrint("DatabaseException $e");
      return false;
    }
  }

  /// Write new track to db
  /// Track names have to be unique
  Future newTrack(Database db, Track newTrack) async {
    debugPrint("DB newTrack ${newTrack.name}");
    // get max id in table
    var table = await db.rawQuery("SELECT MAX(id)+1 as id FROM TRACK");
    int id = table.first['id'];
    // join all parts of trackname with '_'
    var trackNameFinal = newTrack.name.replaceAll(new RegExp(r'[ -]'), '_');
    // create trackCoordsTable for track
    var trackCoordsTableName = await createTrackCoordsTable(db, trackNameFinal);
//    if (trackCoordsTableName != false) {
//      var res = await db.query(trackCoordsTableName, columns: ["id"]);
//      if (res.length > 0 ) {
//        if (res.contains("id")) {
//          newTrack.track = res[0] as int;
//        }
//      }
//    }

    print("CreateTrackCoordsTable $trackCoordsTableName");
    newTrack.track = trackCoordsTableName;

    // create track items table
    var trackItemsTable = await createTrackItemTable(db, trackNameFinal);
    debugPrint("CreateTrackItemTable $trackItemsTable");
    newTrack.items = trackItemsTable;

    // insert in table using new id
    debugPrint("Start insert new Track");
    newTrack.id = id;
    newTrack.createdAt = DateTime.now().toIso8601String();
    var result = await db.insert("Track", newTrack.toMap());
    return result;
  }


  /// To change the track name, we need to create
  /// new track, coords and item table
  /// Clone tables then delete
  /// ToDo Check if tables exists
  Future cloneTrack(Database db, Track newTrack) async {
    print("db CloneTrack");
    /// first create new table and save
    // join all parts of tourname with '_'
    String newTrackName = newTrack.name.replaceAll(RegExp(r' '), '_');
    String oldTrackName = newTrack.track.replaceAll(RegExp(r' '), '_');
    // save for later
    int oldTrackId = newTrack.id;

    // create track table for track
    var cloneTableResult = await cloneTrackCoordsTable(db, newTrack.track, newTrackName);
    newTrack.track = cloneTableResult;
    TrackCoordTable().deleteTrackCoordTable(db, oldTrackName);

    // clone item table and delete old table
    String oldTrackItemsTableName = newTrack.items.replaceAll(RegExp(r' '), '_');
    var cloneItemTableResult = await cloneTrackItemTable(db, newTrack.items, newTrackName);
    newTrack.items = cloneItemTableResult;
    TrackItemTable().deleteTrackItemTable(db, oldTrackItemsTableName);

    // delete track and add new track
    deleteTrack(db, oldTrackId);
    var res = await db.insert("TRACK", newTrack.toMap());
    return res;
  }


  /// Table for track coords
  createTrackCoordsTable(Database db, String trackName) async {
    return await TrackCoordTable().createTrackCoordTable(db, trackName);
  }

/// Clone table for track coordinates
  cloneTrackCoordsTable(Database db, String tableToClone, String newTableName ) async {
    return await TrackCoordTable().cloneTrackCoordTable(db, tableToClone, newTableName);
  }

  /// Table for track items
  createTrackItemTable(Database db, String tourName) async {
    return await TrackItemTable().createTrackItemTable(db, tourName);
  }

  /// Clone table for track items
  cloneTrackItemTable(Database db, String tableToClone, String tableName ) async {
    return await TrackItemTable().cloneTrackItemTable(db, tableToClone, tableName);
  }


  updateTrack(Database db, Track track) async {
    print("updateTrack");
    try {
      var result = await db
          .update("TRACK", track.toMap(), where: "id = ?", whereArgs: [track.id]);
      return result;
    } on DatabaseException catch (e) {
      print("sqlite error $e");
    }
    return 0;
  }


  deleteTrack(Database db, int id) async {
    print("deleteTrack with id $id");
    return db.delete("TRACK", where: "id = ?", whereArgs: [id]);
  }



  Future<List<Track>> getAllTracks(Database db) async {
    debugPrint("getAllTracks()");
    try {
      var result = await db.query("TRACK");
      List<Track> list = result.isNotEmpty ? result.map((c) => Track.fromMap(c)).toList() : [];

      return list;
    } on DatabaseException catch (e) {
      debugPrint("DatabaseExecption in getAllTracks: $e");
    }

    return [];
  }


  Future<int> tableExists(Database db, String tableName) async {
    var result = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name= ?",
        [tableName]);
    if (result.length > 0) {
      print("table $tableName exists");
      return result.length;
    } else {
      print("table $tableName does not exists");
      var tableCreated = await createTrackTable(db);
      if (tableCreated == true) {
        return 1;
      }
    }
    return null;
  }

  Future<int> trackExists(Database db, String query) async {
    try {
      List<Map> maps =
          await db.rawQuery("SELECT id FROM TOUR WHERE name = ? ", [query]);
      if (maps.length > 0) {
        return maps.length;
      }
    } on DatabaseException catch (e) {
      print("DatabaseException: $e");
    }
    return null;
  }

  /// Add track point to track.
  /// 
  Future<void> addTrackPoint() async {
    
  }
}